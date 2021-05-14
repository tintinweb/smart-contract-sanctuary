/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(msg.sender == owner, "ERROR: Not owner");
        _;
    }

    modifier onlyManager
    {
        require(msg.sender == manager, "ERROR: Not manager");
        _;
    }

    constructor()
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

abstract contract ERC20Interface
{
    event Transfer( address indexed _from, address indexed _to, uint _value);
    event Approval( address indexed _owner, address indexed _spender, uint _value);

    function totalSupply() view virtual public returns (uint _supply);
    function balanceOf( address _who ) virtual public view returns (uint _value);
    function transfer( address _to, uint _value) virtual public returns (bool _success);
    function approve( address _spender, uint _value ) virtual public returns (bool _success);
    function allowance( address _owner, address _spender ) virtual public view returns (uint _allowance);
    function transferFrom( address _from, address _to, uint _value) virtual public returns (bool _success);
}

contract ARTIC is ERC20Interface, OwnerHelper
{
    using SafeMath for uint;

    string public name;
    uint public decimals;
    string public symbol;

    uint constant private E18 = 1000000000000000000;
    uint constant private month = 2592000;

    // Total                                         100,000,000
    uint constant public maxTotalSupply           = 100000000 * E18;
    // Sale                                         10,000,000 (10%)
    uint constant public maxSaleSupply            = 10000000 * E18;
    // Marketing                                    25,000,000 (25%)
    uint constant public maxMktSupply             = 25000000 * E18;
    // Development                                  12,000,000 (12%)
    uint constant public maxDevSupply             = 12000000 * E18;
    // EcoSystem                                    20,000,000 (20%)
    uint constant public maxEcoSupply             = 20000000 * E18;
    // Legal & Compliance                           15,000,000 (15%)
    uint constant public maxLegalComplianceSupply = 15000000 * E18;
    // Team                                         5,000,000 (5%)
    uint constant public maxTeamSupply            = 5000000 * E18;
    // Advisors                                     3,000,000 (3%)
    uint constant public maxAdvisorSupply         = 3000000 * E18;
    // Reserve                                      10,000,000 (10%)
    uint constant public maxReserveSupply         = 10000000 * E18;

    // Lock
    uint constant public teamVestingSupply = 500000 * E18;
    uint constant public teamVestingLockDate =  12 * month;
    uint constant public teamVestingTime = 10;

    uint constant public advisorVestingSupply = 750000 * E18;
    uint constant public advisorVestingTime = 4;

    uint public totalTokenSupply;
    uint public tokenIssuedSale;
    uint public tokenIssuedMkt;
    uint public tokenIssuedDev;
    uint public tokenIssuedEco;
    uint public tokenIssuedLegalCompliance;
    uint public tokenIssuedTeam;
    uint public tokenIssuedAdv;
    uint public tokenIssuedRsv;

    uint public burnTokenSupply;

    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;

    mapping (uint => uint) public tmVestingTimer;
    mapping (uint => uint) public tmVestingBalances;
    mapping (uint => uint) public advVestingTimer;
    mapping (uint => uint) public advVestingBalances;

    bool public tokenLock = true;
    bool public saleTime = true;
    uint public endSaleTime = 0;

    event SaleIssue(address indexed _to, uint _tokens);
    event DevIssue(address indexed _to, uint _tokens);
    event EcoIssue(address indexed _to, uint _tokens);
    event LegalComplianceIssue(address indexed _to, uint _tokens);
    event MktIssue(address indexed _to, uint _tokens);
    event RsvIssue(address indexed _to, uint _tokens);
    event TeamIssue(address indexed _to, uint _tokens);
    event AdvIssue(address indexed _to, uint _tokens);

    event Burn(address indexed _from, uint _tokens);

    event TokenUnlock(address indexed _to, uint _tokens);
    event EndSale(uint _date);

    constructor()
    {
        name        = "ARTIC";
        decimals    = 18;
        symbol      = "ARTIC";

        totalTokenSupply = maxTotalSupply;
        balances[owner] = totalTokenSupply;

        tokenIssuedSale     = 0;
        tokenIssuedDev      = 0;
        tokenIssuedEco      = 0;
        tokenIssuedLegalCompliance = 0;
        tokenIssuedMkt      = 0;
        tokenIssuedRsv      = 0;
        tokenIssuedTeam     = 0;
        tokenIssuedAdv      = 0;

        burnTokenSupply     = 0;

        require(maxTeamSupply == teamVestingSupply.mul(teamVestingTime), "ERROR: MaxTeamSupply");
        require(maxAdvisorSupply == advisorVestingSupply.mul(advisorVestingTime), "ERROR: MaxAdvisorSupply");
        require(maxTotalSupply == maxSaleSupply + maxDevSupply + maxEcoSupply + maxMktSupply + maxReserveSupply + maxTeamSupply + maxAdvisorSupply + maxLegalComplianceSupply, "ERROR: MaxTotalSupply");
    }

    function totalSupply() view override public returns (uint)
    {
        return totalTokenSupply;
    }

    function balanceOf(address _who) view override public returns (uint)
    {
        return balances[_who];
    }

    function transfer(address _to, uint _value) override public returns (bool)
    {
        require(isTransferable() == true);
        require(balances[msg.sender] >= _value);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint _value) override public returns (bool)
    {
        require(isTransferable() == true);
        require(balances[msg.sender] >= _value);

        approvals[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) view override public returns (uint)
    {
        return approvals[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint _value) override public returns (bool)
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

    function saleIssue(address _to) onlyOwner public
    {
        require(tokenIssuedSale == 0);
        uint tokens = maxSaleSupply;

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);

        tokenIssuedSale = tokenIssuedSale.add(tokens);

        emit SaleIssue(_to, tokens);
    }

    function devIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedDev == 0);

        uint tokens = maxDevSupply;

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);

        tokenIssuedDev = tokenIssuedDev.add(tokens);

        emit DevIssue(_to, tokens);
    }

    function ecoIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedEco == 0);

        uint tokens = maxEcoSupply;

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);

        tokenIssuedEco = tokenIssuedEco.add(tokens);

        emit EcoIssue(_to, tokens);
    }

    function mktIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedMkt == 0);

        uint tokens = maxMktSupply;

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);

        tokenIssuedMkt = tokenIssuedMkt.add(tokens);

        emit MktIssue(_to, tokens);
    }
    
    function legalComplianceIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedLegalCompliance == 0);

        uint tokens = maxLegalComplianceSupply;

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);

        tokenIssuedLegalCompliance = tokenIssuedLegalCompliance.add(tokens);

        emit LegalComplianceIssue(_to, tokens);
    }

    function rsvIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedRsv == 0);

        uint tokens = maxReserveSupply;

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);

        tokenIssuedRsv = tokenIssuedRsv.add(tokens);

        emit RsvIssue(_to, tokens);
    }

    function teamIssue(address _to, uint _time /* 몇 번째 지급인지 */) onlyOwner public
    {
        require(saleTime == false);
        require( _time < teamVestingTime);

        uint nowTime = block.timestamp;
        require( nowTime > tmVestingTimer[_time] );

        uint tokens = teamVestingSupply;

        require(tokens == tmVestingBalances[_time]);
        require(maxTeamSupply >= tokenIssuedTeam.add(tokens));

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        tmVestingBalances[_time] = 0;

        tokenIssuedTeam = tokenIssuedTeam.add(tokens);

        emit TeamIssue(_to, tokens);
    }

    function advisorIssue(address _to, uint _time) onlyOwner public
    {
        require(saleTime == false);
        require( _time < advisorVestingTime);

        uint nowTime = block.timestamp;
        require( nowTime > advVestingTimer[_time] );

        uint tokens = advisorVestingSupply;

        require(tokens == advVestingBalances[_time]);
        require(maxAdvisorSupply >= tokenIssuedAdv.add(tokens));

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        advVestingBalances[_time] = 0;

        tokenIssuedAdv = tokenIssuedAdv.add(tokens);

        emit AdvIssue(_to, tokens);
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
        require(saleTime == false);

        tokenLock = false;
    }

    function setTokenLock() onlyManager public
    {
        require(tokenLock == false);

        tokenLock = true;
    }

    function endSale() onlyOwner public
    {
        require(saleTime == true);
        require(maxSaleSupply == tokenIssuedSale);

        saleTime = false;

        uint nowTime = block.timestamp;
        endSaleTime = nowTime;

        for(uint i = 0; i < teamVestingTime; i++)
        {
            tmVestingTimer[i] = endSaleTime + teamVestingLockDate + (i * month);
            tmVestingBalances[i] = teamVestingSupply;
        }

        for(uint i = 0; i < advisorVestingTime; i++)
        {
            advVestingTimer[i] = endSaleTime + (3 * i * month);
            advVestingBalances[i] = advisorVestingSupply;
        }

        emit EndSale(endSaleTime);
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) onlyOwner public returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(manager, tokens);
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

    function close() onlyOwner public
    {
        selfdestruct(payable(msg.sender));
    }
}