/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier:MIT

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract stakingContract {
    using SafeMath for uint256;

    address public owner;
    IERC20 public token1;
    IERC20 public token2;

    uint256 public basePercent = 10;
    uint256 public percentDivider = 1000;
    uint256 public minTokenForReward = 1000000000e9;
    uint256 public timeStep = 24 hours;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
    }

    mapping(address => User) internal users;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    event UnStaked(address indexed user, uint256 totalAmount);

    constructor(
        address _owner,
        address _token1,
        address _token2
    ) {
        owner = _owner;
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
    }

    function invest(uint256 value) public {
        User storage user = users[msg.sender];

        token1.transferFrom(msg.sender, address(this), value);

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers = totalUsers.add(1);

            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(value, 0, block.timestamp));
        totalInvested = totalInvested.add(value);
        totalDeposits = totalDeposits.add(1);

        emit NewDeposit(msg.sender, value);
    }

    function withdraw() public {
        require(
            getContractBalanceToken1() > minTokenForReward,
            "You cannot withdraw below the contract balance limit"
        );

        User storage user = users[msg.sender];

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            dividends = (
                user.deposits[i].amount.mul(basePercent).div(percentDivider)
            ).mul(block.timestamp.sub(user.deposits[i].start)).div(timeStep);

            user.deposits[i].start = block.timestamp;
            user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(
                dividends
            ); // changing of storage data
            totalAmount = totalAmount.add(dividends);
        }

        user.checkpoint = block.timestamp;

        token2.transferFrom(owner, msg.sender, totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }

    function unstake() public {
        uint256 totalAmount = getUserTotalDeposits(msg.sender);

        token1.transfer(msg.sender, totalAmount);

        delete users[msg.sender];

        emit UnStaked(msg.sender, totalAmount);
    }

    function getContractBalanceToken1() public view returns (uint256) {
        return token1.balanceOf(address(this));
    }

    function getContractBalanceToken2() public view returns (uint256) {
        return token2.balanceOf(address(this));
    }

    function getUserDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            dividends = (
                user.deposits[i].amount.mul(basePercent).div(percentDivider)
            ).mul(block.timestamp.sub(user.deposits[i].start)).div(timeStep);
            totalAmount = totalAmount.add(dividends);
        }

        return totalAmount;
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (
                user.deposits[user.deposits.length - 1].withdrawn <
                (user.deposits[user.deposits.length - 1].amount.mul(250)).div(
                    percentDivider
                )
            ) {
                return true;
            }
        }
        return false;
    }

    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        User storage user = users[userAddress];

        return (
            user.deposits[index].amount,
            user.deposits[index].withdrawn,
            user.deposits[index].start
        );
    }

    function getUserAmountOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }

        return amount;
    }

    function setBasePercent(uint256 percent) external onlyOwner {
        basePercent = percent;
    }

    function setMinTokenForReward(uint256 amount) external onlyOwner {
        minTokenForReward = amount;
    }

    function setTimeStep(uint256 time) external onlyOwner {
        timeStep = time;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}