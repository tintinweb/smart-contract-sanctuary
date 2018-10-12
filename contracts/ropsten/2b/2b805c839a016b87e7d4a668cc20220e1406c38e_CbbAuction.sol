pragma solidity ^0.4.25;

interface BasicToken {
  function transfer(address receiver, uint amount) external;

  function allowance(address owner, address spender) external view returns (uint256);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  function balanceOf(address tokenOwner) external view returns (uint balance);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner(), "Only owner.");
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Pausable is Ownable {
  event Paused();
  event Unpaused();

  bool private _paused = false;

  /**
   * @return true if the contract is paused, false otherwise.
   */
  function paused() public view returns(bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(_paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    _paused = true;
    emit Paused();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    _paused = false;
    emit Unpaused();
  }
}

contract CbbAuction is Ownable, Pausable {
  uint internal numAuctions;
  uint8 public auctionRate = 8; //
  mapping(uint => Auction) internal auctions;
  mapping(uint => BidInfo) internal auctionBids;

  struct Auction {
    address token;
    uint quantity;
    uint endAt;
    uint startPrice;
    address creator;
    bool ended;
  }

  struct BidInfo {
    mapping(address => uint) addressBids;
    uint highestPrice;
    address winner;
    address[] addresses;
  }

  event AuctionCreated(uint id, address token, uint quantity, uint endAt, uint startPrice, address creator);
  event AuctionEnded(uint id);
  event AuctionBided(uint id, address bidder, uint price, uint highestPrice, address winner);
  event Withdrawal(uint quantity);

  modifier validAuctoinId(uint id) {
    require(auctions[id].creator != address(0), "Id not found.");

    _;
  }

  constructor() public {
    numAuctions = 0;
  }

  function createAuction(address token, uint quantity, uint endAt, uint startPrice) public whenNotPaused returns (bool success) {
    require(quantity > 0, "Quantity must greater than 0.");
    require(endAt >= (now + 1 days), "EndAt must greater than now + 1 day.");
    require(startPrice > 0, "StartPrice must greater than 0.");

    BasicToken tokenReward = BasicToken(token);

    //检查是否有足够的授权
    uint allowance = tokenReward.allowance(msg.sender, address(this));
    if (allowance < quantity) {
      revert("Balance of token not enough.");
    }
    //转移token转到合约里
    tokenReward.transferFrom(msg.sender, address(this), quantity);

    uint auctionId = numAuctions++;
    auctions[auctionId] = Auction(token, quantity, endAt, startPrice, msg.sender, false);

    emit AuctionCreated(auctionId, token, quantity, endAt, startPrice, msg.sender);

    return true;
  }

  function auctionOf(uint auctionId) public validAuctoinId(auctionId) view returns (
    address token,
    uint quantity,
    uint endAt,
    uint startPrice,
    address creator,
    bool ended,
    uint highestPrice,
    address winner
  ) {
    Auction storage auction = auctions[auctionId];
    BidInfo storage bidInfo = auctionBids[auctionId];

    token = auction.token;
    quantity = auction.quantity;
    endAt = auction.endAt;
    startPrice = auction.startPrice;
    creator = auction.creator;
    ended = auction.ended;
    highestPrice = bidInfo.highestPrice;
    winner = bidInfo.winner;
  }

  function bid(uint auctionId) public payable validAuctoinId(auctionId) whenNotPaused returns (bool success) {
    Auction storage auction = auctions[auctionId];

    require(auction.ended == false, "Already ended.");
    require(auction.endAt > now, "Already ended.");
    require(msg.value > 0, "Must send ether.");

    BidInfo storage bidInfo = auctionBids[auctionId];

    require(bidInfo.addressBids[msg.sender] + msg.value > auction.startPrice, "Must greater startPrice price");
    require(bidInfo.addressBids[msg.sender] + msg.value > bidInfo.highestPrice, "Must greater hightest price");

    if (bidInfo.addressBids[msg.sender] == 0) {
      bidInfo.addresses.push(msg.sender);
    }

    bidInfo.addressBids[msg.sender] += msg.value;

    uint price = bidInfo.addressBids[msg.sender];
    if (price > bidInfo.highestPrice) {
      bidInfo.highestPrice = price;
      bidInfo.winner = msg.sender;
    }

    emit AuctionBided(auctionId, msg.sender, price, bidInfo.highestPrice, bidInfo.winner);

    return true;
  }

  function end(uint auctionId) public validAuctoinId(auctionId) whenNotPaused returns (bool success) {
    require(auctions[auctionId].ended == false, "Already ended.");

    Auction storage auction = auctions[auctionId];
    BidInfo storage bidInfo = auctionBids[auctionId];
    BasicToken token = BasicToken(auction.token);

    if (bidInfo.winner != address(0)) {
      auction.creator.transfer(bidInfo.highestPrice * (100 - auctionRate) / 100);

      for (uint i = 0; i < bidInfo.addresses.length; i++) {
        address bidder = bidInfo.addresses[i];

        if (bidder != bidInfo.winner) {
          bidder.transfer(bidInfo.addressBids[bidder]);
        }
      }

      //Send tokens to winner
      token.transfer(bidInfo.winner, auction.quantity);

    } else {
      //back token to creator
      token.transfer(auction.creator, auction.quantity);

    }

    auction.ended = true;

    emit AuctionEnded(auctionId);

    return true;
  }

  function withdrawal(uint quantity) public onlyOwner returns (bool success) {
    owner().transfer(quantity);

    emit Withdrawal(quantity);

    return true;
  }

  function changeRate(uint8 _rate) public onlyOwner {
    auctionRate = _rate;
  }
}