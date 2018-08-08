pragma solidity ^0.4.24;

contract ERC20Interface {
function name() public view returns (string _name);
function symbol() public view returns (string _symbol);
function decimals() public view returns (uint8 _decimals);
function totalSupply() view public returns (uint256 totalSupply_);
// function balanceOf(address _owner) view returns (uint256 balance);
// function transfer(address _to, uint256 _value) returns (bool success);
// function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
// function approve(address _spender, uint256 _value) returns (bool success);
// function allowance(address _owner, address _spender) view returns (uint256 remaining);
// event Transfer(address indexed _from, address indexed _to, uint256 _value);
// event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MyToken is ERC20Interface {
    // 12.210000000000000000
    uint256 totalSupply_ = 2100000000000000000000;
    
    function name() view public returns (string _name) {
        return "Jungle";
    }

    function symbol() view public returns (string _symbol) {
        return "JUNGLE";
    }
 
    function decimals() view public returns (uint8 _decimals) {
        return 18;
    }    

    function totalSupply() view public returns (uint256 _totalSupply) {
        return totalSupply_;
    }    
    
}