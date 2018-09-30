pragma solidity ^0.4.0;
pragma solidity ^0.4.0;
contract SampleContract {
    uint storageData;
    function set(uint x) public{
        storageData = x;
    }
    function get() public constant returns (uint) {
        return storageData;
    }
}