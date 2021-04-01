/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

contract LiquiidaTransaction{

    address owner;

    struct TxRecord {
        bytes32 creditId;
        bytes32 creditSubCode;
        bytes32 creditType;
        uint creditYear;
        uint amount;
        uint quote;
        uint sellingPrice;
        bytes32 buyerFiscalCode;
        bytes32 buyerIBAN;
        bytes32 sellerFiscalCode;
        bytes32 sellerIBAN;
        uint elapsedAt;
        bytes3 step; // (000,020,040)
        uint date;
    }

    struct TxRecordExtended {
        uint indexRef;
        bytes32 reason;
        bytes32 mobileCode;
    }

    mapping (bytes32 => TxRecord[]) public transactions;
    mapping (bytes32 => TxRecordExtended[]) public transactionsExtended;
    mapping (bytes32 => bytes32[]) public creditsIndex;

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    constructor () {
        owner = msg.sender;
    }

    function initTransaction(
        bytes32 _transactionId,
        bytes32 _creditId,
        bytes32 _creditSubCode,
        bytes32 _creditType,
        uint _creditYear,
        uint _amount,
        uint _quote,
        uint _sellingPrice,
        bytes32 _buyerFiscalCode,
        bytes32 _buyerIBAN,
        bytes32 _sellerFiscalCode,
        bytes32 _sellerIBAN
    ) public onlyOwner returns(bool) {
        require (transactions[_transactionId].length == 0, "transactionId already exist");
        TxRecord memory t;
        t.creditId = _creditId;
        t.creditSubCode = _creditSubCode;
        t.creditType = _creditType;
        t.creditYear = _creditYear;
        t.amount = _amount;
        t.quote = _quote;
        t.sellingPrice = _sellingPrice;
        t.buyerFiscalCode = _buyerFiscalCode;
        t.buyerIBAN = _buyerIBAN;
        t.sellerFiscalCode = _sellerFiscalCode;
        t.sellerIBAN = _sellerIBAN;
        t.step = '000';
        t.date = block.timestamp;
        transactions[_transactionId].push(t);
        creditsIndex[_creditId].push(_transactionId);

        emit txEvent(_transactionId, 0, block.timestamp, "initTransaction");
        return true;
    }

    function confirmBuyerPayment(
        bytes32 _transactionId,
        bytes32 _creditId,
        bytes32 _creditSubCode,
        uint _bankTxAmount,
        bytes32 _bankTxReason,
        bytes32 _bankBuyerTxIBAN,
        bytes32 _bankSellerTxIBAN,
        bytes32 _bankBuyerTxFiscalCode,
        bytes32 _bankSellerTxFiscalCode,
        uint _elapsedAt
    ) public onlyOwner returns (bytes3) {
        require (transactions[_transactionId].length > 0, "transaction not found");
        uint lastId = transactions[_transactionId].length-1;
        require (transactions[_transactionId][lastId].step == '000', "transaction status do not match");
        require (transactions[_transactionId][lastId].creditId == _creditId, "transaction creditId do not match");
        require (transactions[_transactionId][lastId].creditSubCode == _creditSubCode, "transaction creditSubCode do not match");
        require (transactions[_transactionId][lastId].sellingPrice <= _bankTxAmount, "transaction amount is not enough");
        require (transactions[_transactionId][lastId].buyerIBAN == _bankBuyerTxIBAN, "transaction buyerIBAN do not match");
        require (transactions[_transactionId][lastId].sellerIBAN == _bankSellerTxIBAN, "transaction sellerIBAN do not match");
        require (transactions[_transactionId][lastId].buyerFiscalCode == _bankBuyerTxFiscalCode, "transaction buyerFiscalCode do not match");
        require (transactions[_transactionId][lastId].sellerFiscalCode == _bankSellerTxFiscalCode, "transaction sellerFiscalCode do not match");
        TxRecord memory newTx = transactions[_transactionId][lastId];
        newTx.sellingPrice = _bankTxAmount;
        newTx.date = block.timestamp;
        newTx.step = '020';
        newTx.elapsedAt = _elapsedAt;
        transactions[_transactionId].push(newTx);
        TxRecordExtended memory newTxExt;
        newTxExt.indexRef = lastId;
        newTxExt.reason = _bankTxReason;
        transactionsExtended[_transactionId].push(newTxExt);
        return newTx.step;
    }

    function confirmSellerTransfer(
        bytes32 _transactionId,
        bytes32 _buyerFiscalCode,
        bytes32 _sellerFiscalCode,
        bytes32 _creditId,
        bytes32 _creditSubCode,
        bytes32 _mobileCode,
        uint _elapsedAt
    ) public onlyOwner returns (bool) {
        require (transactions[_transactionId].length > 0, "transaction not found");
        uint lastId = transactions[_transactionId].length-1;
        require (transactions[_transactionId][lastId].step == '020', "transaction status do not match");
        require (transactions[_transactionId][lastId].creditId == _creditId, "transaction creditId do not match");
        require (transactions[_transactionId][lastId].creditSubCode == _creditSubCode, "transaction creditSubCode do not match");
        require (transactions[_transactionId][lastId].buyerFiscalCode == _buyerFiscalCode, "transaction buyerFiscalCode do not match");
        require (transactions[_transactionId][lastId].sellerFiscalCode == _sellerFiscalCode, "transaction sellerFiscalCode do not match");
        require (transactions[_transactionId][lastId].elapsedAt >= block.timestamp, "transaction expired");
        
        TxRecord memory newTx = transactions[_transactionId][lastId];
        newTx.date = block.timestamp;
        newTx.elapsedAt = _elapsedAt;
        newTx.step = '030';
        transactions[_transactionId].push(newTx);

        TxRecordExtended memory newTxExt;
        newTxExt.indexRef = lastId;
        newTxExt.mobileCode = _mobileCode;
        transactionsExtended[_transactionId].push(newTxExt);
        return true;
    }

    function confirmBuyerTransfer(
        bytes32 _transactionId,
        bytes32 _buyerFiscalCode,
        bytes32 _sellerFiscalCode,
        bytes32 _creditId,
        bytes32 _creditSubCode,
        bytes32 mobileCode,
        uint _elapsedAt,
        uint txExtRef
    ) public onlyOwner returns (bool) {
        require (transactions[_transactionId].length > 0, "transaction not found");
        uint lastId = transactions[_transactionId].length-1;
        require (transactions[_transactionId][lastId].step == '030', "transaction status do not match");
        require (transactions[_transactionId][lastId].creditId == _creditId, "transaction creditId do not match");
        require (transactions[_transactionId][lastId].creditSubCode == _creditSubCode, "transaction creditSubCode do not match");
        require (transactions[_transactionId][lastId].buyerFiscalCode == _buyerFiscalCode, "transaction buyerFiscalCode do not match");
        require (transactions[_transactionId][lastId].sellerFiscalCode == _sellerFiscalCode, "transaction sellerFiscalCode do not match");
        require (transactions[_transactionId][lastId].elapsedAt >= block.timestamp, "transaction expired");
        require (transactionsExtended[_transactionId][txExtRef].mobileCode == mobileCode, "transaction mobileCode do not match");
        
        TxRecord memory newTx = transactions[_transactionId][lastId];
        newTx.date = block.timestamp;
        newTx.elapsedAt = _elapsedAt;
        newTx.step = '040';
        transactions[_transactionId].push(newTx);

        return true;
    }

    function endTransaction() public view onlyOwner returns (bool) {
        return true;
    }


    function getTxLatestStep (bytes32 _transactionId) public view returns(bytes3) {
        return transactions[_transactionId][transactions[_transactionId].length - 1].step;
    }

    function getTxRecordsCount (bytes32 _transactionId) public view returns(uint count) {
        return transactions[_transactionId].length;
    }

    function getTxRecord (bytes32 _transactionId, uint index) public view returns(
        bytes32,
        bytes32,
        bytes32,
        uint,
        bytes3,
        uint
    ) {
        TxRecord memory t = transactions[_transactionId][index];
        return (
            t.creditId,
            t.creditSubCode,
            t.creditType,
            t.creditYear,
            t.step,
            t.date
        );
    }

    function getTxExtRecordsCount (bytes32 _transactionId) public view returns(uint count) {
        return transactionsExtended[_transactionId].length;
    }

    function getTxExtRecord (bytes32 _transactionId, uint index) public view returns(
        uint indexRef,
        bytes32 reason,
        bytes32 mobileCode
    ) {
        TxRecordExtended memory t = transactionsExtended[_transactionId][index];

        return (
            t.indexRef,
            t.reason,
            t.mobileCode
        );
    }

    function getTxRecordDetails (bytes32 _transactionId, uint index) public view returns(
        uint,
        uint,
        uint,
        bytes32,
        bytes32,
        bytes32,
        bytes32
    ) {
        TxRecord memory t = transactions[_transactionId][index];
        return (
            t.amount,
            t.quote,
            t.sellingPrice,
            t.buyerFiscalCode,
            t.buyerIBAN,
            t.sellerFiscalCode,
            t.sellerIBAN
        );
    }

    // TODO
    function getTransactionCountByCreditId(bytes32 _creditId) public view returns(
       uint
    ) {
        return creditsIndex[_creditId].length;
    }    
    
    function getTransactionByCreditId(bytes32 _creditId, uint index) public view returns(
       bytes32
    ) {
        return creditsIndex[_creditId][index];
    }

    // TODO
    // getTransactionByStep
    
    event txEvent(bytes32 _transactionId, uint txLength, uint cdate, bytes32 desc);
}