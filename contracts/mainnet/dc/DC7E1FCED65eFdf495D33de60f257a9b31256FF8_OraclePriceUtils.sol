/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./CarefulMath.sol";
import "./UniswapAnchoredViewInterface.sol";

/**
 * @title OraclePriceUtils
 * @author Mainframe
 */
library OraclePriceUtils {
    /**
     * @notice Converts the 6 decimal prices returned by the Open Price Feed to mantissa form,
     * which has 18 decimals.
     *
     * @dev Requirements:
     * - The price returned by the oracle cannot be zero.
     * - The scaled price cannot overflow.
     *
     * @param oracle The oracle contract.
     * @param symbol The Erc20 symbol of the token for which to query the price.
     * @param precisionScalar A power of 10.
     * @return The upscaled price as a mantissa.
     */
    function getAdjustedPrice(
        UniswapAnchoredViewInterface oracle,
        string memory symbol,
        uint256 precisionScalar
    ) internal view returns (MathError, uint256) {
        string memory actualSymbol = getActualSymbol(symbol);
        uint256 price = oracle.price(actualSymbol);
        require(price > 0, "ERR_PRICE_ZERO");

        /* Integers in Solidity can overflow. */
        uint256 adjustedPrice = price * precisionScalar;
        if (adjustedPrice / price != precisionScalar) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, adjustedPrice);
        }
    }

    /**
     * @dev See https://fravoll.github.io/solidity-patterns/string_equality_comparison.html
     */
    function areStringsEqual(string memory a, string memory b) internal pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }

    /**
     * @notice Handles the special collateral assets by converting them to the symbol
     * the oracle expects.
     * @param symbol The Erc20 symbol of the collateral.
     * @return The symbol as a string in memory.
     */
    function getActualSymbol(string memory symbol) internal pure returns (string memory) {
        if (areStringsEqual(symbol, "WETH")) {
            return "ETH";
        } else {
            return symbol;
        }
    }
}
