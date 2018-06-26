pragma solidity ^0.4.24;

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

contract Ownered {
	address public owner;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	constructor() public {
		owner = msg.sender;
	}

	function changeOwner(address _newOwner) public onlyOwner {
		owner = _newOwner;
	}
}

contract Token is Ownered{

	function totalSupply() public constant returns (uint256 supply) {}
	function balanceOf(address _owner) public constant returns (uint256 balance) {}
	function transfer(address _to, uint256 _value) public returns (bool success) {}
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
	function approve(address _spender, uint256 _value) public returns (bool success) {}
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {
	
	using SafeMath for uint256;
        mapping (address => bool) public blacklisted;
        mapping (address => bool) public whitelisted;

	function transfer(address _to, uint256 _value) public returns (bool success) {

		require(!blacklisted[_to]);
		require(!blacklisted[msg.sender]);
		require(whitelisted[_to]);
		require(whitelisted[msg.sender]);

		if (balances[msg.sender] >= _value && _value > 0) {
			balances[msg.sender] = balances[msg.sender].sub(_value);
			balances[_to] = balances[_to].add(_value);
			emit Transfer(msg.sender, _to, _value);
			return true;
		} else { return false; }
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {

	                require(!blacklisted[_to]);
	                require(!blacklisted[_from]);
	                require(whitelisted[_to]);
	                require(whitelisted[_from]);
	
			balances[_from] = balances[_from].sub(_value);
			allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
			balances[_to] = balances[_to].add(_value);
			
			emit Transfer(_from, _to, _value);
			return true;
		} else { return false; }
	}

	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balances[_owner];
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	uint256 public totalSupply;
}

contract HTCN is StandardToken { // CHANGE THIS. Update the contract name.
	
        using SafeMath for uint256;

	string public name;                  
	uint8 public decimals;                
	string public symbol;                 
	string public version = &#39;H1.0&#39;; 
	uint256 public unitsOneEthCanBuy;     
	uint256 public totalEthInWei;         
	address public fundsWallet;           

	constructor() public {
		balances[msg.sender] = 1000000000000000000000;               
		totalSupply = 1000000000000000000000;                       
		name = &quot;HashnodeTestCoin&quot;;                                  
		decimals = 18;                                              
		symbol = &quot;HTCN&quot;;                                             
		unitsOneEthCanBuy = 10;                                      
		fundsWallet = msg.sender;                                      
	}

	function() public payable{
		totalEthInWei = totalEthInWei.add(msg.value);
		uint256 amount = msg.value.mul(unitsOneEthCanBuy);
		require(balances[fundsWallet] >= amount);

		balances[fundsWallet] = balances[fundsWallet].sub(amount);
		balances[msg.sender] = balances[msg.sender].add(amount);

		emit Transfer(fundsWallet, msg.sender, amount); // Broadcast a message to the blockchain

		fundsWallet.transfer(msg.value);                               
	}

	function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);


		if(!_spender.call(bytes4(bytes32(keccak256(&quot;receiveApproval(address,uint256,address,bytes)&quot;))), msg.sender, _value, this, _extraData)) { throw; }
		return true;
	}
	
	function setBlacklist(address tokenOwner) public onlyOwner returns (bool) {
		blacklisted[tokenOwner] = true;
		return true;
	}

	function unsetBlacklist(address tokenOwner) public onlyOwner returns (bool) {
		blacklisted[tokenOwner] = false;
	}

        function setWhitelist(address tokenOwner) public onlyOwner returns (bool) {
                whitelisted[tokenOwner] = true;
                return true;
        }

        function unsetWhitelist(address tokenOwner) public onlyOwner returns (bool) {
                whitelisted[tokenOwner] = false;
        }

}