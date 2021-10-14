/*
* SPDX-License-Identifier: UNLICENSED
* Copyright © 2021 Blocksquare d.o.o.
*/

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";

interface RevenueDistributionHelpers {
    function transfer(address to, uint256 amount) external returns (bool success);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function canDistributeRent(address user) external view returns (bool);
}

contract RevenueDistribution is Ownable {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) private _revenueAmount;
    mapping(address => uint256) private _totalRevenue;
    mapping(address => uint256) private _totalPayout;
    mapping(address => uint256) private _totalDays;

    address private _dai;
    address private _data;

    event RevenueAdded(address indexed property, address[] users, uint256[] amounts, uint256 fromTime, uint256 toTime);
    event RevenueClaimed(address indexed property, address indexed user, uint256 amount, uint256 time);
    event RevenueSent(address indexed property, address indexed user, uint256 amount, uint256 time);

    constructor(address data, address dai) public {
        _data = data;
        _dai = dai;
    }

    // If System admin just add it
    // If CP check that he can add rent
    function addRevenue(address property, address[] memory users, uint256[] memory amount, uint256 from, uint256 to) public {
        require(users.length == amount.length, "RevenueDistribution: number of user addresses must be the same as number of values");
        require(from < to, "RevenueDistribution: From must be lower than to");
        require(RevenueDistributionHelpers(_data).canDistributeRent(msg.sender), "RevenueDistribution: caller doesn't have permission to add rent");
        uint256 diff = to.sub(from);
        uint256 diffDays = diff.div(1 days);
        require(diffDays > 0, "RevenueDistribution:At least one day must pass");
        uint256 amountToPay = 0;
        for (uint256 i = 0; i < users.length; i++) {
            _revenueAmount[property][users[i]] = _revenueAmount[property][users[i]].add(amount[i]);
            _totalRevenue[users[i]] = _totalRevenue[users[i]].add(amount[i]);
            amountToPay = amountToPay.add(amount[i]);
        }
        require(RevenueDistributionHelpers(_dai).transferFrom(msg.sender, address(this), amountToPay));
        _totalPayout[property] = _totalPayout[property].add(amountToPay);
        _totalDays[property] = _totalDays[property].add(diffDays);

        emit RevenueAdded(property, users, amount, from, to);
    }

    function _claimRevenue(address property, address wallet) private {
        uint256 revenue = _revenueAmount[property][wallet];
        RevenueDistributionHelpers(_dai).transfer(wallet, revenue);
        _revenueAmount[property][wallet] = 0;
        _totalRevenue[wallet] = _totalRevenue[wallet].sub(revenue);
        emit RevenueClaimed(property, wallet, revenue, now);
    }

    /**
    * @notice User function to receive rent
    * @dev Reclaim rent
    * @param property Address of PropToken for which you wish to reclaim rent
    */
    function claimRevenueForToken(address property) public {
        _claimRevenue(property, msg.sender);
    }

    function pushRevenueToUser(address property, address[] memory wallets) public {
        for (uint256 i = 0; i < wallets.length; i++) {
            _claimRevenue(property, wallets[i]);
        }
    }

    function setDataProxy(address dataProxy) public onlyOwner {
        _data = dataProxy;
    }

    function setDAI(address dai) public onlyOwner {
        _dai = dai;
    }

    /**
    * @dev Check amount of pending rent
    * @param property Address of PropToken
    * @param user Address of user
    * @return Amount of pending tokens
    */
    function pendingRevenue(address property, address user) public view returns (uint256) {
        return _revenueAmount[property][user];
    }

    function totalPendingRevenue(address user) public view returns (uint256) {
        return _totalRevenue[user];
    }

    function getAverageMonthlyPayout(address property) public view returns (uint256) {
        if (_totalDays[property] == 0) {
            return 0;
        }
        return _totalPayout[property].mul(30).div(_totalDays[property]);
    }

    function totalPayout(address property) public view returns (uint256) {
        return _totalPayout[property];
    }
}