/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

/**
 * @title UniswapAnchoredViewInterface
 * @author Mainframe
 * @dev Used to interact with the Compound Open Price Feed.
 * https://compound.finance/docs/prices
 */
interface UniswapAnchoredViewInterface {
    /**
     * @notice Get the official price for a symbol.
     * @param symbol The symbol to fetch the price of.
     * @return Price denominated in USD, with 6 decimals.
     */
    function price(string memory symbol) external view returns (uint256);
}
