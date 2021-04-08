// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


import "IERC20.sol";
import "Ownable.sol";
import "UniswapLiquidityInterface.sol";
import "SafeMath.sol";
import "ABDKMathQuad.sol";

 contract LiquidityLock is Ownable, LiquidityValueCalculator {
  using SafeMath for uint256;

  address[] internal lockableToken;

  mapping(address => IERC20) internal token;

  mapping(address => address) internal pairTokenA;

  mapping(address => address) internal pairTokenB;

  mapping(address => uint256) public totalLocked;

  mapping(address => address) internal lockerAddress;

  mapping(address => uint256) public blockReward;

  mapping(address => uint256) internal stakeBlock;

  mapping(address => bytes16) internal rewardRatio;

  mapping(address => mapping (address => uint256)) internal lockPermanentAmount;

  mapping(address => mapping (address => uint256)) internal lockTimedAmount;

  mapping(address => mapping (address => uint256)) internal lockTime;

  mapping(address => mapping(address => bytes16)) internal userRewardRatio;

  uint256 public totalRewardsMinted;

  uint256 internal treasury;

  TokenInterface SWN;

  TokenInterface STBL;

    constructor() {
        address SWN_STBL_pair = address(0x23F218B689185c1794d831bcd1CA6379a5067C74);
        address token_SWN = address(0x98BbEB7e4D59a3E6A3bc6422E5Ff73906302CdE0);
        address token_STBL = address(0xa2fbb92B5C04b7E71C4a06E9d9B2f46e83E1A966);
        SWN = TokenInterface(token_SWN);
        STBL = TokenInterface(token_STBL);
        addLockablePair(SWN_STBL_pair, token_SWN, token_STBL, 1000000000000000000);
    }

  function addLockablePair(address _pair, address _tokenA, address _tokenB, uint256 _blockReward)
  public
  onlyOwner
  {
    (bool _isLockable) = isLockable(_pair);
    if(!_isLockable){
      lockableToken.push(_pair);
      token[_pair] = IERC20(_pair);
      pairTokenA[_pair] = _tokenA;
      pairTokenB[_pair] = _tokenB;
      blockReward[_pair] = _blockReward;
    }
  }

  function adjustBlockReward(address _pair, uint256 _blockReward)
  public
  onlyOwner
  {
    calculateRewardRatio(_pair);
    blockReward[_pair] = _blockReward;
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

  function isLocker(address _address)
  public
  view
  returns(bool)
  {
    if (_address == lockerAddress[_address]) return (true);
    return (false);
  }

  function lockPermanent(address _token, uint256 _amount)
  public
  {
    (bool _isLockable) = isLockable(_token);
    require(_isLockable, "Token not accepted!");
    require(token[_token].transferFrom(msg.sender, address(this), _amount), "No funds received!");
    if(totalLocked[_token] == 0) {
    stakeBlock[_token] = block.number;
    }
    else {
      calculateRewardRatio(_token);
    }

    (bool _isLocker) = isLocker(msg.sender);
    if(!_isLocker){
      lockerAddress[msg.sender] = msg.sender;
    }
    else{
      distributeReward(_token, msg.sender);
    }
    totalLocked[_token] = totalLocked[_token].add(_amount);
    lockPermanentAmount[_token][msg.sender] = lockPermanentAmount[_token][msg.sender].add(_amount);
    userRewardRatio[_token][msg.sender] = rewardRatio[_token];

    if(_token == lockableToken[0]){ // SWN/STBL pair
      uint256 value = computeLiquidityShareTokenBValue(_amount, pairTokenA[_token], pairTokenB[_token]);
      STBL.mint(address(this), value);
      treasury = treasury.add(value);
    }
  }

  function lockTimed(address _token, uint256 _amount, uint256 _time)
  public
  {
    (bool _isLockable) = isLockable(_token);
    require(_isLockable, "Token not accepted!");
    require(token[_token].transferFrom(msg.sender, address(this), _amount), "No funds received!");
    (bool _isLocker) = isLocker(msg.sender);

    if(totalLocked[_token] == 0) {
      stakeBlock[_token] = block.number;
    }
    else {
      calculateRewardRatio(_token);
    }

    if(!_isLocker){
      lockerAddress[msg.sender] = msg.sender;
    }
    else {
      require(lockTime[_token][msg.sender] < _time.add(block.timestamp), "Locking time cannot be shorter than for previous lock!");
      distributeReward(_token, msg.sender);
    }

    totalLocked[_token] = totalLocked[_token].add(_amount);
    lockTimedAmount[_token][msg.sender] = lockTimedAmount[_token][msg.sender].add(_amount);
    lockTime[_token][msg.sender] = _time.add(block.timestamp);
    userRewardRatio[_token][msg.sender] = rewardRatio[_token];
}

  function pushPermanentLockFromLGE(address _LGEcontract, address _liquidityToken, uint256 _totalLiquidityTokenAmount)
  public
  onlyOwner
  {
    (bool _isLockable) = isLockable(_liquidityToken);
    require(_isLockable, "Token not accepted!");
    require(token[_liquidityToken].transferFrom(msg.sender, address(this), _totalLiquidityTokenAmount), "No funds received!");
    LGEInterface LGE_Interface = LGEInterface(_LGEcontract);
    address[] memory investors = LGE_Interface.getInvestors();
    uint256 tokenAmount;

    if(totalLocked[_liquidityToken] == 0) {
      stakeBlock[_liquidityToken] = block.number;
    }
    else {
      calculateRewardRatio(_liquidityToken);
    }
    for (uint256 s = 0; s < investors.length; s += 1){

        (bool _isLocker) = isLocker(investors[s]);
        tokenAmount = LGE_Interface.individualLiquidityTokenAmount(_totalLiquidityTokenAmount, investors[s]);
        if(!_isLocker){
          lockerAddress[investors[s]] = investors[s];
        }
        else {
          distributeReward(_liquidityToken, investors[s]);
        }
        totalLocked[_liquidityToken] = totalLocked[_liquidityToken].add(tokenAmount);
        lockPermanentAmount[_liquidityToken][investors[s]] = lockPermanentAmount[_liquidityToken][investors[s]].add(tokenAmount);
        userRewardRatio[_liquidityToken][investors[s]] = rewardRatio[_liquidityToken];
    }

  }

  function lockAmountOf(address _token, address _address)
  public
  view
  returns(uint256 totalTokensLocked, uint256 timelockedTokens)
  {
    totalTokensLocked = lockTimedAmount[_token][_address].add(lockPermanentAmount[_token][_address]);
    timelockedTokens = lockTimedAmount[_token][_address];
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
  returns(uint256)
  {
    uint256 totalRewards;

    if(lockTimedAmount[_token][_stakeholder] > 0) {
      totalRewards = totalRewards.add(ABDKMathQuad.toUInt(ABDKMathQuad.mul(ABDKMathQuad.fromUInt(lockTimedAmount[_token][_stakeholder]), ABDKMathQuad.sub(rewardRatio[_token], userRewardRatio[_token][_stakeholder]))));
    }
    if(lockPermanentAmount[_token][_stakeholder] > 0) {
      totalRewards = totalRewards.add(ABDKMathQuad.toUInt(ABDKMathQuad.mul(ABDKMathQuad.fromUInt(lockPermanentAmount[_token][_stakeholder]), ABDKMathQuad.sub(rewardRatio[_token], userRewardRatio[_token][_stakeholder]))).mul(3));
    }
    return totalRewards;
  }

  function calculateRewardRatio(address _pair)
  public
  {
    uint256 accumulatedRewards = blockReward[_pair].mul(blocksStaked(_pair));
    rewardRatio[_pair] = ABDKMathQuad.add(rewardRatio[_pair], ABDKMathQuad.div(ABDKMathQuad.fromUInt(accumulatedRewards), ABDKMathQuad.fromUInt(totalLocked[_pair])));
    stakeBlock[_pair] = block.number;
  }

  /**
  * @notice A method to distribute reward to .
  */
  function distributeReward(address _token, address _stakeholder)
  private
  {
    uint256 reward = rewardOf(_token, _stakeholder);
    SWN.mint(msg.sender, reward); // Should call SWN.mint and also increment rewardPermanentLock by x
    totalRewardsMinted = totalRewardsMinted.add(reward);
  }

  /**
  * @notice A method to allow a stakeholder to withdraw his rewards.
  */
  function withdrawReward(address _token)
  public
  {
    (bool _isStakeholder) = isLocker(msg.sender);
    require(_isStakeholder, "No active stake found!");

    uint256 reward = rewardOf(_token, msg.sender);

    calculateRewardRatio(_token);
    SWN.mint(msg.sender, reward);  // Should call SWN.mint instead and also increment rewardPermanentLock by x
    userRewardRatio[_token][msg.sender] = rewardRatio[_token];
    totalRewardsMinted = totalRewardsMinted.add(reward);
  }

  function treasuryAmount()
  public
  view
  returns(uint256)
  {
    return treasury;
  }

  function treasuryReward(uint256 _amount, address _address)
  public
  onlyOwner
  {
    require(_amount <= treasury, "Amount exceeds balance!");
    STBL.transfer(_address, _amount);
  }

  function withdrawLiquidity(address _token, uint256 _amount)
  public
  {
    require(lockTime[_token][msg.sender] < block.timestamp, "Lock time not over!");
    require(_amount <= lockTimedAmount[_token][msg.sender], "Amount exceeds balance!");
    token[_token].transfer(msg.sender, _amount);
    calculateRewardRatio(_token);
    distributeReward(_token, msg.sender);
    totalLocked[_token] = totalLocked[_token].sub(_amount);
    lockTimedAmount[_token][msg.sender] = lockTimedAmount[_token][msg.sender].sub(_amount);
    userRewardRatio[_token][msg.sender] = rewardRatio[_token];

  }

}

interface TokenInterface {
    function mint(address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

interface LGEInterface {
      function getInvestors()
          external
          view
          returns(address[] memory);
      function individualLiquidityTokenAmount(uint256 _totalTokensCreated, address _investor)
          external
          view
          returns(uint256);
    }