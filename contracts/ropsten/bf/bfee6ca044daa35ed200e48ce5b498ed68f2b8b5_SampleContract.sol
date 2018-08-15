pragma solidity ^0.4.24;
contract SampleContract {
    mapping(address => uint) storageData;
    function set(uint x) public {
        storageData[msg.sender] = x;
    }
    function get() constant public returns (uint) {
        return storageData[msg.sender];
    }
}