/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

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

abstract contract BaseFilter is IFilter {
    function getMethod(bytes memory _data) internal pure returns (bytes4 method) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            method := mload(add(_data, 0x20))
        }
    }
}

/**
 * @title ZkSyncFilter
 * @notice Filter used to claim your zkSync account.
 * @author Axel Delamarre - <[email protected]>
 */
contract ZkSyncFilter is BaseFilter {

  bytes4 private constant SET_AUTH_PUBKEY_HASH = bytes4(keccak256("setAuthPubkeyHash(bytes,uint32)"));

  function isValid(address /*_wallet*/, address _spender, address _to, bytes calldata _data) external pure override returns (bool valid) {
    // disable ETH transfer
    if (_data.length < 4) {
        return false;
    }

    bytes4 methodId = getMethod(_data);
    return _spender == _to && methodId == SET_AUTH_PUBKEY_HASH;
  }
}