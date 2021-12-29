/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// File: contracts/ContractC1.sol



pragma solidity ^0.8.5;

contract ContractC1 {
    event abc(string str);

    function C1() public {
        emit abc("Hello");
    }
}

// File: contracts/ContractC2.sol

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.5;


contract ContractC2 {
    event xyz(string str);

    function C2(address addr) public {
        ContractC1 c11 = ContractC1(addr);
        c11.C1();
        emit xyz("Welcome");
    }
}