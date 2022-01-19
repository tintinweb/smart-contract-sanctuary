/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract prueba{


    address public wallet;


    function setWallet()external {
        wallet =msg.sender;
    }

    function getWallet()external view returns(address){

        return wallet;
    }

}