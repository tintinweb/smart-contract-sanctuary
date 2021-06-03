pragma solidity ^0.6.12;

import "./SafeMath.sol";

interface RevenueDistributionHelpers {
    function transfer(address to, uint256 amount) external returns (bool success);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function canDistributeRent(address user) external view returns (bool);
}

contract RevenueDistribution {
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
    function addRevenue(address token, address[] memory users, uint256[] memory amount, uint256 from, uint256 to) public {
        require(users.length == amount.length, "RevenueDistribution: number of user addresses must be the same as number of values");
        require(RevenueDistributionHelpers(_data).canDistributeRent(msg.sender), "RevenueDistribution: caller doesn't have permission to add rent");
        uint256 diff = to.sub(from);
        uint256 diffDays = diff.div(1 days);
        require(diffDays >= 30, "RevenueDistribution: you need to distribute for a period of more than 30 days");
        uint256 amountToPay = 0;
        for (uint256 i = 0; i < users.length; i++) {
            _revenueAmount[token][users[i]] = _revenueAmount[token][users[i]].add(amount[i]);
            _totalRevenue[users[i]] = _totalRevenue[users[i]].add(amount[i]);
            amountToPay = amountToPay.add(amount[i]);
        }
        RevenueDistributionHelpers(_dai).transferFrom(msg.sender, address(this), amountToPay);
        _totalPayout[token] = _totalPayout[token].add(amountToPay);
        _totalDays[token] = _totalDays[token].add(diffDays);

        emit RevenueAdded(token, users, amount, from, to);
    }

    /**
    * @notice User function to receive rent
    * @dev Reclaim rent
    * @param property Address of PropToken for which you wish to reclaim rent
    */
    function claimRevenueForToken(address property) public {
        uint256 revenue = _revenueAmount[property][msg.sender];
        RevenueDistributionHelpers(_dai).transfer(msg.sender, revenue);
        _revenueAmount[property][msg.sender] = 0;
        _totalRevenue[msg.sender] = _totalRevenue[msg.sender].sub(revenue);
        emit RevenueClaimed(property, msg.sender, revenue, now);
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