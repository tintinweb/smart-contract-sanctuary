/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

pragma solidity ^0.8.3;

contract Factory {
    Contract[] newContracts;

    function createContract (bytes32 name) public {
        Contract newContract = new Contract(name);
        newContracts.push(newContract);
    } 
}

contract Contract {
    bytes32 public Name;

    constructor(bytes32 name) public{
        Name = name;
    }
}