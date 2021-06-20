/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

pragma solidity ^0.4.24;

contract Factory {
    address[] public newContracts;

    function createContract(string name) public {
        address newContract = new Contract(name);
        newContracts.push(newContract);
    } 
}  

contract Contract {
    string public Name;
    constructor (string _name) public {
        Name = _name;
    }
    function setName(string _name) public {
        Name = _name;
    }
}

contract interaction {
    Contract contract_ = Contract(0x123); 
    function setSomething(string _name) public {
        contract_.setName(_name);
    }
}