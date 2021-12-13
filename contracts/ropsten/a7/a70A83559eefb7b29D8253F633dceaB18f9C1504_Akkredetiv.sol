// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity ^0.8.0;


// Defines a contract named `HelloWorld`.
// A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract Akkredetiv {

   // Declares a state variable `message` of type `string`.
   // State variables are variables whose values are permanently stored in contract storage. The keyword `public` makes variables accessible from outside a contract and creates a function that other contracts or clients can call to access the value.
   address public importeur;
   address public exporteur;
   address public importeurBank;
   address public exporteurBank;

   uint256 public anzahlungAmount;
   uint256 public contractAmount;
   string public deliveryTerms;
   string public startHarbor;
   string public endHarbor;
   uint256 public status;

   // Similar to many class-based object-oriented languages, a constructor is a special function that is only executed upon contract creation.
   // Constructors are used to initialize the contract's data. Learn more:https://solidity.readthedocs.io/en/v0.5.10/contracts.html#constructors
   constructor(address mimporteur,  address  mexporteur, address  mimporteurBank, address mexporteurBank, uint256 mcontractAmount, uint256 manzahlung,string memory mdeliveryTerms, string memory mstartHarbor,string memory mendHarbor) {
      // Accepts a string argument `initMessage` and sets the value into the contract's `message` storage variable).
      importeur = mimporteur;
      exporteur = mexporteur;
      importeurBank = mimporteurBank;
      exporteurBank = mexporteurBank;
      contractAmount = mcontractAmount;
      anzahlungAmount = manzahlung;
      deliveryTerms = mdeliveryTerms;
      startHarbor = mstartHarbor;
      endHarbor = mendHarbor;

      status = 1;
   } 

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
      if(msg.sender != importeur){
         revert();
      }
      checkAnzahlung();
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
      if(msg.sender != importeur){
         revert();
      }
      checkAnzahlung();
    }

   function getBalance() public view returns (uint) {
      return address(this).balance * 1000000000;
   }

   function checkAnzahlung() public {
      if (getBalance() >= anzahlungAmount){
         status = 2;
      }
   }

   function checkAkkredetivOpen() public {
      if(msg.sender != importeurBank){
         revert();
      }
      else{
         status = 3;
      }
   }

   function checkHotscanOpen() public {
      if(msg.sender != importeurBank){
         revert();
      }
      else{
         status = 4;
      }
   }

   function checkHotscanExporteur() public {
      if(msg.sender != exporteurBank){
         revert();
      }
      else{
         status = 5;
      }
   }

   function productionDone () public {
      if(msg.sender != exporteur){
         revert();
      }
      else{
         status = 6;
      }
   }

   function bookedStorage () public {
      if(msg.sender != importeur){
         revert();
      }
      else{
         status = 7;
      }
   }
/*
   function sendViaTransfer(address payable _to) public payable {
      // This function is no longer recommended for sending Ether.
      _to.transfer(msg.value);
   }

   function sendViaSend(address payable _to) public payable {
      // Send returns a boolean value indicating success or failure.
      // This function is not recommended for sending Ether.
      bool sent = _to.send(msg.value);
      require(sent, "Failed to send Ether");
   }

   function sendViaCall(address payable _to) public payable {
      // Call returns a boolean value indicating success or failure.
      // This is the current recommended method to use.
      (bool sent, bytes memory data) = _to.call{value: msg.value}("");
      require(sent, "Failed to send Ether");
   }*/
}