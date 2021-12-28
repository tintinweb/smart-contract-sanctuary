/**
 *Submitted for verification at polygonscan.com on 2021-12-28
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract ChainIdFetcher {
    function chainId() public view returns (uint256) {
        uint256 cid;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cid := chainid()
        }
        return cid;
    }

    constructor() {}
}