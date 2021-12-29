/**
 *Submitted for verification at polygonscan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract news {
    struct newsfeed {
        address publisher;
        string newsdesc;
    }
    uint public newscount;
    mapping(uint => newsfeed) public newsfeeds;
    
    function addnews(string memory desc) public{
       newscount++;
       newsfeeds[newscount].publisher= msg.sender;
       newsfeeds[newscount].newsdesc=desc;
    }
}