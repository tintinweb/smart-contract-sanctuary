/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// File: contracts\Owned.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// File: contracts\interfaces\IAveNFT.sol


pragma solidity ^0.8.0;

interface IAveNFT {

  struct NFT {
    bool isLocked;
    uint64 transferNonce;
    uint256 batchId;
    uint256 internalBatchNumber;
  }

  struct Royalty {
    address recipient;
    uint256 partsPerMil;
  }

  struct Buyer {
    address ethereumAddress;
    bytes32 avnPublicKey;
  }

  struct SingleNFTData {
    address origin;
    uint256 nft_id;
    string unique_external_ref;
    address owner;
    Royalty[] royalties;
    address minter_t1_address;
  }

  struct BatchNFTData {
    address origin;
    uint256 nft_id;
    uint256 batch_id;
    string unique_external_ref;
    address owner;
    Royalty[] royalties;
    address minter_t1_address;
    uint64 total_supply;
  }

  event LogHighBid(uint256 indexed nftId, address indexed bidder, bytes32 indexed avnPublicKey, uint256 bidIncreasedBy, uint256 currentBid);
  event LogAuctionEnd(uint256 indexed nftId, address indexed winner, uint256 indexed winningBid);
  event LogSaleStart(uint256 indexed batchId, uint256 priceInWei, uint256 initialSupply);
  event LogBuy(uint256 indexed batchId, uint256 indexed internalBatchNumber, uint256 indexed nftId, address buyer, bytes32 avnPublicKey);
  event LogSaleEnd(uint256 indexed batchId, uint256 finalSupply);

  function setURI(string calldata uri) external; // onlyOwner
  function setTransferrerPermission(address transferrer, bool isPermitted) external; // onlyOwner
  function setNFTLock(uint256 nftId, bool isLocked) external; // onlyOwner
  function setNoRoyalties(uint256 id, bool doesNotPayRoyalties) external; // onlyOwner
  function bidOrIncreaseBid(uint256 nftId, bytes32 avnPublicKey) external payable;
  function withdrawBid(uint256 nftId) external;
  function endAuction(uint256 nftId, Royalty[] calldata royalties, uint256 reservePriceInWei) external; // onlyOwner
  function startSale(uint256 batchId, uint256 priceInWei, uint64 initialSupply) external; // onlyOwner
  function buy(uint256 batchId, bytes32 avnPublicKey) external payable;
  function endSale(uint256 batchId, Royalty[] calldata royalties) external; // onlyOwner
  function onTransfer(uint256 nftId, address seller) external payable returns (uint64); //onlyTransferrer
  function getSingleNFTData(uint256 _nftId) external view returns (SingleNFTData memory);
  function getBatchNFTData(uint256 _nftId) external view returns (BatchNFTData memory);
  function getNFTId(uint256 batchId, uint256 internalBatchNumber) external pure returns (uint256);
  function isValidNFT(uint256 nftId) external returns (bool);
}

// File: ..\contracts\AveNFT.sol



pragma solidity ^0.8.0;

