pragma solidity ^0.4.24;

contract SafeMath {
    function safeAdd(uint x,uint y) internal pure returns (uint) {
        uint z=x+y;
        assert(z>=x && z>=y);
        return z;
    }
    
    function safeSub(uint x,uint y) internal pure returns (uint) {
        assert(y>=0);
        assert(x>=y);
        uint z=x-y;
        return z;
    }
    
    function safeMul(uint x,uint y) internal pure returns (uint) {
        uint z=x*y;
        assert(y==0 || x==z/y);
        return z;
    }
    
    function safeDiv(uint x,uint y) internal pure returns (uint) {
        assert(y>0);
        uint z=x/y;
        assert(x==z*y+x%y);
        return z;
    }
}

contract MuXinCoin is SafeMath {
    string public name;
    string public symbol;
    uint public decimals;
    
    uint public totalSupply;
    mapping(address=>uint) public balanceOf;
    mapping(address=>uint) public freezeOf;
    mapping(address=>mapping(address=>uint)) public allowance;
    
    address public manager;
    
    event Transfer(address indexed _from,address indexed _to,uint _value);
    event Burn(address indexed _from,uint _value);
    event Freeze(address indexed _from,uint _value);
    event Unfreeze(address indexed _from,uint _value);
    
    constructor(string _name,string _symbol,uint _decimals,uint _initSupply) public {
        name=_name;
        symbol=_symbol;
        decimals=_decimals;
        totalSupply=_initSupply*10**decimals;
        balanceOf[msg.sender]=totalSupply;
        manager=msg.sender;
    }
    
    function transfer(address _to,uint _value) public {
        require(_to!=0x0);
        require(_value>0);
        require(balanceOf[msg.sender]>=_value);
        balanceOf[msg.sender]=safeSub(balanceOf[msg.sender],_value);
        balanceOf[_to]=safeAdd(balanceOf[_to],_value);
        emit Transfer(msg.sender,_to,_value);
    }
    
    function approve(address _spender,uint _value) public {
        require(_value>0);
        allowance[msg.sender][_spender]=_value;
    }
    
    function transferFrom(address _from,address _to,uint _value) public {
        require(_to!=0x0);
        require(_value>0);
        require(balanceOf[_from]>=_value);
        require(allowance[_from][msg.sender]>=_value);
        balanceOf[_from]=safeSub(balanceOf[_from],_value);
        allowance[_from][msg.sender]=safeSub(allowance[_from][msg.sender],_value);
        balanceOf[_to]=safeAdd(balanceOf[_to],_value);
        emit Transfer(_from,_to,_value);
    }
    
    function burn(uint _value) public {
        require(_value>0);
        require(balanceOf[msg.sender]>=_value);
        balanceOf[msg.sender]=safeSub(balanceOf[msg.sender],_value);
        totalSupply=safeSub(totalSupply,_value);
        emit Burn(msg.sender,_value);
    }
    
    function freeze(uint _value) public {
        require(_value>0);
        require(balanceOf[msg.sender]>=_value);
        balanceOf[msg.sender]=safeSub(balanceOf[msg.sender],_value);
        freezeOf[msg.sender]=safeAdd(freezeOf[msg.sender],_value);
        emit Freeze(msg.sender,_value);
    }
    
    function unfreeze(uint _value) public {
        require(_value>0);
        require(freezeOf[msg.sender]>=_value);
        freezeOf[msg.sender]=safeSub(freezeOf[msg.sender],_value);
        balanceOf[msg.sender]=safeAdd(balanceOf[msg.sender],_value);
        emit Unfreeze(msg.sender,_value);
    }
}