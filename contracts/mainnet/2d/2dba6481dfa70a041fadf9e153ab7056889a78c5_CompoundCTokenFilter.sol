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

import "./BaseFilter.sol";

contract CompoundCTokenFilter is BaseFilter {

    bytes4 private constant CETH_MINT = bytes4(keccak256("mint()"));
    bytes4 private constant CERC20_MINT = bytes4(keccak256("mint(uint256)"));
    bytes4 private constant CTOKEN_REDEEM = bytes4(keccak256("redeem(uint256)"));
    bytes4 private constant CTOKEN_REDEEM_UNDERLYING = bytes4(keccak256("redeemUnderlying(uint256)"));
    bytes4 private constant CTOKEN_BORROW = bytes4(keccak256("borrow(uint256)"));
    bytes4 private constant CETH_REPAY_BORROW = bytes4(keccak256("repayBorrow()"));
    bytes4 private constant CERC20_REPAY_BORROW = bytes4(keccak256("repayBorrow(uint256)"));
    bytes4 private constant ERC20_APPROVE = bytes4(keccak256("approve(address,uint256)"));

    address public immutable underlying;

    constructor (address _underlying) {
        underlying = _underlying;
    }

    function isValid(address /*_wallet*/, address _spender, address _to, bytes calldata _data) external view override returns (bool valid) {
        // disable ETH transfer for cErc20
        if (_data.length < 4) {
            return (_data.length == 0) && (underlying == address(0));
        }
        bytes4 method = getMethod(_data);
        // cToken methods
        if (_spender == _to) {
            if (underlying == address(0)) {
                return (
                    method == CETH_MINT ||
                    method == CTOKEN_REDEEM ||
                    method == CTOKEN_REDEEM_UNDERLYING ||
                    method == CTOKEN_BORROW ||
                    method == CETH_REPAY_BORROW);
            } else {
                return (
                    method == CERC20_MINT ||
                    method == CTOKEN_REDEEM ||
                    method == CTOKEN_REDEEM_UNDERLYING ||
                    method == CTOKEN_BORROW ||
                    method == CERC20_REPAY_BORROW);
            }
        // ERC20 methods
        } else {
            // only allow an approve on the underlying 
            return (method == ERC20_APPROVE && underlying == _to);
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999
  },
  "evmVersion": "istanbul",
  "libraries": {},
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