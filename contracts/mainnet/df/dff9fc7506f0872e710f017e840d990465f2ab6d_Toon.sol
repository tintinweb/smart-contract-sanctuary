/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

contract Toon is ERC20Interface, OwnerHelper
{
    string public name;
    uint public decimals;
    string public symbol;

    uint constant private E18 = 1000000000000000000;
    uint constant private month = 2592000;

    // Total                                        10,000,000,000
    uint constant public maxTotalSupply           = 10000000000 * E18;
    // Sale                                         1,000,000,000 (10%)
    uint constant public maxSaleSupply            = 1000000000 * E18;
    // Marketing                                    2,500,000,000 (25%)
    uint constant public maxMktSupply             = 2500000000 * E18;
    // Development                                  1,500,000,000 (15%)
    uint constant public maxDevSupply             = 1500000000 * E18;
    // EcoSystem                                    2,500,000,000 (25%)
    uint constant public maxEcoSupply             = 2500000000 * E18;
    // Team                                         1,000,000,000 (10%)
    uint constant public maxTeamSupply            = 1000000000 * E18;
    // Advisors                                     500,000,000 (5%)
    uint constant public maxAdvisorSupply         = 500000000 * E18;
    // Reserve                                      1,000,000,000 (10%)
    uint constant public maxReserveSupply         = 1000000000 * E18;

    // Lock
    uint constant public teamVestingSupply = 100000000 * E18;
    uint constant public teamVestingLockDate =  12 * month;
    uint constant public teamVestingTime = 10;

    uint constant public advisorVestingSupply = 125000000 * E18;
    uint constant public advisorVestingTime = 4;

    uint public totalTokenSupply;
    uint public tokenIssuedSale;
    uint public tokenIssuedMkt;
    uint public tokenIssuedDev;
    uint public tokenIssuedEco;
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

    event Issue(address indexed _to, uint _tokens, string _type);
    event TeamIssue(address indexed _to, uint _tokens);
    event Burn(address indexed _from, uint _tokens);

    event TokenUnlock(address indexed _to, uint _tokens);
    event EndSale(uint _date);

    constructor()
    {
        name        = "Toon";
        decimals    = 18;
        symbol      = "Toon";

        totalTokenSupply = maxTotalSupply;
        balances[owner] = totalTokenSupply;

        tokenIssuedSale     = 0;
        tokenIssuedDev      = 0;
        tokenIssuedEco      = 0;
        tokenIssuedMkt      = 0;
        tokenIssuedRsv      = 0;
        tokenIssuedTeam     = 0;
        tokenIssuedAdv      = 0;

        burnTokenSupply     = 0;

        require(maxTeamSupply == teamVestingSupply * teamVestingTime, "ERROR: MaxTeamSupply");
        require(maxAdvisorSupply == advisorVestingSupply * advisorVestingTime, "ERROR: MaxAdvisorSupply");
        require(maxTotalSupply == maxSaleSupply + maxDevSupply + maxEcoSupply + maxMktSupply + maxReserveSupply + maxTeamSupply + maxAdvisorSupply, "ERROR: MaxTotalSupply");
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

        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;

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

        approvals[_from][msg.sender] = approvals[_from][msg.sender] - _value;
        balances[_from] = balances[_from] - _value;
        balances[_to]  = balances[_to] + _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function saleIssue(address _to) onlyOwner public
    {
        require(saleTime == true);
        require(tokenIssuedSale == 0);

        _transfer(msg.sender, _to, maxSaleSupply);

        tokenIssuedSale = maxSaleSupply;

        emit Issue(_to, maxSaleSupply, "Sale");
    }

    function devIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedDev == 0);

        _transfer(msg.sender, _to, maxDevSupply);

        tokenIssuedDev = maxDevSupply;

        emit Issue(_to, maxDevSupply, "Development");
    }

    function ecoIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedEco == 0);

        _transfer(msg.sender, _to, maxEcoSupply);

        tokenIssuedEco = maxEcoSupply;

        emit Issue(_to, maxEcoSupply, "Ecosystem");
    }

    function mktIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedMkt == 0);

        _transfer(msg.sender, _to, maxMktSupply);

        tokenIssuedMkt = maxMktSupply;

        emit Issue(_to, maxMktSupply, "Marketing");
    }

    function rsvIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedRsv == 0);

        _transfer(msg.sender, _to, maxReserveSupply);

        tokenIssuedRsv = maxReserveSupply;

        emit Issue(_to, maxReserveSupply, "Reserve");
    }

    function teamIssue(address _to, uint _time) onlyOwner public
    {
        require(saleTime == false);
        require( _time < teamVestingTime);

        uint nowTime = block.timestamp;
        require( nowTime > tmVestingTimer[_time] );

        uint tokens = teamVestingSupply;

        require(tokens == tmVestingBalances[_time]);
        require(maxTeamSupply >= tokenIssuedTeam + tokens);

        balances[msg.sender] = balances[msg.sender] - tokens;

        balances[_to] = balances[_to] + tokens;
        tmVestingBalances[_time] = 0;

        tokenIssuedTeam = tokenIssuedTeam + tokens;

        emit TeamIssue(_to, tokens);
    }

    function advisorIssue(address _to, uint _time) onlyOwner public
    {
        require(saleTime == false, "ERROR: It's sale time");
        require( _time < advisorVestingTime, "ERROR: Over vesting");

        uint nowTime = block.timestamp;
        require( nowTime > advVestingTimer[_time] );

        uint tokens = advisorVestingSupply;

        require(tokens == advVestingBalances[_time]);
        require(maxAdvisorSupply >= tokenIssuedAdv + tokens);
        require(balances[msg.sender] >= tokens);

        balances[msg.sender] = balances[msg.sender] - tokens;

        balances[_to] = balances[_to] + tokens;
        advVestingBalances[_time] = 0;

        tokenIssuedAdv = tokenIssuedAdv + tokens;

        emit Issue(_to, tokens, "Advisor");
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
            advVestingTimer[i] = endSaleTime + ((i + 1) * month * 3);
            advVestingBalances[i] = advisorVestingSupply;
        }

        emit EndSale(endSaleTime);
    }

    function burnToken(uint _value) onlyManager public
    {
        uint tokens = _value * E18;

        require(balances[msg.sender] >= tokens);

        balances[msg.sender] = balances[msg.sender] - tokens;

        burnTokenSupply = burnTokenSupply + tokens;
        totalTokenSupply = totalTokenSupply - tokens;

        emit Burn(msg.sender, tokens);
    }

    function close() onlyOwner public
    {
        selfdestruct(payable(msg.sender));
    }

    function _transfer(address _from, address _to, uint _value) internal
    {
        require(balances[_from] >= _value);

        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
    }
}