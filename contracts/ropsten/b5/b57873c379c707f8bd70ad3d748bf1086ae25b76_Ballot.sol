/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: GPL-3.0
// @dev Charlie Perkins
pragma solidity >=0.7.0 <0.9.0;

contract Ballot {
    // Choices
    uint firstChoice = 0;
    uint secondChoice = 0;
    uint thirdChoice = 0;
    uint total = 0;
    // Voters
    mapping (address => bool) private _voted;
    // Fuctions to vote 
    function voteFirst(address id) public {
        require(_voted[id] == false, "User already voted");
        firstChoice++;
        total++;
        _voted[id] = true;
    }
    function voteSecond(address id) public {
        require(_voted[id] == false, "User already voted");
        secondChoice++;
        total++;
        _voted[id] = true;
    }
    function voteThird(address id) public {
        require(_voted[id] == false, "User already voted");
        thirdChoice++;
        total++;
        _voted[id] = true;
    }
    // Functions to get vote counts
    function getFirst() public view returns(uint) {
        return firstChoice;
    }
    function getSecond() public view returns(uint) {
        return secondChoice;
    }
    function getThird() public view returns(uint) {
        return thirdChoice;
    }
    function getTotal() public view returns(uint) {
        return total;
    }
}