//SourceUnit: PresaleDMH.sol

pragma solidity ^0.5.8;

library SafeMath {

	/**
	* @dev Returns the lowest value of the two integers
	*/
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
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
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

	function percentageOf(uint256 total, uint256 percentage) internal pure returns (uint256) {
		return div(mul(total, percentage), 100);
	}

	function getPercentage(uint256 total, uint256 piece) internal pure returns (uint256) {
		return div(piece, total);
	}
}

interface DMHToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
}

contract PresaleDMH {
  DMHToken public token;
  address payable public ceoAddress;
  uint256 public tokenPrice = 0;
  uint256 public multiplier = 10 * 1e17;
  uint256 public buyLimit = 0;

  mapping (address => uint256) public boughtTokens;

  event Buy (uint256 amount, uint256 tokens);

  constructor (address _token) public {
    token = DMHToken(_token);
    ceoAddress = msg.sender;
    buyLimit = SafeMath.mul(500, multiplier);
    tokenPrice = 500 * 1e6;
  }

  modifier ceoOnly {
    require(msg.sender == ceoAddress, "Unauthorized");
    _;
  }

  function withdraw (uint256 amount) external ceoOnly {
    require(amount <= address(this).balance, "Insufficient funds");

    msg.sender.transfer(amount);
  }

  function withdrawDMH (uint256 amount) external ceoOnly {
    require(amount <= token.balanceOf(address(this)), "Insufficient funds");

    token.transfer(msg.sender, amount);
  }

  function getTokenBalance () external view returns (uint256) {
    return token.balanceOf(address(this));
  }

  function setTokenPrice (uint256 price) external ceoOnly {
    require(price >= 0, "Invalid price");

    tokenPrice = price;
  }

  function setBuyLimit (uint256 limit) external ceoOnly {
    require(limit >= 0, "Invalid limit");

    buyLimit = SafeMath.mul(limit, multiplier);
  }

  function calculateBuy (uint256 amount) public view returns (uint256) {
    if (tokenPrice <= 0 || amount <= 0) {
      return 0;
    }
    uint256 value = SafeMath.mul(amount, multiplier);
    if (value < tokenPrice) {
      return 0;
    }
    return SafeMath.div(value, tokenPrice);
  }

  function buy () external payable {
    require(tokenPrice > 0, "Token price is zero");
    require(msg.value > 0, "Invalid amount");

    uint256 tokens = calculateBuy(msg.value);
    uint256 newBoughtTokens = SafeMath.add(tokens, boughtTokens[msg.sender]);

    assert(tokens > 0);
    assert(newBoughtTokens <= buyLimit);

    boughtTokens[msg.sender] = newBoughtTokens;
    token.transfer(msg.sender, tokens);

    emit Buy(msg.value, tokens);
  }
}