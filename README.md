# x86-Bank

The x86 Bank is a console based banking application that
allows the user to deposit, withdraw, calculate interest,
 show their current balance. This program utilizes a database
in the form of a text file in order to store user credentials.
User's credentials are verified and updated when the user signs
in and when the user performs a withdraw/deposit.

## Contributors

- Sebastian Ala Torre
- Conan Nguyen
- Samuel Segovia
- Austen Bernal
- Bernardo Flores

## Building

> [!NOTE]
> This method of building only works on Windows, if you are using a different operating system, it is recommended to use [vscode-masm-runner](https://github.com/istareatscreens/vscode-masm-runner)

Install dependencies:

- vscode
- vscode-masm-runner

 To avoid using masm-runner:
- jwasm (optional, for compiling and assembling)
- jwlink (optional, for linking)

Then run:

```shell
.\build.ps1
```
