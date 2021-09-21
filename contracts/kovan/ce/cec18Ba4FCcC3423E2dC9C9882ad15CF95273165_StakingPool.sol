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
    
    mapping(address => bool) public isCurrentStaking;
    mapping(address => StakingData) public userStakingData;
    
    IERC20 public stakingToken;
    address public precog;
    
    uint public duration;
    uint public startTime;
    uint public endTime;
    uint public rewardRate;
    uint public stakingCount;
    
    constructor(IERC20 token, address _precog) {
        stakingToken = token;
        precog = _precog;
    }
    
    modifier onlyPrecog() {
        require(precog == msg.sender, "StakingPool: not from Precog");
        _;
    }
    
    function getUserStakingData(address account) external view override returns(uint returnStakingAmount, uint returnReward, uint returnLocktime){
        returnStakingAmount = userStakingData[account].stakingAmount;
        returnReward = userStakingData[account].reward;
        returnLocktime = userStakingData[account].locktime;
    }
    
    function getEndTime() external view override returns(uint) {
        return endTime;
    }
    
    function depositReward(uint _totalReward) external onlyOwner {
        stakingToken.transferFrom(msg.sender, address(this), _totalReward);
    }
    
    function startStaking(uint _duration, uint _endTime, uint _rewardRate) external onlyOwner {
        require(stakingCount == 0);
        duration = _duration;
        startTime = block.timestamp;
        endTime = _endTime;
        rewardRate = _rewardRate;
    }
    
    function staking(uint amount) external override {
        require(isCurrentStaking[msg.sender] == false, "StakingPool: user is current staking");
        require(block.timestamp >= startTime, "StakingPool: staking hasn't started yet");
        require(block.timestamp < endTime, "StakingPool: can't stake in this time");
        StakingData storage stakingData = userStakingData[msg.sender];
        
        stakingData.stakingAmount = amount;
        stakingData.locktime = block.timestamp + duration;
        isCurrentStaking[msg.sender] = true;
        
        stakingCount += 1;
        
        stakingToken.transferFrom(msg.sender, address(this), amount);
    }
    
    function stakingOnBehalf(address account, uint amount) external override onlyPrecog {
        require(isCurrentStaking[account] == false, "StakingPool: user is current staking");
        require(block.timestamp >= startTime, "StakingPool: staking hasn't started yet");
        require(block.timestamp < endTime, "StakingPool: can't stake in this time");
        StakingData storage stakingData = userStakingData[account];
        
        stakingData.stakingAmount = amount;
        stakingData.locktime = block.timestamp + duration;
        isCurrentStaking[account] = true;
        
        stakingCount += 1;
        
        stakingToken.transferFrom(msg.sender, address(this), amount);
    }
    
    function withdraw(address account) external override {
        StakingData storage stakingData = userStakingData[account];
        require(block.timestamp >= stakingData.locktime, "StakingPool: in locktime");
        
        _harvest(account);
        
        uint amountReturn = stakingData.stakingAmount + stakingData.reward;
        stakingToken.transfer(msg.sender, amountReturn);
        stakingData.stakingAmount = 0;
        stakingData.reward = 0;
        stakingData.locktime = 0;
        isCurrentStaking[account] = false;
        
        stakingCount -= 1;
    }
    
    function _harvest(address account) internal {
        StakingData storage stakingData = userStakingData[account];
        
        uint tokenReward = stakingData.stakingAmount * rewardRate / 100;
        stakingData.reward += tokenReward;
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
    
    function withdraw(address account) external;
    
    function getUserStakingData(address account) external view returns(uint returnStakingAmount, uint returnReward, uint returnLocktime);
    
    function getEndTime() external view returns(uint);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}