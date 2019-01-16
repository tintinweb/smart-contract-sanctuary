pragma solidity ^0.4.24;

//this contract prevents overflow
contract SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

/*
this contract controls the deposit and locked amount of tokens
to buy products from farmers, the restaurant buys the token 1:1rmb for payment.
on order, the amount of the order is locked up
*/
contract depositControl is SafeMath{
    mapping (address => uint) DepositStored;
    mapping (address => uint) DepositLocked;
    mapping (address => bool) DepositController;


    
    constructor () public {
        DepositController[msg.sender] = true;
    }
    
    modifier isDepositController (address _addr) {
        require (DepositController[_addr] == true);
        _;
    }

    function publicAddDeposit (address _account, uint _amount) isDepositController(msg.sender) 
    public {
        DepositStored[_account] = add(DepositStored[_account],_amount);
    }
    
    function publicDeductDeposit (address _account, uint _amount) isDepositController(msg.sender) 
    public {
        DepositStored[_account] = sub(DepositStored[_account],_amount);
    }
    
    function publicLock (address _account, uint _amount) isDepositController(msg.sender) 
    public {
        DepositStored[_account] = sub(DepositStored[_account],_amount);
        DepositLocked[_account] = add(DepositLocked[_account],_amount);
    }
    
    function publicUnlock (address _account, uint _amount) isDepositController(msg.sender)
    public {
        DepositStored[_account] = add(DepositStored[_account],_amount);
        DepositLocked[_account] = sub(DepositLocked[_account],_amount);
    }
    
    function publicTransfers (address _from, address _to, uint _amount) isDepositController(msg.sender)
    public {
        DepositStored[_from] = sub(DepositStored[_from],_amount);
        DepositStored[_to] = add(DepositStored[_to],_amount);
    }
    
    function addDeposit (address _account, uint _amount) 
    internal {
        DepositStored[_account] = add(DepositStored[_account],_amount);
    }
    
    function deductDeposit (address _account, uint _amount) internal {
        DepositStored[_account] = sub(DepositStored[_account],_amount);
    }
    
    function lock (address _account, uint _amount) internal {
        DepositStored[_account] = sub(DepositStored[_account],_amount);
        DepositLocked[_account] = add(DepositLocked[_account],_amount);
    }
    
    function unlock (address _account, uint _amount) internal {
        DepositStored[_account] = add(DepositStored[_account],_amount);
        DepositLocked[_account] = sub(DepositLocked[_account],_amount);
    }
    
    function transfers (address _from, address _to, uint _amount) internal {
        DepositStored[_from] = sub(DepositStored[_from],_amount);
        DepositStored[_to] = add(DepositStored[_to],_amount);
    }
    
}

/*
this contract is the tribunal system.
when a restaurant calls dispute from the "croptract" contract, a case is created
if the restaurant wins, it receives the refund of dispute fee and its locked tokens are unlocked
otherwise, the restaurant has to pay to the farmer as the normal procedure
*/
contract tribunal is depositControl{
    mapping (address => bool) TribunalController;
    mapping (address => bool) Judge;
    mapping (uint => CaseDetails) CaseById;
    enum disputeStatus {open, approved, rejected}
    
    uint disputeCost = 10;
    
    uint caseIdCount = 1;
    
    struct CaseDetails {
        uint orderID;
        disputeStatus caseStatus;
        address payer;
        address payee;
        uint disputeAmount;
    }
    
    constructor () public {
        TribunalController[msg.sender] = true;
        Judge[msg.sender] = true;
    }
    
    modifier isJudge (address _addr) {
        require (Judge[_addr] == true);
        _;
    }
    
    function createCase (uint _orderId, address _payer, address _payee, uint _disputeAmount) internal {
        CaseById[caseIdCount].orderID = _orderId;
        CaseById[caseIdCount].caseStatus = disputeStatus.open;
        CaseById[caseIdCount].payer = _payer;
        CaseById[caseIdCount].payee = _payee;
        CaseById[caseIdCount].disputeAmount = _disputeAmount;
        caseIdCount = add(caseIdCount,1);
    }
    
    function approveDispute (uint _caseId) isJudge(msg.sender) public {
        CaseById[_caseId].caseStatus = disputeStatus.approved;
        super.unlock(CaseById[caseIdCount].payer,CaseById[caseIdCount].disputeAmount);
        super.addDeposit(CaseById[caseIdCount].payer,disputeCost);
    }
    
    function rejectDispute (uint _caseId) isJudge(msg.sender) public {
        CaseById[_caseId].caseStatus = disputeStatus.rejected;
        super.transfers(CaseById[caseIdCount].payer,
        CaseById[caseIdCount].payee,
        CaseById[caseIdCount].disputeAmount);
    }    
    
}

