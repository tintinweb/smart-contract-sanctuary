/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// File: contracts\Owned.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Owned {

  address public owner = msg.sender;

  event LogOwnershipTransferred(address indexed owner, address indexed newOwner);

  modifier onlyOwner {
    require(msg.sender == owner, "Only owner");
    _;
  }

  function setOwner(address _owner)
    external
    onlyOwner
  {
    require(_owner != address(0), "Owner cannot be zero address");
    emit LogOwnershipTransferred(owner, _owner);
    owner = _owner;
  }
}

// File: contracts\interfaces\IAvnNftAuctionV1.sol


pragma solidity 0.8.4;

interface IAvnNftAuctionV1 {

  struct NFT {
    bool isListed;
    address seller;
    uint64 avnOpId;
    uint256 price;
    uint256 endTime;
  }

  struct Batch {
    bool isListed;
    address seller;
    uint256 saleFunds;
    uint256 price;
    uint256 endTime;
    uint64 initialSupply;
    uint64 saleIndex;
    uint256 royaltiesId;
  }

  struct Bid {
    address bidder;
    bytes32 avnPublicKey;
    uint256 amount;
  }

  struct Royalty {
    address recipient;
    uint256 partsPerMil;
  }

  event AvnTransferTo(uint256 indexed nftId, bytes32 indexed avnPublicKey, uint64 indexed avnOpId);
  event AvnMintTo(uint256 indexed batchId, bytes32 indexed avnPublicKey, uint64 indexed saleIndex);
  event AvnCancelBatchListing(uint256 indexed batchId);
  event AvnCancelNftListing(uint256 indexed nftId, uint64 indexed avnOpId);

  event LogStartAuction(uint256 indexed nftId, address indexed seller, uint256 reservePrice, uint256 endTime);
  event LogBid(uint256 indexed nftId, address indexed bidder, bytes32 indexed avnPublicKey, uint256 amount);
  event LogAuctionComplete(uint256 indexed nftId, address indexed winner, uint256 indexed winningBid);
  event LogAuctionCancelled(uint256 indexed nftId);
  event LogStartBatchSale(uint256 indexed batchId, address indexed seller, uint256 price, uint64 initialSupply, uint256 endTime);
  event LogSoldFromBatch(uint256 indexed batchId, uint256 indexed nftId, address indexed buyer);
  event LogBatchSaleComplete(uint256 indexed batchId, uint64 amountSold);
  event LogBatchSaleCancelled(uint256 indexed batchId);
  event LogStartNftSale(uint256 indexed nftId, address indexed seller, uint256 price);
  event LogNftSaleComplete(uint256 indexed nftId, address indexed buyer);
  event LogNftSaleCancelled(uint256 indexed nftId);

  function setAuthority(address authority, bool isAuthorised) external; // onlyOwner
  function startAuction(uint256 nftId, uint256 reservePrice, uint256 endTime, uint64 avnOpId, Royalty[] calldata royalties,
      bytes calldata proof) external;
  function bid(uint256 nftId, bytes32 avnPublicKey) external payable;
  function endAuction(uint256 nftId) external; // onlySeller
  function cancelAuction(uint256 nftId) external; // either Seller, Owner, or Authority
  function startBatchSale(uint256 batchId, uint256 price, uint256 endTime, uint64 initialSupply, Royalty[] calldata royalties,
      bytes calldata proof) external;
  function buyFromBatch(uint256 batchId, bytes32 avnPublicKey) external payable;
  function endBatchSale(uint256 batchId) external; // onlySeller
  function startNftSale(uint256 nftId, uint256 price, uint64 avnOpId, bytes calldata proof) external;
  function buyNft(uint256 nftId, bytes32 avnPublicKey) external payable;
  function cancelNftSale(uint256 nftId) external; // either Seller, Owner, or Authority
}

// File: ..\contracts\AvnNftAuctionV1.sol



pragma solidity 0.8.4;

