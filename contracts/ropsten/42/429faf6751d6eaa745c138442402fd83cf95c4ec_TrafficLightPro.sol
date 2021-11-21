/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

pragma solidity ^0.5.1;

contract TrafficLightPro{
    
    address owner;
    address teacher = 0x47C1C218f11077ef303591cb6B2056DC6ea3063F;
    string color_change;
    
    enum Color{NONE ,GREEN, YELLOW, RED}
    enum State{ON, OFF}
    Color internal color;
    State internal state;
    
    modifier onlyWhileOpen(){
        require((block.timestamp >= 1637445600 && msg.sender == owner) || // Хозяин
            (block.timestamp >= 1637439900 && msg.sender == teacher)|| // Учитель
            (block.timestamp >= 1637439960)); // Все остальные
        _;
    }
    
    constructor() public{
        state = State.OFF;
        color = Color.NONE;
    }
    
    function TurnOn() public{
        require(State.OFF == state, "Already ON");
        state = State.ON;
    }
    function TurnOff() public{
        require(State.ON == state, "Already OFF");
        state = State.OFF;
        color_change = "NONE";
    }
    
    function SetGreenLight() public{
        require(State.ON == state, "Need to TurnON traffic light at first");
        color = Color.GREEN;
        color_change = "Green";
    }
    
    function SetYellowLight() public{
        require(State.ON == state, "Need to TurnON traffic light at first");
        color = Color.YELLOW;
        color_change = "Yellow";
    }
    
    function SetRedLight() public{
        require(State.ON == state, "Need to TurnON traffic light at first");
        color = Color.RED;
        color_change = "Red";
    }
    
    function getColor() public view returns(string memory){
        return color_change;
    }
}