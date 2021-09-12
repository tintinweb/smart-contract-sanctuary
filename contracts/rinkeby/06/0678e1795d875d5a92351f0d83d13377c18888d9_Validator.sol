/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
library Common {
    struct Allocation {
        uint8 token;
        uint256 percentageBps;
    }

    struct Holding {
        uint8 token;
        uint256 amtInLocalDecimals;
    }

    struct Portfolio {
        Common.Allocation[] allocations;
        Common.Holding[] holdings;
        bool isPending;
        bool isTopUp;
        uint256 pendingFunding;
    }
}

library Validator {
    function validate(
        Common.Allocation[] memory allocations,
        address[] memory supportedTokens,
        uint256 MAX_ALLOCATIONS
    ) public pure returns (bool) {
        require(
            allocations.length <= supportedTokens.length &&
                allocations.length <= MAX_ALLOCATIONS,
            "TOO MANY ALLOCATIONS"
        );

        uint256 totalBps = 0;
        for (uint256 i = 0; i < allocations.length; i++) {
            Common.Allocation memory allocation = allocations[i];

            require(
                allocation.percentageBps > 500 &&
                    allocation.percentageBps <= 10000,
                "PERCENTAGE INVALID"
            );
            require(isSupportedToken(allocation.token, supportedTokens));
            totalBps += allocation.percentageBps;
        }
        require(totalBps == 10000, "PERCENTAGES INCORRECT");
        return true;
    }

    function isSupportedToken(uint8 token, address[] memory supportedTokens)
        public
        pure
        returns (bool)
    {
        require(token >= 0, "UNSUPPORTED TOKEN");
        require(token < supportedTokens.length, "UNSUPPORTED TOKEN");
        return true;
    }
}