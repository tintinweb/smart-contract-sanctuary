//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StationHooks {

    bool shh;

    modifier silent {
        if(false) shh = shh;
        _;
    }

    function onTransfer(address, address, address, uint256) external silent returns (bool) { return true; }
    function onSeize(address, address, address, uint256) external silent returns (bool) { return false; }
}

