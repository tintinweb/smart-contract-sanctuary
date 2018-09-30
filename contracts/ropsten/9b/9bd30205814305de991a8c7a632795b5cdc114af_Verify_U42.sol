// Implementation of the U42 Token Specification -- see "U42 Token Specification.md"
//
// Standard ERC-20 methods and the SafeMath library are adapated from OpenZeppelin&#39;s standard contract types
// as at https://github.com/OpenZeppelin/openzeppelin-solidity/commit/5daaf60d11ee2075260d0f3adfb22b1c536db983
// note that uint256 is used explicitly in place of uint

pragma solidity ^0.4.24;

//safemath extensions added to uint256
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

contract Verify_U42 {
	//use OZ SafeMath to avoid uint256 overflows
	using SafeMath for uint256;

	string public constant name = "Verification token for U42 distribution";
	string public constant symbol = "VU42";
	uint8 public constant decimals = 18;
	uint256 public constant initialSupply = 525000000 * (10 ** uint256(decimals));
	uint256 internal totalSupply_ = initialSupply;
	address public contractOwner;

	//token balances
	mapping(address => uint256) balances;

	//for each balance address, map allowed addresses to amount allowed
	mapping (address => mapping (address => uint256)) internal allowed;

	//methods emit the following events (note that these are a subset 
	event Transfer (
		address indexed from, 
		address indexed to, 
		uint256 value );

	event TokensBurned (
		address indexed burner, 
		uint256 value );

	event Approval (
		address indexed owner,
		address indexed spender,
		uint256 value );


	constructor() public {
		//contract creator holds all tokens at creation
		balances[msg.sender] = totalSupply_;

		//record contract owner for later reference (e.g. in ownerBurn)
		contractOwner=msg.sender;

		//indicate all tokens were sent to contract address
		emit Transfer(address(0), msg.sender, totalSupply_);
	}

	function ownerBurn ( 
			uint256 _value )
		public returns (
			bool success) {

		//only the contract owner can burn tokens
		require(msg.sender == contractOwner);

		//can only burn tokens held by the owner
		require(_value <= balances[contractOwner]);

		//total supply of tokens is decremented when burned
		totalSupply_ = totalSupply_.sub(_value);

		//balance of the contract owner is reduced (the contract owner&#39;s tokens are burned)
		balances[contractOwner] = balances[contractOwner].sub(_value);

		//burning tokens emits a transfer to 0, as well as TokensBurned
		emit Transfer(contractOwner, address(0), _value);
		emit TokensBurned(contractOwner, _value);

		return true;

	}
	
	
	function totalSupply ( ) public view returns (
		uint256 ) {

		return totalSupply_;
	}

	function balanceOf (
			address _owner ) 
		public view returns (
			uint256 ) {

		return balances[_owner];
	}

	function transfer (
			address _to, 
			uint256 _value ) 
		public returns (
			bool ) {

		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		emit Transfer(msg.sender, _to, _value);
		return true;
	}

   	//changing approval with this method has the same underlying issue as https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   	//in that transaction order can be modified in a block to spend, change approval, spend again
   	//the method is kept for ERC-20 compatibility, but a set to zero, set again or use of the below increase/decrease should be used instead
	function approve (
			address _spender, 
			uint256 _value ) 
		public returns (
			bool ) {

		allowed[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function increaseApproval (
			address _spender, 
			uint256 _addedValue ) 
		public returns (
			bool ) {

		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval (
			address _spender,
			uint256 _subtractedValue ) 
		public returns (
			bool ) {

		uint256 oldValue = allowed[msg.sender][_spender];

		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function allowance (
			address _owner, 
			address _spender ) 
		public view returns (
			uint256 remaining ) {

		return allowed[_owner][_spender];
	}

	function transferFrom (
			address _from, 
			address _to, 
			uint256 _value ) 
		public returns (
			bool ) {

		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

}