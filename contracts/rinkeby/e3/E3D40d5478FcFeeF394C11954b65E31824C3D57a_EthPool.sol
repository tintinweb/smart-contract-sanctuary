// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

contract EthPool {
    address owner;

    mapping(address => uint256) public balanceOf;
    uint256 public totalDeposits;

    // Used to calculate accumulated rewards when withdrawing
    mapping(address => uint256) public initialRewardsCoefficientOf;
    uint256 public currentRewardsCoefficient;

    constructor() {
        owner = msg.sender;
    }

    event Deposit(address sender, uint256 amount);
    event Withdrawal(address from, uint256 amount);
    event DepositReward(uint256 amount);

    function getOwner() public view returns (address) {
        return owner;
    }

    function getBalance(address addr) public view returns (uint256) {
        return balanceOf[addr];
    }

    function getTotalDeposits() public view returns (uint256) {
        return totalDeposits;
    }

    function getBalanceIncludingRewards(address addr) public view returns (uint256) {
        return
            balanceOf[addr] +
            (balanceOf[addr] * (currentRewardsCoefficient - initialRewardsCoefficientOf[addr])) /
            1000000;
    }

    function deposit() public payable {
        require(msg.value > 0 && balanceOf[msg.sender] == 0);
        totalDeposits += msg.value;
        balanceOf[msg.sender] += msg.value;
        initialRewardsCoefficientOf[msg.sender] = currentRewardsCoefficient;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() public {
        require(balanceOf[msg.sender] > 0);
        uint256 amountWithdraw = getBalanceIncludingRewards(msg.sender);
        totalDeposits -= balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        msg.sender.transfer(amountWithdraw);
        emit Withdrawal(msg.sender, amountWithdraw);
    }

    function depositRewards() public payable {
        require(msg.sender == owner && totalDeposits > 0);
        currentRewardsCoefficient = currentRewardsCoefficient + (msg.value * 1000000) / totalDeposits;
        emit DepositReward(msg.value);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}