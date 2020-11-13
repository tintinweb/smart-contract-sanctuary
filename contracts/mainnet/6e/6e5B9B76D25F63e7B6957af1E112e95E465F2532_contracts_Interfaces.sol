// SPDX-License-Identifier: GPL-3.0


pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IHegicStaking is IERC20 {
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
