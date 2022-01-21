/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT

// File: NewCode_flat.sol



// File: @chainlink/contracts/src/v0.7/interfaces/KeeperCompatibleInterface.sol



pragma solidity ^0.8.7;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.7/KeeperBase.sol


pragma solidity ^0.8.7;

contract KeeperBase {
  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    require(tx.origin == address(0), "only for simulated backend");
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File: @chainlink/contracts/src/v0.7/KeeperCompatible.sol


pragma solidity ^0.8.7;



abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// File: contracts/NewCode.sol


pragma solidity ^0.8.7;

//Registration Smart contract
contract Registration {
    
    //Variables
    address public Regulator; //Ethereum address of the regulator
    mapping(address => bool) public manufacturer; //a mapping that lists all authorized manufacturers
    mapping(address => bool) public distributor; //a mapping that lists all authorized distributors
    mapping(address => bool)  public healthcarecenter; //a mapping for all authorized healthcare centers
    
    //Registration Events
    event RegistrationSCDeployer(address indexed Regulator); //An event to show the address of the registration SC deployer
    event ManufacturerRegistered(address indexed Regulator, address indexed manufacturer);
    event DistributorRegistered(address indexed Regulator, address indexed distributor);
    event HealthCareCenterRegistered(address indexed Regulator, address indexed healthcarecenter);

    //Modifiers
    modifier onlyRegulator() {
        require(Regulator == msg.sender, "Only the Regulator is eligible to run this function");
        _;
    }
    
    //Creating the contract constructor

    constructor() {
        Regulator = msg.sender; //The regulator is the deployer of the registration SC
        emit RegistrationSCDeployer(Regulator);

    }
    
    //Registration Functions

    function manufacturerRegistration (address user) public onlyRegulator {
        require(manufacturer[user] == false, "The user is already registered");
        manufacturer[user] = true;
        emit ManufacturerRegistered(msg.sender, user);

    }
    
    function distributorRegistration (address user) public onlyRegulator {
        require(distributor[user] == false, "The user is already registered");
        distributor[user] = true;
        emit DistributorRegistered(msg.sender, user);
    }

    function healthcarecenterRegistration (address user) public onlyRegulator{
        require(healthcarecenter[user] == false, "The user is already registered");
        healthcarecenter[user] = true;
        emit HealthCareCenterRegistered(msg.sender, user);
    }    
}

//Commitment Smart contract


contract Commitment is KeeperCompatibleInterface {
    
    //Declaring variables
    Registration public regcontract; //used to access variables and functions from the registration contract
    address public CommittedManufacturer; //Used later on for monitoring purposes
    uint public StartingTime; //Used to define the starting time of deploying the ordering SC
    uint public CommitmentDuration; //The time window of commitment
    bytes32 public vaccineName;
    uint public MaxVaccineBoxes; //The maximum amount of COVID-19 vaccine boxes that the manufacturer can produce within each Lot
    uint public MinThreshold; //The minimum threshold that should be met for the manufacturer to accept manufacturing
    mapping(address => bool) public IsDistributorCommitted; //A mapping to check if the distributor has already comitted to deliver the vaccine Lot
    address public CommittedDistributor; //Used to store the address of the committed distributor
    bool public DistributorCommitted;
    mapping(address => HCPreference) public HCAffiliation; //A mapping to choose the affiliated distributor by the healthcare center
    struct HCPreference{
    address adistributor; //affiliated distributor EA
    bool affiliated; //used to check if the distributor has already been assigned as an affiliated distributor
    } 
    
    uint PlacedBidsCounter = 0; //Used to ensure the bids do not exceed the maximum
    uint public CurrentBids; //stores the number of accumulated bids
    uint public BiddersCounter = 0; //Used to store the total number of bidders
    address[] public Bidders; //an array of addresses to store the committed bidders' EAs
    mapping(address => bool) public BidderCommitted; //A mapping for healthcarecenters that have priority in orders
    mapping(address => uint) public BidderAmount; //Used to track the amount committed by each healhcarecenter
    bool public ProductionPermission; //Used to indicate if production is approved or denied
    bool public CommitmentWindowClosed; //Used to all the oracle to execute once only
 
    //Commitment events
    event CommitmentDetails (address indexed _manufacturer, address indexed _vaccineLotEA, bytes32 _vaccineName, uint _MaxVaccineBoxes, uint _MinThreshold, uint _StartingTime, uint _CommitmentDuration); //An event to show the address of the commitment SC deployer and the MaxVaccineLotAmount
    event DistributorCommitmentDetails(address indexed _distributor, address indexed _vaccineLotEA);
    event HealthcareCenterCommitmentDetails(address indexed healthcarecenter, address indexed _vaccineLotEA, uint _placedorder);
    event VaccineLotsManufactured(address indexed manufacturer, uint indexed _ordernumber, uint _VaccineLotsProduced); //An event to confirm the manufacturing of the vaccine lots
    event CloseCommitmentWindow(address indexed _msgsender, bytes32 _windowclosed);
    event ProductionApproved(bytes32 _approved, uint _currentbids, address indexed _vaccineLotEA);
    event ProductionDenied(bytes32 _denied, uint _currentbids, address indexed _vaccineLotEA);


    //Modifiers 
    modifier onlyhealthcarecenter{
    require(regcontract.healthcarecenter(msg.sender), "Only the healthcarecenter is allowed to execute this function");
    _;
    }
    
    modifier onlymanufacturer{
    require(regcontract.manufacturer(msg.sender), "Only the manufacturer is allowed to execute this function");
    _;
    }
    
    modifier onlyDistributor{
    require(regcontract.distributor(msg.sender), "Only the distributor is allowed to execute this function");
    _;
    }

    //Constructor
    
    constructor(address RegistrationSCaddress, uint _MaxVaccineBoxes, string memory _vaccineName, uint _MinThreshold, uint _CommitmentDuration) {
        regcontract = Registration(RegistrationSCaddress);
        CommitmentDuration =  _CommitmentDuration * 1 minutes; //It's assumed that the duration is the same for both the distributors and bidders
        vaccineName = bytes32(bytes(_vaccineName));
        MaxVaccineBoxes = _MaxVaccineBoxes;
        MinThreshold = _MinThreshold;
        StartingTime = block.timestamp;
        CommittedManufacturer = msg.sender;
        emit CommitmentDetails(msg.sender, address(this), vaccineName, MaxVaccineBoxes, MinThreshold, StartingTime, CommitmentDuration);
    } 
    
    //Functions
    
    //Distributor Commitment function
    function DistributorCommitment() public onlyDistributor{
        require(block.timestamp <= StartingTime + CommitmentDuration, "New commitments are no longer accepted as the time window is over");
        require(DistributorCommitted == false, "The vaccine Lot has already been committed to by another distributor ");
        IsDistributorCommitted[msg.sender] = true; //This boolean mapping is used to store the committed distributors
        DistributorCommitted = true; //this boolean indicates that a distributor has committed to deliver the vaccine Lot
        CommittedDistributor = msg.sender;
        emit DistributorCommitmentDetails(msg.sender, address(this));
        
    }

    // This function is used to match the healthcare center to its affiliated distributor, the mapping links the address of the HCcenter with a struct with the details of the Affiliated distributor
    function AddAffiliatedDistributor (address _distributor) public onlyhealthcarecenter{ 
        require(!HCAffiliation[msg.sender].affiliated, "This healthcare center already has an affiliated distributor");
        HCAffiliation[msg.sender].adistributor = _distributor;
        HCAffiliation[msg.sender].affiliated = true;
    }
    
    //Healthcare centers commitment function
    function PlaceBid(uint _PlacedBid) public onlyhealthcarecenter{
        require(block.timestamp <= StartingTime + CommitmentDuration , "New bids are no longer accepted as the time window is over");
        require(IsDistributorCommitted[HCAffiliation[msg.sender].adistributor], "The affiliated distributor with this healthcare center has not committed to deliver this vaccine Lot");
        require(_PlacedBid + PlacedBidsCounter <= MaxVaccineBoxes, "The specified amount exceeds the maximum/remaining number of boxes within the vaccine Lot");
        require(!BidderCommitted[msg.sender], "This healthcare center has already placed a bid before");
        PlacedBidsCounter += _PlacedBid;
        CurrentBids = PlacedBidsCounter; //used because the counter is not public
        Bidders.push(msg.sender);
        BidderCommitted[msg.sender] = true; //Used to ensure that the healthcare center does not place another bid
        BidderAmount[msg.sender] = _PlacedBid; //Used to track the amount comitted by each healthcarecenter
        BiddersCounter += 1; //A counter for the total number of bidders which is used in the monitorting SC

        if(CurrentBids != MaxVaccineBoxes){
            emit HealthcareCenterCommitmentDetails(msg.sender, address(this), _PlacedBid);
        } else if(CurrentBids >= MaxVaccineBoxes){
            emit HealthcareCenterCommitmentDetails(msg.sender, address(this), _PlacedBid);
            emit CloseCommitmentWindow(msg.sender, bytes32("Commitment Window is now closed"));
            emit ProductionApproved(bytes32("Production is approved"), CurrentBids, address(this));
            CommitmentWindowClosed = true;
            ProductionPermission = true;
        }
        
        
    }

    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (StartingTime + CommitmentDuration) < block.timestamp;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        require(CommitmentWindowClosed == false);
        if(CurrentBids >= MinThreshold*MaxVaccineBoxes){
            emit ProductionApproved(bytes32("Production is approved"), CurrentBids, address(this));
            ProductionPermission = true;
            CommitmentWindowClosed = true;
        } else {
            emit ProductionDenied(bytes32("Production is denied"), CurrentBids, address(this));
            CommitmentWindowClosed = true;
        
        }

        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }


}

