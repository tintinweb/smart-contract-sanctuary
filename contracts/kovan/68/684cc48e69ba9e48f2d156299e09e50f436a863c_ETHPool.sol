/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

    ///@title ETHPool Challenge
    ///@author Juan Pablo Poujade ([email protected])
    /**
    @notice ETHPool provides a service where 
    people can deposit ETH and they will receive weekly rewards
    */   
contract ETHPool {
    
    // Total rewards deposited by the team
    uint256 public totalRewards;
    // Total amount deposited by users
    uint256 public totalUsersDeposits;

    // Main users data:
    struct userData {
        uint256 depositedAmount;
        uint256 rewardAmount;
        bool isRegistered;
    }
    mapping(address => userData) public users;

    // Whitepages for users participating in the protocol:
    address[] usersAddressList;

    // Mapping with information about the team's members addresses:
    mapping(address => bool) public usersTeam;
    
    ///@dev Emitted when the team deposits rewards
    ///@param from Address from which the rewards are sent
    ///@param value ETH value deposited
    ///@param date Date of the deposit
    event rewardsDeposited(
        address from,
        uint256 value,
        uint256 date
    );

    ///@dev Emitted when a user makes a new deposit
    ///@param from The address of the user who made the deposit
    ///@param value ETH value deposited by the user
    ///@param date Date of the deposit
    event userDeposited(
        address from, 
        uint256 value, 
        uint256 date
    );

    ///@dev Emitted when a user makes a partial or full withdrawal of its current deposits
    ///@param from The address of the user who made the withdrawal
    ///@param value ETH value retired by the user
    ///@param date Date of the withdrawal
    event userWithdrawalDeposit(
        address from, 
        uint256 value, 
        uint256 date
    );

    ///@dev Emitted when a user makes a partial or full withdrawal of its accumulated rewards
    ///@param from The address of the user who made the withdrawal
    ///@param value ETH value retired by the user
    ///@param date Date of the withdrawal
    event userWithdrawalRewards(
        address from, 
        uint256 value, 
        uint256 date
    );

    // Modifier to ensure allowed operations
    modifier onlyTeam() {
        require(
            usersTeam[msg.sender] == true,
            "Only team members are allowed to execute this operation"
        );
        _;
    }  

    // Contract constructor:
    constructor() {
        usersTeam[msg.sender] = true;
    }

    // Function intendended for the users to make deposits into the protocol.
    // The same user can make many different deposits along the time (will be accumulated)
    function userDeposit() external payable {
        // If this is a new user (first deposit), then we should add him to the registered/whitepages:
        if (users[msg.sender].isRegistered == false) {
            // Set flag as registered:
            users[msg.sender].isRegistered = true;
            // Add to whitepages:
            usersAddressList.push(msg.sender);
        }
        // Update user total deposited amount:
        users[msg.sender].depositedAmount += msg.value;
        // Update total amount deposited by users:
        totalUsersDeposits += msg.value;
        // Trigger corresponding event:
        emit userDeposited(msg.sender, msg.value, block.timestamp);
    }


    // Rewards deposits are expected to happen on weekly basis, but no restrictions were coded.
    // In this way, additional unexpected rewards can be given by the team at any moment ;)
    function depositRewards() external payable onlyTeam {
        // If there are no deposits, it makes no sense to allow rewards to be deposited:
        require(totalUsersDeposits > 0, "Cannot deposit rewards if there are no users deposits");
        // Update total rewards tracking variable:
        totalRewards += msg.value;
        // Update the amount of rewards for each active user:
        // Every time a reward is deposited (at the very same moment) the fractional reward corresponding to each user is computed (based on its current deposits)
        // We are iterating over a list, this is probably not an elegant nor efficient solution (gas consumption)
        for (uint i=0; i<usersAddressList.length; i++) {
            address _addr = usersAddressList[i];
            // Compute new reward to be added to this user (fraction):
            // [OpenZeppelin safe math functions could be used here]
            uint newUserReward = ((msg.value * users[_addr].depositedAmount) / totalUsersDeposits);
            // Accumulate rewards corresponding to this user:
            users[_addr].rewardAmount += newUserReward; 
        }
        // Trigger corresponding event:
        emit rewardsDeposited(msg.sender, msg.value, block.timestamp);
    }

    // Allow users to check their deposits:
    function queryUserDeposit() public view returns(uint256) {
        return users[msg.sender].depositedAmount;
    }
    
    // Function intended for the user to be able to withdraw (partial or full) deposits:
    function withdrawalUserDeposit(uint256 amount) external {
        // Users should not be able to withdraw more than they currently have deposited:
        require(users[msg.sender].depositedAmount >= amount, "Trying to withdraw an amount higher than current deposits");
        // Update total deposited amount:
        totalUsersDeposits -= amount;
        // Update user deposited amount:
        users[msg.sender].depositedAmount -= amount;
        // Transfer funds to the user:
        (bool success, ) = payable(msg.sender).call{
            value: amount
            }("");
        require(success, "Transfer failed");
        emit userWithdrawalDeposit(msg.sender, amount, block.timestamp);

    }

    // Allow users to check their available rewards:
    function queryUserRewards() public view returns(uint256) {
        return users[msg.sender].rewardAmount;
    }
    
    // Function intended for the user to be able to withdraw (partial or full) rewards:
    function withdrawalUserReward(uint256 amount) external {
        // Users should not be able to withdraw more than they currently have as rewards:
        require(users[msg.sender].rewardAmount >= amount, "Trying to withdraw an amount higher than current rewards");
        // Update total deposited rewards:
        totalRewards -= amount;
        // Update user deposited amount:
        users[msg.sender].rewardAmount -= amount;
        // Transfer funds to the user:
        (bool success, ) = payable(msg.sender).call{
            value: amount
            }("");
        require(success, "Transfer failed");
        emit userWithdrawalRewards(msg.sender, amount, block.timestamp);
    }

}