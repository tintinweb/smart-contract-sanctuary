/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

pragma solidity ^0.8.4;
//SPDX-License-Identifier: UNLICENSED


contract FluxCapacitor
{
    address owner;
    
    address[] addresses;
    uint256[] valuesInPercent;
    uint256 goal;
    
    modifier onlyOwner()
    {
        require(msg.sender == owner, "msg.sender is not the owner!");
        _;
    }
    
    constructor(address[] memory _addresses, uint256[] memory _valuesInPercent, uint256 _goal) 
    {
        require(_addresses.length == 2);
        require(_valuesInPercent.length == 2);
        require(_valuesInPercent[0] + _valuesInPercent[1] == 100);
        
        owner = msg.sender;
        
        addresses = _addresses;
        valuesInPercent = _valuesInPercent;
        goal = _goal;
    }
    
    receive() payable external {
        uint256 balance = address(this).balance;
        if(balance >= goal)
        {
            for(uint256 i=0;i<addresses.length;i++)
            {
                (bool success, ) = payable(addresses[i]).call{value: balance * valuesInPercent[i] / 100}("");
                require(success, "Failed");
            }    
        }
    }
    
    //////////////////
    // Owner functions
    
    function setAddresses(address[] memory _addresses) external onlyOwner
    {
        require(_addresses.length == 2);
        
        addresses = _addresses;        
    }
    
    function setValuesInPercent(uint256[] memory _valuesInPercent) external onlyOwner
    {
        require(_valuesInPercent.length == 2);
        require(_valuesInPercent[0] +_valuesInPercent[1] == 100);
        
        valuesInPercent = _valuesInPercent;        
    }
    
    function setAddressesAndValuesInPercent(address[] memory _addresses, uint256[] memory _valuesInPercent) external onlyOwner
    {
        require(_addresses.length == 2);
        require(_valuesInPercent.length == 2);
        require(_valuesInPercent[0] + _valuesInPercent[1] == 100);
        
        addresses = _addresses;
        valuesInPercent = _valuesInPercent;
    }
    
    function setGoal(uint256 _goal) external onlyOwner
    {
        goal = _goal;
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