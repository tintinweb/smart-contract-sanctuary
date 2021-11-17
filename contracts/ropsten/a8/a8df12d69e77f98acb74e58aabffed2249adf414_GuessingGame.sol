/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

pragma solidity 0.6.12;

contract GuessingGame {
bytes32 internal One = 0x0837922bf193271cea1db9fb959a9532dbe6f1d08b76b0091c8ca468e671feb0;
bytes32 internal Two = 0xc1f77584032a9dc848fe57c6465eaca8983b900a4373654fd2859fbe785487b3;   
mapping (address => uint) public Scoreboard;
function CheckGuess(address Guess) public {
    if(keccak256(abi.encodePacked(Guess)) == One){
        Scoreboard[msg.sender]++;
    } 
    else if(keccak256(abi.encodePacked(Guess)) == One){
        Scoreboard[msg.sender]+=2;
    } 
    else{
        Scoreboard[msg.sender]-=2;
    }
}
}