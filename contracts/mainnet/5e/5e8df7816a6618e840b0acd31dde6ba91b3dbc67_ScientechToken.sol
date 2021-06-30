/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity ^ 0.8.2;

library SafeMath { 
    //SPDX-License-Identifier: <SPDX-License>
    function sub(uint a, uint b) internal pure returns (uint) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint a, uint b) internal pure returns (uint) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

contract ScientechToken{
    //SPDX-License-Identifier: <SPDX-License>
    mapping (address => uint) public balances;
    mapping(address => mapping (address => uint))public allowed;
    uint public totalSupply = 1000000000 * 10 ** 2;
    string public name = "ScienTech Token";
    string public symbol = "STT";
    uint public decimals = 2;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    using SafeMath for uint;
    
    constructor(){
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint numTokens) public returns (bool) {
    require(numTokens <= balances[msg.sender], 'Insufficient Balance');
    balances[msg.sender] = balances[msg.sender].sub(numTokens);
    balances[receiver] = balances[receiver].add(numTokens);
    emit Transfer(msg.sender, receiver, numTokens);
    return true;
    }
    
    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner], 'Balance Too Low');    
        require(numTokens <= allowed[owner][msg.sender],'Allowance too low');
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        Transfer(owner, buyer, numTokens);
        return true;
    }
}