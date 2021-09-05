/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract Ownable {
    address public owner;
    bool public enabled;
    
    constructor() {
        owner = msg.sender;
        enabled = true;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    
    modifier onlyEnabled {
        require(enabled == true, "Sorry, the contract is disabled now");
        _;
    }
    
    function changeOwner(address newOwner) onlyOwner public {
        require(owner != newOwner);
        owner = newOwner;
        require(owner == newOwner);
    }
    
    function changeEnabled(bool _enabled) onlyOwner public {
        require(enabled != _enabled);
        enabled = _enabled;
        require(enabled == _enabled);
    }
}


struct Record {
    uint id;
    address sender;
    string message;
    uint timestamp;
    bool isDonated;
    uint donatedValue;
}

contract OpenBoard is Ownable {
    event NewRecord(Record record);
    
    uint public constant MAX_CAPACITY = 100;
    uint public recordId = 0;
    Record[MAX_CAPACITY] public records;
    uint public historicalDonation = 0;

    function submitMessage(string memory message) onlyEnabled public {
        _record(message);
    }

    function donate(string memory message) onlyEnabled payable public {
        require(msg.value > 0, "Donate nothing");
        
        _record(message);
        historicalDonation += msg.value;
    }
    
    function _record(string memory message) internal {
        uint curIndex = recordId % MAX_CAPACITY;
        records[curIndex] = Record(recordId, msg.sender, message, block.timestamp, msg.value > 0, msg.value);
        recordId += 1;
        
        emit NewRecord(records[curIndex]);
    }
    
    function ownerClaim() onlyOwner public {
        payable(owner).transfer(address(this).balance);
    }
}