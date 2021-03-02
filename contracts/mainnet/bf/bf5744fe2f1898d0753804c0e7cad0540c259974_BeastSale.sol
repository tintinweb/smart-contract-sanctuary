/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;


// Welcome to the official token sale for Wall Street Dogs - https://wallstreetdogs.xyz
// Certified, KYC'd, and powered by Beast DAO - https://beast.finance


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

contract BeastSale {
  using SafeMath for uint256;

  uint256 public totalSold;
  ERC20 public Token;
  address payable public owner;
  uint256 public collectedETH;
  uint256 public startDate;
  bool private saleClosed = false;

  constructor(address _wallet) public {
    owner = msg.sender;
    Token = ERC20(_wallet);
  }

  uint256 amount;
 

  receive () external payable {
    require(startDate > 0 && now.sub(startDate) <= 8 days);
    require(Token.balanceOf(address(this)) > 0);
    require(msg.value >= 0.01 ether && msg.value <= 100 ether);
    require(!saleClosed);
     
    //WSDG token sale amount
       amount = msg.value.mul(5000);

    
    require(amount <= Token.balanceOf(address(this)));
    totalSold = totalSold.add(amount);
    collectedETH = collectedETH.add(msg.value);
    // Transfer the BeastDAO tokens
    Token.transfer(msg.sender, amount);
  }


  function support() external payable {
    require(startDate > 0 && now.sub(startDate) <= 8 days);
    require(Token.balanceOf(address(this)) > 0);
    require(msg.value >= 0.01 ether && msg.value <= 100 ether);
    require(!saleClosed);
    
  amount = msg.value.mul(5000);
    
    require(amount <= Token.balanceOf(address(this)));
  
    totalSold = totalSold.add(amount);
    collectedETH = collectedETH.add(msg.value);
    Token.transfer(msg.sender, amount);
  }


  function withdrawETH() public {
      //Withdraw ETH to add UniSwap Liquidity
    require(msg.sender == owner);
    require(saleClosed == true);
    owner.transfer(collectedETH);
  }

 function withdrawTokens() public {
    require(msg.sender == owner);
    require(saleClosed == true);
    // Returns the tokens incase of emergency
    Token.transfer(address(msg.sender), Token.balanceOf(address(this)));
  }

  function closeBeastSale() public {
      //End the BeastDAO sale
    require(msg.sender == owner);
    saleClosed = true;
  }

  function burnTokens() public {
    require(msg.sender == owner && Token.balanceOf(address(this)) > 0 && now.sub(startDate) > 7 days);
    // Burn the left over BEAST tokens after the sale is complete
    Token.transfer(address(0), Token.balanceOf(address(this)));
  }
  
  
  function startBeastSale() public {
      //Start the BeastDAO token sale
    require(msg.sender == owner && startDate==0);
    startDate=now;
  }
  
  function availableTokens() public view returns(uint256) {
    return Token.balanceOf(address(this));
  }
}