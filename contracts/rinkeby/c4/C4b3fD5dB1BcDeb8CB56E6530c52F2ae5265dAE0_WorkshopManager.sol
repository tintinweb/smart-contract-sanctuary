// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WorkshopManager {
    string public name = "Intro to ethers.js";
    address public manager;

    constructor() {
        manager = msg.sender;
    }

    //struct for an event//
    struct Workshop {
        string title;
        string author;
    }

    Workshop[] public workshops;

    function printName() public view returns (string memory) {
        return name;
    }

    function add(string calldata title, string calldata author) public {
        Workshop memory workshop = Workshop(title, author);
        workshops.push(workshop);
    }

    function getWorkshops() public view returns (Workshop[] memory) {
        return workshops;
    }
}

