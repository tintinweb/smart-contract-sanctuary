pragma solidity ^0.4.25;

contract EIP20Interface {
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Burn(address indexed burner, uint256 value);
}

contract EIP20 is EIP20Interface {
    uint256 constant private MAX_UINT256 = 2**256 - 1;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    mapping (address => uint256) public admins;
    address private owner;
    string public name;
    uint8 public decimals;
    string public symbol;
    uint8 public transfers;

    function EIP20() public {
        balances[msg.sender] = 50000000000;
        totalSupply = 50000000000;
        name = "Test coin 5";
        decimals = 2;
        symbol = "TC5";
        owner = msg.sender;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {

        require(transfers != 0);
        
        require( admins[msg.sender] == 1 || now > 1547078400 );
        
        require(_to != address(0));
        
        require(balances[msg.sender] >= _value);
        
        balances[msg.sender] -= _value;
        
        balances[_to] += _value;
        
        Transfer(msg.sender, _to, _value);
        
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(transfers != 0);
        
        require( admins[msg.sender] == 1 || now > 1547078400 );
        
        require(_to != address(0));
        
        uint256 allowance = allowed[_from][msg.sender];
        
        require(balances[_from] >= _value && allowance >= _value);
        
        balances[_from] -= _value;
        
        balances[_to] += _value;
        
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        
        Transfer(_from, _to, _value);
        
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner]; 
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }   
    
    function burn(uint256 _value) public {
        require(msg.sender == owner);
        
        require(_value <= balances[msg.sender]);
        
        address burner = msg.sender;
        
        balances[burner] -= _value;
        
        totalSupply -= _value;
        
        Burn(burner, _value);
    }
    
    function transfersOnOff(uint8 _value) public {
        require(msg.sender == owner);
        
        transfers = _value;
    }
    
    function admin(address _admin, uint8 _value) public {
        require(msg.sender == owner);
        
        admins[_admin] = _value;
    }
}