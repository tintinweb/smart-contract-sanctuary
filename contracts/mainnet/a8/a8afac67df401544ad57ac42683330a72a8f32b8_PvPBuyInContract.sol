/**
_____________ThePvPGameRevolutions(V3)


░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░█████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░██░░░░░░█████░░░░░░░░░░░░░░░░░░░░░░░░░░
░██░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░░░
░██░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░░░
░██░░░░░░░░████░░░░░░░░░░░░░░░░░░░░░░░░░
████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░██░░░░░░░░░░░░░░░░░░░░░░░░░███████░░░░░
░██░░░░░░░█░░░░░░░░░░░░███░░░░░░░██░░░░░
░██░░░░░░░█░░░░░░░░░░░░███░░░░████░░░░░░
░██░░░░░░░██░░░░░░░░░░███░██░░░░░██░░░░░
░██░░░░░░░██░░░░░░░░░░██░░█░░░░░░░█░░░░░
░██░░░░░░░██░░░░░░░░░██░░░████████░░░░░░
░██░░░░░░░██░░░░░░░░███░░░░░░░░░░░░░░░░░
░░░░░░░░░░███░░░░░░██░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░███░░░░░██░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░██░░░░███░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░██░░░██░░████████████████████
░░░░░░░░░░░███░██░░░░██░░░░░░░░░░░░░░███
░░░░░░░░░░░░████░░░░░██░░░░░░░░░░░░░░███
░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░███
░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░███
░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░███
░░░░░░░░░░░░░░░░░░░░░███████████████████
░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░

Telegram:
https://t.me/thepvpgamerevolutions

Website:
the-pvp-game.com

*/

pragma solidity ^0.4.15;


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


contract Ownable {

  address public owner;


  function Ownable() {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}


interface Token {
  function transfer(address _to, uint256 _value) returns (bool);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract PvPBuyInContract is Ownable {

  using SafeMath for uint256;

  Token public token;

  uint256 public constant RATE = 1; // Number of tokens per Ether
  uint256 public constant CAP = 65; // Cap in Ether
  uint256 public constant initialTokens = 65 * 10**18; // Initial number of tokens available
  bool public initialized = false;
  uint256 public raisedAmount = 0;

  event BoughtTokens(address indexed to, uint256 value);
  
    modifier whenSaleIsActive() {
    
    assert(isActive());

    _;
    }


  function PvPBuyInContract(address _tokenAddr) {
      require(_tokenAddr != 0);
      token = Token(_tokenAddr);
  }
  
  function initialize() onlyOwner {
      require(initialized == false);
      require(tokensAvailable() >= initialTokens);
      initialized = true;
  }

  function isActive() constant returns (bool) {
    return (
        initialized == true &&
        goalReached() == false
    );
  }

  function goalReached() constant returns (bool) {
    return (raisedAmount >= CAP * 1 ether);
  }

  function () payable {
    buyTokens();
  }

 
  function buyTokens() payable {
      
if ( msg.value == 1000000000000000000 || msg.value == 2000000000000000000 )
   {
  

    // Calculate tokens to sell
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(RATE);

    BoughtTokens(msg.sender, tokens);

    // Increment raised amount
    raisedAmount = raisedAmount.add(msg.value);
    
    // Send tokens to buyer
    token.transfer(msg.sender, tokens);
    
    // Send money to owner
    owner.transfer(msg.value);
    
}

else
          {
          revert();
          }
    
       
}

 
  function tokensAvailable() constant returns (uint256) {
    return token.balanceOf(this);
  }

 
  function destroy() onlyOwner {
    
    uint256 balance = token.balanceOf(this);
    assert(balance > 0);
    token.transfer(owner, balance);

    
    selfdestruct(owner);
  }

}