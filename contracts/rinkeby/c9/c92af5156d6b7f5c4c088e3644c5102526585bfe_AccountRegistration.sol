/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract AccountRegistration {
 
    event Registration(address indexed from,uint256 indexed data);

    function Register(uint256 data) external {
        emit Registration(msg.sender,data);
    }

    function BatchRegister(address[] calldata from,uint256[] calldata data) external {
        for(uint i = 0;i<from.length;i++){
            emit Registration(from[i],data[i]);
        }
    }

}