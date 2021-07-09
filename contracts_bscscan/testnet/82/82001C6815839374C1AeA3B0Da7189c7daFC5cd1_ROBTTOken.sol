// SPDX-License-Identifier: MIT

// v 3
// 0xBe195d83495b23a4779CfA8444C788D101077417
// 0xAe7a4460A95598E5367b15c6BC54A7a542e618B0
// 0x82001C6815839374C1AeA3B0Da7189c7daFC5cd1

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Owned.sol";
//import "./IERC20Interface.sol";

//contract ROBTTOken is IERC20Interface {
contract ROBTTOken is Owned  {

    using SafeMath for uint;    


    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;


    string public name   = "Robo Trader";
    string public symbol = "ROBT";
    uint8 public  decimals = 8;
    uint public   totalSupply =  1800000 * 10 **uint(decimals);


    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Testevent( string _msg);


    constructor()  {

        balances[msg.sender] = totalSupply;

    }


    function testevent( string memory _msg ) public returns(bool)
    {
        
        emit Testevent( _msg );
    
        return(true);
    }

//==================== functions ==============================


    function _totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    function _decimals() public view returns (uint8) {
        return decimals;
    }
    function _symbol() public view returns (string memory) {
        return symbol;
    }
    function _name() public view returns (string memory) {
        return name;
    }
    


    function getOwner() public view returns  (address) {
        return owner;
    }


    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }


    function transfer(address recipient, uint256 amount) public returns (bool) {    
        
        require( balanceOf(msg.sender) >= amount, 'Saldo insuficiente para operacao( Insufficient funds )');
        balances[ recipient ]    +=  amount;
        balances[msg.sender] -= amount;
        
        emit Transfer(msg.sender, recipient, amount);

        return true;
    }


    function transfer2(address recipient, uint256 amount) public returns (bool) {    
        require( balanceOf(msg.sender) >= amount, 'Saldo insuficiente para operacao( Insufficient funds )');
        balances[ recipient ]    +=  amount;
        balances[msg.sender] -= amount;
        
        return true;
    }



    function transferFrom(address from, address to, uint tokens) public returns (bool success) {

        balances[from] = balances[from].sub(tokens);
        
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    
        balances[to] = balances[to].add(tokens);

        emit Transfer(from, to, tokens);

        return true;

    }


    //==============================================
    


//---------- Allowence -------

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }



}