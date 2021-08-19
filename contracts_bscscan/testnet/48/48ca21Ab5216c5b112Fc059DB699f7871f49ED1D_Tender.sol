/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

//SPDX-licence-identifier = GNU 3.0
//Author = Samed Kahyaoglu
//GitHub = urtuba

pragma solidity >= 0.4.0 < 0.6.0;

contract TenderLib {
    /* 
        uint have to be converted to string for concatenation
    */
    function uint2str(uint _number) internal pure returns (string memory _str) {
        if (_number == 0) { return "0"; }
        
        uint j = _number;
        uint len;
        
        while (j != 0) {
            len++;
            j /= 10;
        }
        
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_number != 0) {
            bstr[k--] = byte(uint8(48 + _number % 10));
            _number /= 10;
        }
        return string(bstr);
    }
}

contract TenderTimer {
    uint public t1;    // when tender ends, bid verification starts
    uint public t2;    // when verification ends
    
    function _timerInitializer (uint _period1, uint _period2) internal {
        /*
            _period1: period of accepting bids in days
            _period2: period of verifiying bids in days
        */
        uint secondsInHour = 3600;
        t1 = now + _period1 * secondsInHour;
        t2 = t1  + _period2 * secondsInHour;
    }
    
    function _bidTimeCheck () internal view returns (bool) {
        require (now < t1);
        return true;
    }
    
    function _validationTimeCheck () internal view returns (bool) {
        require ((t1 < now) && (now < t2));
        return true;
    }
    
    function _endTimeCheck () internal view returns (bool) {
        require (t2 < now);
        return true;
    }
}

contract TenderData is TenderTimer, TenderLib {
    /* 
        The contract to match bid hashes to valid addresses.
        Keeps of which EOA started tender, who is owner.
            tenderHash is stored to verify tender is valid,
            bidHashes is stored to verify bids are valid,
    */
    address public owner;
    bytes32 public tenderHash;
    mapping (address => bytes32) public bidHashes;
    
    event Print (bytes data);
    
    function _tenderIntializer (bytes32 _tenderHash) internal {
        tenderHash = _tenderHash;
        owner = msg.sender;
    }
    
    function _makeBid (bytes32 _bidHash) internal {
        _bidTimeCheck();
        bidHashes[msg.sender] = _bidHash;
    }
    
    function _isBidValid(uint _bidValue, string memory _randomStr) internal view returns (bool) {
        /* 
            If the bid exists and matches with the hash,
            the function stops in reqular way,
            otherwise function call is reverted.
        */
        require (bidHashes[msg.sender] != 0);               // bid exists
        _validationTimeCheck();                             // time is appropriate
        
        bytes memory str = abi.encodePacked(uint2str(_bidValue), _randomStr);
        require(keccak256(str) == bidHashes[msg.sender]);   // the hash matches with the bid
        
        return true;
    }
    
    function _isTenderValid(uint _min, uint _max, uint _est, string memory _randomStr) internal returns (bool) {
        require (msg.sender == owner);
        _endTimeCheck();
        
        bytes memory str = abi.encodePacked(uint2str(_est), "+", uint2str(_min), "+", uint2str(_max), _randomStr);
        emit Print(str);
        require (keccak256(str) == tenderHash);
        
        return true;
    }
}
contract Tender is TenderData {
    /* 
        Tender is actual contract to interact with.
        It delegates controls, functions and storing hashes to
        other contracts. It is responsible to determine the winner.
    */
    bool public finished = false;
    
    uint public estimated;
    uint public minimum;
    uint public maximum;
    
    mapping (address => uint) public bids;
    uint bestBid = 2**256 - 1;
    address winner;
    
    event NewBid(address bidder, bytes32 hash);
    event BidUpdate(address bidder, bytes32 hash);
    event BidValidation(address bidder, uint amount);
    event TenderEnded(uint min, uint max, uint est);
    
    constructor (bytes32 _tenderHash, uint _openDays, uint _validationDays) public {
        _tenderIntializer(_tenderHash);
        _timerInitializer(_openDays, _validationDays);
    }
    
    function makeBid (bytes32 _bidHash) public {
        require (msg.sender != owner);
        require (bidHashes[msg.sender] == 0);
        _makeBid(_bidHash);
        emit NewBid(msg.sender, _bidHash);
    }
    
    function updateBid (bytes32 _bidHash) public {
        require(bidHashes[msg.sender] != 0);
        _makeBid(_bidHash);
        emit BidUpdate(msg.sender, _bidHash);
    }
    
    function validateBid (uint _bidValue, string memory _randomStr) public returns (bool) {
        /* 
            Returns True if the bid is revealed without any error.
            Otherwise transaction is reverted.
        */
        _isBidValid(_bidValue, _randomStr);
        
        bids[msg.sender] = _bidValue;
        
        if(_bidValue < bestBid) {
            bestBid = _bidValue;
            winner = msg.sender;
        }
        
        emit BidValidation(msg.sender, _bidValue);
        return true;
    }
    
    function endTender (uint _min, uint _max, uint _est, string memory _randomStr) public returns (bool) {
        _isTenderValid(_min, _max, _est, _randomStr);
        
        finished    = true;
        minimum     = _min;
        maximum     = _max;
        estimated   = _est;
        
        emit TenderEnded(_min, _max, _est);
        return true;
    }
    
    function getWinner () public view returns (address) {
        require (finished);
        require ((bestBid <= maximum) && (bestBid >= minimum));
        return winner;
    }
}