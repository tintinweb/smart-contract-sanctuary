// SPDX-License-Identifier: No License
pragma solidity >=0.8.6;
import './Authorization.sol';
import './Address.sol';
import './IMerchantOrder.sol';
import './IMerchantPayment.sol';
import './IBank.sol';
import './IRemit.sol';
import './IGateway.sol';
import './ITransferHandler.sol';
contract Gateway is Authorization, IGateway{
    using Address for address;
    
    uint public totalConfirmedOrder = 0;
    uint public totalConfirmPayment = 0;
    uint public totalBankTransfer = 0;
    uint public totalRemitanceTransfer = 0;
    /**
     * Merchant address can be a DApp implementing IMerchantOrder to automatically execute additional for order confirmation.
     * 
     */
    function confirmOrder(address merchant, string calldata stationId, address tokenAddress, uint256 amountDue, address customer, string calldata orderId, string calldata promoCode) public override onlyAuthorizedContract{
        totalConfirmedOrder += 1;
        if(merchant.isContract()){
            IMerchantOrder(merchant).orderConfirmed(stationId, tokenAddress, amountDue, customer, orderId, promoCode);
        }
        emit OrderConfirmed(merchant, stationId, tokenAddress, amountDue, customer, orderId, promoCode);
    }
    /**
     * Receiving merchant can be a DApp impleing IMerchantPayment to automatically execute fund automation.
     * Merchant can deploy their own custom DApp or buy from DApp store.
     */
    function confirmPayment(address merchant, string calldata stationId, address tokenAddress, uint256 amountDue, address customer, string calldata orderId, string calldata promoCode) public override onlyAuthorizedContract{
        totalConfirmPayment += 1;
        if(merchant.isContract()){
            IMerchantPayment(merchant).paymentConfirmed(stationId, tokenAddress, amountDue, customer, orderId, promoCode);
        }
        emit PaymentConfirmed(merchant, stationId, tokenAddress, amountDue, customer, orderId, promoCode);
    }
    
    /**
     * Receiving bankAddress can be a DApp impleing IBank to automatically execute fund automation.
     * Banks can deploy their own custom DApp or buy from DApp store.
     */
    function bankTransfer(address bankAddress, address senderAccount, address receivingAccount,  address tokenAddress, uint256 amountDue, string calldata transactionMeta) public override onlyAuthorizedContract{
        totalBankTransfer += 1;
        if(bankAddress.isContract()){
            IBank(bankAddress).execute(senderAccount, receivingAccount, tokenAddress, amountDue, transactionMeta);
        }
        emit BankTransfer(bankAddress, senderAccount, receivingAccount, tokenAddress, amountDue, transactionMeta);
    }
    
    /**
     * Receiving address can be a DApp impleing IRemit to automatically execute fund automation.
     * Remittance institutions can deploy their own custom DApp or buy from DApp store.
     */
    function remittanceTransfer(address receivingAccount, address tokenAddress, uint256 amountDue, string calldata destinationTag, string calldata transactionMeta) public override onlyAuthorizedContract{
        totalRemitanceTransfer += 1;
        if(receivingAccount.isContract()){
            IRemit(receivingAccount).execute(tokenAddress, amountDue, destinationTag, transactionMeta);
        }
        emit RemittanceTransfer(receivingAccount, tokenAddress, amountDue, destinationTag, transactionMeta);
    }
    
    /**
     * Receiver address can be a DApp impleing ITransferHandler to automatically execute fund automation.
     * User can deploy their own custom DApp or buy from DApp store.
     */
    function notifyTransfer(address sender, address receiver, address tokenAddress, uint256 amount, string calldata transferNote) external override onlyAuthorizedContract{
        if(receiver.isContract()){
            ITransferHandler(receiver).execute(sender, tokenAddress, amount, transferNote);
        }
        emit TransferReceived(sender, receiver, tokenAddress, amount, transferNote);
    }
    function getBlockTimeStamp()external override view returns(uint timestamp){
        return block.timestamp;
    }
}