/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

/**
 * @dev settings:
 * version  v0.8.7+commit.e28d00a7
 * Enable  optimization True with 200 runs
 * ipfs  dweb:/ipfs/QmS8nHHs6M5qgrZDbzbJnw6AX2qSdpJfMBcfUrriBPJWhZ
 */
contract WDAOToken {

    event Test(address indexed sender, address indexed to, uint256 id, uint256[] tokens);

    event Log(address indexed sender, uint256 id, uint256 indexed nftid, uint256 token);


    function test(uint256 id, uint256[] memory tokens) public {
        emit Test(msg.sender, address(this), id, tokens);
    }

    function log(uint256 id, uint256 nftid) public {
        emit Log(msg.sender, id, nftid, 100);
    }
    
}