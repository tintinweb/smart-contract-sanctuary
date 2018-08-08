pragma solidity ^0.4.0;

contract ContractTokens {
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Basic {
  function approve(address _spender, uint256 _value) returns (bool success) {}
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);

}



contract ERC20 is ERC20Basic {
    function balanceOf(address who) public constant returns (uint256);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract TesterFinal is ERC20 {
    
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    uint256 public totalSupply = 1000000000 * 10**8;

    function name() public constant returns (string) {
        return "TesterFinal"; 
    }
    function symbol() public constant returns (string) { 
        return "TFL"; 
    }
    function decimals() public constant returns (uint8) { 
        return 8; 
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function TAKLIMAKAN() public {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    modifier onlyOwner { 
        require(msg.sender == owner);
        _;
    }

    function airdropTesterFinal(address[] addresses, uint256 _value) onlyOwner public {
         for (uint i = 0; i < addresses.length; i++) {
             balances[owner] -= _value;
             balances[addresses[i]] += _value;
             emit Transfer(owner, addresses[i], _value);
         }
    }
    
    function balanceOf(address _owner) constant public returns (uint256) {
	 return balances[_owner];
    }

    modifier limitCertainAmount(uint amount) {
        assert(msg.data.length >= amount + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) limitCertainAmount(2 * 32) public returns (bool success) {

         if (balances[msg.sender] >= _amount
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
             balances[msg.sender] -= _amount;
             balances[_to] += _amount;
             Transfer(msg.sender, _to, _amount);
             return true;
         } else {
             return false;
         }
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        
        allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }


    function claimContractTokens(address _tokenContract) public returns (bool) {
        require(msg.sender == owner);
        ContractTokens token = ContractTokens(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }


}