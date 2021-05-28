/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;



// File: UCMIdeas.sol

//pragma experimental ABIEncoderV2;

contract UCMIdeas {

    address owner;

    struct Idea {
        string idea_owner;
        string idea_title;
	string idea_hash;
    }

    mapping(uint256 => Idea) public ideas;

    constructor(){
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public
    {
    	require (msg.sender == owner);
        owner = newOwner;
    }


    function setIdea(uint256 uuid, string memory idea_owner, string memory title, string memory idea_hash) public 
    {
        require(msg.sender == owner);
        ideas[uuid].idea_owner = idea_owner;
        ideas[uuid].idea_title = title;
        ideas[uuid].idea_hash = idea_hash;
    }

    function getIdea(uint256 uuid) public view
        returns (Idea memory idea)
    {
        idea = ideas[uuid];
    }
}