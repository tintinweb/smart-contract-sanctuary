/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: Apache-2.0
// 2021 (c) Cryptollama
pragma solidity >=0.4.0 <0.7.0;

contract Token {
    
    address private llamaContract = 0x0000000000000000000000000000000000000000;
    address private deployer = 0x0000000000000000000000000000000000000000;

    string public constant name = "Wool token";
    string public constant symbol = "WOOL";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 0;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Burn(address indexed from, uint tokens);
    event Mint(address indexed from, uint tokens);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    using SafeMath for uint256;
    
    modifier _onlyLlama {
        require(msg.sender == llamaContract);
        _;
    }

    constructor() public{
        balances[msg.sender] = totalSupply;
        deployer = msg.sender;
    }
    
    function setLlama(address llama) public {
        require(msg.sender == deployer);
        require(llamaContract == 0x0000000000000000000000000000000000000000);
        llamaContract = llama;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function mint(address who, uint256 amount) public _onlyLlama returns (uint) {
        totalSupply += amount;
        balances[who] += amount;
        emit Mint(who, amount);
        return amount;
    }
    
    function burn(uint256 amount) public returns (uint) {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        emit Burn(msg.sender, amount);
        return amount;
    }
    
    function burnFrom(address who, uint256 amount) public _onlyLlama returns (uint) {
        require(balances[who] >= amount);
        balances[who] -= amount;
        totalSupply -= amount;
        emit Burn(who, amount);
        return amount;
    }
}

library SafeMath {
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