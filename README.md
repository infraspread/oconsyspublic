# oconsys public repo

## Matrix Setup
curl -fsSL https://raw.githubusercontent.com/infraspread/oconsyspublic/main/matrix.sh -o ~/matrix.sh; cd ~; bash matrix.sh

## Profile
curl -fsSL https://raw.githubusercontent.com/infraspread/oconsyspublic/main/.bashrc -o ~/.bashrc; source ~/.bashrc

## Docker Setup
curl -fsSL https://raw.githubusercontent.com/infraspread/oconsyspublic/main/docker_setup.sh -o docker_setup.sh ; chmod +x docker_setup.sh ; ./docker_setup.sh

* Rustdesk Github Nightly Downloader
Usage
```powershell
irm https://raw.githubusercontent.com/infraspread/oconsyspublic/main/html/rustdesk.ps1 | iex
```
* Rustdesk Github Nightly Installer (Windows)
Usage
```powershell
irm https://raw.githubusercontent.com/infraspread/oconsyspublic/main/html/rustdeskdl_win.ps1 | iex
```



