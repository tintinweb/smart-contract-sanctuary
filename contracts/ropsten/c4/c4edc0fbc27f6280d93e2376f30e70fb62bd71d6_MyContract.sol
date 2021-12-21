/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

pragma solidity >=0.8.0;

contract MyContract {
    struct newsfeed{  
        address publisher;  
        string newsdesc;  
    }  
    mapping(uint => newsfeed) public newsfeeds;  
    uint public newsCount;  
  
    function addnews(string memory newsdesc) public {  
        newsCount++;  
        newsfeeds[newsCount].publisher = msg.sender;  
        newsfeeds[newsCount].newsdesc = newsdesc;  
  
    }  
}