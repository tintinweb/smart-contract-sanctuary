// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;




interface CEth {
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}


contract Paytr {
    event MyLog(string, uint256);
    event MyOwnLog(string, uint);

    address sender;
    uint transactionDate;
    uint public transactionID;
    uint intrest;
    
    struct Invoice {
        uint amount;
        address sender;
        address supplier;
        uint transactionDate;
        uint dueDate;
    }
    
      struct dueInvoice {
        uint amount;
        address sender;
        address supplier;
        uint transactionDate;
        uint dueDate;
    }
    
   mapping(uint => Invoice) public userInvoices;
   Invoice[] public invoices;
   dueInvoice[] public dueInvoices;

   constructor() {
        transactionID = 0;
    }
    

    function supplyEthToCompound(address payable _cEtherContract, uint amount, address supplier, uint dueDate)
        public
        payable
        returns (bool)
    {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up by 1e18): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        // uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        uint256 supplyBlockNumber = block.number;
        emit MyLog("Block number while supplying is: ", supplyBlockNumber);

        transactionDate = block.timestamp;
        sender = msg.sender;
        dueDate = block.timestamp + (dueDate * 1 seconds);
        userInvoices[transactionID] = Invoice(amount, sender, supplier, transactionDate, dueDate);
        transactionID ++;
        Invoice memory invoiceData = Invoice(amount, sender, supplier, transactionDate, dueDate);
        invoices.push(invoiceData);

        cToken.mint{value:msg.value,gas:250000}();
        return true;

        

                
    }

        function createAndShowDueList() public returns(dueInvoice[] memory) {
        for (uint i = 0; i < invoices.length; i++) {
            
             if (block.timestamp >= invoices[i].dueDate) {
                uint amount = invoices[i].amount;
                address sender = invoices[i].sender;
                address supplier = invoices[i].supplier;
                uint transactionDate = invoices[i].transactionDate;
                uint dueDate = invoices[i].dueDate;
                
                dueInvoice memory dueList = dueInvoice(amount, sender, supplier, transactionDate, dueDate);
                dueInvoices.push(dueList);
                
            }
            
        }
        return dueInvoices;
        }

    function createDueList() public payable {
        for (uint i = 0; i < invoices.length; i++) {
            
             if (block.timestamp >= invoices[i].dueDate) {
                uint amount = invoices[i].amount;
                address sender = invoices[i].sender;
                address supplier = invoices[i].supplier;
                uint transactionDate = invoices[i].transactionDate;
                uint dueDate = invoices[i].dueDate;
                
                dueInvoice memory dueList = dueInvoice(amount, sender, supplier, transactionDate, dueDate);
                dueInvoices.push(dueList);
                
            }
        
        }

        uint myfee = 0.000000005 ether;
        uint intrest = 0.00001 ether;
        for (uint i = 0; i < dueInvoices.length; i++) {
            address payable supplierToPay = payable(dueInvoices[i].supplier);
            address payable senderToPay = payable(dueInvoices[i].sender);
            supplierToPay.call{value: dueInvoices[i].amount};
            senderToPay.call{value: (intrest - myfee)};
            
            
        }
        uint256 amountToBePaid = dueInvoices[0].amount;
        emit MyLog("Amount that will be paid for first invoice is: ", amountToBePaid);
        
    }

    function balanceOf() external pure returns (uint256 balance) {
        return balance;
    }

    function redeemCEth(
        // address _suppliersAddress,
        uint256 amount,
        bool redeemType,
        address _cEtherContract
    ) public returns (bool) {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        // `amount` is scaled up by 1e18 to avoid decimals

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
           
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        uint256 redeemedEth;

        if (redeemType == true) {
            uint exchangeRateMantissa = cToken.exchangeRateCurrent();
            redeemedEth =(amount * exchangeRateMantissa);
        }

        // Error codes are listed here:
        // https://compound.finance/docs/ctokens#ctoken-error-codes
        emit MyOwnLog("ETH redeemed :", redeemedEth);
        

        return true;
    }

    function payEveryone() public payable {
        uint myfee = 0.000000005 ether;
        uint intrest = 0.00001 ether;
        for (uint i = 0; i < dueInvoices.length; i++) {
            address payable supplierToPay = payable(dueInvoices[i].supplier);
            address payable senderToPay = payable(dueInvoices[i].sender);
            supplierToPay.call{value: dueInvoices[i].amount};
            senderToPay.call{value: (intrest - myfee)};
            
            
        }
    }

    // This is needed to receive ETH when calling `redeemCEth`
    receive() external payable {}

    

}

