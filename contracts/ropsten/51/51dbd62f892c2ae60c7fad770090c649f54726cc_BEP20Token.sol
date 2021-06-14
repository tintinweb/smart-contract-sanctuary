pragma solidity >=0.4.22 <0.9.0;

import "./SafeMath.sol";

contract BEP20Token{

    using SafeMath for uint256;
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint256 public totalSupply = 10000 * (10 ** 18);
    string public name = "Nyan Cat";
    string public symbol = "NYC";
    uint256 public decimals = 18;
    address public owner;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approve(address indexed owner, address indexed spender, uint256 value);
    
    
    constructor() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    function balanceOf(address _owner) public view returns(uint256){
        return balances[_owner];

    }
    
    function getOwner() external view returns(address){
        return owner;
    }
    
    function transfer(address _to, uint256 value) public returns(bool){
        require(balanceOf(msg.sender) >= value, 'Insufficient Balance');
        balances[_to] = balances[_to].add(value); // balances[_to] += value
        balances[msg.sender] = balances[msg.sender].sub(value); // balances[msg.sender] -= value
        
        emit Transfer(msg.sender, _to, value);
        
        return true;
    }
    
    function approve(address spender, uint256 value) public returns(bool){
        allowance[msg.sender][spender] = value;
        
        emit Approve(msg.sender, spender, value);
        
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns(bool){
        require(balanceOf(from) >= value, "Insufficient Balance");
        require(allowance[from][msg.sender] >= value, "Insufficient Allowance");
        balances[to] = balances[to].add(value); //balances[to] += value
        balances[from] = balances[from].sub(value); //bances[from] -= value
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value); //allowance[from][msg.sender] -= value;
        
        emit Transfer(from, to, value);
        
        return true;
    }
    
    function burn(uint256 _value) public returns(bool){
        require(owner == msg.sender); //only owner
        require(_value > 0);
        require(balanceOf(msg.sender) >= _value, "Insufficient Balance.");
        balances[msg.sender] = balances[msg.sender].sub(_value); //balances[msg.sender] -= _value
        totalSupply = totalSupply.sub(_value); //totalSupply -= _value
        
        return(true);
    }

    function transferOwnership(address newOwner) public returns(bool){
        require(owner == msg.sender, "Only current owner can change ownership"); //only owner
        owner = newOwner;
        transfer(owner, balances[msg.sender]);

        return true;
    }
}