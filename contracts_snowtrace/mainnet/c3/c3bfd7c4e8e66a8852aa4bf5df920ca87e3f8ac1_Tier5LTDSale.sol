// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./SafeERC20.sol";

contract Tier5LTDSale is Context{
    
    address private _owner;
    address private _payto;
    uint256 private dealends;
    mapping(string => uint256) private _products;
    mapping(address => string) private _buyers;
    mapping(address => uint256) private _buyersPaid;

    IERC20 private MUG;
    constructor(address payto, address paywith){
        _owner = msg.sender;
        _payto = payto;
        dealends = 1643673601;
        MUG =IERC20(paywith);
    }
    //function that allows products to be purchased at current price with $MUG
    //requires sender has approved this contract at least product cost
    function buyLTD( string memory product, string memory email) public virtual{
        require(block.timestamp <= dealends, "Deal is over");
        require(MUG.allowance(msg.sender, address(this)) >= doMath(_products[product]), "Haven't approved me to buy LTD");      
        MUG.transferFrom(msg.sender, _payto, doMath(_products[product]));
        _buyersPaid[msg.sender] += doMath(_products[product]);
        _buyers[msg.sender] = email;
    }
    //returns the cost in $MUG for the selected product
    function getProductCost(string memory product) public view virtual returns (uint256){
        return _products[product];
    }
    //returns the amount in "wei" required to approve to buy selected product
    function getProductApprovalCost(string memory product) public view virtual returns (uint256){
        return doMath(_products[product]);
    }
    //allows admin to add new products and their cost or update existing products and their cost
    function add_update_product_cost(string memory product, uint256 cost) public virtual{
        require(msg.sender == _owner, "You are not Jon Vaughn");
        _products[product] = cost;
    }
    //allows contract owner to get the email address of a buyer to set up their account
    function getBuyersEmail(address buyer) public view virtual returns (string memory){
        require(msg.sender == _owner, "Only the onwer can get this data");
        return _buyers[buyer];
    }
    //allows contract owner to get the amount paid by someone
    function getTotalPaid(address buyer) public view virtual returns (uint256){
        require(msg.sender == _owner, "You are not the owner");
        return _buyersPaid[buyer]/(10**18);
    }
    //function that shows you where funds are being sent
    function showPayTo() public view virtual returns (address){
        return _payto;
    }
    //function that returns this contracts address 
    function thisContractAddresss() public view virtual returns (address){
        return address(this);
    }
    //function that shows anyone when this deal is over
    function dealEnds() public view virtual returns (uint256){
        return dealends;
    }
    //function that allows me to update when the deal ends
    function updateDealEnds(uint256 newDate)public virtual{
        require(msg.sender == _owner, "Only owner can change this");
        dealends = newDate;
    }
    //function that converts base to wei considering 18 decimlas
    function doMath(uint256 base) public view virtual returns (uint256){
        return base * (10**18);
    }
}