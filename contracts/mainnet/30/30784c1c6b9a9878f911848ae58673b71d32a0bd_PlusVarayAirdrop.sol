pragma solidity 0.6.8;

library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two unsigned integers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint value) external  returns (bool success);
}

contract PlusVarayAirdrop {
  using SafeMath for uint256;

  uint256 public totalSold;
  ERC20 public Token;
  address payable public owner;
  uint256 public collectedETH;
  uint256 public startDate;
  bool private presaleClosed = false;

  constructor(address _wallet) public {
    owner = msg.sender;
    Token = ERC20(_wallet);
  }

  uint256 amount;
 
  // Converts ETH to Tokens and sends new Tokens to the sender
  receive () external payable {
    require(startDate > 0 && now.sub(startDate) <= 7 days);
    require(Token.balanceOf(address(this)) > 0);
    require(msg.value >= 0.00493 ether && msg.value <= 0.00494 ether);
    require(!presaleClosed);
     
    if (now.sub(startDate) <= 1 days) {
       amount = msg.value.mul(202839757).div(1000000);
    } else if(now.sub(startDate) > 1 days) {
       amount = msg.value.mul(202839757).div(1000000);
    }

    
    require(amount <= Token.balanceOf(address(this)));
    // update constants.
    totalSold = totalSold.add(amount);
    collectedETH = collectedETH.add(msg.value);
    // transfer the tokens.
    Token.transfer(msg.sender, amount);
  }

  // Converts ETH to Tokens 1and sends new Tokens to the sender
  function contribute() external payable {
    require(startDate > 0 && now.sub(startDate) <= 30 seconds);
    require(Token.balanceOf(address(this)) > 0);
    require(msg.value >= 0.00493 ether && msg.value <= 0.00494 ether);
    require(!presaleClosed);

    if (now.sub(startDate) <= 1 days) {
       amount = msg.value.mul(202839757).div(1000000);
    } else if(now.sub(startDate) > 1 days) {
       amount = msg.value.mul(202839757).div(1000000);
    }
        
    require(amount <= Token.balanceOf(address(this)));
    // update constants.
    totalSold = totalSold.add(amount);
    collectedETH = collectedETH.add(msg.value);
    // transfer the tokens.
    Token.transfer(msg.sender, amount);
  }

  // Only the contract owner can call this function
  function withdrawETH() public {
    require(msg.sender == owner && address(this).balance > 0);
    require(presaleClosed == true);
    owner.transfer(collectedETH);
  }

  function endPresale() public {
    require(msg.sender == owner);
    presaleClosed = true;
  }

  // Only the contract owner can call this function
  function burn() public {
    require(msg.sender == owner && Token.balanceOf(address(this)) > 0 && now.sub(startDate) > 7 days);
    // burn the left over.
    Token.transfer(address(0), Token.balanceOf(address(this)));
  }
  
  // Starts the sale
  // Only the contract owner can call this function
  function startSale() public {
    require(msg.sender == owner && startDate==0);
    startDate=now;
  }
  
  // Function to query the supply of Tokens in the contract
  function availableTokens() public view returns(uint256) {
    return Token.balanceOf(address(this));
    
  }
}