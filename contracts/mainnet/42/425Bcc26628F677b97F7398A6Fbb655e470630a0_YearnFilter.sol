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

contract YearnFilter is BaseFilter {

    bytes4 private constant DEPOSIT = bytes4(keccak256("deposit(uint256)"));
    bytes4 private constant DEPOSIT_ETH = bytes4(keccak256("depositETH()"));
    bytes4 private constant WITHDRAW = bytes4(keccak256("withdraw(uint256)"));
    bytes4 private constant WITHDRAW_ALL = bytes4(keccak256("withdrawAll()"));
    bytes4 private constant WITHDRAW_ETH = bytes4(keccak256("withdrawETH(uint256)"));
    bytes4 private constant WITHDRAW_ALL_ETH = bytes4(keccak256("withdrawAllETH()"));

    bytes4 private constant ERC20_APPROVE = bytes4(keccak256("approve(address,uint256)"));

    bool public immutable isWeth;

    constructor (bool _isWeth) {
        isWeth = _isWeth;
    }

    function isValid(address /*_wallet*/, address _spender, address _to, bytes calldata _data) external view override returns (bool valid) {
        // disable ETH transfer, except for WETH vault
        if (_data.length < 4) {
            return (_data.length == 0) && isWeth;
        }
        bytes4 method = getMethod(_data);

        if(_spender == _to) {
            return 
                method == DEPOSIT ||
                method == WITHDRAW ||
                method == WITHDRAW_ALL ||
                isWeth && (
                    method == DEPOSIT_ETH ||
                    method == WITHDRAW_ETH ||
                    method == WITHDRAW_ALL_ETH
                );
        }

        // Note that yVault can only call transferFrom on the underlying token => no need to validate the token address here
        return method == ERC20_APPROVE;
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