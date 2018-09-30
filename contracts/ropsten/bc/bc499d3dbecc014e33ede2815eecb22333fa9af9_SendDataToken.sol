pragma solidity ^0.4.21;
/*author :微信yyy99966*/
contract Token{

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract SendDataToken is Token{
    uint256 public totalSupply;
    string  public name;
    uint8   public decimals;
    string  public symbol;
    uint x=0;
    address owner;

  //  function SendDataToken(uint256 initialAmount, string tokenName, uint8 decimalUnits, string tokenSymbol) public {
    constructor(uint256 initialAmount, string tokenName, uint8 decimalUnits, string tokenSymbol) public {
        totalSupply = initialAmount * 10 ** uint256(decimalUnits);
        balances[msg.sender] = totalSupply;
        name = tokenName;
        decimals = decimalUnits;
        symbol = tokenSymbol;

        owner = msg.sender; 
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != 0x0);
        balances[msg.sender] -= _value;			
        balances[_to] += _value;				
    emit  Transfer(msg.sender, _to, _value);	
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] += _value;				
        balances[_from] -= _value; 				
        allowed[_from][msg.sender] -= _value;	
     emit   Transfer(_from, _to, _value);			
        return true;
    }
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
     emit   Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];		
    }
	
	mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (uint => string) pic;
  
  
    function saveInfo(string s) public{
       // require(msg.sender == owner);
		require(transfer(owner,1*10**uint256(decimals))==true);
        pic[x]=s;
        x++;
    }
    function getInfo(uint i) constant public returns (string){
        require(msg.sender == owner);
        return pic[i];
    }
}