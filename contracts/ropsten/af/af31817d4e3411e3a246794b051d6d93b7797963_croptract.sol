pragma solidity ^0.4.24;

contract croptract{
    
    /*misc variables*/
    uint orderIdCount = 1;
    
    /*variables regarding the individuals involved*/
    mapping (address => bool) Controller;
     
    mapping (address => bool) Farmer;
/*    mapping (address => FarmerDetails) FarmerInfo;
    struct FarmerDetails {
        bytes farmLocation;
        bytes farmerIdentity;
        uint landCapacity;
        bytes typeOfCrops;
    }
*/    
    mapping (address => bool) Restaurant;
/*    mapping (address => RestaurantDetails) RestaurantInfo;
    struct RestaurantDetails {
        bytes restaurantIdentity;
        bytes restaurantLocation;
    }
 */   
    mapping (address => bool) Driver;
 /*   mapping (address => RestaurantDetails) DriverInfo;
    struct DriverDetails {
        bytes driverIdentity;
    }*/    
    /*variables regarding the order*/
    //1. status of the proposal
    enum status {requested,accepted,locked,transferring,unlocked,ok,dispute}    
    //2. link an id to a unique order
    mapping (uint => OrderDetails) OrderById;
    //3. things that each order contains
    struct OrderDetails {
        //this id duplicates the mapping
        address source;
        address[] medium;
        address destination;
        bytes destinationAddress;
        status orderStatus;
        bytes orderContent;
        uint grams;
    }
    
    /*function run at first setup*/
    //setup membership address for checking 
    //whether an address is a voting member etc. 
    constructor () public {
	Controller[msg.sender] = true;
    }


    /* modifiers (checkers)*/
    //check if is restaurant
    modifier isRestaurant (address _restaurantAddr) {
        require (Restaurant[_restaurantAddr] == true);
        _;
    }
    
    
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
    
    function addFarmer (address _farmerAddress) isController (msg.sender) public{
        Farmer[_farmerAddress] = true;
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
    function request (address _source, bytes _destinationAddress, bytes _orderContent) 
    isRestaurant(msg.sender) public {
	    //require content not empty
	    require (_destinationAddress.length != 0);
        require (_orderContent.length != 0);
        require (Farmer[_source] == true);
        //create a proposal with the following content
        OrderById[orderIdCount].source = _source;
        OrderById[orderIdCount].destination = msg.sender;
        OrderById[orderIdCount].destinationAddress = _destinationAddress; 
        OrderById[orderIdCount].orderStatus = status.requested;
        OrderById[orderIdCount].orderContent = _orderContent;
        //increment id for next proposal to use
        orderIdCount += 1;
    }
    
    
    
    /*
    main function 2: farmer accepts request
    */
    function acceptOrder (uint _Id) public {
        //require the person executing this function be the appointed farmer
        require (msg.sender == OrderById[_Id].source);
        require (OrderById[_Id].orderStatus == status.requested);
        OrderById[_Id].orderStatus = status.accepted;
    }
    
    /*
    main function 3: harvest and lock
    */    
    function lock (uint _Id, uint _weight) public {
    //require the person executing this function be the appointed farmer
        require (msg.sender == OrderById[_Id].source);  
        require (OrderById[_Id].orderStatus == status.accepted);
        OrderById[_Id].orderStatus = status.locked; 
        OrderById[_Id].grams = _weight;
    }

    /*
    main function 4: drivers mark the goods they&#39;ve picked up 
    */        
    function pickUp (uint _Id) isDriver (msg.sender) public {
        require (OrderById[_Id].orderStatus == status.locked || 
        OrderById[_Id].orderStatus == status.transferring);
        
        OrderById[_Id].medium.push(msg.sender);
        OrderById[_Id].orderStatus = status.transferring;
    }
    
    /*
    main function 5: restaurant receives the box and unlocks
    */        
    function unlock (uint _Id) public {
        require (OrderById[_Id].orderStatus == status.transferring);
    //require the person executing this function be the restaurant who made the order
        require (msg.sender == OrderById[_Id].destination);   
        OrderById[_Id].orderStatus = status.unlocked;
    }    

    /*
    main function 6a: 
    */        
    function goodsOK (uint _Id) public {
        require (OrderById[_Id].orderStatus == status.unlocked);
    //require the person executing this function be the restaurant who made the order
        require (msg.sender == OrderById[_Id].destination);
        OrderById[_Id].orderStatus = status.ok;
    }    
    
    /*
    main function 6b: restaurant receives the box and unlocks
    */        
    function goodsNotOK (uint _Id) public {
        require (OrderById[_Id].orderStatus == status.unlocked);
    //require the person executing this function be the restaurant who made the order
        require (msg.sender == OrderById[_Id].destination);
        OrderById[_Id].orderStatus = status.dispute;
    }    
    
    
    /*view functions (not writing the smart contract)*/
    
    //retrieve info of proposal given id
    function getOrder (uint _getOrderlId) 
    public view returns(address, address[], address, bytes, status, bytes, uint) {
        return (OrderById[_getOrderlId].source, 
        OrderById[_getOrderlId].medium, 
        OrderById[_getOrderlId].destination,
        OrderById[_getOrderlId].destinationAddress,
        OrderById[_getOrderlId].orderStatus, 
        OrderById[_getOrderlId].orderContent, 
        OrderById[_getOrderlId].grams);
        
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