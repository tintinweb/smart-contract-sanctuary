pragma solidity ^0.4.23;

contract P2pep {

  event consumerAddedEvent (address indexed consumerAddress);
  event providerAddedEvent (address indexed providerAddress);
  event startConsumeEvent (address indexed providerAddress, address indexed consumerAddress);
  event stopConsumeEvent (address indexed providerAddress, address indexed consumerAddress);


  address public owner;
  uint constant priceFactor = 2*(10**16);
  modifier restricted() {
    if (msg.sender == owner) _;
  }

  struct Consumer {
    address consumerAddress;
    string consumerName;
    bool exist;
  }

  struct Provider {
    address providerAddress;
    string providerName;
    uint32 totalKilowatts;
    uint32 rating;
    bool exist;
    mapping( address => Consumer ) consumers;
  }

  mapping( address => Consumer ) consumers;
  mapping( address => Provider ) providers;

  constructor() public {
      owner = msg.sender;
  }

  function addConsumer(string _name) public {

    require(!consumers[msg.sender].exist, "allready exist");

    consumers[msg.sender] = Consumer(msg.sender, _name, true);
    emit consumerAddedEvent(msg.sender);
  }

  function addProvider(string _name, uint32 _totalKW, uint32 _rating) public {

    require(!providers[msg.sender].exist);

    providers[msg.sender] = Provider(msg.sender, _name, _totalKW, _rating, true);
    emit providerAddedEvent(msg.sender);
  }

  // this function is called by the consumer
  function startConsume(address _providerAddress) public payable {
    uint purchasedDeal = priceFactor * msg.value;

    require(msg.value >= purchasedDeal, "Hey! Not enough ether!");
    require(providers[_providerAddress].exist);
    require(!providers[_providerAddress].consumers[msg.sender].exist);

    // transfer from the consumer ( the sender ) to the provider
    _providerAddress.transfer(msg.value);
    providers[_providerAddress].consumers[msg.sender] = Consumer(msg.sender, consumers[msg.sender].consumerName, true);

    emit startConsumeEvent(_providerAddress, msg.sender);
  }

    // this function is called by the consumer
  function stopConsume(address _providerAddress) public payable {

    require(providers[_providerAddress].exist);
    require(providers[_providerAddress].consumers[msg.sender].exist);

    // remove the consumer from the provider consuemrs list
    delete providers[_providerAddress].consumers[msg.sender];

    emit stopConsumeEvent(_providerAddress, msg.sender);
  }
}