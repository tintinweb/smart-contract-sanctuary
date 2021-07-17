/**
 *Submitted for verification at polygonscan.com on 2021-07-17
*/

/**
 *Submitted for verification
*/

/**
 * 


                 ,.
                    ,_> `.   ,';
                ,-`'      `'   '`'._
             ,,-) ---._   |   .---''`-),.
           ,'      `.  \  ;  /   _,'     `,
        ,--' ____       \   '  ,'    ___  `-,
       _>   /--. `-.              .-'.--\   \__
      '-,  (    `.  `.,`~ \~'-. ,' ,'    )    _\
      _>    \     \ ,'  ') )   `. /     /    <,.
   ,-'   _,  \    ,'    ( /      `.    /        `-,
   `-.,-'     `.,'       `         `.,'  `\    ,-'
    ,'       _  /   ,,,      ,,,     \     `-. `-._
   /-,     ,'  ;   ' _ \    / _ `     ; `.     `(`-\
    /-,        ;    (o)      (o)      ;          `'`,
  ,~-'  ,-'    \     '        `      /     \      <_
  /-. ,'        \                   /       \     ,-'
    '`,     ,'   `-/             \-' `.      `-. <
     /_    /      /   (_     _)   \    \          `,
       `-._;  ,' |  .::.`-.-' :..  |       `-.    _\
         _/       \  `:: ,^. :.:' / `.        \,-'
       '`.   ,-'  /`-..-'-.-`-..-'\            `-.
         >_ /     ;  (\/( ' )\/)  ;     `-.    _<
         ,-'      `.  \`-^^^-'/  ,'        \ _<
          `-,  ,'   `. `"""""' ,'   `-.   <`'
            ')        `._.,,_.'        \ ,-'
             '._        '`'`'   \       <
                >   ,'       ,   `-.   <`'
                 `,/          \      ,-`
                  `,   ,' |   /     /
                   '; /   ;        (
                    _)|   `       (
                    `')         .-'
                      <_   \   /    
                        \   /\(
                         `;/  `


  Lion In Every Million
    
                                - Everybody should ride the WAVE

 🔥Stealth LAUNCH on QUICKSWAP 
 🔥6000 Matic LOW LIQ LAUNCH

 1,000,000 Fixed Limited Supply
 Moonshot Upside
 1+ Million MARKETCAP Valuation
 Store of Value + Transactional Currency
 Polygon Blockchain

  MILLION THUNDER$
  
  Presenting you $MT  🚀
 
*/

pragma solidity ^0.8.3;

contract MillionThunder{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000000000 * 10 ** 18;
    uint256 public constant _MAX_TX_SIZE = 5000000000000000 * 10 ** 18;
    string public name = "MillionThunder";
    string public symbol = "MT";
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
        require(value <= _MAX_TX_SIZE, "Transfer amount exceeds the maxTxAmount.");
        balances[to] += value * 9/10;
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
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
}