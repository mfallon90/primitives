import yaml

def generate_makefile(rtl_dependencies, sim_dependencies):
    makefile_content = ""

    # Header
    makefile_content += "# Automatically generated Makefile\n\n"
    
    # Directories
    makefile_content += "HDL_DIR := hdl\n"
    makefile_content += "SIM_DIR := sim\n"
    makefile_content += "BUILD_DIR := build\n\n"

    # Targets
    makefile_content += ".PHONY: all clean\n\n"

    # Target for all
    makefile_content += "all: $(BUILD_DIR) rtl sim\n\n"

    # Rules for RTL dependencies
    makefile_content += "rtl: $(BUILD_DIR)/rgmii_rx.sv\n\n"
    makefile_content += "$(BUILD_DIR)/rgmii_rx.sv: $(HDL_DIR)/rgmii_rx.sv | $(BUILD_DIR)\n"
    makefile_content += "\t# Add commands to build RTL dependencies\n\n"

    # Rules for simulation dependencies
    makefile_content += "sim: $(BUILD_DIR)/test_rgmii.py $(BUILD_DIR)/rgmii.py $(BUILD_DIR)/validmonitor.py\n\n"

    for sim_dependency in sim_dependencies:
        makefile_content += "$(BUILD_DIR)/" + sim_dependency["name"] + ": $(SIM_DIR)/" + sim_dependency["name"] + " | $(BUILD_DIR)\n"
        makefile_content += "\t# Add commands to build simulation dependencies\n\n"

    # Rule for creating the build directory
    makefile_content += "$(BUILD_DIR):\n\tmkdir -p $(BUILD_DIR)\n\n"

    # Rule for cleaning
    makefile_content += "clean:\n\trm -rf $(BUILD_DIR)\n"

    return makefile_content

def main():
    # Read YAML file
    with open("manifest.yml", "r") as file:
        dependencies_data = yaml.safe_load(file)

    # Get RTL and simulation dependencies
    rtl_dependencies = dependencies_data.get("rtl_dependencies", [])
    sim_dependencies = dependencies_data.get("sim_dependencies", [])

    # Generate Makefile content
    makefile_content = generate_makefile(rtl_dependencies, sim_dependencies)

    # Write Makefile
    with open("Makefile", "w") as makefile:
        makefile.write(makefile_content)

if __name__ == "__main__":
    main()

