// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Patronage} from "Patronage.sol";

contract PatronageFactory {
    address[] public projects;

    event NewProject(address);

    constructor() {}

    function createProject(string memory title) public {
        Patronage newProject = new Patronage(msg.sender, title);
        projects.push(address(newProject));
        emit NewProject(address(newProject));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Patronage {
    string public title;
    address public owner;
    mapping(uint16 => mapping(address => uint256)) public patreons;
    uint16 public epoch;

    constructor(address _owner, string memory _title) {
        owner = _owner;
        title = _title;
    }

    function fund() external payable {
        require(msg.value >= 10**15, "Value below minimum funding threshold!");
        patreons[epoch][msg.sender] += msg.value;
    }

    // function withdraw(uint256 amount) external {
    //     uint256 balance = patreons[msg.sender];
    //     require(balance >= amount, "Amount higher than current balance!");
    //     msg.sender.transfer(amount);
    //     patreons[msg.sender] -= amount;
    // }

    function payOut() external payable {
        require(msg.sender == owner, "Can only be called by owner");
        epoch++;
        payable(msg.sender).transfer(address(this).balance);
    }
}