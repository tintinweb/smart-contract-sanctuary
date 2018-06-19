pragma solidity ^0.4.13;

contract Prover {
    
    struct Entry {
        bool exists;
        uint256 time;
        uint256 value;
    }
    
    // {address: {dataHash1: Entry1, dataHash2: Entry2, ...}, ...}
    mapping (address => mapping (bytes32 => Entry)) public ledger;
    
    // public functions for adding and deleting entries
    function addEntry(bytes32 dataHash) payable {
        _addEntry(dataHash);
    }
    function addEntry(string dataString) payable {
        _addEntry(sha3(dataString));
    }
    function deleteEntry(bytes32 dataHash) {
        _deleteEntry(dataHash);
    }
    function deleteEntry(string dataString) {
        _deleteEntry(sha3(dataString));
    }
    
    // internals for adding and deleting entries
    function _addEntry(bytes32 dataHash) internal {
        // check that the entry doesn&#39;t exist
        assert(!ledger[msg.sender][dataHash].exists);
        // initialize values
        ledger[msg.sender][dataHash].exists = true;
        ledger[msg.sender][dataHash].time = now;
        ledger[msg.sender][dataHash].value = msg.value;
    }
    function _deleteEntry(bytes32 dataHash) internal {
        // check that the entry exists
        assert(ledger[msg.sender][dataHash].exists);
        uint256 rebate = ledger[msg.sender][dataHash].value;
        delete ledger[msg.sender][dataHash];
        if (rebate > 0) {
            msg.sender.transfer(rebate);
        }
    }
    
    // prove functions
    function proveIt(address claimant, bytes32 dataHash) constant
            returns (bool proved, uint256 time, uint256 value) {
        return status(claimant, dataHash);
    }
    function proveIt(address claimant, string dataString) constant
            returns (bool proved, uint256 time, uint256 value) {
        // compute hash of the string
        return status(claimant, sha3(dataString));
    }
    function proveIt(bytes32 dataHash) constant
            returns (bool proved, uint256 time, uint256 value) {
        return status(msg.sender, dataHash);
    }
    function proveIt(string dataString) constant
            returns (bool proved, uint256 time, uint256 value) {
        // compute hash of the string
        return status(msg.sender, sha3(dataString));
    }
    
    // internal for returning status of arbitrary entries
    function status(address claimant, bytes32 dataHash) internal constant
            returns (bool, uint256, uint256) {
        // if entry exists
        if (ledger[claimant][dataHash].exists) {
            return (true, ledger[claimant][dataHash].time,
                    ledger[claimant][dataHash].value);
        }
        else {
            return (false, 0, 0);
        }
    }

    // raw eth transactions will be returned
    function () {
        revert();
    }
    
}