//Production Smart Contract
contract Production{

    //Declaring Variables 

    Registration public regcontract; //used to access variables and functions from the registration contract
    Commitment public Ccontract; //used to access variables and functions from the commitment contract
    address public vaccineLotEA; //Ethereum address of vaccine Lot
    uint public vaccineBoxes;
    uint public expirydate;
    uint public deliveryduration; //Here we are assuming that delivery should happen within a certain time window
    bytes32 public vaccineName; 
    uint DeliveredBoxesCounter = 0;
    uint public CurrentDeliveredBoxes;
    uint ReceivedBoxesCounter = 0;
    uint public CurrentReceivedBoxes;
    //bytes32 public IPFShash;
    enum  vaccineLotState  {NotManufactured, Manufactured, EnRoute, Delivered}
    vaccineLotState public Lotstate;
    mapping(address => bool) public ReceptionConfirmation; //Used to check if the healthcare center received their committed amount or not
    mapping(address => uint) public ReceivedAmount; //Used to track how much each healthcare center received

    //events
    event vaccineLotProduced(address indexed _manufacturer, address indexed _vaccineLotEA, bytes32 _vaccineName, bytes32 _IPFShash, uint _vaccineBoxes, uint _productionTime, uint _deliveryduration, uint _expirydate); //An event to show the details of the manufatured vaccine Lot
    event EnRoute(address indexed _distributor, address indexed _vaccineLotEA, bytes32 _IPFShash, uint _StartingTime); //Event indicating that the vaccine lot is being delivered
    event ConfirmDelivery(address indexed _distributor, address indexed _vaccineLotEA, address indexed _healthcarecenter, uint _deliveredboxes,  bytes32 _IPFShash, uint _DeliveryTime); //Event confirming that the healthcare center has received the vaccine lot
    event ConfirmReception(address indexed _healhcarecenter, address indexed _vaccineLotEA, uint _receivedboxes,  bytes32 _IPFShash, uint _ReceptionTime); //Event confirming that the healthcare center has received the vaccine lot
    event EndDelivery(address indexed _distributor, address indexed _vaccineLotEA, uint _vaccineBoxesDelivered, bytes32 _IPFShash, uint _EndingTime); // Event declaring the end of the delivery process

    //Modifiers
    modifier onlyhealthcarecenter{
    require(regcontract.healthcarecenter(msg.sender), "Only the healthcarecenter is allowed to execute this function");
    _;
    }
    
    modifier onlymanufacturer{
    require(regcontract.manufacturer(msg.sender), "Only the manufacturer is allowed to execute this function");
    _;
    }
    
    modifier onlyDistributor{
    require(regcontract.distributor(msg.sender), "Only the distributor is allowed to execute this function");
    _;
    }


    //Constructor

    constructor(address registractionSC, address commitmentSC) {

    regcontract = Registration(registractionSC);
    Ccontract = Commitment(commitmentSC);
    vaccineLotEA = commitmentSC; //The EA of the vaccine Lot is the same as the commitment SC EA
    }

    //Functions
    function ProduceVaccineLot(uint _expirydurationinmonths, uint _producedboxes, uint _deliverydurationindays, string memory _IPFShash) public onlymanufacturer{
        require(Ccontract.ProductionPermission() == true, "The manufacturer does not have permission to produce the vaccine Lot");
        require(Lotstate == vaccineLotState.NotManufactured, "This vaccine Lot has already been manufactured");
        Lotstate = vaccineLotState.Manufactured; //Changing the state of the vaccine Lot to manufactured
        vaccineName = Ccontract.vaccineName();
        vaccineBoxes = _producedboxes;
        expirydate = block.timestamp + (_expirydurationinmonths * 30 days);
        deliveryduration = block.timestamp + (_deliverydurationindays * 1 days);
        emit vaccineLotProduced(msg.sender, vaccineLotEA, vaccineName, bytes32(bytes(_IPFShash)), vaccineBoxes, block.timestamp, deliveryduration, expirydate);
    }

    //Note: Delivery time limit can be added if vaccines require that

    function startDelivery(string memory _IPFShash) public onlyDistributor{
        require(Lotstate == vaccineLotState.Manufactured, "This vaccine Lot has either already been delivered or not manufactured yet");
        Lotstate = vaccineLotState.EnRoute;
        emit EnRoute(msg.sender, vaccineLotEA, bytes32(bytes(_IPFShash)), block.timestamp);
    }

    function ProofofReception(uint _receivedboxes, string memory _IPFShash) public onlyhealthcarecenter{ //This function is used by each healthcare center to ensure they received the correct amount of vaccine boxes
        require(Lotstate == vaccineLotState.EnRoute, "Can't confirm vaccine Lot reception as it is not out for delivery yet");
        require(Ccontract.BidderCommitted(msg.sender), "This healthcare center has not committed and therefore cannot receive the vaccine boxes");
        require(!ReceptionConfirmation[msg.sender],"This healthcare center has already confirmed receiving their vaccine boxes");
        require(_receivedboxes == Ccontract.BidderAmount(msg.sender), "Can't confrim reception because the number of boxes does not equal the bidder's committed amount");
        ReceptionConfirmation[msg.sender] = true; 
        ReceivedAmount[msg.sender] = _receivedboxes; //Stores the received amount which will be used in the consumption SC
        emit ConfirmReception(msg.sender, vaccineLotEA, _receivedboxes, bytes32(bytes(_IPFShash)), block.timestamp);
    }

    function ProofofDelivery(address _healthcarecenter, uint _deliveredboxes, string memory _IPFShash) public onlyDistributor{ //This function is used by the distributor to ensure they delivered the correct amount of vaccine boxes for a particular HC center
       //require(Lotstate == vaccineLotState.Received, "Can't confirm vaccine Lot delivery as it is not out for delivery yet or the healthcare center has not yet confirmed receiving it");
        require(_deliveredboxes == Ccontract.BidderAmount(_healthcarecenter), "Can't confrim delivery because the number of boxes does not equal the bidder's committed amount");
        require(Lotstate == vaccineLotState.EnRoute, "Can't confirm vaccine Lot delivery as it is not out for delivery yet or has already been delivered");
        require(Ccontract.IsDistributorCommitted(msg.sender), "Only a committed distributor is allowed to deliver vaccine boxes to healthcare centers");
        require(ReceptionConfirmation[_healthcarecenter],"The healthcare center has not confirmed receiving the vaccine boxes");
        DeliveredBoxesCounter += _deliveredboxes;
        CurrentDeliveredBoxes = DeliveredBoxesCounter;
        if(CurrentDeliveredBoxes == Ccontract.CurrentBids()){
            Lotstate = vaccineLotState.Delivered; //The whole lot has been delivered
            emit ConfirmDelivery(msg.sender, vaccineLotEA,_healthcarecenter, _deliveredboxes, bytes32(bytes(_IPFShash)), block.timestamp); //This is for the individual delivery
            emit EndDelivery(msg.sender, vaccineLotEA, CurrentDeliveredBoxes, bytes32(bytes(_IPFShash)), block.timestamp); //This ends the whole delivery process
        } else {
            emit ConfirmDelivery(msg.sender, vaccineLotEA, _healthcarecenter, _deliveredboxes, bytes32(bytes(_IPFShash)), block.timestamp);
        }
    }
    //Note: In case of disputes, live tracking of delivered vaccines is needed to ensure that they have been delivered
}

