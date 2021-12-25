/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract AccountRegistration {

    event Registration(bytes  data);
    event UnRegistration(bytes  data);

    function Register(bytes12 id) public {
        emit Registration(abi.encodePacked(bytes20(msg.sender),id));
    }

    function UnRegister(bytes12 id) public {
        emit UnRegistration(abi.encodePacked(bytes20(msg.sender),id));
    }

}