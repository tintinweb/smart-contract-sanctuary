/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

/**
 * PANDO token 
 * 
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.9;

library SafeMath
{
  	function mul(uint256 a, uint256 b) internal pure returns (uint256)
    	{
		uint256 c = a * b;
		assert(a == 0 || c / a == b);

		return c;
  	}

  	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a / b;

		return c;
  	}

  	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		assert(b <= a);

		return a - b;
  	}

  	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		assert(c >= a);

		return c;
  	}
}

contract OwnerHelper
{
  	address public owner;

  	event ChangeOwner(address indexed _from, address indexed _to);

  	modifier onlyOwner
	{
		require(msg.sender == owner);
		_;
  	}
  	
  	constructor() public
	{
		owner = msg.sender;
  	}
  	
  	function transferOwnership(address _to) onlyOwner public
  	{
    	require(_to != owner);
    	require(_to != address(0x0));

        address from = owner;
      	owner = _to;
  	    
      	emit ChangeOwner(from, _to);
  	}
}


contract ERC20Interface
{
    event Transfer( address indexed _from, address indexed _to, uint _value);
    event Approval( address indexed _owner, address indexed _spender, uint _value);
    
    function totalSupply() view public returns (uint _supply);
    function balanceOf( address _who ) public view returns (uint _value);
    function transfer( address _to, uint _value) public returns (bool _success);
    function approve( address _spender, uint _value ) public returns (bool _success);
    function allowance( address _owner, address _spender ) public view returns (uint _allowance);
    function transferFrom( address _from, address _to, uint _value) public returns (bool _success);
}

contract PandoToken is ERC20Interface, OwnerHelper
{
    using SafeMath for uint;
    
    string public name;
    uint public decimals;
    string public symbol;

    // Founder
    address private founder;
    
    // Total
    uint public totalTokenSupply;
    uint public burnTokenSupply;

    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;
    mapping (address => bool) private blackAddress; // unLock : false, Lock : true
    
    bool public tokenLock = false;

    // Token Total
    uint constant private E18 = 1000000000000000000;

    event Burn(address indexed _from, uint _tokens);
    event TokenUnlock(address indexed _to, uint _tokens);

    constructor(string memory _name, string memory _symbol, address _founder, uint _totalTokenSupply) public {
        name        = _name;
        decimals    = 18;
        symbol      = _symbol;

        founder = _founder;
        totalTokenSupply  = _totalTokenSupply * E18;
        burnTokenSupply     = 0;

        balances[founder] = totalTokenSupply;
        emit Transfer(address(0), founder, totalTokenSupply);
    }

    // ERC - 20 Interface -----
    modifier notLocked {
        require(isTransferable() == true);
        _;
    }

    function lock(address who) onlyOwner public {
        
        blackAddress[who] = true;
    }
    
    function unlock(address who) onlyOwner public {
        
        blackAddress[who] = false;
    }
    
    function isLocked(address who) public view returns(bool) {
        
        return blackAddress[who];
    }

    function totalSupply() view public returns (uint) 
    {
        return totalTokenSupply;
    }
    
    function balanceOf(address _who) view public returns (uint) 
    {
        return balances[_who];
    }
    
    function transfer(address _to, uint _value) notLocked public returns (bool) 
    {
        require(balances[msg.sender] >= _value);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint _value) notLocked public returns (bool)
    {
        require(balances[msg.sender] >= _value);
        
        approvals[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true; 
    }
    
    function allowance(address _owner, address _spender) view public returns (uint) 
    {
        return approvals[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint _value) notLocked public returns (bool) 
    {
        require(balances[_from] >= _value);
        require(approvals[_from][msg.sender] >= _value);
        
        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to]  = balances[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    // Lock Function -----
    
    function isTransferable() private view returns (bool)
    {
        if(tokenLock == false) {

            if (blackAddress[msg.sender]) // true is Locked
            {
                return false;
            } else {
                return true;
            }
        }
        else if(msg.sender == owner)
        {
            return true;
        }
        
        return false;
    }
    
    function setTokenUnlock() onlyOwner public
    {
        require(tokenLock == true);
        
        tokenLock = false;
    }
    
    function setTokenLock() onlyOwner public
    {
        require(tokenLock == false);
        
        tokenLock = true;
    }

    function withdrawTokens(address _contract, uint _value) onlyOwner public
    {

        if(_contract == address(0x0))
        {
            uint eth = _value.mul(10 ** decimals);
            msg.sender.transfer(eth);
        }
        else
        {
            uint tokens = _value.mul(10 ** decimals);
            ERC20Interface(_contract).transfer(msg.sender, tokens);
            
            emit Transfer(address(0x0), msg.sender, tokens);
        }
    }

    function burnToken(uint _value) onlyOwner public
    {
        uint tokens = _value.mul(10 ** decimals);
        
        require(balances[msg.sender] >= tokens);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        
        burnTokenSupply = burnTokenSupply.add(tokens);
        totalTokenSupply = totalTokenSupply.sub(tokens);
        
        emit Burn(msg.sender, tokens);
    }    
    
    function close() onlyOwner public
    {
        selfdestruct(msg.sender);
    }
    
}