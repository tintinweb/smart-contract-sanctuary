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
 * @dev Pod contract interface.
 * Only the functions required for PoolTogetherAdapter contract are added.
 * The Pod contract is available here
 * github.com/pooltogether/pods/blob/master/contracts/Pod.sol.
 */
interface Pod {
    function balanceOfUnderlying(address) external view returns (uint256);
    function pendingDeposit(address) external view returns (uint256);
}


/**
 * @dev BasePool contract interface.
 * Only the functions required for PoolTogetherAdapter contract are added.
 * The BasePool contract is available here
 * github.com/pooltogether/pooltogether-contracts/blob/master/contracts/BasePool.sol.
 */
interface BasePool {
    function totalBalanceOf(address) external view returns (uint256);
}


/**
 * @title Adapter for PoolTogether protocol.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <[email protected]>
 */
contract PoolTogetherAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "PoolTogether pool";

    address internal constant DAI_POOL = 0x29fe7D60DdF151E5b52e5FAB4f1325da6b2bD958;
    address internal constant USDC_POOL = 0x0034Ea9808E620A0EF79261c51AF20614B742B24;
    address internal constant DAI_POD = 0x9F4C5D8d9BE360DF36E67F52aE55C1B137B4d0C4;
    address internal constant USDC_POD = 0x6F5587E191C8b222F634C78111F97c4851663ba4;

    /**
     * @return Amount of tokens locked in the pool by the given account.
     * @param token Address of the pool!
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        uint256 totalBalance = BasePool(token).totalBalanceOf(account);
        if (token == DAI_POOL) {
            totalBalance += getPodBalance(DAI_POD, account);
        } else if (token == USDC_POOL) {
            totalBalance += getPodBalance(USDC_POD, account);
        }

        return totalBalance;
    }

    function getPodBalance(address pod, address account) internal view returns (uint256) {
        return Pod(pod).balanceOfUnderlying(account) + Pod(pod).pendingDeposit(account);
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

