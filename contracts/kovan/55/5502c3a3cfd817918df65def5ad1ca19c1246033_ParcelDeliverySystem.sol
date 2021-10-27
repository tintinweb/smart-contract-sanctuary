/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

pragma solidity ^0.5.11;
 
 contract ParcelDeliverySystem {
     
     function receiveEth() external payable {
         
     }
     
     
     function SaleMade () public pure returns (string memory){
         string memory sale = 'A product sale has been made, a unqiue barcode will be created for the product packaging.';
         return sale;
     }
 
     function StoreBarcode (string memory created_barcode) public pure returns (string memory){
         string memory barcode = created_barcode;
         return barcode;
     }
     
     function SellersPassword (string memory created_sellers_password) public pure returns (string memory){
         string memory sellers_password = created_sellers_password;
         return sellers_password;
     }
     
     function IncorrectSellersPasswordEntered () public pure returns (string memory){
         string memory incorrect_sellers_password_entered = 'Seller has entered the wrong password.';
         return incorrect_sellers_password_entered;
     }
     
     function CorrectSellersPasswordEntered () public pure returns (string memory){
         string memory correct_sellers_password_entered = 'Seller has entered the correct password, the box will now open and the package can be placed inside, and the products barcode will be scanned.';
         return correct_sellers_password_entered;
     }
     
     function ScannedBarcode (string memory scanned_barcode) public pure returns (string memory){
         string memory barcode_scanned = scanned_barcode;
         return barcode_scanned;
     }
     
     function ScannedBarcodeIsCorrect () public pure returns (string memory){
         string memory barcode_matched = 'Barcode is correct and customer can collect their product using the unique password sent to them.';
         return barcode_matched;
     }
     
     function CustomersPassword (string memory created_customers_password) public pure returns (string memory){
         string memory customers_password = created_customers_password;
         return customers_password;
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
         string memory barcode_unmatched = 'Barcode is incorrect and unique password is sent to the seller to collect. The customer will be notified of the incorrect item delivered.';
         return barcode_unmatched;
     }
     
     function TransactionCompleted () public pure returns (string memory){
         string memory complete = 'Delivery process is now complete.';
         return complete;
     }
 }