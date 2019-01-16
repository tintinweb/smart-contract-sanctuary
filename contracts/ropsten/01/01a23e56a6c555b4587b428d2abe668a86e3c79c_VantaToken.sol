pragma solidity ^0.5.1;

// Made By Tom - <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="23574c4e63474655574c4c574b0d404c4e">[email&#160;protected]</a>

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
  	address public master;
  	address public issuer;
  	address public manager;

  	event ChangeMaster(address indexed _from, address indexed _to);
  	event ChangeIssuer(address indexed _from, address indexed _to);
  	event ChangeManager(address indexed _from, address indexed _to);

  	modifier onlyMaster
	{
		require(msg.sender == master);
		_;
  	}
  	
  	modifier onlyIssuer
	{
		require(msg.sender == issuer);
		_;
  	}
  	
  	modifier onlyManager
	{
		require(msg.sender == manager);
		_;
  	}

  	constructor() public
	{
		master = msg.sender;
  	}
  	
  	function transferMastership(address _to) onlyMaster public
  	{
        	require(_to != master);
        	require(_to != issuer);
        	require(_to != manager);
        	require(_to != address(0x0));

		address from = master;
  	    	master = _to;
  	    
  	    	emit ChangeMaster(from, _to);
  	}

  	function transferIssuer(address _to) onlyMaster public
	{
	        require(_to != master);
        	require(_to != issuer);
        	require(_to != manager);
	        require(_to != address(0x0));

		address from = issuer;        
	    	issuer = _to;
        
    		emit ChangeIssuer(from, _to);
  	}

  	function transferManager(address _to) onlyMaster public
	{
	        require(_to != master);
	        require(_to != issuer);
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

contract VantaToken is ERC20Interface, OwnerHelper
{
    using SafeMath for uint;
    
    string public name;
    uint public decimals;
    string public symbol;
    
    uint constant private E18 = 1000000000000000000;
    // uint constant private month = 2592000;
    // test
    uint constant private month = 60;

    uint constant public maxTotalSupply     = 56200000000 * E18;
    
    uint constant public maxSaleSupply      = 19670000000 * E18;
    uint constant public maxBdevSupply      =  8430000000 * E18;
    uint constant public maxMktSupply       =  8430000000 * E18;
    uint constant public maxRndSupply       =  8430000000 * E18;
    uint constant public maxTeamSupply      =  5620000000 * E18;
    uint constant public maxReserveSupply   =  2810000000 * E18;
    uint constant public maxAdvisorSupply   =  2810000000 * E18;
    
    uint constant public teamVestingSupplyPerTime       = 351250000 * E18;
    uint constant public advisorVestingSupplyPerTime    = 702500000 * E18;
    uint constant public teamVestingDate                = 2 * month;
    uint constant public teamVestingTime                = 16;
    uint constant public advisorVestingDate             = 3 * month;
    uint constant public advisorVestingTime             = 4;
    
    uint public totalTokenSupply;
    
    uint public tokenIssuedSale;
    uint public privateIssuedSale;
    uint public publicIssuedSale;
    uint public tokenIssuedBdev;
    uint public tokenIssuedMkt;
    uint public tokenIssuedRnd;
    uint public tokenIssuedTeam;
    uint public tokenIssuedReserve;
    uint public tokenIssuedAdvisor;
    
    uint public burnTokenSupply;
    
    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;
    
    mapping (address => uint) public privateFirstWallet;
    
    mapping (address => uint) public privateSecondWallet;
    
    mapping (uint => uint) public teamVestingTimeAtSupply;
    mapping (uint => uint) public advisorVestingTimeAtSupply;
    
    bool public tokenLock = true;
    bool public saleTime = true;
    uint public endSaleTime = 0;
    
    event Burn(address indexed _from, uint _value);
    
    event SaleIssue(address indexed _to, uint _tokens);
    event BdevIssue(address indexed _to, uint _tokens);
    event MktIssue(address indexed _to, uint _tokens);
    event RndIssue(address indexed _to, uint _tokens);
    event TeamIssue(address indexed _to, uint _tokens);
    event ReserveIssue(address indexed _to, uint _tokens);
    event AdvisorIssue(address indexed _to, uint _tokens);
    
    event TokenUnLock(address indexed _to, uint _tokens);
    
    constructor() public
    {
        name        = "VANTA Token";
        decimals    = 18;
        symbol      = "VNT";
        
        totalTokenSupply = 0;
        
        tokenIssuedSale     = 0;
        tokenIssuedBdev     = 0;
        tokenIssuedMkt      = 0;
        tokenIssuedRnd      = 0;
        tokenIssuedTeam     = 0;
        tokenIssuedReserve  = 0;
        tokenIssuedAdvisor  = 0;
        
        require(maxTotalSupply == maxSaleSupply + maxBdevSupply + maxMktSupply + maxRndSupply + maxTeamSupply + maxReserveSupply + maxAdvisorSupply);
        
        require(maxTeamSupply == teamVestingSupplyPerTime * teamVestingTime);
        require(maxAdvisorSupply == advisorVestingSupplyPerTime * advisorVestingTime);
    }
    
    // ERC - 20 Interface -----

    function totalSupply() view public returns (uint) 
    {
        return totalTokenSupply;
    }
    
    function balanceOf(address _who) view public returns (uint) 
    {
        uint balance = balances[_who];
        balance = balance.add(privateFirstWallet[_who] + privateSecondWallet[_who]);
        
        return balance;
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
    
    // -----
    
    // Issue Function -----
    
    function privateIssue(address _to, uint _value) onlyIssuer public
    {
        uint tokens = _value * E18;
        require(maxSaleSupply >= tokenIssuedSale.add(tokens));
        
        balances[_to]                   = balances[_to].add( tokens.mul(435)/1000 );
        privateFirstWallet[_to]         = privateFirstWallet[_to].add( tokens.mul(435)/1000 );
        privateSecondWallet[_to]        = privateSecondWallet[_to].add( tokens.mul(130)/1000 );
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedSale = tokenIssuedSale.add(tokens);
        privateIssuedSale = privateIssuedSale.add(tokens);
        
        emit SaleIssue(_to, tokens);
    }
    
    function publicIssue(address _to, uint _value) onlyIssuer public
    {
        uint tokens = _value * E18;
        require(maxSaleSupply >= tokenIssuedSale.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedSale = tokenIssuedSale.add(tokens);
        publicIssuedSale = publicIssuedSale.add(tokens);
        
        emit SaleIssue(_to, tokens);
    }
    
    function bdevIssue(address _to, uint _value) onlyIssuer public
    {
        uint tokens = _value * E18;
        require(maxBdevSupply >= tokenIssuedBdev.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedBdev = tokenIssuedBdev.add(tokens);
        
        emit BdevIssue(_to, tokens);
    }
    
    function mktIssue(address _to, uint _value) onlyIssuer public
    {
        uint tokens = _value * E18;
        require(maxMktSupply >= tokenIssuedMkt.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedMkt = tokenIssuedMkt.add(tokens);
        
        emit MktIssue(_to, tokens);
    }
    
    function rndIssue(address _to, uint _value) onlyIssuer public
    {
        uint tokens = _value * E18;
        require(maxRndSupply >= tokenIssuedRnd.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedRnd = tokenIssuedRnd.add(tokens);
        
        emit RndIssue(_to, tokens);
    }
    
    function reserveIssue(address _to, uint _value) onlyIssuer public
    {
        uint tokens = _value * E18;
        require(maxReserveSupply >= tokenIssuedReserve.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedReserve = tokenIssuedReserve.add(tokens);
        
        emit ReserveIssue(_to, tokens);
    }
    
    // ----
    
    // Vesting Issue Function -----
    
    function teamIssueVesting(address _to, uint _time) onlyIssuer public
    {
        require(saleTime == false);
        require(teamVestingTime >= _time);
        
        uint time = now;
        require( ( ( endSaleTime + (_time * teamVestingDate) ) < time ) && ( teamVestingTimeAtSupply[_time] > 0 ) );
        
        uint tokens = teamVestingTimeAtSupply[_time];

        require(maxTeamSupply >= tokenIssuedTeam.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        teamVestingTimeAtSupply[_time] = 0;
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedTeam = tokenIssuedTeam.add(tokens);
        
        emit TeamIssue(_to, tokens);
    }
    
    function advisorIssueVesting(address _to, uint _time) onlyIssuer public
    {
        require(saleTime == false);
        require(advisorVestingTime >= _time);
        
        uint time = now;
        require( ( ( endSaleTime + (_time * advisorVestingDate) ) < time ) && ( advisorVestingTimeAtSupply[_time] > 0 ) );
        
        uint tokens = advisorVestingTimeAtSupply[_time];
        
        require(maxAdvisorSupply >= tokenIssuedAdvisor.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        advisorVestingTimeAtSupply[_time] = 0;
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedAdvisor = tokenIssuedAdvisor.add(tokens);
        
        emit AdvisorIssue(_to, tokens);
    }
    
    // -----
    
    // Lock Function -----
    
    function isTransferable() private view returns (bool)
    {
        if(tokenLock == false)
        {
            return true;
        }
        else if(msg.sender == manager)
        {
            return true;
        }
        
        return false;
    }
    
    function setTokenUnlock() onlyManager public
    {
        require(tokenLock == true);
        require(saleTime == false);
        
        tokenLock = false;
    }
    
    function setTokenLock() onlyManager public
    {
        require(tokenLock == false);
        
        tokenLock = true;
    }
    
    function privateUnlock(address _to) onlyManager public
    {
        require(tokenLock == false);
        require(saleTime == false);
        
        uint time = now;
        uint unlockTokens = 0;

        if( (time >= endSaleTime.add(month)) && (privateFirstWallet[_to] > 0) )
        {
            balances[_to] = balances[_to].add(privateFirstWallet[_to]);
            unlockTokens = unlockTokens.add(privateFirstWallet[_to]);
            privateFirstWallet[_to] = 0;
        }
        
        if( (time >= endSaleTime.add(month * 2)) && (privateSecondWallet[_to] > 0) )
        {
            balances[_to] = balances[_to].add(privateSecondWallet[_to]);
            unlockTokens = unlockTokens.add(privateSecondWallet[_to]);
            privateSecondWallet[_to] = 0;
        }
        
        emit TokenUnLock(_to, unlockTokens);
    }
    
    // -----
    
    // ETC / Burn Function -----
    
    function () payable external
    {
        revert();
    }
    
    function endSale() onlyManager public
    {
        require(saleTime == true);
        
        saleTime = false;
        
        uint time = now;
        
        endSaleTime = time;
        
        for(uint i = 1; i <= teamVestingTime; i++)
        {
            teamVestingTimeAtSupply[i] = teamVestingTimeAtSupply[i].add(teamVestingSupplyPerTime);
        }
        
        for(uint i = 1; i <= advisorVestingTime; i++)
        {
            advisorVestingTimeAtSupply[i] = advisorVestingTimeAtSupply[i].add(advisorVestingSupplyPerTime);
        }
    }
    
    function withdrawTokens(address _contract, uint _decimals, uint _value) onlyManager public
    {

        if(_contract == address(0x0))
        {
            uint eth = _value.mul(10 ** _decimals);
            msg.sender.transfer(eth);
        }
        else
        {
            uint tokens = _value.mul(10 ** _decimals);
            ERC20Interface(_contract).transfer(msg.sender, tokens);
            
            emit Transfer(address(0x0), msg.sender, tokens);
        }
    }
    
    function burnToken(uint _value) onlyManager public
    {
        uint tokens = _value * E18;
        
        require(balances[msg.sender] >= tokens);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        
        burnTokenSupply = burnTokenSupply.add(tokens);
        totalTokenSupply = totalTokenSupply.sub(tokens);
        
        emit Burn(msg.sender, tokens);
    }
    
    function close() onlyMaster public
    {
        selfdestruct(msg.sender);
    }
    
    // -----
}