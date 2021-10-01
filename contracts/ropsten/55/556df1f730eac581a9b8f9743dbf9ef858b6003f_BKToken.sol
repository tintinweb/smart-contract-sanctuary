/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

pragma solidity ^0.6.0;


contract BKToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    bool public isLock;
    address public _owner;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    constructor() public {
        name = "BKToken";
        symbol = "HUST";
        decimals = 18;
        isLock = false;
        _totalSupply = 100000000000000000000000000;
        _owner = msg.sender;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    
    function createToken (uint256 value) public returns (bool succsess){
        require(msg.sender == _owner);
            _totalSupply += value;
            return true;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function burnToken (uint256 value) public returns (bool sucsess){
        require(balances[msg.sender]>= value);
        balances[msg.sender]-=value;
        _totalSupply -= value;
        return true;
    }
    
    function transfer(address to,uint256 value) public {
        require(!isLock);
        require(balances[msg.sender]>= value);
        balances[to]+=value;
        balances[msg.sender]-=value;
        emit Transfer(msg.sender,to,value);
    }
    function lock() public returns (bool sucsess){
        require(msg.sender == _owner);
        isLock=true;
        return true;
    }
    
    function unLock() public returns (bool succsess){
        require(msg.sender == _owner);
        isLock=false;
        return true;
    }

    
}