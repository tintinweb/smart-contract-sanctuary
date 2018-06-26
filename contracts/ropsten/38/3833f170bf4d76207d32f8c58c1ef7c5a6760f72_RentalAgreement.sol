pragma solidity ^0.4.23;


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface token {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _address) external returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function owner() external returns (address);
  function totalAllowance(address user, address spender) external returns (bool);
}

interface notifier {
  function deposit(address user, uint amount) external;
  function withdraw(address user, uint amount) external;
  function rentModified(uint256 amount) external;
  function ticket(bool ticketOpen) external;
  function approved(address user) external;
  function dispute(bool ongGoing) external;
}


contract RentalAgreement {
  using SafeMath for uint256;

  token public EthRental;
  notifier public Notifier;
  address public admin;
  address public landlord;
  address public tenant;
  uint256 public rent;
  bool public agreementAproved;
  uint256 public escrowAmount;
  uint256 public withdrawableAmount;
  bool public ticketOpen;
  bool public onGoingDispute;

  event Approved(address user);
  event Deposit(address user, uint amount);
  event Withdraw(address user, uint amount);
  event RentModified(uint256 amount);
  event Ticket(bool open);
  event Dispute(bool ongGoing);

  function RentalAgreement() public {
    EthRental = token(0x3DdCB3df872c7663d58db958b06fc82E19B49945); //token address
    Notifier = notifier(0x4232a7F252d92634841c21a029926eFAB58551d5);
    admin = EthRental.owner();
    landlord = msg.sender;
    tenant = 0x0Ec793B3F6ECf6FC2D371F7e2000337A1CB47dA6; //tenant address
    rent = 30000000000000000; //rent amount
  }

  //Tenant approves this this agreement
  function approveAgreement() public {
    require(msg.sender == tenant);
    require(!agreementAproved);
    require(EthRental.totalAllowance(tenant, this));
    agreementAproved = true;
    Notifier.approved(tenant);
    emit Approved(tenant);
  }

  //Tenant deposits the rent manually
  function deposit(uint amount) public {
    require(EthRental.transferFrom(msg.sender, this, amount));
    if(ticketOpen){
      escrowAmount = escrowAmount.add(amount);
    }else{
      withdrawableAmount = withdrawableAmount.add(amount);
    }
    Notifier.deposit(msg.sender, amount);
    emit Deposit(msg.sender, amount);
  }

  //The rent is deposited in tenant&#39;s behalf
  function depositFrom(uint amount) public {
    require(msg.sender == admin);
    require(EthRental.transferFrom(tenant, this, amount));
    if(ticketOpen){
      escrowAmount = escrowAmount.add(amount);
    }else{
      withdrawableAmount = withdrawableAmount.add(amount);
    }
    Notifier.deposit(msg.sender, amount);
    emit Deposit(tenant, amount);
  }

  //Withdraw the money paid
  function withdraw() public {
    require(msg.sender == landlord);
    uint256 amount = withdrawableAmount;
    withdrawableAmount = 0;
    require(EthRental.transfer(landlord, amount));
    Notifier.withdraw(landlord, amount);
    emit Withdraw(landlord, amount);
  }

  //Increase/Decrease the rent
  function modifyRent(uint newRent) public {
    require(msg.sender == landlord);
    rent = newRent;
    Notifier.rentModified(rent);
    emit RentModified(rent);
  }

  //Open a ticket
  function openTicket() public {
    require(msg.sender == tenant);
    require(!ticketOpen);
    ticketOpen = true;
    Notifier.ticket(ticketOpen);
    emit Ticket(ticketOpen);

  }

  //Close the ticket
  function closeTicket() public {
    require(msg.sender == tenant || msg.sender == admin);
    require(ticketOpen);
    ticketOpen = false;
    uint256 amount = escrowAmount;
    escrowAmount = 0;
    withdrawableAmount = withdrawableAmount.add(amount);
    Notifier.ticket(ticketOpen);
    emit Ticket(ticketOpen);
  }

  function startDispute() public {
    require(msg.sender == admin || msg.sender == landlord);
    require(!onGoingDispute);
    onGoingDispute = true;
    emit Dispute(onGoingDispute);
  }

  function endDispute() public {
    require(msg.sender == admin || msg.sender == landlord);
    require(onGoingDispute);
    onGoingDispute = false;
    emit Dispute(onGoingDispute);
  }


}