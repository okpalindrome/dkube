#!/bin/bash

# Initialize variables
directory=""
namespace=""
active_resource=()
scan_checkov="false" # In the future, this must be handled using an array with actual argument input (tool name) 

declare -A UNIQUE_IMAGES

# Import SAST modules
source ./SAST/sast-checkov.sh

# Function to display usage information
usage() {
    echo
    echo "Usage: $0"
    echo
    echo "Options:"
    echo "  -d, --dir           Specify the directory to use to store the result."
    echo "  -n, --namespace     Specify the namespace to query [optional]."
    echo "  -s, --sast          Perform SAST scan using Checkov [optional]."
    echo "  -h, --help          Display this help message."
    exit 1
}

save_images() {
    for img in "${!UNIQUE_IMAGES[@]}"; do
        echo "$img" >> "$dest/docker_images.txt"
    done
    
    # sort it
    sort -o "$dest/docker_images.txt" "$dest/docker_images.txt"
    
    echo -e "\e[1mTotal unique images:  $(wc -l < $dest/docker_images.txt)\e[0m"
}

grab_images() {
    
    touch "$dest/docker_images.txt"
    echo "Fetching Docker images from various objects..."
    
    # You can add or remove the places to check for images
    res_types=("deployments" "statefulsets" "daemonsets" "cronjobs" "jobs" "pods" "replicasets")
    
    for res in "${res_types[@]}"; do
        
        if [[ "$res" == "pods" ]]; then
            jsonpath="{.items[*].spec.containers[*].image} {.items[*].spec.initContainers[*].image}"
        else
            jsonpath="{.items[*].spec.template.spec.containers[*].image} {.items[*].spec.template.spec.initContainers[*].image}"
        fi
        
        images=$(kubectl get "$res" -n "$namespace" -o jsonpath="$jsonpath" 2>/dev/null)
        
        if [ $? -eq 0 ] && [ -n "$images" ]; then
            
            # filter out the spaces for count check
            image_count=$(echo "$images" | tr ' ' '\n' | grep -v '^$' | wc -l)
            
            if [ $image_count -gt 0 ]; then
                echo "Found $image_count images in $res..."
                for img in $images; do
                    if [ -n "$img" ]; then
                        UNIQUE_IMAGES["$img"]=1
                    fi
                done
            fi
        fi
    done
    save_images
}

query_active_resources() {
    
    resource=$1
    
    # permission to fetch - actively query the resource for your role
    checking=$(kubectl get "$resource" --no-headers -n "$namespace" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$checking" ]; then
        res_path="$dest/$resource"
        mkdir -p "$res_path"
        
        filename="manifest_$resource.yaml"
        
        kubectl get "$resource" -n "$namespace" -o yaml > "$res_path/$filename"
        
        echo "$resource" >> "$dest/active_resources.txt"
    fi
    
}

api_resources() {
    
    resources=($(kubectl api-resources --verbs=list --namespaced=true -n "$namespace" -o name))
    
    total=${#resources[@]}
    count=0
    
    echo ""
    printf "Checking api resources [%d/%d] " $count $total

    touch "$dest/active_resources.txt"
    
    for obj in "${resources[@]}"; do
        ((count++))
        printf "\r \033[KChecking resources [%d/%d] " $count $total

        if [ -n $obj ]; then
            echo "$obj" >> "$dest/available_api_resources.txt"
            query_active_resources "$obj"
        fi
        sleep 0.1
    done
    echo ""
    echo ""
    echo -e "\e[1mTotal active resources you can query: $(wc -l < $dest/active_resources.txt)\e[0m"
}

# Check if at least one argument is provided
if [ $# -eq 0 ]; then
    usage
fi

# Parse command line arguments - flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--dir)
            directory="$2"
            shift 2
        ;;
        -n|--namespace)
            namespace="$2"
            shift 2
        ;;
        -s|--sast)
            scan_checkov="true"
            shift
        ;;
        -h|--help)
            usage
        ;;
        *)
            echo "Unknown option: $1"
            usage
        ;;
    esac
done

directory="${directory%/}"

if [[ -z "$directory" || ! -d "$directory" ]]; then
    echo "Provide directory or given directory does not exist!"
    usage
fi

if [[ -z "$namespace" ]]; then
    namespace=$(kubectl config view --minify -o jsonpath={..namespace})
    
    if [[ -z "$namespace" ]]; then
        echo "[Error] getting the current context's namespace."
        usage
    else
        echo "Querying current context's namespace: $namespace"
    fi
fi

if [ ! -d "$directory/$namespace" ]; then
    mkdir -p "$directory/$namespace"
    dest="$directory/$namespace"
else 
    echo "Directory $directory/$namespace already exists!"
    exit 1
fi


# docker image scrapping
grab_images "$dest"

# find active resources/objects
api_resources

# call sast tools
if [ "$scan_checkov" == "true" ]; then
    sast-checkov "$dest"
fi


echo -e "\n\e[1mCompleted: $dest \e[0m"
