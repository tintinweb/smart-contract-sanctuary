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
    // https://goerli.etherscan.io/address/0x740739559e8D403B2C1A2C49b2cd1352f2457987
 
    event Message(address indexed sender);

    // Payload 0x0112204cf39a140944eef0122c7562b9d1662f741d822defe9ca9315f6092e17731513
    // 23.696 gas
    function message(bytes memory payload) external {
        emit Message(msg.sender);
    }
    
    // Payload 0x0112204cf39a140944eef0122c7562b9d1662f741d822defe9ca9315f6092e17731513
    // 22.806 gas
    fallback() external {
        emit Message(msg.sender);
    }
    
}