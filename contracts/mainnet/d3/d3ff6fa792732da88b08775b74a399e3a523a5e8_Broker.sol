pragma solidity ^0.4.7;
contract Broker {
  enum State { Created, Validated, Locked, Inactive }
  State public state;

  enum FileState { 
    Created, 
    Invalidated
    // , Confirmed 
  }

  struct File{
    // The purpose of this file. Like, picture, license info., etc.
    // to save the space, we better use short name.
    // Dapps should match proper long name for this.
    bytes32 purpose;
    // name of the file
    string name;
    // ipfs id for this file
    string ipfshash;
    FileState state;
  }

  struct Item{
    string name;
    // At least 0.1 Finney, because it&#39;s the fee to the developer
    uint   price;
    // this could be a link to an Web page explaining about this item
    string detail;
    File[] documents;
  }

  Item public item;
  address public seller;
  address public buyer;
  address public broker;
  uint    public brokerFee;
  // Minimum 0.1 Finney (0.0001 eth ~ 25Cent) to 0.01% of the price.
  uint    public developerfee = 0.1 finney;
  uint    minimumdeveloperfee = 0.1 finney;
  address developer = 0x001973f023e4c03ef60ea34084b63e7790d463e595;
  // bool public validated;
  address creator = 0x0;


  modifier onlyBuyer() {
    require(msg.sender == buyer);
    _;
  }

  modifier onlySeller() {
    require(msg.sender == seller);
    _;
  }

  modifier onlyCreator() {
    require(msg.sender == creator);
    _;
  }

  modifier onlyBroker() {
    require(msg.sender == broker);
    _;
  }

  modifier inState(State _state) {
      require(state == _state);
      _;
  }

  modifier condition(bool _condition) {
      require(_condition);
      _;
  }

  event Aborted();
  event PurchaseConfirmed();
  event ItemReceived();
  event Validated();

  // The constructor
  function Broker(bool isbroker) {
    if(creator==address(0)){
      //storedData = initialValue;
      if(isbroker)
        broker = msg.sender;
      else
        seller = msg.sender;
      creator = msg.sender;
      // value = msg.value / 2;
      // require((2 * value) == msg.value);
      state = State.Created;

      // validated = false;
      brokerFee = 50;
    }
  }

  function joinAsBuyer(){
    if(buyer==address(0)){
      buyer = msg.sender;
    }
  }

  function joinAsBroker(){
    if(broker==address(0)){
      broker = msg.sender;
    }
  }

  function createOrSet(string name, uint price, string detail)
    inState(State.Created)
    onlyCreator
  {
    require(price > minimumdeveloperfee);
    item.name = name;
    item.price = price;
    item.detail = detail;
    developerfee = (price/1000)<minimumdeveloperfee ? minimumdeveloperfee : (price/1000);
  }

  function getBroker()
    constant returns(address, uint)
  {
    return (broker, brokerFee);
  }

  function getSeller()
    constant returns(address)
  {
    return (seller);
  }

  function setBroker(address _address, uint fee)
  {
    brokerFee = fee;
    broker = _address;
  }

  function setBrokerFee(uint fee)
  {
    brokerFee = fee;
  }

  function setSeller(address _address)
  {
    seller = _address;
  }

  function parseAddr(string _a) internal returns (address){
    bytes memory tmp = bytes(_a);
    uint160 iaddr = 0;
    uint160 b1;
    uint160 b2;
    for (uint i=2; i<2+2*20; i+=2){
        iaddr *= 256;
        b1 = uint160(tmp[i]);
        b2 = uint160(tmp[i+1]);
        if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
        else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
        if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
        else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
        iaddr += (b1*16+b2);
    }
    return address(iaddr);
  }

  // We will have some &#39;peculiar&#39; list of documents
  // for each deals. 
  // For ex, for House we will require
  // proof of documents about the basic information of the House,
  // and some insurance information.
  // So we can make a template for each differene kind of deals.
  // Deals for a house, deals for a Car, etc.
  function addDocument(bytes32 _purpose, string _name, string _ipfshash)
  {
    require(state != State.Inactive);
    require(state != State.Locked);
    item.documents.push( File({
      purpose:_purpose, name:_name, ipfshash:_ipfshash, state:FileState.Created}
      ) 
    );
  }

  // deleting actual file on the IPFS network is very hard.
  function deleteDocument(uint index)
  {
    require(state != State.Inactive);
    require(state != State.Locked);
    if(index<item.documents.length){
      item.documents[index].state = FileState.Invalidated;
    }
  }

  function validate()
    onlyBroker
    inState(State.Created)
  {
    // if(index<item.documents.length){
    //   item.documents[index].state = FileState.Confirmed;
    // }
    Validated();
    // validated = true;
    state = State.Validated;
  }

  /// Abort the purchase and reclaim the ether.
  /// Can only be called by the seller before
  /// the contract is locked.
  function abort()
      onlySeller
      inState(State.Created)
  {
      Aborted();
      state = State.Inactive;
      // validated = false;
      seller.transfer(this.balance);
  }

  function abortByBroker()
      onlyBroker
  {
      require(state != State.Inactive);
      state = State.Inactive;
      Aborted();
      buyer.transfer(this.balance);
  }

  /// Confirm the purchase as buyer.
  /// The ether will be locked until confirmReceived
  /// is called.
  function confirmPurchase()
      inState(State.Validated)
      condition(msg.value == item.price)
      payable
  {
      state = State.Locked;
      buyer = msg.sender;
      PurchaseConfirmed();
  }

  /// Confirm that you (the buyer) received the item.
  /// This will release the locked ether.
  function confirmReceived()
      onlyBroker
      inState(State.Locked)
  {
      // It is important to change the state first because
      // otherwise, the contracts called using `send` below
      // can call in again here.
      state = State.Inactive;

      // NOTE: This actually allows both the buyer and the seller to
      // block the refund - the withdraw pattern should be used.
      seller.transfer(this.balance-brokerFee-developerfee);
      broker.transfer(brokerFee);
      developer.transfer(developerfee);

      ItemReceived();
  }

  function getInfo() constant returns (State, string, uint, string, uint, uint){
    return (state, item.name, item.price, item.detail, item.documents.length, developerfee);
  }

  function getFileAt(uint index) constant returns(uint, bytes32, string, string, FileState){
    return (index,
      item.documents[index].purpose,
      item.documents[index].name,
      item.documents[index].ipfshash,
      item.documents[index].state);
  }
}