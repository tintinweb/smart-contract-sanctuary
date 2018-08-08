pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
    }
    
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract owned {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract BasicToken {
    function totalSupply () public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 _value);
    event Approval(address indexed owner, address indexed spender, uint256 _value);
    event FrozenFunds(address target, bool frozen);
    event Burn(address indexed from, uint256 _value);
}

contract EdenToken is BasicToken, owned {
    using SafeMath for uint256;
    string public name = "Eden Token";
    string public symbol= "EDT";
    uint8 public decimals = 2;
    uint256 public totalSupply = 200000000;  
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;  
    mapping (address => bool) public frozenAccount;

    constructor() public {
        totalSupply = totalSupply * 10 ** uint256(decimals);
        owner = msg.sender;        
        balanceOf[msg.sender] = totalSupply;                                            
    }
    
    function totalSupply () public view returns (uint256){
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256){
        return balanceOf[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowance[_owner][_spender];
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to !=  address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);    
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(owner));
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool){
        allowance[msg.sender][_spender] = (allowance[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool){
        uint256 oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowance[msg.sender][_spender] = 0;
        } 
        else {
        allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
        spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
        }
    }
    
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                      
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[_from] >= _value);                
        balanceOf[_from] -= _value;                         
        allowance[_from][msg.sender] -= _value;             
        totalSupply -= _value;                              
        emit Burn(_from, _value);
        return true;
    }

    function mintToken(address target, uint256 mintedAmount) public onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), owner, mintedAmount);
        emit Transfer(owner, target, mintedAmount);
    }

    function freezeAccount(address target) public onlyOwner {
        frozenAccount[target] = true;
        emit FrozenFunds(target, true);
    }
    
    function unFreezeAccount(address target) public onlyOwner{
        frozenAccount[target] = false;
        emit FrozenFunds(target, false);
    }
    
    function setname(string _name) onlyOwner public {
        name = _name;
    }
    
    function setsymbol(string _symbol) onlyOwner public {
        symbol = _symbol;
    }
}