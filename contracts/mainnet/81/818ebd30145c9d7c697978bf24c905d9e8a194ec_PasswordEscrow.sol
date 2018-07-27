pragma solidity 0.4.23;

contract PasswordEscrow {
  address public owner;
  uint256 public commissionFee;
  uint256 public totalFee;

  //data
  struct Transfer {
    address from;
    uint256 amount;
  }

  mapping(bytes32 => Transfer) private transferToPassword;

  mapping(address => uint256) private indexToAddress;
  mapping(address => mapping(uint256 => bytes32)) private passwordToAddress;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier passwordOwner(bytes32 _byte) {
    require(
      transferToPassword[_byte].from == msg.sender &&
      transferToPassword[_byte].amount > 0
    );
    _;
  }

  event LogChangeCommissionFee(uint256 fee);
  event LogChangeOwner(address indexed exOwner, address indexed newOwner);
  event LogDeposit(address indexed from, uint256 amount);
  event LogGetTransfer(address indexed from, address indexed recipient, uint256 amount);
  event LogEmergency(address indexed from, uint256 amount);



  constructor(uint256 _fee) public {
    commissionFee = _fee;
    owner = msg.sender;
  }

  function changeCommissionFee(uint256 _fee) public onlyOwner {
    commissionFee = _fee;

    emit LogChangeCommissionFee(_fee);
  }

  function changeOwner(address _newOwner) public onlyOwner {
    address exOwner = owner;
    owner = _newOwner;

    emit LogChangeOwner(exOwner, _newOwner);
  }


  //simple transfer
  function deposit(bytes32 _password) public payable {
    require(
      msg.value > commissionFee &&
      transferToPassword[sha3(_password)].amount == 0
    );

    bytes32 pass = sha3(_password);
    transferToPassword[pass] = Transfer(msg.sender, msg.value);

    uint256 index = indexToAddress[msg.sender];

    indexToAddress[msg.sender]++;
    passwordToAddress[msg.sender][index] = pass;

    emit LogDeposit(msg.sender, msg.value);
  }

  function getTransfer(bytes32 _password) public payable {
    require(
      transferToPassword[sha3(_password)].amount > 0
    );

    bytes32 pass = sha3(_password);
    address from = transferToPassword[pass].from;
    uint256 amount = transferToPassword[pass].amount - commissionFee;
    totalFee += commissionFee;

    transferToPassword[pass].amount = 0;

    msg.sender.transfer(amount);

    emit LogGetTransfer(from, msg.sender, amount);
  }



  //advanced transfer
  function AdvancedDeposit(bytes32 _password, bytes32 _num) public payable {
    require(
      msg.value >= commissionFee &&
      transferToPassword[sha3(_password, _num)].amount == 0
    );

    bytes32 pass = sha3(_password, _num);
    transferToPassword[pass] = Transfer(msg.sender, msg.value);

    uint256 index = indexToAddress[msg.sender];

    indexToAddress[msg.sender]++;
    passwordToAddress[msg.sender][index] = pass;


    emit LogDeposit(msg.sender, msg.value);
  }

  function getAdvancedTransfer(bytes32 _password, bytes32 _num) public payable {
    require(
      transferToPassword[sha3(_password, _num)].amount > 0
    );

    bytes32 pass = sha3(_password, _num);
    address from = transferToPassword[pass].from;
    uint256 amount = transferToPassword[pass].amount - commissionFee;
    totalFee += commissionFee;

    transferToPassword[pass].amount = 0;

    msg.sender.transfer(amount);

    emit LogGetTransfer(from, msg.sender, amount);
  }

  function viewIndexNumber() public view returns(uint256) {
    return indexToAddress[msg.sender];
  }

  function viewPassword(uint256 _index) public view returns(bytes32, uint256) {
    bytes32 hash = passwordToAddress[msg.sender][_index];
    uint256 value = transferToPassword[hash].amount;

    return (hash, value);
  }

  function emergency(bytes32 _byte) public payable passwordOwner(_byte) {

    uint256 amount = transferToPassword[_byte].amount - commissionFee * 2;
    totalFee += commissionFee * 2;
    transferToPassword[_byte].amount = 0;

    msg.sender.transfer(amount);

    emit LogEmergency(msg.sender, amount);
  }

  function withdrawFee() public payable onlyOwner {
    require( totalFee > 0);

    uint256 fee = totalFee;
    totalFee = 0;

    msg.sender.transfer(totalFee);
  }

  function withdraw() public payable onlyOwner {
    msg.sender.transfer(this.balance);
  }


}