// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IPCVDripController.sol"; 
import "./Incentivized.sol"; 
import "./Timed.sol";

/// @title a PCV dripping controller
/// @author Fei Protocol
contract PCVDripController is IPCVDripController, CoreRef, Timed, Incentivized {
 
    /// @notice source PCV deposit to withdraw from
    IPCVDeposit public override source;

    /// @notice target address to drip to
    IPCVDeposit public override target;

    /// @notice amount to drip after each window
    uint256 public override dripAmount;

    /// @notice PCV Drip Controller constructor
    /// @param _core Fei Core for reference
    /// @param _source the PCV deposit to drip from
    /// @param _target the PCV deposit to drip to
    /// @param _frequency frequency of dripping
    /// @param _dripAmount amount to drip on each drip
    /// @param _incentiveAmount the FEI incentive for calling drip
    constructor(
        address _core,
        IPCVDeposit _source,
        IPCVDeposit _target,
        uint256 _frequency,
        uint256 _dripAmount,
        uint256 _incentiveAmount
    ) CoreRef(_core) Timed(_frequency) Incentivized(_incentiveAmount) {
        target = _target;
        emit TargetUpdate(address(0), address(_target));

        source = _source;
        emit SourceUpdate(address(0), address(_source));

        dripAmount = _dripAmount;
        emit DripAmountUpdate(0, _dripAmount);

        // start timer
        _initTimed();
    }

    /// @notice drip PCV to target by withdrawing from source
    function drip()
        external
        override
        afterTime
        whenNotPaused
    {
        require(dripEligible(), "PCVDripController: not eligible");
        
        // reset timer
        _initTimed();

        // incentivize caller
        _incentivize();
        
        // drip
        source.withdraw(address(target), dripAmount);
        target.deposit(); // trigger any deposit logic on the target
        emit Dripped(address(source), address(target), dripAmount);
    }

    /// @notice set the new PCV Deposit source
    function setSource(IPCVDeposit newSource)
        external
        override
        onlyGovernor
    {
        require(address(newSource) != address(0), "PCVDripController: zero address");

        address oldSource = address(source);
        source = newSource;
        emit SourceUpdate(oldSource, address(newSource));
    }

    /// @notice set the new PCV Deposit target
    function setTarget(IPCVDeposit newTarget)
        external
        override
        onlyGovernor
    {
        require(address(newTarget) != address(0), "PCVDripController: zero address");

        address oldTarget = address(target);
        target = newTarget;
        emit TargetUpdate(oldTarget, address(newTarget));
    }

    /// @notice set the new drip amount
    function setDripAmount(uint256 newDripAmount)
        external
        override
        onlyGovernor
    {
        require(newDripAmount != 0, "PCVDripController: zero drip amount");

        uint256 oldDripAmount = dripAmount;
        dripAmount = newDripAmount;
        emit DripAmountUpdate(oldDripAmount, newDripAmount);
    }

    /// @notice checks whether the target balance is less than the drip amount
    function dripEligible() public view virtual override returns(bool) {
        return target.balance() < dripAmount;
    }
}