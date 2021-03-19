pragma solidity ^0.5.7;

import "kzNurERC20_v1.sol";

contract NurToken is ERC20Interface {
    string public constant symbol = "NUR";
    string public constant name = "Nur Token";
    uint8 public constant decimals = 18;

    
    // Total Supply
    uint private constant __totalSupply = 1000000;
    mapping (address => uint) private __balanceOf;
    mapping (address => mapping(address => uint)) private __allowance;
    
    constructor() public {
        __balanceOf[msg.sender] = __totalSupply;
    }
    
    function totalSupply() view public returns (uint _totalSupply){
        _totalSupply = __totalSupply;
    }
    
    function balanceOf (address _addr) view public returns (uint balance) {
        return __balanceOf [_addr];
    }
    
    function transfer(address _to, uint _value) public returns (bool success) {
        if (_value > 0 && _value <= balanceOf(msg.sender)) {
            __balanceOf[msg.sender] -= _value;
            __balanceOf[_to] += _value;
            return true;
        }
        return false;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        if (__allowance[from][msg.sender] > 0 && tokens > 0 &&
        __allowance[from][msg.sender] >= tokens ) {
            __balanceOf[from] -= tokens;
            __balanceOf[to] += tokens;
            return true;
            
        }
        return false;
    }
    
    function approve(address spender, uint tokens ) public returns (bool success) {
        __allowance[msg.sender][spender] = tokens;
        return true;
    }
    
    function allowance(address tokenOwner, address spender) view public returns (uint remaining) {
        return __allowance[tokenOwner][spender];
    }
}