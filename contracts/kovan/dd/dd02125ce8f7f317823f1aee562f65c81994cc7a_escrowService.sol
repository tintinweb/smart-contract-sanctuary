/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import "../ILendingPool.sol";

import "../ILendingPoolAddressesProvider.sol";


import "../IWETHGateway.sol";

import "../IERC20.sol";

import "../Ownable.sol";




contract escrowService is Ownable{
    
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE }
    
    uint public contractLiabilities;
        
    struct transaction_details{
        State state;
        address payable seller_address;
        uint256 transaction_value_in_wei;
    }
    mapping(address => transaction_details) transactions;
    
    IERC20 public aToken = IERC20(0x87b1f4cf9BD63f7BBD3eE1aD04E8F52540349347);

    address private lendingPoolAddress;
    

    address private lpAddressProviderAddress = 0x88757f2f99175387aB4C6a4b3067c77A695b0349;

    address private WETHGatewayAddress = 0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70;

    ILendingPool private lendingPool;

    ILendingPoolAddressesProvider private provider;

    IWETHGateway private wETHGateway;
    
    constructor() public {

        provider = ILendingPoolAddressesProvider(lpAddressProviderAddress);
        lendingPoolAddress = provider.getLendingPool();
        lendingPool = ILendingPool(lendingPoolAddress);
        wETHGateway = IWETHGateway(WETHGatewayAddress);
    }

    
    
    function newTransaction(address payable sellerAddress) external payable {
        require(msg.value > 0, "Transaction value must be larger than zero");
        require(sellerAddress != payable(0), "Seller address must be given");
        require(transactions[msg.sender].seller_address == payable(0), "This address already has a transaction pending");
        transactions[msg.sender] = transaction_details(State.AWAITING_DELIVERY, sellerAddress, msg.value);
        contractLiabilities = contractLiabilities + msg.value;
        depositETH();
    }
    
    function confirmDelivery() external{
        require(transactions[msg.sender].state == State.AWAITING_DELIVERY, "Cannot confirm delivery");
        require(withdrawETH(uint256(transactions[msg.sender].transaction_value_in_wei), transactions[msg.sender].seller_address), "Withdraw from Aave failed");
        contractLiabilities = contractLiabilities - transactions[msg.sender].transaction_value_in_wei;
        transactions[msg.sender].state = State.COMPLETE;
        transactions[msg.sender].seller_address = payable(0);
        
        
    }
    
    function getContractBalance() public view returns(uint){
     return address(this).balance;
    }
    
    function getAtokenBalance() public view returns(uint256) {
        return (aToken.balanceOf(address(this)));
    }
    
    function getTransaction(address fetchAddress) public view returns(uint, address) {
        if (transactions[fetchAddress].state == State.AWAITING_DELIVERY) {
            return (transactions[fetchAddress].transaction_value_in_wei, transactions[fetchAddress].seller_address);
        }else{
            return (0, address(0));
        }
    }
    

    function depositETH() internal {
        wETHGateway.depositETH{value: msg.value}(lendingPoolAddress, address(this), 0);
    }   
    
    function withdrawETH(uint256 amount, address payable receiveAddress) internal returns(bool){
        require(aToken.approve(WETHGatewayAddress, amount), "Approve failed");
        require(aToken.allowance(payable(this), WETHGatewayAddress) == amount, "allowance missing");
        require(aToken.transferFrom(receiveAddress, payable(this), amount), "Transfer failed !");
        lendingPool.setUserUseReserveAsCollateral(0x87b1f4cf9BD63f7BBD3eE1aD04E8F52540349347, false);
        wETHGateway.withdrawETH(lendingPoolAddress, uint256(amount) , payable(receiveAddress));
        return true;
    }
    
    function withdrawProfits() public onlyOwner {
        require(profitAmount() > 0, "No profits to withdraw");
        uint256 profit = profitAmount();
        withdrawETH(profit, msg.sender);
    }
    
    function profitAmount() public view returns(uint256) {
        return uint256(aToken.balanceOf(address(this)) - contractLiabilities);
    }
    
    function getContractAaveInfo(address fetchAddress) public view returns(uint256, uint256, uint256, uint256,uint256, uint256, uint256){
        return(lendingPool.getUserAccountData(fetchAddress));
    }
    
    function changeAllowance(address spender, uint256 amount) public {
        aToken.approve(spender, amount);
    }
    
    function getAllowance(address owner, address spender) public view returns(uint256) {
        return(aToken.allowance(owner, spender));
    }
    receive() external payable{
       
    }
}