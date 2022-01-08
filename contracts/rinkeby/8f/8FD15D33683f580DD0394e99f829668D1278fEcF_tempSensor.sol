/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract tempSensor
{
    bool LEDturnedOn;
    bool tempUpdated;
    int256 currentTemp;
    uint256 lastTempUpdate;
    address owner;
    
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    
    constructor() 
    {
        LEDturnedOn = false;
        tempUpdated = true;
        lastTempUpdate = block.number;
        owner = msg.sender;
    }
    
    function isLightTurnedOn() public view returns (bool)
    {
        return LEDturnedOn;
    }
    
    function isTempCurrent() public view returns (bool)
    {
        return tempUpdated;
    }
    
    function turnLightOn() public payable
    {
        if( msg.value < 1000 wei){ revert(); }
        LEDturnedOn = true;
    }
    
    function turnLightOffAdminOnly() public onlyOwner
    {
        LEDturnedOn = false;
    }
    
    function updateTemp() public payable
    {
        if(msg.value < 10 wei){ revert(); }
        tempUpdated = false;
    }
    
    function setTempDeviceOnly(int256 _temp) public onlyOwner
    {
        currentTemp = _temp;
        lastTempUpdate = block.number;
        tempUpdated = true;
    }
    
    function getTemp() public view returns (int256, uint256)
    {
        return (currentTemp, lastTempUpdate);
    }

    function transferOutAdminOnly(address payable addr, uint256 amount) public onlyOwner
    {
        if(amount <= address(this).balance)
        {
            addr.transfer(amount);
        }
    }
}