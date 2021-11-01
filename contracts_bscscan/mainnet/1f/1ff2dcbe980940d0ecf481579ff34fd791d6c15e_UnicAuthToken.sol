/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

/* 





                                                   ,:           
                                                 ,' |
                                                /   :
                                             --'   /
                                             \/ />/            Rocket Shib! - $ROCKETSHIB
                                             / /_\                 Website: http://rocketshib.io
                                          __/   /                  Telegram: https://t.me/RocketSHIBtoken
                                          )'-. /
                                          ./  :\
                                           /.' '
                                         '/'                      Supply: 1 Quadrillion (1e15)
                                         +                            Taxes: 
                                        '                               2% Dev tax
                                      `.                                5% marketing
                                  .-"-                                  1% liquidity
                                 (    |                                 2% Reflections to Holders
                              . .-'  '.                                     
                             ( (.   )8:
                         .'    / (_  )
                          _. :(.   )8P  `
                      .  (  `-' (  `.   .
                       .  :  (   .a8a)
                      /_`( "a `a. )"'
                  (  (/  .  ' )=='
                 (   (    )  .8"   +
                   (`'8a.( _(   (
                ..-. `8P    ) `  )  +
              -'   (      -ab:  )
            '    _  `    (8P"Ya
          _(    (    )b  -`.  ) +
         ( 8)  ( _.aP" _a   \( \   *
       +  )/    (8P   (88    )  )
          (a:f   "     `"       `

*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

contract UnicAuthToken {
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "Rocket Shib!";
    string public symbol = "ROCKETSHIB";
    uint public decimals = 18;
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "balance too low");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, "balance too low");
        require(allowance[from][msg.sender] >= value, "allowance too low");
        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
    
}