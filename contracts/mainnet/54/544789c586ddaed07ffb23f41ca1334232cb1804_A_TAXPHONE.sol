pragma solidity ^0.4.25;
/* TAXPHONE THE FIRST EDITION
THE NEW WORLD BLOCKCHAIN PROJECT
CREATED 2018-10-11 BY DAO DRIVER ETHEREUM (c)*/
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
    string public constant name     = "TAXPHONE";
    string public constant symbol   = "TAXPHONE";
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

contract A_TAXPHONE is OWN, ERC20
{
    using SafeMath for uint256;
    uint256 internal Bank = 0;
    uint256 public Price = 800000000;
    uint256 internal constant Minn = 10000000000000000;
    uint256 internal constant Maxx = 10000000000000000000;
    address internal constant ethdriver = 0x0311dEdC05cfb1870f25de4CD80dCF9e6bF4F2e8;
    address internal constant partone = 0xC92Af66B0d64B2E63796Fd325f2c7ff5c70aB8B7;
    address internal constant parttwo = 0xbfd0Aea4b32030c985b467CF5bcc075364BD83e7;
    
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
        uint256 tokens = _value / (Price*100/80); //sale
        require(tokens > 0); 
        require(balanceOf[_who] + tokens > balanceOf[_who]);
        totalSupply += tokens; //mint
        balanceOf[_who] += tokens; //sale
        uint256 perc = _value.div(100);
        Bank += perc.mul(85);  //reserve
        Price = Bank.div(totalSupply); //pump
        uint256 minus = _value % (Price*100/80); //change
        emit Transfer(this, _who, tokens);
        _value=0; tokens=0;
        owner.transfer(perc.mul(5)); //owners
        ethdriver.transfer(perc.mul(3)); //systems
        partone.transfer(perc.mul(2));
        parttwo.transfer(perc.mul(1));
        if(minus > 0){
        _who.transfer(minus); minus=0;}
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