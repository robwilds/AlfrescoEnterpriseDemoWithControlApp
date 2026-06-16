#!/bin/bash

# Function to display the menu
display_menu() {
    echo "--------------------------"
    echo "       MAIN MENU        "
    echo "--------------------------"
    echo "1. Start"
    echo "2. Start Fresh"
    echo "3. Stop"
    echo "4. Stop and Backup"
    echo "5. Down"
    echo "6. install amps and jars and restart content and share"
    echo "7. restart"
    echo "8. pull all images"
    echo "9. Exit"
    echo "--------------------------"
}

#get to the main tools directory
cd ./tools

# Main loop for the menu
while true; do
    display_menu
    read -p "Enter your choice (1-9): " choice

    case $choice in
        1)
            echo "Starting up...."
            # Add commands for Option One here
            ./start.sh
            ;;
        2)
            echo "Clearing out db and content folders and restoring from zip..."
            # Add commands for Option Two here
            ./stop.sh;./clearFolders.sh;./start.sh
            ;;
        3)  echo "stopping containers"
            ./stop.sh
            ;;
        4)
            echo "Stopping and backing up to zip..."
            # Add commands for Option Three here
            ./stop_and_backup.sh
            ;;
        5)
            echo "Downing all containers"
            ./down.sh
            ;;
        6)
            echo "Installing amps and jars..."
            ./install_amps_and_jars.sh
            ;;

        7)
            echo "restarting containers..."
            ./restart.sh
            ;;
        8)
            echo "Pulling all Images..."
            ./pullAll.sh
            ;;
        9)
            echo "Exiting the script. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter a number between 1 and 9."
            ;;
    esac
    echo # Add a blank line for readability
done
