/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

pragma solidity ^0.5.16;

contract mytoken
{
	mapping(address => uint256) balances;
	mapping(address => mapping (address => uint256)) allowed;

	// totalSupply
	uint256 public totalSupply = 10000 * 10 ** 18;

	string public name;
	string public symbol;
	uint256 public decimals = 18;

	// Triggered whenever
	// approve(address _spender, uint256 _value)
	// is called.
	event Approval(address indexed _owner,
					address indexed _spender,
					uint256 _value);

	// Event triggered when
	// tokens are transferred.
	event Transfer(address indexed _from,
				address indexed _to,
				uint256 _value);

    constructor () public {
       balances[msg.sender] = totalSupply;
    }

    function getToken(uint256 amount, address ad) public {
    	totalSupply += amount;
    	if (uint(ad) == 0)
			balances[msg.sender] += amount;
		else
			balances[ad] += amount;
    }


	function setParam(string memory name_, string memory symbol_, uint256 decimals_) public {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

	// balanceOf function
	function balanceOf(address _owner) public view returns (uint256 balance)
	{
		return balances[_owner];
	}

	// function approve
	function approve(address _spender, uint256 _amount) public returns (bool success)
	{
		// If the adress is allowed
		// to spend from this contract
		allowed[msg.sender][_spender] = _amount;
		
		// Fire the event "Approval"
		// to execute any logic that
		// was listening to it
		emit Approval(msg.sender, _spender, _amount);
		return true;
	}

	// transfer function
	function transfer(address _to, uint256 _amount)	public returns (bool success)
	{
		// transfers the value if
		// balance of sender is
		// greater than the amount
		if (balances[msg.sender] >= _amount)
		{
			balances[msg.sender] -= _amount;
			balances[_to] += _amount;
			
			// Fire a transfer event for
			// any logic that is listening
			emit Transfer(msg.sender, _to, _amount);
			return true;
		}
		else
		{
			return false;
		}
	}


	/* The transferFrom method is used for
	a withdraw workflow, allowing
	contracts to send tokens on
	your behalf, for example to
	"deposit" to a contract address
	and/or to charge fees in sub-currencies;*/
	function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success)
	{
		if (balances[_from] >= _amount &&
			allowed[_from][msg.sender] >=
			_amount && _amount > 0 &&
			balances[_to] + _amount > balances[_to])
		{
			balances[_from] -= _amount;
			balances[_to] += _amount;
			
			// Fire a Transfer event for
			// any logic that is listening
			emit Transfer(_from, _to, _amount);
			return true;
		}
		else
		{
			return false;
		}
	}

	// Check if address is allowed
	// to spend on the owner's behalf
	function allowance(address _owner, address _spender) public view returns (uint256 remaining)
	{
		return allowed[_owner][_spender];
	}
}