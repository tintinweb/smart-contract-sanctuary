pragma solidity ^0.4.0;
contract SampleContract {
    mapping(address => uint) storageData;
    function set(uint x) public {
        storageData[msg.sender] = x;
    }
    function get(address add) public constant returns (uint) {
        return storageData[add];
    }
}