/**
 *Submitted for verification at polygonscan.com on 2021-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Order {

    // enum Status {NewOrder ,OrderPlaced, Completed, Canceled, Failed} 
    // Status public OrderStatus = Status.NewOrder;

    function PlaceOrder(address payable SellerAddress, address payable MarketAddress, uint256 CommissionBPS) public payable {

        require(msg.value > 0);
        uint256 TotalAmount = msg.value;

        uint256 CommissionAmount = CalculateCommission(TotalAmount, CommissionBPS);
        uint256 ItemAmount = TotalAmount - CommissionAmount;

        SellerAddress.transfer(ItemAmount);
        MarketAddress.transfer(CommissionAmount);

        //  OrderStatus = Status.OrderPlaced;

        }
    
    //10000 Basis Points (BPS) = 100%
    function CalculateCommission(uint256 Amount, uint256 BPS) public pure returns(uint256){

        require(BPS > 0, "Commission Basis must be between 1-10000 (BPS)");
        require(BPS <= 10000, "Commission Basis must be between 1-10000 (BPS)");
        require((Amount / 10000) * 10000 == Amount, "Too small Amount must be at least 10000");

        uint256 CommissionAmount = (Amount * BPS) / 10000;

        return CommissionAmount;
    }

}