//Consumption Smart Contract
contract Consumption{

    //Variables
    Registration public regcontract2;
    Commitment public Ccontract2; //used to access variables and functions from the commitment contract
    Production public pcontract;
    mapping(address => uint) public usedAmount;
    mapping(address => uint) public wastedAmount;

    //Events
    event VaccineBoxesUsed(address indexed _healhcarecenter, uint _Amountused, bytes32 _IPFShash, uint _DateofUse);
    event VaccineBoxesDisposed(address indexed _healhcarecenter, uint _disposedAmount, bytes32 _IPFShash, uint _DateofDisposal);

    //Modifiers
    modifier onlyhealthcarecenter{
        require(regcontract2.healthcarecenter(msg.sender), "Only the healthcare center is allowed to execute this function");
        _;
    }

    //Constructor
    constructor(address registrationSC, address commitmentSC, address ProductionSC) {
        regcontract2 = Registration(registrationSC);
        Ccontract2 = Commitment(commitmentSC);
        pcontract = Production(ProductionSC);
    }

    //Functions
    //Note: Here we are assuming vaccine boxes are used one box at a time instead of using vaccine vials to avoid complexity

    function UseVaccineBoxes(uint _usedvaccineBoxes, string memory _IPFShash) public onlyhealthcarecenter{
        require(Ccontract2.BidderCommitted(msg.sender), "The executor of this function needs to be a committed bidder");
        require(_usedvaccineBoxes + usedAmount[msg.sender] + wastedAmount[msg.sender] <= pcontract.ReceivedAmount(msg.sender));
        usedAmount[msg.sender] += _usedvaccineBoxes; //This accumulates how much each HC center used

        emit VaccineBoxesUsed(msg.sender, _usedvaccineBoxes, bytes32(bytes(_IPFShash)), block.timestamp);
    }

    function DisposeVaccineBoxes(uint _disposedvaccineBoxes, string memory _IPFShash) public onlyhealthcarecenter{
        require(_disposedvaccineBoxes + usedAmount[msg.sender] + wastedAmount[msg.sender] <= pcontract.ReceivedAmount(msg.sender));
        wastedAmount[msg.sender] += _disposedvaccineBoxes; //This accumulates how much each HC center wasted
        emit VaccineBoxesDisposed(msg.sender, _disposedvaccineBoxes, bytes32(bytes(_IPFShash)), block.timestamp);
    }

}

