// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * Azuro V2 API docs: https://azuro-protocol.notion.site/Chainlink-V2-23b8d3b1cdbc48bd859a3eee0fd18747
 *
 * Azuro V2 Rinkeby LP Proxy contract address: 0xdD1F799518837A7a9B508E0a94682BBF214e8B76
 *   - https://rinkeby.etherscan.io/address/0xdd1f799518837a7a9b508e0a94682bbf214e8b76#code
 *
 * Azuro V2 Rinkeby LP Implementation contract address: 0xbE73f65B8D4f6c533fFfc2f4718a6caa25EB4aC0
 *   - https://rinkeby.etherscan.io/address/0xbE73f65B8D4f6c533fFfc2f4718a6caa25EB4aC0#code
 */
/**
 * @title A testing contract for Azuro
 * @author LinkPool
 * @notice Mocks the methods `phase2end` from the implementation contract LP.sol, which allows test the Azuro EA.
 */
contract AzuroV2MockLP {
    /* ========== CONSUMER STATE VARIABLES ========== */

    uint256 public phase2end;

    /* ========== HELPER FUNCTIONS ========== */

    function setPhase2end(uint256 _phase2end) external {
        phase2end = _phase2end;
    }
}