/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

// SPDX-License-Identifier: GPL-3.0
/**
 *Submitted for verification at BscScan.com on 2021-06-25
*/

pragma solidity = 0.8.6;

interface IPancakeCallee {
    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
interface IPancakePair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}
interface WBNB{
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
}
contract flashloan is IPancakeCallee{
    uint256 fee=0;
    uint256 amount=0;
    WBNB wbnb = WBNB(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
    IPancakePair LP = IPancakePair(0xf8B09Fe16E357C7068e13649E8e307d3DF795ad3);
    
    function loan() public payable{
        fee = msg.value;
        amount = fee*9975/25;
        LP.swap(amount,0,address(this),new bytes(1));//vay tiền
    }   
    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) override external{
        //
        //Đang cóĐang có tiền, so du la amount+fee
        //
        wbnb.deposit{value:fee}();
        wbnb.transfer(address(LP),amount+fee);//tra tien
    }
    
}