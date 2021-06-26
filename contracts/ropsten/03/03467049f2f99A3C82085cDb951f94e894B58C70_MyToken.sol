/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;


contract MyToken
{
    string public constant name = "proglit";
    string public constant symbol = "PRL";
    uint8 public constant decimals = 3;
    
    uint public totalSupply = 0;
    address owner;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    
    event Transfer(address indexed address1, address indexed address2, uint number);
    event Approval(address indexed address1, address indexed address2, uint number);
    
    
    modifier OnlyOwner()
    {
        require(owner == msg.sender);
        _;
    }
    
    
    constructor()
    {
        owner = msg.sender;
    }
    
    
    function mint(address address_needed, uint parts) public OnlyOwner payable
    {
        
        require((totalSupply + parts) >= totalSupply);
        require(balances[address_needed] + parts >= balances[address_needed]);
        
        balances[address_needed] += parts;
        totalSupply += parts;
    }
    
    function balanceOf(address address_needed) public view returns(uint)
    {
        return balances[address_needed];
    }
    
    function balanceOf() public view returns(uint)
    {
        return balances[msg.sender];
    }
    
    
    function transfer(address address_needed, uint number) public payable
    {
        require(balances[msg.sender] >= number);
        require((balances[address_needed] + number) >= balances[address_needed]);
        
        balances[msg.sender] -= number;
        balances[address_needed] += number;
        
        emit Transfer(msg.sender, address_needed, number);
    }
    
    function transferFrom(address address1, address address2, uint number) public payable
    {
        require(balances[address1] >= number);
        require((balances[address2] + number) >= balances[address2]);
        
        balances[address1] -= number;
        balances[address2] += number;
        
        allowed[msg.sender][address1] -= number;
        
        emit Transfer(address1, address2, number);
        emit Approval(address1, address2, number);
    }
    
    
    function approve(address address_needed, uint value) public payable
    {
		allowed[msg.sender][address_needed] = value;
		
		emit Approval(msg.sender, address_needed, value);
	}
	
	function allowance(address _owner, address _spender) public view returns (uint) 
	{
		return allowed[_owner][_spender];
	}
}