/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: IToken

// import needed contracts if any
interface IToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _address) external view returns (uint256);

    function transferFrom(
        address sender,
        address receiver,
        uint256 amount
    ) external;
}

// File: simple_lottery.sol

// contract
contract SimpleLottery {
    uint256 private _entryFee;
    address private _token;
    address public owner;

    // constructor
    constructor(address token) {
        owner = msg.sender;
        _token = token;
    }

    function setEntryFee(uint256 amount) public {
        require(msg.sender == owner);
        _entryFee = amount;
    }

    function getEntryFee() public view returns (uint256) {
        return _entryFee;
    }

    function getPoolBalance() external view returns (uint256) {
        return IToken(_token).balanceOf(address(this));
    }

    function getTokenTotalSupply() external view returns (uint256) {
        return IToken(_token).totalSupply();
    }

    function getTokenBalance() external view returns (uint256) {
        return IToken(_token).balanceOf(msg.sender);
    }

    function enter() public payable {
        IToken(_token).transferFrom(msg.sender, address(this), _entryFee);
    }
}