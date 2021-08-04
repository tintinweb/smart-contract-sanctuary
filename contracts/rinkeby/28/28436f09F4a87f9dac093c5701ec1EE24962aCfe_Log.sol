/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;

//Go to the "read" functions to play the game! (Don't use write or you will pay gas)

//Shhh... Don't look at the source code!
//The answers lie here!

//If you wanna play fair, try figuring out the answers yourself before trying to find them here!

//Now, a bunch of space so you don't accedentally see them

















































































//So, if you're wondering how the heck this thing works, ill try explaining as best as I can!


contract Log {
    
    //makes this thing say log is very pog
    string Clue1 = "ONE day, Jerry came out to get SIX bottles of water, he ended up tripping and he split THREE!";

    //Cool button that anyone can see because its public, and when you press it, it shows the clue
    function GetClue() public view returns (string memory) {return Clue1;}

    //number is a number
        uint256 number;

    //Makes a cool button that saves a number when you press it
    function EnterCombination(uint256 num) public {number = num;}

    //Makes cool button that shows saved number
    function Getcombination() public view returns (uint256){
        
        return number;
    }
    
    string combo = "Congrats! You got it right!";
    
    function CheckAnswer() public view returns (string memory){
        
        require(number == 163, "Sorry, you're wrong!");
        return combo;
    }
}