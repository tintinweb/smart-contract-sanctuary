/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Poll5 {

    string public photoUrl;
    mapping (address => int) votes;
    int ups;
    int downs;
    event report(int _choice, address _addr);

    constructor() {
        photoUrl="first_poll";
        ups=0;
        downs=0;
    }

    function VoteThis (string memory _photoUrl) public {
        photoUrl = _photoUrl;
    }

    function vote (int _choice) public {
        require (votes[msg.sender] != 0, "not a valid address");
        require (_choice == 1 || _choice == -1, "not a valid data");
        votes[msg.sender] = _choice;
        if (_choice == 1) ups++;
        if (_choice == -1) downs++;
        emit report(_choice,msg.sender);
    }

    function getVotes () public view returns (int, int) {
        return (ups, downs);
    }

    function getVote (address _addr) public view returns (int) {
        return votes[_addr];
    }
}