/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Global Enums and Structs



struct LegacyStrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 rateLimit;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}
struct Limits {
    uint256 profitLimitRatio;
    uint256 lossLimitRatio;
    bool exists;
}

// Part: CustomHealthCheck

interface CustomHealthCheck {
    function check(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding,
        address callerStrategy
    ) external view returns (bool);
}

// File: CommonHealthCheck.sol

contract CommonHealthCheck {
    // Default Settings for all strategies
    uint256 constant MAX_BPS = 10_000;
    uint256 public profitLimitRatio;
    uint256 public lossLimitRatio;
    // profit & loss for specific strategy
    mapping(address => Limits) public strategiesLimits;

    address public governance;
    address public management;

    mapping(address => address) public checks;

    modifier onlyGovernance() {
        require(msg.sender == governance, "!authorized");
        _;
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == governance || msg.sender == management,
            "!authorized"
        );
        _;
    }

    constructor() public {
        governance = msg.sender;
        management = msg.sender;
        profitLimitRatio = 300;
        lossLimitRatio = 100; 
    }

    function setGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0));
        governance = _governance;
    }

    function setManagement(address _management) external onlyGovernance {
        require(_management != address(0));
        management = _management;
    }

    function setProfitLimitRatio(uint256 _profitLimitRatio) external onlyAuthorized {
        require(_profitLimitRatio < MAX_BPS);
        profitLimitRatio = _profitLimitRatio; 
    }

    function setlossLimitRatio(uint256 _lossLimitRatio) external onlyAuthorized {
        require(_lossLimitRatio < MAX_BPS);
       lossLimitRatio = _lossLimitRatio;
    }

    function setStrategyLimits(address _strategy, uint256 _profitLimitRatio, uint256 _lossLimitRatio) external onlyAuthorized {
       require(_lossLimitRatio < MAX_BPS);
       require(_profitLimitRatio < MAX_BPS);
        strategiesLimits[_strategy] = Limits(_profitLimitRatio, _lossLimitRatio, true);
    }

    function setCheck(address _strategy, address _check)
        external
        onlyAuthorized
    {
        checks[_strategy] = _check;
    }

    function check(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding,
        uint256 totalDebt
    ) external view returns (bool) {
        return
            _runChecks(profit, loss, debtPayment, debtOutstanding, totalDebt);
    }

    function _runChecks(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding,
        uint256 totalDebt
    ) internal view returns (bool) {
        address customCheck = checks[msg.sender];

        if (customCheck == address(0)) {
            return _executeDefaultCheck(profit, loss, totalDebt);
        }

        return
            CustomHealthCheck(customCheck).check(
                profit,
                loss,
                debtPayment,
                debtOutstanding,
                msg.sender
            );
    }

    function _executeDefaultCheck(
        uint256 _profit,
        uint256 _loss,
        uint256 _totalDebt
    ) internal view returns (bool) {
        Limits memory limits = strategiesLimits[msg.sender];
        uint256 _profitLimitRatio;
        uint256 _lossLimitRatio;
        if(limits.exists) {
            _profitLimitRatio = limits.profitLimitRatio;
            _lossLimitRatio = limits.lossLimitRatio;

        } else {
            _profitLimitRatio = profitLimitRatio;
            _lossLimitRatio = lossLimitRatio;
        }
        
        if (_profit > ((_totalDebt * _profitLimitRatio) / MAX_BPS)) {
            return false;
        }
        if (_loss > ((_totalDebt * _lossLimitRatio) / MAX_BPS)) {
            return false;
        }
        // health checks pass
        return true;
    }
}