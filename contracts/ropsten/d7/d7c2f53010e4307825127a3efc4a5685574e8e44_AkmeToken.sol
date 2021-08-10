/**
 *Submitted for verification at Etherscan.io on 2021-08-10
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

interface IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract AkmeToken is ERC20Interface, OwnerHelper, IERC20Metadata
{
    using SafeMath for uint;
    
    string public name;
    uint8 public decimals;
    string public symbol;

    // Founder
    address private founder;
    
    // Total
    uint public totalTokenSupply;
    uint public burnTokenSupply;

    // Supply

    uint constant public maxTotalSupply = 2000000000 * E18;
    uint constant public maxAdminSupply = 200000000 * E18; // 10%
    uint constant public maxResearchSupply = 200000000 * E18; // 10%
    uint constant public maxMktSupply = 240000000 * E18; // 12%
    uint constant public maxUserRewardSupply = 1300000000 * E18; // 65%
    uint constant public maxContingencySupply = 60000000 * E18; // 3%

    uint public tokenIssuedAdmin;
    uint public tokenIssuedResearch;
    uint public tokenIssuedMkt;
    uint public tokenIssuedUserReward;
    uint public tokenIssuedContingency;

    // withdraw request

    mapping (address => mapping ( uint => bool)) public withdrawRequestFlag; // contract => value
    mapping (address => mapping ( uint => uint)) public lastWithdrawRequestTime; // contract => value
    uint public constant WITHDRAW_REQUEST_DELAY_TIME = 6 hours;
    uint public constant WITHDRAW_REQUEST_MAXIMUM_DELAY_TIME = 7 days;

    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;
    
    bool public tokenLock = false; // unLock : false, Lock : true

    // Token Total
    uint constant private E18 = 1000000000000000000;

    event Burn(address indexed _from, uint _tokens);
    event TokenUnlock(address indexed _to, uint _tokens);

    event AdminIssue(address indexed _to, uint _tokens);
    event ResearchIssue(address indexed _to, uint _tokens);
    event MktIssue(address indexed _to, uint _tokens);
    event UserRewardIssue(address indexed _to, uint _tokens);
    event ContingencyIssue(address indexed _to, uint _tokens);

    constructor(address _founder, uint _totalTokenSupply) public {
        name        = 'AK Messenger';
        decimals    = 18;
        symbol      = 'AKME';

        founder = _founder;
        totalTokenSupply  = _totalTokenSupply * E18;
        burnTokenSupply     = 0;

        tokenIssuedAdmin = 0;
        tokenIssuedResearch = 0;
        tokenIssuedMkt = 0;
        tokenIssuedUserReward = 0;
        tokenIssuedContingency = 0;

        balances[founder] = totalTokenSupply;
        emit Transfer(address(0), founder, totalTokenSupply);
    }

    // ERC - 20 Interface -----
    modifier notLocked {
        require(isTransferable() == true);
        _;
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
        emit Approval(_from, msg.sender, approvals[_from][msg.sender]);
        return true;
    }
    
    // Lock Function -----
    
    function isTransferable() private view returns (bool)
    {
        if(tokenLock == false) {
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

    function withdrawTokenRequest(address _contract, uint _value) onlyOwner public {
        withdrawRequestFlag[_contract][_value] = true;
        lastWithdrawRequestTime[_contract][_value] = block.timestamp;
    }

    function withdrawTokens(address _contract, uint _value) onlyOwner public
    {
        require(withdrawRequestFlag[_contract][_value],"Withdraw request first");
        require(block.timestamp >= lastWithdrawRequestTime[_contract][_value].add(WITHDRAW_REQUEST_DELAY_TIME), "request hasn't surpassed time");
        require(block.timestamp <= lastWithdrawRequestTime[_contract][_value].add(WITHDRAW_REQUEST_MAXIMUM_DELAY_TIME), "request is stale");

        withdrawRequestFlag[_contract][_value] = false;
        
        if(_contract == address(0x0))
        {
            uint eth = _value.mul(10 ** uint256(decimals));
            msg.sender.transfer(eth);
        }
        else
        {
            uint8 tokenDecimals = IERC20Metadata(_contract).decimals();
            uint tokens = _value.mul(10 ** uint256(tokenDecimals));
            ERC20Interface(_contract).transfer(msg.sender, tokens);
            
            emit Transfer(address(0x0), msg.sender, tokens);
        }
    }

    function burnToken(uint _value) onlyOwner public
    {
        uint tokens = _value.mul(10 ** uint256(decimals));
        
        require(balances[msg.sender] >= tokens);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        
        burnTokenSupply = burnTokenSupply.add(tokens);
        totalTokenSupply = totalTokenSupply.sub(tokens);
        
        emit Transfer(msg.sender, address(0), tokens);
        emit Burn(msg.sender, tokens);
    }    
    
    function close() onlyOwner public
    {
        selfdestruct(msg.sender);
    }

    // token issue functions

    function adminIssue(address _to) onlyOwner public 
    {
        require(tokenIssuedAdmin == 0);

        uint tokens = maxAdminSupply;

        balances[_to] = balances[_to].add(tokens);

        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedAdmin = tokenIssuedAdmin.add(tokens);

        emit Transfer(address(0), _to, tokens);
        emit AdminIssue(_to, tokens);
    }

    function researchIssue(address _to) onlyOwner public 
    {
        require(tokenIssuedResearch == 0);

        uint tokens = maxResearchSupply;

        balances[_to] = balances[_to].add(tokens);

        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedResearch = tokenIssuedResearch.add(tokens);

        emit Transfer(address(0), _to, tokens);
        emit ResearchIssue(_to, tokens);
    }

    function mktIssue(address _to) onlyOwner public 
    {
        require(tokenIssuedMkt == 0);

        uint tokens = maxMktSupply;

        balances[_to] = balances[_to].add(tokens);

        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedMkt = tokenIssuedMkt.add(tokens);

        emit Transfer(address(0), _to, tokens);
        emit MktIssue(_to, tokens);
    }

    function userRewardIssue(address _to) onlyOwner public 
    {
        require(tokenIssuedUserReward == 0);

        uint tokens = maxUserRewardSupply;
        balances[_to] = balances[_to].add(tokens);

        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedUserReward = tokenIssuedUserReward.add(tokens);
    
        emit Transfer(address(0), _to, tokens);
        emit UserRewardIssue(_to, tokens);
    }

    function contingencyIssue(address _to) onlyOwner public 
    {
        require(tokenIssuedContingency == 0);

        uint tokens = maxContingencySupply;
        balances[_to] = balances[_to].add(tokens);

        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedContingency = tokenIssuedContingency.add(tokens);
      
        emit Transfer(address(0), _to, tokens);
        emit ContingencyIssue(_to, tokens);
    }
}