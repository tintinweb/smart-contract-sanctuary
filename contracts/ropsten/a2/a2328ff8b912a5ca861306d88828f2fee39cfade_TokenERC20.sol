pragma solidity ^0.4.21;

/*
VERSION DATE: 15/01/2019
*/

contract Token 
{
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token 
{

	function _transfer(address _from, address _to, uint256 _value) internal returns (bool success) 
	{
        if (balances[_from] >= _value && _value > 0) 
		{
            balances[_from] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
	}

    function transfer(address _to, uint256 _value) public returns (bool success) 
	{
        if (balances[msg.sender] >= _value && _value > 0) 
		{
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
	{
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0)
		{
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public view returns (uint256 balance)
	{
        return balances[_owner];
    }

	function _approve(address _from, address _spender, uint256 _value) internal returns (bool success)
	{
        allowed[_from][_spender] = _value;
        emit Approval(_from, _spender, _value);
        return true;
    }
	
    function approve(address _spender, uint256 _value) public returns (bool success)
	{
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining)
	{
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract Owned 
{
	address public owner;

	mapping(address => bool) public admins;
	
    function Owned() public 
	{
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public 
	{
		require(msg.sender == owner);
        owner = newOwner;
    }
	
    function addAdmin(address addr) public
	{
		require(msg.sender == owner);
        admins[addr] = true;
    }

    function removeAdmin(address addr) external
	{
		require(msg.sender == owner);
        admins[addr] = false;
    }
	
	modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
	
}

contract TokenERC20 is StandardToken, Owned
{
    string public constant name = "Peller.Tech";
    uint8  public constant decimals = 0;
    string public constant symbol = "PT";
	uint public constant maxCount = 50;
	
	mapping (uint32 => bool) public nonces;
	
	function TokenERC20() public 
	{
		mint( 10**9 );
	}
	
    function mint( uint256 _initialAmount ) private
	{
		require(totalSupply==0);
        balances[address(this)] = _initialAmount;
        totalSupply = _initialAmount;
    }
	
	function getFreeTokens(uint32 nonce, bytes32 r, bytes32 s, uint8 v) public
	{
		bytes memory prefix = "\x19Ethereum Signed Message:\n32";
		
		bytes32 hash = keccak256( this, msg.sender, nonce );
        address signer = ecrecover(keccak256(prefix,hash), v, r, s);
		require(admins[signer]);
		require(nonces[nonce] == false);
		
		//require(balanceOf(msg.sender)==0);
		require(balances[address(this)]>= maxCount);
		
		nonces[nonce] = true;
		
		_transfer(address(this), msg.sender, maxCount);
	}
	
}