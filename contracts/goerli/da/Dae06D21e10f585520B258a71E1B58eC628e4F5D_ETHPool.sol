// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ETHPool {
    struct Deposit {
        uint256 amount;
        uint256 rewardIndex;
    }

    struct Rewards {
        uint256 amount;
        uint256 totalDeposited;
    }

    struct UserDeposits {
        mapping(uint256 => Deposit) values;
        uint256 nDeposits;
        uint256 firstReward;
        uint256 totalDeposit;
    }

    address public team;
    mapping(address => UserDeposits) deposits;
    Rewards[] rewards;
    uint256 public totalDeposited;

    event Deposited(uint256 amount);
    event RewardsDeposited(uint256 amount);

    constructor() {
        team = msg.sender;
    }

    modifier onlyTeam() {
        require(msg.sender == team, "Only the ETHPool team can perform this action");
        _;
    }

    function deposit() external payable {
        UserDeposits storage userDeposits = deposits[msg.sender];
        uint256 n = userDeposits.nDeposits;
        if (n == 0) {
            userDeposits.firstReward = rewards.length;
        }
        userDeposits.values[n] = Deposit({ amount: msg.value, rewardIndex: rewards.length });
        userDeposits.nDeposits += 1;
        userDeposits.totalDeposit += msg.value;
        totalDeposited += msg.value;
        emit Deposited(msg.value);
    }

    function withdraw() external {
        uint256 amount = withdrawableAmount();
        totalDeposited -= deposits[msg.sender].totalDeposit;
        deposits[msg.sender].nDeposits = 0;
        deposits[msg.sender].firstReward = 0;
        deposits[msg.sender].totalDeposit = 0;
        payable(msg.sender).transfer(amount);
    }

    function withdrawableAmount() public view returns(uint256) {
        UserDeposits storage userDeposits = deposits[msg.sender];
        uint256 userRewards = 0;
        uint256 accumulatedDeposits = 0;
        uint256 depositIndex = 0;
        if (userDeposits.nDeposits == 0) {
            return 0;
        }
        for (uint256 r = userDeposits.firstReward; r < rewards.length; r++) {
            Rewards storage reward = rewards[r];
            uint256 k;
            for (k = depositIndex; k < userDeposits.nDeposits; k++) {
                if (userDeposits.values[k].rewardIndex <= r) {
                    accumulatedDeposits += userDeposits.values[k].amount;
                } else {
                    break;
                }
            }
            depositIndex = k;
            // The user's share of this particular reward is the amount they had deposited
            // before this reward was deposited, divided by the total amount deposited at that time
            userRewards += accumulatedDeposits * reward.amount / reward.totalDeposited;
        }
        return userDeposits.totalDeposit + userRewards;
    }

    function depositedAmount() external view returns(uint256) {
        return deposits[msg.sender].totalDeposit;
    }

    function depositRewards() external payable onlyTeam {
        rewards.push(Rewards({ amount: msg.value, totalDeposited: totalDeposited }));
        emit RewardsDeposited(msg.value);
    }
}