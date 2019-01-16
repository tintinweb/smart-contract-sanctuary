pragma solidity >=0.4.22 <0.6.0;

contract StandardTokenInterface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is StandardTokenInterface{
    
    mapping(address => mapping(address => uint256)) internal allowed;
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        
        require(_to != address(0x0));
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
        uint256 previous = balanceOf[msg.sender] + balanceOf[_to];
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        assert(balanceOf[msg.sender] + balanceOf[_to] == previous);
        emit Transfer(msg.sender,_to,_value);
        
        success = true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        require(_from != address(0x0));
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from,_to,_value);
        
        success = true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        require(_spender != address(0x0));
        require(balanceOf[msg.sender] >= _value);
        
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        success = true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        
        remaining = allowed[_owner][_spender];
    }
}

contract QRL is StandardToken{
    
    constructor() public {
        name = "QRL TOKEN";
        symbol = "QRL";
        decimals = 0;
        totalSupply = 10000000000;
        balanceOf[msg.sender] = totalSupply;
    }
}