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


interface ITimeWarpPool {
    function userStacked(address) external view returns (uint256);

    function userLastReward(address) external view returns (uint32);

    function getReward(address, uint32) external view returns (uint256, uint32);
}


interface IUniswapV2Pair {
    function totalSupply() external view returns (uint256);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

/**
 * @title Adapter for Time protocol (staking).
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <[email protected]>
 */
contract TimeStakingAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant STACKING_POOL_TIME = 0xa106dd3Bc6C42B3f28616FfAB615c7d494Eb629D;
    address internal constant STACKING_POOL_TIME_ETH_LP = 0x55c825983783c984890bA89F7d7C9575814D83F2;
    address internal constant UNISWAP_POOL_TIME_ETH_LP = 0x1d474d4B4A62b0Ad0C819841eB2C74d1c5050524;

    /**
     * @return Amount of staked TIME tokens for a given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address, address account) external view override returns (uint256) {
        uint256 totalBalance = 0;

        totalBalance += ITimeWarpPool(STACKING_POOL_TIME).userStacked(account);
        uint32 lastReward = ITimeWarpPool(STACKING_POOL_TIME).userLastReward(account);
        (uint256 amount,) = ITimeWarpPool(STACKING_POOL_TIME).getReward(account, lastReward);
        totalBalance += amount;

        uint256 balanceLP = ITimeWarpPool(STACKING_POOL_TIME_ETH_LP).userStacked(account);
        uint256 totalSupply = IUniswapV2Pair(UNISWAP_POOL_TIME_ETH_LP).totalSupply();
        (uint112 reserve0,,) = IUniswapV2Pair(UNISWAP_POOL_TIME_ETH_LP).getReserves();
        if (balanceLP > 0) {
            totalBalance += balanceLP / totalSupply * reserve0;
        }
        return totalBalance;
    }
}

{
  "optimizer": {
    "enabled": false,
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