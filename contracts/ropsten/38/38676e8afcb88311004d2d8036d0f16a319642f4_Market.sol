pragma solidity ^0.4.24;

contract Market {

  event OfferAdded(uint indexed id, string product, uint price);
  event OfferChanged(uint indexed id, Status status);
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

  function setWhitelisted(address addr, bool value)
  public {
    require(msg.sender == owner, "only owner can whitelist");
    whitelisted[addr] = value;
    emit Whitelisted(addr, value);
  }

  modifier restricted {
    require(whitelisted[msg.sender], "not whitelisted");
    _;
  }

  modifier inState(uint id, Status status) {
    require(offers[id].status == status, "offer in wrong state");
    _;
  }

  function addOffer(string product, uint price, address arbiter)
  restricted public returns (uint) {
    uint id = offers.length;
    offers.push(Offer({
        product: product,
        price: price,
        status: Status.OFFERED,
        creator: msg.sender,
        taker: 0,
        arbiter: arbiter
    }));
    require(whitelisted[arbiter], "arbiter not whitelisted");
    emit OfferAdded(id, product, price);
    emit OfferChanged(id, Status.OFFERED);
    return id;
  }

  function setArbiter(uint id, address arbiter)
  inState(id, Status.OFFERED)
  public {
    Offer storage offer = offers[id];
    require(msg.sender == offer.creator, "sender is not the creator");
    require(whitelisted[arbiter], "arbiter not whitelisted");
    offer.arbiter = arbiter;
  }

  function setOfferState(uint id, Status status) internal {
    offers[id].status = status;
    emit OfferChanged(id, status);
  }

  function takeOffer(uint id, address arbiter)
  inState(id, Status.OFFERED) public
  restricted payable {
    Offer storage offer = offers[id];

    require(msg.value == offer.price, "value does not match price");
    require(offer.arbiter == arbiter, "unexpected arbiter");
    require(offer.creator != msg.sender, "creator cannot be taker");

    offer.taker = msg.sender;
    setOfferState(id, Status.TAKEN);
  }

  function finalize(uint id) internal {
    Offer storage offer = offers[id];
    offer.creator.transfer(offer.price);
    setOfferState(id, Status.CONFIRMED);
  }

  function confirmOffer(uint id)
  inState(id, Status.TAKEN) public {
    require(offers[id].taker == msg.sender, "only taker can confirm");
    finalize(id);
  }

  function resolveOffer(uint id, bool delivered, bool burn)
  inState(id, Status.TAKEN) restricted public {
    Offer storage offer = offers[id];
    require(offer.arbiter == msg.sender, "only arbiter can resolve");

    if(delivered) {
      finalize(id);
    } else {
      offer.taker.transfer(offer.price);
      setOfferState(id, Status.ABORTED);
    }
  }

}