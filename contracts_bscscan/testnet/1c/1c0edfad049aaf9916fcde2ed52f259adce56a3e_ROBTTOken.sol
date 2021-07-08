// SPDX-License-Identifier: MIT

// v 3
// 0x60471aFea8419334F079bAA4FcBA3d48e661aa01
// 0x15974B426BAc4aaECEF81428628ce642F030cc81
// 0xF49707846D5d196b56911eA991633E4385F51F25
// 0xae9B0afb6fBe9A19d00873471CD316f21ddc49cf
// 0x2543010bEa6614fb6400be41aa140523047AC761
// 0x1C0EDfAd049aAF9916FCdE2Ed52f259Adce56a3E

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

        emit Testevent( "um");

        balances[from] = balances[from].sub(tokens);

        emit Testevent( "dois");

        allowed[msg.sender][from] = allowed[msg.sender][from].sub(tokens);

        emit Testevent( "tres");

        balances[to] = balances[to].add(tokens);

        emit Testevent( "quadro");
        
        emit Transfer(from, to, tokens);

        return true;

    }


    //==============================================
    

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

//        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

   }
    

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