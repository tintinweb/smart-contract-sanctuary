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

contract SPRINT is ERC20Interface, OwnerHelper
{
    using SafeMath for uint;
    
    string public name;
    uint public decimals;
    string public symbol;
    
    uint constant private E18 = 1000000000000000000;
    
    // Total                                  2,000,000,000
    uint constant public maxTotalSupply     = 2000000000 * E18;

    // Marketing                              500,000,000 (25%)
    uint constant public maxMktSupply       = 500000000 * E18;

    // EcoSystem                              440,000,000 (22%)
    uint constant public maxEcoSupply       = 440000000 * E18;

    // Bounty                                 300,000,000 (15%)
    uint constant public maxBountySupply    = 300000000 * E18;

    // Tech Development                       200,000,000 (10%)
    uint constant public maxTechSupply      = 200000000 * E18;

    // Founder                                200,000,000 (10%)
    uint constant public maxFounderSupply   = 200000000 * E18;

    // Advisors                               140,000,000 (7%)
    uint constant public maxAdvisorSupply   = 140000000 * E18;

    // Team                                   120,000,000 (6%)
    uint constant public maxTeamSupply      = 120000000 * E18;

     // Sale Supply                           100,000,000 (5%)
    uint constant public maxSaleSupply      = 100000000 * E18;   
        

    uint public totalTokenSupply;

    uint public tokenIssuedMkt;
    uint public tokenIssuedEco;
    uint public tokenIssuedBounty;
    uint public tokenIssuedTech;
    uint public tokenIssuedFnd;
    uint public tokenIssuedAdv;
    uint public tokenIssuedTeam;
    uint public tokenIssuedSale;    
    
    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;
      
    // bool public tokenLock = false;


    event MktIssue(address indexed _to, uint _tokens);
    event EcoIssue(address indexed _to, uint _tokens);
    event TechIssue(address indexed _to, uint _tokens);
    event FounderIssue(address indexed _to, uint _tokens);
    event TeamIssue(address indexed _to, uint _tokens);
    event AdvIssue(address indexed _to, uint _tokens);
    event BountyIssue(address indexed _to, uint _tokens);
    event SaleIssue(address indexed _to, uint _tokens);

    
    constructor() public
    {
        name        = "SPRINT";
        decimals    = 18;
        symbol      = "SPRT";
        
        totalTokenSupply = 2000000000 * E18;
        balances[owner] = totalTokenSupply;


        tokenIssuedMkt      = 0;
        tokenIssuedEco      = 0;
        tokenIssuedTech     = 0;
        tokenIssuedFnd      = 0;
        tokenIssuedTeam     = 0;
        tokenIssuedAdv      = 0;
        tokenIssuedBounty   = 0;
        tokenIssuedSale     = 0;
        
        require(maxTotalSupply == maxSaleSupply + maxMktSupply + maxEcoSupply + maxTechSupply + maxFounderSupply + maxTeamSupply + maxAdvisorSupply + maxBountySupply);
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
        // require(isTransferable() == true);
        require(balances[msg.sender] >= _value);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint _value) public returns (bool)
    {
        // require(isTransferable() == true);
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
        // require(isTransferable() == true);
        require(balances[_from] >= _value);
        require(approvals[_from][msg.sender] >= _value);
        
        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to]  = balances[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    function mktIssue(address _to) onlyOwner public
    {
        require(tokenIssuedMkt == 0);
        
        uint tokens = maxMktSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedMkt = tokenIssuedMkt.add(tokens);
        
        emit MktIssue(_to, tokens);
    }

    function ecoIssue(address _to) onlyOwner public
    {
        require(tokenIssuedEco == 0);
        
        uint tokens = maxEcoSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedEco = tokenIssuedEco.add(tokens);
        
        emit EcoIssue(_to, tokens);
    }

    function bountyIssue(address _to) onlyOwner public
    {
        require(tokenIssuedBounty == 0);
        
        uint tokens = maxBountySupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedBounty = tokenIssuedBounty.add(tokens);
        
        emit BountyIssue(_to, tokens);
    }    

    function techIssue(address _to) onlyOwner public
    {
        require(tokenIssuedTech == 0);
        
        uint tokens = maxTechSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedTech = tokenIssuedTech.add(tokens);
        
        emit TechIssue(_to, tokens);
    }

    function founderIssue(address _to) onlyOwner public
    {
        require(tokenIssuedFnd == 0);
        
        uint tokens = maxFounderSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedFnd = tokenIssuedFnd.add(tokens);
        
        emit FounderIssue(_to, tokens);
    }

    function advisorIssue(address _to) onlyOwner public
    {
        require(tokenIssuedAdv == 0);
        
        uint tokens = maxAdvisorSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedAdv = tokenIssuedAdv.add(tokens);
        
        emit AdvIssue(_to, tokens);
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
    
    function saleIssue(address _to) onlyOwner public
    {
        require(tokenIssuedSale == 0);
        
        uint tokens = maxSaleSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedSale = tokenIssuedSale.add(tokens);
        
        emit SaleIssue(_to, tokens);
    }
    
    // function isTransferable() private view returns (bool)
    // {
    //     if(tokenLock == false)
    //     {
    //         return true;
    //     }
    //     else if(msg.sender == owner)
    //     {
    //         return true;
    //     }
    //     return false;
    // }
    
    // function setTokenUnlock() onlyManager public
    // {
    //     require(tokenLock == true);        
    //     tokenLock = false;
    // }
    
    // function setTokenLock() onlyManager public
    // {
    //     require(tokenLock == false);
    //     tokenLock = true;
    // }
    
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