/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface Etheria {
  function getOwner(uint8 col, uint8 row) external view returns(address);
  function setOwner(uint8 col, uint8 row, address newOwner) external;
}

interface MapElevationRetriever {
  function getElevation(uint8 col, uint8 row) external view returns (uint8);
}

contract EtheriaExchangeXL {

  address public owner;
  address public pendingOwner;

  string public name = "EtheriaExchangeXL";

  Etheria public constant etheria = Etheria(address(0xB21f8684f23Dbb1008508B4DE91a0aaEDEbdB7E4));
  MapElevationRetriever public constant mapElevationRetriever = MapElevationRetriever(address(0x68549D7Dbb7A956f955Ec1263F55494f05972A6b));

  uint128 public minBid = uint128(1 ether); // setting this to 10 finney throws compilation error for some reason
  uint256 public feeRate = uint256(100);  // in basis points (100 is 1%)
  uint256 public collectedFees;

  struct Bid {
    uint128 amount;
    uint8 minCol;        // shortened all of these for readability
    uint8 maxCol;
    uint8 minRow;
    uint8 maxRow;
    uint8 minEle;
    uint8 maxEle;
    uint8 minWat;
    uint8 maxWat;
    uint64 biddersIndex; // renamed from bidderIndex because it's the Index of the bidders array
  }

  address[] public bidders;

  mapping (address => Bid) public addressToBidMap;                                          // renamed these three to be ultra-descriptive
  mapping (address => uint256) public addressToPendingWithdrawalMap;
  mapping (uint16 => uint128) public indexToAskMap;

  event OwnershipTransferInitiated(address indexed owner, address indexed pendingOwner);    // renamed some of these to conform to past tense verbs
  event OwnershipTransferAccepted(address indexed oldOwner, address indexed newOwner);
  event BidCreated(address indexed bidder, uint128 indexed amount, uint8 minCol, uint8 maxCol, uint8 minRow, uint8 maxRow, uint8 minEle, uint8 maxEle, uint8 minWat, uint8 maxWat);
  event BidAccepted(address indexed seller, address indexed bidder, uint128 indexed amount, uint16 col, uint16 row, uint8 minCol, uint8 maxCol, uint8 minRow, uint8 maxRow, uint8 minEle, uint8 maxEle, uint8 minWat, uint8 maxWat);
  event BidCancelled(address indexed bidder, uint128 indexed amount, uint8 minCol, uint8 maxCol, uint8 minRow, uint8 maxRow, uint8 minEle, uint8 maxEle, uint8 minWat, uint8 maxWat);
  event AskCreated(address indexed owner, uint256 indexed price, uint8 col, uint8 row);    
  event WithdrawalProcessed(address indexed account, address indexed destination, uint256 indexed amount);
  
  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "EEXL: Not owner");
    _;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    pendingOwner = newOwner;
    emit OwnershipTransferInitiated(msg.sender, newOwner);
  }

  function acceptOwnership() external {
    require(msg.sender == pendingOwner, "EEXL: Not pending owner");
    emit OwnershipTransferAccepted(owner, msg.sender);
    owner = msg.sender;
    pendingOwner = address(0);
  }

  function _safeTransferETH(address recipient, uint256 amount) internal {
    // Secure transfer of ETH that is much less likely to be broken by future gas-schedule EIPs
    (bool success, ) = recipient.call{ value: amount }(""); // syntax: (bool success, bytes memory data) = _addr.call{value: msg.value, gas: 5000}(encoded function and data)
    require(success, "EEXL: ETH transfer failed");
  }

  function collectFees() external onlyOwner {
    uint256 amount = collectedFees;
    collectedFees = uint256(0);
    _safeTransferETH(msg.sender, amount);
  }

  function setFeeRate(uint256 newFeeRate) external onlyOwner {
    // Set the feeRate to newFeeRate, then validate it
    require((feeRate = newFeeRate) <= uint256(500), "EEXL: Invalid feeRate"); // feeRate will revert if req fails
  }

  function setMinBid(uint128 newMinBid) external onlyOwner {
    minBid = newMinBid;                                                     // doubly beneficial because I could effectively kill new bids with a huge minBid 
  }                                                                         // in the event of an exchange upgrade or unforseen problem

  function _getIndex(uint8 col, uint8 row) internal pure returns (uint16) {
    require(_isValidColOrRow(col) && _isValidColOrRow(row), "EEXL: Invalid col and/or row");
    return (uint16(col) * uint16(33)) + uint16(row);
  }
  
  function _isValidColOrRow(uint8 value) internal pure returns (bool) {
    return (value >= uint8(0)) && (value <= uint8(32));                    // while nobody should be checking, eg, getAsk when row/col=0/32, we do want to respond non-erroneously
  }

  function _isValidElevation(uint8 value) internal pure returns (bool) {
    return (value >= uint8(125)) && (value <= uint8(216));
  }

  function _isWater(uint8 col, uint8 row) internal view returns (bool) {
    return mapElevationRetriever.getElevation(col, row) < uint8(125);   
  }

  function _boolToUint8(bool value) internal pure returns (uint8) {
    return value ? uint8(1) : uint8(0);
  }

  function _getSurroundingWaterCount(uint8 col, uint8 row) internal view returns (uint8 waterTiles) {  
    require((col >= uint8(1)) && (col <= uint8(31)), "EEXL: Water counting requres col 1-31");
    require((row >= uint8(1)) && (row <= uint8(31)), "EEXL: Water counting requres col 1-31");
    if (row % uint8(2) == uint8(1)) {
      waterTiles += _boolToUint8(_isWater(col + uint8(1), row + uint8(1)));  // northeast_hex
      waterTiles += _boolToUint8(_isWater(col + uint8(1), row - uint8(1)));  // southeast_hex
    } else {
      waterTiles += _boolToUint8(_isWater(col - uint8(1), row - uint8(1)));  // southwest_hex
      waterTiles += _boolToUint8(_isWater(col - uint8(1), row + uint8(1)));  // northwest_hex
    }

    waterTiles += _boolToUint8(_isWater(col, row - uint8(1)));               // southwest_hex or southeast_hex
    waterTiles += _boolToUint8(_isWater(col, row + uint8(1)));               // northwest_hex or northeast_hex
    waterTiles += _boolToUint8(_isWater(col + uint8(1), row));               // east_hex
    waterTiles += _boolToUint8(_isWater(col - uint8(1), row));               // west_hex
  }

  function getBidders() public view returns (address[] memory) {
    return bidders;
  }

  function getAsk(uint8 col, uint8 row) public view returns (uint128) {
    return indexToAskMap[_getIndex(col, row)];
  }

  function getAsks() external view returns (uint128[1088] memory asks) {  
    for (uint256 i; i <= uint256(1088); ++i) {
        asks[i] = indexToAskMap[uint16(i)];
    }
  }

  function setAsk(uint8 col, uint8 row, uint128 price) external {
    require(etheria.getOwner(col, row) == msg.sender, "EEXL: Not tile owner");
    emit AskCreated(msg.sender, indexToAskMap[_getIndex(col, row)] = price, col, row);
  }

  function makeBid(uint8 minCol, uint8 maxCol, uint8 minRow, uint8 maxRow, uint8 minEle, uint8 maxEle, uint8 minWat, uint8 maxWat) external payable {
    require(msg.sender == tx.origin, "EEXL: not EOA");  // (EOA = Externally owned account) // Etheria doesn't allow tile ownership by contracts, this check prevents black-holing
    
    require(msg.value <= type(uint128).max, "EEXL: value too high");
    require(msg.value >= minBid, "EEXL: req bid amt >= minBid");              
    require(msg.value >= 0, "EEXL: req bid amt >= 0");
    
    require(addressToBidMap[msg.sender].amount == uint128(0), "EEXL: bid exists, cancel first");

    require(_isValidColOrRow(minCol), "EEXL: minCol OOB");
    require(_isValidColOrRow(maxCol), "EEXL: maxCol OOB");
    require(minCol <= maxCol, "EEXL: req minCol <= maxCol");

    require(_isValidColOrRow(minRow), "EEXL: minRow OOB");
    require(_isValidColOrRow(maxRow), "EEXL: maxRow OOB");
    require(minRow <= maxRow, "EEXL: req minRow <= maxRow");

    require(_isValidElevation(minEle), "EEXL: minEle OOB");   // these ele checks prevent water bidding, regardless of row/col
    require(_isValidElevation(maxEle), "EEXL: maxEle OOB");
    require(minEle <= maxEle, "EEXL: req minEle <= maxEle");

    require(minWat <= uint8(6), "EEXL: minWat OOB");
    require(maxWat <= uint8(6), "EEXL: maxWat OOB");
    require(minWat <= maxWat, "EEXL: req minWat <= maxWat");

    uint256 biddersArrayLength = bidders.length;                           
    require(biddersArrayLength < type(uint64).max, "EEXL: too many bids"); 

    addressToBidMap[msg.sender] = Bid({
      amount: uint128(msg.value),
      minCol: minCol,
      maxCol: maxCol,
      minRow: minRow,
      maxRow: maxRow,
      minEle: minEle,
      maxEle: maxEle,
      minWat: minWat,
      maxWat: maxWat,
      biddersIndex: uint64(biddersArrayLength)
    });

    bidders.push(msg.sender);

    emit BidCreated(msg.sender, uint128(msg.value), minCol, maxCol, minRow, maxRow, minEle, maxEle, minWat, maxWat);
  }

  function _deleteBid(address bidder, uint64 biddersIndex) internal { // used by cancelBid and acceptBid
    address lastBidder = bidders[bidders.length - uint256(1)];

    // If bidder not last bidder, overwrite with last bidder 
    if (bidder != lastBidder) {
      bidders[biddersIndex] = lastBidder;            // Overwrite the bidder at the index with the last bidder
      addressToBidMap[lastBidder].biddersIndex = biddersIndex;  // Update the bidder index of the bid of the previously last bidder
    }

    delete addressToBidMap[bidder];
    bidders.pop();
  }

  function cancelBid() external {
    // Cancels the bid, getting the bid's amount, which is then added account's pending withdrawal
    Bid storage bid = addressToBidMap[msg.sender];
    uint128 amount = bid.amount;

    require(amount != uint128(0), "EEXL: No existing bid");

    emit BidCancelled(msg.sender, amount, bid.minCol, bid.maxCol, bid.minRow, bid.maxRow, bid.minEle, bid.maxEle, bid.minWat, bid.maxWat);

    _deleteBid(msg.sender, bid.biddersIndex);
    addressToPendingWithdrawalMap[msg.sender] += uint256(amount);
  }

  function acceptBid(uint8 col, uint8 row, address bidder, uint256 minAmount) external {
    require(etheria.getOwner(col, row) == msg.sender, "EEXL: Not owner"); // etheria.setOwner will fail below if not owner, making this check unnecessary, but I want this here anyway
    
    Bid storage bid = addressToBidMap[bidder];
    uint128 amount = bid.amount;

    require(
      (amount >= minAmount) &&
      (col >= bid.minCol) &&
      (col <= bid.maxCol) &&
      (row >= bid.minRow) &&
      (row <= bid.maxRow) &&
      (mapElevationRetriever.getElevation(col, row) >= bid.minEle) &&
      (mapElevationRetriever.getElevation(col, row) <= bid.maxEle) &&
      (_getSurroundingWaterCount(col, row) >= bid.minWat) &&
      (_getSurroundingWaterCount(col, row) <= bid.maxWat),
      "EEXL: tile doesn't meet bid reqs"
    );

    emit BidAccepted(msg.sender, bidder, amount, col, row, bid.minCol, bid.maxCol, bid.minRow, bid.maxRow, bid.minEle, bid.maxEle, bid.minWat, bid.maxWat);
                                                                                                                                                        
    _deleteBid(bidder, bid.biddersIndex);

    etheria.setOwner(col, row, bidder);
    require(etheria.getOwner(col, row) == bidder, "EEXL: failed setting tile owner"); // ok for require after event emission. Events are technically state changes and atomic as well.

    uint256 fee = (uint256(amount) * feeRate) / uint256(10_000);
    collectedFees += fee;

    addressToPendingWithdrawalMap[msg.sender] += (uint256(amount) - fee);

    delete indexToAskMap[_getIndex(col, row)];
  }

  function _withdraw(address account, address payable destination) internal {
    uint256 amount = addressToPendingWithdrawalMap[account];
    require(amount > uint256(0), "EEXL: nothing pending");

    addressToPendingWithdrawalMap[account] = uint256(0);
    _safeTransferETH(destination, amount);

    emit WithdrawalProcessed(account, destination, amount);
  }

  function withdraw(address payable destination) external {
    _withdraw(msg.sender, destination);
  }

  function withdraw() external {
    _withdraw(msg.sender, payable(msg.sender));
  }

}