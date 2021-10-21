/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.8.7;
 
contract CryptoCat {
    uint uniqId;
    uint cost;
    string name;
    address owner;
    
    constructor(uint _cost, string memory _name){
        owner = msg.sender;
        uniqId = uint(keccak256(bytes(_name))) + uint(block.timestamp);
        cost = _cost;
        name = _name;
    }
    
    function setCost(uint _cost)public{
        cost = _cost;
    }
    
    function buy(address _owner)public{
        owner = _owner;
    }
    
    function getInfo()public view returns(address, uint, string memory, uint)
    {
        return (owner, uniqId, name, cost);
    }
    
    function getUniqId()public view returns(uint){
        return uniqId;
    }    
    
    function getName()public view returns(string memory){
        return name;
    }   

    function getCost()public view returns(uint){
        return cost;
    }       
}

contract CryptoCatShop{
    address[] cryptoCats;
    address owner;
string[]  str = new string[](2);

    constructor(){
        owner = msg.sender;
    }
    
    function createCat(uint _cost, string calldata _name)public{
        cryptoCats.push(address(new CryptoCat(_cost, _name)));
    }
    
    function getCryptoCats()public view returns(uint, string memory, uint){
        
    }
    function f()public
    {
        str[0] = "gfd";
        str[1] = "gfdsa";
    }    
    
    function g()public view returns(string[] memory)
    {
        return str;
    }

}