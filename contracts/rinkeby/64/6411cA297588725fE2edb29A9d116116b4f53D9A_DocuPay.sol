/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract DocuPay {
  struct Document {
    address payable uploader;
    string title;
    uint256 date;
    string description;
    uint256 fee;
    string file;
    uint256 upvotes;
    uint256 favourites;
  }

  Document[] public documents;

  // Users have a name, reputation, and a library of documents they have uploaded, purchased, and favourited
  mapping(address => string) public name;
  mapping(address => uint256) public reputation;
  mapping(address => uint256[]) public documentsUploaded;
  mapping(address => uint256[]) public documentsPurchased;
  mapping(address => uint256[]) public documentsFavourited;

  // Getters
  function getDocument(uint256 docIndex) public view returns(Document memory) {
    return documents[docIndex];
  }

  function getName(address user) public view returns(string memory) {
    return name[user];
  }

  function getReputation(address user) public view returns(uint256) {
    return reputation[user];
  }

  function getTotalDocumentsCount() public view returns(uint256) {
    return documents.length;
  }

  function getDocumentsUploadedCount(address user) public view returns(uint256) {
    return documentsUploaded[user].length;
  }

  function getDocumentUploaded(address user, uint256 docIndex) public view returns(uint256) {
    return documentsUploaded[user][docIndex];
  }

  function getDocumentsPurchasedCount(address user) public view returns(uint256) {
    return documentsPurchased[user].length;
  }

  function getDocumentPurchased(address user, uint256 docIndex) public view returns(uint256) {
    return documentsPurchased[user][docIndex];
  }

  function getDocumentsFavouritedCount(address user) public view returns(uint256) {
    return documentsFavourited[user].length;
  }

  function getDocumentFavourited(address user, uint256 docIndex) public view returns(uint256) {
    return documentsFavourited[user][docIndex];
  }

  function changeName(string memory newName) public {
    require(bytes(newName).length > 0 && bytes(newName).length <= 35, "Invalid name length");

    // Update the user's name
    name[msg.sender] = newName;
  }

  function uploadDocument(string memory title, uint256 date, string memory description, uint256 fee, string memory file) public {
    // Validate the user input
    require(bytes(title).length > 0 && bytes(title).length <= 25, "Invalid title length");
    require(bytes(description).length > 0 && bytes(description).length <= 1000, "Invalid description length");
    require(fee >= 0 wei, "Fee cannot be negative");

    // Add the document
    documents.push(Document(payable(msg.sender), title, date, description, fee, file, 0, 0));
    documentsUploaded[msg.sender].push(documents.length);
  }

  function purchaseDocument(uint256 docIndex) public payable {
    require(msg.sender != documents[docIndex].uploader && !isDocumentPurchased(docIndex), "Please purchase this document first");
    require(msg.value == documents[docIndex].fee, "Invalid amount paid");

    // Pay the uploader
    payable(documents[docIndex].uploader).transfer(msg.value);

    // Add the document to the user's purchase library
    documentsPurchased[msg.sender].push(docIndex);
  }

  function isDocumentPurchased(uint256 docIndex) public view returns(bool) {
    // Check if the user has purchased the document previously
    for (uint256 i = 0; i < documentsPurchased[msg.sender].length; i++) {
      if (documentsPurchased[msg.sender][i] == docIndex) return true;
    }
    
    return false;
  }

  function canView(uint256 docIndex) public view returns(bool) {
    // If the user uploaded the document or they have purchased the document before, they can view it
    if (msg.sender == documents[docIndex].uploader || isDocumentPurchased(docIndex)) return true;
    return false;
  }

  function upvoteDocument(uint256 docIndex) public {
    require(msg.sender != documents[docIndex].uploader, "You cannot upvote your own document");
    require(documentsPurchased[msg.sender][docIndex] == docIndex, "Please purchase this document first before upvoting");

    // Increase the number of upvotes and the uploader's reputation
    getDocument(docIndex).upvotes += 1;
    reputation[documents[docIndex].uploader] += 10;
  }

  function favouriteDocument(uint256 docIndex) public {
    // Users can favourite a document to save and look at later, whether they have purchased it or not
    documentsFavourited[msg.sender].push(docIndex);
    getDocument(docIndex).favourites += 1;
  }
}