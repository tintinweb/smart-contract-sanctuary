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
  function dispute(bool ongGoing, address user) external;
}


contract RentalAgreement {
  using SafeMath for uint256;

  token public EthRental;
  notifier public Notifier;
  address public admin;
  address public landlord;
  address public tenant;
  uint256 public rent;
  bool public agreementApproved;
  uint256 public escrowAmount;
  uint256 public withdrawableAmount;
  bool public ticketOpen;
  bool public onGoingDispute;
  address public disputeStartedBy;

  /*-----Rental Agreement Clauses-----*/

  /*General*/
  uint256 public selectedPropertyID = 5;
  string public selectedCountry=&#39;VEN&#39;;
  uint256 public selectedStateID=4;
  uint256 public dateLeaseStarts = 2323321212;
  uint256 public leaseDateSelected = 3;
  uint256 public dateLeaseEnds = 23232312;
  uint256 public renewalSelected = 3;
  
  /*Property*/
  uint256 public selectedAccessToParking = 1;

  /*Parties*/
  uint256 public selectedOccupantsOptions=2;

  /*Terms*/
  uint256 public selectedRentFrequency = 2;
  uint256 public rentAgreed = 393993393939;
  uint256 public paymentDateDay = 4;
  uint256 public paymentDateMonth = 9;
  uint256 public selectedincrementNotice = 3;
  uint256 public daysNoticeBeforeIncreasingRent = 48;
  uint256 public selectedPetsAllowance = 3;
  uint256 public selectedSmokingAllowance = 1;
  uint256 public selectedLatePayment = 32;
  uint256 public latePaymentAmount = 3;
  uint256 public selectedUtilitiesDetails = 2;
  uint256 public electricity = 3;
  uint256 public water_sewer = 2;
  uint256 public internet = 1;
  uint256 public cable = 2;
  uint256 public telephone = 3;
  uint256 public naturalGas = 2;
  uint256 public heatingOil_propane = 1;
  uint256 public garbageCollection = 2;
  uint256 public alarm_securitySystem = 3;

  /*Final details*/
  uint256 public selectedDisputeResolution = 1;
  uint256 public selectedDisputeResolutionCost = 2;
  uint256 public selectedAdditionalClause = 2;



  event Approved(address user);
  event Deposit(address user, uint amount);
  event Withdraw(address user, uint amount);
  event RentModified(uint256 amount);
  event Ticket(bool open);
  event Dispute(bool ongGoing, address user);


  constructor() public {
    EthRental = token(0x7a09FD841C49F9C82D722B940A21864B5cD8320F); //token address
    Notifier = notifier(0xc182e9604f65FF08c0AC045E5F2EFB3bdeC83dA0);
    admin = EthRental.owner();
    landlord = msg.sender;
    tenant = 0x0Ec793B3F6ECf6FC2D371F7e2000337A1CB47dA6; //tenant address
    rent = 30000000000000000; //rent amount
  }



  //Tenant approves this this agreement
  function approveAgreement() public {
    require(msg.sender == tenant);
    require(EthRental.totalAllowance(tenant, this));
    agreementApproved = true;
    Notifier.approved(tenant);
    emit Approved(tenant);
  }

  //Tenant deposits the rent manually
  function deposit(uint amount) rentalAgreementApproved public {
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
  function depositFrom(uint amount) rentalAgreementApproved public {
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
  function withdraw() rentalAgreementApproved public {
    require(msg.sender == landlord);
    uint256 amount = withdrawableAmount;
    withdrawableAmount = 0;
    require(EthRental.transfer(landlord, amount));
    Notifier.withdraw(landlord, amount);
    emit Withdraw(landlord, amount);
  }

  //Increase/Decrease the rent
  function modifyRent(uint newRent) rentalAgreementApproved public {
    require(msg.sender == landlord);
    rent = newRent;
    Notifier.rentModified(rent);
    emit RentModified(rent);
  }

  //Open a ticket
  function openTicket() rentalAgreementApproved public {
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

  function startDispute() rentalAgreementApproved public {
    require(!onGoingDispute);
    require(msg.sender == admin || msg.sender == landlord || msg.sender == tenant);
    disputeStartedBy = msg.sender;
    onGoingDispute = true;
    Notifier.dispute(onGoingDispute, disputeStartedBy);
    emit Dispute(onGoingDispute, disputeStartedBy);
  }

  function endDispute() public {
    require(onGoingDispute);
    require(msg.sender == disputeStartedBy || msg.sender == admin);
    onGoingDispute = false;
    Notifier.dispute(onGoingDispute, disputeStartedBy);
    emit Dispute(onGoingDispute, disputeStartedBy);
  }


  function viewContractState() public view returns(uint256,uint256,uint256,bool,bool){
    return (rent, escrowAmount, withdrawableAmount, ticketOpen, onGoingDispute);
  }

  function viewMostRelevantClauses() public view returns(uint256,string,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
    return (selectedPropertyID,
            selectedCountry,
            selectedStateID,
            selectedRentFrequency,
            paymentDateDay,
            paymentDateMonth,
            dateLeaseStarts,
            leaseDateSelected,
            renewalSelected);
  }

  function viewFirstLotOfClauses() public view returns(uint256,string,uint256,uint256,uint256,uint256,uint256,uint256){
    return (selectedPropertyID,
            selectedCountry,
            selectedStateID,
            dateLeaseStarts,
            leaseDateSelected,
            dateLeaseEnds,
            renewalSelected,
            selectedAccessToParking);
  }

  function viewSecondLotOfClauses() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
    return (selectedOccupantsOptions,
            selectedRentFrequency,
            rentAgreed,
            paymentDateDay,
            paymentDateMonth,
            selectedincrementNotice,
            daysNoticeBeforeIncreasingRent,
            selectedPetsAllowance);
  }

  function viewThirdLotOfClauses() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
    return (selectedSmokingAllowance,
            selectedLatePayment,
            latePaymentAmount,
            selectedUtilitiesDetails,
            electricity,
            water_sewer,
            internet,
            cable);
  }

  function viewFourthLotOfClauses() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
    return (telephone,
            naturalGas,
            heatingOil_propane,
            garbageCollection,
            alarm_securitySystem,
            selectedDisputeResolution,
            selectedDisputeResolutionCost,
            selectedAdditionalClause);
  }



  modifier rentalAgreementApproved {
    require(agreementApproved);
    _;
  }


}