pragma solidity ^0.4.24;

contract xkToken  {
    string public constant name = "xkToken";
    string public constant symbol = "yxk2";
    uint8 public constant decimals = 5;
    uint256 _totalSupply = 1000 * (10**(uint256(decimals)));
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // Owner of this contract
    address public owner;
    // Balances for each account
    mapping(address => uint256) balances;
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
 
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor () public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
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
   function kill() onlyOwner {
          selfdestruct(owner);
       }
}