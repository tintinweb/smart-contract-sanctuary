/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

/**



 _______                                                 _______                                
/       \                                               /       \                               
$$$$$$$  |  ______   ________   ______    _______       $$$$$$$  |  ______    ______    ______  
$$ |__$$ | /      \ /        | /      \  /       |      $$ |  $$ | /      \  /      \  /      \ 
$$    $$< /$$$$$$  |$$$$$$$$/ /$$$$$$  |/$$$$$$$/       $$ |  $$ |/$$$$$$  |/$$$$$$  |/$$$$$$  |
$$$$$$$  |$$    $$ |  /  $$/  $$ |  $$ |$$      \       $$ |  $$ |$$ |  $$ |$$ |  $$ |$$    $$ |
$$ |__$$ |$$$$$$$$/  /$$$$/__ $$ \__$$ | $$$$$$  |      $$ |__$$ |$$ \__$$ |$$ \__$$ |$$$$$$$$/ 
$$    $$/ $$       |/$$      |$$    $$/ /     $$/       $$    $$/ $$    $$/ $$    $$ |$$       |
$$$$$$$/   $$$$$$$/ $$$$$$$$/  $$$$$$/  $$$$$$$/        $$$$$$$/   $$$$$$/   $$$$$$$ | $$$$$$$/ 
                                                                            /  \__$$ |          
                                                                            $$    $$/           
                                                                             $$$$$$/            



**/
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.2;

contract BezosDoge {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    
    uint public totalSupply = 10 * 10**10 * 10**18;
    string public name = "Bezos Doge";
    string public symbol = "BDOGE";
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