/**
 *Submitted for verification at BscScan.com on 2021-10-08
*/

pragma solidity ^0.8.4;



contract FundHolder {
    
    address payable ownerWallet;
    
    
    constructor(address payable _owner) {
        ownerWallet = _owner;
    }
    
    
    
    
    function withdrawFunds() external payable {
        uint256 weiBalance = address(this).balance;
        ownerWallet.transfer(weiBalance);
    }
    
    function setOwner(address payable _wallet) external {
        ownerWallet = _wallet;
    }
}