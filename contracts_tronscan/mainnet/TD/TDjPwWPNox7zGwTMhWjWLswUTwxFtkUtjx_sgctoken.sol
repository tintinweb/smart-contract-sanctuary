//SourceUnit: sgctoken.sol

pragma solidity ^0.5.10;

contract sgctoken {
    
    uint256 totalsupply;
    address admin ;
    string name_;
    string symbol_;
    uint8 decimal_;
    event Deposit(address spender,uint256 amount,uint256 balance);
    event Transfertrx(address to,uint256 amount,uint256 balance);
    constructor (uint256 _qty, string memory _name, string memory _symbol, uint8 _decimal) public {
        totalsupply = _qty;
        admin = msg.sender;
        balances[admin] = totalsupply;
        name_ = _name;
        symbol_ = _symbol;
        decimal_ = _decimal;
    }
    
    function name() public view returns(string memory) {
        return name_;
    }
    function symbol() public view returns(string memory) {
        return symbol_;
    }
    function decimal () public view returns(uint8) {
        return decimal_;
    }
    
    
    function totalSupply() public view returns (uint256) {
        return totalsupply;
    }
    
    mapping (address => uint256) balances;
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    event Transfer(address indexed Sender, address indexed Receipient, uint256 Quantity);
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require( balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    // transferFrom, approve , allowance(view)
    
    // Owner , spender , receipient 
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        require( balances[_from] >= _value, "Insufficient balance in owner wallet");
        require(allowed[_from][msg.sender] >= _value, "Not enough allowance");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    mapping (address => mapping (address => uint256)) allowed;
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
        
    }
    
    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function buytoken(uint256 _nooftoken,uint256 _trxprice) public  payable returns(uint256)
    {
       
       require(_nooftoken%900==0,"minimum 900 SGC token and its multiple");
       require((_nooftoken/900)*6==_trxprice,"wrong amount");
       
        require((msg.value)/1000000>=_trxprice,"insufficient balance");
        //require((msg.value)>=_trxprice,"insufficient balance");
        require(balances[admin] >= _nooftoken, "Insufficient balance in admin wallet");
        balances[admin] -= _nooftoken;
        balances[msg.sender] += _nooftoken;
        emit Transfer(admin, msg.sender, _nooftoken);
        emit Deposit(msg.sender,_trxprice,address(this).balance);
        return msg.value;
        
        
    }
    
    
    
     function trxtransfer(address  _to, uint256 _amount) public payable  {
        require(msg.sender==admin,"only admin");
        address(uint256(_to)).transfer(_amount);
        emit Transfertrx(_to,_amount,address(this).balance);
    }
    
    function getbalance(address _addres) public view returns(uint256)
    {
        return address(this).balance;
    }
    
    // Mint , Burn , change decimal numbers
}