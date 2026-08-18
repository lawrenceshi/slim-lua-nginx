import os
import pathlib

# The function for writing text
def write_text(read_file_name:str, write_to_file):
    with open(os.path.join("build", f"{read_file_name}.txt"), "r") as text:
        write_to_file.write(text.read())
    return True

def write_replace_text(read_file_name:str, write_to_file, change:dict):
    with open(os.path.join("build", f"{read_file_name}.txt"), "r") as text:
        replace_text = text.read()
        for k,v in change.items():
            replace_text = replace_text.replace(k, v)
        write_to_file.write(replace_text)

def ask_number(question:str,options:list) -> int:
    print("==============================")
    print(question)
    for i in range(len(options)):
        print(f"Option {i+1}. {options[i]}")
    print("==============================")

    answer=int(input("Please select an option by entering the corresponding number: "))

    if answer > len(options):
        print("Invalid input. Please enter a number corresponding to one of the options.")
        return ask_number(question, options)
    return answer

def ask_bool(question:str) -> bool:
    print("==============================")
    print(question)
    print("==============================")

    answer = input("Input (y/n): ").lower()

    if answer == "y" or answer == "yes" or answer == "true":
        return True
    elif answer == "n" or answer == "no" or answer == "false":
        return False
    else:
        print("Invalid input. Please enter 'y' or 'n'.")
        return ask_bool(question)

def main(
        Containerfile_write_path:list = ["Production.Containerfile"], 
        ARGs_env_path:list = ["ARGs.env"],
        if_arg_env:bool = True,
        Cloud_or_Local:int = 1,

        ) -> bool:

    Containerfile_write_path=os.path.normpath(os.path.join(Containerfile_write_path))
    
    with open(Containerfile_write_path, "w") as container_file:
            # Some non-usable error test:
            if "alpine" in v["builder_image"] and v["include_corazawaf"]:
                print("This config is Incompatible and not useable")
                exit(1)

            # Write '''DO NOT CHANGE''' warning
            if v["write_warning"]:
                write_text("Warning", container_file)
            
            # Write and replace the From xxx image
            if v["write_base_image"]:
                write_replace_text("Image", container_file, {"$[image_name]": v["builder_image"], "$[stage_name]" : v["builder_stage_name"]})
            
            # Coraza Part
            if v["include_corazawaf"]:
                write_replace_text("Corazawaf", container_file, {"$[Libcoraza_Versio]" : v["libcoraza_version"], "$[Corazawaf_Version]" : v["libcoraza_version"]})
            
            

if __name__ == "__main__":
    print("Starting the configuration script")
    Cloud_or_Local = ask_number(question="Do you want to use the builder image from the cloud, or build it locally?", options=["Cloud", "Locally"])

    main(
        Containerfile_write_path = "Production.Containerfile",
        Cloud_or_Local=Cloud_or_Local
    )