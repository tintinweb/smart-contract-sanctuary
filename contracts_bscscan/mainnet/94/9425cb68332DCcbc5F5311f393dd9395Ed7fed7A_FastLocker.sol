/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

//"SPDX-License-Identifier: KK"
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract FastLocker is Ownable {
    uint public locked_until;
    
    constructor(uint _locked_until) {
        locked_until = _locked_until;
    }
    
    modifier controlla_tempo {
        require(block.timestamp > locked_until,"You cannot withdraw yet. (Time)");
        require(msg.sender == owner(),"Not owner");
        _;
    }

    function updateLock(uint _newTime) external onlyOwner {
        require(locked_until <= _newTime,"new date cannot be in the past");
        locked_until = _newTime;
    } 
    
    function Withdraw(address Token, uint amount) external controlla_tempo {
        uint256 balance = BEP20(Token).balanceOf(address(this));
        require(balance > 0,"you have 0 of this.");
		require(BEP20(Token).transfer(owner(), amount),"transfer error");
    }
}
abstract contract BEP20 {
    function balanceOf(address tokenOwner) virtual external view returns (uint256);
    function transfer(address receiver, uint256 numTokens) virtual public returns (bool);
}