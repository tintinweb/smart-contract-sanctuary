/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

/**
BonoBonk

______  _____ _   _ ___________  _____ _   _  _   __
| ___ \|  _  | \ | |  _  | ___ \|  _  | \ | || | / /
| |_/ /| | | |  \| | | | | |_/ /| | | |  \| || |/ / 
| ___ \| | | | . ` | | | | ___ \| | | | . ` ||    \ 
| |_/ /\ \_/ / |\  \ \_/ / |_/ /\ \_/ / |\  || |\  \
\____/  \___/\_| \_/\___/\____/  \___/\_| \_/\_| \_/
                                                    
                                                    
Website: https://www.bonobonk.com
Telegram: https://t.me/bonobonkbsc
Twitter: https://twitter.com/BONOBONKBSC
*/

pragma solidity ^0.8.2;

contract BonoBonk {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000;
    string public name = "BonoBonk";
    string public symbol = "$BONOBONK";
    uint public decimals = 2;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
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
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}