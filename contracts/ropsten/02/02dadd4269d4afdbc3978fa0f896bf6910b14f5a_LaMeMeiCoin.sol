pragma solidity ^0.4.24;

contract SafeMath {
    function safeAdd(uint x,uint y) internal pure returns(uint) {
        uint z=x+y;
        require(z>=x && z>=y);
        return z;
    }

    function safeSub(uint x,uint y) internal pure returns(uint) {
        require(x>=y);
        uint z=x-y;
        return z;
    }

    function safeMul(uint x,uint y) internal pure returns(uint) {
        uint z=x*y;
        require(y==0 || x==z/y);
        return z;
    }

    function safeDiv(uint x,uint y) internal pure returns(uint) {
        require(y>0);
        uint z=x/y;
        require(x==z*y+x%y);
        return z;
    }
}

contract LaMeMeiCoin is SafeMath {
    string public name;
    string public symbol;
    uint public decimals;

    mapping(address=>uint) public balanceOf;
    uint public totalSupply;
    mapping(address=>mapping(address=>uint)) public allowance;
    mapping(address=>uint) public freezeOf;

    address public manager;

    event Transfer(address indexed from,address indexed to,uint value);
    event Approve(address indexed from,address indexed to,uint value);
    event Burn(address indexed from,uint value);
    event Freeze(address indexed from,uint value);
    event Unfreeze(address indexed from,uint value);

    constructor(string _name,string _symbol,uint _decimals,uint initSupply) public {
        name=_name;
        symbol=_symbol;
        decimals=_decimals;
        totalSupply=initSupply*10**decimals;
        balanceOf[msg.sender]=totalSupply;
        manager=msg.sender;
    }

    function _transfer(address from,address to,uint value) private {
        require(to!=0x0);
        require(value>0);
        require(balanceOf[from]>=value);
        balanceOf[from]=safeSub(balanceOf[from],value);
        balanceOf[to]=safeAdd(balanceOf[to],value);
        emit Transfer(from,to,value);
    }

    function transfer(address to,uint value) public {
        _transfer(msg.sender,to,value);
    }

    function approve(address spender,uint value) public {
        require(spender!=0x0);
        require(value>0);
        allowance[msg.sender][spender]=value;
        emit Approve(msg.sender,spender,value);
    }

    function transferFrom(address from,address to,uint value) public {
        require(allowance[from][msg.sender]>=value);
        allowance[from][msg.sender]=safeSub(allowance[from][msg.sender],value);
        _transfer(from,to,value);
    }

    function burn(uint value) public {
        require(value>0);
        require(balanceOf[msg.sender]>=value);
        balanceOf[msg.sender]=safeSub(balanceOf[msg.sender],value);
        totalSupply=safeSub(totalSupply,value);
        emit Burn(msg.sender,value);
    }

    function freeze(uint value) public {
        require(value>0);
        require(balanceOf[msg.sender]>=value);
        balanceOf[msg.sender]=safeSub(balanceOf[msg.sender],value);
        freezeOf[msg.sender]=safeAdd(freezeOf[msg.sender],value);
        emit Freeze(msg.sender,value);
    }

    function unfreeze(uint value) public {
        require(value>0);
        require(freezeOf[msg.sender]>=value);
        freezeOf[msg.sender]=safeSub(freezeOf[msg.sender],value);
        balanceOf[msg.sender]=safeAdd(balanceOf[msg.sender],value);
        emit Unfreeze(msg.sender,value);
    }
}