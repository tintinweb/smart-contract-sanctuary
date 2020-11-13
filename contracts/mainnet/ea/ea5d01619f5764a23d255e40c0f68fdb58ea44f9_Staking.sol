// SPDX-License-Identifier: MIT

// Burning Network
// Total Supply - 21000 BURN
// Website: https://burning.network/

pragma solidity ^0.7.0;

// File: @openzeppelin/contracts/math/SafeMath.sol

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256 r) {
        return (a + m - 1) / m * m;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function amountToTransfer(uint256 amount) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/GSN/Context.sol

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @Burning-Network/contracts/Staking.sol

contract Staking is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _stakes;
    mapping (address => uint256) private _time;

    IERC20 public contractAddress;
    
    uint256 public stakingPool;
    uint256 private chargeFee = 500; // 5%
    uint256 public initialAmount;
    uint256 public totalFee;
    uint256 public rewardPool;

    constructor(IERC20 _contractAddress) {
        contractAddress = _contractAddress;
    }
    
    function amountToCharge(uint256 amount) internal virtual returns (uint256) {
        uint256 _amount = amount.ceil(chargeFee).mul(chargeFee).div(10000);
        return _amount;
    }
    
    function approvedAmount(address owner) public view returns (uint256) {
        return contractAddress.allowance(owner, address(this));
    }
    
    function stakeOf(address account) public view returns (uint256) {
        return _stakes[account];
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return contractAddress.balanceOf(account);
    }
    
    function chargePercent() public view returns (uint256) {
        uint256 _chargeFee = chargeFee.div(100);
        return _chargeFee;
    }

    // Transfer initial amount to the staking contract (only for owner)
    function addToContract(uint256 amount) public virtual onlyOwner {
        uint256 amountForPool = contractAddress.amountToTransfer(amount);
        
        initialAmount = initialAmount.add(amountForPool);
        rewardPool = rewardPool.add(amountForPool);
        
        contractAddress.transferFrom(msg.sender, address(this), amount);
    }
    
    // Function to stake tokens
    function stakeTokens(uint256 amount) external {
        require(initialAmount != 0, "Wait for official announcement");
        require(contractAddress.balanceOf(msg.sender) >= amount, "Your current balance is less than the amount for staking");
        require(contractAddress.allowance(msg.sender, address(this)) >= amount, "Please approve tokens before staking");

        uint256 _amountToCharge = amountToCharge(contractAddress.amountToTransfer(amount));
        uint256 _amountToTransfer = contractAddress.amountToTransfer(amount).sub(_amountToCharge);

        _stakes[msg.sender] = _stakes[msg.sender].add(_amountToTransfer);
        _time[msg.sender] = block.timestamp;
        totalFee = totalFee.add(_amountToCharge);
        stakingPool = stakingPool.add(_amountToCharge).add(_amountToTransfer);
        rewardPool = rewardPool.add(totalFee);

        contractAddress.transferFrom(msg.sender, address(this), amount);
    }

    // Function to calculate your current reward
    function calculateReward() internal virtual returns (uint256) {
        uint256 amount = rewardPool.mul(_stakes[msg.sender]).div(stakingPool);
        uint256 stakingTime = block.timestamp.sub(_time[msg.sender]);
        uint256 reward = amount.mul(3).mul(stakingTime).div(10 ** 6);

        // Probably will not happened but I feel more confident when I see it here:
        if (reward > rewardPool) {
            uint256 _reward = rewardPool.div(2);
            
            _stakes[msg.sender] = _stakes[msg.sender].sub(_reward);
            rewardPool = rewardPool.sub(_reward);
            
            return _reward;
        }    

        return reward;
    }
    
    // Function to check your current reward
    function checkReward() public view returns (uint256) {
        uint256 amount = rewardPool.mul(_stakes[msg.sender]).div(stakingPool);
        uint256 stakingTime = block.timestamp.sub(_time[msg.sender]);
        uint256 reward = amount.mul(3).mul(stakingTime).div(10 ** 6);

        if (reward > rewardPool) {
            uint256 _reward = rewardPool.div(2);
            return _reward;
        }  

        return reward;
    }
    
    // Function to get reward from the balance of the staking contract
    function claimReward() external {
        uint256 reward = calculateReward();
        
        _time[msg.sender] = block.timestamp;
        
        rewardPool = rewardPool.sub(reward);
        
        contractAddress.transfer(msg.sender, reward);
    }
    
    // Function to remove staking tokens
    // You need to claim reward before unstaking or you will lose your reward
    function removeStake(uint256 amount) external {
        _stakes[msg.sender] = _stakes[msg.sender].sub(amount);

        stakingPool = stakingPool.sub(amount);
        
        contractAddress.transfer(msg.sender, amount);
    }
}