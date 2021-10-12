/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract WhaleNetworkPartner is Context, Ownable {
    uint256 private _taxFee;
    uint256 private _burnFee;
    uint256 private _serviceFee;
    uint256 private _partnerShare;
    bool private _isInitialized = false;
    constructor() {

    }

    function taxFee() public view returns(uint256){
        return _taxFee;
    }
    function burnFee() public view returns(uint256){
        return _burnFee;
    }
    function serviceFee() public view returns(uint256){
        return _serviceFee;
    }
    function partnerShare() public view returns(uint256){
        return _partnerShare;
    }
    
    function init(uint256 tax, uint256 burn, uint256 service, uint256 partner) onlyOwner() external returns(bool){
        require(!_isInitialized, "WhaleNetworkPartner: Contract is already initialized.");
        _taxFee = tax;
        _burnFee = burn;
        _serviceFee = service;
        _partnerShare = partner;
        _isInitialized = true;
        return _isInitialized;
    }
}