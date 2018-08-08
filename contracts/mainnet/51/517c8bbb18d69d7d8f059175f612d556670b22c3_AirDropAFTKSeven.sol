pragma solidity ^0.4.20;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;
  event OwnershipTransferred (address indexed _from, address indexed _to);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public{
    owner = msg.sender;
    OwnershipTransferred(address(0), owner);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
    OwnershipTransferred(owner,newOwner);
  }
}

/**
 * @title Token
 * @dev API interface for interacting with the Token contract 
 */
interface Token {
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
  function balanceOf(address _owner) constant external returns (uint256 balance);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool); 
}

/**
 * @title AirDropAFTKSeven Ver 1.0
 * @dev This contract can be used for Airdrop or token redumption for AFTK Token
 *
 */
contract AirDropAFTKSeven is Ownable {

  Token token;
  mapping(address => uint256) public redeemBalanceOf; 
  event BalanceSet(address indexed beneficiary, uint256 value);
  event Redeemed(address indexed beneficiary, uint256 value);
  event BalanceCleared(address indexed beneficiary, uint256 value);
  event TokenSendStart(address indexed beneficiary, uint256 value);
  event TransferredToken(address indexed to, uint256 value);
  event FailedTransfer(address indexed to, uint256 value);

  function AirDropAFTKSeven() public {
      address _tokenAddr = 0x7fa2f70bd4c4120fdd539ebd55c04118ba336b9e;
      token = Token(_tokenAddr);
  }

 /**
  * @dev Send approved tokens to one address
  * @param dests -> address where you want to send tokens
  * @param quantity -> number of tokens to send
  */
 function sendTokensToOne(address dests, uint256 quantity)  public payable onlyOwner returns (uint) {
    
	TokenSendStart(dests,quantity * 10**18);
	token.approve(dests, quantity * 10**18);
	require(token.transferFrom(owner , dests ,quantity * 10**18));
    return token.balanceOf(dests);
	
  }

 /**
  * @dev Send approved tokens to seven addresses
  * @param dests1 -> address where you want to send tokens
  * @param dests2 -> address where you want to send tokens
  * @param dests3 -> address where you want to send tokens
  * @param dests4 -> address where you want to send tokens
  * @param dests5 -> address where you want to send tokens
  * @param dests6 -> address where you want to send tokens
  * @param dests7 -> address where you want to send tokens
  * @param quantity -> number of tokens to send
  */
 function sendTokensTo7(address dests1, address dests2, address dests3, address dests4, address dests5, 
 address dests6, address dests7,  uint256 quantity)  public payable onlyOwner returns (uint) {
    
	TokenSendStart(dests1,quantity * 10**18);
	token.approve(dests1, quantity * 10**18);
	require(token.transferFrom(owner , dests1 ,quantity * 10**18));
	
	TokenSendStart(dests2,quantity * 10**18);
	token.approve(dests2, quantity * 10**18);
	require(token.transferFrom(owner , dests2 ,quantity * 10**18));
	
	TokenSendStart(dests3,quantity * 10**18);
	token.approve(dests3, quantity * 10**18);
	require(token.transferFrom(owner , dests3 ,quantity * 10**18));
	
	TokenSendStart(dests4,quantity * 10**18);
	token.approve(dests4, quantity * 10**18);
	require(token.transferFrom(owner , dests4 ,quantity * 10**18));
	
	TokenSendStart(dests5,quantity * 10**18);
	token.approve(dests5, quantity * 10**18);
	require(token.transferFrom(owner , dests5 ,quantity * 10**18));
	
	TokenSendStart(dests6,quantity * 10**18);
	token.approve(dests6, quantity * 10**18);
	require(token.transferFrom(owner , dests6 ,quantity * 10**18));
    
	TokenSendStart(dests7,quantity * 10**18);
	token.approve(dests7, quantity * 10**18);
	require(token.transferFrom(owner , dests7 ,quantity * 10**18));
	
	return token.balanceOf(dests7);
  }
  
 /**
  * @dev admin can destroy this contract
  */
  function destroy() onlyOwner public { uint256 tokensAvailable = token.balanceOf(this); require (tokensAvailable > 0); token.transfer(owner, tokensAvailable);  selfdestruct(owner);  } 
}