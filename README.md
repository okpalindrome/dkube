# dkube

Crawls the static information from a specific namespace in Kubernetes and performs SAST scan locally.

- Get all unique Docker images.
- List all actively used resources.
- Crawl the yaml from each active resources.
- Crawled manifest files will be scanned using SAST tool [Checkov](https://github.com/bridgecrewio/checkov). You can also feed these files to more SAST tools like [kube-score](https://github.com/zegl/kube-score), etc. to better facilitate your Pentest.
- Store all the above information in a directory structure.

```
-- namespace-directory
   -- resource 1
            manifest_resource-name.yaml
   -- resource 2
            manifest_resource-name.yaml
   -- sast-tool-name
            vul_id.txt
            <namespace>-resources.yaml
            unique_findings.txt
    docker_images.txt
    active_resources.txt
    available_api_resources.txt
```

- This acts as a snapshot of the environment.
- Also, using [docker-multi-scan](https://github.com/okpalindrome/docker-multi-scan) you can scan the images using Grype, Trivy and Docker-scout at once.

### Prequisites
- kubectl cli tool
- Kube-config file at `~/.kube/config`

### Usage
```
$ chmod +x dkube.sh
$ ./dkube.sh -h

Usage: ./dkube.sh

Options:
  -d, --dir           Specify the directory to use to store the result.
  -n, --namespace     Specify the namespace to query [optional].
  -s, --sast          Perform SAST scan using Checkov [optional].
  -h, --help          Display this help message.
```
### Example
```
./dkube.sh -d /home/kali/Documents/github-tools-payloads/dkube/ -n monitoring -s
Fetching Docker images from various objects...
Found 3 images in deployments...
Found 3 images in statefulsets...
Found 1 images in daemonsets...
Found 8 images in pods...
Found 13 images in replicasets...
Total unique images:  7

 Checking resources [35/35] 

Total active resources you can query: 14

Total vulnerabilities found: 18
 Querying individual findings [18/18] 
Completed: /home/kali/Documents/github-tools-payloads/dkube/monitoring 
```

Note - For any CRLF errors, use `dos2unix dkube.sh`
