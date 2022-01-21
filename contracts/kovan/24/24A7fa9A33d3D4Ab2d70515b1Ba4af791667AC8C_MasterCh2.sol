/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// Create a frontend with this interface for students submit their solutions
interface iMasterCh2 {
    function solutions(uint256) external returns (address);
    function ownerIndex(address) external returns (uint256);
    function addSolution (address) external returns (bool);
}


// Master code
interface iChallenge2 {
    function difference(uint256 original) external returns (uint8);
}

contract MasterCh2 {
    
    address[] public solutions;
    mapping(address => uint256) public ownerIndex;

    function addSolution (address scSolution) external returns (bool) {
        _addSolution (msg.sender, scSolution);
        return true;
    }
    
    function _addSolution (address scOwner, address scSolutionAddress) private returns (bool) {

        iChallenge2 scSolution = iChallenge2(scSolutionAddress);
        uint256 anyNumber = 123456789;  //we can use VRF to get a random number here         
        require ((scSolution.difference(anyNumber) < 10), "wrong solution");
        
        //Only owner's sc can add
        //require (scSolution.owner() == scOwner, "only sc owner");

        if (ownerIndex[scOwner] > 0) {
            solutions[ownerIndex[scOwner]] = scSolutionAddress;
        }
        else {
            solutions.push(scSolutionAddress);
            uint256 index = solutions.length;    //Attention: real location is index-1!
            ownerIndex[scOwner] = index;
        }

        return true;
    }

    function countSolutions () public view returns (uint) {
        return (solutions.length);
    }

    address[] private auxList;
    function listSolutions (uint256 from, uint256 to) public returns (address[] memory) {
        delete auxList;

        for(uint256 i=from; i<=to; i++) {
            auxList.push(solutions[i-1]);
        }
        return auxList;
    }
    
}