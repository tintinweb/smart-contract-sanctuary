pragma solidity ^0.4.24;

contract GeoEscrow {
  //state variables
  uint storedData;
  address owner; //owner of contract
  mapping (address => uint) private deposit_accounts; //list of organizations depositing
  mapping (uint => Purchase) private purchase_registry;
  struct Purchase {
    uint amount;
    address purchaser;
    bool approved;
    address seller;
    string mtcn;
  }
  uint purchase_requests; //number of purchase requests

  //constructor setting contract owner
  constructor () public {
    owner = msg.sender;
    purchase_requests = 0;
  }

  //modifiers
  modifier isOwner (address _owner) { require(_owner == owner); _;} //checking owner
  //checking if org on deposit list
  modifier isDepositer (address _depositer) { require(deposit_accounts[_depositer] > 0); _;}

  //events
  event Deposit(address _depositer); //event for deposits
  event Withdraw(address _depositer); //event for withdraws from depositer
  event Purchased(address _purchaser); //event for conversion agents to purchase eth/geo
  event Authenticate(address _depositer); //event for depositer to authenticate purchases of eth/geo

  //functions
  function deposit() public payable returns (uint) {
    //depositing funds into escrow account
    require(msg.value > 0);
    deposit_accounts[msg.sender] += msg.value;
    address(this).transfer(msg.value);
    emit Deposit(msg.sender);
    return deposit_accounts[msg.sender];
  }

  function withdraw(uint amount) public isDepositer(msg.sender) returns (bool) {
    //withdrawing funds from escrow account
    if (amount <= deposit_accounts[msg.sender]) {
      deposit_accounts[msg.sender] -= amount;
      msg.sender.transfer(amount);
      emit Withdraw(msg.sender);
      return true;
    } else {
      return false;
    }
  }

  function getBalance() public view isDepositer(msg.sender) returns (uint) {
    //get balance of amount in escrow pool
    return deposit_accounts[msg.sender];
  }

  function getMyBalance() public view isOwner(msg.sender) returns (uint) {
    return address(this).balance;
  }

  function getPurchaseRequests() public view isDepositer(msg.sender) returns (uint) {
    return purchase_requests;
  }

  /*
  function getPurchases() constant public
  isDepositer(msg.sender) {
    //retrieves un-approved purchase requests
    Purchased(msg.sender);
  }
  */

  function makePurchase(uint amount, address seller, string mtcn) public returns (bool) {
    //send purchase request for eth
    if (seller != msg.sender) {
      purchase_requests += 1; //increment the request number overall
      purchase_registry[purchase_requests].amount = amount; //capture requested amount to be purchased
      purchase_registry[purchase_requests].seller = seller; //capture who they are trying to purchase
      purchase_registry[purchase_requests].purchaser = msg.sender;
      purchase_registry[purchase_requests].mtcn = mtcn; //put in Western Union MTCN number to be auth
      purchase_registry[purchase_requests].approved = false; //approval status or not
      return true;
    } else {
      return false;
    }
  }

  function authenticate(uint index) public returns (bool) {
    if (index <= purchase_requests && index > 0) {
      purchase_registry[index].approved = true;
      emit Authenticate(msg.sender);
      return true;
    } else {
      return false;
    }
  }

  function set(uint x) public {
    storedData = x;
  }

  function get() public view returns (uint) {
    return storedData;
  }

  //fallback function
  function () public payable {}
}