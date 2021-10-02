/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

pragma solidity ^0.4.23;
/*

WHO IS ALADEEN?
His Highness, 
His Excellency, 
The Supreme Leader of all Wadiyans, 
Admiral General Haffaz bin Omar Al Aladeen, 
By the Grace of Allah and Unanimous Acclamation of the People, 
Beloved Oppressor, 
President and Prime Minister Haffaz Aladeen is the de facto head of state of the Socialist Republic of Wadiya.
Assuming leadership after the death of his father, Omar Aladeen, 
Haffaz Aladeen has ruled the country under a Socialistic Nationalist political ideology, 
aligning himself both economically and militarily with states such as North Korea, Ba’athist Syria, and China.

*/

contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value)public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); 
        c = a - b;
        }
        
        function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; 
        require(a == 0 || c / a == b); } 
        
        function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

contract Aladeen is ERC20, SafeMath {
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() public {
        name = "Aladeen";
        symbol = "ALAD";
        decimals = 18;
        _totalSupply = 7000000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
        function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
       function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
        function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
        function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

}