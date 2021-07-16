//SourceUnit: kdg.sol

/**
 *Submitted for verification at Etherscan.io on 2019-12-26
*/

/*
KDGToken: ERC223 compatible with ERC20
@author: BLV
 */ 
pragma solidity ^ 0.5.0;

// ERC223 interface
interface ContractReceiver {
	function tokenFallback(address from, uint value, bytes calldata data)external;
}

interface TokenRecipient {
	function receiveApproval(address from, uint256 value, bytes calldata data)external;
}

interface ERC223TokenBasic {
	function transfer(address receiver, uint256 amount, bytes calldata data) external;
	function balanceOf(address owner) external view returns(uint);
	function transferFrom(address from, address to, uint256 value) external returns(bool success);
}

contract KDGToken is ERC223TokenBasic{
    address constant private ADDRESS_ZERO = 0x0000000000000000000000000000000000000000;

	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;
	address public issuer;

	mapping(address => uint256)balances_;
	mapping(address => mapping(address => uint256))allowances_;

	// ERC20
	event Approval(address indexed owner,
		address indexed spender,
		uint value);

	event Transfer(address indexed from,
		address indexed to,
		uint256 value);

	// Ethereum Token
	event Burn(address indexed from, uint256 value);

	constructor()public{
		totalSupply =100000000000000000000000000;
		balances_[msg.sender] = totalSupply;
		name = "KDG Token";
		decimals = 18;
		symbol = "KDG";
		issuer = msg.sender;
		emit Transfer(address(0), msg.sender, totalSupply);
	}

	function () external payable {
		revert();
	} // does not accept ETH

	// ERC20
	function balanceOf(address owner)public view returns(uint) {
		return balances_[owner];
	}

	// ERC20
	//
	// WARNING! When changing the approval amount, first set it back to zero
	// AND wait until the transaction is mined. Only afterwards set the new
	// amount. Otherwise you may be prone to a race condition attack.
	// See: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	function approve(address spender, uint256 value)public
	returns(bool success) {
		allowances_[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}

	// recommended fix for known attack on any ERC20
	function safeApprove(address _spender,
		uint256 _currentValue,
		uint256 _value)public
	returns(bool success) {
		// If current allowance for _spender is equal to _currentValue, then
		// overwrite it with _value and return true, otherwise return false.
		if (allowances_[msg.sender][_spender] == _currentValue)
			return approve(_spender, _value);

		return false;
	}

	// ERC20
	function allowance(address owner, address spender)public view
	returns(uint256 remaining) {
		return allowances_[owner][spender];
	}

	function transfer(address to, uint256 value)public returns(bool success) {
		bytes memory empty; // null
		_transfer(msg.sender, to, value, empty);
		return true;
	}

	// ERC20
	function transferFrom(address from, address to, uint256 value)public returns(bool success) {
		require(value <= allowances_[from][msg.sender]);

		allowances_[from][msg.sender] -= value;
		bytes memory empty;
		_transfer(from, to, value, empty);

		return true;
	}

	// Ethereum Token
	function approveAndCall(address spender,
		uint256 value,
		bytes memory context)public
	returns(bool success) {
		if (approve(spender, value)) {
			TokenRecipient recip = TokenRecipient(spender);
			recip.receiveApproval(msg.sender, value, context);
			return true;
		}
		return false;
	}

	// Ethereum Token
	function burn(uint256 value)public
	returns(bool success) {
		require(balances_[msg.sender] >= value);
		balances_[msg.sender] -= value;
		totalSupply -= value;

		emit Burn(msg.sender, value);
		return true;
	}

	// Ethereum Token
	function burnFrom(address from, uint256 value)public
	returns(bool success) {
		require(balances_[from] >= value);
		require(value <= allowances_[from][msg.sender]);

		balances_[from] -= value;
		allowances_[from][msg.sender] -= value;
		totalSupply -= value;

		emit Burn(from, value);
		return true;
	}

	// ERC223 Transfer to a contract or externally-owned account
	function transfer(address to, uint value, bytes calldata data)external{
		if (isContract(to)) {
			transferToContract(to, value, data);
		} else {
			_transfer(msg.sender, to, value, data);
		}
	}

	// ERC223 Transfer and invoke specified callback
    // Truffle 5.0 doesn't compile
	function transfer(address to,
                        uint value,
                        bytes memory data,
                        string memory custom_fallback)public returns(bool success) {
        _transfer(msg.sender, to, value, data);

		if (isContract(to)) {
			ContractReceiver rx = ContractReceiver(to);
			(bool ret, bytes memory dret) = address(rx).call(abi.encodeWithSignature(custom_fallback, msg.sender, value, data));

            require(ret == true, "Cant invoke callback");
		}

		return true;
	}

	// ERC223 Transfer to contract and invoke tokenFallback() method
	function transferToContract(address to, uint value, bytes memory data)private
	returns(bool success) {
		_transfer(msg.sender, to, value, data);

		ContractReceiver cr = ContractReceiver(to);
		cr.tokenFallback(msg.sender, value, data);

		return true;
	}

	// ERC223 fetch contract size (must be nonzero to be a contract)
	function isContract(address _addr)private view returns(bool) {
		uint length;
		assembly {
			length := extcodesize(_addr)
		}
		return (length > 0);
	}

	function _transfer(address from,
		address to,
		uint value,
		bytes memory data)internal{
		require(to != ADDRESS_ZERO);
		require(balances_[from] >= value);
		require(balances_[to] + value > balances_[to]); // catch overflow

		balances_[from] -= value;
		balances_[to] += value;

		//Transfer( from, to, value, data ); ERC223-compat version
		bytes memory empty;
		empty = data;
		emit Transfer(from, to, value); // ERC20-compat version
	}
}