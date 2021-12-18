/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: GPL-3.0

// 115792089237316195423570985008687907853269984665640564039457584007913129639935;

pragma solidity >=0.8.0 <0.9.0;

contract Ownable {
    address owner = msg.sender;

    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
}

contract Tippable is Ownable {
    address tipsWithdrawAddress = msg.sender;
    
    event Tipped(address _tipper, uint256 _value);

    function changeTipsWithdrawAddress(address _tipsWithdrawAddress) public onlyOwner {
        tipsWithdrawAddress = _tipsWithdrawAddress;
    }

    function tip() public payable {
        emit Tipped(msg.sender, msg.value);
    }

    function withdrawTips() public onlyOwner {
        payable(tipsWithdrawAddress).transfer(address(this).balance);
    }
}

contract CryptoCalls is Tippable {
    struct Range {
        uint256 lowerBound;
        uint256 upperBound;
    }

    struct Call {
        Range dateRange; 
        Range priceRange;
        bytes32 memo;
        uint256 creationTime;
    }

    struct AddressCalls {
        mapping(uint256 => Call) calls;
        uint256 callsCount;
    }

    mapping(address => AddressCalls) private calls;

    event CallCreated(
        address _caller
    );

    function getCallsCount(address _address) public view returns (uint256) {
        return calls[_address].callsCount;
    }

    function getCall(address _address, uint256 _id) public view returns (Call memory) {
        return calls[_address].calls[_id];
    }

    function makeCall(uint256 _minPrice, uint256 _maxPrice, uint256 _minDate, uint256 _maxDate, bytes32 memo) public payable {
        require(_maxPrice >= _minPrice, "Max price should be greater than min price");
        require(_maxDate >= _minDate, "Max date should be greater than min date.");
        require(_minDate > block.timestamp, "Call date should be in the future.");

        AddressCalls storage addressCalls = calls[msg.sender];
        Call storage call = addressCalls.calls[addressCalls.callsCount];
        call.priceRange.lowerBound = _minPrice;
        call.priceRange.upperBound = _maxPrice;
        call.dateRange.lowerBound = _minDate;
        call.dateRange.upperBound = _maxDate;
        call.memo = memo;
        call.creationTime = block.timestamp;
        addressCalls.callsCount++;

        emit CallCreated(msg.sender);
    }
}