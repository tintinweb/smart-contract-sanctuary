/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ThomasMore {
    
    address public owner;
    
    uint public nrOfDiplomas;
    
    mapping(address => Diploma) public diplomas;
    
    struct Diploma {
        uint score;
        string name;
    }
    
    constructor() { //Only runs on deployment
        nrOfDiplomas = 0;
        owner = msg.sender; //Deployer is owner
    }
    
    function mintDiploma(address studentAddress, string memory studentName, uint studentScore) public { //uint automatically gets put in memory
        require(owner == msg.sender, "Only the owner can mint diplomas");
        require(diplomas[studentAddress].score == 0, "Can only mint one diploma per student");
        
        diplomas[studentAddress] = Diploma(studentScore, studentName);
        
        nrOfDiplomas++;
    }
    
    function getMyDiploma(address studentKey) external view returns (Diploma memory) {
        return diplomas[studentKey];
    }
}