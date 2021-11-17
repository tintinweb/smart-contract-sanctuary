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
    
    constructor() {
        nrOfDiplomas = 0;
        owner = msg.sender;
    }
    
    function mintDiploma(address studentAddress, string memory studentName, uint studentScore) public {
        require(owner == msg.sender, "Only owner can mint diplomas");
        require(diplomas[studentAddress].score == 0, "Can only mine one diploma per student");
        diplomas[studentAddress] = Diploma(studentScore, studentName);
        nrOfDiplomas++;
     }
    
    function getMyDiploma(address studentAddress) external view returns (Diploma memory) {
        return diplomas[studentAddress];
    }
    
    
    
}