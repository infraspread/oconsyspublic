# oconsys public repo

## Rustdesk Server Install
curl -fsSL https://raw.githubusercontent.com/infraspread/oconsyspublic/main/rustdesk_server_install.sh -o ~/rustdesk_server_install.sh; chmod +x ~/rustdesk_server_install.sh; ~/rustdesk_server_install.sh

## asciinema v3
curl -fsSL https://raw.githubusercontent.com/infraspread/oconsyspublic/main/asciinema -o /usr/bin/asciinema; chmod +x /usr/bin/asciinema

## Matrix Setup
curl -fsSL https://raw.githubusercontent.com/infraspread/oconsyspublic/main/matrix.sh -o ~/matrix.sh; cd ~; bash matrix.sh
curl -fsSL https://raw.githubusercontent.com/infraspread/oconsyspublic/main/install_matrix_debian_rc.sh -o ~/install_matrix_debian_rc.sh; cd ~; chmod +x install_matrix_debian_rc.sh; ./install_matrix_debian_rc.sh

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



