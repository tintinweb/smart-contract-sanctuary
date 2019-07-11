/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Ownable {
	event NewOwner(address indexed old, address indexed current);

	address public owner = msg.sender;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

  constructor () internal {
    owner = msg.sender;
  }

	function setOwner(address _new)
		external
		onlyOwner
	{
		emit NewOwner(owner, _new);
		owner = _new;
	}
}

/**
 * @title ERC20
 * @dev ERC20 token interface
 */
 contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
 }

contract Faucet is Ownable {
    using SafeMath for uint256;

    /* --- EVENTS --- */

    event TokenExchanged(address receiver, uint etherReceived, uint tokenSent);

    /* --- FIELDS / CONSTANTS --- */

    address public tokenAddress;
    uint16 public exchangeRate; // ETH -> token exchange rate
    uint public exchangeLimit; // Max amount of ether allowed to exchange

    /* --- PUBLIC/EXTERNAL FUNCTIONS --- */

    constructor(address _tokenAddress, uint16 _exchangeRate, uint _exchangeLimit) public {
        tokenAddress = _tokenAddress;
        exchangeRate = _exchangeRate;
        exchangeLimit = _exchangeLimit;
    }

    function() public payable {
        require(msg.value <= exchangeLimit);

        uint transferAmount = msg.value.mul(exchangeRate);
        require(ERC20(tokenAddress).transfer(msg.sender, transferAmount), "insufficient erc20 token balance");

        emit TokenExchanged(msg.sender, msg.value, transferAmount);
    }

    function withdrawEther(uint amount) onlyOwner public {
        owner.transfer(amount);
    }

    function withdrawToken(uint amount) onlyOwner public {
        ERC20(tokenAddress).transfer(owner, amount);
    }

    function getTokenBalance() public view returns (uint) {
        return ERC20(tokenAddress).balanceOf(this);
    }

    function getEtherBalance() public view returns (uint) {
        return address(this).balance;
    }

    function updateExchangeRate(uint16 newExchangeRate) onlyOwner public {
        exchangeRate = newExchangeRate;
    }

    function updateExchangeLimit(uint newExchangeLimit) onlyOwner public {
        exchangeLimit = newExchangeLimit;
    }
}