pragma solidity ^0.4.25;
/* NEXT LEVEL CLUB CRYPTO-BANK THE FIRST EDITION
THE NEW WORLD ECONOMY PROJECT
CREATED 2018-10-04 BY DAO DRIVER ETHEREUM (c)
0xB453AA2Cdc2F9241d2c451053DA8268B34b4227f */
contract OWN
{
    address public owner;
    address internal newOwner;
    
    constructor() 
    public
    payable
    {
    owner = msg.sender;
    }
    
    modifier onlyOwner 
    {
    require(owner == msg.sender);
    _;
    }
    
    function changeOwner(address _owner)
    onlyOwner 
    public
    {
    require(_owner != 0);
    newOwner = _owner;
    }
    
    function confirmOwner()
    public 
    { 
    require(newOwner == msg.sender);
    owner = newOwner;
    delete newOwner;
    }
}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
    return 0;
    }
    uint256 c = a*b;
    assert(c/a == b);
    return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a/b;
    return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
    }
}
contract ERC20
{
    string public constant name     = "NEXT LEVEL CLUB";
    string public constant symbol   = "NLCLUB";
    uint8  public constant decimals =  6;
    uint256 public totalSupply;
    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    mapping (address => mapping(address => uint256)) public allowance;
    mapping (address => uint256) public balanceOf;
    
    function balanceOf(address who)
    public constant
    returns (uint)
    {
    return balanceOf[who];
    }
    
    function approve(address _spender, uint _value)
    public
    {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    }
    
    function allowance(address _owner, address _spender) 
    public constant 
    returns (uint remaining) 
    {
    return allowance[_owner][_spender];
    }
    
    modifier onlyPayloadSize(uint size) 
    {
    require(msg.data.length >= size + 4);
    _;
    }
}

contract A_NEXT_LEVEL is OWN, ERC20
{
    using SafeMath for uint256;
    uint256 internal Bank = 0;
    uint256 public Price = 800000000;
    uint256 internal constant Minn = 10000000000000000;
    uint256 internal constant Maxx = 10000000000000000000;
    address internal constant ethdriver = 0xB453AA2Cdc2F9241d2c451053DA8268B34b4227f;
    
    function() 
    payable 
    public
        {
        require(msg.value>0);
        require(msg.value >= Minn);
        require(msg.value <= Maxx);
        mintTokens(msg.sender, msg.value);
        }
        
    function mintTokens(address _who, uint256 _value) 
    internal 
        {
        uint256 tokens = _value / (Price*10/8); //sale
        require(tokens > 0); 
        require(balanceOf[_who] + tokens > balanceOf[_who]);
        totalSupply += tokens; //mint
        balanceOf[_who] += tokens; //sale
        uint256 perc = _value.div(100);
        Bank += perc.mul(85);  //reserve
        Price = Bank.div(totalSupply); //pump
        uint256 minus = _value % (Price*10/8); //change
        require(minus > 0);
        emit Transfer(this, _who, tokens);
        _value=0; tokens=0;
        owner.transfer(perc.mul(5)); //owners
        ethdriver.transfer(perc.mul(5)); //systems
        _who.transfer(minus); minus=0;
        }
        
    function transfer (address _to, uint _value) 
    public onlyPayloadSize(2 * 32) 
    returns (bool success)
        {
        require(balanceOf[msg.sender] >= _value);
        if(_to != address(this)) //standart
        {
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        }
        else //tokens to contract
        {
        balanceOf[msg.sender] -= _value;
        uint256 change = _value.mul(Price);
        require(address(this).balance >= change);
		
		if(totalSupply > _value)
		{
        uint256 plus = (address(this).balance - Bank).div(totalSupply);    
        Bank -= change; totalSupply -= _value;
        Bank += (plus.mul(_value));  //reserve
        Price = Bank.div(totalSupply); //pump
        emit Transfer(msg.sender, _to, _value);
        }
        if(totalSupply == _value)
        {
        Price = address(this).balance/totalSupply;
        Price = (Price.mul(101)).div(100); //pump
        totalSupply=0; Bank=0;
        emit Transfer(msg.sender, _to, _value);
        owner.transfer(address(this).balance - change);
        }
        msg.sender.transfer(change);
        }
        return true;
        }
    
    function transferFrom(address _from, address _to, uint _value) 
    public onlyPayloadSize(3 * 32)
    returns (bool success)
        {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        if(_to != address(this)) //standart
        {
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        }
        else //sale
        {
        balanceOf[_from] -= _value;
        uint256 change = _value.mul(Price);
        require(address(this).balance >= change);
        if(totalSupply > _value)
        {
        uint256 plus = (address(this).balance - Bank).div(totalSupply);   
        Bank -= change;
        totalSupply -= _value;
        Bank += (plus.mul(_value)); //reserve
        Price = Bank.div(totalSupply); //pump
        emit Transfer(_from, _to, _value);
        allowance[_from][msg.sender] -= _value;
        }
        if(totalSupply == _value)
        {
        Price = address(this).balance/totalSupply;
        Price = (Price.mul(101)).div(100); //pump
        totalSupply=0; Bank=0; 
        emit Transfer(_from, _to, _value);
        allowance[_from][msg.sender] -= _value;
        owner.transfer(address(this).balance - change);
        }
        _from.transfer(change);
        }
        return true;
        }
}