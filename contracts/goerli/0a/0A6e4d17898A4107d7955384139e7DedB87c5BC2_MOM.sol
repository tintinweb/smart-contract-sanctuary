/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

// SPDX SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

contract MOM {
 
    // Payload TX di esempio: 0x0112204cf39a140944eef0122c7562b9d1662f741d822defe9ca9315f6092e17731513
    // https://rinkeby.etherscan.io/tx/0x5ca6c0197ebf823e7577e54570b9cfeac6f9f42d39e1d005fca48f14857650bc
    // 21.560 gas
    
    // Contratto di test
    // https://goerli.etherscan.io/address/0x48F096d5B9fB12F80988BE1b6783C4Da9b8B6712
 
    event Message(address indexed sender);

    // Payload 0x0112204cf39a140944eef0122c7562b9d1662f741d822defe9ca9315f6092e17731513
    // 22.948 gas 
    function message1(bytes memory payload) external { }
    
    // Payload 0x0112204cf39a140944eef0122c7562b9d1662f741d822defe9ca9315f6092e17731513
    // 24.130 gas
    function message2(bytes memory payload) external {
        emit Message(msg.sender);
    }
    
    fallback() external {
        emit Message(msg.sender);
    }
    
}