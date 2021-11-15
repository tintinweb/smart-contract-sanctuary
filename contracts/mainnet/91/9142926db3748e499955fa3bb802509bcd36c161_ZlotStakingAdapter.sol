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


interface ERC20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
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

import { ERC20 } from "../../ERC20.sol";
import { ProtocolAdapter } from "../ProtocolAdapter.sol";


/**
 * @dev StakingRewards contract interface.
 * Only the functions required for YearnStakingV1Adapter contract are added.
 * The StakingRewards contract is available here
 * github.com/Synthetixio/synthetix/blob/master/contracts/StakingRewards.sol.
 */
interface StakingRewards {
    function earned(address) external view returns (uint256);
}


/**
 * @title Adapter for zlot.finance protocol.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <[email protected]>
 */
contract ZlotStakingAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant ZLOT = 0xA8e7AD77C60eE6f30BaC54E2E7c0617Bd7B5A03E;

    address internal constant UNI_HEGIC_ZHEGIC = 0x6Ddc12eF2940137F89af63F05196a4c9D4883Ee4;
    address internal constant UNI_WETH_ZHEGIC = 0x2855d51a6c054e5e879BfcE18e3a028aE5c190F7;
    address internal constant UNI_HEGIC_DAI = 0x502700F282e6BfC2Bb3b805893fAdFfaCf688e7b;
    address internal constant UNI_DAI_ZLOT = 0x48598b64d88aB649e49e82f9e328eEeE5011a8ff;

    address internal constant UNI_HEGIC_ZHEGIC_POOL = 0xeA21E881521aAbf9D5063d0c036996C4D26A82e7;
    address internal constant UNI_WETH_ZHEGIC_POOL = 0x27f405bdd5a0A90856f5Fe408165825fe2f2D26C;
    address internal constant UNI_HEGIC_DAI_POOL = 0xf2545371545A1c45f1646bAE2AD338cF683B3dA6;
    address internal constant UNI_DAI_ZLOT_POOL = 0x0fd7379436E2aCBa072913c6c8dDB8D6A2f62Acf;

    /**
     * @return Amount of staked tokens / rewards earned after staking for a given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        if (token == ZLOT) {
            uint256 totalRewards = 0;

            totalRewards += StakingRewards(UNI_HEGIC_ZHEGIC_POOL).earned(account);
            totalRewards += StakingRewards(UNI_WETH_ZHEGIC_POOL).earned(account);
            totalRewards += StakingRewards(UNI_HEGIC_DAI_POOL).earned(account);
            totalRewards += StakingRewards(UNI_DAI_ZLOT_POOL).earned(account);

            return totalRewards;
        } else if (token == UNI_HEGIC_ZHEGIC) {
            return ERC20(UNI_HEGIC_ZHEGIC_POOL).balanceOf(account);
        } else if (token == UNI_WETH_ZHEGIC) {
            return ERC20(UNI_WETH_ZHEGIC_POOL).balanceOf(account);
        } else if (token == UNI_HEGIC_DAI) {
            return ERC20(UNI_HEGIC_DAI_POOL).balanceOf(account);
        } else if (token == UNI_DAI_ZLOT) {
            return ERC20(UNI_DAI_ZLOT_POOL).balanceOf(account);
        } else {
            return 0;
        }
    }
}

