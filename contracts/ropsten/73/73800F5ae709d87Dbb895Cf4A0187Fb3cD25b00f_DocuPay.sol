/**
 *Submitted for verification at Etherscan.io on 2022-01-22
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
    uint256 votes;
    uint256 favourites;
  }

  struct Comment {
    address commenter;
    string commentMsg;
  }

  Document[] public documents;
  Comment[] public comments;

  // Users have a name, reputation, and a library of documents they have uploaded, purchased, and favourited
  mapping(address => string) public name;
  mapping(address => uint256) public reputation;
  mapping(address => uint256[]) public documentsUploaded;
  mapping(address => uint256[]) public documentsPurchased;
  mapping(address => uint256[]) public documentsFavourited;
  mapping(string => uint256[]) public commentsOnDocument;

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

  function getCommentCount(string memory document) public view returns(uint256) {
    return commentsOnDocument[document].length;
  }

  function getCommentOnDocument(string memory document, uint256 index) public view returns(uint256) {
    return commentsOnDocument[document][index];
  }

  function getComment(uint256 commentIndex) public view returns(Comment memory) {
    return comments[commentIndex];
  }

  function changeName(string memory newName) public {
    // Validate the user input
    require(bytes(newName).length > 0 && bytes(newName).length <= 35, "Name length must be above 0 and below 35 chars");

    // Update the user's name
    name[msg.sender] = newName;
  }

  function uploadDocument(string memory title, uint256 date, string memory description, uint256 fee, string memory file) public {
    // Validate the user input
    require(bytes(title).length > 0 && bytes(title).length <= 25, "Title length must be above 0 and above 25 chars");
    require(bytes(description).length > 0 && bytes(description).length <= 1000, "Description length must be above 0 and under 1000 chars");
    require(fee >= 0 wei, "Fee cannot be negative");

    // Add the document
    documents.push(Document(payable(msg.sender), title, date, description, fee, file, 0, 0));
    documentsUploaded[msg.sender].push(documents.length);
  }

  function purchaseDocument(uint256 docIndex) public payable {
    // Check if the document has not been purchased, and if the given amount is the same as the set fee
    require(msg.sender != getDocument(docIndex).uploader && !isDocumentPurchased(docIndex), "Please purchase this document first");
    require(msg.value == getDocument(docIndex).fee, "Invalid amount paid");

    // Pay the uploader
    payable(documents[docIndex].uploader).transfer(msg.value);

    // Add the document to the user's purchase library
    documentsPurchased[msg.sender].push(docIndex);
  }

  function isDocumentPurchased(uint256 docIndex) public view returns(bool) {
    // Check if the user has purchased the document previously
    for (uint256 i = 0; i < documentsPurchased[msg.sender].length; i++) {
      if (documentsPurchased[msg.sender][i] == docIndex)
        return true;
    }
    
    return false;
  }

  function canView(uint256 docIndex) public view returns(bool) {
    // If the user uploaded the document or they have purchased the document before, they can view it
    if (msg.sender == getDocument(docIndex).uploader || isDocumentPurchased(docIndex))
      return true;

    return false;
  }

  function upvoteDocument(uint256 docIndex) public {
    // Ensure that the voter is not the uploader
    require(msg.sender != getDocument(docIndex).uploader, "You cannot upvote your own document");

    // Increase the number of votes and the uploader's reputation
    documents[docIndex].votes += 1;
    reputation[documents[docIndex].uploader] += 10;
  }

  function downvoteDocument(uint256 docIndex) public {
    // Ensure that the voter is not the uploader
    require(msg.sender != getDocument(docIndex).uploader, "You cannot downvote your own document");

    // Decrease the number of votes
    documents[docIndex].votes -= 1;

    // Check if the user's reputation will be less than zero once their reputation has been decreased
    if ((reputation[documents[docIndex].uploader] -= 5) >= 0) {
      reputation[documents[docIndex].uploader] -= 5;
    } else {
      // Prevent the user's reputation from going below zero
      reputation[documents[docIndex].uploader] == 0;
    }
  }

  function favouriteDocument(uint256 docIndex) public {
    // Check if the document has already been favourited
    bool isDocumentFound = false;

    for (uint256 i = 0; i < documentsFavourited[msg.sender].length; i++) {
      if (documentsFavourited[msg.sender][i] == docIndex)
        isDocumentFound = true;
    }

    require(isDocumentFound == false, "You have already favourited this document");

    // Users can favourite a document to save and look at later, whether they have purchased it or not
    documentsFavourited[msg.sender].push(docIndex);
    documents[docIndex].favourites += 1;
  }

  function unfavouriteDocument(uint256 docIndex) public {
    // Check if the document has been favourited
    bool isDocumentFound = false;

    for (uint256 i = 0; i < documentsFavourited[msg.sender].length; i++) {
      if (documentsFavourited[msg.sender][i] == docIndex)
        isDocumentFound = true;
    }

    require(isDocumentFound == true, "You have not favourited this document");

    // Users can unfavourite a document, and it will then be removed from their library
    delete documentsFavourited[msg.sender][docIndex];
    documents[docIndex].favourites -= 1;
  }

  function sendComment(string memory document, string memory commentMsg) public {
    // Validate the user input
    require(bytes(commentMsg).length > 0 && bytes(commentMsg).length < 500, "Comment length must be above 0 and under 500 chars");

    // Add the comment to the mapping
    comments.push(Comment(msg.sender, commentMsg));
    return commentsOnDocument[document].push(comments.length);
  }
}