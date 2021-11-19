/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

pragma solidity ^0.5.1;

contract TraficLightTest{
    enum Status{on, off}
    enum Colour{red, yellow, green, none}
    Status internal status;
    Colour internal colour;
    address owner = 0xd6Cd6DF6a79B1cF44225548D6f27b1DA74EFC5f8;
    address teacher = 0x47C1C218f11077ef303591cb6B2056DC6ea3063F;
    
    modifier AccessRestriction(){
        require((msg.sender == owner && block.timestamp >= 1637339400) || //15 min after contract creation
        (msg.sender == teacher && block.timestamp >= 1637345700) || //21:15 19.11.2021
        (block.timestamp >= 1637384400)); //all after 8:00 20.11.2021
        _;
    }
    
    constructor() public{
        status = Status.off;
        colour = Colour.none;
    }
    function Enable() public{
        require(Status.off == status);
        status = Status.on;
    }
    function Disable() public{
        require(Status.on == status);
        status = Status.off;
    }
    function getStatus() public view returns(Status){
        return status;
    }
    function SwitchToRed() public{
        require(Status.on == status);
        colour = Colour.red;
    }
    function SwitchToYellow() public{
        require(Status.on == status);
        colour = Colour.yellow;
    }
    function SwitchToGreen() public{
        require(Status.on == status);
        colour = Colour.green;
    }
    function getColour() public view returns(Colour){
        require(Status.on == status);
        return colour;
    }
}