pragma solidity ^0.4.21;
// import &#39;./bonbon.sol&#39;;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface AirdropToken {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _owner) constant external returns (uint256);
  function decimals() constant external returns (uint256);
}

contract ICOAirCenter is Ownable {
  using SafeMath for uint256;

  address public airdroptoken;
  uint256 public decimals;
  uint256 public rate;
  uint256 public weiRaised;
  AirdropToken internal token;
  AirdropToken internal tmptoken;
  AirdropToken internal icotoken;

  event TransferredToken(address indexed to, uint256 value);
  event FailedTransfer(address indexed to, uint256 value);
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  modifier whenDropIsActive() {
    assert(isActive());
    _;
  }

  constructor() public {
    // initial token
    airdroptoken = 0x6EA3bA628a73D22E924924dF3661843e53e5c3AA;
    token = AirdropToken(airdroptoken);
    tmptoken = AirdropToken(airdroptoken);
    icotoken = AirdropToken(airdroptoken);
    decimals = getDecimals();
    rate = 10000; // 1 eth for 10000 bbt
  }

  function () external payable{
    getTokens(msg.sender);
  }

  function getTokens(address _beneficiary) public payable{
    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);
    uint256 tokens = _getTokenAmount(weiAmount);
    uint256 tokenbalance = icotoken.balanceOf(this);
    require(tokenbalance >= tokens);
    weiRaised = weiRaised.add(weiAmount);
    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(msg.sender,_beneficiary,weiAmount,tokens);
    _updatePurchasingState(_beneficiary, weiAmount);
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // begin buy token related functions 
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure {
    // optional override
  }

  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    icotoken.transfer(_beneficiary, _tokenAmount);
  }

  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal pure{
    // optional override
  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

  // end

  function isActive() public constant returns (bool) {
    return (
      tokensAvailable() > 0 // Tokens must be available to send
      );
  }

  function getDecimals() public constant returns (uint256){
    return token.decimals();
  }


  function setToken(address tokenaddress) onlyOwner external{
    require(tokenaddress != address(0));
    token = AirdropToken(tokenaddress);
    airdroptoken = tokenaddress;
    decimals = getDecimals();
  }

  //below function can be used when you want to send every recipeint with different number of tokens
  function sendTokens(address tokenaddress,address[] dests, uint256[] values) whenDropIsActive onlyOwner external {
    require(dests.length == values.length);
    require(tokenaddress == airdroptoken);
    uint256 i = 0;
    while (i < dests.length) {
      uint256 toSend = values[i].mul(10**decimals);
      sendInternally(dests[i] , toSend, values[i]);
      i++;
    }
  }

  // this function can be used when you want to send same number of tokens to all the recipients
  function sendTokensSingleValue(address tokenaddress,address[] dests, uint256 value) whenDropIsActive onlyOwner external {
    require(tokenaddress == airdroptoken);
    
    uint256 i = 0;
    uint256 toSend = value.mul(10**decimals);
    while (i < dests.length) {
      sendInternally(dests[i] , toSend, value);
      i++;
    }
  }  

  function sendInternally(address recipient, uint256 tokensToSend, uint256 valueToPresent) internal {
    if(recipient == address(0)) return;

    if(tokensAvailable() >= tokensToSend) {
      token.transfer(recipient, tokensToSend);
      emit TransferredToken(recipient, valueToPresent);
    }else {
        emit FailedTransfer(recipient, valueToPresent);
    }
  }

  function tokensAvailable() public constant returns (uint256) {
    return token.balanceOf(this);
  }

  // fund retrieval related functions
  function retrieveToken(address tokenaddress) public onlyOwner{
    tmptoken = AirdropToken(tokenaddress);
    uint256 balance = tmptoken.balanceOf(this);
    require (balance > 0);
    tmptoken.transfer(owner,balance);
  }

  function retrieveEth(uint256 value) public onlyOwner{
    uint256 ethamount = value.mul(10**18);
    uint256 balance = address(this).balance;
    require (balance > 0 && ethamount<= balance);
    owner.transfer(ethamount);
  }

  function destroy() public onlyOwner {
    uint256 balance = tokensAvailable();
    require (balance > 0);
    token.transfer(owner, balance);
    selfdestruct(owner);
  }
}