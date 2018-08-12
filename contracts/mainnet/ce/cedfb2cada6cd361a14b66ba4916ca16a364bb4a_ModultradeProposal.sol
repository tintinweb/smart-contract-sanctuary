pragma solidity ^0.4.18;

// File: contracts/ERC20.sol

/*
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint public totalSupply;

  function balanceOf(address who) public constant returns (uint);

  function allowance(address owner, address spender) public constant returns (uint);

  function transfer(address to, uint value) public returns (bool ok);

  function transferFrom(address from, address to, uint value) public returns (bool ok);

  function approve(address spender, uint value) public returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint value);

  event Approval(address indexed owner, address indexed spender, uint value);
}

// ERC223
contract ContractReceiver {
  function tokenFallback(address from, uint value) public;
}

// File: contracts/Ownable.sol

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {

  address public owner;

  function Ownable() public { owner = msg.sender; }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {

    if (newOwner != address(0)) {
      owner = newOwner;
    }

  }
}

// File: contracts/Deployer.sol

contract Deployer {

  address public deployer;

  function Deployer() public { deployer = msg.sender; }

  modifier onlyDeployer() {
    require(msg.sender == deployer);
    _;
  }
}

// File: contracts/OracleOwnable.sol

contract OracleOwnable is Ownable {

  address public oracle;

  modifier onlyOracle() {
    require(msg.sender == oracle);
    _;
  }

  modifier onlyOracleOrOwner() {
    require(msg.sender == oracle || msg.sender == owner);
    _;
  }

  function setOracle(address newOracle) public onlyOracleOrOwner {
    if (newOracle != address(0)) {
      oracle = newOracle;
    }

  }

}

// File: contracts/ModultradeLibrary.sol

library ModultradeLibrary {
  enum Currencies {
  ETH, MTR
  }

  enum ProposalStates {
  Created, Paid, Delivery, Closed, Canceled
  }
}

// File: contracts/ModultradeStorage.sol

contract ModultradeStorage is Ownable, Deployer {

  bool private _doMigrate = true;

  mapping (address => address[]) public sellerProposals;

  mapping (uint => address) public proposalListAddress;

  address[] public proposals;

  event InsertProposalEvent (address _proposal, uint _id, address _seller);

  event PaidProposalEvent (address _proposal, uint _id);

  function ModultradeStorage() public {}

  function insertProposal(address seller, uint id, address proposal) public onlyOwner {
    sellerProposals[seller].push(proposal);
    proposalListAddress[id] = proposal;
    proposals.push(proposal);

    InsertProposalEvent(proposal, id, seller);
  }

  function getProposalsBySeller(address seller) public constant returns (address[]){
    return sellerProposals[seller];
  }

  function getProposals() public constant returns (address[]){
    return proposals;
  }

  function getProposalById(uint id) public constant returns (address){
    return proposalListAddress[id];
  }

  function getCount() public constant returns (uint) {
    return proposals.length;
  }

  function getCountBySeller(address seller) public constant returns (uint) {
    return sellerProposals[seller].length;
  }

  function firePaidProposalEvent(address proposal, uint id) public {
    require(proposalListAddress[id] == proposal);

    PaidProposalEvent(proposal, id);
  }

  function changeOwner(address newOwner) public onlyDeployer {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

// File: contracts/ModultradeProposal.sol

contract ModultradeProposal is OracleOwnable, ContractReceiver {

  address public seller;

  address public buyer;

  uint public id;

  string public title;

  uint public price;

  ModultradeLibrary.Currencies public currency;

  uint public units;

  uint public total;

  uint public validUntil;

  ModultradeLibrary.ProposalStates public state;

  uint public payDate;

  string public deliveryId;

  uint public fee;

  address public feeAddress;

  ERC20 mtrContract;

  Modultrade modultrade;

  bytes public tokenFallbackData;

  event CreatedEvent(uint _id, ModultradeLibrary.ProposalStates _state);

  event PaidEvent(uint _id, ModultradeLibrary.ProposalStates _state, address _buyer);

  event DeliveryEvent(uint _id, ModultradeLibrary.ProposalStates _state, string _deliveryId);

  event ClosedEvent(uint _id, ModultradeLibrary.ProposalStates _state, address _seller, uint _amount);

  event CanceledEvent(uint _id, ModultradeLibrary.ProposalStates _state, address _buyer, uint _amount);

  function ModultradeProposal(address _modultrade, address _seller, address _mtrContractAddress) public {
    seller = _seller;
    state = ModultradeLibrary.ProposalStates.Created;
    mtrContract = ERC20(_mtrContractAddress);
    modultrade = Modultrade(_modultrade);
  }

  function setProposal(uint _id,
  string _title,
  uint _price,
  ModultradeLibrary.Currencies _currency,
  uint _units,
  uint _total,
  uint _validUntil
  ) public onlyOracleOrOwner {
    require(state == ModultradeLibrary.ProposalStates.Created);
    id = _id;
    title = _title;
    price = _price;
    currency = _currency;
    units = _units;
    total = _total;
    validUntil = _validUntil;
  }

  function setFee(uint _fee, address _feeAddress) public onlyOracleOrOwner {
    require(state == ModultradeLibrary.ProposalStates.Created);
    fee = _fee;
    feeAddress = _feeAddress;
  }

  function() public payable {purchase();}

  function purchase() public payable {
    require(currency == ModultradeLibrary.Currencies.ETH);
    require(msg.value >= total);
    setPaid(msg.sender);
  }

  function setPaid(address _buyer) internal {
    require(state == ModultradeLibrary.ProposalStates.Created);
    state = ModultradeLibrary.ProposalStates.Paid;
    buyer = _buyer;
    payDate = now;
    PaidEvent(id, state, buyer);
    modultrade.firePaidProposalEvent(address(this), id);
  }

  function paid(address _buyer) public onlyOracleOrOwner {
    require(getBalance() >= total);
    setPaid(_buyer);
  }

  function mtrTokenFallBack(address from, uint value) internal {
    require(currency == ModultradeLibrary.Currencies.MTR);
    require(msg.sender == address(mtrContract));
    require(value >= total);
    setPaid(from);
  }

  function tokenFallback(address from, uint value) public {
    mtrTokenFallBack(from, value);
  }

  function tokenFallback(address from, uint value, bytes data) public {
    tokenFallbackData = data;
    mtrTokenFallBack(from, value);
  }

  function delivery(string _deliveryId) public onlyOracleOrOwner {
    require(state == ModultradeLibrary.ProposalStates.Paid);
    deliveryId = _deliveryId;
    state = ModultradeLibrary.ProposalStates.Delivery;
    DeliveryEvent(id, state, deliveryId);
    modultrade.fireDeliveryProposalEvent(address(this), id);
  }

  function close() public onlyOracleOrOwner {
    require(state != ModultradeLibrary.ProposalStates.Closed);
    require(state != ModultradeLibrary.ProposalStates.Canceled);

    if (currency == ModultradeLibrary.Currencies.ETH) {
      closeEth();
    }
    if (currency == ModultradeLibrary.Currencies.MTR) {
      closeMtr();
    }

    state = ModultradeLibrary.ProposalStates.Closed;
    ClosedEvent(id, state, seller, this.balance);
    modultrade.fireCloseProposalEvent(address(this), id);
  }

  function closeEth() private {
    if (fee > 0) {
      feeAddress.transfer(fee);
    }
    seller.transfer(this.balance);
  }

  function closeMtr() private {
    if (fee > 0) {
      mtrContract.transfer(feeAddress, fee);
    }
    mtrContract.transfer(seller, getBalance());
  }

  function cancel(uint cancelFee) public onlyOracleOrOwner {
    require(state != ModultradeLibrary.ProposalStates.Closed);
    require(state != ModultradeLibrary.ProposalStates.Canceled);
    uint _balance = getBalance();
    if (_balance > 0) {
      if (currency == ModultradeLibrary.Currencies.ETH) {
        cancelEth(cancelFee);
      }
      if (currency == ModultradeLibrary.Currencies.MTR) {
        cancelMtr(cancelFee);
      }
    }
    state = ModultradeLibrary.ProposalStates.Canceled;
    CanceledEvent(id, state, buyer, this.balance);
    modultrade.fireCancelProposalEvent(address(this), id);
  }

  function cancelEth(uint cancelFee) private {
    uint _fee = cancelFee;
    if (cancelFee > this.balance) {
      _fee = this.balance;
    }
    feeAddress.transfer(_fee);
    if (this.balance > 0 && buyer != address(0)) {
      buyer.transfer(this.balance);
    }
  }

  function cancelMtr(uint cancelFee) private {
    uint _fee = cancelFee;
    uint _balance = getBalance();
    if (cancelFee > _balance) {
      _fee = _balance;
    }
    mtrContract.transfer(feeAddress, _fee);
    _balance = getBalance();
    if (_balance > 0 && buyer != address(0)) {
      mtrContract.transfer(buyer, _balance);
    }
  }

  function getBalance() public constant returns (uint) {
    if (currency == ModultradeLibrary.Currencies.MTR) {
      return mtrContract.balanceOf(address(this));
    }

    return this.balance;
  }
}

// File: contracts/Modultrade.sol

contract Modultrade is OracleOwnable, Deployer {

  address public mtrContractAddress;

  ModultradeStorage public modultradeStorage;

  event ProposalCreatedEvent(uint _id, address _proposal);

  event PaidProposalEvent (address _proposal, uint _id);
  event CancelProposalEvent (address _proposal, uint _id);
  event CloseProposalEvent (address _proposal, uint _id);
  event DeliveryProposalEvent (address _proposal, uint _id);

  event LogEvent (address _addr, string _log, uint _i);

  function Modultrade(address _owner, address _oracle, address _mtrContractAddress, address _storageAddress) public {
    transferOwnership(_owner);
    setOracle(_oracle);
    mtrContractAddress = _mtrContractAddress;
    modultradeStorage = ModultradeStorage(_storageAddress);
  }

  function createProposal(
  address seller,
  uint id,
  string title,
  uint price,
  ModultradeLibrary.Currencies currency,
  uint units,
  uint total,
  uint validUntil,
  uint fee,
  address feeAddress
  ) public onlyOracleOrOwner {
    ModultradeProposal proposal = new ModultradeProposal(address(this), seller, mtrContractAddress);
    LogEvent (address(proposal), &#39;ModultradeProposal&#39;, 1);
    proposal.setProposal(id, title, price, currency, units, total, validUntil);
    proposal.setFee(fee, feeAddress);
    proposal.setOracle(oracle);
    proposal.transferOwnership(owner);

    modultradeStorage.insertProposal(seller, id, address(proposal));
    ProposalCreatedEvent(proposal.id(), address(proposal));
  }


  function transferStorage(address _owner) public onlyOracleOrOwner {
    modultradeStorage.transferOwnership(_owner);
  }

  function firePaidProposalEvent(address proposal, uint id) public {
    var _proposal = modultradeStorage.getProposalById(id);
    require(_proposal == proposal);
    PaidProposalEvent(proposal, id);
  }

  function fireCancelProposalEvent(address proposal, uint id) public {
    var _proposal = modultradeStorage.getProposalById(id);
    require(_proposal == proposal);
    CancelProposalEvent(proposal, id);
  }

  function fireCloseProposalEvent(address proposal, uint id) public {
    var _proposal = modultradeStorage.getProposalById(id);
    require(_proposal == proposal);
    CloseProposalEvent(proposal, id);
  }

  function fireDeliveryProposalEvent(address proposal, uint id) public {
    var _proposal = modultradeStorage.getProposalById(id);
    require(_proposal == proposal);
    DeliveryProposalEvent(proposal, id);
  }

}