/*
the order contract
at the end of the stage, the restaurant chooses ok to pay to Farmer
otherwise, the restaurant brings the case to the tribunal
*/
contract croptract is tribunal{
    
    /*misc variables*/
    uint orderIdCount = 1;
    
    
    
    /*variables regarding the individuals involved*/
    mapping (address => bool) Controller;
     
    mapping (address => bool) Farmer;
    mapping (address => uint) FarmerCertificate;

    mapping (address => bool) Restaurant;

    mapping (address => bool) Driver;
    /*variables regarding the order*/
    //1. status of the proposal
    enum status {sent,acknowledged,packed,accepted,disputed}    
    //2. link an id to a unique order
    mapping (uint => OrderDetails) OrderById;
    //3. things that each order contains
    struct OrderDetails {
        address source;
        address[] medium;
        address purchaser;
        bytes destinationAddress;
        status orderStatus;
        bytes orderContent;
        uint totalAmount;
        uint deadline;
    }
    
    /*function run at first setup*/
    //setup membership address for checking 
    //whether an address is a voting member etc. 
    constructor () public {
	Controller[msg.sender] = true;
    }


    /* modifiers (checkers)*/


    //check if is driver
    modifier isDriver (address _driverAddr) {
        require (Driver[_driverAddr] == true);
        _;
    }
    
    modifier isController (address _controllerAddr){
        require (Controller[_controllerAddr] == true);
        _;
    }

    /*functions*/
    /*
    controller functions
    */
    function addController (address _controllerAddress) isController (msg.sender) public{
        Controller[_controllerAddress] = true;
    }
    
    function addFarmer (address _controllerAddress) isController (msg.sender) public{
        Farmer[_controllerAddress] = true;
    }    
    
    function renewFarmerCertificate (address _farmerAddress, uint _daysExtend) isController (msg.sender) public{
        FarmerCertificate[_farmerAddress] = now + _daysExtend *1 days;
    }    

    function addRestaurant (address _restaurantAddress) isController (msg.sender) public{
        Restaurant[_restaurantAddress] = true;
    }
    
    function addDriver (address _driverAddress) isController (msg.sender) public{
        Driver[_driverAddress] = true;
    }
    
    function removeController (address _controllerAddress) isController (msg.sender) public{
        Controller[_controllerAddress] = false;
    }
    
    function revokeFarmerCertificate (address _farmerAddress) isController (msg.sender) public{
        FarmerCertificate[_farmerAddress] = 0;
    } 
    
    function removeFarmer (address _farmerAddress) isController (msg.sender) public{
        Farmer[_farmerAddress] = false;
    }    

    function removeRestaurant (address _restaurantAddress) isController (msg.sender) public{
        Restaurant[_restaurantAddress] = false;
    }
    
    function removeDriver (address _driverAddress) isController (msg.sender) public{
        Driver[_driverAddress] = false;
    }
    
    /*
    main function 1: restaurant requests vegetables
    */
    function request (address _source, address _purchaser, bytes _destinationAddress, bytes _orderContent, uint _totalAmount, uint _deadline) 
    isController(msg.sender) public {
	    //require content not empty
	    require (_destinationAddress.length != 0);
        require (_orderContent.length != 0);
        require (_totalAmount > 0);
        require (_totalAmount <= DepositStored[_purchaser]);
        require (Farmer[_source] == true);
        require (FarmerCertificate[_source] >= now + _deadline);
        
        //create a proposal with the following content
        OrderById[orderIdCount].source = _source;
        OrderById[orderIdCount].purchaser = _purchaser;
        OrderById[orderIdCount].destinationAddress = _destinationAddress; 
        OrderById[orderIdCount].orderStatus = status.sent;
        OrderById[orderIdCount].orderContent = _orderContent;
        OrderById[orderIdCount].totalAmount = _totalAmount;
        OrderById[orderIdCount].deadline = now + _deadline;        
        
        
        
        //increment id for next proposal to use
        orderIdCount = add(orderIdCount,1);
    }
    
    
    
    /*
    main function 2: farmer accepts request
    */
    function acknowledgeOrder (uint _Id) public {
        //require the person executing this function be the appointed farmer
        require (msg.sender == OrderById[_Id].source);
        require (OrderById[_Id].orderStatus == status.sent);
        OrderById[_Id].orderStatus = status.acknowledged;
        
        depositControl.lock(OrderById[_Id].purchaser,OrderById[_Id].totalAmount);
    }
    
    /*
    main function 3: harvest and packed
    */    
    function pack (uint _Id) public {
    //require the person executing this function be the appointed farmer
        require (msg.sender == OrderById[_Id].source);  
        require (OrderById[_Id].orderStatus == status.acknowledged);
        OrderById[_Id].orderStatus = status.packed; 
    }

    /*
    main function 4: drivers mark the goods they&#39;ve picked up 
    */        
    function pickUp (uint _Id) isDriver (msg.sender) public {
        require (OrderById[_Id].orderStatus == status.packed);
        OrderById[_Id].medium.push(msg.sender);
    }
    

    /*
    main function 5a: restaurant receives goods and says ok
    */        
    function goodsOK (uint _Id) public {
        require (OrderById[_Id].orderStatus == status.packed);
    //require the person executing this function be the restaurant who made the order
        require (msg.sender == OrderById[_Id].purchaser);
        OrderById[_Id].orderStatus = status.accepted;
        depositControl.unlock(OrderById[_Id].purchaser,OrderById[_Id].totalAmount);
        depositControl.transfers(OrderById[_Id].purchaser,OrderById[_Id].source,OrderById[_Id].totalAmount);
    }    
    
    /*
    main function 5b: restaurant receives goods and says not ok (because of quality, lateness)
    */        
    function goodsNotOK (uint _Id) public {
        require (OrderById[_Id].orderStatus == status.packed);
    //require the person executing this function be the restaurant who made the order
        require (msg.sender == OrderById[_Id].purchaser);
        OrderById[_Id].orderStatus = status.disputed;
        depositControl.deductDeposit(OrderById[_Id].purchaser,disputeCost);
        createCase(_Id,OrderById[_Id].purchaser,OrderById[_Id].source,OrderById[_Id].totalAmount);
    }
    
    /*
    main function 5c: restaurant does not receive the goods
    */
    function goodsNotReceived (uint _Id) public {
        require (OrderById[_Id].orderStatus == status.acknowledged);
        require (now> OrderById[_Id].deadline + 2 days);        
    //require the person executing this function be the restaurant who made the order
        require (msg.sender == OrderById[_Id].purchaser);
        OrderById[_Id].orderStatus = status.disputed;
        depositControl.deductDeposit(OrderById[_Id].purchaser,disputeCost);
        createCase(_Id,OrderById[_Id].purchaser,OrderById[_Id].source,OrderById[_Id].totalAmount);
    }    
    
    /*
    special function: farmer can call dispute 
    if the restaurant does not execute 5a or 5b or 5c within a time period
    */
    function forceDispute (uint _Id) public {
        require (OrderById[_Id].orderStatus == status.packed);
        require (msg.sender == OrderById[_Id].source);
        require (now > OrderById[_Id].deadline + 5 days);
        createCase(_Id,OrderById[_Id].purchaser,OrderById[_Id].source,OrderById[_Id].totalAmount);
    }
    
    
    /*view functions (not writing the smart contract)*/
    
    //retrieve info of proposal given id
    function getOrder (uint _getOrderlId) 
    public view returns(address, address[], address, bytes, status, bytes, uint) {
        return (OrderById[_getOrderlId].source, 
        OrderById[_getOrderlId].medium, 
        OrderById[_getOrderlId].purchaser,
        OrderById[_getOrderlId].destinationAddress,
        OrderById[_getOrderlId].orderStatus, 
        OrderById[_getOrderlId].orderContent, 
        OrderById[_getOrderlId].totalAmount);
    }

    function getController (address _getControllerAddr) public view returns(bool){
        return Controller[_getControllerAddr];
    }
    function getRestaurant (address _getRestaurantAddr) public view returns(bool){
        return Restaurant[_getRestaurantAddr];
    }
    function getFarmer (address _getFarmerAddr) public view returns(bool){
        return Farmer[_getFarmerAddr];
    }
    function getDriver (address _getDriverAddr) public view returns(bool){
        return Driver[_getDriverAddr];
    }
    function getCounter () public view returns(uint){
        return orderIdCount;
    }
}