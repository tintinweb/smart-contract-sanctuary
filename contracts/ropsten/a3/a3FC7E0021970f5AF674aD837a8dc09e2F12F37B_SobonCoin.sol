pragma solidity ^0.7.3; 

import "./IERC20.sol";

contract SobonCoin is EIP20Interface {

	uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public totalSupply;

    constructor (
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

	function balanceOf(address _owner) public view virtual override returns (uint256 balance)
	{
		return balances[_owner];
	}

	function transfer(address _to, uint256 _value) public virtual override returns (bool success)
	{
		require(balances[msg.sender] >= _value);
		
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		emit Transfer(msg.sender,_to,_value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool success)
	{
		uint256 allowance = allowed[_from][msg.sender];
		require(balances[_from] >= _value && allowance >= _value);

		if (allowance < MAX_UINT256) {
			allowed[_from][msg.sender] -= _value;			
		}
		balances[_from] -= _value;
		balances[_to] += _value;
		emit Transfer(_from,_to,_value);
		return true;		
	}

	function approve(address _spender, uint256 _value) public virtual override returns (bool success)
	{
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public virtual override view returns (uint256 remaining)
	{
		return allowed[_owner][_spender];
	}
}