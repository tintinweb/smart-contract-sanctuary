pragma solidity ^0.4.0;

contract ContractToken {
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Token {

  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
  function approve(address _spender, uint256 _value) returns (bool success) {}
}

contract ERC20 is ERC20Token {
  function allowance(address owner, address spender) public constant returns (uint256);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MDL is ERC20 {
    
    function name() public constant returns (string) { 
        return "MDL Talent Hub"; 
    }
    function symbol() public constant returns (string) { 
        return "MDL"; 
    }
    function decimals() public constant returns (uint8) { 
        return 8; 
    }
    
    address owner = msg.sender;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint256 public totalSupply = 1000000000 * 10**8;

    function MDL() public {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    modifier onlyOwner { 
        require(msg.sender == owner);
        _;
    }

    function airdropMDL(address[] addresses, uint256 _value) onlyOwner public {
         for (uint i = 0; i < addresses.length; i++) {
             balances[owner] -= _value;
             balances[addresses[i]] += _value;
             emit Transfer(owner, addresses[i], _value);
         }
    }
    
    
    function balanceOf(address _owner) constant public returns (uint256) {
	 return balances[_owner];
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {

         if (balances[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
             balances[_from] -= _amount;
             allowed[_from][msg.sender] -= _amount;
             balances[_to] += _amount;
             Transfer(_from, _to, _amount);
             return true;
         } else {
            return false;
         }
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        
        allowed[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }

    function withdrawContractTokens(address _tokenContract) public returns (bool) {
        require(msg.sender == owner);
        ContractToken token = ContractToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }


}