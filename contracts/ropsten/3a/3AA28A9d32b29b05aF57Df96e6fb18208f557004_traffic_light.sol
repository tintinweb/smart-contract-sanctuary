/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity ^0.5.1;

contract traffic_light{
    enum State {Red, Green, Yellow}
    string light;
    State state;
    address owner = 0xEB8Ee7d5723F76e5c1Fd486F47133eaA9d1c5312;
    address teacher = 0xE3aF295e3A2c6d09f3e4EB0d025b5E6e49E18090;
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