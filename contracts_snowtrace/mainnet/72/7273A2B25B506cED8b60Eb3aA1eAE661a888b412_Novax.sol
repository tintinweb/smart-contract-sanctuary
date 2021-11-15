/**
 *Submitted for verification at snowtrace.io on 2021-11-11
*/

pragma solidity >=0.7.0 <0.9.0;


contract Novax {
   
    address private owner;
    mapping(string => uint256) private params1;
    mapping(string => string) private params2;
    mapping(string => address) private params3;

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address user) onlyOwner public{
        owner = user;
    }
   
    function setParam1(string memory key, uint256 value) onlyOwner public{
        params1[key] = value;
    }
   
    function setParam2(string memory key, string memory value) onlyOwner public{
        params2[key] = value;
    }
   
    function setParam3(string memory key, address value) onlyOwner public{
        params3[key] = value;
    }
   
    //Getters
    function getParam1(string memory key) public view returns (uint256)  {
        return params1[key];
    }
   
    function getParam2(string memory key) public view returns (string memory)  {
        return params2[key];
    }
   
    function getParam3(string memory key) public view returns (address)  {
        return params3[key];
    }
   
    function getOwner() public view returns (address)  {
        return owner;
    }

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
   
}