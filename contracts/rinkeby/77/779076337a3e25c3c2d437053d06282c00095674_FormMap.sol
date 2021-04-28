/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.4.21;


contract FormMap {
    address internal admin;
   
    mapping(address => string) map;

    event GetForm(address _from, string _content);
   
    function FormMap () public {
        admin = msg.sender;
    }

    function Add(string content) public returns (bool){
        map[msg.sender] = content;
        return true;
    }
    
    function Get() public returns (string){
        emit GetForm(msg.sender, map[msg.sender]);
        return map[msg.sender];
    }
}