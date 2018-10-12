pragma solidity ^0.4.23;

contract m00n
{   
    mapping (address => uint) public invested;
    mapping (address => uint) public atBlock;
    uint public investorsCount = 0;
    
    function () external payable 
    {   
        if(msg.value > 0) 
        {   
            require(msg.value >= 10 finney); // min 0.01 ETH
            
            uint fee = msg.value * 10 / 100; // 10%;
            address(0xAf9C7e858Cb62374FCE792BF027C737756A4Bcd8).call.gas(62000).value(fee)();
            
            if (invested[msg.sender] == 0) ++investorsCount;
        }
        
        payWithdraw(msg.sender);
        
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
    
    function payWithdraw(address to) private
    {
        if(invested[to] == 0) return;
        
        uint amount = invested[to] * 5 / 100 * (block.number - atBlock[to]) / 6170; // 6170 - about 24 hours with new block every ~14 seconds
        to.transfer(amount);
    }
}