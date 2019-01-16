pragma solidity >=0.4.22 <0.6.0;

interface StandardTokenInterface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is StandardTokenInterface{
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    uint256 public _totalSupply;
    
    function name() external view returns (string memory) {
        
        return _name;
    }
    
    function symbol() external view returns (string memory) {
        
        return _symbol;
    }
    
    function decimals() external view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() external view returns (uint256) {
        
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        
        balance = balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        
        require(_to != address(0x0));
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        
        uint256 previous = balances[msg.sender] + balances[_to];
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        assert(balances[msg.sender] + balances[_to] == previous);
        emit Transfer(msg.sender,_to,_value);
        
        success = true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        require(_from != address(0x0));
        require(_to != address(0x0));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from,_to,_value);
        
        success = true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        require(_spender != address(0x0));
        require(balances[msg.sender] >= _value);
        
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        success = true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        
        remaining = allowed[_owner][_spender];
    }
}

contract QRLS is StandardToken{
    
    constructor(string memory name,string memory symbol,uint8 decimals,uint256 totalSupply) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = totalSupply;
        balances[msg.sender] = _totalSupply;
    }
}