pragma solidity ^0.8.0;

import "./interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

interface IERC20 is IERC20Metadata {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}

pragma solidity ^0.8.0;
import "../common/interfaces/IERC20.sol";
import "../common/Ownable.sol";
import "./interfaces/IStakingPool.sol";

contract StakingPool is IStakingPool, Ownable {
    
    mapping(address => StakingData[]) public userStakingData;
    mapping(address => bool) public isCurrentStaking;
    
    IERC20 public stakingToken;
    address public precog;
    
    uint public duration;
    uint public endTime;
    uint public rewardRate;
    
    constructor(IERC20 token, address _precog) {
        stakingToken = token;
        precog = _precog;
    }
    
    modifier onlyPrecog() {
        require(precog == msg.sender, "StakingPool: not from Precog");
        _;
    }
    
    function getUserStakingData(address account) external view override returns(StakingData[] memory){
        return userStakingData[account];
    }
    
    function getRequireLockTime(address account) external view override returns(uint){
        uint countStaking = userStakingData[account].length;
        return userStakingData[account][countStaking - 1].locktime;
    } 
    
    function getEndTime() external view override returns(uint) {
        return endTime;
    }
    
    function depositReward(uint _totalReward) external onlyOwner {
        stakingToken.transferFrom(msg.sender, address(this), _totalReward);
    }
    
    function withdrawReward(uint amount) external override onlyOwner {
        require(amount <= stakingToken.balanceOf(address(this)), "StakingPool: Don't have enough balance to withdraw");
        stakingToken.transfer(msg.sender, amount);
    }
    
    function startStaking(uint _duration, uint _endTime, uint _rewardRate) external onlyOwner {
        require(block.timestamp > endTime, "StakingPool: cannot start new staking in this time");
        duration = _duration;
        endTime = _endTime;
        rewardRate = _rewardRate;
    }
    
    function staking(uint amount) external override {
        require(block.timestamp < endTime, "StakingPool: can't stake in this time");
        StakingData[] storage stakingData = userStakingData[msg.sender];
        
        StakingData memory _stakingData;
        
        _stakingData.stakingAmount = amount;
        _stakingData.locktime = block.timestamp + duration;
        _stakingData.reward = amount * rewardRate / 100;
        stakingData.push(_stakingData);
        isCurrentStaking[msg.sender] = true;
        
        stakingToken.transferFrom(msg.sender, address(this), amount);
    }
    
    function stakingOnBehalf(address account, uint amount) external override onlyPrecog {
        require(block.timestamp < endTime, "StakingPool: can't stake in this time");
        StakingData[] storage stakingData = userStakingData[account];
        
        StakingData memory _stakingData;
        
        _stakingData.stakingAmount = amount;
        _stakingData.locktime = block.timestamp + duration;
        _stakingData.reward = amount * rewardRate / 100;
        stakingData.push(_stakingData);
        isCurrentStaking[account] = true;
        
        stakingToken.transferFrom(msg.sender, address(this), amount);
    }
    
    function withdraw(address account) external override returns(uint) {
        require(block.timestamp >= this.getRequireLockTime(account), "StakingPool: in locktime");
        require(isCurrentStaking[account], "StakingPool: not staking");
        StakingData[] storage stakingData = userStakingData[account];
        
        uint totalReward;
        uint totalStakingAmount;
        uint newTotalBalance;
        
        for(uint i = 0; i < stakingData.length; i++){
            if(block.timestamp >= stakingData[i].locktime){
                totalStakingAmount += stakingData[i].stakingAmount;
                totalReward += stakingData[i].reward;
                stakingData[i].stakingAmount = 0;
                stakingData[i].reward = 0;
                stakingData[i].locktime = 0;
            }
            newTotalBalance += stakingData[i].stakingAmount;
        }
        
        isCurrentStaking[account] = newTotalBalance == 0 ? false : true;
        
        uint amountReturn = totalReward + totalStakingAmount;
        stakingToken.transfer(msg.sender, amountReturn);
        return amountReturn;
    }
}

pragma solidity ^0.8.0;

interface IStakingPool {
    struct StakingData {
        uint stakingAmount;
        uint reward;
        uint locktime;
    }
    
    function staking(uint amount) external;
    
    function stakingOnBehalf(address account, uint amount) external;
    
    function withdraw(address account) external returns(uint);
    
    function withdrawReward(uint amount) external;
    
    function getUserStakingData(address account) external view returns(StakingData[] memory);
    
    function getEndTime() external view returns(uint);
    
    function getRequireLockTime(address account) external view returns(uint);
}

