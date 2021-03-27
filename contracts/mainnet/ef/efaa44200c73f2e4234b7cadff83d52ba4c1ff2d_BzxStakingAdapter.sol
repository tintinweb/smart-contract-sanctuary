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

import {ERC20} from "../../ERC20.sol";
import {ProtocolAdapter} from "../ProtocolAdapter.sol";

/**
 * @dev StakingRewards contract interface.
 * Only the functions required for AragonStakingAdapter contract are added.
 * The StakingRewards contract is available here
 * github.com/Synthetixio/synthetix/blob/master/contracts/StakingRewards.sol.
 */
interface StakingRewards {
    function earned(address)
        external
        view
        returns (
            uint256 bzrxRewardsEarned,
            uint256 stableCoinRewardsEarned,
            uint256 bzrxRewardsVesting,
            uint256 stableCoinRewardsVesting
        );

    function balanceOfByAssets(address account)
        external
        view
        returns (
            uint256 bzrxBalance,
            uint256 iBZRXBalance,
            uint256 vBZRXBalance,
            uint256 lPTokenBalance
        );

    function balanceOfByAsset(address token, address account)
        external
        view
        returns (uint256 balance);
}

/**
 * @title Adapter for BZX protocol (staking).
 * This will return current staking + earnigns that can be immediately withdrawn.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Roman Iftodi <[email protected]>
 */
contract BzxStakingAdapter is ProtocolAdapter {
    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant IBZRX = 0x18240BD9C07fA6156Ce3F3f61921cC82b2619157;
    address internal constant VBZRX = 0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F;
    address internal constant BZRX = 0x56d811088235F11C8920698a204A5010a788f4b3;
    address internal constant BPT = 0xe26A220a341EAca116bDa64cF9D5638A935ae629;
    address internal constant CURVE3CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    address internal constant STAKING_CONTRACT = 0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4;

    /**
     * @return Amount of staked LP tokens for a given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account)
        external
        view
        override
        returns (uint256)
    {
        if (token == IBZRX || token == VBZRX || token == BPT) {
            return StakingRewards(STAKING_CONTRACT).balanceOfByAsset(token, account);
        } else if (token == BZRX) {
            (uint256 bzrxEarnings, , , ) = StakingRewards(STAKING_CONTRACT).earned(account);
            return StakingRewards(STAKING_CONTRACT).balanceOfByAsset(token, account) + bzrxEarnings;
        } else if (token == CURVE3CRV) {
            (, uint256 curve3crv, , ) = StakingRewards(STAKING_CONTRACT).earned(account);
            return curve3crv;
        } else {
            return 0;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 10000
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