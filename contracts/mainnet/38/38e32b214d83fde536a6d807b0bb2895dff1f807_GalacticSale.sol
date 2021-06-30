/**
 * 
 * 
  _______      ___       __          ___       ______ .___________. _______ .______       __   __    __  .___  ___. 
 /  _____|    /   \     |  |        /   \     /      ||           ||   ____||   _  \     |  | |  |  |  | |   \/   | 
|  |  __     /  ^  \    |  |       /  ^  \   |  ,----'`---|  |----`|  |__   |  |_)  |    |  | |  |  |  | |  \  /  | 
|  | |_ |   /  /_\  \   |  |      /  /_\  \  |  |         |  |     |   __|  |      /     |  | |  |  |  | |  |\/|  | 
|  |__| |  /  _____  \  |  `----./  _____  \ |  `----.    |  |     |  |____ |  |\  \----.|  | |  `--'  | |  |  |  | 
 \______| /__/     \__\ |_______/__/     \__\ \______|    |__|     |_______|| _| `._____||__|  \______/  |__|  |__|                                                                                                                

____ _  _ ____ ___  _ ____ _  _ ____    ____ ____    ___ _  _ ____    ____ ____ _    ____ ____ ___ ____ ____ _ _  _ _  _ 
| __ |  | |__| |  \ | |__| |\ | [__     |  | |___     |  |__| |___    | __ |__| |    |__| |     |  |___ |__/ | |  | |\/| 
|__] |__| |  | |__/ | |  | | \| ___]    |__| |        |  |  | |___    |__] |  | |___ |  | |___  |  |___ |  \ | |__| |  | 
                                                                                                                         
____ ____ ___ ____ ___     ____ _  _ ___     ____ ___ ____ ____ _  _ ____ _  _                                           
[__  |___  |  |___ |__]    |__| |\ | |  \    [__   |  |__| |__/ |\/| |__| |\ |                                           
___] |___  |  |___ |       |  | | \| |__/    ___]  |  |  | |  \ |  | |  | | \|   

Reality Benders

(3)(6)(9)
MarsOne
Rocket Labs
Elon Musk
Richard Brandson
Space Force
International Space Station
Beyond
 * 
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */


pragma solidity ^0.4.8;

import "./IncreasingPriceCrowdsale.sol";
import "./GalacticCrowdsale.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract GalacticSale is IncreasingPriceCrowdsale, Ownable {
  uint256 public defaultCap;
  mapping(address => uint256) public contributions;
  mapping(address => uint256) public caps;

  address  private ownerwallet;
  constructor (
    uint256 _openingTime,
    uint256 _closingTime,
    address  _wallet,
    address _token,
    uint256 _initialRate,
    uint256 _finalRate,
    uint256 _walletCap
  )
    public
    GalacticCrowdsale(_initialRate, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)
    IncreasingPriceCrowdsale(_initialRate, _finalRate)
  {
      ownerwallet=_wallet;
      defaultCap = _walletCap;
  }
  
  function closeSale() onlyOwner public{
      if(!hasClosed()) revert();
      uint256 contractTokenBalance = tokensRemaining();
     
      if(contractTokenBalance>0){
        ERC20(token).transfer(ownerwallet,contractTokenBalance);  
        emit Transfer(address(0),address(ownerwallet),contractTokenBalance);
      }
  }

/**
   * @dev Sets default user's maximum contribution.
   * @param _cap Wei limit for individual contribution
   */
  function setDefaultCap( uint256 _cap) external onlyOwner {
      defaultCap = _cap;
  }
/**
   * @dev Sets a specific user's maximum contribution.
   * @param _beneficiary Address to be capped
   * @param _cap Wei limit for individual contribution
   */
  function setUserCap(address _beneficiary, uint256 _cap) external onlyOwner {
    caps[_beneficiary] = _cap;
  }
/**
   * Called from invest() to confirm if the curret investment does not break our cap rule.
   */
  function isBreakingCap(uint tokenAmount) public view  returns (bool limitBroken) {
    if(tokenAmount > getTokensLeft()) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * We are sold out when our approve pool becomes empty.
   */
  function isCrowdsaleFull() public view returns (bool) {
    return getTokensLeft() == 0;
  }

  /**
   * Get the amount of unsold tokens allocated to this contract;
   */
  function getTokensLeft() public view returns (uint) {
    return token.allowance(owner, address(this));
  }

  /**
   * Transfer tokens from approve() pool to the buyer.
   *
   * Use approve() given to this crowdsale to distribute the tokens.
   */
  function assignTokens(address receiver, uint tokenAmount) onlyOwner {
    if(!token.transferFrom(address(0), receiver, tokenAmount)) revert();
  }
  /**
   * @dev Sets a group of users' maximum contribution.
   * @param _beneficiaries List of addresses to be capped
   * @param _cap Wei limit for individual contribution
   */
  function setGroupCap(
    address[]  _beneficiaries,
    uint256 _cap
  )
    external
    onlyOwner
  {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      caps[_beneficiaries[i]] = _cap;
    }
  }

  /**
   * @dev Returns the cap of a specific user.
   * @param _beneficiary Address whose cap is to be checked
   * @return Current cap for individual user
   */
  function getUserCap(address _beneficiary) public view returns (uint256) {
    return caps[_beneficiary];
  }

  /**
   * @dev Returns the amount contributed so far by a sepecific user.
   * @param _beneficiary Address of contributor
   * @return User contribution so far
   */
  function getUserContribution(address _beneficiary)
    public view returns (uint256)
  {
    return contributions[_beneficiary];
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the user's funding cap.
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    if(caps[_beneficiary]==0){
      caps[_beneficiary] = defaultCap;
    }
    require(contributions[_beneficiary].add(_weiAmount) <= caps[_beneficiary]);
  }

  /**
   * @dev Extend parent behavior to update user contributions
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._updatePurchasingState(_beneficiary, _weiAmount);
    contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount);
  }

}