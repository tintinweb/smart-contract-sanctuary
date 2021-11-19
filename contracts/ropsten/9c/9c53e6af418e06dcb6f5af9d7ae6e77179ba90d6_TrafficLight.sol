/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity 0.5.1;
contract TrafficLight {
    string signal;
    address owner;
    address teacher=0x47C1C218f11077ef303591cb6B2056DC6ea3063F;
//20 мин - мне, 21:15 - преподавателю, 8:00 -всем
    modifier onlyWhileOpen(){
        require(( block.timestamp>=1637265600 && msg.sender == owner ) || 
        (block.timestamp>=1637259300 && msg.sender == teacher) || 
        (block.timestamp>=1637298000));

         _;
     }
    
    enum Colour {Red,Yellow,Green} 
    Colour public state;
    
constructor()public{
    state=Colour.Red;
}
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