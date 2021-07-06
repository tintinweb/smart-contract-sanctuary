// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import { IERC20, ILendingPool, IProtocolDataProvider, IStableDebtToken, ITransmuter } from './Interfaces.sol';
import { SafeERC20 } from './Libraries.sol';

/**
 * This is a proof of concept starter contract, showing how uncollaterised loans are possible
 * using Aave v2 credit delegation.
 * This example supports stable interest rate borrows.
 * It is not production ready (!). User permissions and user accounting of loans should be implemented.
 * See @dev comments
 */

contract AaveCreditDelegation {
    using SafeERC20 for IERC20;

    ILendingPool constant lendingPool = ILendingPool(address(0x9FE532197ad76c5a68961439604C037EB79681F0)); // Kovan
    IProtocolDataProvider constant dataProvider = IProtocolDataProvider(address(0x744C1aaA95232EeF8A9994C4E0b3a89659D9AB79)); // Kovan

    address owner;

    constructor () {
        owner = msg.sender;
    }

    /**
     * Deposits collateral into the Aave, to enable credit delegation
     * This would be called by the delegator.
     * @param asset The asset to be deposited as collateral
     * @param amount The amount to be deposited as collateral
     * @param isPull Whether to pull the funds from the caller, or use funds sent to this contract
     *  User must have approved this contract to pull funds if `isPull` = true
     *
     */
    function depositCollateral(address asset, uint256 amount, bool isPull) public {
        if (isPull) {
            IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        }
        IERC20(asset).safeApprove(address(lendingPool), amount);
        lendingPool.deposit(asset, amount, address(this), 0);
    }

    /**
     * Approves the borrower to take an uncollaterised loan
     * @param borrower The borrower of the funds (i.e. delgatee)
     * @param amount The amount the borrower is allowed to borrow (i.e. their line of credit)
     * @param asset The asset they are allowed to borrow
     *
     * Add permissions to this call, e.g. only the owner should be able to approve borrowers!
     */
    function approveBorrower(address borrower, uint256 amount, address asset) public {
        (, address stableDebtTokenAddress,) = dataProvider.getReserveTokensAddresses(asset);
        IStableDebtToken(stableDebtTokenAddress).approveDelegation(borrower, amount);
    }

    /**
     * Repay an uncollaterised loan
     * @param amount The amount to repay
     * @param asset The asset to be repaid
     *
     * User calling this function must have approved this contract with an allowance to transfer the tokens
     *
     * You should keep internal accounting of borrowers, if your contract will have multiple borrowers
     */
    function repayBorrower(uint256 amount, address asset) public {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).safeApprove(address(lendingPool), amount);
        lendingPool.repay(asset, amount, 1, address(this));
    }

    /**
     * Withdraw all of a collateral as the underlying asset, if no outstanding loans delegated
     * @param asset The underlying asset to withdraw
     *
     * Add permissions to this call, e.g. only the owner should be able to withdraw the collateral!
     */
    function withdrawCollateral(address asset) public {
        (address aTokenAddress,,) = dataProvider.getReserveTokensAddresses(asset);
        uint256 assetBalance = IERC20(aTokenAddress).balanceOf(address(this));
        lendingPool.withdraw(asset, assetBalance, owner);
    }
}

contract AlchemixStakeUnstake {

    ITransmuter constant alTransmuter = ITransmuter(address(0x9FE532197ad76c5a68961439604C037EB79681F0));
    function stakeAlchemix(uint256 amount) public {

        alTransmuter.stake(amount);
    }

}