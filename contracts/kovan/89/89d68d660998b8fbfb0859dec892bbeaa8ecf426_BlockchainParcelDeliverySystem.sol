/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

pragma solidity ^0.5.11;
 
 contract BlockchainParcelDeliverySystem {
     
     function receiveEth() external payable {
         
     }
     
     
     function DefineContract (string memory price, string memory product) public pure returns (string memory, string memory, string memory, string memory, string memory, string memory, string memory){
         string memory part1 = 'The contract is undertaking now on the following terms:';
         string memory part2 = '1. The customer is to pay (amount in ETH):';
         string memory product_price = price;
         string memory part3 = '2. For product:';
         string memory product_type = product;
         string memory part4 = 'upon the customer collecting their parcel.';
         string memory part5 = 'The Contract will terminate upon incorrect parcel delivery.';
         return (part1, part2, product_price, part3, product_type, part4, part5);
        
     }
     
   
     function StoreBarcode (string memory created_barcode) public pure returns (string memory, string memory){
         string memory barcode = created_barcode;
         string memory mesg = 'The barcode number is:';
         return (mesg, barcode);
     }
     
     function SellersPassword (string memory created_sellers_password) public pure returns (string memory, string memory){
         string memory sellers_password = created_sellers_password;
         string memory mesg = "The seller's password is:";
         return (mesg, sellers_password);
     }
     
     function IncorrectSellersPasswordEntered () public pure returns (string memory){
         string memory incorrect_sellers_password_entered = 'Seller has entered the wrong password.';
         return incorrect_sellers_password_entered;
     }
     
     function CorrectSellersPasswordEntered () public pure returns (string memory){
         string memory correct_sellers_password_entered = 'Seller has entered the correct password, the box will now open and the package can be placed inside. Please scan the package barcode.';
         return correct_sellers_password_entered;
     }
     
     function ScannedBarcode (string memory scanned_barcode) public pure returns (string memory, string memory){
         string memory barcode_scanned = scanned_barcode;
         string memory mesg = 'The scanned barcode is:';
         return (mesg, barcode_scanned);
     }
     
     function ScannedBarcodeIsCorrect () public pure returns (string memory){
         string memory barcode_matched = 'Barcode is correct and customer can collect their product using the unique password sent to them.';
         return barcode_matched;
     }
     
     function CustomersPassword (string memory created_customers_password) public pure returns (string memory, string memory){
         string memory customers_password = created_customers_password;
         string memory mesg = "The customer's password is:";
         return (mesg, customers_password);
     }
     
     function IncorrectCustomersPasswordEntered () public pure returns (string memory){
         string memory incorrect_customers_password_entered = 'Customer has entered the wrong password.';
         return incorrect_customers_password_entered;
     }
     
     function CorrectCustomersPasswordEntered () public pure returns (string memory){
         string memory correct_customers_password_entered = 'Customer has entered the correct password, the box will now open and the package can be retrieved by the customer. The transaction will now take place between customer and seller.';
         return correct_customers_password_entered;
     } 
     
     function ScannedBarcodeIsIncorrect () public pure returns (string memory){
         string memory barcode_unmatched = 'Barcode is incorrect! A unique password will be created for the seller to collect the incorrect parcel.';
         return barcode_unmatched;
     }
     
     function ContractTerminated () public pure returns (string memory){
         string memory barcode_unmatched = 'The contract has terminated due to the incorrect password.';
         return barcode_unmatched;
     }
     
     function ContractCompleted () public pure returns (string memory){
         string memory complete = 'The contract has successfully been fulfilled.';
         return complete;
     }
 }