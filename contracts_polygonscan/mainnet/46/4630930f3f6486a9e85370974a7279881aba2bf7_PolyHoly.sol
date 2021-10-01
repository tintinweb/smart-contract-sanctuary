/**
 *Submitted for verification at polygonscan.com on 2021-10-01
*/

// Specifies that the source code is for a version
// of Solidity greater than 0.5.10
pragma solidity ^0.5.10;

// A contract is a collection of functions and data (its state)
// that resides at a specific address on the Ethereum blockchain.
contract PolyHoly {

    // The keyword "public" makes variables accessible from outside a contract
    // and creates a function that other contracts or SDKs can call to access the value
    string public message;
    string public symbol;
   string public name;
   int256 public decimals;
   int public _totalSupply;
    
    // A special function only run during the creation of the contract
    constructor(string memory initMessage) public {
        // Takes a string value and stores the value in the memory data storage area,
        // setting `message` to that value
        message = initMessage;
         symbol = "STC";
        name = "STATE COIN";
        decimals = 9;
        _totalSupply = 1000000000000000000000000;
    }

}