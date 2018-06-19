pragma solidity ^0.4.24;

contract TransEther{
    
    //조건
    //1. SmartContract 주소로 1이더를 받는 즉시  
    //2 99.9% 내 지갑 주소로 전송 bossAddress : 0x40e899a8a0Ca7d1a79b6b1bb0f03AD090F0Ad747
    //3. 나머지 0.1%는 특정 주소로 전송        otherAdderss : 

    address owener ;
    address bossAddr =   0x40e899a8a0Ca7d1a79b6b1bb0f03AD090F0Ad747;     // 99.9% 받는 주소1 (주소 변경 시 이곳 수정)
    address customAddr = 0xEc61C896C8F638e3970ed729E072f7AB03a10b5A;     // 0.1 받는 주소2   (주소 변경 시 이곳 수정)
    mapping (address => uint) public balances;
    
    event EthValueLog(address from, uint vlaue,uint cur);
    
    constructor() public{
        owener = msg.sender;
    }
    
    function() payable public{
        
        uint value = msg.value; 
        require(msg.value > 0);
        
        uint firstValue = value * 999 / 1000;
        uint secondValue = value * 1 / 1000;
        
        //bool sendok1 = msg.sender.call.value(firstValue).gas(21000)();
        //bool sendok2 = msg.sender.call.value(secondValue).gas(21000)();
        
         bossAddr.transfer(firstValue);
         emit EthValueLog(bossAddr,firstValue,now);
         
         customAddr.transfer(secondValue);
         emit EthValueLog(customAddr,secondValue,now);
        
    } 
}