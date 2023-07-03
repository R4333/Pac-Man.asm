# Pac-Man.asm
A Pac-Man Game in NASM x86 Assembly.


# Assembling Pacman.asm with NASM in DOSBox

This guide will walk you through the process of assembling a file named `pacman.asm` using NASM in DOSBox.

## Prerequisites

Before you begin, make sure you have the following installed:

- [DOSBox](https://www.dosbox.com/download.php)
- [NASM](https://www.nasm.us/)

## Step 1: Set up DOSBox

1. Install DOSBox on your system if you haven't already.
2. Launch DOSBox.

## Step 2: Create a project directory

1. Create a new directory for your project.
2. Place the `pacman.asm` file in this directory.

## Step 3: Mount the project directory in DOSBox

1. In DOSBox, type the following command to view the current mounted drives:

```mount```


Note the drive letters currently in use.

2. Mount your project directory as a new drive letter. Replace `C:\path\to\project` with the actual path to your project directory:

```mount X C:\path\to\project```


The project directory should now be accessible as the X drive in DOSBox.

## Step 4: Assemble the file

1. In DOSBox, change to the X drive:

```X:/```


2. Use NASM to assemble the `pacman.asm` file. Assuming you have NASM installed and added to your system's PATH, run the following command:

```nasm pacman.asm -o pacman.com```


This command will generate the `pacman.com` executable.

## Step 6: Run the Pacman game

1. Once the assembling process is complete, you can run the Pacman game by typing:

```pacman.com```




The game should now start running in DOSBox.

Congratulations! You have successfully assembled and run the Pacman game using NASM in DOSBox.

## Additional Resources

- [NASM Documentation](https://www.nasm.us/doc/)
- [DOSBox Documentation](https://www.dosbox.com/wiki/Main_Page)






