import os
import re
import requests
import subprocess  # For Invoke-Item equivalent
from concurrent.futures import ThreadPoolExecutor
from tqdm import tqdm



# ANSI escape codes for colored text
RED = '\033[91m'
GREEN = '\033[92m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
MAGENTA = '\033[95m'
CYAN = '\033[96m'
RESET = '\033[0m'  # Reset to default color

def show_error(msg):
    print(f"{RED}Error: {msg}{RESET}")

def show_instruction(msg):
    print(f"{BLUE}{msg}{RESET}")

def show_exception(msg):
    print(f"{RED}{msg}{RESET}")

def get_details(html_content):
    patterns = {
        'instructorPattern': r'<span class="instructor-name">(?P<instructor>.*?)</span>'
    }
    
    title_match = re.search(r'<title>(.*?)</title>', html_content)
    title_name = title_match.group(1).split('|')[0] if title_match else "Title not found"

    if re.search(patterns['instructorPattern'], html_content):
        instructor_name = re.search(patterns['instructorPattern'], html_content).group('instructor')
    else:
        instructor_name = "Instructor not found"
    return title_name, instructor_name

def show_details(details_list):
    print(f"- Title: {details_list[0]}")
    print(f"- Instructor: {details_list[1]}")

def get_additional_details(html_content):
    additional_details_match = re.search(r'<span class="course-number-term-detail">(.*?)</span>', html_content)
    if additional_details_match:
        return additional_details_match.group(1).split("|")
    else:
        return ["Course ID not found", "Course Semester not found.", "Course Level not found."]

def show_additional_details(additional_details):
    print(f"- ID: {additional_details[0]}")
    print(f"- Semester: {additional_details[1]}")
    print(f"- Level: {additional_details[2]}")

def set_resource_list(downloads_page_link):
    try:
        download_page = requests.get(downloads_page_link)
        download_page.raise_for_status()  # Raise HTTPError for bad responses
        content = download_page.text
        keys = ['Lecture Videos', 'Assignments', 'Exams', 'Lecture Notes']
        resource_list = [key for key in keys if key in content]
        return resource_list
    except requests.exceptions.RequestException as e:
        show_error(f"Unable to load resource list: {e}")
        return []

def show_resources(res_list):
    if res_list:
        print(f"{GREEN}::::::::::::::::::::::::::::::::{RESET}")
        print(f"{GREEN}--------Resources Available--------{RESET}")
        print(f"{GREEN}::::::::::::::::::::::::::::::::{RESET}")
        for index, res in enumerate(res_list, start=1):
            print(f"{index} {res}")
    else:
        print(f"{YELLOW}:({RESET}")
        print(f"{YELLOW}No resources found!{RESET}")
        show_instruction("Please try downloading manually.")
        exit()

def get_options(res_list):
    print("Enter the index of the desired resource for download")
    print("=>Use commas for multiple indices")
    print("=>Enter A for downloading all resources")
    print("=>Example: 1,2")

    while True:
        user_inputs = input("Input: ")
        if not user_inputs:
            show_error("Input cannot be empty")
            continue

        if user_inputs.lower() == 'a':
            return 'all'

        try:
            target_indices = []
            for user_input in user_inputs.split(','):
                index = int(user_input.strip()) - 1
                if 0 <= index < len(res_list):
                    target_indices.append(index)
                else:
                    show_error("One or more of the indices invalid")
                    break
            else:  # Only executes if the inner loop completes without a break
                return target_indices
        except ValueError:
            show_error("Invalid input")

def get_path():
    print("Enter the download path: ")
    print("=>Example: C:\\Users\\john\\OneDrive\\Desktop")
    print("=>Example: Course (💡Make folder in the current directory)")

    while True:
        input_path = input("Input: ").strip()
        if not input_path:
            show_error("Path cannot be empty string")
        else:
            return input_path

def get_response(res_list):
    user_inputs = get_options(res_list)
    try:
        input_path = get_path()
    except Exception as e:
        show_error(str(e))
        exit()
    return {
        'inputPath': input_path,
        'userInputs': user_inputs
    }

def get_files(base_uri, dir_name, download_path, slash):
    try:
        base_page = requests.get(base_uri)
        base_page.raise_for_status()
        html_content = base_page.text
    except requests.exceptions.RequestException as e:
        show_exception(str(e))
        return

    if 'LVideos' in dir_name:
        download_links_list = re.findall(r'href="(.*?\.mp4)"', html_content)
    else:
        download_links_list = re.findall(r'href="(.*?\.pdf)"', html_content)

    files = []

    full_download_path = os.path.join(download_path, dir_name)
    if not os.path.exists(full_download_path):
        os.makedirs(full_download_path)

    index = 1
    for download_link in download_links_list:
        if '/courses/' in download_link:
            download_link = 'https://ocw.mit.edu' + download_link
            extension = '.pdf'
        else:
            extension = '.mp4'

        file_uri = download_link
        file_name = f"{dir_name} {index}{extension}"
        file_path = os.path.join(full_download_path, file_name)

        files.append({
            'Uri': file_uri,
            'outFile': file_path
        })
        index += 1

    download_option = input("How would you like to download the files?\n1. Serially\n2. Parallely\nEnter option (1 or 2): ")
    if download_option == '2':
        with ThreadPoolExecutor(max_workers=4) as executor:  # Adjust max_workers as needed
            print(f"{CYAN}🔁 Downloads in progress...{RESET}")
            futures = [executor.submit(download_file, file['Uri'], file['outFile']) for file in files]
            for future in tqdm(futures, desc=f"{CYAN}{dir_name} 🚀 Downloading {RESET}", total=len(files)):
                future.result()  # Wait for each future to complete
            print(f"{GREEN}{dir_name} ✅ Downloads finished!{RESET}")
    else:
        print(f"{CYAN}{dir_name} 🔁 Downloads in progress...{RESET}")
        for file in files:
            try:
                download_file(file['Uri'], file['outFile'])
                print(f"{CYAN}Downloaded {file['outFile']}{RESET}")
            except Exception as e:
                show_exception(f"Error downloading {file['outFile']}: {e}")
        print(f"{GREEN}{dir_name} ✅ Downloads finished!{RESET}")

