/**
 *Submitted for verification at polygonscan.com on 2021-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {

    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock() public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + 183 days;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "BEP20: locked");
        require(block.timestamp > _lockTime , "BEP20: locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract Dopey_Distributor is Context, Ownable {
    
    
    
    function distribute(address token, address[] calldata recipients, uint256 amount) public onlyOwner() {
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20(token).transfer(recipients[i], amount);
        }
    }
 
    function zzZendTokens(address token) public onlyOwner() {
        uint256 tokens = checkTokenBalance(token);
        IERC20(token).transfer(owner(), tokens);
    }
    
    function checkTokenBalance(address token) public view returns(uint256 balance){
        balance = IERC20(token).balanceOf(address(this));
        return balance;
    }
}