# Automated Secure Boot Configuration

🚀 **Enable Secure Boot on Arch Linux with Ease!**

This project provides a comprehensive, automated solution for enabling Secure Boot on Arch Linux systems. Whether you're using systemd-boot with GNOME or need dual-boot support with Windows, our state-of-the-art configuration script makes the process simple and secure.

## 🎯 Why Use This Project?

- **Secure**: Protect your system with UEFI Secure Boot
- **Compatible**: Works with systemd-boot and GNOME
- **Dual-Boot Ready**: Seamless Windows integration
- **Automated**: State-of-the-art script handles all configuration
- **Well-Documented**: Comprehensive guides for every step

## 📋 Features

- ✅ **Automated Secure Boot configuration** using state machine architecture
- ✅ **Support for systemd-boot with Unified Kernel Images (UKI)** - modern, recommended approach
- ✅ **Microsoft vendor key enrollment** for Windows compatibility
- ✅ **Automatic re-signing** of updated boot components via pacman hooks
- ✅ **Comprehensive documentation** with step-by-step instructions

## 💻 Requirements

- Arch Linux (or Arch-based distribution) with UEFI support
- Administrative privileges (sudo access)
- UEFI firmware that supports Secure Boot
- For dual-boot setups: Windows installation detected on the system

## 📁 Files Included

- `secure-boot-setup.sh` - Main automation script
- `secure-boot-setup-guide.md` - Comprehensive setup guide
- `windows-usb-issues.md` - Troubleshooting Windows USB input issues
- `README.md` - Project overview and quick start guide
- `LICENSE` - MIT License
- `.gitignore` - Version control exclusions

## 🚀 Quick Start

1. **Install required packages**:
   ```bash
   sudo pacman -S sbctl systemd-ukify
   yay -S shim-signed
   ```

2. **Run the setup script**:
   ```bash
   sudo ./secure-boot-setup.sh
   ```

3. **Follow the on-screen instructions** to complete the setup

4. **Enable Secure Boot** in your UEFI firmware settings

## 📖 Documentation

- [Secure Boot Setup Guide](secure-boot-setup-guide.md) - Detailed instructions
- [Windows USB Issues](windows-usb-issues.md) - Troubleshooting Windows USB input problems

## 🎯 Key Benefits

- **Effortless Setup**: Our script automates the complex configuration process
- **Modern Technology**: Supports the latest Secure Boot standards and UKI
- **Community-Driven**: Open-source with active contributions
- **Professionally Maintained**: Regular updates and improvements

## 🤝 Contributing

Contributions are welcome! Please open issues or submit pull requests to help improve this project.

## 📋 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Thanks to the Arch Linux community for their ongoing support
- Special thanks to the developers of sbctl, systemd-ukify, and shim-signed

## 🌟 Get Started Today!

Join the growing community of users who have secured their Arch Linux systems with our Automated Secure Boot Configuration! 🎉