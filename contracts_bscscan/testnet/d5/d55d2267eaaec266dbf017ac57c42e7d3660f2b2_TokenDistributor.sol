/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

pragma solidity ^0.4.25;

interface Token {
  function transfer(address _to, uint256 _value) external returns (bool);
}

contract onlyOwner {
  address public owner;
  /** 
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() public {
    owner = msg.sender;
  }
  modifier isOwner {
    require(msg.sender == owner);
    _;
  }
}

contract TokenDistributor is onlyOwner{

  Token token;
  event TransferredToken(address indexed to, uint256 value);
  address distTokens;
  uint256 decimal;

  constructor(address _contract, uint256 _tokenDecimal) public{
      distTokens = _contract;
      decimal = _tokenDecimal;
      token = Token(_contract);
  }
  
  function setTokenContract(address _contract, uint256 _tokenDecimal) isOwner public{
      distTokens = _contract;
      decimal = _tokenDecimal;
      token = Token(_contract);
  } 
  
  function getTokenContract() public view returns(address){
      return distTokens;
  }
  function sendAmount(address[] _user, uint256 value) isOwner public returns(bool){
	for(uint i=0; i< _user.length; i++)
    token.transfer(_user[i], value*10**decimal);
    return true;
  }
 
}