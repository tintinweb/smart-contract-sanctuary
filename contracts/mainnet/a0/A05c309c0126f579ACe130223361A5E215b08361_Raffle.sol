/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract Raffle is Ownable {
    receive() external payable {}
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    function raffle(address[] memory addresses) external onlyOwner {
        uint numberOfUsers = addresses.length;
        require(numberOfUsers > 0, "Addresses not passed");
        uint totalBalance = address(this).balance;
        require(totalBalance > 0, "Zero balance in contract");
        uint sharePerOne = totalBalance/numberOfUsers;
        for(uint i = 0; i < numberOfUsers; i++) {
            payable(addresses[i]).transfer(sharePerOne);
        }
    }
}