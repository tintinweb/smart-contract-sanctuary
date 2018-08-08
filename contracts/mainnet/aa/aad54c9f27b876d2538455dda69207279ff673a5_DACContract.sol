pragma solidity ^0.4.21;

// smart contract for Davinci coin

// ownership contract
contract Owned {
    address public owner;

    event TransferOwnership(address oldaddr, address newaddr);

    modifier onlyOwner() { if (msg.sender != owner) return; _; }

    function Owned() public {
        owner = msg.sender;
    }
    
    function transferOwnership(address _new) onlyOwner public {
        address oldaddr = owner;
        owner = _new;
        emit TransferOwnership(oldaddr, owner);
    }
}

// erc20
contract ERC20Interface {
	uint256 public totalSupply;
	function balanceOf(address _owner) public constant returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
	function approve(address _spender, uint256 _value) public returns (bool success);
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract DACContract is ERC20Interface, Owned {
	string public constant symbol = "DAC";
	string public constant name = "Davinci coin";
	uint8 public constant decimals = 18;
	uint256 public constant totalSupply = 8800000000000000000000000000;

	bool public stopped;

	mapping (address => int8) public blackList;

	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowed;


    event Blacklisted(address indexed target);
    event DeleteFromBlacklist(address indexed target);
    event RejectedPaymentToBlacklistedAddr(address indexed from, address indexed to, uint256 value);
    event RejectedPaymentFromBlacklistedAddr(address indexed from, address indexed to, uint256 value);


	modifier notStopped {
        require(!stopped);
        _;
    }

// constructor
	function DACContract() public {
		balances[msg.sender] = totalSupply;
	}
	
// function made for airdrop
	function airdrop(address[] _to, uint256[] _value) onlyOwner notStopped public {
	    for(uint256 i = 0; i < _to.length; i++){
	        if(balances[_to[i]] > 0){
	            continue;
	        }
	        transfer(_to[i], _value[i]);
	    }
	}

// blacklist management
    function blacklisting(address _addr) onlyOwner public {
        blackList[_addr] = 1;
        emit Blacklisted(_addr);
    }
    function deleteFromBlacklist(address _addr) onlyOwner public {
        blackList[_addr] = -1;
        emit DeleteFromBlacklist(_addr);
    }

// stop the contract
	function stop() onlyOwner {
        stopped = true;
    }
    function start() onlyOwner {
        stopped = false;
    }
	
// ERC20 functions
	function balanceOf(address _owner) public constant returns (uint256 balance){
		return balances[_owner];
	}
	function transfer(address _to, uint256 _value) notStopped public returns (bool success){
		require(balances[msg.sender] >= _value);

		if(blackList[msg.sender] > 0){
			emit RejectedPaymentFromBlacklistedAddr(msg.sender, _to, _value);
			return false;
		}
		if(blackList[_to] > 0){
			emit RejectedPaymentToBlacklistedAddr(msg.sender, _to, _value);
			return false;
		}

		balances[msg.sender] -= _value;
		balances[_to] += _value;
		emit Transfer(msg.sender, _to, _value);
		return true;
	}
	function transferFrom(address _from, address _to, uint256 _value) notStopped public returns (bool success){
		require(balances[_from] >= _value
			&& allowed[_from][msg.sender] >= _value);

		if(blackList[_from] > 0){
			emit RejectedPaymentFromBlacklistedAddr(_from, _to, _value);
			return false;
		}
		if(blackList[_to] > 0){
			emit RejectedPaymentToBlacklistedAddr(_from, _to, _value);
			return false;
		}

		balances[_from] -= _value;
		allowed[_from][msg.sender] -= _value;
		balances[_to] += _value;
		emit Transfer(_from, _to, _value);
		return true;
	}
	function approve(address _spender, uint256 _value) notStopped public returns (bool success){
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining){
		return allowed[_owner][_spender];
	}
}