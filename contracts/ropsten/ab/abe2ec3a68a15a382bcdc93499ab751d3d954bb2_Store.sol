/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;

contract Store{
    
    struct Customer {
        address upline;
        uint256 referrals;
        uint256 direct_bonus;
    }
    address public owner;
    constructor()public{
        owner=msg.sender;
    }
    
    mapping(address=>Customer) public customers;
    mapping(address=>mapping(uint8=>uint256)) public product;
    
    //setProduct
    function setProduct(address _add, uint8 _id,uint256 _amount) public{
        product[_add][_id]=_amount;
    }
    
    //setUpline
    function _setUpline(address _addr, address _upline) private {
            customers[_addr].upline = _upline;
            customers[_upline].referrals++;
        }
        
    //purchaseProduct
    function purchaseProduct(address _add, uint8 _id)public{
       // msg.sender.transfer(product[_add][_id]*5/100);
        
        //refferals_direct_bunuses
        address refferal1=customers[_add].upline;
        address refferal2=customers[refferal1].upline;
        address refferal3=customers[refferal2].upline;
        customers[refferal1].direct_bonus =product[_add][_id]*5/100;
        customers[refferal2].direct_bonus =product[_add][_id]*3/100;
        customers[refferal3].direct_bonus =product[_add][_id]*1/100;
    }
}