pragma solidity ^0.4.16;
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

contract AirCenter is Ownable {
  using SafeMath for uint256;

  address public airdroptoken;
  uint256 public decimals;
  AirdropToken internal token;
  AirdropToken internal tmptoken;

  event TransferredToken(address indexed to, uint256 value);
  event FailedTransfer(address indexed to, uint256 value);

  modifier whenDropIsActive() {
    assert(isActive());
    _;
  }

  constructor() public {
    // initial token
    airdroptoken = 0x962b9E77c46fe6285014582a04D336bb139db1b7;
    token = AirdropToken(airdroptoken);
    tmptoken = AirdropToken(airdroptoken);
    decimals = getDecimals();
  }

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

  function retrieveToken(address tokenaddress) public onlyOwner{
    tmptoken = AirdropToken(tokenaddress);
    uint256 balance = tmptoken.balanceOf(this);
    require (balance > 0);
    tmptoken.transfer(owner,balance);
  }

  function destroy() public onlyOwner {
    uint256 balance = tokensAvailable();
    require (balance > 0);
    token.transfer(owner, balance);
    selfdestruct(owner);
  }
}