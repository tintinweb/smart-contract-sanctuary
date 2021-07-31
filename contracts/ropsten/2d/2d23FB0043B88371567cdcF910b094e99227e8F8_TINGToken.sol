/**
 *Submitted for verification at Etherscan.io on 2021-07-30
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
    address public manager;

  	event ChangeOwner(address indexed _from, address indexed _to);
    event ChangeManager(address indexed _from, address indexed _to);

  	modifier onlyOwner
	{
		require(msg.sender == owner);
		_;
  	}
  	
    modifier onlyManager
    {
        require(msg.sender == manager);
        _;
    }

  	constructor() public
	{
		owner = msg.sender;
  	}
  	
  	function transferOwnership(address _to) onlyOwner public
  	{
    	require(_to != owner);
        require(_to != manager);
    	require(_to != address(0x0));

        address from = owner;
      	owner = _to;
  	    
      	emit ChangeOwner(from, _to);
  	}

    function transferManager(address _to) onlyOwner public
    {
        require(_to != owner);
        require(_to != manager);
        require(_to != address(0x0));
        
        address from = manager;
        manager = _to;
        
        emit ChangeManager(from, _to);
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

contract TINGToken is ERC20Interface, OwnerHelper
{
    using SafeMath for uint;
    
    string public name;
    uint public decimals;
    string public symbol;
    
    uint constant private E18 = 1000000000000000000;
    
    // Total                                  2,000,000,000
    uint constant public maxTotalSupply     = 2000000000 * E18;

    // User Engagement                        1,400,000,000 (70%)
    uint constant public maxUserSupply      = 1400000000 * E18;

    // Airdrop                                200,000,000 (10%)
    uint constant public maxAirdropSupply   = 200000000 * E18;

    // Marketing                              200,000,000 (10%)
    uint constant public maxMarketSupply    = 200000000 * E18;

    // Research & Development                 100,000,000 (5%)
    uint constant public maxRnDSupply       = 100000000 * E18;

    // Team                                   50,000,000 (2.5%)
    uint constant public maxTeamSupply      = 50000000 * E18;

    // Reserve                                50,000,000 (2.5%)
    uint constant public maxReserveSupply   = 50000000 * E18;   
        

    uint public totalTokenSupply;

    uint public tokenIssuedUser;
    uint public tokenIssuedAirdrop;
    uint public tokenIssuedMarket;
    uint public tokenIssuedRnD;
    uint public tokenIssuedTeam;
    uint public tokenIssuedReserve;    
    
    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;
      
    bool public tokenLock = false;


    event UserIssue(address indexed _to, uint _tokens);
    event AirdropIssue(address indexed _to, uint _tokens);
    event MarketIssue(address indexed _to, uint _tokens);
    event RnDIssue(address indexed _to, uint _tokens);
    event TeamIssue(address indexed _to, uint _tokens);
    event ReserveIssue(address indexed _to, uint _tokens);

    
    constructor() public
    {
        name        = "PANTING";
        decimals    = 18;
        symbol      = "TING";
        
        totalTokenSupply = 2000000000 * E18;
        balances[owner] = totalTokenSupply;


        tokenIssuedUser     = 0;
        tokenIssuedAirdrop  = 0;
        tokenIssuedMarket   = 0;
        tokenIssuedRnD      = 0;
        tokenIssuedTeam     = 0;
        tokenIssuedReserve  = 0;
        
        require(maxTotalSupply == maxUserSupply + maxAirdropSupply + maxMarketSupply + maxRnDSupply + maxTeamSupply + maxReserveSupply);
    }

    function totalSupply() view public returns (uint) 
    {
        return totalTokenSupply;
    }
    
    function balanceOf(address _who) view public returns (uint) 
    {
        return balances[_who];
    }
    
    function transfer(address _to, uint _value) public returns (bool) 
    {
        require(isTransferable() == true);
        require(balances[msg.sender] >= _value);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint _value) public returns (bool)
    {
        require(isTransferable() == true);
        require(balances[msg.sender] >= _value);
        
        approvals[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true; 
    }
    
    function allowance(address _owner, address _spender) view public returns (uint) 
    {
        return approvals[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) 
    {
        require(isTransferable() == true);
        require(balances[_from] >= _value);
        require(approvals[_from][msg.sender] >= _value);
        
        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to]  = balances[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    function userIssue(address _to) onlyOwner public
    {
        require(tokenIssuedUser == 0);
        
        uint tokens = maxUserSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedUser = tokenIssuedUser.add(tokens);
        
        emit UserIssue(_to, tokens);
    }

    function airdropIssue(address _to) onlyOwner public
    {
        require(tokenIssuedAirdrop == 0);
        
        uint tokens = maxAirdropSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedAirdrop = tokenIssuedAirdrop.add(tokens);
        
        emit AirdropIssue(_to, tokens);
    }

    function marketIssue(address _to) onlyOwner public
    {
        require(tokenIssuedMarket == 0);
        
        uint tokens = maxMarketSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedMarket = tokenIssuedMarket.add(tokens);
        
        emit MarketIssue(_to, tokens);
    }    

    function rndIssue(address _to) onlyOwner public
    {
        require(tokenIssuedRnD == 0);
        
        uint tokens = maxRnDSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedRnD = tokenIssuedRnD.add(tokens);
        
        emit RnDIssue(_to, tokens);
    }

    function teamIssue(address _to) onlyOwner public
    {
        require(tokenIssuedTeam == 0);
        
        uint tokens = maxTeamSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedTeam = tokenIssuedTeam.add(tokens);
        
        emit TeamIssue(_to, tokens);
    }
    
    function reserveIssue(address _to) onlyOwner public
    {
        require(tokenIssuedReserve == 0);
        
        uint tokens = maxReserveSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedReserve = tokenIssuedReserve.add(tokens);
        
        emit ReserveIssue(_to, tokens);
    }
    
    function isTransferable() private view returns (bool)
    {
        if(tokenLock == false)
        {
            return true;
        }
        else if(msg.sender == owner)
        {
            return true;
        }
        return false;
    }
    
    function setTokenUnlock() onlyManager public
    {
        require(tokenLock == true);        
        tokenLock = false;
    }
    
    function setTokenLock() onlyManager public
    {
        require(tokenLock == false);
        tokenLock = true;
    }
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) onlyOwner public returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(manager, tokens);
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

    function close() onlyOwner public
    {
        selfdestruct(msg.sender);
    }
    
}