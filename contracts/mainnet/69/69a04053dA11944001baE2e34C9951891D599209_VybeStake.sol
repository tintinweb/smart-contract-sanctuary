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

  uint256 _totalStaked;
  mapping (address => uint256) private _staked;
  mapping (address => uint256) private _lastClaim;
  address private _developerFund;

  event Rewards(address indexed staker, uint256 mintage, uint256 developerFund);
  event MelodyAdded(address indexed melody);
  event MelodyRemoved(address indexed melody);

  constructor(address vybe) Ownable(msg.sender) {
    _VYBE = Vybe(vybe);
    _developerFund = msg.sender;
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

  function staked(address staker) external view returns (uint256) {
    return _staked[staker];
  }

  function increaseStake(uint256 amount) external {
    require(_VYBE.transferFrom(msg.sender, address(this), amount));
    _totalStaked = _totalStaked.add(amount);
    if (_staked[msg.sender] == 0) {
      _lastClaim[msg.sender] = block.timestamp;
    }
    _staked[msg.sender] = _staked[msg.sender].add(amount);
  }

  function decreaseStake(uint256 amount) external {
    _staked[msg.sender] = _staked[msg.sender].sub(amount);
    _totalStaked = _totalStaked.sub(amount);
    require(_VYBE.transfer(address(msg.sender), amount));
  }

  function _calculateMintage(address staker) private view returns (uint256) {
    uint256 share = _VYBE.totalSupply().div(20).div(_totalStaked.div(_staked[staker]));
    uint256 timeElapsed = block.timestamp.sub(_lastClaim[staker]);
    uint256 mintage = 0;
    if (timeElapsed > MONTH) {
      mintage = share.mul(timeElapsed.div(MONTH));
      timeElapsed = timeElapsed.mod(MONTH);
    }
    if (timeElapsed != 0) {
      mintage = mintage.add(share.div(MONTH.div(timeElapsed)));
    }
    return mintage;
  }

  function calculateRewards(address staker) public view returns (uint256) {
    return _calculateMintage(staker).div(20).mul(19);
  }

  function claimRewards() external noReentrancy {
    uint256 mintage = _calculateMintage(msg.sender);
    uint256 mintagePiece = mintage.div(20);
    require(mintagePiece > 0);

    _lastClaim[msg.sender] = block.timestamp;
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
    IOwnershipTransferrable(owned).transferOwnership(upgraded);
  }
}
