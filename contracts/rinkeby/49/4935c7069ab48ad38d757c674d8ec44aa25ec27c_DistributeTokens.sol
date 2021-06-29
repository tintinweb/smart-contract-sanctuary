/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.4.24;

contract DistributeTokens {
    address public owner; 
    address[] public investors; 
    uint[] public investorTokens; 

    constructor() public {
        owner = msg.sender;
    }

    //投資
    function invest() public payable {
        investors.push(msg.sender);  //push 就是把東西加進去陣列裡面
        investorTokens.push(msg.value / 100); 
    }

    //分配獎金
    function distribute() public {
        require(msg.sender == owner); // only owner
        
        //限制只能每天領一次！
        
        //問題發生於當invest的人很多(investors很大)時，用for loop進行transfer, gas fee有可能超過一個block的上限
        // 分析：
        // 真正的天天分紅卡了 400 多顆以太幣，最後被投資者罵翻！
        // 一個transfer耗費2300 gas，目前一個block極限是塞滿 800 萬gas
        // 8,000,000 / 2300 等於大約可以投資的人數 3478 人
        
        for(uint i = 0; i < investors.length; i++) { 
            investors[i].transfer(investorTokens[i]); 
        }
    }
}