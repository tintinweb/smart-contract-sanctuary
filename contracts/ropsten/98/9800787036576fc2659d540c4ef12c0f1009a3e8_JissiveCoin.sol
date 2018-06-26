pragma solidity ^0.4.24;

/**
* @title JissiveMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
  
  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

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
    uint256 c = a / b;
    return c;
  }
}

contract JissiveCoin {
  using SafeMath for uint;
  address public owner; // This is owner eth address for contract transaction
  string public constant symbol = &quot;JSC&quot;; // This is token symbol
  string public constant name = &quot;jissive Coin&quot;; // this is token name
  uint8 public constant decimals = 18; // decimal digit for token price calculation.
  uint256 public totalSupply = 0;
  uint256 public maxSupply = 95000000; // This is max supply amount for token
  uint256 public rate = 10 ** 15 wei; // This is token rate in terms of wei(eather&#39;s smallest unit).

 // Timestamps for different dates for pre sale.
  uint256 private startDate = 1529504078;
  uint256 private endDate = 1532096078;

  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;

  //  Modifier to validate owner of the contract
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  event Transfer(address indexed from, address indexed _to, uint256 _value);
  event Approval(address indexed owner, address indexed _spender, uint256 _value);

  constructor() public{
    owner = msg.sender;
    balances[owner] = 5000000;
  }

  //  Function for finding total sold token 
  function totalTokenSold() public constant returns (uint256 balance) {
      return totalSupply;
  }

  //  Function for finding balance token from max supply
  function balanceMaxSupply() public constant returns (uint256 balance) {
      return maxSupply;
  }
  
  function balanceOf(address who) public constant returns (uint256) {
      return balances[who];
  }

  function balanceEth(address _owner) public constant returns (uint256 balance) {
      return _owner.balance;
  }

  //  Function for collect amount from contract to owner address
  function collect(uint256 amount) onlyOwner public{
    msg.sender.transfer(amount);
  }

	//  Function for validating the pre sale period
  function inPreSalePeriod() public constant returns (bool) {
      if (now >= startDate && now < endDate) {
          return true;
      } else {
          return false;
      }
  }

	//  Function for changing the startDate of pre-sale
	function changeStartDate(uint256 startDateTimeStamp) onlyOwner public {
		require( startDateTimeStamp < endDate );
		startDate = startDateTimeStamp;
	}

	//  Function for changing the endDate of pre-sale
	function changeEndDate(uint256 endDateTimeStamp) onlyOwner public {
		require( endDateTimeStamp > startDate );
		endDate = endDateTimeStamp;
	}

	//  Function for changing the rate of token
  function changeRate(uint256 newRate) onlyOwner public {
		rate = newRate;
  }

  //  Function for purchase the token from the contract to another address
  function create(address beneficiary) payable public{
    require(beneficiary != address(0));
    require(inPreSalePeriod());

    uint256 amount = msg.value;
    uint256 tokens = amount/rate;
    require(tokens <= maxSupply);

    if(amount > 0){
      balances[beneficiary] = balances[beneficiary].add(tokens);
      totalSupply = totalSupply.add(tokens);
      maxSupply = maxSupply.sub(tokens);
    }
  }

  //  Function for transfer the token from the contract to another address
  function transfer(address to, uint256 tokens) onlyOwner public returns (bool) {
    if(tokens > 0){
        balances[to] = balances[to].add(tokens);
        totalSupply = totalSupply.add(tokens);
        maxSupply = maxSupply.sub(tokens);
    }
    emit Transfer(msg.sender, to, tokens);
    return true;
  }

}