pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
// &#39;AAA&#39; Smart Contract for Tokens
//
// Deployed to: 0x1
// Symbol: AAA
// Name: BAKKET
// Total supply: 100 000 000
// Decimals: 18
// Functions: Minting for future liquidity increase / SafeMath / BasicERC20
//
// (c) DEMO COP
// ----------------------------------------------------------------------------

library SafeMath {

	  /**
	  * @dev Multiplies two numbers, throws on overflow.
	  */
  
	  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
	    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
	    // benefit is lost if &#39;b&#39; is also tested.
	    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

contract BaseERC20Token {
    
    using SafeMath for uint256;
    mapping (address => uint256) public balanceOf;
  
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor (
        uint256 _totalSupply,
        uint8 _decimals,
        string _name,
        string _symbol
    )
        public
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}
contract MintableToken is BaseERC20Token, Ownable {
    address public owner = msg.sender;

    constructor(
        uint256 _totalSupply,
        uint8 _decimals,
        string _name,
        string _symbol
    ) BaseERC20Token(_totalSupply, _decimals, _name, _symbol) public
    {
    }

    function mint(address recipient, uint256 amount) public {
        require(msg.sender == owner);
        require(totalSupply + amount >= totalSupply); // Overflow check

        totalSupply += amount;
        balanceOf[recipient] += amount;
        emit Transfer(address(0), recipient, amount);
    }

    function burn(uint256 amount) public {
        require(amount <= balanceOf[msg.sender]);

        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function burnFrom(address from, uint256 amount) public {
        require(amount <= balanceOf[from]);
        require(amount <= allowance[from][msg.sender]);

        totalSupply -= amount;
        balanceOf[from] -= amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, address(0), amount);
    }
}