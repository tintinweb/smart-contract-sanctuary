pragma solidity ^0.4.23;
contract NBminer {
    mapping (address=>uint) balances;
    mapping (address=>uint) powers;
    
    uint public decimals = 2;
    
    constructor() public{
        
    }
    
    function miner() public returns(uint) {
        uint po = powers[msg.sender];
        uint nb;
        // power += 10**uint(decimals);
        if (po < 60) {
            po += 1;
        }
        else {
            po = 60;
        }
        
        nb = po + (po*po*2)/13;
        
        powers[msg.sender] = po;
        balances[msg.sender] = nb;
        
        return nb;
    }
    
    function get_power(address addr) public view returns(uint){
        return powers[addr];
    }
    
    function get_nb(address addr) public view returns(uint){
        return balances[addr];
    }
}