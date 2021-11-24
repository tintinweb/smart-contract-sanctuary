/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StakingPool {
    bool constant private notComplete = true;

    event FundsReturned();

    function complete() external payable {
        if(notComplete) {
            payable(msg.sender).transfer(payable(address(this)).balance);
            emit FundsReturned();
        }
    }
}

contract Staker {
    mapping (address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 120 seconds;
    StakingPool private exampleExternalContract;
    bool private executed;
    bool private openForWithdraw;

    event Stake(address, uint256);

    modifier beforeDeadline {
        require(block.timestamp <= deadline, "Missed the deadline");
        _;
    }

    constructor(StakingPool stakingPoolAddress) {
        exampleExternalContract = stakingPoolAddress;
    }

    receive() external payable {}

    function timeLeft() public view returns (uint256) {
        if(deadline >= block.timestamp) {
            return deadline - block.timestamp;
        } else {
            return 0;
        }
    }

    function stake() external payable beforeDeadline {
        require(msg.value > 0, "Ether must be sent to stake");
        require(!executed, "Already executed");

        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    function execute() external {
        if(address(this).balance >= threshold && block.timestamp <= deadline) {
            executed = true;
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }

    function withdraw() external {
        require(openForWithdraw, "Withdrawals are closed");
        require(balances[msg.sender] > 0, "Your Ether balance is 0");

        uint256 value = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(value);
    }
}