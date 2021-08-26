// SPDX-License-Identifier: No License
pragma solidity >=0.8.6;
import './Authorization.sol';
import './Address.sol';
import './IMerchantOrder.sol';
import './IMerchantPayment.sol';
import './IBank.sol';
import './IRemit.sol';
contract Gateway is Authorization{
    using Address for address;
    
    uint public totalConfirmedOrder = 0;
    uint public totalConfirmPayment = 0;
    uint public totalBankTransfer = 0;
    uint public totalRemitanceTransfer = 0;
    
    event OrderConfirmed(address merchant, string indexed stationId, address tokenAddress, uint256 amountDue, address customer, string indexed orderId, string promoCode);
    event PaymentConfirmed(address merchant, string indexed stationId, address tokenAddress, uint256 amountDue, address customer, string indexed orderId, string promoCode);
    event BankTransfer(address indexed bank, address indexed currency, uint256 amountDue, string transactionMeta);
    event TransferReceived(address sender, address indexed receiver, uint256 amount);
    event RemitanceTransfer(address indexed remitanceProvider, address indexed currency, uint256 amountDue, string destinationTag, string transactionMeta);
    /**
     * 
     */
    function confirmOrder(address merchant, string calldata stationId, address tokenAddress, uint256 amountDue, address customer, string calldata orderId, string calldata promoCode) public onlyAuthorizedContract{
        totalConfirmedOrder += 1;
        if(merchant.isContract()){
            IMerchantOrder(merchant).orderConfirmed(stationId, tokenAddress, amountDue, customer, orderId, promoCode);
        }
        emit OrderConfirmed(merchant, stationId, tokenAddress, amountDue, customer, orderId, promoCode);
    }
    
    function confirmPayment(address merchant, string calldata stationId, address tokenAddress, uint256 amountDue, uint256 amountReceived, address customer, string calldata orderId, string calldata promoCode) public onlyAuthorizedContract{
        totalConfirmPayment += 1;
        if(merchant.isContract()){
            IMerchantPayment(merchant).paymentConfirmed(stationId, tokenAddress, amountDue, amountReceived, customer, orderId, promoCode);
        }
        emit PaymentConfirmed(merchant, stationId, tokenAddress, amountDue, customer, orderId, promoCode);
    }
    
    function bankTransfer(address bank,address from, address to,  address tokenAddress, uint256 amountDue, string calldata transactionMeta) public onlyAuthorizedContract{
        totalBankTransfer += 1;
        if(bank.isContract()){
            IBank(bank).execute(from, to, tokenAddress, amountDue, transactionMeta);
        }
        emit BankTransfer(bank, tokenAddress, amountDue, transactionMeta);
    }
    
    function remitanceTransfer(address recipient, address tokenAddress, uint256 amountDue, string calldata destinationTag, string calldata transactionMeta) public onlyAuthorizedContract{
        totalRemitanceTransfer += 1;
        if(recipient.isContract()){
            IRemit(recipient).execute(tokenAddress, amountDue, destinationTag, transactionMeta);
        }
        emit RemitanceTransfer(recipient, tokenAddress, amountDue, destinationTag, transactionMeta);
    }
    
    function notifyTransfer(address sender, address receiver, uint256 amount) external onlyAuthorizedContract{
        emit TransferReceived(sender, receiver, amount);
    }
}