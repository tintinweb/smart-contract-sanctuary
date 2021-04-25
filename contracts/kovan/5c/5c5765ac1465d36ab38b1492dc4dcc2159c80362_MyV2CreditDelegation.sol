// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import { IERC20, ILendingPool, IProtocolDataProvider, IStableDebtToken } from './Interfaces.sol';
import { SafeERC20 } from './Libraries.sol';

/**
 * This is a proof of concept starter contract, showing how uncollaterised loans are possible
 * using Aave v2 credit delegation.
 * This example supports stable interest rate borrows.
 * It is not production ready (!). User permissions and user accounting of loans should be implemented.
 * See @dev comments
 */
 
contract MyV2CreditDelegation {
    using SafeERC20 for IERC20;
    
    ILendingPool constant lendingPool = ILendingPool(address(0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe)); // Kovan
    IProtocolDataProvider constant dataProvider = IProtocolDataProvider(address(0x3c73A5E5785cAC854D468F727c606C07488a29D6)); // Kovan
    
    address owner;

    constructor () public {
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