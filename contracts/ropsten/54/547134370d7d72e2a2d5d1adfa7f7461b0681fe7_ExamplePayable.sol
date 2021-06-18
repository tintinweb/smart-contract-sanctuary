/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity >=0.5.0 <0.7.0;


contract ExamplePayable {
    mapping (address => bool) registeredAddresses;


    constructor() public {}


    // It is important to also provide the
    // `payable` keyword here, otherwise the function will
    // automatically reject all Ether sent to it.
    function register() public payable {
        registeredAddresses[msg.sender] = true;
    }

}