/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// File: contracts/ContractC1.sol



pragma solidity ^0.8.5;

contract ContractC1 {
    event abc(string str);
    
    function alpha() public {
        emit abc("Bye");
    }
}
// File: contracts/ContractC2.sol


pragma solidity ^0.8.5;

contract ContractC2 {
    ContractC1 c11;
    event pqr(string str);

    function beta(address addr) public {
        c11 = ContractC1(addr);
        c11.alpha();
        emit pqr("Hi");
    }
}