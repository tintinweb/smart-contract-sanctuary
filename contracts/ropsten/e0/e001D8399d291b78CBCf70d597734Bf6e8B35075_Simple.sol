/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity ^0.8;

contract Simple {
    
    
    uint256 public number;
    
    struct Card {
        uint256 id;
        string name;
    }
    
    //Card public levi = Card({id: 1,name: "levi"});
    
    Card[] public card;
    mapping(string => uint256) public IdtoName;
    
    function store(uint256 n) public {
        number = n;
    }
    
    function addCards(string memory _name,uint256 _id) public {
        card.push(Card(_id,_name));
        IdtoName[_name] = _id;
        
    }
}