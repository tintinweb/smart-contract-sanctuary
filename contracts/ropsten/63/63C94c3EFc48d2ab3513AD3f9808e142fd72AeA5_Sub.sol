/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.7.6;

interface IBridge {
    function subscribe(uint256 fromChainID,address fromContract,string memory eventName,uint256 startBlock) external;
}

contract Sub {
    address public systemContract;

    constructor(address _systemContract){
        systemContract = _systemContract;
    }

    function subscribe(
        uint256 fromChainID,
        address fromContract,
        string memory eventName,
        uint256 startBlock
    ) public {
        IBridge(systemContract).subscribe(
            fromChainID,
            fromContract,
            eventName,
            startBlock
        );
    }
}