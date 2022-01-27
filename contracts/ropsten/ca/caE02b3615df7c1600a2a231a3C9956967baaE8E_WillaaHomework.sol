// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;

contract WillaaHomework {
    // Objective is to use as many types as I can and set realistic variables with comments
    bool _hasThePartyStarted; // Function that returns if the party has started
    int _tokenID; // The access token ID, required for entry to the party
    
    int bigNumber = 5; // Five is the number of points on the star of the sign of the beast
    int lilNumber = 4; // Four is the number of points on a tetrahedron

    function checkNumber() public view returns(string memory){ 
        if(bigNumber > lilNumber) { // double checking that 5 is greater than 4 
            return "5 is greater than 4 and you have passed the test"; // test pass message
        }
        else {
            return "Oh, no!";
        }
    }

   string _welcomeMessage = "Welcome to the party!"; // Welcome message for the wallet signature confirmation
   bytes32 _welcomeMessageOptimized = "Welcome to the party!"; // a word using LESS gas

    function addSomeNumbers() public pure returns(uint){
        uint a = 6; 
        uint b = 9;
        uint addition = a + b;
        return addition; 
    }    

    address _communityWalletAddress; // The spot for the wallet
    
}