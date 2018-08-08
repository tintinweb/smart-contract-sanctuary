pragma solidity ^0.4.20;


contract GxToken {
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}


contract ERC20Basic {

  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);

}



contract ERC20 is ERC20Basic {

  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);

}


contract GreenXToken is ERC20 {
    
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    uint256 public totalSupply = 10000000000000000000000000;

    function name() public constant returns (string) { return "GREENx"; }
    function symbol() public constant returns (string) { return "Gx"; }
    function decimals() public constant returns (uint8) { return 18; }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event DistrFinished();

    bool public distributionFinished = false;

    modifier canDistr() {
    require(!distributionFinished);
    _;
    }

    function GreenXToken() public {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    modifier onlyOwner { 
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    
    function distributeToken(address[] addresses, uint256 _value) onlyOwner {
     for (uint i = 0; i < addresses.length; i++) {
         balances[owner] -= _value;
         balances[addresses[i]] += _value;
         Transfer(owner, addresses[i], _value);
     }
}
    
    function balanceOf(address _owner) constant public returns (uint256) {
	 return balances[_owner];
    }

    // mitigates the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

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
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

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

    function finishDistribution() onlyOwner public returns (bool) {
    distributionFinished = true;
    DistrFinished();
    return true;
    }

    function withdrawGxTokens(address _tokenContract) public returns (bool) {
        require(msg.sender == owner);
        GxToken token = GxToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }


}