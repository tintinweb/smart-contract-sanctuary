/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.4.24;

contract Factory {
    address[] public newContracts;

    function createContract(string name) public {
        address newContract = new customContract(name); // use contract to create another contract
        newContracts.push(newContract);
    } 
}

contract customContract {
    string public Name;
    constructor (string _name) public {
        Name = _name;
    }
    function setName(string _name) public {
        Name = _name;
    }
    function getName() public view returns(string){
        return Name;
    }
}

// contract interaction {
//     customContract contract_ = customContract(0x123); // get contract
//     function setsomething(string _name) public {
//         contract_.setName(_name);
//     }
//     function getContractName() public view returns(string){
//         return contract_.getName();
//     }
// }