# Rename Sole User
**Purpose:** Rename the single user you have and migrate their home folder.
1) Sign in to the sole user
2) Create a temp user
```shell
sudo adduser tmp
sudo usermod -aG sudo tmp
# enter a password, then spam enter throught the prompts
```
3) Logout of the sole user and log into to the `temp user`
```shell
logout
# or
exit
```
_If using ssh_
```shell
ssh tmp@yourhost
```
4) Rename the old user and move their home folder
```shell
export OLD_USER="mj"
export NEW_USER="monjia"
# kill all processes the old user is running
sudo pkill -9 -u $OLD_USER
sudo usermod -l $NEW_USER -d /home/$NEW_USER -m $OLD_USER
sudo groupmod -n $NEW_USER $OLD_USER
sudo usermod -c "$NEW_USER" $NEW_USER
```

5) Remove `tmp` user
```shell
sudo pkill -9 -u tmp
sudo deluser --remove-home tmp
```

6) Verify all is correct
```shell
tail -n 5 /etc/passwd
ls /home
```
