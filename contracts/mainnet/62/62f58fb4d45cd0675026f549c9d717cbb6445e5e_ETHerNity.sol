pragma solidity ^0.4.24;

contract ETHerNity {
    
    struct Tx {
        address user;
        uint value;
    }
    
    address public owner;
    Tx[] public txs;
    bool blocking;
    
    uint constant MIN_ETHER = 0.01 ether;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier mutex() {
        blocking = true;
        _;
        blocking = false;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function() payable public {
        withReferrer(owner);
        
        if (msg.sender == owner) {
            dispatch();
        }
    }
    
    function withReferrer(address referrar) payable public {
        if (blocking) return;
        
        owner.send(msg.value / 10);
        referrar.send(msg.value / 10);
        
        if (msg.value < MIN_ETHER)
            return;

        txs.push(Tx({
           user: msg.sender,
           value: msg.value / 30
        }));
    }
    
    function dispatch() onlyOwner mutex public {
        for(uint i = 0; i < txs.length; i++) {
            if (address(this).balance >= txs[i].value)
                txs[i].user.send(txs[i].value);
        }
            
    }

}