// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

address constant GELATO = 0x3CACa7b48D0573D793d3b0279b5F0029180E83b6;
string constant OK = "OK";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

address constant UNISWAPV2ROUTER02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.7;

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
pragma solidity 0.8.7;

import {GelatoString} from "../../../lib/GelatoString.sol";
import {UniswapData, UniswapResult} from "../../../structs/SUniswap.sol";
import {
    IUniswapV2Router02
} from "../../../interfaces/uniswap/IUniswapV2Router02.sol";
import {UNISWAPV2ROUTER02} from "../../../constants/CUniswap.sol";
import {OK} from "../../../constants/CAaveServices.sol";

contract UniswapResolver {
    using GelatoString for string;

    function multicallGetAmounts(UniswapData[] memory _datas)
        public
        view
        returns (UniswapResult[] memory)
    {
        UniswapResult[] memory results = new UniswapResult[](_datas.length);

        for (uint256 i = 0; i < _datas.length; i++) {
            try
                IUniswapV2Router02(UNISWAPV2ROUTER02).getAmountsOut(
                    _datas[i].amountIn,
                    _datas[i].path
                )
            returns (uint256[] memory amounts) {
                results[i] = UniswapResult({
                    id: _datas[i].id,
                    amountOut: amounts[_datas[i].path.length - 1],
                    message: OK
                });
            } catch Error(string memory error) {
                results[i] = UniswapResult({
                    id: _datas[i].id,
                    amountOut: 0,
                    message: error.prefix(
                        "UniswapResolver.getAmountOut failed:"
                    )
                });
            } catch {
                results[i] = UniswapResult({
                    id: _datas[i].id,
                    amountOut: 0,
                    message: "UniswapResolver.getAmountOut failed:undefined"
                });
            }
        }

        return results;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

struct UniswapResult {
    bytes32 id;
    uint256 amountOut;
    string message;
}

struct UniswapData {
    bytes32 id;
    uint256 amountIn;
    address[] path;
}

