/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract AccountRegistration {

    event Registration(bytes20 from,bytes4 id);
    event UnRegistration(bytes20 from,bytes4 id);

    function Register(bytes4 id) public {
        emit Registration(bytes20(msg.sender),id);
    }

    function UnRegister(bytes4 id) public {
        emit UnRegistration(bytes20(msg.sender),id);
    }

}