/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// at first we need to tell the compiler the version of solidity we are using. we do that by writing pragma solidity and then version
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// carrot sign means above 0.8.0 and bellow 0.9.0 
// if we are using solidity version above 0.6.8 you will have to add license https://forum.openzeppelin.com/t/solidity-0-6-8-introduces-spdx-license-identifiers/2859
// otherwise we can have a warning in console and even when we deploy the contract that is okay but still looks bad for a professional programmer
// give an example 
// contract lolopino{
//     uint public numbers = 5000;
// }
// add mr bean waiting meme while reading the warning message that came from compiler for not adding the license
// you can also copy the version and stuff from the contracts that are created by solidity itself
// enough talk on version and stuff now let's start codding the token smart contract
contract lolopinoo{
    mapping(address => uint) public balances; 
    /*
    Mapping:
    It is something you can use to store the values into one variable. For example 
    mapping(address => uint) public balances
    Balances here is the name of this mapping and what it actually says is, what amount (that is uint) does one address have you can get that information through one variable that is, balances.. 
    */
    uint public totalSupply = 1000000; // one million token totalSupply - how to count
    string public symbol = 'LOOPN';
    string public name = 'Lolopino Token';
    uint public decimal = 18;

    // a constructor is a function that runs only once, at the time of compilation
    // we are going to send all the tokens to the address which is deploying the smart contract so that ot can destribute later on 
    constructor(){
            balances[msg.sender] = totalSupply;
    }
    // till now we have completed the code that is required to create a token and send it to your address 

    // function - read data from the smart contract or update data












}