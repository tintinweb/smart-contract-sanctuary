// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.6.0;

import "./hermezInterface.sol";

// mock class of ERC20 to change decimals, this is not anymore a openZeppelin standard
contract HermezAddL1 {
    // Event emitted when a L1-user transaction is called and added to the nextL1FillingQueue queue
    event L1UserTxEvent(
        uint32 indexed queueIndex,
        uint8 indexed position, // Position inside the queue where the TX resides
        bytes l1UserTx
    );

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function hermezAddL1(address hermezAddress, uint256 num) public {
        bytes memory t;
        uint32 queue = hermezInterface(hermezAddress).nextL1FillingQueue();
        for (uint256 i = 0; i < num; i++) {
            hermezInterface(hermezAddress).addL1Transaction(
                1,
                0,
                0,
                0,
                0,
                0,
                t
            );

            emit L1UserTxEvent(queue + uint32(i), uint8(i), t);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.6.12;

/**
 * @dev Define interface verifier
 */
interface hermezInterface {
    function addL1Transaction(
        uint256 babyPubKey,
        uint48 fromIdx,
        uint40 loadAmountF,
        uint40 amountF,
        uint32 tokenID,
        uint48 toIdx,
        bytes calldata permit
    ) external;

    function addToken(address tokenAddress, bytes calldata permit) external;

    function nextL1FillingQueue() external view returns (uint32);
}