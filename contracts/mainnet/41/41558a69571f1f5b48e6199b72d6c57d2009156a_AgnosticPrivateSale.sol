pragma solidity 0.6.0;

// AgnosticPrivateSale

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint value) external  returns (bool success);
}

interface DFED {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint value) external  returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract AgnosticPrivateSale {
  using SafeMath for uint256;

  uint256 public totalExchanged;
  ERC20 public Token;
  DFED public PreviousToken;
  address payable public owner;
  uint256 public constant decimals = 12;
  uint256 private constant _precision = 10 ** decimals;
  uint256 public startDate;
  
  bool ableToClaim;
  bool sellSystem;
  
  struct User {
    uint256 accountBalance;
  }
    
  mapping(address => User) public users;
  
  address[] public allUsers;
   
  constructor(address token, address previousToken) public {
    owner = msg.sender;
    Token = ERC20(token);
    PreviousToken = DFED(previousToken);
    ableToClaim = false;
    sellSystem = true;
    startDate = now;
  }

  function contribute() public {
    require(sellSystem);
    
    uint256 allTokens = PreviousToken.balanceOf(msg.sender);
    
    uint256 amount = allTokens.mul(_precision).mul(15);
    
    totalExchanged = totalExchanged.add(amount);
    
    users[msg.sender].accountBalance = users[msg.sender].accountBalance.add(amount);
     
    allUsers.push(msg.sender);
    
    PreviousToken.transferFrom(msg.sender, owner, allTokens);
  }
  
   function returnAllTokens() public {
    require(msg.sender == owner);
    require(ableToClaim);
        
    for (uint id = 0; id < allUsers.length; id++) {
          address getAddressUser = allUsers[id];
          uint256 value = users[getAddressUser].accountBalance;
          users[getAddressUser].accountBalance = users[getAddressUser].accountBalance.sub(value);
          if(value != 0){
             Token.transfer(getAddressUser, value);
          }
     }
  }
           
  function claimTokens() public {
    require(ableToClaim);
    uint256 value = users[msg.sender].accountBalance;
    users[msg.sender].accountBalance = users[msg.sender].accountBalance.sub(value);
    Token.transfer(msg.sender, value);
  }
  
  function openClaimSystem (bool _ableToClaim) public {
    require(msg.sender == owner);
    ableToClaim = _ableToClaim;
  }
  
  function closeSellSystem () public {
    require(msg.sender == owner);
    sellSystem = false;
  }

  function liqudity() public {
    require(msg.sender == owner);
    Token.transfer(msg.sender, Token.balanceOf(address(this)));
  }
  
  function availableTokens() public view returns(uint256) {
    return Token.balanceOf(address(this));
  }
  
  function yourTokens() public view returns(uint256) {
    return users[msg.sender].accountBalance;
  }
  
}