/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


/**
 * @dev An initial stub implementation for the withdrawals contract proxy.
 */
contract WithdrawalsManagerStub {
    /**
     * @dev Receives Ether.
     *
     * Currently this is intentionally not supported since Ethereum 2.0 withdrawals specification
     * might change before withdrawals are enabled. This contract sits behind a proxy that can be
     * upgraded to a new implementation contract collectively by LDO holders by performing a vote.
     *
     * When Ethereum 2.0 withdrawals specification is finalized, Lido DAO will prepare the new
     * implementation contract and initiate a vote among LDO holders for upgrading the proxy to
     * the new implementation.
     */
    receive() external payable {
        revert("not supported");
    }
}