//Waste Assessment Smart Contract
contract WasteAssessment is KeeperCompatibleInterface {

    //Variables
    Registration public regcontract3; //Might not be needed Here
    Commitment public Ccontract3; 
    Production public pcontract2; 
    Consumption public Cscontract;
    uint public excessAmount;
    uint public missingAmount;
    uint public unusedAmount;

    //Events
    event ManufacturerViolation(address _manufacturer, bytes32 _msg, uint _excessAmount);
    event DistributorViolation(address _distributor, bytes32 _msg, uint _missingAmount);
    event HealthcareCenterViolation(address _healhcarecenter, bytes32 _msg, uint _unusedAmount);

    //Constructor
    constructor(address registrationSC, address commitmentSC, address ProductionSC, address ConsumptionSC){
        regcontract3 = Registration(registrationSC);
        Ccontract3 = Commitment(commitmentSC);
        pcontract2 = Production(ProductionSC);
        Cscontract = Consumption(ConsumptionSC);
    }

    //Functions
    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = block.timestamp > pcontract2.expirydate();
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {

        if(pcontract2.vaccineBoxes() > Ccontract3.CurrentBids()){
            excessAmount = pcontract2.vaccineBoxes() - Ccontract3.CurrentBids();
            emit ManufacturerViolation(Ccontract3.CommittedManufacturer(), bytes32("Excess Amount Produced"), excessAmount);
        }


        if(pcontract2.CurrentDeliveredBoxes() < pcontract2.vaccineBoxes()){
            missingAmount = pcontract2.vaccineBoxes() - pcontract2.CurrentDeliveredBoxes();
            emit DistributorViolation(Ccontract3.CommittedDistributor(), bytes32("Distributor Failed To Deliver"), missingAmount);
        }

        for(uint i = 0; i < Ccontract3.BiddersCounter(); i++){
            if(Cscontract.usedAmount(Ccontract3.Bidders(i)) < Ccontract3.BidderAmount(Ccontract3.Bidders(i))){
                unusedAmount = Ccontract3.BidderAmount(Ccontract3.Bidders(i)) - Cscontract.usedAmount(Ccontract3.Bidders(i));
                emit HealthcareCenterViolation(Ccontract3.Bidders(i), bytes32("HCcenter failed to consume"), missingAmount);
            } else if(Cscontract.wastedAmount(Ccontract3.Bidders(i)) > 0){
                emit HealthcareCenterViolation(Ccontract3.Bidders(i), bytes32("HCcenter wasted vaccines"), Cscontract.wastedAmount(Ccontract3.Bidders(i)));
            }
        }
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }


}