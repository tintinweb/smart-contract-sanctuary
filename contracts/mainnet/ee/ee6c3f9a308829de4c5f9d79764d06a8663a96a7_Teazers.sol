// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.11;

import './TeazersBase.sol';

contract Teazers is TeazersBase {
    constructor(address _addr) public {
        owner = msg.sender;

        reentry_status = ENTRY_ENABLED;

        levelCost[1] = 0.003 ether;
        for (uint8 i = 2; i <= TOP_LEVEL; i++) {
            levelCost[i] = levelCost[i - 1] * 2;
        }

        createAccount(_addr, _addr, true);

        for (uint8 j = 1; j <= TOP_LEVEL; j++) {
            handlePositionX3(_addr, _addr, _addr, j, true);
            handlePositionX4(_addr, _addr, _addr, j, true);
        }
    }
}