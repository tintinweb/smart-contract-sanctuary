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

/**
 * @title YearnV2Filter
 * @notice Filter used for deposits & withdrawals into/from YearnV2 vaults
 * such as the WETH vault at 0xa9fE4601811213c340e850ea305481afF02f5b28
 * @author Olivier VDB - <[email protected]>
 */
contract YearnV2Filter is BaseFilter {

    // Note: deposit and withdraw method implementations in Vyper have default values for all their arguments
    // (see https://github.com/yearn/yearn-vaults/blob/master/contracts/Vault.vy).
    // Each Vyper method therefore results in N+1 ABI methods for N parameters
    // These ABI methods are denoted (DEPOSIT|WITHDRAW){i} below where i is the number of parameters for the method

    bytes4 private constant DEPOSIT0 = bytes4(keccak256("deposit()"));
    bytes4 private constant DEPOSIT1 = bytes4(keccak256("deposit(uint256)"));
   
    bytes4 private constant WITHDRAW0 = bytes4(keccak256("withdraw()"));
    bytes4 private constant WITHDRAW1 = bytes4(keccak256("withdraw(uint256)"));

    bytes4 private constant ERC20_APPROVE = bytes4(keccak256("approve(address,uint256)"));

    function isValid(address _wallet, address _spender, address _to, bytes calldata _data) external view override returns (bool valid) {
        // disable ETH transfers
        if (_data.length < 4) {
            return false;
        }

        bytes4 method = getMethod(_data);
        if(_spender != _to) {
            return method == ERC20_APPROVE;
        }

        if(method == DEPOSIT0 || method == DEPOSIT1 || method == WITHDRAW0 || method == WITHDRAW1) {
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