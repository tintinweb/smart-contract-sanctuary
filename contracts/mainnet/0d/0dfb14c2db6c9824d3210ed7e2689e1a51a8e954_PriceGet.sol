pragma solidity ^0.4.23;

contract Oasis{
    function getBestOffer(address sell_gem, address buy_gem) public constant returns(uint256);
    function getOffer(uint id) public constant returns (uint, address, uint, address);
}


contract PriceGet {
    using SafeMath for uint;
    
    
    Oasis market;
    address public marketAddress;
    address public dai = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    mapping( address => uint256 ) public locked;
    mapping( address => uint256 ) public tokenBalance;

    constructor(address addr) public {
        marketAddress = addr;
        market = Oasis(marketAddress);
    }
    
    
    function deposit() public payable {
        require(msg.value > 0.001 ether);
        locked[msg.sender] += msg.value;
    }
    
    
    function mint(uint256 amount) public {
        require(locked[msg.sender] > 0.001 ether);
        uint currentPrice = getPrice();
        uint tokens = SafeMath.div(amount*1e18, currentPrice);
        tokenBalance[msg.sender] = SafeMath.add(tokenBalance[msg.sender], tokens);
    }
    
    
    function burn(uint256 amount) public {
        require(amount <= tokenBalance[msg.sender]);
        tokenBalance[msg.sender] = SafeMath.sub(tokenBalance[msg.sender], amount);
    }
    
    
    function tokenValue(address user) public view returns(uint256) {
        require(tokenBalance[user] > 0);
        uint tokens = tokenBalance[user];
        uint currentPrice = getPrice();
        uint value = SafeMath.mul(tokens, currentPrice);
        return value;
    }
    
    
    function withdraw() public {
        require(tokenBalance[msg.sender] == 0);
        require(locked[msg.sender] > 0);
        uint payout = locked[msg.sender];
        locked[msg.sender] = 0;
        msg.sender.transfer(payout);
    }
    
    
    function getPrice() public view returns(uint256) {
        uint id = market.getBestOffer(weth,dai);
        uint payAmt;
        uint buyAmt;
        address payGem;
        address buyGem;
        (payAmt, payGem, buyAmt, buyGem) = market.getOffer(id);
        uint rate = SafeMath.div(buyAmt*1e18, payAmt);
        return rate;
    }
    
    
}






/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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