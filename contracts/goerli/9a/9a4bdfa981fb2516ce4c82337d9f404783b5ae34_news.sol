/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity >=0.4.0 <=0.6.0;  

  contract news{  

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