contract AveNFT is IAveNFT, Owned {

  uint256 constant private ONE_MILLION = 1000000;
  uint64 constant private UNLIMITED_SUPPLY = type(uint64).max;
  bool private payingOut;

  mapping (address => bool) public canTransfer;
  mapping (uint256 => NFT) private nft;
  mapping (uint256 => Buyer[]) private buyers;
  mapping (uint256 => Royalty[]) private royalties;
  mapping (uint256 => mapping(address => uint256)) private bidderFunds;
  mapping (uint256 => uint256) saleFunds;
  mapping (uint256 => bool) private isSale;
  mapping (uint256 => bool) private isEnded;
  mapping (uint256 => uint256) private price;
  mapping (uint256 => bool) private noRoyalties;
  mapping (uint256 => uint64) private totalSupply;
  string private uri;

  constructor (string memory _uri) {
    uri = _uri;
  }

  function setURI(string calldata _uri)
    external
    override
    onlyOwner
  {
    uri = _uri;
  }

  function setTransferrerPermission(address _transferrer, bool _isPermitted)
    external
    override
    onlyOwner
  {
    canTransfer[_transferrer] = _isPermitted;
  }

  function setNFTLock(uint256 _nftId, bool _isLocked)
    external
    override
    onlyOwner
  {
    nft[_nftId].isLocked = _isLocked;
  }

  function setNoRoyalties(uint256 _id, bool _doesNotPayRoyalties)
    external
    override
    onlyOwner
  {
    noRoyalties[_id] = _doesNotPayRoyalties;
  }

  function bidOrIncreaseBid(uint256 _nftId, bytes32 _avnPublicKey)
    external
    override
    payable
  {
    require(_nftId != 0, "Missing NFT ID");
    require(!isSale[_nftId], "Cannot bid on a sale");
    require(_avnPublicKey != 0, "Missing AVN public key");
    bidderFunds[_nftId][msg.sender] += msg.value;

    if (buyers[_nftId].length == 0) {
      buyers[_nftId].push(Buyer(msg.sender, _avnPublicKey));
    }

    if (msg.sender == buyers[_nftId][0].ethereumAddress) {
      price[_nftId] = bidderFunds[_nftId][msg.sender];
    } else {
      require(bidderFunds[_nftId][msg.sender] > price[_nftId], "Bid too low");
      price[_nftId] = bidderFunds[_nftId][msg.sender];
      buyers[_nftId][0] = Buyer(msg.sender, _avnPublicKey);
    }

    emit LogHighBid(_nftId, msg.sender, _avnPublicKey, msg.value, price[_nftId]);
  }

  function withdrawBid(uint256 _nftId)
    external
    override
  {
    require(_nftId != 0, "Missing NFT ID");
    uint256 funds = bidderFunds[_nftId][msg.sender];
    require(funds > 0, "No funds to withdraw");
    require(!isSale[_nftId], "Cannot withdraw from a sale");
    require(msg.sender != buyers[_nftId][0].ethereumAddress, "Cannot withdraw unless outbid");
    bidderFunds[_nftId][msg.sender] = 0;
    sendFunds(msg.sender, funds);
  }

  function endAuction(uint256 _nftId, Royalty[] calldata _royalties, uint256 _reservePriceInWei)
    external
    override
    onlyOwner
  {
    require(!isSale[_nftId], "Please call endSale");
    require(!isEnded[_nftId], "Auction already closed");
    isEnded[_nftId] = true;

    address winner;
    uint256 winningBid;

    if (buyers[_nftId].length == 1) {
      if (winningBid >= _reservePriceInWei) {
        winner = buyers[_nftId][0].ethereumAddress;
        winningBid = bidderFunds[_nftId][winner];
        totalSupply[_nftId] = 1;
        bidderFunds[_nftId][winner] = 0;
        setRoyaltiesAndDistributeFunds(_nftId, _royalties, winningBid);
      } else {
        totalSupply[_nftId] = 0;
        buyers[_nftId][0].ethereumAddress = address(0);
      }
    } else {
      totalSupply[_nftId] = 0;
    }

    emit LogAuctionEnd(_nftId, winner, winningBid);
  }

  function startSale(uint256 _batchId, uint256 _priceInWei, uint64 _initialSupply)
    external
    override
    onlyOwner
  {
    require(!isSale[_batchId], "Sale already exists");
    isSale[_batchId] = true;
    price[_batchId] = _priceInWei;
    totalSupply[_batchId] = (_initialSupply > 0) ? _initialSupply : UNLIMITED_SUPPLY;
    emit LogSaleStart(_batchId, _priceInWei, _initialSupply);
  }

  function buy(uint256 _batchId, bytes32 _avnPublicKey)
    external
    override
    payable
  {
    require(!isEnded[_batchId], "Sale has ended");
    require(isSale[_batchId], "Not a sale");
    require(msg.value == price[_batchId], "Price must match");
    require(totalSupply[_batchId] - buyers[_batchId].length > 0, "Sold out");
    buyers[_batchId].push(Buyer(msg.sender, _avnPublicKey));
    uint256 internalBatchNumber = buyers[_batchId].length;
    saleFunds[_batchId] += msg.value;
    uint256 nftId = getNFTId(_batchId, internalBatchNumber);
    nft[nftId].internalBatchNumber = internalBatchNumber;
    nft[nftId].batchId = _batchId;
    emit LogBuy(_batchId, internalBatchNumber, nftId, msg.sender, _avnPublicKey);
  }

  function endSale(uint256 _batchId, Royalty[] calldata _royalties)
    external
    override
    onlyOwner
  {
    require(!isEnded[_batchId], "Sale already ended");
    isEnded[_batchId] = true;
    if (buyers[_batchId].length > 0) {
      totalSupply[_batchId] = uint64(buyers[_batchId].length);
      uint256 totalSales = saleFunds[_batchId];
      saleFunds[_batchId] = 0;
      setRoyaltiesAndDistributeFunds(_batchId, _royalties, totalSales);
    } else {
      totalSupply[_batchId] = 0;
    }

    emit LogSaleEnd(_batchId, totalSupply[_batchId]);
  }

  function onTransfer(uint256 _nftId, address _seller)
    external
    override
    payable
    returns (uint64)
  {
    require(canTransfer[msg.sender], "Permission required");
    if (!isValidNFT(_nftId)) return 0;
    if (nft[_nftId].isLocked) return 0;
    nft[_nftId].transferNonce += 1;
    uint256 id = (nft[_nftId].batchId == 0) ? _nftId : nft[_nftId].batchId;
    distributeFunds(id, msg.value, _seller);

    return nft[_nftId].transferNonce;
  }

  function getSingleNFTData(uint256 _nftId)
    external
    override
    view
    returns (SingleNFTData memory data_)
  {
    if (isValidNFT(_nftId))
      data_ = SingleNFTData(address(this), _nftId, getURI(_nftId), getBuyer(_nftId), royalties[_nftId], owner);
  }

  function getBatchNFTData(uint256 _nftId)
    external
    override
    view
    returns (BatchNFTData memory data_)
  {
    if (isValidNFT(_nftId))
      data_ = BatchNFTData(address(this), _nftId, nft[_nftId].batchId, getURI(_nftId), getBuyer(_nftId),
          royalties[nft[_nftId].batchId], owner, totalSupply[_nftId]);
  }

  function getNFTId(uint256 _batchId, uint256 _internalBatchNumber)
    public
    override
    pure
    returns (uint256)
  {
    return uint256(keccak256(abi.encode(_batchId, _internalBatchNumber)));
  }

  function isValidNFT(uint256 _nftId)
    public
    override
    view
    returns (bool)
  {
    return
      (isEnded[_nftId] && !isSale[_nftId] && nft[_nftId].internalBatchNumber == 0 && totalSupply[_nftId] == 1) ||
      (isEnded[_nftId] && isSale[_nftId] && nft[_nftId].internalBatchNumber > 0);
  }

  function getURI(uint256 _nftId)
    private
    view
    returns (string memory)
  {
    return string(abi.encodePacked(uri, toString(_nftId)));
  }

  function getBuyer(uint256 _nftId)
    private
    view
    returns (address buyer_)
  {
    if (isEnded[_nftId]) {
      if (nft[_nftId].internalBatchNumber == 0) {
        buyer_ = buyers[_nftId][0].ethereumAddress;
      } else {
        buyer_ = buyers[nft[_nftId].batchId][nft[_nftId].internalBatchNumber - 1].ethereumAddress;
      }
    }
  }

  function setRoyaltiesAndDistributeFunds(uint256 _id, Royalty[] memory _royalties, uint256 _amount)
    private
  {
    setRoyalties(_id, _royalties);
    distributeFunds(_id, _amount, owner);
  }

  function setRoyalties(uint256 _id, Royalty[] memory _royalties)
    private
  {
    uint256 totalRoyalties;

    for (uint256 i = 0; i < _royalties.length; i++) {
      require(_royalties[i].recipient != address(0), "Missing royalty recipient");
      totalRoyalties += _royalties[i].partsPerMil;
      require(totalRoyalties <= ONE_MILLION, "Royalties too high");
      royalties[_id].push(_royalties[i]);
    }
  }

  function distributeFunds(uint256 _id, uint256 _amount, address _seller)
    private
  {
    assert(!payingOut);
    payingOut = true;
    uint256 remaining = _amount;

    if (!noRoyalties[_id]) {
      uint256 royaltyPayment;
      for (uint256 i = 0; i < royalties[_id].length; i++) {
        royaltyPayment = _amount * royalties[_id][i].partsPerMil / ONE_MILLION;
        remaining -= royaltyPayment;
        sendFunds(royalties[_id][i].recipient, royaltyPayment);
      }
    }

    sendFunds(_seller, remaining);
    payingOut = false;
  }

  function sendFunds(address _recipient, uint256 _amount)
    private
  {
    (bool success, ) = _recipient.call{value: _amount}("");
    require(success, "Transfer failed");
  }

  function toString(uint256 _value)
    private
    pure
    returns (string memory)
  {
    if (_value == 0) {
      return "0";
    }
    uint256 temp = _value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (_value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
      _value /= 10;
    }
    return string(buffer);
  }
}