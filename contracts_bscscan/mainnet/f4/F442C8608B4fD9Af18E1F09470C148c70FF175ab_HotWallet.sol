/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-21
*/

pragma solidity ^0.8.4;
//SPDX-License-Identifier: UNLICENSED
//Hotwallet code

contract HotWallet
{
    address owner;
    
    address  Readdresses;
    uint256 goal;
    
    modifier onlyOwner()
    {
        require(msg.sender == owner, "msg.sender is not the owner!");
        _;
    }
    
    constructor(address  _addresses,  uint256 _goal) 
    {
        owner = msg.sender;
        
        Readdresses = _addresses;
        goal = _goal;
    }
    
    receive() payable external {
        uint256 balance = address(this).balance;
        if(balance >= goal)
        {
            payable(Readdresses).transfer(balance );
        }
    }
    
    //////////////////
    // Owner functions
    
    function setAddresses(address  _addresses) external onlyOwner
    {

        Readdresses = _addresses;        
    }
    

    
    function setGoal(uint256 _goal) external onlyOwner
    {
        goal = _goal;
    }
    
    function getGoal() public view returns (uint256)
    {
        return (goal);
    }
    
    function getBalance() public view returns (uint256)
    {
        uint256 balance = address(this).balance;
        return (balance);
    }
    
    function withdraw() external onlyOwner
    {
        payable(owner).transfer(address(this).balance);
    }
    
    function setOwner(address _owner) external onlyOwner
    {
        owner = _owner;
    }
}