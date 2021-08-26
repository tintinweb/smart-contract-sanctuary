// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <=0.8.7;

import "./ERC20.sol";

contract CREDIToken is ERC20 {
    constructor() ERC20("TESTCR1", "TESTCR1") {
        uint8 decimals = 18;
        _mint(
            150000000 * 10**decimals,
            decimals,
            0x0Ba4f79732a70c8428b18f8506d60fF7b581F349
        );
    }
}


// contract CREDIToken is ERC20 {
//     constructor() ERC20("Credi", "CREDI") {
//         uint8 decimals = 18;
//         _mint(
//             msg.sender,
//             150000000 * 10**decimals,
//             decimals,
//             0x0Ba4f79732a70c8428b18f8506d60fF7b581F349
//         );
//     }
// }