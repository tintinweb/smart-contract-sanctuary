pragma solidity ^0.4.23;

// File: contracts/ERC223.sol

contract ERC223 {
	
	// Get the account balance of another account with address owner
	function balanceOf(address owner) public view returns (uint);
	
	function name() public view returns (string);
	function symbol() public view returns (string);
	function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint);

	// Needed due to backwards compatibility reasons because of ERC20 transfer function does&#39;t have bytes
	// parameter. This function must transfer tokens and invoke the function tokenFallback(address, uint256,
	// bytes) in to, if to is a contract. If the tokenFallback function is not implemented in to (receiver 
	// contract), the transaaction must fail and the transfer of tokens should not occur.
	function transfer(address to, uint value) public returns (bool success);

	// This function must transfer tokens and invoke the function tokenFallback(address, uint256, bytes) in
	// to, if to is a contract. If the tokenFallback function is not implemented in to (receiver contract), then
	// the transaction must fail and the transfer of tokens should not occur.
	// If to is an externally owned address, then the transaction must be sent without trying to execute
	// tokenFallback in to.
	// data can be attached to this token transaction it will stay in blockchain forever(requires more gas).
	// data can be empty.
    function transfer(address to, uint value, bytes data) public returns (bool success);

    //
    function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool success);

    // Triggered when tokens are transferred.
    event Transfer(address indexed from, address indexed to, uint indexed value, bytes data);
}

// File: contracts/ERC223ReceivingContract.sol

contract ERC223ReceivingContract { 
	
	// A function for handling token transfers, which is called from the token contract, when a token holder sends
	// tokens. from is the address of the sender of the token, value is the amount of incoming tokens, and data is
	// attached data siimilar to msg.data of Ether transactions. It works by analogy with the fallback function of
	// Ether transactions and returns nothing.
    function tokenFallback(address from, uint value, bytes data) public;
}

// File: contracts/SafeMath.sol

/**
 * Math operations with safety checks
 */
library SafeMath {function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    } 

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
    }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
         return a < b ? a : b;
  }

}

// File: contracts/MyToken.sol

/*
 * @title Reference implementation fo the ERC223 standard token.
 */
contract MyToken is ERC223 {
    using SafeMath for uint;

    mapping(address => uint) balances; // List of user balances.

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

 
    constructor(string _name, string _symbol, uint8 _decimals, uint _totalSupply) public {
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		totalSupply = _totalSupply;
		balances[msg.sender] = _totalSupply;
	}

    function name() public view returns (string) {
		 return name;
    }

    function symbol() public view returns (string) {
		return symbol;
	}

    function decimals() public view returns (uint8) {
    	return decimals;
    }

    function totalSupply() public view returns (uint) {
    	return totalSupply;
    }


	function balanceOf(address owner) public view returns (uint) {
		return balances[owner];
	}

	function transfer(address to, uint value, bytes data) public returns (bool) {
		if(balanceOf(msg.sender) < value) revert();
		// Standard function transfer similar to ERC20 transfer with no data.
		// Added due to backwards compatibility reasons.

		balances[msg.sender] = balances[msg.sender].sub(value);
		balances[to] = balances[to].add(value);
		if(isContract(to)) {
			ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
			receiver.tokenFallback(msg.sender, value, data);
		}
		emit Transfer(msg.sender, to, value, data);
		return true;
	}

	function transfer(address to, uint value) public returns (bool) {
		if(balanceOf(msg.sender) < value) revert();
		bytes memory empty;

		balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        if(isContract(to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
            receiver.tokenFallback(msg.sender, value, empty);
        }
        emit Transfer(msg.sender, to, value, empty);
        return true;
	}

	function transfer(address to, uint value, bytes data, string customFallback) public returns (bool) {
		if(balanceOf(msg.sender) < value) revert();

		balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
		if (isContract(to)) {
            assert(to.call.value(0)(bytes4(keccak256(customFallback)), msg.sender, value, data));
        }
        emit Transfer(msg.sender, to, value, data);
        return true;
	}

	function isContract(address addr) private view returns (bool) {
		uint len;
		assembly {
			len := extcodesize(addr)
		}
		return (len > 0);
	}
}