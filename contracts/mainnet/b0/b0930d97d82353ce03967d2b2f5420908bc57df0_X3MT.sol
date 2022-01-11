//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "ERC20.sol";


contract X3MT is ERC20 {

    constructor(
        address gnosisSafeMultisig
    ) ERC20("X3M Token", "X3MT") {
        _mint(gnosisSafeMultisig, 10000000000000000000000000000); // 10  000 000 000   000 000 000  000 000 000
    }

}