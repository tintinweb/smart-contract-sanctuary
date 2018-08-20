pragma solidity ^0.4.24;

contract Hope {
    address public owner;
    uint256 public endDate;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    event newDate (uint256 date);
    
    constructor (uint256 _endDate) {
        owner = msg.sender;
        endDate = _endDate;
    }
    
    function changeEndDate (uint256 _endDate) onlyOwner {
        endDate = _endDate;    
    }
    
    function insertDate (uint256 date) onlyOwner {
        emit newDate(date);
    }
}