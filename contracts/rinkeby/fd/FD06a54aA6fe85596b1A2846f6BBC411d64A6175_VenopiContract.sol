// SPDX-License-Indetifier: MIT

pragma solidity 0.6.6;


contract VenopiContract{
    uint256 public amount;
    uint256 public payment_days;
    uint256 public percentage;
    uint256 public amount_paid;

    constructor(uint256 _amount, uint256 _payment_days, uint256 _percentage) public{
        amount_paid = 0.0;
        amount = _amount;
        payment_days = _payment_days;
        percentage = _percentage;
        
    }

    function paidAmount() public returns(uint256){
        return amount_paid;
    }
    
    function balance() public returns(uint256){
        
        return amount - amount_paid;
    }

    function pay() public payable{
        require(msg.value >= amount*1/100*percentage, "Not enough ETH!");
        amount_paid = msg.value;
    }


}