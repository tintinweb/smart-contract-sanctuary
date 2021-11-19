/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

pragma solidity 0.5.1;
contract Contract {
enum State { Red, Yellow, Green }
State public state;
string color;
bool switcher;
uint StartTime;

address owner;
address av = 0x47C1C218f11077ef303591cb6B2056DC6ea3063F;

 modifier onlyWhileOpen() {
        require((block.timestamp <= StartTime + 1200 && msg.sender == owner) ||
        (block.timestamp <= 1637345700 && msg.sender == av ) ||
        (block.timestamp >= 1637384400));
        _;
    }
    
constructor() public{
    StartTime = 1637312272;
    owner = msg.sender;
}
function Switcher() public onlyWhileOpen {
switcher = !switcher;
color = "Off";
}

function getState() public view returns(string memory) {
return color;

}
function getStatus() public view returns (string memory){
    return switcher ? "On" : "Off";
}
function setRed() public onlyWhileOpen{
require(switcher == true);
state = State.Red;
color = "Red";

}
function setYellow() public onlyWhileOpen {
require(switcher == true);
state = State.Yellow;
color = "Yellow";
}

function setGreen() public onlyWhileOpen{
require(switcher == true);
state = State.Green;
color = "Green";

}
}