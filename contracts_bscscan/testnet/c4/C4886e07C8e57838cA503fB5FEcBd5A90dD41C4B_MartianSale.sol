/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

//SPDX-Licence-Identifier: To The Mars (Martian)

pragma solidity ^0.5.0;

interface IERC20 {
    function balanceOf(address owner) external returns(address);
    function transfer(address to, uint256 value) external returns(bool);
    function decimals() external returns (uint256);
    function allowance(address owner, address spender)external view returns (uint256);
    function transferFrom(address from, address to, uint256 value)external returns (bool);
    function approve(address spender, uint256 value)external returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract MartianSale {
    using SafeMath for uint256;
    IERC20 public token;
    address public tokenWallet;
    uint256 public price = 25000;
    address owner;
    uint256 public tokenPurchased;
    
    event TokenPurchased(
    address indexed purchaser,
    uint256 value,
    uint256 amount
    );

    
    constructor (IERC20 _token, address _tokenWallet) public {
        require(_tokenWallet != address(0));
        
        owner = msg.sender;
        
        token = _token;
        tokenWallet = _tokenWallet;
       
    }
    
    function changePrice(uint256 _price) public returns(uint256) {
        require(msg.sender == owner, "Only owner can set Price");
        price = _price;
        return price;
    }
    
    function buy() public payable {
        require(msg.value != 0, "Amount cannot be 0");
       
        
        uint256 totalTokens = msg.value.mul(price);
        tokenPurchased = tokenPurchased.add(totalTokens);
        token.transferFrom(tokenWallet, msg.sender, totalTokens);
        emit TokenPurchased (
             msg.sender,
             price,
             totalTokens);
             
        forwardFunds();
        
    }
    
    function remainingTokens()view public returns(uint256) {
        return token.allowance(tokenWallet, address(this));
    }
    
    function forwardFunds() public returns(bool){
        require(msg.sender == owner, "Only owner can call this function");
        msg.sender.transfer(address(this).balance);
    }
    
     function approve()public returns (bool) {
         require(msg.sender == owner, "Only owner can call this function");
         IERC20(token).approve(address(this), 10000000*10*18);
     }
    
    
    
    
    
    
    
}