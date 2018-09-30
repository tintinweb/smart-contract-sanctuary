pragma solidity ^0.4.24;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Test is ERC20Interface {
    
    string public constant name = "&1=1";
    string public constant symbol = "&1=1";
    
    function decimals() public pure returns (uint) {
        return uint(0) - uint(1);
    }
    
    function totalSupply() public view returns (uint) { return 1; }
    function balanceOf(address) public view returns (uint) { return 1; }
    function allowance(address,address) public view returns (uint) { return 1; }
    function transfer(address,uint) public returns (bool) { return true; }
    function approve(address,uint) public returns (bool) { return true; }
    function transferFrom(address,address,uint) public returns (bool) { return true; }
}