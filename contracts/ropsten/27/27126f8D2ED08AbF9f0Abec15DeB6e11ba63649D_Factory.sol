/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

pragma solidity ^0.8.10;

contract Factory {
    MyNewContract[] public contractList;
    MyNewContract public myNewContract;

    function createContract(string memory name) public {
        myNewContract = new MyNewContract(name); //return new contract address
        contractList.push(myNewContract);
    } 
}

contract MyNewContract {
    string public Name;
    constructor (string memory contractName) public {
        Name = contractName;
    }
    function setName(string memory resetName) public {
        Name = resetName;
    }
}

// contract interaction {
//     Contract contract_ = Contract(0x123); 
//     function setSomething(string _name) public {
//         contract_.setName(_name);
//     }
// }