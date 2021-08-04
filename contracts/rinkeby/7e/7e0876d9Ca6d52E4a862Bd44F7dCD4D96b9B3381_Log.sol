/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;

//Go to the "read" and "write" functions to play the game! 
//You may have to get test ETH (Not real eth, don't worry) for this, go to https://faucet.rinkeby.io to get some eth"


//Shhh... Don't look at the source code!
//The answers lie here!

//If you wanna play fair, try figuring out the answers yourself before trying to find them here!

//Now, a bunch of space so you don't accedentally see them











contract Log {
    
    string Clue1 = "ONE day, Jerry came out to get SIX bottles of water, he ended up tripping and he split THREE!";

    function GetClue() public view returns (string memory) {return Clue1;}

        uint256 number;

    function EnterCombination(uint256 num) public {number = num;}
    
    function ResetPuzzle() public {number = 0;}

    function Getcombination() public view returns (uint256){
        
        return number;
    }
    
    string combo = "Congrats! You got it right!";
    
    function CheckifRight() public view returns (string memory){
        
        require(number == 163, "Sorry, you're wrong!");
        return combo;
    }
    
    string notcombo = "Nope, you're not right, or you haven't answered yet.";
    
    function CheckifWrong() public view returns (string memory){
        
        require(number != 163, "Nope, you're not right");
        return notcombo;
    }
}