/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transfer_token(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract RSHIBAPresale  {
  using SafeMath for uint256;
  IERC20 public token;
  uint256 public rate;
  uint256 public weiRaised;
  uint256 public weiMaxPurchaseBnb;
  address payable private owner;
  uint256 public tokenSold;
  mapping(address => uint256) public purchasedBnb;
  event Purchase(address indexed buyer, address indexed referral, uint256 value, uint256 amount);
  event DirectReward(address indexed referral, uint256 token_gifted);
  
  constructor(uint256 _rate, IERC20 _token, uint256 _max) public {
    require(_rate > 0);
    require(_max > 0);
    require(_token != IERC20(address(0)));
    rate = _rate;
    token = _token;
    weiMaxPurchaseBnb = _max;
    owner = msg.sender;
  }
  
  fallback () external payable {
    revert();    
  }
  receive () external payable {
    revert();
  }
  
  function add_level_income(address referral, uint256 numberOfTokens) private returns(bool) {

    require(referral != address(0), "BEP20: Referral Address can't be Zero Address");
    uint256 referral_balance = token.balanceOf(referral);
    
    if( referral_balance > 100e9 ){ 
        uint256 commission = numberOfTokens * 4 / 100;
        _deliverTokens(referral, commission);
        tokenSold = tokenSold.add(commission);
        emit DirectReward(referral, commission);
     }
   }
     
  function buy_token(address _beneficiary, address _referral) public payable {
    require(msg.value >= 100000000000000000, "BEP20: Minimum buying is 0.1 BNB");
    uint256 maxBnbAmount = maxBnb(_beneficiary);
    uint256 weiAmount = msg.value > maxBnbAmount ? maxBnbAmount : msg.value;
    weiAmount = _preValidatePurchase(_beneficiary, weiAmount);
    uint256 tokens = _getTokenAmount(weiAmount);
    weiRaised = weiRaised.add(weiAmount);
    _processPurchase(_beneficiary, tokens);
    emit Purchase(msg.sender, _beneficiary, weiAmount, tokens);
    _updatePurchasingState(_beneficiary, weiAmount);
    if (msg.value > weiAmount) {
      uint256 refundAmount = msg.value.sub(weiAmount);
      msg.sender.transfer(refundAmount);
    }
    add_level_income(_referral, tokens);
  }
  
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) public view returns (uint256) {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    uint256 tokenAmount = _getTokenAmount(_weiAmount);
    uint256 curBalance = token.balanceOf(address(this));
    if (tokenAmount > curBalance) {
      return curBalance.mul(1e9).div(rate);
    }
    return _weiAmount;
  }
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer_token(_beneficiary, _tokenAmount);
  }
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    purchasedBnb[_beneficiary] = _weiAmount.add(purchasedBnb[_beneficiary]);    
  }
  function _updateRate(uint256 _newRate) external {
    require(owner == msg.sender, "not owner!");
    rate = _newRate;
  }
  function _getTokenAmount(uint256 _weiAmount) public view returns (uint256) {
    return _weiAmount.mul(1e9).div(rate);
  }
  function TransferFunds() external {
    require(owner == msg.sender, "not owner!");
    owner.transfer(address(this).balance);
  }
  function maxBnb(address _beneficiary) public view returns (uint256) {
    return weiMaxPurchaseBnb.sub(purchasedBnb[_beneficiary]);
  }
  function transferAnyERC20Token(address tokenAddress, uint256 tokens) external {
    require(owner == msg.sender, "not owner!");
    IERC20(tokenAddress).transfer(owner, tokens);
  }
}