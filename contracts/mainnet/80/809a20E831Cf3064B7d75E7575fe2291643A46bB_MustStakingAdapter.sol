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
 * @dev Tube contract interface.
 * Only the functions required for MustStakingAdapter contract are added.
 * The Tube contract is available here
 * etherscan.io/address/0x048Dda990f581e80EFfc72E4e1996AE548f8d64C#code
 * 
 */
interface StakingRewards {
    function balanceOf(address account) external view returns (uint256);
    function earned(address account) external view returns (uint256);
}


/**
 * @title Adapter for Tube protocol.
 * @dev Implementation of ProtocolAdapter interface.
 */
contract MustStakingAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant MUST = 0x9C78EE466D6Cb57A4d01Fd887D2b5dFb2D46288f;
    address internal constant UNI_V2_WETH_POOL = 0x15861b072abAd08b24460Add30b09E1481290F94;
    address internal constant STAKING_REWARD = 0x048Dda990f581e80EFfc72E4e1996AE548f8d64C;

    /**
     * @return Amount of TUBE for a given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
if (token == MUST) {
return StakingRewards(STAKING_REWARD).earned(account);
} else if (token == UNI_V2_WETH_POOL) {
return StakingRewards(STAKING_REWARD).balanceOf(account);
} else {
return 0;
}
}
}