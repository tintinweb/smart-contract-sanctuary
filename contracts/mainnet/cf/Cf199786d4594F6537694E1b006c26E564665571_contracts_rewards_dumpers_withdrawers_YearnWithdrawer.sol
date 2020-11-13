// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.5.17;

import "@openzeppelin/contracts/access/roles/SignerRole.sol";
import "../imports/yERC20.sol";

contract YearnWithdrawer is SignerRole {
    function yearnWithdraw(address yTokenAddress) external onlySigner {
        yERC20 yToken = yERC20(yTokenAddress);
        uint256 balance = yToken.balanceOf(address(this));
        yToken.withdraw(balance);
    }
}
