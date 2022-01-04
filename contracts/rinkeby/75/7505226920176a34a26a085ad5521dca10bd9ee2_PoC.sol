// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title PoC Contract verification via EtherScan API
 */
contract PoC {

    string public message;

    function storeMessage() external { 
        message = "PoC Contract";
    }
}