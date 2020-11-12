// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./IOwnershipTransferrable.sol";
import "./ReentrancyGuard.sol";
import "./Vybe.sol";

contract VybeStake is ReentrancyGuard, Ownable {
  using SafeMath for uint256;

  uint256 constant UINT256_MAX = ~uint256(0);
  uint256 constant MONTH = 30 days;

  Vybe private _VYBE;

  bool private _dated;
  bool private _migrated;
  uint256 _deployedAt;

  uint256 _totalStaked;
  mapping (address => uint256) private _staked;
  mapping (address => uint256) private _lastClaim;
  address private _developerFund;

  event StakeIncreased(address indexed staker, uint256 amount);
  event StakeDecreased(address indexed staker, uint256 amount);
  event Rewards(address indexed staker, uint256 mintage, uint256 developerFund);
  event MelodyAdded(address indexed melody);
  event MelodyRemoved(address indexed melody);

  constructor(address vybe) Ownable(msg.sender) {
    _VYBE = Vybe(vybe);
    _developerFund = msg.sender;
    _deployedAt = block.timestamp;
  }

  function upgradeDevelopmentFund(address fund) external onlyOwner {
    _developerFund = fund;
  }

  function vybe() external view returns (address) {
    return address(_VYBE);
  }

  function totalStaked() external view returns (uint256) {
    return _totalStaked;
  }

  function migrate(address previous, address[] memory people, uint256[] memory lastClaims) external {
    require(!_migrated);
    require(people.length == lastClaims.length);
    for (uint i = 0; i < people.length; i++) {
      uint256 staked = VybeStake(previous).staked(people[i]);
      _staked[people[i]] = staked;
      _totalStaked = _totalStaked.add(staked);
      _lastClaim[people[i]] = lastClaims[i];
      emit StakeIncreased(people[i], staked);
    }
    require(_VYBE.transferFrom(previous, address(this), _VYBE.balanceOf(previous)));
    _migrated = true;
  }

  function staked(address staker) external view returns (uint256) {
    return _staked[staker];
  }

  function lastClaim(address staker) external view returns (uint256) {
    return _lastClaim[staker];
  }

  function increaseStake(uint256 amount) external {
    require(!_dated);

    require(_VYBE.transferFrom(msg.sender, address(this), amount));
    _totalStaked = _totalStaked.add(amount);
    _lastClaim[msg.sender] = block.timestamp;
    _staked[msg.sender] = _staked[msg.sender].add(amount);
    emit StakeIncreased(msg.sender, amount);
  }

  function decreaseStake(uint256 amount) external {
    _staked[msg.sender] = _staked[msg.sender].sub(amount);
    _totalStaked = _totalStaked.sub(amount);
    require(_VYBE.transfer(address(msg.sender), amount));
    emit StakeDecreased(msg.sender, amount);
  }

  function calculateSupplyDivisor() public view returns (uint256) {
    // base divisior for 5%
    uint256 result = uint256(20)
      .add(
        // get how many months have passed since deployment
        block.timestamp.sub(_deployedAt).div(MONTH)
        // multiply by 5 which will be added, tapering from 20 to 50
        .mul(5)
      );

    // set a cap of 50
    if (result > 50) {
      result = 50;
    }
    return result;
  }

  function _calculateMintage(address staker) private view returns (uint256) {
    // total supply
    uint256 share = _VYBE.totalSupply()
      // divided by the supply divisor
      // initially 20 for 5%, increases to 50 over months for 2%
      .div(calculateSupplyDivisor())
      // divided again by their stake representation
      .div(_totalStaked.div(_staked[staker]));

    // this share is supposed to be issued monthly, so see how many months its been
    uint256 timeElapsed = block.timestamp.sub(_lastClaim[staker]);
    uint256 mintage = 0;
    // handle whole months
    if (timeElapsed > MONTH) {
      mintage = share.mul(timeElapsed.div(MONTH));
      timeElapsed = timeElapsed.mod(MONTH);
    }
    // handle partial months, if there are any
    // this if check prevents a revert due to div by 0
    if (timeElapsed != 0) {
      mintage = mintage.add(share.div(MONTH.div(timeElapsed)));
    }
    return mintage;
  }

  function calculateRewards(address staker) public view returns (uint256) {
    // removes the five percent for the dev fund
    return _calculateMintage(staker).div(20).mul(19);
  }

  // noReentrancy shouldn't be needed due to the lack of external calls
  // better safe than sorry
  function claimRewards() external noReentrancy {
    require(!_dated);

    uint256 mintage = _calculateMintage(msg.sender);
    uint256 mintagePiece = mintage.div(20);
    require(mintagePiece > 0);

    // update the last claim time
    _lastClaim[msg.sender] = block.timestamp;
    // mint out their staking rewards and the dev funds
    _VYBE.mint(msg.sender, mintage.sub(mintagePiece));
    _VYBE.mint(_developerFund, mintagePiece);

    emit Rewards(msg.sender, mintage, mintagePiece);
  }

  function addMelody(address melody) external onlyOwner {
    _VYBE.approve(melody, UINT256_MAX);
    emit MelodyAdded(melody);
  }

  function removeMelody(address melody) external onlyOwner {
    _VYBE.approve(melody, 0);
    emit MelodyRemoved(melody);
  }

  function upgrade(address owned, address upgraded) external onlyOwner {
    _dated = true;
    IOwnershipTransferrable(owned).transferOwnership(upgraded);
  }
}
