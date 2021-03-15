// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
import "./FarmStaking.sol";

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
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


contract FarmStakingGenerator is Context, Ownable {
  using SafeMath for uint256;
  IFarmFactory public factory;

  struct FarmParameters {
    uint256 bonusBlocks;
    uint256 totalBonusReward;
    uint256 numBlocks;
    uint256 endBlock;
    uint256 requiredAmount;
  }

  constructor(IFarmFactory _factory) public {
    factory = _factory;
  }

  /**
   * @notice Determine the endBlock based on inputs. Used on the front end to show the exact settings the Farm contract will be deployed with
   */
  function determineEndBlock(uint256 _amount, uint256 _blockReward, uint256 _startBlock, uint256 _bonusEndBlock, uint256 _bonus) public pure returns (uint256, uint256) {
    FarmParameters memory params;
    params.bonusBlocks = _bonusEndBlock.sub(_startBlock);
    params.totalBonusReward = params.bonusBlocks.mul(_bonus).mul(_blockReward);
    params.numBlocks = _amount.sub(params.totalBonusReward).div(_blockReward);
    params.endBlock = params.numBlocks.add(params.bonusBlocks).add(_startBlock);

    uint256 nonBonusBlocks = params.endBlock.sub(_bonusEndBlock);
    uint256 effectiveBlocks = params.bonusBlocks.mul(_bonus).add(nonBonusBlocks);
    uint256 requiredAmount = _blockReward.mul(effectiveBlocks);
    return (params.endBlock, requiredAmount);
  }

  /**
   * @notice Determine the blockReward based on inputs specifying an end date. Used on the front end to show the exact settings the Farm contract will be deployed with
   */
  function determineBlockReward(uint256 _amount, uint256 _startBlock, uint256 _bonusEndBlock, uint256 _bonus, uint256 _endBlock) public pure returns (uint256, uint256) {
    uint256 bonusBlocks = _bonusEndBlock.sub(_startBlock);
    uint256 nonBonusBlocks = _endBlock.sub(_bonusEndBlock);
    uint256 effectiveBlocks = bonusBlocks.mul(_bonus).add(nonBonusBlocks);
    uint256 blockReward = _amount.div(effectiveBlocks);
    uint256 requiredAmount = blockReward.mul(effectiveBlocks);
    return (blockReward, requiredAmount);
  }

  /**
   * @notice Creates a new FarmStaking contract and registers it in the 
   * .sol. All farming rewards are locked in the FarmStaking Contract
   */
  function createFarmStaking(IERC20 _rewardToken, uint256 _amount, IERC20 _token, uint256 _blockReward, uint256 _startBlock, uint256 _bonusEndBlock, uint256 _bonus) public onlyOwner returns (address){
    require(_startBlock > block.number, 'START'); // ideally at least 24 hours more to give farmers time
    require(_bonus > 0, 'BONUS');
    require(address(_rewardToken) != address(0), 'REWARD TOKEN');
    require(address(_token) != address(0), 'TOKEN');
    require(_blockReward > 1000, 'BLOCK REWARD'); // minimum 1000 divisibility per block reward

    FarmParameters memory params;
    (params.endBlock, params.requiredAmount) = determineEndBlock(_amount, _blockReward, _startBlock, _bonusEndBlock, _bonus);

    TransferHelper.safeTransferFrom(address(_rewardToken), address(_msgSender()), address(this), params.requiredAmount);
    FarmStaking newFarm = new FarmStaking(address(factory), address(this));
    RewardHolder newRewardHolder = new RewardHolder(address(this), address(newFarm));
    TransferHelper.safeApprove(address(_rewardToken), address(newRewardHolder), params.requiredAmount);
    newRewardHolder.init(address(_rewardToken), params.requiredAmount);
    newFarm.init(address(newRewardHolder), _rewardToken, params.requiredAmount, _token, _blockReward, _startBlock, params.endBlock, _bonusEndBlock, _bonus);

    factory.registerFarm(address(newFarm));
    return (address(newFarm));
  }
}