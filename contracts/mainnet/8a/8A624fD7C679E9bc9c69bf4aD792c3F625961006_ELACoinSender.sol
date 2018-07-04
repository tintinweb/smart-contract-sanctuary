pragma solidity ^0.4.21;

contract Ownable {

  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public{
    require(newOwner != address(0));
    owner = newOwner;
  }
}


interface Token {
  function transfer(address _to, uint256 _value) external returns  (bool);
  function balanceOf(address _owner) external constant returns (uint256 balance);
}

contract ELACoinSender is Ownable {

  Token token;

  event TransferredToken(address indexed to, uint256 value);
  event FailedTransfer(address indexed to, uint256 value);

  modifier whenDropIsActive() {
    assert(isActive());

    _;
  }

  function Multisend () public {
      address _tokenAddr = 0xFaF378DD7C26EBcFAe80f4675faDB3F9d9DFC152; //here pass address of your token
      token = Token(_tokenAddr);
  }

  function isActive() constant public returns (bool) {
    return (
        tokensAvailable() > 0 // Tokens must be available to send
    );
  }
//below function can be used when you want to send every recipeint with different number of tokens
// change the uint256 tosend = value  * “10**18”; to adjust the decimal points
  function sendTokens(address[] dests, uint256[] values) whenDropIsActive onlyOwner external {
    uint256 i = 0;
    while (i < dests.length) {
        uint256 toSend = values[i]; //here set if you want to send in whole number leave as is or delete the 10**18 to send in 18 decimals
        sendInternally(dests[i] , toSend, values[i]);
        i++;
    }
  }

// this function can be used when you want to send same number of tokens to all the recipients
// change the uint256 tosend = value  * “10**18”; to adjust the decimal points
  function sendTokensSingleValue(address[] dests, uint256 value) whenDropIsActive onlyOwner external {
    uint256 i = 0;
    uint256 toSend = value;  //here set if you want to send in whole number leave as is or delete the 10**18 to send in 18 decimals
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
    } else {
      emit FailedTransfer(recipient, valueToPresent); 
    }
  }   


  function tokensAvailable() constant public returns (uint256) {
    return token.balanceOf(this);
  }

  function destroy() onlyOwner external {
    uint256 balance = tokensAvailable();
    require (balance > 0);
    token.transfer(owner, balance);
    selfdestruct(owner);
  }}