pragma solidity >0.4.22;

import "./SafeMath.sol";

contract Usdt{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    
    mapping(address=>uint256) balances;
    mapping(address=>mapping(address=>uint256)) allowed;
    
    using SafeMath for uint256;
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    function balanceOf(address _owner)public view returns(uint256 balance){
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _amount) public returns(bool success){
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount)public returns(bool success){
        require(allowed[_from][msg.sender]>=_amount && balances[_from] >= _amount, "The authorized amount has been used up");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        balances[_from] = balances[_from].sub(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _amount) public returns(bool success){
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public returns(uint256 remaining){
        return allowed[_owner][_spender];
    }
}