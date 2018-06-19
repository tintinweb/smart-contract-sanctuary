pragma solidity ^0.4.18;

library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract LowRiskBag {
  using SafeMath for uint256;

  address contractOwner;
  uint tokenStartPrice = 0.001 ether;
  uint tokenPrice;
  address tokenOwner;
  uint lastBuyBlock;
  uint newRoundDelay = 40;
  event Transfer(address indexed from, address indexed to, uint256 price);
  event NewRound();
    

  function LowRiskBag() public {
    contractOwner = msg.sender;
    tokenOwner = address(0);
    lastBuyBlock = block.number; 
    tokenPrice = tokenStartPrice;
  }

  function changeContractOwner(address newOwner) public {
    require(contractOwner == msg.sender);
    contractOwner = newOwner;
  }
  function changeStartPrice(uint price) public {
    require(contractOwner == msg.sender);
    tokenStartPrice = price;
  }
    
  function changeNewRoundDelay(uint delay) public {
    require(contractOwner == msg.sender);
    newRoundDelay = delay;
  }
  
  function buyToken() public payable {
    address currentOwner = tokenOwner;
    uint256 currentPrice = tokenPrice;

    require(currentOwner != msg.sender);
    require(msg.value >= currentPrice);
    require(currentPrice > 0);

    uint256 paidTooMuch = msg.value.sub(currentPrice);
    uint256 payment = currentPrice.div(2);
    
    tokenPrice = currentPrice.mul(110).div(50);
    tokenOwner = msg.sender;
    lastBuyBlock = block.number;

    Transfer(currentOwner, msg.sender, currentPrice);
    if (currentOwner != address(0))
      currentOwner.transfer(payment);
    if (paidTooMuch > 0)
      msg.sender.transfer(paidTooMuch);
  }

  function getBlocksToNextRound() public view returns(uint) {
    if (lastBuyBlock + newRoundDelay < block.number)
      return 0;
    return lastBuyBlock + newRoundDelay + 1 - block.number;
  }

  function getCurrentData() public view returns (uint price, uint nextPrice, uint pool, uint nextPool, address owner, bool canFinish) {
    owner = tokenOwner;
    pool = tokenPrice.mul(50).div(110).mul(85).div(100);
    nextPool = tokenPrice.mul(85).div(100);
    price = tokenPrice;
    nextPrice = price.mul(110).div(50);
    if (getBlocksToNextRound() == 0)
      canFinish = true;
    else
      canFinish = false;
  }

  function finishRound() public {
    require(tokenPrice > tokenStartPrice);
    require(tokenOwner == msg.sender || lastBuyBlock + newRoundDelay < block.number);
    lastBuyBlock = block.number;
    uint payout = tokenPrice.mul(50).div(110).mul(85).div(100); // 85% of last paid price
    address owner = tokenOwner;
    tokenPrice = tokenStartPrice;
    tokenOwner = address(0);
    owner.transfer(payout);
    NewRound();
  }

  function payout(uint amount) public {
    require(contractOwner == msg.sender);
    uint balance = this.balance;
    if (tokenPrice > tokenStartPrice)
      balance -= tokenPrice.mul(50).div(110).mul(85).div(100); // payout for tokenOwner cant be paid out from contract owner
    if (amount>balance)
      amount = balance;
    contractOwner.transfer(amount);
  }
  
  function getBalance() public view returns(uint balance) {
    balance = this.balance;
    if (tokenPrice > tokenStartPrice)
      balance -= tokenPrice.mul(50).div(110).mul(85).div(100); // payout for tokenOwner cant be paid out from contract owner
      
  }
}