// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

library Calculator {
    /**
     * Represents the return value of the `calcTokens` method.
     *
     * The fields:
     * - `tokensAmount`: the amount of tokens that may be bought for the given
     *   amount of USD at the given token supply;
     * - `maintainerBonusTokensAmount`: the amount of maintainer bonus tokens
     *   to be minted when selling the `tokensAmount` at the given token supply;
     * - `bountyBonusTokensAmount`: the amount of bounty bonus tokens to be
     *   minted when selling the `tokensAmount` at the given token supply;
     * - `nextNodeId`: the adjusted value for the supply node pointer
     *   immediately after `tokensAmount`, `maintainerBonusTokensAmount`
     *   and `bountyBonusTokensAmount` are minted;
     * - `nextPricePerToken`: the price per token (in USD) immediately after
     *   `tokensAmount`, `maintainerBonusTokensAmount` and
     *   `bountyBonusTokensAmount` are minted.
     */
    struct Result {
        uint256 tokensAmount;
        uint256 maintainerBonusTokensAmount;
        uint256 bountyBonusTokensAmount;
        uint8 nextNodeId;
        uint256 nextPricePerToken;
    }

    /**
     * @dev internal state used by token calculations loop
     */
    // solhint-disable-next-line contract-name-camelcase
    struct _LoopState {
        uint256 prev;
        uint256 curr;
        uint256 next;
    }

    /**
     * Must be in sync with contract's decimals() implementation
     */
    uint8 public constant DECIMALS = 18;

    /**
     * The price per token threshold above which a maintainer bonus tokens are
     * additionally minted on every sold chunk of tokens in an amount equal
     * to 1/10 of the chunk sold.
     */
    uint256 public constant MAINTAINER_BONUS_PRICE_THRESHOLD =
        10 * 10**DECIMALS;

    /**
     * The price per token threshold above which a bounty bonus tokens are
     * additionally minted on every sold chunk of tokens in an amount equal
     * to 1/10 of the chunk sold.
     */
    uint256 public constant BOUNTY_BONUS_PRICE_THRESHOLD = 20 * 10**DECIMALS;

    /**
     * Adjusts the pointer value so it points to `supplyLUT` segment
     * corresponding to the token `supply`
     */
    function adjustNodeId(
        uint8 nodeId,
        uint256 supply,
        uint256[] storage supplyLUT
    ) public view returns (uint8) {
        if (supply < supplyLUT[nodeId + 1]) {
            if (supply < supplyLUT[nodeId]) {
                // decrease
                while (true) {
                    nodeId -= 1;
                    if (supply >= supplyLUT[nodeId]) {
                        return nodeId;
                    }
                }
            }
        } else {
            // increase
            while (true) {
                nodeId += 1;
                if (supply < supplyLUT[nodeId + 1]) {
                    return nodeId;
                }
            }
        }

        return nodeId;
    }

    /**
     * Determines the number of tokens that can be bought for the given
     * `usdAmount` at the specified `supply` according to the
     * price per token growth function represented by reference points from the
     * provided supply and price lookup tables (LUTs); additionally,
     * determines the number of maintainer and bounty bonus tokens to be minted.
     *
     * The tokens are sold in chunks, each chunk is defined by the distance
     * between two supply nodes in the `supplyLUT`; the price of a partial
     * chunk (the final chunk of each purchase) is determined using linear
     * approximation. See `LUTsLoader` for values stored in these LUTs.
     *
     * Maintainer and bounty bonus tokens are started to being calculated
     * after the current price per token surpasses the `MAINTAINER_BONUS_PRICE_THRESHOLD`
     * and `BOUNTY_BONUS_PRICE_THRESHOLD` thresholds respectively if not
     * suppressed by `suppressMaintainerBonus` and/or `suppressBountyBonus`
     * flags respectively. The amount of bonus tokens to be minted is being
     * added on each chunk rather than on each purchase to ensure
     * the price per token grows gradually even during the large atomic purchases.
     *
     * See `Result` struct for retval reference.
     *
     * @param usdAmount the amount of USD to spend
     * @param supply the current token supply
     * @param nodeId the adjusted pointer to the `supplyLUT` segment which corresponds to the current `supply`
     * @param suppressMaintainerBonus the flag to suppress maintainer bonus tokens calculations (regardless of the current price per token)
     * @param suppressBountyBonus the flag to suppress bounty bonus tokens calculations (regardless of the current price per token)
     * @param supplyLUT the LUT containing a supply growth scale
     * @param priceLUT the LUT containing price per token for each element of the `supplyLUT`
     */
    // solhint-disable-next-line function-max-lines
    function calcTokens(
        uint256 usdAmount,
        uint256 supply,
        uint8 nodeId,
        bool suppressMaintainerBonus,
        bool suppressBountyBonus,
        uint256[] storage supplyLUT,
        uint256[] storage priceLUT
    ) public view returns (Result memory r) {
        require(
            supply >= supplyLUT[nodeId] && supply < supplyLUT[nodeId + 1],
            "nodeId is out of sync"
        );

        r.nextNodeId = nodeId;

        // values are calculated on every loop
        _LoopState memory supplyNode = _LoopState(0, supply, 0);
        _LoopState memory priceNode = _LoopState(0, 0, 0);

        while (true) {
            supplyNode.prev = supplyLUT[r.nextNodeId];
            supplyNode.next = supplyLUT[r.nextNodeId + 1];

            priceNode.prev = priceLUT[r.nextNodeId];
            priceNode.next = priceLUT[r.nextNodeId + 1];

            // current price is determined using linear approximation
            priceNode.curr = _approxPricePerToken(supplyNode, priceNode);

            // take less than the beginning of the next node
            uint256 usdAmountMaxed = usdAmount * 10**DECIMALS;
            uint256 tokensByIteration;

            // this branch is for the case when the remaining usdAmount is not
            // enough to buy out the next segment completely (this is the last)
            if (
                supplyNode.next - supplyNode.curr >
                (2 * usdAmountMaxed) / (priceNode.next + priceNode.curr)
            ) {
                // adjust supply, as the segment is partially bought
                _LoopState memory adjustedSupplyNode = _LoopState(
                    supplyNode.prev,
                    supplyNode.curr +
                        usdAmountMaxed /
                        (priceNode.next + priceNode.curr),
                    supplyNode.next
                );

                tokensByIteration =
                    usdAmountMaxed /
                    _approxPricePerToken(adjustedSupplyNode, priceNode);

                r.tokensAmount += tokensByIteration;
                supplyNode.curr += tokensByIteration;

                // since this branch is partial, no more USD left
                usdAmount = 0;
            }
            // this branch is for the case when the whole segment is bought out
            else {
                tokensByIteration = supplyNode.next - supplyNode.curr;

                r.tokensAmount += tokensByIteration;
                supplyNode.curr = supplyNode.next;
                r.nextNodeId += 1;

                usdAmount -=
                    (tokensByIteration *
                        ((priceNode.curr + priceNode.next) / 2)) /
                    10**DECIMALS;
            }

            // calc bonus tokens for this loop
            if (
                false == suppressMaintainerBonus &&
                priceNode.curr >= MAINTAINER_BONUS_PRICE_THRESHOLD
            ) {
                r.maintainerBonusTokensAmount += tokensByIteration / 10;
                supplyNode.curr += tokensByIteration / 10;
            }

            if (
                false == suppressBountyBonus &&
                priceNode.curr >= BOUNTY_BONUS_PRICE_THRESHOLD
            ) {
                r.bountyBonusTokensAmount += tokensByIteration / 10;
                supplyNode.curr += tokensByIteration / 10;
            }

            // nodeId may change after calculated bonuses issued
            r.nextNodeId = adjustNodeId(
                r.nextNodeId,
                supplyNode.curr,
                supplyLUT
            );

            if (usdAmount == 0) break;
        }

        // adjust the current price per token for the caller code
        r.nextPricePerToken = _approxPricePerToken(supplyNode, priceNode);
    }

    /**
     * Linearly approximates the price per token between two nodes
     */
    function _approxPricePerToken(
        _LoopState memory supplyNode,
        _LoopState memory priceNode
    ) private pure returns (uint256) {
        return
            ((supplyNode.curr - supplyNode.prev) *
                (priceNode.next - priceNode.prev)) /
            (supplyNode.next - supplyNode.prev) +
            priceNode.prev;
    }
}