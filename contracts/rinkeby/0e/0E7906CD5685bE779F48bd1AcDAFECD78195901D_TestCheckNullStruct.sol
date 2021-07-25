/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

pragma solidity ^0.5.10;

contract TestCheckNullStruct{
    
    struct User{
        uint name;
        bool isUsed;
    }
    
    mapping(address => User) users;
    mapping(uint => address) addresses;
    
    constructor() public {
      users[msg.sender] = User({
        name: 1,
        isUsed: true
      });
    }

    function isExistEntry(address _addr) public view returns(bool){
        return users[_addr].isUsed;
    }
    
    function isExistAddress(uint _key) public view returns(bool){
        return addresses[_key] != address(0);
    }
}