// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./Pausable.sol";

interface ISnakeskin {
  function mint(address recipient, uint256 amount) external;
}

interface ISassySnakes {
  function snakeSize(uint256 tokenId) external view returns (uint256);
  function snakeRarity(uint256 tokenId) external view returns (uint256);
}

contract Vivarium is IERC721Receiver, Ownable, Pausable {
  using EnumerableSet for EnumerableSet.UintSet;

  struct Stake {
    uint80 startTimestamp; // seconds
    uint80 lockupPeriod; // seconds
    uint256 tokensReceived;
  }

  address public ERC20_CONTRACT;
  address public ERC721_CONTRACT;
  uint256 public BASE_REWARD;
  uint256 public numberStaked;
  bool private isEmergencyWithdrawal = false;

  mapping(address => EnumerableSet.UintSet) private _deposits;
  mapping(address => mapping(uint256 => Stake)) private _stakes; // owner => (tokenId => stake)
 
  mapping(uint256 => uint256) private _lockupToMultipliers;
  uint256[] private _lockups;

  constructor(
    address _erc20,
    address _erc721,
    uint256 _baseReward,
    uint256[] memory _initialLockups, 
    uint256[] memory _initialLockupMultipliers
  ) {
    ERC20_CONTRACT = _erc20;
    ERC721_CONTRACT = _erc721;
    BASE_REWARD = _baseReward;

    _setLockupMultipliers(_initialLockups, _initialLockupMultipliers);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function depositsOf(address account) public view returns (uint256[] memory) {
    EnumerableSet.UintSet storage depositSet = _deposits[account];
    uint256[] memory tokenIds = new uint256[](depositSet.length());

    for (uint256 i; i < depositSet.length(); i++) {
        tokenIds[i] = depositSet.at(i);
    }

    return tokenIds;
  }

  function getRemoveableTokens(address account) external view returns (uint256[] memory) {
    uint256[] memory deposits = depositsOf(account);

    uint256 counter = 0;
    for (uint256 i = 0; i < deposits.length; i++) {
      if (isTokenRemoveable(account, deposits[i])) {
        counter++;
      } else {
        deposits[i] = 0;
      }
    }

    uint256[] memory removeableTokens = new uint256[](counter);
    counter = 0;

    for (uint256 i = 0; i < deposits.length; i++) {
      if (deposits[i] != 0) {
        removeableTokens[counter++] = deposits[i];
      }
    }


    return removeableTokens;
  }

  function isTokenRemoveable(address owner, uint256 tokenId) public view returns (bool) {
    Stake memory tokensStake = _stakes[owner][tokenId];
    uint256 endTimestamp = tokensStake.startTimestamp + tokensStake.lockupPeriod;

    if (tokensStake.lockupPeriod == 0 || block.timestamp >= endTimestamp) {
      return true;
    }

    return false;
  }

  function addSnakeToVivarium(uint256 tokenId, uint256 lockupPeriod) public whenNotPaused {
    require(_lockupToMultipliers[lockupPeriod] != 0,"Vivarium: An invalid lockup period has been entered");
    require(lockupPeriod > 0, "Vivarium: Naughty, naughty. Lockup period must be greater than 0");
  
    _deposits[msg.sender].add(tokenId);
    _addStake(tokenId, lockupPeriod);
    _incrementNumberStaked();

    IERC721(ERC721_CONTRACT).safeTransferFrom(msg.sender, address(this), tokenId, '');
  }

  function removeSnakeFromVivarium(uint256 tokenId) public whenNotPaused {
    require(_deposits[msg.sender].contains(tokenId), "Vivarium: Snake must be deposited for it to be removed");
    require(block.timestamp > _stakes[msg.sender][tokenId].startTimestamp + _stakes[msg.sender][tokenId].lockupPeriod, "Vivarium: Staking lockup period has not completed");

    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;

    claim(tokenIds);

    _deposits[msg.sender].remove(tokenId);
    _decrementNumberStaked();

    IERC721(ERC721_CONTRACT).safeTransferFrom(address(this), msg.sender, tokenId, '');
  }

  function restakeSnakeToVivarium(uint256 tokenId, uint256 lockupPeriod) public whenNotPaused {
    require(_deposits[msg.sender].contains(tokenId), "Vivarium: Snake must already be deposited to restake");
    require(block.timestamp > _stakes[msg.sender][tokenId].startTimestamp + _stakes[msg.sender][tokenId].lockupPeriod, "Vivarium: Current stake must complete to restake");

    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;

    claim(tokenIds);

    _addStake(tokenId, lockupPeriod);    
  }

  function calculateRewards(address[] memory owners, uint256[] memory tokenIds) external view returns (uint256) {
    require(owners.length == tokenIds.length, "Vivarium: Input args must have equal length");

    uint256 totalReward = 0;

    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256[] memory info = _calculateTokenReward(owners[i], tokenIds[i]);
      totalReward += info[0] + info[1];
    }

    return totalReward;
  }

  function claim(uint256[] memory tokenIds) public whenNotPaused {
    uint256 reward = 0;

    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenReward = _claimTokenRewards(tokenIds[i]);
      reward += tokenReward;
    }

    ISnakeskin(ERC20_CONTRACT).mint(msg.sender, reward);
  }

  function emergencyWithdrawal(uint256[] memory tokenIds) external {
    require(isEmergencyWithdrawal, "Vivarium: Emergency withdrawal is currently disabled");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(_deposits[msg.sender].contains(tokenIds[i]), "Vivarium: Snake must be deposited for it to be removed");
    }

    for (uint256 i = 0; i < tokenIds.length; i++) {
      _deposits[msg.sender].remove(tokenIds[i]);
      _decrementNumberStaked();
      IERC721(ERC721_CONTRACT).safeTransferFrom(address(this), msg.sender, tokenIds[i], '');
    }
  }

  function setEmergencyWithdrawal(bool _isEmergencyWithdrawal) external onlyOwner {
    isEmergencyWithdrawal = _isEmergencyWithdrawal;
  }

  function bulkAddSnakes(uint256[] calldata tokenIds, uint256[] calldata lockupPeriods) external {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      addSnakeToVivarium(tokenIds[i], lockupPeriods[i]);
    }
  }

  function bulkRemoveSnakes(uint256[] calldata tokenIds) external {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      removeSnakeFromVivarium(tokenIds[i]);
    }
  }  

  function bulkRestakeSnakes(uint256[] calldata tokenIds, uint256[] calldata lockupPeriods) external {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      restakeSnakeToVivarium(tokenIds[i], lockupPeriods[i]);
    }
  }

  function isDeposited(uint256 tokenId, address snakeOwner) external view returns (bool) {
    return _deposits[snakeOwner].contains(tokenId);
  }

  function _setLockupMultipliers(uint256[] memory newLockups, uint256[] memory newLockupMultipliers) private onlyOwner {
    require(newLockups.length == newLockupMultipliers.length, "Vivarium: Must be equal size inputs");

    for (uint256 i = 0; i < _lockups.length; i++) {
      delete _lockupToMultipliers[_lockups[i]];
    }
    delete _lockups;

    // Lockup multiplier used after stake has expired
    _lockups.push(0);
    _lockupToMultipliers[0] = 1;

    for (uint256 i = 0; i < newLockupMultipliers.length; i++) {
      _lockups.push(newLockups[i]);
      _lockupToMultipliers[newLockups[i]] = newLockupMultipliers[i];
    }
  }

  function _addStake(uint256 tokenId, uint256 lockupPeriod) private {
    require(_lockupToMultipliers[lockupPeriod] != 0, "Vivarium: An invalid lockup period has been entered");

    Stake memory stake = Stake({
      startTimestamp: uint80(block.timestamp),
      lockupPeriod: uint80(lockupPeriod),
      tokensReceived: 0
    });

    _stakes[msg.sender][tokenId] = stake;
  }

  function _incrementNumberStaked() private {
    numberStaked += 1;
  }

  function _decrementNumberStaked() private {
    numberStaked -= 1;
  }

  function _applySizeMultiplier(uint256 tokenId, uint256 reward) private view returns (uint256) {
    uint256 snakeSize = ISassySnakes(ERC721_CONTRACT).snakeSize(tokenId);
    uint256 percentMultiplier = 100 + (snakeSize - 1) * 10;
    return (reward * percentMultiplier) / 100;
  }

  function _applyRarityMultiplier(uint256 tokenId, uint256 reward) private view returns (uint256) {
    uint256 snakeRarity = ISassySnakes(ERC721_CONTRACT).snakeRarity(tokenId);
    uint256 percentMultiplier = 100 + (snakeRarity - 1) * 10;
    return (reward * percentMultiplier) / 100;
  }

  function _calculateStakeReward(uint256 tokenId, uint256 lockupPeriod, uint256 secondsElapsed) 
    private 
    view 
    returns (uint256) 
  {
    uint256 reward = (secondsElapsed * _lockupToMultipliers[lockupPeriod] * BASE_REWARD) / 1 days;
    reward = _applyRarityMultiplier(tokenId, reward);
    reward = _applySizeMultiplier(tokenId, reward);
    return reward;
  }

  function _calculateTokenReward(address owner, uint256 tokenId) private view returns (uint256[] memory) {
    Stake memory stake = _stakes[owner][tokenId];
    uint256 currTimestamp = block.timestamp;
    uint256 stakeEndTimestamp = stake.startTimestamp + stake.lockupPeriod;

    // [2] = if zeroed stake created during execution
    uint256[] memory reward = new uint256[](3);

    uint256 elapsed;
    if (stake.startTimestamp >= currTimestamp) {
      elapsed = 0;
    } else if (stakeEndTimestamp <= currTimestamp) {
      elapsed = stake.lockupPeriod;
    } else {
      // Part way through lockupPeriod
      elapsed = currTimestamp - stake.startTimestamp;
    }

    if (elapsed > 0) {
      uint256 totalStakeReward = _calculateStakeReward(tokenId, stake.lockupPeriod, elapsed);
      uint256 unclaimedStakeReward = totalStakeReward - stake.tokensReceived;
      reward[0] = unclaimedStakeReward;
    }

    // Create new stake (with lockup=0) if this one has expired
    if (stake.lockupPeriod != 0 && elapsed == stake.lockupPeriod) {
      reward[2] = stakeEndTimestamp;

      if (stakeEndTimestamp < currTimestamp) {
        uint256 newStakeReward = _calculateStakeReward(tokenId, 0, currTimestamp - stakeEndTimestamp);
        reward[1] = newStakeReward;
      }
    }

    return reward;  
  }

  function _claimTokenRewards(uint256 tokenId) private returns (uint256) {
    require(_deposits[msg.sender].contains(tokenId), "Vivarium: Snake must be deposited to query current reward");

    uint256[] memory info = _calculateTokenReward(msg.sender, tokenId);
    if (info[2] != 0) {
      _stakes[msg.sender][tokenId] = Stake({
        startTimestamp: uint80(info[2]),
        lockupPeriod: 0,
        tokensReceived: 0
      });
      _stakes[msg.sender][tokenId].tokensReceived = info[1];
    } else {
      _stakes[msg.sender][tokenId].tokensReceived += info[0];
    }

    uint256 totalReward = info[0] + info[1];

    return totalReward;  
  }

}