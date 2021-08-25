// This contract is under development and has not yet been deployed on mainnet

pragma solidity ^0.8.0;

import './IERC20.sol';
import './IPancakePair.sol';
import './IPancakeRouter.sol';
import './IPancakeFactory.sol';

import './Ownable.sol';
import './Lockable.sol';

contract YieldFarmingWithoutMinting is Ownable, Lockable {
  struct Farm {
    address creator;
    IERC20 token;
    IPancakePair lpToken;
    string name;
    uint id;
    uint startsAt;
    uint lastRewardedBlock;
    uint lpLockTime;
    uint numberOfFarmers;
    uint lpTotalAmount;
    uint lpTotalLimit;
    uint farmersLimit;
    uint maxStakePerFarmer;
    bool isActive;
  }

  struct Farmer {
    uint balance;
    uint startBlock;
    uint startTime;
  }

  Farm[] private _farms;
  mapping(uint => mapping (address => Farmer)) private _farmers;
  mapping(address => bool) private _pools;

  uint public farmsCount = 0;
  uint public creationFee;

  event FarmCreated(uint farmId);

  constructor(uint _creationFee) {
    creationFee = _creationFee;
  }

  receive() external payable {}

  function createFarm(
    IERC20 token,
    IPancakePair lpToken,
    uint startsAt,
    uint durationInBlocks,
    uint lpLockTime,
    uint farmersLimit,
    uint maxStakePerFarmer,
    uint lpTotalLimit
  ) external payable {
    if (msg.sender != _owner) {
      require(msg.value >= creationFee, "You need to pay fee for creating own yield farm");
    }

    address tokenAddress = address(token);
    address lpTokenAddress = address(lpToken);
    address pairToken0 = lpToken.token0();
    address pairToken1 = lpToken.token1();
      
    {
      require(!_pools[lpTokenAddress], "This liquidity pool is already exist");

      IPancakeFactory factory = IPancakeFactory(lpToken.factory());
      
      address pairFromFactory = factory.getPair(pairToken0, pairToken1);

      require(
        pairFromFactory == lpTokenAddress &&
        (pairToken0 == tokenAddress || pairToken1 == tokenAddress)
      , "Liquidty pool is invalid");
    }

    _pools[lpTokenAddress] = true;

    uint farmId = farmsCount;

    _farms.push(
      Farm({
        creator: msg.sender,
        token: token,
        lpToken: lpToken,
        name: string(abi.encodePacked(IERC20(pairToken0).symbol(), "-", IERC20(pairToken1).symbol())),
        id: farmId,
        startsAt: startsAt,
        lastRewardedBlock: block.number + durationInBlocks,
        lpLockTime: lpLockTime,
        numberOfFarmers: 0,
        lpTotalAmount: 0,
        lpTotalLimit: lpTotalLimit,
        farmersLimit: farmersLimit,
        maxStakePerFarmer: maxStakePerFarmer,
        isActive: true
      })
    );
    
    farmsCount += 1;

    emit FarmCreated(farmId);
  }
  
  function stake(uint farmId, uint amount) external withLock {
    _stake(_farms[farmId], _farmers[farmId][msg.sender], amount);
  }

  /*
    withdraw only reward
  */
  function harvest(uint farmId) external withLock {
    _withdrawHarvest(_farms[farmId], _farmers[farmId][msg.sender]);
  }

  /*
    withdraw both lp tokens and reward
  */
  function withdraw(uint farmId) external withLock {
    Farm storage farm = _farms[farmId];
    Farmer storage farmer = _farmers[farmId][msg.sender];
    
    _withdrawHarvest(farm, farmer);
    _withdrawLP(farm, farmer);
  }

  /*
    withdraw only lp tokens
  */
  function emergencyWithdraw(uint farmId) external withLock {
    _withdrawLP(_farms[farmId], _farmers[farmId][msg.sender]);
  }

  function _stake(Farm storage farm, Farmer storage farmer, uint amount) internal {
    _stake(farm, farmer, amount, true);
  }

  function _stake(Farm storage farm, Farmer storage farmer, uint amount, bool transferLpTokens) internal {
    require(amount > 0, "Amount must be greater than zero");
    require(farm.isActive, "This farm is inactive or not exist");
    require(block.timestamp >= farm.startsAt, "Yield farming has not started yet for this farm");
    require(block.number <= farm.lastRewardedBlock, "Yield farming is currently closed for this farm");

    uint farmersLimit = farm.farmersLimit;
    uint maxStakePerFarmer = farm.maxStakePerFarmer;
    uint lpTotalLimit = farm.lpTotalLimit;

    if (farmersLimit != 0) {
      require(farm.numberOfFarmers <= farmersLimit, "This farm is already full");
    }
    
    if (lpTotalLimit != 0) {
      require(farm.lpTotalAmount + amount <= lpTotalLimit, "This farm is already full");
    }

    if (maxStakePerFarmer != 0) {
      require(farmer.balance + amount <= maxStakePerFarmer, "You can't stake in this farm, because after that you will be a whale. Sorry :(");
    }
    
    if (transferLpTokens) {
      farm.lpToken.transferFrom(msg.sender, address(this), amount);
    }

    farm.lpTotalAmount += amount;
    farmer.balance += amount;

    if (farmer.startBlock == 0) {
      farm.numberOfFarmers += 1;
      farmer.startBlock = block.number;
      farmer.startTime = block.timestamp;
    }
  }

  function _withdrawLP(Farm storage farm, Farmer storage farmer) internal {
    uint amount = farmer.balance;

    require(amount > 0, "Balance must be greater than zero");

    farm.lpToken.transfer(msg.sender, amount);
    farm.lpTotalAmount -= amount;
    farm.numberOfFarmers -= 1;

    farmer.startBlock = 0;
    farmer.startTime = 0;
    farmer.balance = 0;
  }

  function _withdrawHarvest(Farm memory farm, Farmer storage farmer) internal {
    require(farmer.startBlock != 0, "You are not a farmer");
    require(block.timestamp >= farmer.startTime + farm.lpLockTime, "Too early for withdraw");

    uint harvestAmount = _calculateYield(farm, farmer);

    farmer.startBlock = block.number;
    farmer.startTime = block.timestamp;

    farm.token.transfer(msg.sender, harvestAmount);
  }
  
  function yield(uint farmId) external view returns (uint) {
    return _calculateYield(_farms[farmId], _farmers[farmId][msg.sender]);
  }

  function _calculateYield(Farm memory farm, Farmer memory farmer) internal view returns (uint) {
    uint lpTotalAmount = farm.lpTotalAmount;
    uint startBlock = farmer.startBlock;

    if (lpTotalAmount == 0 || startBlock == 0) {
      return 0;
    }
    
    uint rewardedBlocks = block.number - startBlock;
    uint tokensPerFarmer = (rewardedBlocks * farm.token.balanceOf(address(this))) / farm.lastRewardedBlock;
    uint balanceRate = (farmer.balance * 10**9) / lpTotalAmount;

    return (tokensPerFarmer * balanceRate) / 10**9;
  }

  function me(uint farmId) external view returns (Farmer memory) {
    return _farmers[farmId][msg.sender];
  }

  function updateFarm(
    uint farmId,
    uint startsAt,
    uint blocksDuration,
    uint lpLockTime,
    uint farmersLimit,
    uint maxStakePerFarmer
  ) external {
    Farm storage farm = _farms[farmId];

    require(msg.sender == _owner || msg.sender == farm.creator, "Only owner or creator can update this farm");
    require(block.timestamp < farm.startsAt, "You can update only not started farms");

    farm.startsAt = startsAt;
    farm.lastRewardedBlock = block.number + blocksDuration;
    farm.lpLockTime = lpLockTime;
    farm.farmersLimit = farmersLimit;
    farm.maxStakePerFarmer = maxStakePerFarmer;
  }

  function setActive(uint farmId, bool value) external onlyOwner {
    _farms[farmId].isActive = value;
  }
  
  function setCreationFee(uint _creationFee) external onlyOwner {
    creationFee = _creationFee;
  }
  
  function farms(uint start, uint size) public view returns (Farm[] memory){
      Farm[] memory arrFarms = new Farm[](farmsCount);
      
      uint end = start + size > farmsCount ? farmsCount : start + size;

      for (uint i = start; i < end; i++) {
          Farm storage farm = _farms[i];
          arrFarms[i] = farm;
      }

      return arrFarms;
  }

  function withdrawFee() external onlyOwner {
    payable(_owner).transfer(address(this).balance);
  }
}