pragma solidity ^0.4.20;

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
    
    event OwnerTransferPropose(address indexed _from, address indexed _to);

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
}

    function OwnerHelper() public
    {
        owner = msg.sender;
    }

    function transferOwnership(address _to) onlyOwner public
    {
        require(_to != owner);
        require(_to != address(0x0));
        owner = _to;
        OwnerTransferPropose(owner, _to);
    }
}

contract ERC20Interface
{
    event Transfer( address indexed _from, address indexed _to, uint _value);
    event Approval( address indexed _owner, address indexed _spender, uint _value);
    
    function totalSupply() constant public returns (uint _supply);
    function balanceOf( address _who ) constant public returns (uint _value);
    function transfer( address _to, uint _value) public returns (bool _success);
    function approve( address _spender, uint _value ) public returns (bool _success);
    function allowance( address _owner, address _spender ) constant public returns (uint _allowance);
    function transferFrom( address _from, address _to, uint _value) public returns (bool _success);
}

contract bohwa is ERC20Interface, OwnerHelper
{
    using SafeMath for uint256;
    
    string public name;
    uint public decimals;
    string public symbol;
    uint public totalSupply;
    address public wallet;

    uint private E18 = 1000000000000000000;
    
    uint public maxSupply = 100000000 * E18; 
    uint public mktSupply =  30000000 * E18; 
    uint public saleSupply = 70000000 * E18;
    
    uint public ethPerToken = 5000;
    uint public private1SaleBonus = 30; 
    uint public private2SaleBonus = 25; 
    uint public preSale1Bonus = 10; 
    uint public preSale2Bonus = 5; 
    uint public crowdSaleBonus = 0; // zero Bonus
    
    uint public privateSale1StartDate = 1528506611;
    uint public privateSale1EndDate = 1529457011;
    uint public privateSale2StartDate = 1537260400;
    uint public privateSale2EndDate = 1537865200;

    uint public preSale1StartDate = 1547951600;
    uint public preSale1EndDate = 1548556400;
    uint public preSale2StartDate = 1549951600;
    uint public preSale2EndDate = 1550556400;

    uint public crowdSaleStartDate = 1568642800;
    uint public crowdSaleEndDate = 1569852400;
    
    bool public tokenLock = true;
    
    uint public icoIssuedMkt = 0;
    uint public icoIssuedSale = 0;

    uint public saleEtherReceived =0;
    
    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;
    mapping (address => bool) internal personalLocks;
    mapping (address => uint) internal  icoEtherContributeds;
    
    event RemoveLock(address indexed _who);
    event WithdrawMkt(address indexed _to, uint _value);
    

    function bohwa() public
    {
        name = "Bohwatest3";
        decimals = 18;
        symbol = "BHT3";
        owner = 0x03bf3a22d51a39a52a1b2f954ab3bac9656b2497;
    	
	    totalSupply = 0;
    }
    
    function atNow() private constant returns(uint)
    {
        return now;
    }
    
    function () payable public
    {
        buyToken();
    }
    
    function buyToken() private
    {
        require(saleSupply > icoIssuedSale);
        
        uint saleType = 0;  
        uint saleBonus = 0;
        
        uint minEth = 0;       // minimum Ethereum
        uint maxEth = 3000 ether;  // maximum Ethereum

        uint nowTime = atNow();
        
        if(nowTime >= privateSale1StartDate && nowTime < privateSale1EndDate)
        {
            saleType = 1;
            saleBonus = private1SaleBonus;
        }
           
        else if(nowTime >= privateSale2StartDate && nowTime < privateSale2EndDate)
        {
            saleType = 2;
            saleBonus = private2SaleBonus;
        }
        else if(nowTime >= preSale1StartDate && nowTime < preSale1EndDate)
        {
            saleType = 3;
            saleBonus = preSale1Bonus;
        }
         else if(nowTime >= preSale2StartDate && nowTime < preSale2EndDate)
        {
            saleType = 4;
            saleBonus = preSale2Bonus;
        }
        else if(nowTime >= crowdSaleStartDate && nowTime < crowdSaleEndDate)
        {
            saleType = 5;
            saleBonus = crowdSaleBonus;
        }
        
        require (saleType >= 1 && saleType <= 5);
        require(msg.value >= minEth && icoEtherContributeds[msg.sender].add(msg.value) <= maxEth);
        uint tokens = ethPerToken.mul(msg.value);
        tokens = tokens.mul(100 + saleBonus) / 100;
        
        require (saleSupply >= icoIssuedSale.add(tokens));
        saleEtherReceived = saleEtherReceived.add(msg.value);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        icoIssuedSale = icoIssuedSale.add(tokens);
    	icoEtherContributeds[msg.sender] = icoEtherContributeds[msg.sender].add(msg.value);
    	personalLocks[msg.sender] = true; // basic Personal Lock
        totalSupply = totalSupply.add(tokens);
        
        Transfer(0x0, msg.sender, tokens);
        
        owner.transfer(address(this).balance);
    }
    

    function isTokenLock(address _from, address _to) constant public returns (bool _success)
    {
        _success = false;
        if(tokenLock == true)
        {
            _success = true;
        }
        
        if(personalLocks[_from] == true || personalLocks[_to] == true)
        {
            _success = true;
        }
        
        return _success;
    }
    
    function isPersonalLock(address _who) constant public returns (bool)
    {
        return personalLocks[_who];
    }

    function removeTokenLock() onlyOwner public
    {
        require(tokenLock == true);
        
        tokenLock = false;

        RemoveLock(0x0);
    }

    function removePersonalTokenLock(address _person) onlyOwner public
    {
        require(personalLocks[_person] == true);
        
        personalLocks[_person] = false;
        
        RemoveLock(_person);
    }

    
    function totalSupply() constant public returns (uint) 
    {
        return totalSupply;
    }
    
    function balanceOf(address _who) constant public returns (uint) 
    {
        return balances[_who];
    }
    
    function transfer(address _to, uint _value) public returns (bool) 
    {
        require(balances[msg.sender] >= _value);
        require(tokenLock == false);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint _value) public returns (bool)
    {
        require(balances[msg.sender] >= _value);
        
        approvals[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint) 
    {
        return approvals[_owner][_spender];
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool) 
    {
        require(balances[_from] >= _value);
        require(approvals[_from][msg.sender] >= _value);        
        require(tokenLock == false);
        
        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to]  = balances[_to].add(_value);
        
        Transfer(_from, _to, _value);
        
        return true;
    }
    
    function withdrawMkt(address _to, uint _value) public onlyOwner
    {
        require(mktSupply > icoIssuedMkt);
     	require(mktSupply > icoIssuedMkt.add(_value));
        uint tokens = _value * E18;
        
        balances[_to] = balances[_to].add(tokens);
        icoIssuedMkt = icoIssuedMkt.add(tokens);
        totalSupply = totalSupply.add(tokens);
        
        Transfer(0x0, _to, tokens);
    }
}