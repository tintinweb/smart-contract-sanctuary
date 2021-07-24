/**
 *Submitted for verification at polygonscan.com on 2021-07-24
*/

// SPDX-License-Identifier: -- 🦉 <> 🔮 --

pragma solidity ^0.8.0;

interface ISwapRouterV2B {

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    )
        external
        view
        returns
    (
        uint[] memory amounts
    );
}

contract DAIEquivalent {

    uint256 constant _decimals = 18;
    uint256 constant YODAS_PER_WISE = 10 ** _decimals;
    uint256 constant BASE_DIFF = 1E12;

    address public constant WISE = 0xB77e62709e39aD1cbeEBE77cF493745AeC0F453a;
    address public constant WETH = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address public constant USDC = 0x9719d867A500Ef117cC201206B8ab51e794d3F82;

    ISwapRouterV2B public constant SWAP_ROUTER = ISwapRouterV2B(
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
    );

    uint256 public latestDAIEquivalent;
    address[] public _path = [WISE, WETH, USDC];

    function updateDAIEquivalent()
        external
    {
       latestDAIEquivalent = _getDAIEquivalent();
    }

    function getDAIEquivalent()
        external
        view
        returns (uint256)
    {
        return _getDAIEquivalent();
    }

    function _getDAIEquivalent()
        internal
        view
        returns (uint256)
    {
        try SWAP_ROUTER.getAmountsOut(
            YODAS_PER_WISE, _path
        ) returns (uint256[] memory results) {
            return results[2] * BASE_DIFF;
        } catch Error(string memory) {
            return latestDAIEquivalent;
        } catch (bytes memory) {
            return latestDAIEquivalent;
        }
    }
}