/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
 
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor () internal {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

contract DiscreetError is Ownable {
    receive() external payable {}
    
    function weiBalance() public view returns(uint256) {
        return address(this).balance;
    }
    function claim() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}