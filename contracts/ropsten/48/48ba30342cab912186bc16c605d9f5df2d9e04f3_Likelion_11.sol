/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

// Seo sangcheol

pragma solidity 0.8.1;

contract Likelion_11 {
    
    string[] member = ['Ava','Becky','Devy','Elice','Fabian'];
    
    function add(string memory _add) public returns(uint,uint) {
        member.push(_add);
        return (member.length, 10-member.length);
    }
    
    
    function find(string memory _find) public returns(string memory) {
        uint i;
        for(uint i=0; i<member.length; i++) {
}                return (member[i]);
    } 
}