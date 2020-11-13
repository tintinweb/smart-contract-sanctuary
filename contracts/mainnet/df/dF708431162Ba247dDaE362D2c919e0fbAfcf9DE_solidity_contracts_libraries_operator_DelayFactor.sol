pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

library DelayFactor {
    using SafeMath for uint256;

    /// @notice Gets delay factor for rewards calculation.
    /// @return Integer representing floating-point number with 16 decimals places.
    function calculate(
        uint256 currentRequestStartBlock,
        uint256 relayEntryTimeout
    ) public view returns(uint256 delayFactor) {
        uint256 decimals = 1e16; // Adding 16 decimals to perform float division.

        // T_deadline is the earliest block when no submissions are accepted
        // and an entry timed out. The last block the entry can be published in is
        //     currentRequestStartBlock + relayEntryTimeout
        // and submission are no longer accepted from block
        //     currentRequestStartBlock + relayEntryTimeout + 1.
        uint256 deadlineBlock = currentRequestStartBlock.add(relayEntryTimeout).add(1);

        // T_begin is the earliest block the result can be published in.
        // Relay entry can be generated instantly after relay request is
        // registered on-chain so a new entry can be published at the next
        // block the earliest.
        uint256 submissionStartBlock = currentRequestStartBlock.add(1);

        // Use submissionStartBlock block as entryReceivedBlock if entry submitted earlier than expected.
        uint256 entryReceivedBlock = block.number <= submissionStartBlock ? submissionStartBlock:block.number;

        // T_remaining = T_deadline - T_received
        uint256 remainingBlocks = deadlineBlock.sub(entryReceivedBlock);

        // T_deadline - T_begin
        uint256 submissionWindow = deadlineBlock.sub(submissionStartBlock);

        // delay factor = [ T_remaining / (T_deadline - T_begin)]^2
        //
        // Since we add 16 decimal places to perform float division, we do:
        // delay factor = [ T_temaining * decimals / (T_deadline - T_begin)]^2 / decimals =
        //    = [T_remaining / (T_deadline - T_begin) ]^2 * decimals
        delayFactor = ((remainingBlocks.mul(decimals).div(submissionWindow))**2).div(decimals);
    }
}