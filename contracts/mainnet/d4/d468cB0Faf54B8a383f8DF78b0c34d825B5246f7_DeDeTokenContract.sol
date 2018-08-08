pragma solidity ^0.4.11;

contract ERC20Interface {
	function totalSupply() constant returns (uint totalSupply);
	function balanceOf(address _owner) constant returns (uint balance);
	function transfer(address _to, uint _value) returns (bool success);
	function transferFrom(address _from, address _to, uint _value) returns (bool success);
	function approve(address _spender, uint _value) returns (bool success);
	function allowance(address _owner, address _spender) constant returns (uint remaining);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract DeDeTokenContract is ERC20Interface {
// ERC20 basic variables
	string public constant symbol = "DEDE";
	string public constant name = "DeDeToken";
	uint8 public constant decimals = 18; // smallest unit is 10**-18, same as ether wei
	uint256 public _totalSupply = (25 ether) * (10 ** 7); // total dede is 2.5 * 10**8

	mapping (address => uint) public balances;
	mapping (address => mapping (address => uint256)) public allowed;

// variables for donation
	address public dedeNetwork;
	bool public installed = false;

// constructor
	function DeDeTokenContract(address _dedeNetwork){
		require(_dedeNetwork != 0);

		balances[_dedeNetwork] = (_totalSupply * 275) / 1000; // 27.5% of all tokens. 20% is for dedeNetwork, 7.5% is for early donators
		balances[this] = _totalSupply - balances[_dedeNetwork];

		Transfer(0, _dedeNetwork, balances[_dedeNetwork]);
		Transfer(0, this, balances[this]);

		dedeNetwork = _dedeNetwork;
	}

	function installDonationContract(address donationContract){
		require(msg.sender == dedeNetwork);
		require(!installed);

		installed = true;

		allowed[this][donationContract] = balances[this];
		Approval(this, donationContract, balances[this]);
	}

	function changeDeDeNetwork(address newDeDeNetwork){
		require(msg.sender == dedeNetwork);
		dedeNetwork = newDeDeNetwork;
	}

// ERC20 FUNCTIONS
	//get total tokens
	function totalSupply() constant returns (uint totalSupply){
		return _totalSupply;
	}
	//get balance of user
	function balanceOf(address _owner) constant returns (uint balance){
		return balances[_owner];
	}
	//transfer tokens
	function transfer(address _to, uint _value) returns (bool success){
		if(balances[msg.sender] >= _value
			&& _value > 0
			&& balances[_to] + _value > balances[_to]){
			balances[msg.sender] -= _value;
			balances[_to] += _value;
			Transfer(msg.sender, _to, _value);
			return true;
		}
		else{
			return false;
		}
	}
	//transfer tokens if you have a delegated wallet
	function transferFrom(address _from, address _to, uint _value) returns (bool success){
		if(balances[_from] >= _value
			&& allowed[_from][msg.sender] >= _value
			&& _value > 0
			&& balances[_to] + _value > balances[_to]){
			balances[_from] -= _value;
			allowed[_from][msg.sender] -= _value;
			balances[_to] += _value;
			Transfer(_from, _to, _value);
			return true;
		}
		else{
			return false;
		}
	}
	//delegate your wallet to someone
	function approve(address _spender, uint _value) returns (bool success){
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}
	//get allowance that you can spend, from delegated wallet
	function allowance(address _owner, address _spender) constant returns (uint remaining){
		return allowed[_owner][_spender];
	}
}