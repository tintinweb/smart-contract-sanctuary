/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface Token {
    function previousOwner() external view returns (address);
    function transferOwnership(address addr)  external;
    function getUnlockTime() external view returns(uint256);
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    
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


contract OwnershipLocker is Context, Ownable {
    
    uint256 public unlockFee = 1 ether;
    
    function updateUnlockFee(uint256 weiAmount) external onlyOwner{
        unlockFee = weiAmount;
    }
    
    function checkUnlockTime(Token contractAddress) public view returns(uint256){
        return contractAddress.getUnlockTime();
    }
    
    function checkPreviousOwner(Token contractAddress) public view returns(address) {
        return contractAddress.previousOwner();
    }
    
    function unlockContract(Token contractAddress) public payable{
        require(msg.value == unlockFee, 'Unlock fee is 1 ETH');
        address _lastOwner = contractAddress.previousOwner();
        uint256 _unlockTime = contractAddress.getUnlockTime();
        require(_lastOwner == msg.sender, 'You are not the last owner');
        require(_unlockTime >= block.timestamp ,'You must wait the unlock time');
        contractAddress.transferOwnership(msg.sender);
    }
    
    function withdraw() external onlyOwner{
        address payable wallet = payable(msg.sender);
        wallet.transfer(address(this).balance);
    }
    
}