contract AvnNftAuctionV1 is IAvnNftAuctionV1, Owned {

  string constant private AVN_LIST_NFT = "AVN_LIST_NFT";
  string constant private AVN_START_BATCH_SALE = "AVN_START_BATCH_SALE";
  uint256 constant private EMPTY_END_TIME_FOR_SINGLE_SALE = 0;
  uint256 constant private ONE_MILLION = 1000000;
  uint64 constant private UNLIMITED_SUPPLY = type(uint64).max;
  bytes1 constant private BATCH_HASH_PREFIX = 0x42; // "B"
  uint64 constant private EMPTY_OPID_FOR_BATCH_SALE = 0;
  bool private payingOut;
  uint256 private rId;

  mapping (address => bool) public authority;
  mapping (uint256 => NFT) private nft;
  mapping (uint256 => Batch) private batch;
  mapping (uint256 => Bid) private highBid;
  mapping (uint256 => uint256) private royaltiesId; // nftId => royaltiesId
  mapping (uint256 => Royalty[]) private royalties; // royaltiesId => royalties
  mapping (bytes32 => bool) private proofUsed;

  modifier nftIsListed(uint256 _nftId) {
    require(nft[_nftId].isListed, "NFT is not listed");
    _;
  }

  modifier nftIsNotListed(uint256 _nftId) {
    require(!nft[_nftId].isListed, "NFT is already listed");
    _;
  }

  modifier batchIsListed(uint256 _batchId) {
    require(batch[_batchId].isListed, "Batch is not listed");
    _;
  }

  modifier batchIsNotListed(uint256 _batchId) {
    require(!batch[_batchId].isListed, "Batch is already listed");
    _;
  }

  modifier endTimeIsValid(uint256 _endTime) {
    require(block.timestamp < _endTime, "End time has passed");
    _;
  }

  modifier onlySeller(address _seller) {
    require(_seller == msg.sender, "Only seller");
    _;
  }

  modifier onlySellerOrAuthorityOrOwner(uint256 _nftId) {
    require(msg.sender == nft[_nftId].seller || authority[msg.sender] || msg.sender == owner, "Not permitted");
    _;
  }

  function setAuthority(address _authority, bool _isAuthorised)
    external
    override
    onlyOwner
  {
    require(_authority != address(0), "Cannot authorise zero address");
    authority[_authority] = _isAuthorised;
  }

  function startAuction(uint256 _nftId, uint256 _reservePrice, uint256 _endTime, uint64 _avnOpId, Royalty[] calldata _royalties,
      bytes calldata _proof)
    external
    override
    nftIsNotListed(_nftId)
    endTimeIsValid(_endTime)
  {
    checkProof(AVN_LIST_NFT, _nftId, _endTime, _avnOpId, _proof);

    nft[_nftId].isListed = true;
    nft[_nftId].seller = msg.sender;
    nft[_nftId].avnOpId = _avnOpId;
    nft[_nftId].endTime = _endTime;

    highBid[_nftId].amount = (_reservePrice > 0) ? _reservePrice - 1 : 0;

    if (royaltiesId[_nftId] == 0) {
      rId++;
      royaltiesId[_nftId] = rId;
      setRoyalties(rId, _royalties);
    }

    emit LogStartAuction(_nftId, msg.sender, _reservePrice, _endTime);
  }

  function bid(uint256 _nftId, bytes32 _avnPublicKey)
    external
    override
    payable
    nftIsListed(_nftId)
  {
    require(block.timestamp <= nft[_nftId].endTime, "Bidding has ended");
    require(msg.value > highBid[_nftId].amount, "Bid too low");
    require(_avnPublicKey != 0, "AVN public key required");

    refundAnyExistingBid(_nftId);
    highBid[_nftId].bidder = msg.sender;
    highBid[_nftId].avnPublicKey = _avnPublicKey;
    highBid[_nftId].amount = msg.value;

    emit LogBid(_nftId, highBid[_nftId].bidder, highBid[_nftId].avnPublicKey, highBid[_nftId].amount);
  }

  function endAuction(uint256 _nftId)
    external
    override
    nftIsListed(_nftId)
    onlySeller(nft[_nftId].seller)
  {
    require(block.timestamp > nft[_nftId].endTime, "Cannot end auction yet");
    nft[_nftId].isListed = false;

    if (highBid[_nftId].bidder == address(0)) {
      emit LogAuctionCancelled(_nftId);
      emit AvnCancelNftListing(_nftId, nft[_nftId].avnOpId);
    } else {
      distributeFunds(royaltiesId[_nftId], highBid[_nftId].amount, msg.sender);
      emit LogAuctionComplete(_nftId, highBid[_nftId].bidder, highBid[_nftId].amount);
      emit AvnTransferTo(_nftId, highBid[_nftId].avnPublicKey, nft[_nftId].avnOpId);
    }

    delete highBid[_nftId];
    delete nft[_nftId];
  }

  function cancelAuction(uint256 _nftId)
    external
    override
    nftIsListed(_nftId)
    onlySellerOrAuthorityOrOwner(_nftId)
  {
    nft[_nftId].isListed = false;
    refundAnyExistingBid(_nftId);
    emit LogAuctionCancelled(_nftId);
    emit AvnCancelNftListing(_nftId, nft[_nftId].avnOpId);
  }

  function startBatchSale(uint256 _batchId, uint256 _price, uint256 _endTime, uint64 _initialSupply,
      Royalty[] calldata _royalties, bytes calldata _proof)
    external
    override
    batchIsNotListed(_batchId)
    endTimeIsValid(_endTime)
  {
    checkProof(AVN_START_BATCH_SALE, _batchId, _endTime, EMPTY_OPID_FOR_BATCH_SALE, _proof);

    batch[_batchId].isListed = true;
    batch[_batchId].seller = msg.sender;
    batch[_batchId].price = _price;
    batch[_batchId].endTime = _endTime;
    batch[_batchId].initialSupply = (_initialSupply > 0) ? _initialSupply : UNLIMITED_SUPPLY;
    rId++;
    batch[_batchId].royaltiesId = rId;
    setRoyalties(rId, _royalties);

    emit LogStartBatchSale(_batchId, msg.sender, _price, batch[_batchId].initialSupply, _endTime);
  }

  function buyFromBatch(uint256 _batchId, bytes32 _avnPublicKey)
    external
    override
    payable
    batchIsListed(_batchId)
  {
    require(block.timestamp <= batch[_batchId].endTime, "Sales have ended");
    require(msg.value == batch[_batchId].price, "Incorrect price");
    require(_avnPublicKey != 0, "AVN public key required");
    require(batch[_batchId].initialSupply - batch[_batchId].saleIndex > 0, "Sold out");

    batch[_batchId].saleIndex++;
    // TODO - Do we need BATCH_HASH_PREFIX and the contract address here (since T2 already incorporates these into batchId)?
    uint256 nftId = uint256(keccak256(abi.encodePacked(BATCH_HASH_PREFIX, address(this), _batchId, batch[_batchId].saleIndex)));
    royaltiesId[nftId] = batch[_batchId].royaltiesId;
    batch[_batchId].saleFunds += msg.value;

    emit LogSoldFromBatch(_batchId, nftId, msg.sender);
    emit AvnMintTo(_batchId, _avnPublicKey, batch[_batchId].saleIndex);
  }

  function endBatchSale(uint256 _batchId)
    external
    override
    batchIsListed(_batchId)
    onlySeller(batch[_batchId].seller)
  {
    require(block.timestamp > batch[_batchId].endTime, "Cannot end sales yet");
    batch[_batchId].isListed = false;

    if (batch[_batchId].saleIndex > 0) {
      uint256 totalSalesAmount = batch[_batchId].saleFunds;
      batch[_batchId].saleFunds = 0;
      distributeFunds(batch[_batchId].royaltiesId, totalSalesAmount, msg.sender);
      emit LogBatchSaleComplete(_batchId, batch[_batchId].saleIndex);
    } else {
      emit LogBatchSaleCancelled(_batchId);
      emit AvnCancelBatchListing(_batchId);
    }
  }

  function startNftSale(uint256 _nftId, uint256 _price, uint64 _avnOpId, bytes calldata _proof)
    external
    override
    nftIsNotListed(_nftId)
  {
    checkProof(AVN_LIST_NFT, _nftId, EMPTY_END_TIME_FOR_SINGLE_SALE, _avnOpId, _proof);
    nft[_nftId].isListed = true;
    nft[_nftId].seller = msg.sender;
    nft[_nftId].avnOpId = _avnOpId;
    nft[_nftId].price = _price;
    emit LogStartNftSale(_nftId, msg.sender, _price);
  }

  function buyNft(uint256 _nftId, bytes32 _avnPublicKey)
    external
    override
    payable
    nftIsListed(_nftId)
  {
    require(msg.value == nft[_nftId].price, "Incorrect price");
    require(_avnPublicKey != 0, "AVN public key required");
    nft[_nftId].isListed = false;
    distributeFunds(royaltiesId[_nftId], msg.value, nft[_nftId].seller);
    emit LogNftSaleComplete(_nftId, msg.sender);
    emit AvnTransferTo(_nftId, _avnPublicKey,  nft[_nftId].avnOpId);
  }

  function cancelNftSale(uint256 _nftId)
    external
    override
    nftIsListed(_nftId)
    onlySellerOrAuthorityOrOwner(_nftId)
  {
    nft[_nftId].isListed = false;
    emit LogNftSaleCancelled(_nftId);
    emit AvnCancelNftListing(_nftId, nft[_nftId].avnOpId);
  }

  function sendFunds(address _recipient, uint256 _amount)
    private
  {
    (bool success, ) = _recipient.call{value: _amount}("");
    require(success, "Transfer failed");
  }

  function setRoyalties(uint256 _royaltiesId, Royalty[] memory _royalties)
    private
  {
    uint256 totalRoyalties;

    for (uint256 i = 0; i < _royalties.length; i++) {
      require(_royalties[i].recipient != address(0), "Missing royalty recipient");
      totalRoyalties += _royalties[i].partsPerMil;
      require(totalRoyalties <= ONE_MILLION, "Royalties too high");
      royalties[_royaltiesId].push(_royalties[i]);
    }
  }

  function checkProof(string memory _proofType, uint256 _id, uint256 _endTime, uint64 _avnOpId, bytes memory _proof)
    private
  {
    bytes32 msgHash = keccak256(abi.encodePacked(_proofType, _id, msg.sender, _endTime, _avnOpId));
    require(!proofUsed[msgHash], "Proof already used");
    proofUsed[msgHash] = true;
    address signer = recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)), _proof);
    require(authority[signer], "Invalid proof");
  }

  function recover(bytes32 hash, bytes memory signature)
    private
    pure
    returns (address)
  {
    if (signature.length != 65) return address(0);

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return address(0);
    if (v < 27) v += 27;
    if (v != 27 && v != 28) return address(0);

    return ecrecover(hash, v, r, s);
  }

  function refundAnyExistingBid(uint256 _nftId)
    private
  {
    if (highBid[_nftId].bidder != address(0)) {
      address bidder = highBid[_nftId].bidder;
      uint256 amount = highBid[_nftId].amount;
      delete highBid[_nftId];
      sendFunds(bidder, amount);
    }
  }

  function distributeFunds(uint256 _royaltiesId, uint256 _amount, address _seller)
    private
  {
    assert(!payingOut);
    payingOut = true;
    uint256 remaining = _amount;

    if (_royaltiesId != 0) {
      uint256 royaltyPayment;
      for (uint256 i = 0; i < royalties[_royaltiesId].length; i++) {
        royaltyPayment = _amount * royalties[_royaltiesId][i].partsPerMil / ONE_MILLION;
        remaining -= royaltyPayment;
        sendFunds(royalties[_royaltiesId][i].recipient, royaltyPayment);
      }
    }

    sendFunds(_seller, remaining);
    payingOut = false;
  }
}