/**
 *Submitted for verification at polygonscan.com on 2021-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract HelloWorld {
    string internal _last_human;

    constructor(string memory name){
        require(bytes(name).length > 0,"whoooooooooooooo are you ?!");
        _last_human = name;
    }

    event Shaked(string last,string next);

    function shake(string calldata who_are_you) public payable returns(string memory){

        require(bytes(who_are_you).length < 1,"tell me who are you.");

        require(keccak256(bytes(who_are_you)) != keccak256(bytes(_last_human)),"snake eat there tails.");

        string memory retmsg = string(abi.encodePacked('Hello,' , who_are_you , ' ! I am ' , _last_human));

        emit Shaked(_last_human,who_are_you);

        _last_human = who_are_you;

        return retmsg;
    }
}