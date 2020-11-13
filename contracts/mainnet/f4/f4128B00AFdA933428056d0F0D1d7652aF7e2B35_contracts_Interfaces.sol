/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2020 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IHegicStaking is IERC20 {
    function lockupPeriod() external view returns (uint256);
    function MAX_SUPPLY() external view returns (uint256);
    function lastBoughtTimestamp(address) external view returns (uint256);

    function claimProfit() external returns (uint profit);
    function buy(uint amount) external;
    function sell(uint amount) external;
    function profitOf(address account) external view returns (uint profit);
}

interface IHegicStakingETH is IHegicStaking {
    function sendProfit() external payable;
}

interface IHegicStakingERC20 is IHegicStaking {
    function sendProfit(uint amount) external;
}
