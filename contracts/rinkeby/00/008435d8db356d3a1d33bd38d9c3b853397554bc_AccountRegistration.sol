/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract AccountRegistration {

    event Registration(address indexed from,uint256 indexed data);
    event UnRegistration(address indexed from,uint256 indexed data);

    function Register(uint256 data) public {
        emit Registration(msg.sender,data);
    }

    function UnRegister(uint256 data) public {
        emit UnRegistration(msg.sender,data);
    }

}