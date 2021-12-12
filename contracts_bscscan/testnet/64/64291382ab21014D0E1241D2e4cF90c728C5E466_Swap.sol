/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract Swap {
    // 一个usdt能兑换多少dada
    uint256 public price = 1000000000 * 10 ** 18;

    // 每一万u价格增加20%(price = price * 80 / 100) 
    uint256 boundary = 10000 * 10 ** 18;

    // 收U的地址
    address seller;
    // 存DADA的地址 
    address entrepot;

    // 输入USDT
    IERC20 inputToken = IERC20(0xce88973456fBb7B96156f7DBf15300F21A515FE5);
    // 兑换成dada
    IERC20 outputToken = IERC20(0xa8A4e617F8b2cbCa91673D046959781bA4c59326);

    // 总共卖出的总量(input)
    uint256 public sellTotalAmount;

    // 用户已经购买的数量(input)
    mapping(address => uint256) public userBuyAmount;
    uint256 userMaxBuy = 100*10**18;

    constructor(address _seller, address _entrepot) {
        seller = _seller;
        entrepot = _entrepot;
    }

    function swap(uint256 inputAmount) public {
        // 每个账户只能买100u;
        require(userBuyAmount[msg.sender] + inputAmount <= userMaxBuy);
        (bool overflow ,uint256 outputAmount) = getOutput(inputAmount);
        inputToken.transferFrom(msg.sender, seller, inputAmount);
        outputToken.transferFrom(entrepot,msg.sender, outputAmount);
        sellTotalAmount += inputAmount;
        userBuyAmount[msg.sender] += inputAmount;
        
        if(overflow) {
            price = price * 80 / 100;
        }
    }

    function getOutput(uint256 inputAmount) public view returns(bool,uint256) {
        
        bool overflow;
        uint256 levelOne = sellTotalAmount / boundary;
        uint256 levelTwo = (sellTotalAmount + inputAmount) / boundary;
        
        if(levelOne < levelTwo) {
            // 跨了两个价格 
            overflow = true;
            
            // 获取当前价格购买的数量
            uint256 inputAmountOne = boundary - sellTotalAmount % boundary;
            uint256 inputAmountTwo = inputAmount - inputAmountOne;
            uint256 priceTwo = price * 80 / 100;
            return(overflow,inputAmountOne * price + inputAmountTwo * priceTwo);
            
        } else {
            uint256 outputAmount = inputAmount * price;
            return (overflow,outputAmount);
        }
        
    }

}