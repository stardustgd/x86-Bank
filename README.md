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

> [!WARNING]
> This project currently only runs on Windows and has some bugs.

Install dependencies:

- vscode
- [vscode-masm-runner](https://github.com/istareatscreens/vscode-masm-runner)
- jwasm (optional, to avoid using masm-runner)
- jwlink (optional, for manual linking)

Then run:

```shell
.\build.ps1
```
