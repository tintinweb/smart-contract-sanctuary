// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;

import "SafeMath.sol";
import "ReentrancyGuard.sol";
import "TransferHelper.sol";

contract Stake is ReentrancyGuard {
    using SafeMath for uint256;

    address token;
    address private owner;

    uint256 public stakePeriod;
    uint256 public totalStake;
    uint256 totalWeight;
    uint256 public totalTokenReceived;
    uint256 public startTime;
    
    mapping(address => uint256) public staked;
    mapping(address => uint256) public timelock;
    mapping(address => uint256) weighted;
    mapping(address => uint256) accumulated;

    event logStake(address indexed stakeHolder, uint256 amount);
    event logWithdraw(address indexed stakeHolder, uint256 amount, uint256 reward);
    event logDeposit(address indexed depositor, uint256 amount);

    constructor(address _token, uint256 periodInDays, uint256 start, address _owner) public {
        token = _token;
        stakePeriod = periodInDays.mul(86400);
        startTime = start;
        owner = _owner;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }
    
    function setStakePeriod(uint256 periodInDays) public onlyOwner {
        require(periodInDays > 0, "Period greater than 0");
        stakePeriod = periodInDays.mul(86400);
    }
    
    function getStakeData() public view returns(uint256, uint256, uint256, uint256) {
        return (startTime, stakePeriod, totalStake, totalTokenReceived);
    }
    
    function getStakeHolderData(address stakeHolderAddress) public view returns(uint256, uint256, uint256, uint256, uint256) {
        uint256 tokenOut = staked[msg.sender];
        uint256 reward = tokenOut.mul(totalWeight.sub(weighted[msg.sender])).div(10**18).add(accumulated[msg.sender]);
        return (staked[stakeHolderAddress], timelock[stakeHolderAddress], weighted[stakeHolderAddress], accumulated[stakeHolderAddress], reward);
    }

    function stake(uint256 amount) nonReentrant public {
        require(block.timestamp >= startTime, "Stake not begin");
        require(amount > 0, "Nothing to stake");

        _stake(amount);
        timelock[msg.sender] = block.timestamp.add(stakePeriod);

        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
    }

    function withdraw() nonReentrant public returns (uint256 amount, uint256 reward) {
        require(block.timestamp >= timelock[msg.sender], "Stake is locked");

        (amount, reward) = _applyReward();
        emit logWithdraw(msg.sender, amount, reward);

        timelock[msg.sender] = 0;

        TransferHelper.safeTransfer(token, msg.sender, amount);
        if (reward > 0) {
            TransferHelper.safeTransfer(token, msg.sender, reward);
        }
    }

    function claim() nonReentrant public returns (uint256 reward) {
        (uint256 amount, uint256 _reward) = _applyReward();
        emit logWithdraw(msg.sender, amount, _reward);
        reward = _reward;

        require(reward > 0, "Nothing to pay out");
        TransferHelper.safeTransfer(token, msg.sender, reward);

        // restake after withdrawal
        _stake(amount);
        timelock[msg.sender] = block.timestamp.add(stakePeriod);
    }

    function deposit(uint amount) nonReentrant external payable {
        require(amount > 0, "Nothing to deposit");
        require(totalStake > 0, "Nothing staked");
        
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);

        totalTokenReceived = totalTokenReceived.add(amount);

        emit logDeposit(msg.sender, amount);

        _distribute(amount, totalStake);
    }

    function _stake(uint256 tokenIn) private {
        uint256 addBack;
        if (staked[msg.sender] > 0) {
            (uint256 tokenOut, uint256 reward) = _applyReward();
            addBack = tokenOut;
            accumulated[msg.sender] = reward;
            staked[msg.sender] = tokenOut;
        }

        staked[msg.sender] = staked[msg.sender].add(tokenIn);
        weighted[msg.sender] = totalWeight;
        totalStake = totalStake.add(tokenIn);

        if (addBack > 0) {
            totalStake = totalStake.add(addBack);
        }

        emit logStake(msg.sender, tokenIn);
    }

    function _applyReward() private returns (uint256 tokenOut, uint256 reward) {
        require(staked[msg.sender] > 0, "Nothing staked");

        tokenOut = staked[msg.sender];
        reward = tokenOut
            .mul(totalWeight.sub(weighted[msg.sender]))
            .div(10**18)
            .add(accumulated[msg.sender]);
        totalStake = totalStake.sub(tokenOut);
        accumulated[msg.sender] = 0;
        staked[msg.sender] = 0;
    }

    function _distribute(uint256 _value, uint256 _totalStake) private {
        totalWeight = totalWeight.add(_value.mul(10**18).div(_totalStake));
    }
}