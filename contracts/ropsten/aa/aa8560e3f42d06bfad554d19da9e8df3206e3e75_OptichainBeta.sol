/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// Interfaz estándar de un token ERC20
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function sumTotal() public view returns (uint);
    function numTokens(address tokenOwner) public view returns (uint balance);
    function transferirTokens(address receptor, uint tokens) public returns (bool success);
    function transferirEmisorReceptor(address emisor, address receptor, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Libreria SafeMath
// ----------------------------------------------------------------------------
contract SafeMath {
    //Suma sin overflow
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    //Resta sin overflow
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); 
        c = a - b; 
    } 
    //Multiplicación sin overflow
    function safeMul(uint a, uint b) public pure returns (uint c) { 
        c = a * b; 
        require(a == 0 || c / a == b); 
    }
    //División sin overflow
    function safeDiv(uint a, uint b) public pure returns (uint c) { 
        require(b > 0);
        c = a / b;
    }
}


contract OptichainBeta is ERC20Interface, SafeMath {
    string public name; // nombre del token
    string public symbol; // abreviatura del token
    uint8 public decimals; // decimales totales del token

    uint256 public _totalSupply; // suministro total de tokens

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "OptichainBeta";
        symbol = "OCB";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function sumTotal() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function numTokens(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

  
    function transferirTokens(address receptor, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[receptor] = safeAdd(balances[receptor], tokens);
        emit Transfer(msg.sender, receptor, tokens);
        return true;
    }

    function transferirEmisorReceptor(address emisor, address receptor, uint tokens) public returns (bool success) {
        balances[emisor] = safeSub(balances[emisor], tokens);
        allowed[emisor][msg.sender] = safeSub(allowed[emisor][msg.sender], tokens);
        balances[receptor] = safeAdd(balances[receptor], tokens);
        emit Transfer(emisor, receptor, tokens);
        return true;
    }
}