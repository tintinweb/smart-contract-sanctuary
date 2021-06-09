/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

/**


 ___              _                 _               
(  _`\           ( )               (_)              
| |_) )  __     _| | _ __   _      | |  ___   _   _ 
| ,__/'/'__`\ /'_` |( '__)/'_`\    | |/' _ `\( ) ( )
| |   (  ___/( (_| || |  ( (_) )   | || ( ) || (_) |
(_)   `\____)`\__,_)(_)  `\___/'   (_)(_) (_)`\___/'
                                                    
                                                    


**/
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.2;

contract PedroInu {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    
    uint public totalSupply = 10 * 10**11 * 10**18;
    string public name = "Pedro Inu";
    string public symbol = "PEDRO";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        return true;
        
    }
}