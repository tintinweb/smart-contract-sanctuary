/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//you can call the contract whatever you want, doesn't matter

contract blahblahblahcontractwhatever{
    
    
    //this makes "thisisaNumber" a number. uint256 = number
    uint256 thisisaNumber = 5;
    
    //This below makes a button called "Supercoolbutton" that anyone can see, because its public.
    //Because it has "view" in it, this button will not require gas. 
    //"returns" basically says when you press the button, (uint256) will appear (remember, uint256 = number)
    
    function Supercoolbutton(uint256 putinanumber) public view returns (uint256){
        
        //this does math, very cool math.
        putinanumber = putinanumber + thisisaNumber;
        
        //this makes it so when you press the button, it shows the number
        return putinanumber;
    }
    
    
    
    
    
    
    
    //this makes "thisistext" text. string = text
    string thisistext = "Wow! super cool text!";
    
    
    //this makes a button called "SayText" that shows text when you press it
    //its public, so anyone can see it, and it returns text (memory is the location of where the text is, memory requires a LOT of gas, so text usually is not stored on blockchains)
    
    function SayText() public view returns(string memory){
        
        return thisistext;
    }
}

//Now, how to deploy the contract!

//You see on the top left of the screen, there are 5 buttons.

//You can click the second button to get the SOLIDITY COMPILER! Click on compile (the blue button) to check for errors and compile the contract.

//once its compiled, you can click the 3rd button from the top to deploy and run transactions!

//Click where it says "enviroment" and change it to "injected web3", change your metamask to rinkeby testnet, press deploy, and go wild.