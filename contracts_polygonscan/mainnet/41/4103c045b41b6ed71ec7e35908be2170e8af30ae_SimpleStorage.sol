/**
 *Submitted for verification at polygonscan.com on 2021-08-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract SimpleStorage {
    // state variable
    string public text; // this variable is stored on blockchain (storage)
    // by using "public", solidity will automatically write a get function for this var
    
     function set(string memory _text) public { // it's common practice to underscore the var input to avoid the confusion state variable
     // _text is not stored on blockchain therefore it should be declared memory
        text = _text;
    }
    
    function get() public view returns(string memory) { // we want to take a copy of actual string, not pointer to that string
        // view doesn't write to the blockchain
        // pure doesn't change the state of sc
        return text;
    }
    
    // there is also calldata?
}