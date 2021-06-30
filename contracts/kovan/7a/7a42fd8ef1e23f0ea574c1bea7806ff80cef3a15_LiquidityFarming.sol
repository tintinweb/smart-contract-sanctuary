// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


import "IERC20.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "ABDKMathQuad.sol";

 contract LiquidityFarming is Ownable {
  using SafeMath for uint256;

  address[] internal lockableToken;

  mapping(address => IERC20) internal token;

  mapping(address => uint256) public totalLocked;

  mapping(address => uint256) public totalScore;

  mapping(address => uint256) public blockReward;

  mapping(address => uint256) internal stakeBlock;

  mapping(address => bytes16) internal rewardRatio;

  mapping(address => mapping(address => address)) internal lockerAddress;

  mapping(address => mapping (address => uint256)) internal lockPermanentAmount;

  mapping(address => mapping (address => uint256)) internal lockTimedAmount;

  mapping(address => mapping (address => uint256)) internal lockTime;

  mapping(address => mapping (address => uint256)) internal userScore;

  mapping(address => mapping(address => bytes16)) internal userRewardRatio;

  uint256 public totalRewardsMinted;

  uint256 public rewardTax;

  uint256 internal treasury;

  TokenInterface SWN;

  TokenInterface STBL;

  address LGE;

    constructor() {
        address token_SWN = address(0xb057200dd85E514AE170135f43902640c0941F77);
        address token_STBL = address(0x231F7f060DdCB71284327d160ccF79DFf4cd38eF);
        SWN = TokenInterface(token_SWN);
        STBL = TokenInterface(token_STBL);
        LGE = address(0x5C75Aa32eFB0b5A07835F09D8810d2533f7337D7);
        rewardTax = 8;
    }

  function addLockablePair(address _pair, uint256 _blockReward)
  public
  {
    (bool _isLockable) = isLockable(_pair);
    if(!_isLockable){
      lockableToken.push(_pair);
      token[_pair] = IERC20(_pair);
      blockReward[_pair] = _blockReward;
    }
  }

  function adjustBlockReward(address _pair, uint256 _blockReward)
  public
  onlyOwner
  {
    require(isLockable(_pair), "This token has not been added!");
    calculateRewardRatio(_pair);
    blockReward[_pair] = _blockReward;
  }

  function adjustRewardTax(uint256 _rewardTax)
  public
  onlyOwner
  {
    require(0 < _rewardTax && _rewardTax <= 10);
    rewardTax = _rewardTax;
  }

  function removeRewardEmissions()
  public
  onlyOwner
  {
    for (uint256 s = 0; s < lockableToken.length; s += 1){
      calculateRewardRatio(lockableToken[s]);
      blockReward[lockableToken[s]] = 0;
    }

  }

  function isLockable(address _token)
  public
  view
  returns(bool)
  {
    for (uint256 s = 0; s < lockableToken.length; s += 1){
      if (_token == lockableToken[s]) return (true);
    }
    return (false);
  }

  function isLocker(address _pair, address _address)
  public
  view
  returns(bool)
  {
    if (_address == lockerAddress[_pair][_address]) return (true);
    return (false);
  }

  function lockPermanent(address _token, uint256 _amount)
  public
  {
    require(isLockable(_token), "Token not accepted!");
    require(token[_token].transferFrom(msg.sender, address(this), _amount), "No funds received!");
    pushLiquidityData(_token, msg.sender, _amount, true);
  }

  function lockTimed(address _token, uint256 _amount, uint256 _time)
  public
  {
    require(isLockable(_token), "Token not accepted!");
    require(token[_token].transferFrom(msg.sender, address(this), _amount), "No funds received!");
    require(lockTime[_token][msg.sender] < _time.add(block.timestamp), "Locking time cannot be shorter than for previous lock!");

    pushLiquidityData(_token, msg.sender, _amount, false);
    lockTime[_token][msg.sender] = _time.add(block.timestamp);
}

  function pushLiquidityData(address _token, address _stakeholder, uint256 _amount, bool _permanent)
  internal
  {//uint256 reward = rewardOf(_token, _stakeholder);
    if(totalLocked[_token] == 0) stakeBlock[_token] = block.number;
    else calculateRewardRatio(_token);

    if(!isLocker(_token, _stakeholder)){
      lockerAddress[_token][_stakeholder] = _stakeholder;
      totalLocked[_token] = totalLocked[_token].add(_amount);
      userRewardRatio[_token][_stakeholder] = rewardRatio[_token];
    }
    else {
      uint256 reward = rewardOf(_token, _stakeholder);
      totalLocked[_token] = totalLocked[_token].add(_amount);
      userRewardRatio[_token][_stakeholder] = rewardRatio[_token];
      distributeReward(_stakeholder, reward);
    }



    if(_permanent){
      userScore[_token][_stakeholder] = userScore[_token][_stakeholder].add(_amount.mul(2));
      totalScore[_token] = totalScore[_token].add(_amount.mul(2));
      lockPermanentAmount[_token][_stakeholder] = lockPermanentAmount[_token][_stakeholder].add(_amount);
    }
    else {
      userScore[_token][_stakeholder] = userScore[_token][_stakeholder].add(_amount);
      totalScore[_token] = totalScore[_token].add(_amount);
      lockTimedAmount[_token][_stakeholder] = lockTimedAmount[_token][_stakeholder].add(_amount);
    }
  }

  function pushPermanentLockFromLGE(address _liquidityToken, uint256 _totalLiquidityTokenAmount, address[] memory investors, uint256[] memory tokenAmount)
  public
  {
    require(msg.sender == LGE, "Function can only be called by the Liquidity Generation Event contract!");
    addLockablePair(_liquidityToken, 1000000000000000000); // Token addresses and block reward
    require(isLockable(_liquidityToken), "Token not accepted!");
    require(token[_liquidityToken].transferFrom(msg.sender, address(this), _totalLiquidityTokenAmount), "No funds received!");

    if(totalLocked[_liquidityToken] == 0) {
      stakeBlock[_liquidityToken] = block.number;
    }
    else {
      calculateRewardRatio(_liquidityToken);
    }
    for (uint256 s = 0; s < investors.length; s += 1){

        if(!isLocker(_liquidityToken, investors[s])) lockerAddress[_liquidityToken][investors[s]] = investors[s];
        totalLocked[_liquidityToken] = totalLocked[_liquidityToken].add(tokenAmount[s]);
        lockPermanentAmount[_liquidityToken][investors[s]] = lockPermanentAmount[_liquidityToken][investors[s]].add(tokenAmount[s]);
        userRewardRatio[_liquidityToken][investors[s]] = rewardRatio[_liquidityToken];
        userScore[_liquidityToken][investors[s]] = userScore[_liquidityToken][investors[s]].add(tokenAmount[s].mul(2));
        totalScore[_liquidityToken] = totalScore[_liquidityToken].add(tokenAmount[s].mul(2));
    }

  }

    function pushLGEAddress(address _LGE) public onlyOwner {
      LGE = _LGE;
    }

  function blocksStaked(address _token)
  private
  view
  returns(uint256)
  {
    return  block.number.sub(stakeBlock[_token]);
  }

  function rewardOf(address _token, address _stakeholder)
  public
  view
  returns(uint256 totalRewards)
  {
    uint256 totalUserScore = userScore[_token][_stakeholder];
    totalRewards = ABDKMathQuad.toUInt(ABDKMathQuad.mul(ABDKMathQuad.fromUInt(totalUserScore), ABDKMathQuad.sub(rewardRatio[_token], userRewardRatio[_token][_stakeholder])));

    return totalRewards;
  }

  function getTotalScore(address _token) internal view returns (uint256 _totalScore){
    _totalScore = totalScore[_token];
  }

  function calculateRewardRatio(address _pair)
  public
  {
    uint256 accumulatedRewards = blockReward[_pair].mul(blocksStaked(_pair));
    rewardRatio[_pair] = ABDKMathQuad.add(rewardRatio[_pair], ABDKMathQuad.div(ABDKMathQuad.fromUInt(accumulatedRewards), ABDKMathQuad.fromUInt(getTotalScore(_pair))));
    stakeBlock[_pair] = block.number;
  }

  /**
  * @notice A method to distribute reward to .
  */
  function distributeReward(address _stakeholder, uint256 _reward)
  internal
  {
    uint256 tax = _reward.mul(rewardTax).div(100);
    SWN.mint(_stakeholder, _reward.sub(tax));
    SWN.mint(address(this), tax);
    totalRewardsMinted = totalRewardsMinted.add(_reward);
    treasury = treasury.add(tax);
  }

  /**
  * @notice A method to allow a stakeholder to withdraw his rewards.
  */
  function withdrawReward(address _token)
  public
  {
    require(lockTimedAmount[_token][msg.sender] > 0 || lockPermanentAmount[_token][msg.sender] > 0, "No active stake found!");

    calculateRewardRatio(_token);
    uint256 reward = rewardOf(_token, msg.sender);
    userRewardRatio[_token][msg.sender] = rewardRatio[_token];
    totalRewardsMinted = totalRewardsMinted.add(reward);
    uint256 tax = reward.mul(rewardTax).div(100);
    SWN.mint(msg.sender, reward.sub(tax));
    SWN.mint(address(this), tax);
    treasury = treasury.add(tax);


  }

  function treasuryReward(address _address, uint256 _amount)
  public
  onlyOwner
  {
    require(_amount <= treasury, "Amount exceeds balance!");
    SWN.transfer(_address, _amount);
  }

  function withdrawLiquidity(address _token, uint256 _amount)
  public
  {
    require(lockTime[_token][msg.sender] < block.timestamp, "Lock time not over!");
    require(_amount <= lockTimedAmount[_token][msg.sender], "Amount exceeds balance!");
    calculateRewardRatio(_token);
    uint256 reward = rewardOf(_token, msg.sender);

    totalLocked[_token] = totalLocked[_token].sub(_amount);
    lockTimedAmount[_token][msg.sender] = lockTimedAmount[_token][msg.sender].sub(_amount);
    userRewardRatio[_token][msg.sender] = rewardRatio[_token];
    totalScore[_token] = totalScore[_token].sub(_amount);
    userScore[_token][msg.sender] = userScore[_token][msg.sender].sub(_amount);
    distributeReward(msg.sender, reward);
    token[_token].transfer(msg.sender, _amount);

  }

}

interface TokenInterface {
    function mint(address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}