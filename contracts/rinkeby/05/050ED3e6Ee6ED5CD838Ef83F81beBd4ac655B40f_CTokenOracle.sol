// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {Decimal} from "../../lib/Decimal.sol";
import {SafeMath} from "../../lib/SafeMath.sol";

import {IChainLinkAggregator} from "../chainlink/IChainLinkAggregator.sol";
import {IOracle} from "../IOracle.sol";

import {ICToken} from "./ICToken.sol";

contract CTokenOracle is IOracle {

    using SafeMath for uint256;
    using SafeMath for uint8;

    uint256 public precisionScalar;

    uint256 public chainlinkTokenScalar;
    uint256 public chainlinkEthScalar;

    uint256 constant BASE = 10 ** 18;

    ICToken public cToken;

    IChainLinkAggregator public chainLinkTokenAggregator;
    IChainLinkAggregator public chainLinkEthAggregator;

    constructor (
        address _cTokenAddress,
        address _chainLinkTokenAggregator,
        address _chainLinkEthAggregator
    )
        public
    {
        cToken = ICToken(_cTokenAddress);
        chainLinkTokenAggregator = IChainLinkAggregator(_chainLinkTokenAggregator);
        chainLinkEthAggregator = IChainLinkAggregator(_chainLinkEthAggregator);

        // For CUSDC, this is 8
        uint8 cTokenDecimals = cToken.decimals();

        // For USDC, this is 6
        uint8 underlyingDecimals = ICToken(cToken.underlying()).decimals();

        // The result, in the case of cUSDC, will be 16
        precisionScalar = uint256(18 + underlyingDecimals - cTokenDecimals);

        chainlinkTokenScalar = uint256(18 - chainLinkTokenAggregator.decimals());
        chainlinkEthScalar = uint256(18 - chainLinkEthAggregator.decimals());
    }

    function fetchCurrentPrice()
        external
        view
        returns (Decimal.D256 memory)
    {
        uint256 exchangeRate = cToken.exchangeRateStored(); // 213927934173700 (16 dp)

        // Scaled exchange amount
        uint256 cTokenAmount = exchangeRate.mul(BASE).div(uint256(10 ** precisionScalar));

        // Some result in x decimal places
        uint256 priceInEth = uint256(
            chainLinkTokenAggregator.latestAnswer()
        ).mul(10 ** chainlinkTokenScalar);

        uint256 priceOfEth = uint256(
            chainLinkEthAggregator.latestAnswer()
        ).mul(10 ** chainlinkEthScalar);

        // Multiply the two together to get the value of 1 cToken
        uint256 result = cTokenAmount.mul(priceInEth).div(BASE);
        result = result.mul(priceOfEth).div(BASE);

        require(
            result > 0,
            "CTokenOracle: cannot report a price of 0"
        );

        return Decimal.D256({
            value: result
        });

    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {SafeMath} from "../lib/SafeMath.sol";
import {Math} from "./Math.sol";

/**
 * @title Decimal
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Functions ============

    function one()
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function onePlus(
        D256 memory d
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.add(BASE) });
    }

    function mul(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, d.value, BASE);
    }

    function mul(
        D256 memory d1,
        D256 memory d2
    )
        internal
        pure
        returns (D256 memory)
    {
        return Decimal.D256({ value: Math.getPartial(d1.value, d2.value, BASE) });
    }

    function div(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, BASE, d.value);
    }

    function add(
        D256 memory d,
        uint256 amount
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.add(amount) });
    }

    function sub(
        D256 memory d,
        uint256 amount
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.sub(amount) });
    }

}

pragma solidity ^0.5.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

interface IChainLinkAggregator {

    function decimals()
        external
        view
        returns (uint8);

    function latestAnswer()
        external
        view
        returns (int256);

    function latestTimestamp()
        external
        view
        returns (uint256);

    function latestRound()
        external
        view
        returns (uint256);

    function getAnswer(uint256 roundId)
        external
        view
        returns (int256);

    function getTimestamp(uint256 roundId)
        external
        view
        returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 timestamp
    );

    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {Decimal} from "../lib/Decimal.sol";

interface IOracle {

    function fetchCurrentPrice()
        external
        view
        returns (Decimal.D256 memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

interface ICToken {

    function exchangeRateStored()
        external
        view
        returns (uint);

    function underlying()
        external
        view
        returns (address);

    function decimals()
        external
        view
        returns (uint8);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {SafeMath} from "./SafeMath.sol";

/**
 * @title Math
 *
 * Library for non-standard Math functions
 */
library Math {
    using SafeMath for uint256;

    uint256 constant BASE = 10**18;

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function to128(
        uint256 number
    )
        internal
        pure
        returns (uint128)
    {
        uint128 result = uint128(number);
        require(
            result == number,
            "Math: Unsafe cast to uint128"
        );
        return result;
    }

    function min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a > b ? a : b;
    }

    /**
     * @dev Performs a / b, but rounds up instead
     */
    function roundUpDiv(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a
            .mul(BASE)
            .add(b.sub(1))
            .div(b);
    }

    /**
     * @dev Performs a * b / BASE, but rounds up instead
     */
    function roundUpMul(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a
            .mul(b)
            .add(BASE.sub(1))
            .div(BASE);
    }
}