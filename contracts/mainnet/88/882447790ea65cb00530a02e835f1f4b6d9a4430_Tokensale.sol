pragma solidity ^0.4.19;



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


// We need this interface to interact with out ERC20 - tokencontract
contract ERC20Interface {
         // function totalSupply() public constant returns (uint256);
      function balanceOf(address tokenOwner) public constant returns (uint256 balance);
         // function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
      function transfer(address to, uint256 tokens) public returns (bool success);
         // function approve(address spender, uint256 tokens) public returns (bool success);
         // function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
         // event Transfer(address indexed from, address indexed to, uint256 tokens);
         // event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
 } 


// ---
// Main tokensale class
//
contract Tokensale
{
using SafeMath for uint256;

address public owner;                  // Owner of this contract, may withdraw ETH and kill this contract
address public thisAddress;            // Address of this contract
string  public lastaction;             // 
uint256 public constant RATE = 1000;   // 1 ETH = 1000 Rentarto Coin
uint256 public raisedAmount     = 0;   // Raised amount in ETH
uint256 public available_tokens = 0;   // Last number of available_tokens BEFORE last payment

uint256 public lasttokencount;         // Last ordered token
bool    public last_transfer_state;    // Last state (bool) of token transfer



// ---
// Construktor
// 
function Tokensale () public
{
owner       = msg.sender;
thisAddress = address(this);
} // Construktor


 
 



// ---
// Pay ether to this contract and receive your tokens
//
function () payable public
{
address tokenAddress = 0x7C0924eEA284EF4B7A1b0Fefdd0d808Fc717377E;
ERC20Interface atoContract = ERC20Interface(tokenAddress); // Rentarto Coin is 0x7C0924eEA284EF4B7A1b0Fefdd0d808Fc717377E


//
// Minimum = 0.00125 ETH
//
if ( msg.value >= 1250000000000000 )
   {
   // Calculate tokens to sell
   uint256 weiAmount = msg.value;
   uint256 tokens = weiAmount.mul(RATE);
    
   // Our current token balance
   available_tokens = atoContract.balanceOf(thisAddress);    
    
   
   if (available_tokens >= tokens)
      {      
      
      	  lasttokencount = tokens;   
      	  raisedAmount   = raisedAmount.add(msg.value);
   
          // Send tokens to buyer
          last_transfer_state = atoContract.transfer(msg.sender,  tokens);
          
          
      } // if (available_tokens >= tokens)
      else
          {
          revert();
          }
   
   
   
   } // if ( msg.value >= 1250000000000000 )
   else
       {
       revert();
       }





} // ()
 



//
// owner_withdraw - Ether withdraw (owner only)
//
function owner_withdraw () public
{
if (msg.sender != owner) return;

owner.transfer( this.balance );
lastaction = "Withdraw";  
} // owner_withdraw



//
// Kill (owner only)
//
function kill () public
{
if (msg.sender != owner) return;


// Transfer tokens back to owner
address tokenAddress = 0x7C0924eEA284EF4B7A1b0Fefdd0d808Fc717377E;
ERC20Interface atoContract = ERC20Interface(tokenAddress); // rentarto is 0x7C0924eEA284EF4B7A1b0Fefdd0d808Fc717377E

uint256 balance = atoContract.balanceOf(this);
assert(balance > 0);
atoContract.transfer(owner, balance);


owner.transfer( this.balance );
selfdestruct(owner);
} // kill


} /* contract Tokensale */