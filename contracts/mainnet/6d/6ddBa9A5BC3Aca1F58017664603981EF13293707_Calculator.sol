/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

library Calculator {
    struct Result {
        uint256 tokensAmount;
        uint256 maintainerBonusTokensAmount;
        uint256 bountyBonusTokensAmount;
        uint256 nextNodeId;
        uint256 nextPricePerToken;
    }

    // solhint-disable-next-line contract-name-camelcase
    struct _LoopState {
        uint256 prev;
        uint256 curr;
        uint256 next;
    }

    uint8 public constant DECIMALS = 18;

    uint256 public constant MAINTAINER_BONUS_PRICE_THRESHOLD =
        10 * 10**DECIMALS;

    uint256 public constant BOUNTY_BONUS_PRICE_THRESHOLD = 20 * 10**DECIMALS;

    function adjustNodeId(
        uint256 nodeId,
        uint256 supply,
        uint256[] storage supplyLUT
    ) public view returns (uint256) {
        if (supply < supplyLUT[nodeId + 1]) {
            if (supply < supplyLUT[nodeId]) {
                while (true) {
                    nodeId -= 1;
                    if (supply >= supplyLUT[nodeId]) {
                        return nodeId;
                    }
                }
            }
        } else {
            while (true) {
                nodeId += 1;
                if (supply < supplyLUT[nodeId + 1]) {
                    return nodeId;
                }
            }
        }

        return nodeId;
    }

    // solhint-disable-next-line function-max-lines
    function calcTokens(
        uint256 usdAmount,
        uint256 supply,
        uint256 nodeId,
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

        _LoopState memory supplyNode = _LoopState(0, supply, 0);
        _LoopState memory priceNode = _LoopState(0, 0, 0);

        while (true) {
            supplyNode.prev = supplyLUT[r.nextNodeId];
            supplyNode.next = supplyLUT[r.nextNodeId + 1];

            priceNode.prev = priceLUT[r.nextNodeId];
            priceNode.next = priceLUT[r.nextNodeId + 1];

            priceNode.curr = _approxPricePerToken(supplyNode, priceNode);

            uint256 usdAmountMaxed = usdAmount * 10**DECIMALS;
            uint256 tokensByIteration;

            if (
                supplyNode.next - supplyNode.curr >
                (2 * usdAmountMaxed) / (priceNode.next + priceNode.curr)
            ) {
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

                usdAmount = 0;
            }
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

            r.nextNodeId = adjustNodeId(
                r.nextNodeId,
                supplyNode.curr,
                supplyLUT
            );

            if (usdAmount == 0) break;
        }

        r.nextPricePerToken = _approxPricePerToken(supplyNode, priceNode);
    }

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

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode