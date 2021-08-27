// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./IBEP20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

/// @title TokenInfoHelper - Helper contract to retrieve token information
/// @author WalletNow <[email protected]>
contract TokenInfoHelper {
    struct TokenInfo {
        string symbol;
        string name;
        uint8 decimals;
    }
    struct UniswapV2PairInfo {
        address token0;
        address token1;
        uint112 reserve0;
        uint112 reserve1;
        uint32 blockTimestampLast;
        uint256 totalSupply;
    }

    function getTokensInfo(address[] memory tokens) public view returns (TokenInfo[] memory tokensInfo) {
        tokensInfo = new TokenInfo[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokensInfo[i] = getTokenInfo(tokens[i]);
        }
    }

    function getTokenInfo(address token) public view returns (TokenInfo memory tokenInfo) {
        tokenInfo = TokenInfo('', '', 0);
        IBEP20 tk = IBEP20(token);

        try tk.symbol() returns (string memory symbol) {
            tokenInfo.symbol = symbol;
        } catch { }
        try tk.name() returns (string memory name) {
            tokenInfo.name = name;
        } catch { }
        try tk.decimals() returns (uint8 decimals) {
            tokenInfo.decimals = decimals;
        } catch { }
    }

    function getUniswapV2PairsInfo(address[] memory tokens) public view returns (UniswapV2PairInfo[] memory pairsInfo) {
        pairsInfo = new UniswapV2PairInfo[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            pairsInfo[i] = getUniswapV2PairInfo(tokens[i]);
        }
    }
    function getUniswapV2PairInfo(address token) public view returns (UniswapV2PairInfo memory pairInfo) {
        IUniswapV2Pair pair = IUniswapV2Pair(token);
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
        pairInfo = UniswapV2PairInfo(
            pair.token0(),
            pair.token1(),
            reserve0,
            reserve1,
            blockTimestampLast,
            pair.totalSupply()
        );
    }
    function getUniswapV2PairInfoForPair(address factory, address tokenA, address tokenB) public view returns (UniswapV2PairInfo memory pairInfo) {
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pairInfo = UniswapV2PairInfo(address(0), address(0), 0, 0, 0, 0);
        } else {
            pairInfo = getUniswapV2PairInfo(pair);
        }
    }

}