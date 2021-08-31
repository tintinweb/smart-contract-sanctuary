/**
 *Submitted for verification at Etherscan.io on 2021-08-31
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

contract NKGENToken is ERC20Interface, OwnerHelper
{
    using SafeMath for uint;
    
    string public name;
    uint public decimals;
    string public symbol;
    
    uint constant private E18 = 1000000000000000000;
    
    // Total                                  100,000,000
    uint constant public maxTotalSupply     = 100000000 * E18;

    // Marketing                              30,000,000 (30%)
    uint constant public maxMarketSupply    = 30000000 * E18;

    // User Reward                            25,000,000 (25%)
    uint constant public maxUserSupply      = 25000000 * E18;

    // Platform Admin                         10,000,000 (10%)
    uint constant public maxPlatformAdmin   = 10000000 * E18;

    // Platform Maintenance and Repairment    10,000,000 (10%)
    uint constant public maxPlatformMain    = 10000000 * E18;

    // Platform Research and Development      10,000,000 (10%)
    uint constant public maxPlatformDev     = 10000000 * E18;

    // Contingency                            10,000,000 (10%)
    uint constant public maxContingency     = 10000000 * E18;   

    // Development Team                       5,000,000 (5%)
    uint constant public maxDevTeam         = 5000000 * E18;   
        

    uint public totalTokenSupply;

    uint public tokenIssuedMarket;
    uint public tokenIssuedUserReward;
    uint public tokenIssuedPlatformAdmin;
    uint public tokenIssuedPlatformMain;
    uint public tokenIssuedPlatformDev;
    uint public tokenIssuedContingency;
    uint public tokenIssuedDevTeam;     
    
    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;
      
    bool public tokenLock = false;

    event MarketIssue(address indexed _to, uint _tokens);
    event UserRewardIssue(address indexed _to, uint _tokens);
    event PlatformAdminIssue(address indexed _to, uint _tokens);
    event PlatformMainIssue(address indexed _to, uint _tokens);
    event PlatformDevIssue(address indexed _to, uint _tokens);
    event ContingencyIssue(address indexed _to, uint _tokens);
    event DevTeamIssue(address indexed _to, uint _tokens);

    
    constructor() public
    {
        name        = "NKGEN";
        decimals    = 18;
        symbol      = "NKGEN";
        
        totalTokenSupply = 100000000 * E18;
        balances[owner] = totalTokenSupply;

        tokenIssuedMarket         = 0;
        tokenIssuedUserReward     = 0;
        tokenIssuedPlatformAdmin  = 0;
        tokenIssuedPlatformMain   = 0;
        tokenIssuedPlatformDev    = 0;
        tokenIssuedContingency    = 0;
        tokenIssuedDevTeam        = 0;
        
        require(maxTotalSupply == maxMarketSupply + maxUserSupply + maxPlatformAdmin  + maxPlatformMain + maxPlatformDev + maxContingency + maxDevTeam);
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

    function marketIssue(address _to) onlyOwner public
    {
        require(tokenIssuedMarket == 0);
        
        uint tokens = maxMarketSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedMarket = tokenIssuedMarket.add(tokens);
        
        emit MarketIssue(_to, tokens);
    }   

    function userRewardIssue(address _to) onlyOwner public
    {
        require(tokenIssuedUserReward == 0);
        
        uint tokens = maxUserSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedUserReward = tokenIssuedUserReward.add(tokens);
        
        emit UserRewardIssue(_to, tokens);
    }

    function platfromAdminIssue(address _to) onlyOwner public
    {
        require(tokenIssuedPlatformAdmin == 0);
        
        uint tokens = maxPlatformAdmin;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedPlatformAdmin = tokenIssuedPlatformAdmin.add(tokens);
        
        emit PlatformAdminIssue(_to, tokens);
    }

    function platformMainIssue(address _to) onlyOwner public
    {
        require(tokenIssuedPlatformMain == 0);
        
        uint tokens = maxPlatformMain;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedPlatformMain = tokenIssuedPlatformMain.add(tokens);
        
        emit PlatformMainIssue(_to, tokens);
    }

    function platformDevIssue(address _to) onlyOwner public
    {
        require(tokenIssuedPlatformDev == 0);
        
        uint tokens = maxPlatformDev;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedPlatformDev = tokenIssuedPlatformDev.add(tokens);
        
        emit PlatformDevIssue(_to, tokens);
    }
    
    function contingencyIssue(address _to) onlyOwner public
    {
        require(tokenIssuedContingency == 0);
        
        uint tokens = maxContingency;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedContingency = tokenIssuedContingency.add(tokens);
        
        emit ContingencyIssue(_to, tokens);
    }

    function devTeamIssue(address _to) onlyOwner public
    {
        require(tokenIssuedDevTeam == 0);
        
        uint tokens = maxDevTeam;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedDevTeam = tokenIssuedDevTeam.add(tokens);
        
        emit DevTeamIssue(_to, tokens);
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
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) onlyOwner public returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
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