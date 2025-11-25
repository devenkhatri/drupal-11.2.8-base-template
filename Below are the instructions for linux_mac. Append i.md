## 9. Hosts File (Optional)

### For Linux/macOS

```bash
sudo nano /etc/hosts

# Add the following lines:

127.0.0.1 drupal.localhost
127.0.0.1 pma.localhost
127.0.0.1 mail.localhost
```


### For Windows

1. Open **Notepad** as Administrator:
    - Click the **Start** button.
    - Type **Notepad** in the search bar.
    - Right-click on **Notepad** and select **Run as administrator**.
    - Confirm any User Account Control prompts.
2. In Notepad, open the hosts file:
    - Go to **File > Open**.
    - Navigate to `C:\Windows\System32\drivers\etc`.
    - If you do not see any files, change the file type filter from "Text Documents (*.txt)" to **All Files (*.*)**.
    - Select the file named **hosts** and open it.
3. Add these lines at the end of the file:
```
127.0.0.1 drupal.localhost
127.0.0.1 pma.localhost
127.0.0.1 mail.localhost
```

4. Save the file and close Notepad.
5. Flush the DNS cache to apply changes:
    - Open the **Command Prompt** (search for "cmd" and run normally).
    - Run the command:

```
ipconfig /flushdns
```


This will ensure your system resolves these hostnames locally to 127.0.0.1 for your Docker containers.[^1][^4][^6][^7]
<span style="display:none">[^2][^3][^5][^8][^9]</span>

<div align="center">⁂</div>

[^1]: https://docs.rackspace.com/docs/modify-your-hosts-file

[^2]: https://www.youtube.com/watch?v=wA_JI-SeKXM

[^3]: https://learn.microsoft.com/en-us/answers/questions/3764615/editing-and-saving-the-hosts-file

[^4]: https://world.siteground.com/kb/hosts-file/

[^5]: https://www.knownhost.com/blog/how-to-view-a-hosts-file-location-edit/

[^6]: https://www.liquidweb.com/blog/edit-host-file-windows-10/

[^7]: https://www.hostinger.com/in/tutorials/how-to-edit-hosts-file

[^8]: https://www.youtube.com/watch?v=yRyUI9vrd6Q

[^9]: https://hostsfileeditor.com

