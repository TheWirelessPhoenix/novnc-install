# noVNC + TigerVNC + i3 + Nginx Reverse Proxy + HTTP Basic Auth Installer

> A streamlined setup for a remote desktop environment on your Ubuntu server (and other Debian based like Kali linux).

This script combines the power of **TigerVNC**, **noVNC**, and **i3**, with an optional, secure **Nginx** reverse proxy powered by **Let's Encrypt** SSL certificates, to create a fully functional remote desktop environment.

## ✨ Features

*   **Effortless Installation:** Automates the installation and configuration of TigerVNC, noVNC, and the lightweight i3 window manager.
*   **Secure Access:** Optionally configures an Nginx reverse proxy with automatic SSL certificate generation and renewal via Let's Encrypt.
*   **HTTP Basic Authentication:** Provides an extra layer of security with optional HTTP Basic Authentication for your reverse proxy.
*   **Customizable:** Allows you to specify the VNC user, ports, display number, and hostname during setup.
*   **Troubleshooting Utilities:** Offers functions to help fix common Nginx configuration issues and reinstall the reverse proxy setup if needed.

## 🚀 Quick Start

    git clone https://github.com/vtstv/novnc-install.git && cd novnc-install && chmod +x novnc-install.sh && sudo ./novnc-install.sh


## 🛠️ Usage

The script provides an interactive menu to guide you through the installation and configuration process. You can choose to:

1. Install noVNC with TigerVNC and i3.
2. Configure an Nginx reverse proxy with Let's Encrypt SSL.
3. Fix common Nginx configuration problems.
4. Reinstall the Nginx reverse proxy setup.

## An example of Kali linux running in the AWS cloud:

<img src="https://github.com/user-attachments/assets/895f3f5d-1def-42a8-a056-596769f37418" style="width:80%;">


## 🔒 Security Note

**Always** use strong and unique passwords for your VNC user and HTTP Basic Authentication.

## 🤝 Contribution

Contributions are welcome! Feel free to contribute to this project by submitting pull requests or reporting issues on the [GitHub repository](https://github.com/vtstv/novnc-install).

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <strong>Enjoy your new remote desktop!</strong> ✨
</p>
