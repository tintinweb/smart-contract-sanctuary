//SourceUnit: FRLO_IDO.sol

// SPDX-License-Identifier: none
pragma solidity ^0.8.0;

interface TRC20 {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract FundRaiseLaunchpadIDO{
    
  uint public priceOfTRX = 79; // 0.079 usd
 
  
  struct Investor {
    bool registered;
    uint invested;
    address referer;
    uint balanceRef;
  }

  address public buyTokenAddr;
  address public updater;
  address public contractAddr = address(this);
  uint public currentTokenPrice = 14;
  uint public currrentTokenPriceDecimal = 100;

  address public owner = msg.sender;
  
  uint[] public refRewards;
  
  mapping (address => Investor) public investors;
  event DepositAt(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);
  event OwnershipTransferred(address);
  
  constructor() {
        updater = msg.sender;
        for (uint i = 3; i >= 1; i--) {
            refRewards.push(i);
        }
  }

  
  function rewardReferers(uint amount, address referer) internal {
    address rec = referer;
    
    for (uint i = 0; i < refRewards.length; i++) {
      if (investors[rec].invested == 0) {
        break;
      }
      uint refRewardPercent = 0;
      if(i==0){
          refRewardPercent = 3;
      }
      else if(i==1){
          refRewardPercent = 2;
      }
      else if(i==2){
          refRewardPercent = 1;
      }
      uint a = amount * refRewardPercent / 100;
      
      investors[rec].balanceRef += a;
      
      
      rec = investors[rec].referer;
    }
  }
  
  function buyTokenWithTRX(address referer) external payable {

    require(msg.value >= 0,"Invalid Amount");
 
    address sender = msg.sender;
   
    if (investors[referer].invested > 0 && investors[sender].invested==0) {
        investors[msg.sender].referer = referer;
    }
   
    uint tokenVal = (msg.value * priceOfTRX / (1000/currrentTokenPriceDecimal)) / currentTokenPrice;
    
    investors[sender].invested += tokenVal;
    
    rewardReferers(tokenVal, investors[msg.sender].referer);

    emit DepositAt(sender, 0, tokenVal);
  } 

  

    /*
    like tokenPrice = 0.0000000001
    setBuyPrice = 1 
    tokenPriceDecimal= 10
    */
    // Set buy price  

    function changTokenPrice(uint _currentTokenPrice, uint _currrentTokenPriceDecimal) external {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        currentTokenPrice   = _currentTokenPrice;
        currrentTokenPriceDecimal     = _currrentTokenPriceDecimal;
    }


    function setBuyTokenAddr(address _buyTokenAddr) external {
        require(msg.sender == owner || msg.sender == updater, "Permission error");
        buyTokenAddr = _buyTokenAddr;
    }


    function buyFRLPManual(address addr,uint amt) external  {
    require(msg.sender == owner || msg.sender == updater, "Permission error");
    address sender = addr;
    
    uint tokenVal = (amt * priceOfTRX / (1000/currrentTokenPriceDecimal)) / currentTokenPrice;
    
    investors[sender].invested += tokenVal;
    emit DepositAt(sender, 0, tokenVal);
  }


    // only by owner
    function changeUpdater(address _updater) external {
        require(msg.sender == owner, "Only owner");
        updater = _updater;
    }

    // Owner Token Withdraw    
    // Only owner can withdraw token 
    function withdrawToken(address tokenAddress, address to, uint amount) external {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        TRC20 _token = TRC20(tokenAddress);
        _token.transfer(to, amount);
    }
    
    // Owner TRX Withdraw
    // Only owner can withdraw TRX from contract
    function withdrawTRX(address payable to, uint amount) external {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        to.transfer(amount);
    }
    
    // Ownership Transfer
    // Only owner can call this function
    function transferOwnership(address to) external {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot transfer ownership to zero address");
        owner = to;
        emit OwnershipTransferred(to);
    }

    // TRX Price Update
    // Only owner can call this function
    // 1 TRX = 21.22 usd then send 2122
    function trxpriceChange(uint usdPrice) external {
        require(msg.sender == owner, "Only owner");
        priceOfTRX = usdPrice;
    }


    function usd_price() public view returns (uint) {
        return priceOfTRX;
    }

    function tokenInTRX(uint amount) public view returns (uint) {
        
        uint tokenVal = (amount * priceOfTRX *currrentTokenPriceDecimal) / (1000*currentTokenPrice);
        
        return tokenVal;
    }


}