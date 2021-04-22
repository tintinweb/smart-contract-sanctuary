// Copyright (C) 2021  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

import "./IFilter.sol";

abstract contract BaseFilter is IFilter {
    function getMethod(bytes memory _data) internal pure returns (bytes4 method) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            method := mload(add(_data, 0x20))
        }
    }
}

// Copyright (C) 2021  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

interface IFilter {
    function isValid(address _wallet, address _spender, address _to, bytes calldata _data) external view returns (bool valid);
}

// Copyright (C) 2021  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

import "./BaseFilter.sol";

contract UniswapV2UniZapFilter is BaseFilter {

    bytes4 private constant ERC20_APPROVE = bytes4(keccak256("approve(address,uint256)"));
    bytes4 constant internal ADD_LIQUIDITY_WITH_ETH = bytes4(keccak256("swapExactETHAndAddLiquidity(address,uint256,address,uint256)"));
    bytes4 constant internal REMOVE_LIQUIDITY_TO_ETH = bytes4(keccak256("removeLiquidityAndSwapToETH(address,uint256,uint256,address,uint256)"));
    bytes4 constant internal ADD_LIQUIDITY_WITH_TOKEN = bytes4(
        keccak256(
            "swapExactTokensAndAddLiquidity(address,address,uint256,uint256,address,uint256)"
            )
        );
    bytes4 constant internal REMOVE_LIQUIDITY_TO_TOKEN = bytes4(
        keccak256(
            "removeLiquidityAndSwapToToken(address,address,uint256,uint256,address,uint256)"
            )
        );

    // Token registry
    address public immutable tokenRegistry;
    // Uniswap V2 factory
    address public immutable uniFactory;
    // Uniswap v2 pair init code
    bytes32 public immutable uniInitCode;
    // WETH address
    address public immutable weth;

    constructor (address _tokenRegistry, address _uniFactory, bytes32 _uniInitCode, address _weth) {
        tokenRegistry = _tokenRegistry;
        uniFactory = _uniFactory;
        uniInitCode = _uniInitCode;
        weth = _weth;
    }

    function isValid(address _wallet, address _spender, address _to, bytes calldata _data) external view override returns (bool valid) {
        // not needed but detects failure early
        if (_data.length < 4) {
            return false;
        }
        bytes4 method = getMethod(_data);
        // UniZap method: check that pair is valid and recipient is the wallet
        if (_spender == _to) {
            if (method == ADD_LIQUIDITY_WITH_TOKEN || method == REMOVE_LIQUIDITY_TO_TOKEN) {
                (address tokenA, address tokenB, , , address recipient) = abi.decode(_data[4:], (address, address, uint256, uint256, address));
                return isValidPair(tokenA, tokenB) && recipient == _wallet;
            }
            if (method == ADD_LIQUIDITY_WITH_ETH) {
                (address token, , address recipient) = abi.decode(_data[4:], (address, uint256, address));
                return isValidPair(token, weth) && recipient == _wallet;
            }
            if (method == REMOVE_LIQUIDITY_TO_ETH) {
                (address token, , , address recipient) = abi.decode(_data[4:], (address, uint256, uint256, address));
                return isValidPair(token, weth) && recipient == _wallet;
            }
         // ERC20 methods
        } else {
            // only allow approve
            return (method == ERC20_APPROVE);
        }
    }

    function isValidPair(address _tokenA, address _tokenB) internal view returns (bool) {
        address pair = pairFor(_tokenA, _tokenB);
        (bool success, bytes memory res) = tokenRegistry.staticcall(abi.encodeWithSignature("isTokenTradable(address)", pair));
        return success && abi.decode(res, (bool));
    }

    function pairFor(address _tokenA, address _tokenB) internal view returns (address) {
        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        return(address(uint160(uint256(keccak256(abi.encodePacked(
            hex"ff",
            uniFactory,
            keccak256(abi.encodePacked(token0, token1)),
            uniInitCode
        ))))));
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999
  },
  "evmVersion": "istanbul",
  "libraries": {
    "": {}
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}