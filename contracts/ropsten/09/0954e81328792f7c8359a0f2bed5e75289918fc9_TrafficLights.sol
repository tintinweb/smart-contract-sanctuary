/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity 0.5.1;
contract TrafficLights {
    string signal;
    address owner;
    address teacher=0x47C1C218f11077ef303591cb6B2056DC6ea3063F;
uint256 startTime=block.timestamp;
    modifier onlyWhileOpen(){
        require((block.timestamp>=startTime + 20 minutes && msg.sender == owner ) || 
        (block.timestamp>=startTime + 30 minutes && msg.sender == teacher) || 
        (block.timestamp>=startTime + 11 hours));

         _;
     }
    
enum Colour {Red,Yellow,Green} //перечисление возможных цветов
    Colour public state;
    
function GREEN() public {
    state = Colour.Green;
    signal = "Green";
}
function YELLOW() public {
    state = Colour.Yellow;
    signal = "Yellow";
}
function RED() public {
    state = Colour.Red;
    signal = "Red"; 
}
function Signal() public view returns(string memory) {
return signal;
}
}