pragma solidity ^0.4.24;

contract xkToken  {
    string public constant name = "xkToken";
    string public constant symbol = "j";
    uint8 public constant decimals = 5;
    uint256 _totalSupply = 1000 * (10**(uint256(decimals)));
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    // Owner of this contract
    address public owner;
    // Balances for each account
    mapping(address => uint256) balances;
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
    
    constructor () public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }
 
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

   
    
    function totalsuplly ()public view returns(uint256){
        return _totalSupply;
    }
    
    function Balances_of (address _owner)public view returns(uint256){
        return balances[_owner];
    }
    function transfer(address _to,uint256 _amount)public returns (bool success) {
    require(_to != address(0));
    require(_amount > 0 && _amount <= balances[msg.sender]);
    balances[msg.sender] -=_amount ;
    balances[_to] += _amount;
    emit Transfer(msg.sender, _to, _amount);
    return true;
}
    function transfeFrom(address _from,address _to,uint256 _amount) public returns (bool success) {
        require(_to != address(0));
        require(allowed[msg.sender][_from]>=_amount);
        require(balances[_from]>=_amount && _amount>0);
        balances[_from]-=_amount;
        balances[_to]+=_amount;
        return true;
    
}
    function approves(address _spender,uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
}
   function allowance(address _owner,address _spender) public view returns(uint256 allow){
        return allowed[_owner][_spender];
}
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        _totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }
     function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        _totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }


   function kill() onlyOwner {
          selfdestruct(owner);
       }
}