pragma solidity ^0.5.1;

// Made By Tom - <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="73071c1e33171605071c1c071b5d101c1e">[email&#160;protected]</a>

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
  	address public owner1;
  	address public owner2;

  	event OwnerTransferPropose(address indexed _from, address indexed _to);

  	modifier onlyOwner
	{
		require(msg.sender == owner1 || msg.sender == owner2);
		_;
  	}

  	constructor() public
	{
		owner1 = msg.sender;
  	}

  	function transferOwner1(address _to) onlyOwner public
	{
        require(_to != owner1);
        require(_to != owner2);
        require(_to != address(0x0));
    	owner1 = _to;
        
    	emit OwnerTransferPropose(msg.sender, _to);
  	}

  	function transferOwner2(address _to) onlyOwner public
	{
        require(_to != owner1);
        require(_to != owner2);
        require(_to != address(0x0));
    	owner2 = _to;
        
    	emit OwnerTransferPropose(msg.sender, _to);
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

    address private creator;
    
    string public name;
    uint public decimals;
    string public symbol;
    
    uint constant private E18 = 1000000000000000000;
    uint private constant month = 2592000;
    
    uint constant public maxTotalSupply     = 56200000000 * E18;
    
    uint constant public maxSaleSupply      = 19670000000 * E18;
    uint constant public maxBdevSupply      =  8430000000 * E18;
    uint constant public maxMktSupply       =  8430000000 * E18;
    uint constant public maxRndSupply       =  8430000000 * E18;
    uint constant public maxTeamSupply      =  2810000000 * E18;
    uint constant public maxReserveSupply   =  5620000000 * E18;
    uint constant public maxAdvisorSupply   =  2810000000 * E18;
    
    
    uint public totalTokenSupply;
    
    uint public tokenIssuedSale;
    uint public apIssuedSale;
    uint public bpIssuedSale;
    uint public pbIssuedSale;
    uint public tokenIssuedBdev;
    uint public tokenIssuedMkt;
    uint public tokenIssuedRnd;
    uint public tokenIssuedTeam;
    uint public tokenIssuedReserve;
    uint public tokenIssuedAdvisor;
    
    uint public burnTokenSupply;
    
    
    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;
    
    
    mapping (address => uint) public ap1;
    uint public apLock_1 = 1514818800;
    
    mapping (address => uint) public ap2;
    uint public apLock_2 = 1514818800;
    
    mapping (address => uint) public ap3;
    uint public apLock_3 = 1514818800;


    mapping (address => uint) public bp1;
    uint public bpLock_1 = 1514818800;
    
    mapping (address => uint) public bp2;
    uint public bpLock_2 = 1514818800;

    
    bool public tokenLock = true;
    bool public saleTime = true;
    
    event Refund(address indexed _from, address indexed _to, uint _value);
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
        creator     = msg.sender;
        
        totalTokenSupply = 0;
        
        tokenIssuedSale     = 0;
        tokenIssuedBdev     = 0;
        tokenIssuedMkt      = 0;
        tokenIssuedRnd      = 0;
        tokenIssuedTeam     = 0;
        tokenIssuedReserve  = 0;
        tokenIssuedAdvisor  = 0;
        
        require(maxTotalSupply == maxSaleSupply + maxBdevSupply + maxMktSupply + maxRndSupply + maxTeamSupply + maxReserveSupply + maxAdvisorSupply);
    }
    
    // ERC - 20 Interface -----

    function totalSupply() view public returns (uint) 
    {
        return totalTokenSupply;
    }
    
    function balanceOf(address _who) view public returns (uint) 
    {
        uint balance = balances[_who];
        balance = balance.add(ap1[_who] + ap2[_who] + ap3[_who]);
        balance = balance.add(bp1[_who] + bp2[_who]);
        
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
    
    function apSaleIssue(address _to, uint _value) onlyOwner public
    {
        uint tokens = _value * E18;
        require(maxSaleSupply <= tokenIssuedSale.add(tokens));
        
        balances[_to]   = balances[_to].add( tokens.mul(385)/1000 );
        ap1[_to]        = ap1[_to].add( tokens.mul(385)/1000 );
        ap2[_to]        = ap2[_to].add( tokens.mul(115)/1000 );
        ap3[_to]        = ap3[_to].add( tokens.mul(115)/1000 );
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedSale = tokenIssuedSale.add(tokens);
        apIssuedSale = apIssuedSale.add(tokens);
        
        emit SaleIssue(_to, tokens);
    }
    
    function bpSaleIssue(address _to, uint _value) onlyOwner public
    {
        uint tokens = _value * E18;
        require(maxSaleSupply <= tokenIssuedSale.add(tokens));
        
        balances[_to]   = balances[_to].add( tokens.mul(435)/1000 );
        bp1[_to]        = bp1[_to].add( tokens.mul(435)/1000 );
        bp2[_to]        = bp2[_to].add( tokens.mul(130)/1000 );
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedSale = tokenIssuedSale.add(tokens);
        bpIssuedSale = bpIssuedSale.add(tokens);
        
        emit SaleIssue(_to, tokens);
        
    }
    
    function saleIssue(address _to, uint _value) onlyOwner public
    {
        uint tokens = _value * E18;
        require(maxSaleSupply <= tokenIssuedSale.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedSale = tokenIssuedSale.add(tokens);
        pbIssuedSale = pbIssuedSale.add(tokens);
        
        emit SaleIssue(_to, tokens);
    }
    
    function bdevIssue(address _to, uint _value) onlyOwner public
    {
        uint tokens = _value * E18;
        require(maxBdevSupply <= tokenIssuedBdev.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedBdev = tokenIssuedBdev.add(tokens);
        
        emit BdevIssue(_to, tokens);
    }
    
    function mktIssue(address _to, uint _value) onlyOwner public
    {
        uint tokens = _value * E18;
        require(maxMktSupply <= tokenIssuedMkt.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedMkt = tokenIssuedMkt.add(tokens);
        
        emit MktIssue(_to, tokens);
    }
    
    function rndIssue(address _to, uint _value) onlyOwner public
    {
        uint tokens = _value * E18;
        require(maxRndSupply <= tokenIssuedRnd.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedRnd = tokenIssuedRnd.add(tokens);
        
        emit RndIssue(_to, tokens);
    }
    
    function reserveIssue(address _to, uint _value) onlyOwner public
    {
        uint tokens = _value * E18;
        require(maxReserveSupply <= tokenIssuedReserve.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedReserve = tokenIssuedReserve.add(tokens);
        
        emit ReserveIssue(_to, tokens);
    }
    
    function teamIssue(address _to, uint _value) onlyOwner public
    {
        uint tokens = _value * E18;
        require(maxTeamSupply <= tokenIssuedTeam.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedTeam = tokenIssuedTeam.add(tokens);
        
        emit TeamIssue(_to, tokens);
    }
    
    function advisorIssue(address _to, uint _value) onlyOwner public
    {
        uint tokens = _value * E18;
        require(maxAdvisorSupply <= tokenIssuedAdvisor.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
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
        else if(msg.sender == owner1 || msg.sender == owner2)
        {
            return true;
        }
        
        return false;
    }
    
    function tokenLockUp(bool _boolean) onlyOwner public
    {
        require(tokenLock == _boolean);
        
        tokenLock = _boolean;
    }
    
    function apLockUp(address _to) onlyOwner public
    {
        require(tokenLock == false);
        
        uint time = now;
        uint unlockTokens = 0;

        if(time >= apLock_1 && ap1[_to] > 0)
        {
            balances[_to] = balances[_to].add(ap1[_to]);
            unlockTokens = unlockTokens.add(ap1[_to]);
            ap1[_to] = 0;
        }
        
        if(time >= apLock_2 && ap2[_to] > 0)
        {
            balances[_to] = balances[_to].add(ap2[_to]);
            unlockTokens = unlockTokens.add(ap2[_to]);
            ap2[_to] = 0;
        }
        
        if(time >= apLock_3 && ap3[_to] > 0)
        {
            balances[_to] = balances[_to].add(ap3[_to]);
            unlockTokens = unlockTokens.add(ap3[_to]);
            ap3[_to] = 0;
        }
        
        emit TokenUnLock(_to, unlockTokens);
    }
    
    function bpLockUp(address _to) onlyOwner public
    {
        require(tokenLock == false);
        
        uint time = now;
        uint unlockTokens = 0;

        if(time >= bpLock_1 && bp1[_to] > 0)
        {
            balances[_to] = balances[_to].add(bp1[_to]);
            unlockTokens = unlockTokens.add(bp1[_to]);
            bp1[_to] = 0;
        }
        
        if(time >= bpLock_2 && bp2[_to] > 0)
        {
            balances[_to] = balances[_to].add(bp2[_to]);
            unlockTokens = unlockTokens.add(bp2[_to]);
            bp2[_to] = 0;
        }
        
        emit TokenUnLock(_to, unlockTokens);
    }
    
    // -----
    
    // ETC / Refund / Burn Function -----
    
    function () payable external
    {
        revert();
    }
    
    function endSale() onlyOwner public
    {
        require(saleTime == true);
        
        saleTime = false;
    }
    
    function withdrawTokens(address _to, uint _value) onlyOwner public
    {
        uint tokens = _value * E18;
        
        balances[_to] = balances[_to].add(tokens);
        totalTokenSupply = totalTokenSupply.add(tokens);
        
        emit Transfer(address(0x0), _to, tokens);
    }
    
    function setApTime(uint _time) onlyOwner public
    {
        require(tokenLock == true);
        apLock_1 = _time;
        apLock_2 = _time.add(month);
        apLock_3 = apLock_2.add(month);
    }
    
    function setBpTime(uint _time) onlyOwner public
    {
        require(tokenLock == true);
        bpLock_1 = _time;
        bpLock_2 = _time.add(month);
    }
    
    function refundApToken(address _from) onlyOwner public
    {
        require(balances[_from] > 0);
        require(tokenLock == true);
        require(saleTime == true);
        
        uint tokens = balances[_from].add(ap1[_from] + ap2[_from] + ap3[_from]);
        balances[_from] = 0;
        ap1[_from] = 0;
        ap2[_from] = 0;
        ap3[_from] = 0;
        
        totalTokenSupply = totalTokenSupply.sub(tokens);
        tokenIssuedSale = tokenIssuedSale.sub(tokens);
        apIssuedSale = apIssuedSale.sub(tokens);
        
        emit Refund(_from, msg.sender, tokens);
        emit Transfer( _from, msg.sender, tokens);
    }
    
    function refundBpToken(address _from) onlyOwner public
    {
        require(balances[_from] > 0);
        require(tokenLock == true);
        require(saleTime == true);
        
        uint tokens = balances[_from].add(bp1[_from] + bp2[_from]);
        balances[_from] = 0;
        bp1[_from] = 0;
        bp2[_from] = 0;
        
        totalTokenSupply = totalTokenSupply.sub(tokens);
        tokenIssuedSale = tokenIssuedSale.sub(tokens);
        bpIssuedSale = bpIssuedSale.sub(tokens);
        
        emit Refund(_from, msg.sender, tokens);
        emit Transfer( _from, msg.sender, tokens);
    }
    
    function refundToken(address _from) onlyOwner public
    {
        require(balances[_from] > 0);
        require(tokenLock == true);
        require(saleTime == true);
        
        uint tokens = balances[_from];
        balances[_from] = 0;
        
        totalTokenSupply = totalTokenSupply.sub(tokens);
        tokenIssuedSale = tokenIssuedSale.sub(tokens);
        pbIssuedSale = pbIssuedSale.sub(tokens);
        
        emit Refund(_from, msg.sender, tokens);
        emit Transfer( _from, address(0x0), tokens);
    }
    
    function burnToken(address _from) onlyOwner public
    {
        require(balances[_from] > 0);
        
        uint tokens = balances[_from];
        balances[_from] = 0;
        
        burnTokenSupply = burnTokenSupply.add(tokens);
        totalTokenSupply = totalTokenSupply.sub(tokens);
        
        emit Burn(_from, tokens);
        emit Transfer( _from, address(0x0), tokens);
    }
    
    function close() public
    {
        require(msg.sender == creator);
        selfdestruct(msg.sender);
    }
    
    // -----
}