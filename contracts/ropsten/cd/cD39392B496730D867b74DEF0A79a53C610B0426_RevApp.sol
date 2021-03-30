/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: MIT
//pragma experimental ABIEncoderV2;
pragma solidity ^0.7.0;

/**
 * @title RevApp
 * @dev Stores hashes to IPFS content and implements basic logic
 */
contract RevApp{

  //Review id counter
  uint public reviewId = 1;
  //Holds algorithm hash
  string algorithm;
  //Holds owner address
  address owner;

  constructor() {
     // Init owner of RevApp contract
       owner = msg.sender;
   }

  //To accept payments
  fallback() external payable {}

  //For execution owner address is needed
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  //Execution returns gas if given constrains are false
  modifier refundGasCost()
  {
    //Actual gas
    uint remainingGasStart = gasleft();
    _;
    //Check if user has right to recompensation (one free insert in 24 hours)
    if (FreeInserts[msg.sender] == 0 || FreeInserts[msg.sender] < block.timestamp) {
      //Reinitialize time counter
      FreeInserts[msg.sender] = block.timestamp + 1 days;
      //Actual gas after execution
      uint remainingGasEnd = gasleft();
      //Gas difference
      uint usedGas = remainingGasStart - remainingGasEnd;
      // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
      usedGas += 21000 + 9700;
      // Possibly need to check max gasprice and usedGas here to limit possibility for abuse.
      uint256 gasCost = usedGas * tx.gasprice;
      // Refund gas cost
      if (address(this).balance > gasCost) {
        address payable _to = msg.sender;
        _to.transfer(gasCost);
      }
    }
  }

  struct Review {
    string content;
    string analysis_result;
    string author;
  }

  struct Author {
    uint[] reviewIds;
  }

  struct Product {
    string fileId;
    uint[] reviewIds;
    mapping(address => uint) payed;
  }

  // maps id to Review
  mapping(uint256 => Review)  Reviews;
  // maps string (address, ip address) to Author
  mapping(string  => Author)  Authors;
  // maps string (EAN) to Product
  mapping(string  => Product) Products;
  // maps address to time of next free insert possible
  mapping(address => uint) FreeInserts;
  //Emmited on insert and update of review
  event InsertedReview(uint _ReviewId, string _Algorithm, uint[] _ProductReviews, uint[] _AuthorReviews, string _Product);

  // inserts
  function insertReview( string memory  _Content, string memory _Product) public payable refundGasCost{
    if (checkEAN(_Product)) {
      uint id = _getReviewId();
      Reviews[id].content = _Content;
      Reviews[id].author = toString(msg.sender);
      Authors[toString(msg.sender)].reviewIds.push(id);
      Products[_Product].reviewIds.push(id);
      emit InsertedReview(id, algorithm, getReviewIdsForProduct(_Product), getReviewIdsForAuthor(toString(msg.sender)), _Product);
    }
  }

  function insertReview( string memory  _Content, string memory _Product, string memory _User) public payable refundGasCost {
    if (checkEAN(_Product)) {
      uint id = _getReviewId();
      Reviews[id].content = _Content;
      Reviews[id].author = toString(msg.sender);
      Authors[_User].reviewIds.push(id);
      Products[_Product].reviewIds.push(id);
      emit InsertedReview(id, algorithm, getReviewIdsForProduct(_Product), getReviewIdsForAuthor(toString(msg.sender)), _Product);
    }
  }

  // Only owner
  function _insertAlgorithm( string memory _Algorithm) public onlyOwner {
    algorithm = _Algorithm;
  }

  function _sendRefund(address payable _to, uint256 _ammount) public payable onlyOwner{
    // Call returns a boolean value indicating success or failure.
    // This is the current recommended method to use.
    _to.transfer(_ammount);
  }

  // updates
  function updateReviewContent(uint _Id, string memory _Content, string memory _Product, string memory _User) public {
    if (keccak256(abi.encodePacked(Reviews[_Id].author)) == keccak256(abi.encodePacked(toString(msg.sender)))) {
      Reviews[_Id].content = _Content;
      emit InsertedReview(_Id, algorithm, getReviewIdsForProduct(_Product),
        getReviewIdsForAuthor(toString(msg.sender)), _Product);
    }
  }

  function updateReviewContent(uint _Id, string memory _Content, string memory _Product) public {
    if (keccak256(abi.encodePacked(Reviews[_Id].author)) == keccak256(abi.encodePacked(toString(msg.sender)))) {
      Reviews[_Id].content = _Content;
      emit InsertedReview(_Id, algorithm, getReviewIdsForProduct(_Product),
        getReviewIdsForAuthor(toString(msg.sender)), _Product);
    }
  }

  function updateReviewResult( uint _ReviewId, string memory _Result) public onlyOwner{
    Reviews[_ReviewId].analysis_result = _Result;
  }

  function updateProductFile( string memory _Product, string memory _FileHash) public {
    Products[_Product].fileId = _FileHash;
  }

  // getters
  function _getReviewId() private returns (uint) {
    return reviewId++;
  }

  function getProductById(string memory _Product) public returns (string memory) {
    if (checkEAN(_Product)) {
      return Products[_Product].fileId;
    }
    //Return -1 as error code, invalid product
    return "-1";
  }

  function getReviewIdsForProduct(string memory _Product) view public returns (uint[] memory) {
    //Check if EAN given (only 13 number accepting for now)
    if (checkEAN(_Product) && checkPayment(_Product, msg.sender)) {
          return Products[_Product].reviewIds;
      }
    //Return 0 as error code, invalid product
    uint[] memory res = new uint[](1);
    res[0] = 0;
    return res;
  }

  function getReviewCountForProduct(string memory _Product) view public returns (int) {
    //Check if EAN given (only 13 number accepting for now)
    if (checkEAN(_Product)) {
      return int(Products[_Product].reviewIds.length);
    }
    //Return -1 as error code, invalid product
    return -1;
  }

  function getReviewIdsForProductByPage(string memory _Product, uint _Page, uint _PageSize) view public returns (uint[] memory) {
    if (!checkEAN(_Product) || !checkPayment(_Product, msg.sender)){
      //Return 0 as error code, invalid product
      uint[] memory res = new uint[](1);
      res[0] = 0;
      return res;
    }
    if (Products[_Product].reviewIds.length < _PageSize && _Page == 0) {
      return Products[_Product].reviewIds;
    }
    uint start = _Page * _PageSize;
    if (start >= Products[_Product].reviewIds.length) {
      uint [] memory out;
      return out;
    }
    uint end = start + _PageSize;
    if (end >= Products[_Product].reviewIds.length) {
      end = Products[_Product].reviewIds.length;
    }
    uint[] memory out = new uint[](end - start);
    for(uint i=0;i<end - start;i++){
      out[i] = Products[_Product].reviewIds[i + start];
    }
    return out;
  }

  function getReviewIdsForAuthor(string memory _Author) view public returns (uint[] memory) {
    return Authors[_Author].reviewIds;
  }

  function getReviewById(uint  _ReviewId) view public returns (string memory, string memory) {
    return (Reviews[_ReviewId].content, Reviews[_ReviewId].analysis_result);
  }

  function getAlgorithm() view public returns (string memory) {
    return algorithm;
  }

  function getFreeInsertForAddress() view public returns (bool) {
    if (FreeInserts[msg.sender] == 0 || FreeInserts[msg.sender] < block.timestamp){
      return true;
    }
    return false;
  }

  function payForReviews(string memory _Product) external payable {
    if(msg.value > 0.000000002 ether) {
      Products[_Product].payed[msg.sender] = 1;
    }
  }

  // helper functions
  function toString(address account) public pure returns(string memory) {
    return toString(abi.encodePacked(account));
  }

  function toString(uint256 value) public pure returns(string memory) {
    return toString(abi.encodePacked(value));
  }

  function toString(bytes32 value) public pure returns(string memory) {
    return toString(abi.encodePacked(value));
  }

  function toString(bytes memory data) public pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
      str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
      str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
  }

  function checkEAN(string memory str) private pure returns (bool){
    bytes memory b = bytes(str);
    if(!(b.length == 13)) return false;

    for(uint i; i<b.length; i++){
      bytes1 char = b[i];

      if(!(char >= 0x30 && char <= 0x39))
        return false;
    }
    return true;
  }

  function isTime() view public returns (bool){
    if (FreeInserts[msg.sender] == 0 || FreeInserts[msg.sender] < block.timestamp) {
      return true;
    }
    return false;
  }

  function isMoney(uint256 _amount) view public returns (bool){
    if (address(this).balance > _amount) {
      return true;
    }
    return false;
  }

  function checkPayment(string memory _Product, address _User) view public returns (bool){
    if (Products[_Product].reviewIds.length > 9 && Products[_Product].payed[_User] == 0){
      return false;
    }
    return true;
  }
}