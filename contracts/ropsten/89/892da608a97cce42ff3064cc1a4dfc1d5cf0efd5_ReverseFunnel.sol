// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ReverseFunnel{
    address ownerAddr;
    incomingCrypto[]  pastIncomes;
    uint256 moneyPool;
    
    uint256[]  aray;
    
    event event_calculatingIntererst(uint256 poolSize);
    
    
    struct incomingCrypto{
        address senderAddr;
        uint256 amount;
        uint256 receiveTime;
    }
    
    constructor(address owner){
        moneyPool = 0;
        ownerAddr = owner;
    }
    
    //an outside address will call this once a day using the owners address
    function onNewDay() public onlyOwner{
        //go through each transactions to process the interests
        for(uint256 i = 0; i < pastIncomes.length; i++)
        {
            processAddress(pastIncomes[i]);
        }
        emit event_calculatingIntererst(moneyPool);
    }
    
    modifier onlyOwner{
        //only the owner can call this function
        require(msg.sender == ownerAddr, "only owner can call this");
        _;
    }
    
    function processAddress( incomingCrypto memory crypt) private {
        //address payed its due more than a day ago
        if(crypt.receiveTime < block.timestamp - 1 days)
        {
            //pay to address if there is enough money in the pool
            if(moneyPool >= crypt.amount/10)
            {
                payable(crypt.senderAddr).send(crypt.amount/10);
                moneyPool -= crypt.amount/10;
            }
            //break down the contract if the pool is out of money
            else{
                terminate();
            }
        }
    }
    
    //whenever receive new payments, set up new struct
    receive() external payable{
        //ccreate and add to past income list
        incomingCrypto memory newP =  incomingCrypto({senderAddr: msg.sender, amount:msg.value,receiveTime: block.timestamp});
        pastIncomes.push(newP);
        
        //up the money pool
        moneyPool += msg.value;
    }
    
    
    // only availible to owner
    function terminate() private{
        selfdestruct(payable(ownerAddr));
    }
}