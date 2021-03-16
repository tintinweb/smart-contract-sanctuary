/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

pragma solidity 0.5.10;

contract SassoCartaForbici {
 address public owner;
 uint256 public gamesPlayed;
 enum hand {SASSO, CARTA, FORBICI}
 enum result {VINTO, PERSO, PAREGGIO}
 string public lastResult;

 constructor() public payable{
   owner = msg.sender;
   gamesPlayed = 0;
   lastResult = "";
 }

 //Return result in string form
 function resultToString(result res) public pure returns(string memory) {
   if (res == result.VINTO) {
     return "Hai Vinto! :)";
   }
   if (res == result.PERSO) {
     return "Hai Perso! :(";
   }
   if (res == result.PAREGGIO) {
     return "PAREGGIO! :O";
   }
   return "";
 }
 
  // Get a random hand
 function generateHand() public view returns(hand){
   // uint8 rand = uint8(uint256(keccak256(block.timestamp))%3 + 1);
   uint rand = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 3;
   if (rand == 0) {
     return hand.SASSO;
   }
   if (rand == 1) {
     return hand.CARTA;
   }
   if (rand == 2) {
     return hand.FORBICI;
   }
 }   
 

 // Convert int to hand
 function convertHand(uint256 choice) public pure returns(hand){
   if (choice == 0) {
     return hand.SASSO;
   }
   if (choice == 1) {
     return hand.CARTA;
   }
   if (choice == 2) {
     return hand.FORBICI;
   }
 }
 
 // Emit outcome based on result for js display result
 function setLastResult(result res) public {
   if (res == result.PAREGGIO) {
     lastResult = resultToString(res);
   }
   if (res == result.VINTO) {
     lastResult = resultToString(res);
   }
   if (res == result.PERSO) {
     lastResult = resultToString(res);
   }
 }

 // Determine winning
 function determineWin(hand SoftStrategy,hand TU) public pure returns(result) {
   // Check tie
   if (SoftStrategy == TU) {
     return result.PAREGGIO;
   }
   // Check win/lose
   if (SoftStrategy == hand.SASSO) {
     if (TU == hand.CARTA) {
       return result.VINTO;
     } else {
       return result.PERSO;
     }
   }
   if (SoftStrategy == hand.CARTA) {
     if (TU == hand.FORBICI) {
       return result.VINTO;
     } else {
       return result.PERSO;
     }
   }
   if (SoftStrategy == hand.FORBICI) {
     if (TU == hand.SASSO) {
       return result.VINTO;
     } else {
       return result.PERSO;
     }
   }
 
 }
}