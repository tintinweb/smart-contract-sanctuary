pragma solidity ^0.4.24;

contract Market {

  event OfferAdded(uint indexed id, string product, uint price);
  event OfferChanged(uint indexed id, Status status, address taker, address arbiter);
  event Whitelisted(address indexed addr, bool value);

  enum Status { OFFERED, TAKEN, CONFIRMED, ABORTED }

  struct Offer {
    string product;
    uint price;
    Status status;
    address creator;
    address taker;
    address arbiter;
  }

  address public owner;
  mapping (address => bool) public whitelisted;
  Offer[] public offers;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted {
    require(whitelisted[msg.sender], "only whitelisted parties can do that");
    _;
  }

  modifier inState(uint id, Status expected) {
    require(offers[id].status == expected, "offer not in expected state");
    _;
  }

  function setWhitelisted(address addr, bool value)
  public {
    require(msg.sender == owner, "only owner can whitelist");
    whitelisted[addr] = value;
    emit Whitelisted(addr, value);
  }

  function addOffer(string product, uint price, address arbiter)
  restricted public returns (uint) {
    require(whitelisted[arbiter], "arbiter has to be whitelisted");
    uint id = offers.length;
    offers.push(Offer({
      product: product,
      price: price,
      arbiter: arbiter,
      status: Status.OFFERED,
      creator: msg.sender,
      taker: 0
    }));
    emit OfferAdded(id, product, price);
    emit OfferChanged(id, Status.OFFERED, 0, arbiter);
    return id;
  }

  function setArbiter(uint id, address arbiter)
  inState(id, Status.OFFERED)
  public {
    Offer storage offer = offers[id];
    require(msg.sender == offer.creator, "only creator can change arbiters");
    require(whitelisted[arbiter], "arbiters have to be whitelisted");
    offer.arbiter = arbiter;
    emit OfferChanged(id, Status.OFFERED, offer.taker, arbiter);
  }

  function setOfferStatus(uint id, Status status) internal {
    Offer storage offer = offers[id];
    offer.status = status;
    emit OfferChanged(id, offer.status, offer.taker, offer.arbiter);
  }

  function takeOffer(uint id, address arbiter)
  inState(id, Status.OFFERED)
  restricted public
  payable {
    Offer storage offer = offers[id];
    require(msg.sender != offer.creator, "taker cannot be creator");
    require(msg.value == offer.price, "price does not match");
    require(arbiter == offer.arbiter, "unexpected arbiter");

    offer.taker = msg.sender;
    setOfferStatus(id, Status.TAKEN);
  }

  function finalize(uint id) internal {
    Offer storage offer = offers[id];
    offer.creator.transfer(offer.price);
    setOfferStatus(id, Status.CONFIRMED);
  }

  function confirmOffer(uint id)
  inState(id, Status.TAKEN)
  public {
    require(msg.sender == offers[id].taker, "only taker can confirm");
    finalize(id);
  }

  function resolveOffer(uint id, bool delivered, bool burn)
  inState(id, Status.TAKEN)
  public {
    Offer storage offer = offers[id];
    require(msg.sender == offer.arbiter, "only arbiter can resolve");

    if(delivered) {
      finalize(id);
    } else {
      offer.taker.transfer(offer.price);
      setOfferStatus(id, Status.ABORTED);
    }
  }

}