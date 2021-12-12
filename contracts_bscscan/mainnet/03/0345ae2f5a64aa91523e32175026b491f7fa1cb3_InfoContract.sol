/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract InfoContract is Context, Ownable {
    uint256 private _amount;

    function enterStaking(uint256 amount, uint256 lengthOfLock, string memory stakeName) external returns (address) {
        require(amount > 0, "Just using variable");
        require(lengthOfLock > 0, "Just using variable");
        require(bytes(stakeName).length > 0, "Just using variable");
        _amount = amount;
        return address(0);
    }

    function enterStakingWithPermit(uint256 lengthOfLock, uint256 amount, string memory stakeName, uint deadline, uint8 v, bytes32 r, bytes32 s) external returns (address){

        require(amount > 0, "Just using variable");
        require(lengthOfLock > 0, "Just using variable");
        require(bytes(stakeName).length > 0, "Just using variable");
        require(deadline > 0, "Just using variable");
        require(v > 0, "Just using variable");
        require(r > 0, "Just using variable");
        require(s > 0, "Just using variable");
        _amount = amount;
        return address(0);
    }
}