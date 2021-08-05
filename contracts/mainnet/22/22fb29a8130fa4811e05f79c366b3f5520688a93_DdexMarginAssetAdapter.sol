// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import { ProtocolAdapter } from "../ProtocolAdapter.sol";


/**
 * @dev Hydro contract interface.
 * Only the functions required for DdexMarginAssetAdapter contract are added.
 * The Hydro contract is available here
 * github.com/HydroProtocol/protocol/blob/master/contracts/Hydro.sol.
 */
interface Hydro {
    function getAllMarketsCount() external view returns (uint256);
    function marketBalanceOf(uint16, address, address) external view returns (uint256);
}


/**
 * @title Asset adapter for DDEX protocol (margin account).
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <[email protected]>
 */
contract DdexMarginAssetAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant HYDRO = 0x241e82C79452F51fbfc89Fac6d912e021dB1a3B7;
    address internal constant HYDRO_ETH = 0x000000000000000000000000000000000000000E;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @return Amount of tokens held by the given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        uint256 allMarketsCount = Hydro(HYDRO).getAllMarketsCount();
        uint256 totalBalance = 0;

        for (uint16 i = 0; i < uint16(allMarketsCount); i++) {
            try Hydro(HYDRO).marketBalanceOf(
                i,
                token == ETH ? HYDRO_ETH : token,
                account
            ) returns (uint256 marketBalance) {
                totalBalance += marketBalance;
            } catch {} // solhint-disable-line no-empty-blocks
        }

        return totalBalance;
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;


/**
 * @title Protocol adapter interface.
 * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.
 * @author Igor Sobolev <[email protected]>
 */
interface ProtocolAdapter {

    /**
     * @dev MUST return "Asset" or "Debt".
     * SHOULD be implemented by the public constant state variable.
     */
    function adapterType() external pure returns (string memory);

    /**
     * @dev MUST return token type (default is "ERC20").
     * SHOULD be implemented by the public constant state variable.
     */
    function tokenType() external pure returns (string memory);

    /**
     * @dev MUST return amount of the given token locked on the protocol by the given account.
     */
    function getBalance(address token, address account) external view returns (uint256);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
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