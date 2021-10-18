/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

pragma solidity >=0.5.0 <0.6.0;

contract Smecherometru {
 
    function areSauNuSmecherometru(string memory _name) public view returns(string memory) {
	string memory smecher = "Are";
	string memory nesmecher = "Nu Are"; 
        if(keccak256(abi.encodePacked(_name))==keccak256(abi.encodePacked('Dragos')) || keccak256(abi.encodePacked(_name))==keccak256(abi.encodePacked('Teo'))) return "Are";
        else return "Nu are";
    } 
    

}