def download_file(url, filename):
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()  # Raise HTTPError for bad responses
        total_size = int(response.headers.get('content-length', 0))
        block_size = 8192
        with open(filename, 'wb') as file, tqdm(
            desc=filename,
            total=total_size,
            unit='iB',
            unit_scale=True,
            unit_divisor=1024,
        ) as bar:
            for chunk in response.iter_content(chunk_size=block_size):
                if chunk:  # filter out keep-alive new chunks
                    file.write(chunk)
                    bar.update(len(chunk))
    except requests.exceptions.RequestException as e:
        show_exception(f"Error downloading {url}: {e}")

def get_lvideos(download_path, link, slash):
    try:
        get_files(link + 'resources/lecture-videos/', 'LVideos', download_path, slash)
    except Exception as e:
        show_error("Error in downloading Lecture Videos")
        show_exception(str(e))

def get_assignments(download_path, link, slash):
    try:
        get_files(link + 'resources/assignments/', 'Assignments', download_path, slash)
    except Exception as e:
        show_error("Error in downloading Assignments")
        show_exception(str(e))

def get_exams(download_path, link, slash):
    try:
        get_files(link + 'resources/exams/', 'Exams', download_path, slash)
    except Exception as e:
        show_error("Error in downloading Exams")
        show_exception(str(e))

def get_lnotes(download_path, link, slash):
    try:
        get_files(link + 'resources/lecture-notes/', 'LNotes', download_path, slash)
    except Exception as e:
        show_error('Error in downloading LNotes')
        show_exception(str(e))

def import_resources(user_response, res_list, link, slash):
    download_path = user_response['inputPath']
    user_inputs = user_response['userInputs']

    if user_inputs == 'all':
        resources_to_download = res_list
    else:
        resources_to_download = [res_list[i] for i in user_inputs]

    for res in resources_to_download:
        print(f"{MAGENTA}✨ Fetching {res}{RESET}")
        if res == 'Lecture Videos':
            get_lvideos(download_path, link, slash)
        elif res == 'Assignments':
            get_assignments(download_path, link, slash)
        elif res == 'Exams':
            get_exams(download_path, link, slash)
        elif res == 'Lecture Notes':
            get_lnotes(download_path, link, slash)

def welcome():
    print(fr"""{YELLOW}
     ____  ______      _____    _____  __
    / __ \/ ___/ | /| / / _ \  / _ \ \/ /
    / /_/ / /__ | |/ |/ / // / / ___/\\ / 
    \____/\___/ |__/|__/____(_)_/    /_/                                    
    {RESET}""")
    print(f"{GREEN}✨ Learn from MIT in your terminal! ✨{RESET}")

# Starting point
if __name__ == "__main__":
    
    welcome()

    link = input("Enter the URL to course homepage: ")

    link = link.strip()

    if "https://ocw.mit.edu/courses" in link:
        try:
            web_response = requests.get(link)
            web_response.raise_for_status()
            html_content = web_response.text
        except requests.exceptions.RequestException as e:
            show_error(f"Failed to retrieve the course page: {e}")
            exit()

        print(f"{GREEN}--------Course Found--------{RESET}")
        print(f"{GREEN}:::::::::::::::::::::::::::::::::::{RESET}")

        details = get_details(html_content)
        show_details(details)

        additional_details = get_additional_details(html_content)
        show_additional_details(additional_details)

        downloads_page_link = link.rstrip('/') + '/download/'
        try:
            res_list = set_resource_list(downloads_page_link)
            show_resources(res_list)
        except Exception as e:
            show_error(str(e))
            exit()

        user_response = get_response(res_list)
        try:
            import_resources(user_response, res_list, link, '/')  # Assuming Unix-like paths
            # This opens the file explorer of the respective OS
            if os.name == 'nt':  # Windows
                os.startfile(user_response['inputPath'])
            else:  # macOS or Linux
                if os.name == 'posix':
                    subprocess.run(['xdg-open', user_response['inputPath']])  #linux
                elif os.name == 'darwin':
                     subprocess.run(['open', user_response['inputPath']])  # macOS
        except Exception as e:
            show_exception(str(e))