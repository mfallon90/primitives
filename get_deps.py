
import subprocess
import yaml
import os

# Constants
BASE_URL = "https://github.com/mfallon90/"
TARGET_DIRECTORY = "/build"

def clone_git_repository(name, branch):
    # Construct the full repository URL
    url = f"{BASE_URL}{name}.git"


    # Form the Git clone command
    git_clone_cmd = f"git clone --branch {branch} {url}"

    # Run the Git clone command
    try:
        subprocess.run(git_clone_cmd, shell=True, check=True)
        print(f"Repository '{name}' cloned successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error cloning repository '{name}': {e}")

def main(yaml_file):
    # Get the absolute path to the script directory
    script_directory = os.path.dirname(os.path.abspath(__file__))

    build_directory = os.path.join(script_directory, "build")

    os.makedirs(build_directory, exist_ok=True)

    # Join the script directory with the YAML file name
    yaml_file_path = os.path.join(script_directory, yaml_file)

    # Read YAML file
    with open(yaml_file_path, "r") as file:
        yaml_data = yaml.safe_load(file)

    # Get Git dependencies
    git_dependencies = yaml_data.get("git_dependencies", [])
    
    print(git_dependencies)

    os.chdir(build_directory)
    # Clone Git repositories
    for git_dependency in git_dependencies:
        name = git_dependency.get("name")
        branch = git_dependency.get("branch", "master")  # Default to "master" if not specified

        if name:
            clone_git_repository(name, branch)
        else:
            print("Invalid Git dependency entry in YAML file.")

if __name__ == "__main__":
    # Specify the YAML file as a command-line argument
    yaml_file_name = "manifest.yml"
    main(yaml_file_name)

