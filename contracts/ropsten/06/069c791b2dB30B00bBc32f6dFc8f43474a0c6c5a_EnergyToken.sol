pragma solidity ^0.4.24;


library SafeMath {

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		require(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0); // Solidity only automatically asserts when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;
		return c;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);
		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		return a % b;
	}
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	address public owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	* @dev The Ownable constructor sets the original `owner` of the contract to the sender
	* account.
	*/
	constructor() public {
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
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}


/**
 * @title ERC20Basic
 * @dev Condensed version of Zeppelin ERC20 and ERC20Basic
 * @dev see https://theethereum.wiki/w/index.php/ERC20_Token_Standard
 */
contract ERC20Interface {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool); // ol&#39;interface
	event Transfer(address indexed from, address indexed to, uint256 value);

	function allowance(address owner, address spender) public constant returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Interface { /*ERC20Basic*/
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	uint256 totalSupply_;

	/**
	* @dev total number of tokens in existence
	*/
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_value <= balances[msg.sender]);
		require(_to != address(0));

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	* @dev Gets the balance of the specified address.
	* @param _owner The address to query the the balance of.
	* @return An uint256 representing the amount owned by the passed address.
	*/
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20Interface, BasicToken { /*ERC20*/

	mapping (address => mapping (address => uint256)) internal allowed;

	/**
	* @dev Transfer tokens from one address to another
	* @param _from address The address which you want to send tokens from
	* @param _to address The address which you want to transfer to
	* @param _value uint256 the amount of tokens to be transferred
	*/
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);
		require(_to != address(0));

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	/**
	* @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
	*
	* Beware that changing an allowance with this method brings the risk that someone may use both the old
	* and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
	* race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
	* https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	* @param _spender The address which will spend the funds.
	* @param _value The amount of tokens to be spent.
	*/
	function approve(address _spender, uint256 _value) public returns (bool) {
		require(_spender != address(0));
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	/**
	* @dev Function to check the amount of tokens that an owner allowed to a spender.
	* @param _owner address The address which owns the funds.
	* @param _spender address The address which will spend the funds.
	* @return A uint256 specifying the amount of tokens still available for the spender.
	*/
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	/**
	* @dev Increase the amount of tokens that an owner allowed to a spender.
	*
	* approve should be called when allowed[_spender] == 0. To increment
	* allowed value is better to use this function to avoid 2 calls (and wait until
	* the first transaction is mined)
	* From MonolithDAO Token.sol
	* @param _spender The address which will spend the funds.
	* @param _addedValue The amount of tokens to increase the allowance by.
	*/
	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	/**
	* @dev Decrease the amount of tokens that an owner allowed to a spender.
	*
	* approve should be called when allowed[_spender] == 0. To decrement
	* allowed value is better to use this function to avoid 2 calls (and wait until
	* the first transaction is mined)
	* From MonolithDAO Token.sol
	* @param _spender The address which will spend the funds.
	* @param _subtractedValue The amount of tokens to decrease the allowance by.
	*/
	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

}

contract EnergyToken is StandardToken, Ownable {

	string public name = "Energy Test";
	string public symbol = "ETT";
	uint public decimals = 2;
	uint public INITIAL_SUPPLY = 1000000 * (10 ** decimals);

	/**
	* Transaction Reference Data
	* the first bytes32 is the querykey to help with searching the hash table:
	* h(h(FULLNAME),h(SERIALNUM),h(MACADDRESS),h(TIMESTAMP),h(LOGS))
	* and the second bytes32 is the virtual battery percentage value to hex
	*/
	mapping (bytes32 => bytes32) public extraDataRef;
	/**
	* Transaction count by address
	* the from addresses and the the tx index num
	*/
	mapping (address => uint256 ) public extraDataByAddrIndex;
	/**
	* Transaction Ref indexed by addresses
	* the from address mapped to index mapped to querykey
	*/
	mapping (address => mapping ( uint256 => bytes32 ) ) public extraDataByAddress;

	event ExtraDataRef(bytes32 indexed dataQueryKey, bytes32 indexed dataRef);
	event ExtraDataRefByAddr(address indexed addrQueryKey, uint256 indexed addrTransactionIndex, bytes32 indexed dataQueryKey);

	/**
	* @dev Constructor that gives msg.sender all of existing tokens.
	*/
	constructor() public onlyOwner() {
		totalSupply_ = INITIAL_SUPPLY;
		balances[msg.sender] = totalSupply_;
		emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
	}

	/**
	* Transfer With Extra Data
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	* @param _extraData1 h( string )
	* @param _extraData2 virtual energy transfer value to hex
	* h( string )
	*/
	function transferWithExtra(address _to, uint256 _value, bytes32 _extraData1, bytes32 _extraData2) public returns (bool) {
		uint256 index = extraDataByAddrIndex[msg.sender];
		uint256 indexNew = index.add(1);
		transfer(_to, _value);
		extraDataByAddress[msg.sender][index] = _extraData1;
		extraDataByAddrIndex[msg.sender] = indexNew;
		extraDataRef[_extraData1] = _extraData2;
		emit ExtraDataRef(_extraData1, _extraData2);
		emit ExtraDataRefByAddr(msg.sender, index, _extraData2);
		return true;
	}

	/**
	* @dev Function to get the extraData1 from a strings
	* @param _s json object representing the combined logs of energy transfer
	* @return bytes32
	*/
	function extraData1FromHash(string _s) public pure returns (bytes32) {
		return keccak256( abi.encodePacked( _s ) );
	}
    // function extraData1FromHash(string _fnam, string _snum, string _maca, string _time, string _logs) public pure returns (bytes32) {
    // 	return keccak256( keccak256(_fnam), keccak256(_snum), keccak256(_maca), keccak256(_time), keccak256(_logs) );
    // }

	/**
	* @dev Aidrop transfer to multiple addresses with the same value
	*/
	function multiTransferFixed(address[] _dests, uint256 _value) public returns (uint256) {
		uint256 i=0;
		while (i < _dests.length) {
			transfer(_dests[i], _value);
			i++;
		}
		return i;
	}

	/**
	* @dev Aidrop transfer to multiple addresses
	*/
	function multiTransfer(address[] _dests, uint256[] _values) public returns (uint256) {
		assert(_dests.length == _values.length);
		uint256 i=0;
		while (i < _dests.length) {
			transfer(_dests[i], _values[i]);
			i++;
		}
		return i;
	}

	/**
	* Owner can transfer out any accidentally sent ERC20 tokens
	*/
	function transferAnyERC20Token(address tokenAddress) public onlyOwner returns (bool success) {
		uint256 balance = ERC20Interface(tokenAddress).balanceOf(this);
		return ERC20Interface(tokenAddress).transfer(owner, balance);
	}

	/**
	* @dev Function to be executed postmint to create one extra token
	*
	* Based on
	* github.com/OpenZeppelin/zeppelin-solidity/blob/v1.6.0/contracts/token/ERC20/MintableToken.sol
	* 100 is the amount of tokens to mint.
	* @return A boolean that indicates if the operation was successful.
	*/
	function postMintCreation(address _to/*, uint256 _amount*/) public onlyOwner returns (bool) {
		uint256 amount = 100;
		if (_to==0) _to = msg.sender;
		totalSupply_ = totalSupply_.add(amount);
		balances[_to] = balances[_to].add(amount);
		emit Transfer(address(0), _to, amount);
		return true;
	}

	function () external { revert(); } // not payable

}