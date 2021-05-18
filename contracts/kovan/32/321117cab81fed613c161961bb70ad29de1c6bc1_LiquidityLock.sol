// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


import "IERC20.sol";
import "Ownable.sol";
import "UniswapLiquidityInterface.sol";
import "SafeMath.sol";

 contract LiquidityLock is Ownable, LiquidityValueCalculator {
  using SafeMath for uint256;

  address[] internal lockableToken;

  mapping(address => IERC20) internal token;

  mapping(address => uint256) public totalLocked;

  mapping(address => uint256) public totalScore;

  mapping(address => uint256) public totalNFTScore;

  mapping(address => uint256) public blockReward;

  mapping(address => uint256) internal stakeBlock;

  mapping(address => bytes16) internal rewardRatio;

  mapping(address => mapping(address => address)) internal lockerAddress;

  mapping(address => mapping (address => uint256)) internal lockPermanentAmount;

  mapping(address => mapping (address => uint256)) internal lockTimedAmount;

  mapping(address => mapping (address => uint256)) internal lockTime;

  mapping(address => mapping (address => uint256)) internal userScore;

  mapping(address => mapping (address => uint256)) internal NFTScore;

  mapping(address => mapping(address => bytes16)) internal userRewardRatio;

  uint256 public totalRewardsMinted;

  uint256 internal treasury;

  TokenInterface SWN;

  TokenInterface STBL;

  NFTInterface NFT;

  MathInteface ABDKMathQuad;

  address LGE;

  address NFTManager;

  address PreLiquidityNFT;

    constructor() {
        address token_SWN = address(0x84967A6Aee89AC7867e0Fff65D6d1c348945Ed3e);
        address token_STBL = address(0x79931818921d7Ce09e91B27ADd67bab4125eb066);
        SWN = TokenInterface(token_SWN);
        STBL = TokenInterface(token_STBL);
        NFT = NFTInterface(0x0);
        LGE = address(0x0);
        NFTManager = address(0x0);
        ABDKMathQuad = MathInteface(0x85321dF71Fbbc2444E0A8c006cb4E74b4Af52AE7);
    }

  function addLockablePair(address _pair, uint256 _blockReward)
  public
  onlyOwner
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

    if(NFT.isStaker(PreLiquidityNFT, msg.sender)) refreshDataNFT(_token, msg.sender);

    if(_token == lockableToken[0]){ // STBL recollateralizaton
      uint256 value = computeLiquidityShareTokenBValue(_amount, address(SWN), address(STBL));
      STBL.mint(address(this), value);
      treasury = treasury.add(value);
    }
  }

  function lockTimed(address _token, uint256 _amount, uint256 _time)
  public
  {
    require(isLockable(_token), "Token not accepted!");
    require(token[_token].transferFrom(msg.sender, address(this), _amount), "No funds received!");
    require(lockTime[_token][msg.sender] < _time.add(block.timestamp), "Locking time cannot be shorter than for previous lock!");

    pushLiquidityData(_token, msg.sender, _amount, false);
    lockTime[_token][msg.sender] = _time.add(block.timestamp);
    if(NFT.isStaker(PreLiquidityNFT, msg.sender)) refreshDataNFT(_token, msg.sender);
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

    function pushNFTAddress(address _NFT) public onlyOwner {
      NFT = NFTInterface(_NFT);
    }

  function refreshDataNFT(address _token, address _staker) internal {
    uint256 previousNFTScore = NFTScore[_token][_staker];
    NFTScore[_token][msg.sender] = NFT.calculateScore(PreLiquidityNFT, _staker, userScore[_token][_staker]);
    totalNFTScore[_token] = totalNFTScore[_token].sub(previousNFTScore).add(NFTScore[_token][_staker]);
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
    if(NFTScore[_token][_stakeholder] > 0) totalUserScore = totalUserScore.add(NFTScore[_token][_stakeholder]);
    totalRewards = ABDKMathQuad.toUInt(ABDKMathQuad.mul(ABDKMathQuad.fromUInt(totalUserScore), ABDKMathQuad.sub(rewardRatio[_token], userRewardRatio[_token][_stakeholder])));

    return totalRewards;
  }

  function getTotalScore(address _token) internal view returns (uint256 _totalScore){
    _totalScore = totalScore[_token].add(totalNFTScore[_token]);
  }

  function addRewardNFT(address _NFT, uint _id) public { // Need to approve NFT for NFTManager contract first
    require(NFT.stakeNFT(msg.sender, _NFT, _id), "NFT staking failed!");
    for (uint256 s = 0; s < lockableToken.length; s += 1){
      if(isLocker(lockableToken[s], msg.sender)){
        calculateRewardRatio(lockableToken[s]);
        uint256 reward = rewardOf(lockableToken[s], msg.sender);
        userRewardRatio[lockableToken[s]][msg.sender] = rewardRatio[lockableToken[s]];
        distributeReward(msg.sender, reward);
        refreshDataNFT(lockableToken[s], msg.sender);
      }
    }

  }

  function removeRewardNFT(address _NFT, uint _id) public { // Need to approve NFT for NFTManager contract first
    require(NFT.unStakeNFT(msg.sender, _NFT, _id), "NFT unstaking failed!");
    for (uint256 s = 0; s < lockableToken.length; s += 1){
      if(isLocker(lockableToken[s], msg.sender)){
        calculateRewardRatio(lockableToken[s]);
        uint256 reward = rewardOf(lockableToken[s], msg.sender);
        userRewardRatio[lockableToken[s]][msg.sender] = rewardRatio[lockableToken[s]];
        distributeReward(msg.sender, reward);
        refreshDataNFT(lockableToken[s], msg.sender);
      }
    }

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
    SWN.mint(_stakeholder, _reward); // Should call SWN.mint and also increment rewardPermanentLock by x
    totalRewardsMinted = totalRewardsMinted.add(_reward);
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
    SWN.mint(msg.sender, reward);  // Should call SWN.mint instead and also increment rewardPermanentLock by x

  }

  function treasuryReward(address _address, uint256 _amount)
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
    calculateRewardRatio(_token);
    uint256 reward = rewardOf(_token, msg.sender);

    totalLocked[_token] = totalLocked[_token].sub(_amount);
    lockTimedAmount[_token][msg.sender] = lockTimedAmount[_token][msg.sender].sub(_amount);
    userRewardRatio[_token][msg.sender] = rewardRatio[_token];
    totalScore[_token] = totalScore[_token].sub(_amount);
    userScore[_token][msg.sender] = userScore[_token][msg.sender].sub(_amount);
    if(NFT.isStaker(PreLiquidityNFT, msg.sender) || NFTScore[_token][msg.sender] > 0){
      uint256 previousNFTScore = NFTScore[_token][msg.sender];
      NFTScore[_token][msg.sender] = NFT.calculateScore(PreLiquidityNFT, msg.sender, userScore[_token][msg.sender]);
      totalNFTScore[_token] = totalNFTScore[_token].sub(previousNFTScore).add(NFTScore[_token][msg.sender]);
    }

    distributeReward(msg.sender, reward);
    token[_token].transfer(msg.sender, _amount);

  }

}

interface TokenInterface {
    function mint(address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
}

interface NFTInterface {
    function stakeNFT(address _staker, address _NFT, uint _id) external returns (bool);
    function isStaker(address _NFT, address _address) external view returns(bool);
    function hasStakedNFT(address _owner) external view returns(bool);
    function calculateScore(address _NFT, address _owner, uint256 _previousScore) external view returns(uint256 addedScore);
    function unStakeNFT(address _staker, address _NFT, uint _id) external returns (bool);
}
interface MathInteface {
  function fromUInt (uint256 x) external pure returns (bytes16);
  function toUInt (bytes16 x) external pure returns (uint256);
  function add (bytes16 x, bytes16 y) external pure returns (bytes16);
  function sub (bytes16 x, bytes16 y) external pure returns (bytes16);
  function mul (bytes16 x, bytes16 y) external pure returns (bytes16);
  function div (bytes16 x, bytes16 y) external pure returns (bytes16);
}