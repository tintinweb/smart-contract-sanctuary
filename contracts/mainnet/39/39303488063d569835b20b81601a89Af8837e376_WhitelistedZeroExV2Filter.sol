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

// Copyright (C) 2020  Argent Labs Ltd. <https://argent.xyz>

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

/**
 * @title ParaswapUtils
 * @notice Common methods used by Paraswap filters
 */
library ParaswapUtils {
    address constant internal ETH_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct ZeroExV2Order {
        address makerAddress;
        address takerAddress;
        address feeRecipientAddress;
        address senderAddress;
        uint256 makerAssetAmount;
        uint256 takerAssetAmount;
        uint256 makerFee;
        uint256 takerFee;
        uint256 expirationTimeSeconds;
        uint256 salt;
        bytes makerAssetData;
        bytes takerAssetData;
    }

    struct ZeroExV2Data {
        ZeroExV2Order[] orders;
        bytes[] signatures;
    }

    struct ZeroExV4Order {
        address makerToken;
        address takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        address maker;
        address taker;
        address txOrigin;
        bytes32 pool;
        uint64 expiry;
        uint256 salt;
    }

    struct ZeroExV4Signature {
        uint8 signatureType;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct ZeroExV4Data {
        ZeroExV4Order order;
        ZeroExV4Signature signature;
    }

    function hasValidUniV2Path(
        address[] memory _path,
        address _tokenRegistry,
        address _factory,
        bytes32 _initCode,
        address _weth
    )
        internal
        view
        returns (bool)
    {
        address[] memory lpTokens = new address[](_path.length - 1);
        for(uint i = 0; i < lpTokens.length; i++) {
            lpTokens[i] = pairFor(_path[i], _path[i+1], _factory, _initCode, _weth);
        }
        return hasTradableTokens(_tokenRegistry, lpTokens);
    }

    function pairFor(address _tokenA, address _tokenB, address _factory, bytes32 _initCode, address _weth) internal pure returns (address) {
        (address tokenA, address tokenB) = (_tokenA == ETH_TOKEN ? _weth : _tokenA, _tokenB == ETH_TOKEN ? _weth : _tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return(address(uint160(uint(keccak256(abi.encodePacked(
            hex"ff",
            _factory,
            keccak256(abi.encodePacked(token0, token1)),
            _initCode
        ))))));
    }

    function hasTradableTokens(address _tokenRegistry, address[] memory _tokens) internal view returns (bool) {
        (bool success, bytes memory res) = _tokenRegistry.staticcall(abi.encodeWithSignature("areTokensTradable(address[])", _tokens));
        return success && abi.decode(res, (bool));
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

import "../BaseFilter.sol";
import "./ParaswapUtils.sol";

/**
 * @title WhitelistedZeroExV2Filter
 * @notice Filter used for calls to the ZeroExV2 exchange at 0x080bf510fcbf18b91105470639e9561022937712.
 * Only trades with whitelisted market makers are allowed. Currently deployed to work with Paraswap's market makers only.
 * @author Olivier VDB - <[email protected]>
 */
contract WhitelistedZeroExV2Filter is BaseFilter {

    bytes4 private constant SELL = bytes4(keccak256(
        "marketSellOrdersNoThrow((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[],uint256,bytes[])"
    ));

    // Supported ParaswapPool market makers
    mapping(address => bool) public marketMakers;

    constructor(address[] memory _marketMakers) {
        for(uint i = 0; i < _marketMakers.length; i++) {
            marketMakers[_marketMakers[i]] = true;
        }
    }

    function isValid(address /*_wallet*/, address /*_spender*/, address /*_to*/, bytes calldata _data) external view override returns (bool valid) {
        // disable ETH transfer
        if (_data.length < 4) {
            return false;
        }

        bytes4 methodId = getMethod(_data);

        if(methodId == SELL) {
            ParaswapUtils.ZeroExV2Order[] memory orders = abi.decode(_data[4:], (ParaswapUtils.ZeroExV2Order[]));
            for(uint i = 0; i < orders.length; i++) {
                if(!marketMakers[orders[i].makerAddress]) {
                    return false;
                }
            }
            return true;
        }
        
        return false;
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