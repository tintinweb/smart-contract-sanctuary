/**
 *Submitted for verification at BscScan.com on 2021-10-08
*/

pragma solidity ^0.8.4;



contract FundHolder {
    
    address payable public Wallet;
    address public owner;
    
    
    event Received(address,uint256);
    
    
    constructor(address payable _owner) {
        owner = msg.sender;
        Wallet = _owner;
    }
    
    
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Not owner");
        _;
    }
    
    
    
    function deposit() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    
    
    function withdrawFunds() external payable onlyOwner{
        uint256 weiBalance = address(this).balance;
        Wallet.transfer(weiBalance);
    }
    
    
    function transferOwnership(address _newOwner) external onlyOwner{
        owner = _newOwner;
    }
    
    
    function setWallet (address payable _Wallet) external onlyOwner {
        Wallet = _Wallet;
    }
    
}