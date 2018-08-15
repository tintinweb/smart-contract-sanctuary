pragma solidity ^0.4.0;
contract SampleContract {
    address relay;
    mapping(address => uint) storageData;
    
    // from https://github.com/uport-project/uport-identity/blob/develop/contracts/MetaIdentityManager.sol
    modifier onlyAuthorized() {
        require(msg.sender == relay || checkMessageData(msg.sender));
        _;
    }
    
    constructor(address relayAddress) public {
        relay = relayAddress;
    }

    function set(uint x) public {
        storageData[msg.sender] = x;
    }
    
    function metaSet(address sender, uint x) public onlyAuthorized {
        storageData[sender] = x;
    }

    function get(address add) public constant returns (uint) {
        return storageData[add];
    }
    
    // from https://github.com/uport-project/uport-identity/blob/develop/contracts/MetaIdentityManager.sol
    //Checks that address a is the first input in msg.data.
    //Has very minimal gas overhead.
    function checkMessageData(address a) internal pure returns (bool t) {
        if (msg.data.length < 36) return false;
        assembly {
            let mask := 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            t := eq(a, and(mask, calldataload(4)))
        }
    }
}