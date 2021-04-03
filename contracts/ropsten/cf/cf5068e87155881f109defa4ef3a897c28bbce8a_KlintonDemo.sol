/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity >=0.6.0 <0.9.0;

contract KlintonDemo {
    // int number;
    uint256 unsignedNumber;
    // mapping(uint256 => string) map;
    // address addr;
    // mapping(uint256 => address) mapAddress;
    // mapping(address => uint256) mapAddToNum;
    // string name;
    address owner;
    
    // automatically call when deployed
    constructor(uint256 iniValue) public{
        unsignedNumber = iniValue;
        owner = msg.sender;
    }
    
    function add(uint256 value) public {
        require(msg.sender == owner);
        unsignedNumber += value;
    }
    
    function getValue() public view returns (uint256) {
        return unsignedNumber;
    }
}