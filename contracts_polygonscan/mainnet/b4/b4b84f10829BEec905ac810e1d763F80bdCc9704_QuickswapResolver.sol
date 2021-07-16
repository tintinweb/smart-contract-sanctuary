// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {GelatoString} from "../../../lib/GelatoString.sol";
import {QuickswapData, QuickswapResult} from "../../../structs/SQuickswap.sol";
import {
    IUniswapV2Router02
} from "../../../interfaces/quickswap/IUniswapV2Router02.sol";
import {UNISWAPV2ROUTER02} from "../../../constants/CQuickswap.sol";
import {OK} from "../../../constants/CAaveServices.sol";

contract QuickswapResolver {
    using GelatoString for string;

    function multicallGetAmounts(QuickswapData[] memory _datas)
        public
        view
        returns (QuickswapResult[] memory)
    {
        QuickswapResult[] memory results = new QuickswapResult[](_datas.length);

        for (uint256 i = 0; i < _datas.length; i++) {
            try
                IUniswapV2Router02(UNISWAPV2ROUTER02).getAmountsOut(
                    _datas[i].amountIn,
                    _datas[i].path
                )
            returns (uint256[] memory amounts) {
                results[i] = QuickswapResult({
                    id: _datas[i].id,
                    amountOut: amounts[_datas[i].path.length - 1],
                    message: OK
                });
            } catch Error(string memory error) {
                results[i] = QuickswapResult({
                    id: _datas[i].id,
                    amountOut: 0,
                    message: error.prefix(
                        "QuickswapResolver.getAmountOut failed:"
                    )
                });
            } catch {
                results[i] = QuickswapResult({
                    id: _datas[i].id,
                    amountOut: 0,
                    message: "QuickswapResolver.getAmountOut failed:undefined"
                });
            }
        }

        return results;
    }
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.4;

library GelatoString {
    function startsWithOK(string memory _str) internal pure returns (bool) {
        if (
            bytes(_str).length >= 2 &&
            bytes(_str)[0] == "O" &&
            bytes(_str)[1] == "K"
        ) return true;
        return false;
    }

    function revertWithInfo(string memory _error, string memory _tracingInfo)
        internal
        pure
    {
        revert(string(abi.encodePacked(_tracingInfo, _error)));
    }

    function prefix(string memory _second, string memory _first)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_first, _second));
    }

    function suffix(string memory _first, string memory _second)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_first, _second));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

struct QuickswapResult {
    bytes32 id;
    uint256 amountOut;
    string message;
}

struct QuickswapData {
    bytes32 id;
    uint256 amountIn;
    address[] path;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IUniswapV2Router02 {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

address constant UNISWAPV2ROUTER02 = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

address constant GELATO = 0x7598e84B2E114AB62CAB288CE5f7d5f6bad35BbA;
string constant OK = "OK";