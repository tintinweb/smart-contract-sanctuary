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


  /*General*/

  struct PropertyType{
    uint256 selectedPropertyID;
    // string other;
  }

  struct PropertyLocation{
    string selectedCountry;
    uint256 selectedStateID;
  }

  struct LeaseDetails{
    uint256 dateLeaseStarts;
    uint256 leaseDateSelected;
    uint256 dateLeaseEnds;
    uint256 renewalSelected;
  }

  struct General{
    PropertyType propertyType;
    PropertyLocation propertyLocation;
    LeaseDetails leaseDetails;
  }


  /*Property*/

  struct PropertyDetails{
    uint256 selectedAccessToParking;
  }

  struct Property{
    PropertyDetails propertyDetails;
  }


  /*Parties*/

  struct TenantInformation{
    uint256 selectedOccupantsOptions;
  }

  struct Parties{
    TenantInformation tenantInformation;
  }


  /*Terms*/

  struct Rent{
    uint256 selectedRentFrequency;
    uint256 rentAmount;
    uint256 paymentDateDay;
    uint256 paymentDateMonth;
  }

  struct RentIncrease{
    uint256 selectedincrementNotice;
    uint256 daysNoticeBeforeIncreasingRent;
  }

  struct UseOfProperty{
    uint256 selectedPetsAllowance;
    uint256 selectedSmokingAllowance;
  }

  struct LatePayments{
    uint256 selectedLatePayment;
    uint256 latePaymentAmount;
  }

  struct UtilitiesDetails{
    uint256 selectedUtilitiesDetails;
    uint256 electricity;
    uint256 water_sewer;
    uint256 internet;
    uint256 cable;
    uint256 telephone;
    uint256 naturalGas;
    uint256 heatingOil_propane;
    uint256 garbageCollection;
    uint256 alarm_securitySystem;
  }

  struct Terms{
    Rent rent;
    RentIncrease rentIncrease;
    UseOfProperty useOfProperty;
    LatePayments latePayments;
    UtilitiesDetails utilitiesDetails;
  }


  /*Final details*/

  struct DisputeResolution{
    uint256 selectedDisputeResolution;
    uint256 selectedDisputeResolutionCost;
  }

  struct AdditionalClauses{
    uint256 selectedAdditionalClause;
  }

  struct FinalDetails{
    DisputeResolution disputeResolution;
    AdditionalClauses additionalClauses;
  }



  /*Rental agreement info*/
  struct Clauses{
    General general;
    Property property;
    Parties parties;
    Terms terms;
    FinalDetails finalDetails;
  }

  Clauses public clauses;


  event Approved(address user);
  event Deposit(address user, uint amount);
  event Withdraw(address user, uint amount);
  event RentModified(uint256 amount);
  event Ticket(bool open);
  event Dispute(bool ongGoing, address user);

  function RentalAgreement() public {
    EthRental = token(0x7a09FD841C49F9C82D722B940A21864B5cD8320F); //token address
    Notifier = notifier(0xc182e9604f65FF08c0AC045E5F2EFB3bdeC83dA0);
    admin = EthRental.owner();
    landlord = msg.sender;
    tenant = 0x0Ec793B3F6ECf6FC2D371F7e2000337A1CB47dA6; //tenant address
    rent = 30000000000000000; //rent amount


    // clauses.general.propertyType.other = &#39;Cabin&#39;;
    clauses.general.propertyType.selectedPropertyID = 5;
    clauses.general.propertyLocation.selectedCountry=&#39;VEN&#39;;
    clauses.general.propertyLocation.selectedStateID=4;
    clauses.general.leaseDetails.dateLeaseStarts = 2323321212;
    clauses.general.leaseDetails.leaseDateSelected = 3;
    clauses.general.leaseDetails.dateLeaseEnds = 23232312;
    clauses.general.leaseDetails.renewalSelected = 3;
    
    clauses.property.propertyDetails.selectedAccessToParking = 1;

    clauses.parties.tenantInformation.selectedOccupantsOptions=2;

    clauses.terms.rent.selectedRentFrequency = 2;
    clauses.terms.rent.rentAmount = 393993393939;
    clauses.terms.rent.paymentDateDay = 4;
    clauses.terms.rent.paymentDateMonth = 9;
    clauses.terms.rentIncrease.selectedincrementNotice = 3;
    clauses.terms.rentIncrease.daysNoticeBeforeIncreasingRent = 48;
    clauses.terms.useOfProperty.selectedPetsAllowance = 3;
    clauses.terms.useOfProperty.selectedSmokingAllowance = 1;
    clauses.terms.latePayments.selectedLatePayment = 32;
    clauses.terms.latePayments.latePaymentAmount = 3;
    clauses.terms.utilitiesDetails.selectedUtilitiesDetails = 2;
    clauses.terms.utilitiesDetails.electricity = 3;
    clauses.terms.utilitiesDetails.water_sewer = 2;
    clauses.terms.utilitiesDetails.internet = 1;
    clauses.terms.utilitiesDetails.cable = 2;
    clauses.terms.utilitiesDetails.telephone = 3;
    clauses.terms.utilitiesDetails.naturalGas = 2;
    clauses.terms.utilitiesDetails.heatingOil_propane = 1;
    clauses.terms.utilitiesDetails.garbageCollection = 2;
    clauses.terms.utilitiesDetails.alarm_securitySystem = 3;

    clauses.finalDetails.disputeResolution.selectedDisputeResolution = 1;
    clauses.finalDetails.disputeResolution.selectedDisputeResolutionCost = 2;
    clauses.finalDetails.additionalClauses.selectedAdditionalClause = 2;





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
    return (clauses.general.propertyType.selectedPropertyID,
            clauses.general.propertyLocation.selectedCountry,
            clauses.general.propertyLocation.selectedStateID,
            clauses.terms.rent.selectedRentFrequency,
            clauses.terms.rent.paymentDateDay,
            clauses.terms.rent.paymentDateMonth,
            clauses.general.leaseDetails.dateLeaseStarts,
            clauses.general.leaseDetails.leaseDateSelected,
            clauses.general.leaseDetails.renewalSelected);
  }

  function viewFirstLotOfClauses() public view returns(uint256,string,uint256,uint256,uint256,uint256,uint256,uint256){
    return (clauses.general.propertyType.selectedPropertyID,
            clauses.general.propertyLocation.selectedCountry,
            clauses.general.propertyLocation.selectedStateID,
            clauses.general.leaseDetails.dateLeaseStarts,
            clauses.general.leaseDetails.leaseDateSelected,
            clauses.general.leaseDetails.dateLeaseEnds,
            clauses.general.leaseDetails.renewalSelected,
            clauses.property.propertyDetails.selectedAccessToParking);
  }

  function viewSecondLotOfClauses() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
    return (clauses.parties.tenantInformation.selectedOccupantsOptions,
            clauses.terms.rent.selectedRentFrequency,
            clauses.terms.rent.rentAmount,
            clauses.terms.rent.paymentDateDay,
            clauses.terms.rent.paymentDateMonth,
            clauses.terms.rentIncrease.selectedincrementNotice,
            clauses.terms.rentIncrease.daysNoticeBeforeIncreasingRent,
            clauses.terms.useOfProperty.selectedPetsAllowance);
  }

  function viewThirdLotOfClauses() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
    return (clauses.terms.useOfProperty.selectedSmokingAllowance,
            clauses.terms.latePayments.selectedLatePayment,
            clauses.terms.latePayments.latePaymentAmount,
            clauses.terms.utilitiesDetails.selectedUtilitiesDetails,
            clauses.terms.utilitiesDetails.electricity,
            clauses.terms.utilitiesDetails.water_sewer,
            clauses.terms.utilitiesDetails.internet,
            clauses.terms.utilitiesDetails.cable);
  }

  function viewFourthLotOfClauses() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
    return (clauses.terms.utilitiesDetails.telephone,
            clauses.terms.utilitiesDetails.naturalGas,
            clauses.terms.utilitiesDetails.heatingOil_propane,
            clauses.terms.utilitiesDetails.garbageCollection,
            clauses.terms.utilitiesDetails.alarm_securitySystem,
            clauses.finalDetails.disputeResolution.selectedDisputeResolution,
            clauses.finalDetails.disputeResolution.selectedDisputeResolutionCost,
            clauses.finalDetails.additionalClauses.selectedAdditionalClause);
  }



  modifier rentalAgreementApproved {
    require(agreementApproved);
    _;
  }


}