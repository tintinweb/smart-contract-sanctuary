pragma solidity ^0.7.0;

contract Token {
    function balanceOf(address _owner) public virtual returns (uint256 balance) {}

    function transfer(address _to, uint256 _value) public virtual returns (bool success) {}

    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success) {}

    function approve(address _spender, uint256 _value) public virtual returns (bool success) {}

    function allowance(address _owner, address _spender) public virtual returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }
    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract LibertasToken is StandardToken {
    
    string public name;                   
    uint8 public decimals;               
    string public symbol;             
    string public version = 'V1.0';    

    constructor() {
        balances[msg.sender] = 10000000000;               
        totalSupply = 10000000000;                        
        name = "LIBERTAS";                                 
        decimals = 2;                                     
        symbol = "LIBERTAS";                                  
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        (bool success, ) = _spender.call(abi.encode(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        require(success);
        return true;
    }
}

