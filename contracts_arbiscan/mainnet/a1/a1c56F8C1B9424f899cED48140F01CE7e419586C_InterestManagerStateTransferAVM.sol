// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

import "./IInterestManagerStateTransferAVM.sol";
import "./InterestManagerBaseAVM.sol";

/**
 * @title InterestManagerStateTransferAVM
 * @author Alexander Schlindwein
 *
 * The L2 InterestManager logic for the state transfer from L1.
 * This implementation will also not invest anything into Compound or similar,
 * and will remain the logic until Compound has moved to L2.
 */
contract InterestManagerStateTransferAVM is InterestManagerBaseAVM, IInterestManagerStateTransferAVM {

    /**
     * Initializes the contract. 
     *
     * @param owner The owner (IdeaTokenExchange)
     * @param dai The address of the Dai contract
     */
    function initializeStateTransfer(address owner, address dai) external override {
        require(address(_dai) == address(0), "already-init");
        initializeBaseInternal(owner, dai);
    }

    /**
     * Increments the _totalShares. Used for state transfer.
     * Can only be called by the IdeaTokenExchange.
     *
     * @param amount The amount by which to increase _totalShares
     */
    function addToTotalShares(uint amount) external override onlyOwner {
        _totalShares = _totalShares.add(amount);
    }

    /**
     * Invest an amount of Dai. Does nothing for now, just holds the Dai.
     *
     * @param amount The amount of Dai to invest
     */
    function investInternal(uint amount) internal override {}

    /**
     * Redeems an amount of Dai.
     *
     * @param amount The amount of Dai to redeem
     */
    function redeemInternal(address recipient, uint amount) internal override {
        require(_dai.transfer(recipient, amount), "dai-transfer");
    }

    /**
     * Accrues interest. Does nothing for now.
     */
    function accrueInterest() external override {}

    /**
     * Returns the total amount of Dai holdings.
     *
     * @return The total amount of Dai holdings.
     */
    function getTotalDaiReserves() public view override returns (uint) {
        return _dai.balanceOf(address(this));
    }
}