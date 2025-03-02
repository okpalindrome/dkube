# dkube

Crawls the static information from a specific namespace in Kubernetes. 

- Get all unique Docker images.
- List all actively used resources.
- Crawl the yaml from each active resources.
- Store all the above information in a directory structure.

```
-- namespace-directory
   -- resource 1
            manifest_resource-name.yaml
   -- resource 2
            manifest_resource-name.yaml
   docker_images.txt
   active_resources.txt
   available_api_resources.txt
```

- This acts as a snapshot of the environment.
- You can feed the results to perform SAST scan using [Kube-linter](https://github.com/stackrox/kube-linter), [kube-score](https://github.com/zegl/kube-score), [checkov](https://github.com/bridgecrewio/checkov), etc.
- Also, using [docker-multi-scan](https://github.com/okpalindrome/docker-multi-scan) you can scan the images using Grype, Trivy and Docker-scout at once.


### Usage
```
$ chmod +x dkube.sh
$ ./dkube.sh          

Usage: ./dkube.sh

Options:
  -d, --dir           Specify the directory to use to store the result.
  -n, --namespace     Specify the namespace to query [optional].
  -h, --help          Display this help message.
```
### Example
```
./dkube.sh -d .
Querying current context's namespace: asteroid-destroyer
Fetching Docker images from various objects...
Found 11 images in deployments...
Found 24 images in pods...
Found 104 images in replicasets...
Total unique images:  57

 Checking resources [176/176]

Total active resources you can query: 17
Completed: ./asteroid-destroyer
```

Note - You can use `dos2unix dkube.sh` for any CRLF errors.

#### Todo
- Scan for misconfigurations (leads) using well-known SAST tools locally to better facilitate the Pentest quickly.