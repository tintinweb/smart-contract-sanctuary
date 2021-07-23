/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity ^0.4.11;
 
contract Mrc{
    string[] pic;
    uint x=0;
    address owner;
    function Mrc(){
        owner = msg.sender;
    }
    function save(string s) public{
        require(msg.sender == owner);
        pic[x]=s;
        x++;
    }
    function getpic(uint i) constant public returns (string){
        require(msg.sender == owner);
        return pic[i];
    }
}