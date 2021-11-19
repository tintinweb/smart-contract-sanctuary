/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

pragma solidity ^0.5.1;

contract TrafficLight {
    enum LightColor{ Green, Yellow, Red }
    LightColor private color = LightColor.Green;
    address owner;
    address teach = 0x47C1C218f11077ef303591cb6B2056DC6ea3063F;
    uint256 startTime = block.timestamp;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyByTimer() { require(
        (block.timestamp >= startTime + 20 minutes && msg.sender == owner) || 
        (block.timestamp >= startTime + 70 minutes && msg.sender == teach) ||
        (block.timestamp >= startTime + 11 hours));
        _;
    }
    
    function getColor() public onlyByTimer view returns(string memory) {
        if (color == LightColor.Green) return "Green";
        if (color == LightColor.Yellow) return "Yellow";
        if (color == LightColor.Red) return "Red";
    }
    
    function setRedColor() public {
        color = LightColor.Red;
    }
    
    function setYellowColor() public {
        color = LightColor.Yellow;
    }
    
    function setGreenColor() public {
        color = LightColor.Green;
    }
}