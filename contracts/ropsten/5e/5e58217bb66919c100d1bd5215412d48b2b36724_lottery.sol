pragma solidity ^0.4.0;
contract lottery{

    uint randNum;
    uint numAddresses = 0;
    address[] addresses;
    address owner;
    uint totalETH;
    
    function () public payable{
    }
    
    constructor() public payable{
        owner = msg.sender;
    }
    
    function getBalance() public returns (uint){
        return address(this).balance;
    }
    
    
    function buy() public payable{
        require (msg.value > 0);
        numAddresses += 1;
        addresses.push(msg.sender);
        totalETH += (msg.value);


        //payout when five enter contract
        if(numAddresses == 5){
            randNum = (uint)(blockhash(block.number-1)) % 5;

            //owner pays to winner
            addresses[randNum].transfer(totalETH);
            
            //nullify variables
            delete addresses[0];
            delete addresses[1];
            delete addresses[2];
            delete addresses[3];
            delete addresses[4];
            numAddresses = 0;
            randNum = 0;
        }
    }
}