/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// File: contracts/common/interfaces/Uniswap.sol

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Interface for Uniswap v2.
 * @dev This only contains the methods/events that we use in our contracts or offchain infrastructure.
 */
abstract contract Uniswap {
    // Called after every swap showing the new uniswap "price" for this token pair.
    event Sync(uint112 reserve0, uint112 reserve1);
    // Base currency.
    address public token0;
    // Quote currency.
    address public token1;
}

// File: contracts/common/test/UniswapMock.sol

pragma solidity ^0.6.0;


/**
 * @title Uniswap v2 Mock that allows manual price injection.
 */
contract UniswapMock is Uniswap {
    function setTokens(address _token0, address _token1) external {
        token0 = _token0;
        token1 = _token1;
    }

    function setPrice(uint112 reserve0, uint112 reserve1) external {
        emit Sync(reserve0, reserve1);
    }
}