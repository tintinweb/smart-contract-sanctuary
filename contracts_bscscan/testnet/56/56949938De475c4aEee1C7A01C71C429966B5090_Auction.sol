// SPDX-License-Identifier: --🌲--

pragma solidity ^0.8.0;

import "./Interface.sol";

import "./SafeMath.sol";

/**
 * @title Treedefi Marketplace 
 *
 * @author treedefi
 */
contract Auction {

  using SafeMath for uint256;
  
  // Link to different contracts
  IBEP20Token private SEED;
  IBEP20Token private TREE;
  IBEP20Token private WBNB;
  ITreedefiForest private NFTREE;
  
  // Addresses that manage the system
  address private _admin;
  address private _treasury;
  address private _donation;
  
  // Default maximum duration
  uint256 private _maxDuration = 240 hours;
  
  // List of tree Ids putted for auction
  uint256[] public auctionList;

  // Mapping from treeId to auction details
    mapping(uint256 => Wood) public treeList;

  // Mapping from treeId to user bids
    mapping(uint256 => Bid[]) public auctionBids;

  // Mapping from treeId to maximum duration allowed by admin
    mapping(uint256 => uint256) public maxDuration;
  
  // Marketplace fee in percentage( with 10x value for precision) 
    Fee private _marketplaceFee;
    
  // Fee for place a bid in english auction
    Fee private _bidFee;
  
  // Fee struct to hold fee details for different payment types 
    struct Fee {
        uint256 _tree;
        uint256 _seed;
        uint256 _wbnb;
    }
    
  // Wood struct to hold auction details of tree
    struct Wood {
        bool forAuction;
        AuctionType auctionType;
        PaymentType paymentType;
        uint256 basePrice;
        uint256 startPrice;
        uint256 endPrice;
        uint64 duration;
        uint64 startedAt;
    }

  // Bid struct to hold bidder and amount
    struct Bid {
        address from;
        uint256 amount;
    }

  // Enumeration for auction type
  enum AuctionType { DUTCH, ENGLISH }
  
  // Enumeration for payment type
  enum PaymentType { TREE_TOKEN, SEED_TOKEN, WBNB_TOKEN }
  
  /**
	 * @dev Fired in buyTree() and acceptBid() when auction ends successfully 
	 *
	 * @param _from an address of previous owner
	 * @param _to an address of new owner
	 * @param _id Id of tree
	 * @param _value amount paid for purchase
	 * @param _paymentType defines amount paid in perticular token
	 */
  event Purchase(
        address indexed _from,
        address indexed _to,
        uint256 indexed _id,
        uint256 _value,
        PaymentType _paymentType
  );
  
  /**
	 * @dev Fired in listTreeForEnglishAuction() and listTreeForDutchAuction()
	 *       when tree is listed for auction successfully
	 *
	 * @param _owner an address of tree owner
	 * @param _id Id of tree
	 * @param _auctionType defines type of auction
	 * @param _duration defines duration of auction in number of seconds 
	 */
  event Listing(
        address indexed _owner,
        uint256 indexed _id,
        AuctionType _auctionType,
        uint256 _duration
  );
  
  /**
	 * @dev Fired in bidOnAuction() when bid is placed
	 *      for english auction successfully
	 *
	 * @param _from an address of bidder
	 * @param _treeId Id of tree
	 * @param _value defines bid amount to be paid
	 * @param _paymentType defines bid amount in perticular token 
	 */
  event BidSuccess(address indexed _from, uint _treeId, uint _value, PaymentType _paymentType);
  
  // Checks this contract is approved for given tree   
  modifier isManager(uint256 _id) {
    
    address _approved = NFTREE.getApproved(_id);
     
    require(
      address(this) == _approved,
      " Treedefi: Contract is not approved to manage token of this ID "
    );
    
    _;
  
  }
  
  // Checks given tree is listed for auction
  modifier listed(uint256 _id) {
    
    require(
      treeList[_id].forAuction,
      " Treedefi: TREE of this ID is not for listed for auction "
    );
    
    _;
  
  }
  
  // Checks duration falls into defined limit
  modifier durationAllowed(uint256 _id, uint64 _duration) {
    
    uint256 _max = (maxDuration[_id] == 0) ? _maxDuration : maxDuration[_id];

    require(
      _max >= _duration,
      " Treedefi: duration exceeds maximum limit defined by admin "
    );

    require(
      _duration >= 1 hours,
      " Treedefi: duration should be greater than 1 hour "
    );
    
    _;
  
  }
  
   /**
	 * @dev Creates/deploys treedefi marketplace
	 *
	 * @param _seedToken address of SEED token
	 * @param _treeToken address of TREE token
	 * @param _wbnb address of WBNB token
	 * @param _nftree address of NFTREE V2 
	 * @param _treasuryWallet address of treasury wallet 
	 * @param _donationWallet address of donation wallet
	 */
  constructor(
      address _seedToken, 
      address _treeToken, 
      address _wbnb, 
      address _nftree,
      address _treasuryWallet,
      address _donationWallet
    ) {

      SEED = IBEP20Token(_seedToken);
      TREE = IBEP20Token(_treeToken);
      WBNB = IBEP20Token(_wbnb);
      NFTREE = ITreedefiForest(_nftree);
      _admin = NFTREE.getOwner();
      _treasury = _treasuryWallet;
      _donation = _donationWallet;
      
      // Initialize marketplace fee
      // 0.5 percent for TREE & SEED, 3 percent for WBNB 
      _marketplaceFee = Fee(5, 5, 30);  
      
      
      // Initialize bid Fee
      // 0.01 for TREE & WBNB, 0.1 for SEED
      _bidFee = Fee(1E16, 1E17, 1E16);
  }
  

  /** @dev set maximum duration allowed for auction of perticular tree 
     *@param _id unsigned integer defines tokenID 
     *@param _duration unsigned integer defines maximum duration for auction
     */
  function setMaxDuration(uint256 _id, uint64 _duration) external {
    
    require(
      msg.sender == _admin,
      " Treedefi: only admin can define maximum duration "
    );
  
    maxDuration[_id] = _duration;

  }
  
  /** @dev sets marketplace fee charged for finalize an auction
    * @notice desired fee percentage should be multiply by 10 for precision   
     *@param _tree unsigned integer defines percentage of TREE token charged as a fee
     *@param _seed unsigned integer defines percentage of SEED token charged as a fee
     *@param _wbnb unsigned integer defines percentage of WBNB token charged as a fee
     */
  function setMarketplaceFee(uint256 _tree, uint256 _seed, uint256 _wbnb) external {
    
    require(
      msg.sender == _admin,
      " Treedefi: only admin can set fees "
    );
  
    _marketplaceFee = Fee(_tree, _seed, _wbnb);

  }
  
  /** @dev sets fee for placing bid in english auction  
     *@param _tree unsigned integer defines amount of TREE token charged as a fee
     *@param _seed unsigned integer defines amount of SEED token charged as a fee
     *@param _wbnb unsigned integer defines amount of WBNB token charged as a fee
     */
  function setBidFee(uint256 _tree, uint256 _seed, uint256 _wbnb) external {
    
    require(
      msg.sender == _admin,
      " Treedefi: only admin can set fees "
    );
  
    _bidFee = Fee(_tree, _seed, _wbnb);

  }
  
  /** @dev returns total number of auction count  
     */
  function auctionCount() external view returns (uint256) {
      return auctionList.length;
  }

  /** @dev List Treedefi Forest NFT for english auction 
     *@param _id unsigned integer defines tokenID to list for auction
     *@param _basePrice unsigned integer defines base price for the tokenID
     *@param _duration unsigned integer defines duration for auction
     *@param _paymentType unsigned integer defines payment type in terms of SEED/TREE/WBNB 
     */
  function listTreeForEnglishAuction(
    uint256 _id, 
    uint256 _basePrice, 
    uint64 _duration,
    PaymentType _paymentType
    ) 
    external 
    isManager(_id)
    durationAllowed(_id, _duration)
  {
    
    address _owner = NFTREE.ownerOf(_id);
    
    require(
      msg.sender == _owner,
      " Treedefi: Only owner of token can list the token for auction "
    );

    require(
      treeList[_id].forAuction == false,
      " Treedefi: Tree already listed for auction "
    );
     
    treeList[_id] = Wood(true, AuctionType.ENGLISH, _paymentType, _basePrice, 
                    0, 0, _duration, uint64(block.timestamp));
    
    auctionList.push(_id);
    
    emit Listing(_owner, _id, AuctionType.ENGLISH, _duration);

  }


  /** @dev List Treedefi Forest NFT for dutch auction 
     *@param _id unsigned integer defines tokenID to list for auction
     *@param _startPrice unsigned integer defines starting price 
     *@param _endPrice unsigned integer defines ending price 
     *@param _duration unsigned integer defines duration for auction
     *@param _paymentType unsigned integer defines payment type in terms of SEED/TREE/WBNB 
     */
  function listTreeForDutchAuction(
    uint256 _id, 
    uint256 _startPrice,
    uint256 _endPrice, 
    uint64 _duration,
    PaymentType _paymentType
    ) 
    external 
    isManager(_id)
    durationAllowed(_id, _duration)
  {
    
    address _owner = NFTREE.ownerOf(_id);

    require(
      msg.sender == _owner,
      " Treedefi: Only owner of token can list the token for auction "
    );

    require(
      treeList[_id].forAuction == false,
      " Treedefi: Tree already listed for auction "
    );
    
    require(
      _startPrice > _endPrice,
      " Treedefi: start price should be greater than end price "
    );
     
    treeList[_id] = Wood(true, AuctionType.DUTCH, _paymentType, 0, 
                        _startPrice, _endPrice, _duration, uint64(block.timestamp));

    auctionList.push(_id);
    
    emit Listing(_owner, _id, AuctionType.DUTCH, _duration);

  } 
  

  /** @dev Buy Treedefi Forest NFT for current price listed in dutch auction 
     *@param _id unsigned integer defines tokenID to buy
     *@param _value unsigned integer defines value of TREE/SEED/WBNB tokens to buy NFT 
     */
  function buyTree(uint256 _id, uint256 _value) 
    external
    isManager(_id)
    listed(_id)
  {
     
     address _owner = NFTREE.ownerOf(_id);
     
     IBEP20Token PaymentToken = getPaymentInterface(_id);

     uint256 _currentPrice = getCurrentPrice(_id);

      require(
      treeList[_id].auctionType == AuctionType.DUTCH,
      " Treedefi: TREE of this ID is not listed for dutch auction "
      );
     
     require(
      _currentPrice <= _value,
      " Treedefi: Provided value is less than current price "
      );

     require(
      PaymentToken.balanceOf(msg.sender) >= _value,
      " Treedefi : Buyer doesn't have enough balance to purchase token "
     );

     require(
      PaymentToken.allowance(msg.sender, address(this)) >= _value,
      " Treedefi :  Contract is not approved to spend tokens of user "
     );
     
     require(
      msg.sender != _owner,
      " Treedefi : Tree already own by address"
     );

     uint256 _feePercentage = getMarketplaceFee(_id);

     uint256 _fee = _value.mul(_feePercentage).div(1000);
     uint256 _transferValue = _value.sub(_fee);                         
     
     PaymentToken.transferFrom(msg.sender, _owner, _transferValue);
     PaymentToken.transferFrom(msg.sender, _admin, _fee);
             
     NFTREE.transferFrom(_owner, msg.sender, _id);
    
     PaymentType _paymentType = treeList[_id].paymentType;
    
     delete treeList[_id];

     emit Purchase(_owner, msg.sender, _id, _value, _paymentType);
  
  }


  /** @dev returns current price of NFTree listed in dutch auction 
     *@param _id unsigned integer defines tokenID 
     */
  function getCurrentPrice(uint256 _id) public view returns (uint256) {

      require(treeList[_id].startedAt > 0);
      
      uint256 secondsPassed = 0;

      secondsPassed = block.timestamp - treeList[_id].startedAt;

      if (secondsPassed >= treeList[_id].duration) {
          
          return treeList[_id].endPrice;
      
      } else {

          int256 totalPriceChange = int256(treeList[_id].endPrice) - int256(treeList[_id].startPrice);

          int256 currentPriceChange = totalPriceChange * int256(secondsPassed) / int64(treeList[_id].duration);

          int256 currentPrice = int256(treeList[_id].startPrice) + currentPriceChange;

          return uint256(currentPrice);
      
      }
  }


  /** @dev Bid for Treedefi Forest NFT listed in english auction 
     *@param _id unsigned integer defines tokenID 
     *@param _value unsigned integer defines value of TREE/SEED/WBNB tokens  
     */
  function bidOnAuction(uint256 _id, uint256 _value) 
    external
    isManager(_id)
    listed(_id)
  {
     address _owner = NFTREE.ownerOf(_id);    
        
     IBEP20Token PaymentToken = getPaymentInterface(_id);

     uint256 _deadline = uint256(treeList[_id].startedAt)
                        .add(uint256(treeList[_id].duration));

     require(
      treeList[_id].auctionType == AuctionType.ENGLISH,
      " Treedefi: TREE of this ID is not listed for english auction "
      );

     require(
      block.timestamp <= _deadline,
      " Treedefi: auction duration expired "
      );

     uint bidsLength = auctionBids[_id].length;
     uint256 _lastBidPrice = treeList[_id].basePrice;
     Bid memory lastBid; 

      // there are previous bids
        if( bidsLength > 0 ) {
            lastBid = auctionBids[_id][bidsLength - 1];
            _lastBidPrice = lastBid.amount;
        }
     
     require(
      _lastBidPrice < _value,
      " Treedefi: Provided value is less than last bid price or base price "
      );

     require(
      PaymentToken.balanceOf(msg.sender) >= _value,
      " Treedefi : Buyer doesn't have enough balance to purchase token "
     );
     
     // Get require fee to place a bid 
     uint256 _fee = getFeeForBid(_id);
     
     require(
      PaymentToken.allowance(msg.sender, address(this)) >= _value.add(_fee),
      " Treedefi :  Contract is not approved to spend tokens of user "
     );
     
     require(
      msg.sender != _owner,
      " Treedefi : Tree already own by address"
     );
     
     // Transfer fee
     if(_fee > 0){
        PaymentToken.transferFrom(msg.sender, _treasury, _fee.div(2));
        PaymentToken.transferFrom(msg.sender, _donation, _fee.div(2));
     }
     
     // Insert bid 
        Bid memory newBid;
        newBid.from = msg.sender;
        newBid.amount = _value;
        auctionBids[_id].push(newBid);
        PaymentType _paymentType = treeList[_id].paymentType;
        emit BidSuccess(msg.sender, _id, _value, _paymentType);

  }

  /**
    * @dev Accept bid for Treedefi Forest NFT listed in english auction 
    * @dev On success NFTree is transfered to bidder and auction owner gets the amount
    * @param _id uint ID of NFTree
    * @param _bidNumber uint serial number of bid to accept
    */
  function acceptBid(uint256 _id, uint256 _bidNumber) 
    external 
    isManager(_id)
    listed(_id)
  {
    
    address _owner = NFTREE.ownerOf(_id);
     
    IBEP20Token PaymentToken = getPaymentInterface(_id);

    Bid memory bidInfo = auctionBids[_id][_bidNumber.sub(1)];

    require(
      msg.sender == _owner,
      " Treedefi: Only owner of token can accept bid for auction "
    );

    require(
      treeList[_id].auctionType == AuctionType.ENGLISH,
      " Treedefi: TREE of this ID is not listed for english auction "
    );

    require(
      PaymentToken.balanceOf(bidInfo.from) >= bidInfo.amount,
      " Treedefi : Buyer doesn't have enough balance to purchase token "
    );

    require(
      PaymentToken.allowance(bidInfo.from, address(this)) >= bidInfo.amount,
      " Treedefi :  Contract is not approved to spend tokens of Buyer "
    );

    uint256 _feePercentage = getMarketplaceFee(_id);

    uint256 _fee = bidInfo.amount.mul(_feePercentage).div(1000);
    uint256 _transferValue = bidInfo.amount.sub(_fee);                         
     
    PaymentToken.transferFrom(bidInfo.from, _owner, _transferValue);
    PaymentToken.transferFrom(bidInfo.from, _admin, _fee);
             
    NFTREE.transferFrom(_owner, bidInfo.from, _id);
    
    PaymentType _paymentType = treeList[_id].paymentType;

    delete treeList[_id];

    delete auctionBids[_id];                    

    emit Purchase(_owner, bidInfo.from, _id, bidInfo.amount, _paymentType);
        
  }
  
  /** @dev returns bid count of NFTree listed in english auction 
     *@param _id unsigned integer defines tokenID 
     */
  function getBidCount(uint256 _id) external view returns (uint256) {
      return auctionBids[_id].length;
  }      
  
  /**
    * @dev Cancels pending auction by the owner
    * @dev Bidder is refunded with the initial amount
    * @param _id uint ID of NFTree
    */
  function cancelAuction(uint256 _id) 
    external
    listed(_id)
  {
  
      address _owner = NFTREE.ownerOf(_id);
      
      require(
        msg.sender == _owner,
        " Treedefi: Only owner of token can cancel the auction "
      );
      
      if(treeList[_id].auctionType == AuctionType.ENGLISH){ 
        delete auctionBids[_id];
      }
      
      delete treeList[_id];
  
  }


  /** @dev returns payment interface of NFTree listed in auction 
     *@param _id unsigned integer defines tokenID 
     */
  function getPaymentInterface(uint256 _id) internal view returns (IBEP20Token) {
   
    IBEP20Token PaymentToken;

    if(treeList[_id].paymentType == PaymentType.TREE_TOKEN){
      PaymentToken = TREE;
    }else if(treeList[_id].paymentType == PaymentType.SEED_TOKEN){
      PaymentToken = SEED;
    }else if(treeList[_id].paymentType == PaymentType.WBNB_TOKEN){
      PaymentToken = WBNB;
    }

    return PaymentToken;
  
  }
  
  /** @dev returns fee amount for placing a bid in english auction 
     *@param _id unsigned integer defines tokenID 
     */
  function getFeeForBid(uint256 _id) internal view returns (uint256) {
    uint256 _fee;
    
    if(treeList[_id].paymentType == PaymentType.TREE_TOKEN){
      _fee = _bidFee._tree;
    }else if(treeList[_id].paymentType == PaymentType.SEED_TOKEN){
      _fee = _bidFee._seed;
    }else if(treeList[_id].paymentType == PaymentType.WBNB_TOKEN){
      _fee = _bidFee._wbnb;
    }

    return _fee;
  
  }
  
  /** @dev returns fee amount for placing a bid in english auction 
     *@param _id unsigned integer defines tokenID 
     */
  function getMarketplaceFee(uint256 _id) internal view returns (uint256) {
    uint256 _fee;
    
    if(treeList[_id].paymentType == PaymentType.TREE_TOKEN){
      _fee = _marketplaceFee._tree;
    }else if(treeList[_id].paymentType == PaymentType.SEED_TOKEN){
      _fee = _marketplaceFee._seed;
    }else if(treeList[_id].paymentType == PaymentType.WBNB_TOKEN){
      _fee = _marketplaceFee._wbnb;
    }

    return _fee;
  
  }

}