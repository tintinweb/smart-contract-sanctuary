/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.5.0;

contract Bank {
    struct Compte{
        uint value;
        bool exist;
    }
    Compte[] listeCompte;
    mapping(address => Compte) listeDesComptes;
    address[] users;
    uint nbUsers;
    address creator;
   
   
    constructor() {
        nbUsers = 0;
        creator = msg.sender;
    }
   
   
    // event Transfer(address _from, address _to, uint _value);
   
    function register() public {
        if (listeDesComptes[msg.sender].exist != true) {
            users.push(msg.sender);
            nbUsers++;
            Compte memory compteUser = Compte(0, true);
            listeDesComptes[msg.sender] = compteUser;
        }
    }
   
    function safeAdd(uint a, uint b) private pure returns(uint c){
           c = a + b;
           require(c >= a + b);
    }
   
    function safeSub(uint a, uint b) private pure returns(uint c){
        require(a >= b);
        c = a - b;
    }
   
   
    function deposit(uint amount) public view {
       Compte memory c = listeDesComptes[msg.sender];
       
       c.value = safeAdd(c.value, amount);
    }
   
    function withdraw(uint amount) public view  {
       Compte memory c = listeDesComptes[msg.sender];
       
       c.value = safeSub(c.value, amount);
    }
   
    function send(address to, uint amount) public view {
       Compte memory cto = listeDesComptes[to];
       
       withdraw(amount);
       cto.value = safeAdd(cto.value, amount);
    }
   
    function myBalance() public view returns(uint total) {
        Compte memory c = listeDesComptes[msg.sender];
        total = c.value;
    }
}