// SPDX-License-Identifier: GPL-3.0-or-later

// Inspired by Fei's TimelockedDelegator
// https://github.com/fei-protocol/fei-protocol-core/blob/master/contracts/dao/TimelockedDelegator.sol
// 
// Modified to
// - use our `TokenVesting` contract
// - remove TRIBE hardcoding

pragma solidity 0.6.9;

import "./TokenVesting.sol";
import "./Delegatee.sol";
import "./IDelegateableERC20.sol";
import "./SafeMath.sol";

/**
 * @title DelegateableTokenVesting
 * @author Alexander Schlindwein
 *
 * Vests an ERC20 token for `duration` seconds and unlocks to the `beneficiary` address.
 * The vesting `startTime` can be set in the future, which fully locks the tokens
 * until vesting begins.
 *
 * The voting power of the vested tokens can be delegated.
 */
contract DelegateableTokenVesting is TokenVesting {

    using SafeMath for uint;

    mapping(address => address) public _delegateContract;
    mapping(address => uint) public _delegateAmount;

    uint public _totalDelegated;

    event Delegate(address indexed delegatee, uint amount);
    event Undelegate(address indexed delegatee, uint amount);

    /**
     * Initializes the contract and delegates all voting power to `beneficiary`.
     *
     * @param beneficiary The recipient of the tokens when unlocked
     * @param startTime The timestamp when vesting begins. If 0, the current block timestamp is used.
     * @param duration The duration in seconds to vest the tokens
     * @param lockedToken The address of the vested token
     */
    constructor(address beneficiary, uint startTime, uint duration, address lockedToken)
        TokenVesting(beneficiary, startTime, duration, lockedToken) public 
    {
        IDelegateableERC20(_lockedToken).delegate(_beneficiary);
    }

    /**
     * Delegates `amount` voting power to `delegatee`.
     * If the `delegatee` already has delegated voting power the amount is added.
     * May only be called by the `beneficiary`.
     *
     * @param delegatee The address to receive the voting power
     * @param amount The amount of tokens to delegate
     */
    function delegate(address delegatee, uint amount) external onlyBeneficiary {
        require(amount <= tokenBalance(), "not-enough-tokens");

        if (_delegateContract[delegatee] != address(0)) {
            amount = amount.add(undelegate(delegatee));
        }

        IDelegateableERC20 token = IDelegateableERC20(_lockedToken);
        address delegateContract = address(new Delegatee(delegatee, address(token)));

        _delegateContract[delegatee] = delegateContract;
        _delegateAmount[delegatee] = amount;
        _totalDelegated = _totalDelegated.add(amount);

        require(token.transfer(delegateContract, amount), "transfer-failed");

        emit Delegate(delegatee, amount);
    }

    /**
     * Removes delegated voting power from `delegatee`.
     * May only be called by the `beneficiary`.
     *
     * @param delegatee The address to remove the voting power from.
     */
    function undelegate(address delegatee) public onlyBeneficiary returns (uint) {
        address delegateContract = _delegateContract[delegatee];
        require(delegateContract != address(0), "invalid-delegatee");

        Delegatee(delegateContract).withdraw();

        uint amount = _delegateAmount[delegatee];
        _totalDelegated = _totalDelegated.sub(amount);

        _delegateContract[delegatee] = address(0);
        _delegateAmount[delegatee] = 0;

        emit Undelegate(delegatee, amount);

        return amount;
    }

    /**
     * Returns the total amount of tokens: balance + delegated amount
     *
     * @return The total amount of tokens
     */
    function totalToken() public view override returns (uint) {
        return tokenBalance() + _totalDelegated;
    }

    /**
     * Accepts the `pendingBeneficiary` and transfers voting power.
     * May only be called by the `pendingBeneficiary`.
     */
    function acceptBeneficiary() external override {
        _setBeneficiary(msg.sender);
        IDelegateableERC20(_lockedToken).delegate(msg.sender);
    }

    /**
     * Internal getter to return the token balance in this contract.
     *
     * @return The token balance in this contract.
     */
    function tokenBalance() internal view returns (uint) {
        return IDelegateableERC20(_lockedToken).balanceOf(address(this));
    }
}