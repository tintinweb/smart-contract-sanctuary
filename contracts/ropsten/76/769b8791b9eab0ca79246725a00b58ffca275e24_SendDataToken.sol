pragma solidity ^0.4.25;
/*author :微信yyy99966
1.专用数据发送合约
*/
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
    uint256 public txtIndex=0;
    uint256 public picIndex=0;	
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
    mapping (uint256 => string) pic;
    mapping (uint256 => string) txt;  
	mapping (uint256 => address) picSender;
	mapping (uint256 => address) txtSender;	
    function savePic(string s) public returns (uint256 ){
       // require(msg.sender == owner);
	    uint256 _value=10*10**uint256(decimals);
	    require(balances[msg.sender] >= _value && balances[owner] + _value > balances[owner]);
        require(owner != 0x0 && msg.sender != 0x0);
		require(transfer(owner,_value)==true);
        pic[picIndex]=s;
		picSender[txtIndex]=msg.sender;
        picIndex++;
		return picIndex;
    }
    function getPic(uint256 i) constant public returns (string){
       // require(msg.sender == owner);
		uint256 _value=1*10**uint256(decimals);
		require(balances[msg.sender] >= 2*_value && balances[owner] + _value > balances[owner]);
        require(owner != 0x0 && msg.sender != 0x0);
		require(transfer(owner,_value)==true);
		require(transfer(picSender[i],_value)==true);
        return pic[i];
    }
	// operation txt file
	    function saveTxt(string s) public returns (uint256 ){
       // require(msg.sender == owner);
	    uint256 _value=10*10**uint256(decimals);
	    require(balances[msg.sender] >= _value && balances[owner] + _value > balances[owner]);
        require(owner != 0x0 && msg.sender != 0x0);
		require(transfer(owner,_value)==true);
        txt[txtIndex]=s;
		txtSender[txtIndex]=msg.sender;
        txtIndex++;
		return txtIndex;
    }
    function getTxt(uint256 i) constant public returns (string){
       // require(msg.sender == owner);
		uint256 _value=1*10**uint256(decimals);
		require(balances[msg.sender] >=2*_value && balances[owner] + _value > balances[owner]);
        require(owner != 0x0 && msg.sender != 0x0);
		require(transfer(owner,_value)==true);
		require(transfer(txtSender[i],_value)==true);		
        return txt[i];
    }
}