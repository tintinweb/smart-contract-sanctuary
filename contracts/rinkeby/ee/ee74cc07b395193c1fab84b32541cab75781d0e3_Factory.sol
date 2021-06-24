/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.4.24;

contract Factory {
    address[] public newContracts;

    function createContract(string name) public {
        address newContract = new Contract(name); // use contract to create another contract
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

// contract interaction {
//     contract contract_ = contract(0x123); // get contract
//     function setsomething(string _name) public {
//         contract_.setname(_name);
//     }
// }