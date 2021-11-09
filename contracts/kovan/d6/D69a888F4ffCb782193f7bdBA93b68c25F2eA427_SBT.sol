// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StandardToken.sol";

contract SBT is StandardToken
{
	string public name = "SBTERC223";
	string public symbol = "SBT";
	uint8 public constant decimals = 18;
        address internal  _admin;

	uint public constant DECIMALS_MULTIPLIER = 10**uint(decimals);

	constructor() 
	{
                 _admin = msg.sender;
		totalSupply = 400000000 * DECIMALS_MULTIPLIER;
		balances[msg.sender] = totalSupply;
	  	emit Transfer(address(0), msg.sender, totalSupply);
	}


      modifier ownership()  {
    require(msg.sender == _admin);
        _;
    }



  //Admin can transfer his ownership to new address
  function transferownership(address _newaddress) public returns(bool){
      require(msg.sender==_admin);
      _admin=_newaddress;
      return true;
  }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./IERC223.sol";

contract StandardToken is ERC20, ERC223
{
        
	uint256 public totalSupply;

        
	mapping (address => uint256) internal balances;
	mapping (address => mapping (address => uint256)) internal allowed;

	event Burn(address indexed burner, uint256 value);

	function transfer(address _to, uint256 _value) external override returns (bool)
	{
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		balances[msg.sender] = balances[msg.sender] - _value;
		balances[_to] = balances[_to] + _value;
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf (address _owner) public override view returns (uint256 balance)
	{
		return balances[_owner];
	}

	function transferFrom(address _from, address _to, uint256 _value) external override returns (bool)
	{
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from] - _value;
		balances[_to] = balances[_to] + _value;
		allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
		emit Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) external override returns (bool)
	{
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public override view returns (uint256)
	{
		return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint256 _addedValue) external returns (bool)
	{
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue;
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint256 _subtractedValue) external returns (bool)
	{
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue)
		{
			allowed[msg.sender][_spender] = 0;
		}
		else
		{
			allowed[msg.sender][_spender] = oldValue - _subtractedValue;
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function transfer(address _to, uint256 _value, bytes calldata _data) external override
	{
		require(_value > 0 );
		if(isContract(_to))
		{
			ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
			receiver.tokenFallback(msg.sender, _value, _data);
		}
		balances[msg.sender] = balances[msg.sender] - _value;
		balances[_to] = balances[_to] + _value;
		emit Transfer(msg.sender, _to, _value, _data);
	}

	function isContract(address _addr) view private returns (bool is_contract)
	{
		uint256 length;
		assembly
		{
			length := extcodesize(_addr)
		}
		return (length>0);
	}

	function burn(uint256 _value) external
	{
		require(_value <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender] - _value;
		totalSupply = totalSupply - _value;
		emit Burn(msg.sender, _value);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC223 interface
 */
interface ERC223
{
	function transfer(address to, uint256 value, bytes calldata data) external;
	event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
}

/*
Base class contracts willing to accept ERC223 token transfers must conform to.
*/

abstract contract ERC223ReceivingContract
{
	function tokenFallback(address _from, uint256 _value, bytes calldata _data) virtual external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC20 interface
 */
interface ERC20
{
	function balanceOf(address who) external view returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
	function approve(address spender, uint256 value) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}