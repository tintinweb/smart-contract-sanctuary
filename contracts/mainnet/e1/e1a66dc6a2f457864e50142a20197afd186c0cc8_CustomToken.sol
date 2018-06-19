pragma solidity ^0.4.19;

contract BaseToken{    
    string public name;      
    string public symbol;     
    uint8 public decimals;   
    uint256 public totalSupply;     

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) public allowance;   
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event FrozenFunds(address target, bool frozen);  

    address public owner;
    modifier onlyOwner {        
        require(msg.sender == owner);       
        _;
    } 
    mapping (address => bool) public frozenAccount;
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;        
        FrozenFunds(target, freeze);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {        
        return balances[_owner];
    }   

    function _transfer(address _from, address _to, uint _value) internal {        
        require(!frozenAccount[_from]); 
        require(_to != 0x0);
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);
        balances[_from] -= _value;
        balances[_to] += _value;
        Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);        
        _transfer(_from, _to, _value);
        allowance[_from][msg.sender] -= _value;
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract CustomToken is BaseToken {
    function CustomToken() public {
        totalSupply = 2.6 * 100000000 * 1000000;           
        owner = 0x690Ae62C7b56F08d0d712c6e4Ef1103a5A0B38F9;      
        balances[owner] = totalSupply; 
        name = &#39;Garlic Chain&#39;; 
        symbol = &#39;GLC&#39;;                    
        decimals = 6; 
        Transfer(address(0), owner, totalSupply);
    }    
}