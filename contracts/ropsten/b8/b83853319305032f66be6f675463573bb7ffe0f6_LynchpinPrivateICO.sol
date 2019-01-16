pragma solidity ^0.4.23;

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure
    returns (uint256)
    {
        uint256 c = a * b;

        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure
    returns (uint256)
    {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure
    returns (uint256)
    {
        assert(b <= a);

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure
    returns (uint256)
    {
        uint256 c = a + b;

        assert(c >= a);

        return c;
    }
}

interface ERC20
{
    function totalSupply() view external returns (uint _totalSupply);
    function balanceOf(address _owner) view external returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) view external returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract LynchpinToken is ERC20
{
    using SafeMath for uint256;

    string  public name        = "qwerty";
    string  public symbol      = "qwe";
    uint8   public decimals    = 18;
    uint    public totalSupply = 5000000 * (10 ** uint(decimals));
    address public owner       = 0x22741e8eE26E83AaCBf098a31DE5af1b1231920e;

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    constructor() public
    {
        balanceOf[owner] = totalSupply;
    }

    function totalSupply() view external returns (uint _totalSupply)
    {
        return totalSupply;
    }

    function balanceOf(address _owner) view external returns (uint balance)
    {
        return balanceOf[_owner];
    }

    function allowance(address _owner, address _spender) view external returns (uint remaining)
    {
        return allowance[_owner][_spender];
    }
    function _transfer(address _from, address _to, uint _value) internal
    {
        require(_to != 0x0);

        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    function transfer(address _to, uint _value) public returns (bool success)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success)
    {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // disallow incoming ether to this contract
    function () public
    {
        revert();
    }
}

contract Ownable
{
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) public
    {
        owner = _owner;
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner
    {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract LynchpinPrivateICO is Ownable(0x22741e8eE26E83AaCBf098a31DE5af1b1231920e)
{
    using SafeMath for uint256;

    LynchpinToken public lynT = LynchpinToken(0xfec25433743e28a534e990a51bd7fa76dd524972);

    uint256 public tokeninOneEther;
    uint256 public maxTokensToSell = 2000000 * 10**18;
    uint256 public tokenSold;
    bool crowdsaleClosed = false;

    uint256 LOCK_PERIOD_START    = 1556668800;    // Wednesday, May 1, 2019 12:00:00 AM         start time
    uint256 LOCK_PERIOD_9_MONTH  = 1580515200;    // Saturday, February 1, 2020 12:00:00 AM     9th month done
    uint256 LOCK_PERIOD_10_MONTH = 1583020800;    // Sunday, March 1, 2020 12:00:00 AM          10th  month done
    uint256 LOCK_PERIOD_11_MONTH = 1585699200;    // Wednesday, April 1, 2020 12:00:00 AM       11th month done
    uint256 LOCK_PERIOD_END      = 1588291200;    // Friday, May 1, 2020 12:00:00 AM            12th month done - lock-in period ends

    mapping(address => uint256) public tokensOwed;
    mapping(address => uint256) public ethContribution;
    mapping(address => bool) public isWhitelisted;

    event LogAddedToWhitelist(address indexed _contributor);
    event LogTokenRateUpdated(uint256 _newRate);
    event LogSaleClosed();

    constructor(uint256 _tokeninOneEther) public
    {
        require (_tokeninOneEther > 0);
        isWhitelisted[owner] = true;
        tokeninOneEther = _tokeninOneEther;
        emit LogTokenRateUpdated(_tokeninOneEther);
    }

    function () public payable
    {
        require(!crowdsaleClosed);
        require(isWhitelisted[msg.sender]);

        uint256 amountToSend = msg.value * tokeninOneEther;

        require (tokenSold.add(amountToSend) <= maxTokensToSell);

        tokensOwed[msg.sender] += amountToSend;
        tokenSold += amountToSend;
        ethContribution[msg.sender] += msg.value;
        owner.transfer(address(this).balance);
    }

    function addContributor(address _contributor) external onlyOwner
    {
        require(_contributor != address(0));
        require(!isWhitelisted[_contributor]);
        isWhitelisted[_contributor] = true;
        emit LogAddedToWhitelist(_contributor);
    }

    function updateTokenRate(uint256 _tokeninOneEther ) external onlyOwner
    {
        require (_tokeninOneEther > 0);
        tokeninOneEther = _tokeninOneEther;
        emit LogTokenRateUpdated(_tokeninOneEther);
    }

    function closeSale() external onlyOwner
    {
        require (now > LOCK_PERIOD_START);
        lynT.transfer(msg.sender, lynT.balanceOf(address(this)));
        owner.transfer(address(this).balance);
        crowdsaleClosed = true;
        emit LogSaleClosed();
    }

    function withdrawMyTokens () external
    {
        require (crowdsaleClosed);
        require (tokensOwed[msg.sender] > 0);
        require (now > LOCK_PERIOD_9_MONTH);

        uint256 penalty = 0;
        if(now > LOCK_PERIOD_END)
            penalty = 0;
        else if(now > LOCK_PERIOD_11_MONTH)
            penalty = 20;
        else if(now > LOCK_PERIOD_10_MONTH)
            penalty = 30;
        else
            penalty = 40;

        uint256 tokenBought = tokensOwed[msg.sender];
        uint256 toSend = tokenBought.sub(tokenBought.mul(penalty).div(100));
        tokensOwed[msg.sender] = 0;
        lynT.transfer(msg.sender, toSend);
    }

    function withdrawPenaltyTokens() external onlyOwner
    {
        require (now > LOCK_PERIOD_END);
        lynT.transfer(msg.sender, lynT.balanceOf(address(this)));
        owner.transfer(address(this).balance);
    }
}