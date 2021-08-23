/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

pragma solidity 0.8.5;
// SPDX-License-Identifier: MIT

import "./PancakeRouter.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";

contract TokenSwap is Ownable, ReentrancyGuard {
  address private TOKEN;
  address private WBNB;
  
  mapping (address => bool) private _whitelistedAddresses; // The list of whitelisted addresses
  
  event SuccessfullyBought(address, bool, bool, bool);
  
  uint8 private _contractFee; //% of each transaction that will sent to contract
  uint8 private _rewardFee; //% of each transaction that will be used for BNB reward pool
  uint8 private _marketingFee; //% of each transaction that will be used for increasing market wallet
  uint8 private _totalFees; //total fees
  
  // PANCAKESWAP INTERFACES (For swaps)
  address private _pancakeSwapRouterAddress;
  address private _marketingWalletAddress;
  
  IPancakeRouter02 private _pancakeswapV2Router;
    
  uint256 private _totalMarketingFeesPooled;
  uint256 private _totalContractFeesPooled;
  uint256 private _totalRewardFeesPooled;
  uint256 private _totalBnbBought;
  uint256 private _totalFeesPooled;
  
  //WBNB Test 0xae13d989dac2f0debff460ac112a837c89baa7cd|| 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
  //Router TESTNET: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 || other 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
  constructor(address routerAddress, address wbnbAddress, address tokenAddress) {
    _whitelistedAddresses[address(this)] = true;
    _pancakeSwapRouterAddress = routerAddress; 
    _pancakeswapV2Router = IPancakeRouter02(_pancakeSwapRouterAddress);
    WBNB = wbnbAddress;
    TOKEN = tokenAddress;
     
    _totalMarketingFeesPooled = 0;
    _totalContractFeesPooled = 0;
    _totalRewardFeesPooled = 0;
    _totalBnbBought = 0;
    _totalFeesPooled = 0;
    
    _contractFee = 2;
    _rewardFee = 4;
    _marketingFee = 6;
    _totalFees = _contractFee + _rewardFee + _marketingFee;
    _marketingWalletAddress = msg.sender;
  }
  
  function setMarketingWallet(address marketingWallet) public onlyOwner() {
      _marketingWalletAddress = marketingWallet;
  }
  
  function getTokenAddress() public view returns(address) {
      return TOKEN;
  }
  
  function getWbnbAddress() public view returns(address) {
      return WBNB;
  }
  
  function getFees() public view returns(uint8, uint8, uint8) {
  return (_marketingFee, _contractFee, _rewardFee);
  }
  
  receive() external payable {
    buyToken();
  }

  function buyToken() public payable returns(bool){
    require((msg.value/100)*100 == msg.value, 'Too small');
      address[] memory path = new address[](2);
      path[0] = WBNB;
      path[1] = TOKEN;
    if (_whitelistedAddresses[msg.sender]) {
      _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(0, path, msg.sender, block.timestamp);
      emit SuccessfullyBought(msg.sender, true, true, true);
    } else {
      // The amount parameter includes both the liquidity and the reward tokens, we need to find the correct portion for each one so that they are allocated accordingly
      uint256 bnbToSend = (msg.value * (100 - _totalFees))/100;
      uint256 feeAmount = msg.value - bnbToSend;
      uint256 tokensReservedForReward = (feeAmount * _rewardFee) / _totalFees;
      uint256 tokensReservedForContract = (feeAmount * _contractFee) / _totalFees;
      uint256 tokensReservedForMarketing = feeAmount - tokensReservedForReward - tokensReservedForContract;
      _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbToSend}(0, path, msg.sender, block.timestamp);
      _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: tokensReservedForContract}(0, path, TOKEN, block.timestamp);
      (bool successSentRewards,) = TOKEN.call{value:tokensReservedForReward}("");
      (bool successSentMarketing,) = _marketingWalletAddress.call{value:tokensReservedForMarketing}("");
        
      // Keep track of how many BNB were added to all
      _totalBnbBought += msg.value;
      _totalContractFeesPooled += tokensReservedForContract;
      _totalRewardFeesPooled += tokensReservedForReward;
      _totalMarketingFeesPooled += tokensReservedForMarketing;
      _totalFeesPooled += feeAmount;
      
      emit SuccessfullyBought(msg.sender, true, successSentRewards, successSentMarketing);
    }
    
    return true;
  }
  
  function setFees(uint8 marketingFee, uint8 contractFee, uint8 rewardFee) public onlyOwner {
    require(marketingFee + contractFee + rewardFee <= 18, "Total fees cannot exceed 18%");
        
    _marketingFee = marketingFee;
    _contractFee = contractFee;
    _rewardFee = rewardFee;
        
    // Enforce invariant
    _totalFees = marketingFee + contractFee + rewardFee; 
  }
  
  function setWhitelisted(address addr, bool whitelist) public onlyOwner {
    _whitelistedAddresses[addr] = whitelist;
  }
  
  function isWhitelisted(address addr) public view returns (bool) {
    return _whitelistedAddresses[addr];
  }
    
  function extractLeftovers() external payable onlyOwner {
    require(address(this).balance > 0, "Contract balance is zero");
    (payable(msg.sender)).transfer(address(this).balance);
  }
}