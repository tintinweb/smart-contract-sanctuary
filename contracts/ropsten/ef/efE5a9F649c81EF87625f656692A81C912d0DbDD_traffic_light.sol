/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

pragma solidity ^0.5.1;

contract traffic_light{
    enum State {Red, Green, Yellow}
    string light;
    State state;
    address owner=0x5d43411e9CBEb357cbf26b881b2B1DB245B08c01;
    address teacher = 0x47C1C218f11077ef303591cb6B2056DC6ea3063F;
    uint256 startTime = block.timestamp;
 modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }

modifier onlyWhileOpen(){
    require((block.timestamp >= startTime + 20 minutes && msg.sender == owner) || 
    (block.timestamp >= startTime + 70 minutes && msg.sender == teacher) ||
    (block.timestamp >= startTime + 11 hours));
    _;
}

constructor() public{
    state = State.Red;
}
function activateRed() public{
    state = State.Red;
    light = "Red light";
}

function activateYellow() public{
    state = State.Yellow;
    light = "Yellow light";
}

function activateGreen() public onlyOwner{
    state = State.Green;
    light = "Green light";
}
function whichLight() public onlyWhileOpen view returns(string memory){
    return light;
}

}