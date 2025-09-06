sast-checkov() {

    # Check if dest is set
    if [[ -z "$dest" ]]; then
        echo "Error: 'dest' variable is not set."
        return 1
    fi
    
    mkdir -p "$dest/checkov"
    checkov_path="$dest/checkov"
    
    # get all resources - yaml
    resources_file="$checkov_path/$namespace-resources.yaml"
    kubectl get all -n "$namespace" -o yaml > "$resources_file"
    
    # scan on yaml file 
    all_findings_file="$checkov_path/$namespace-all-resource-findings.txt"
    checkov -f "$resources_file" --skip-results-upload --no-cert-verify --quiet  > "$all_findings_file" 2>/dev/null

    unique_findings_file="$checkov_path/unique_findings.txt"
    cat "$checkov_path/$namespace-all-resource-findings.txt" | grep "Check: CKV_*" | sed 's/Check: //g' | sort | uniq > "$unique_findings_file"

    mapfile -t keys < <(cat "$unique_findings_file" | sed 's/:.*//')

    total=${#keys[@]}
    count=0
    
    echo ""
    echo -e "\e[1mTotal vulnerabilities found: $total"
    printf "Querying individual findings [%d/%d] " $count $total

    for key in "${keys[@]}"; do
        ((count++))
        printf "\r \033[KQuerying individual findings [%d/%d] " $count $total

        key_findings_file="$checkov_path/$key.txt"
        checkov --check $key -f "$resources_file" --skip-results-upload --no-cert-verify --quiet 2>/dev/null | grep -e "FAILED for resource:" -e "Guide:" | sort | uniq > "$key_findings_file"
        
    done

    rm "$all_findings_file"
}
