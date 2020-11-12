pragma solidity ^0.6.1;

import "./Owned.sol";

contract Swap is Owned {
    // Refund delay. Default: 4 hours
    uint public refundDelay = 4 * 60 * 4;

    // Max possible refund delay: 5 days
    uint constant MAX_REFUND_DELAY = 60 * 60 * 2 * 4;

    /**
     * Set the block height at which a refund will successfully process.
     */
    function setRefundDelay(uint delay) external onlyOwner {
        require(delay <= MAX_REFUND_DELAY, "Delay is too large.");
        refundDelay = delay;
    }
}
