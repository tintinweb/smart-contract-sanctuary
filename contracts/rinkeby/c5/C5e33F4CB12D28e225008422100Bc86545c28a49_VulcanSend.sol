/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// contract VulcanApplication {
    
//     function sendApplication(bytes calldata data) public {}
    
// }

interface IVulcanApplication {
    
    function sendApplication(bytes calldata data) external;
    
}

contract VulcanSend {
    // VulcanApplication va;
    address va_addr;

    constructor (address _t) {
        // va = VulcanApplication(_t);
        va_addr = _t;
    }

    function messageVulcan(string calldata data) public {
        // va.sendApplication(bytes(data));
        IVulcanApplication(va_addr).sendApplication(bytes(data));
    }
}