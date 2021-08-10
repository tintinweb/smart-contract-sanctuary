/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

    contract Operator {

    address operator;
    address location;
    address manager;
    address seller;
    
    struct Operators { address operator;}
    mapping(address => Operators) OperatorAddresses;
    
    struct Records {address operator; string items; string sellerId; string customerLocation; string customer;}
    mapping(address => Records) RecordOwners;
    
    modifier onlyNewOperator(){
        require(OperatorAddresses[msg.sender].operator != msg.sender);
        _;
    }
    
    modifier OperatorAccess(){
        require(msg.sender == operator);
        _;
    }
    
    modifier LocationAccess(){
        require(msg.sender == location || msg.sender == operator);
        _;
    }
    
    modifier ManagerAccess(){
         require(msg.sender == operator || msg.sender == location || msg.sender == manager);
        _;
    }

    struct Locations {address location; string location_name;}
    mapping(address => Locations[] ) OperatorLocations;

    struct Managers {address manager; string manager_name;}
    mapping(address => Managers []) LocationManagers;
    
    struct Sellers {address seller; string seller_name; string sellerId;}
    mapping(address => Sellers []) ManagerSellers;

    struct Menus {string item; string price;}
    mapping (address => Menus) LocationMenus; 
    
//OPERATOR FUNCTIONS
    function createOperator(address _operator) public onlyNewOperator {
        require(msg.sender == _operator);
        operator = _operator;
        OperatorAddresses[msg.sender] = Operators(msg.sender);
    }
    function deactivateAllLocations() public OperatorAccess{
        delete OperatorLocations[msg.sender];
    }
    function deactivateLocation(address _location) public OperatorAccess{
        Locations[] storage locations = OperatorLocations[msg.sender];
         for (uint i = 0; i < locations.length; i++) {
             if (locations[i].location==_location) {
                 delete locations[i];
         }}
    }
    function activateLocation(address _location, string memory _location_name) public OperatorAccess{
        location = _location;
        Locations memory thisLocation = Locations(_location,_location_name);
        OperatorLocations[msg.sender].push(thisLocation);
    }
    function viewLocations() public view returns(Locations [] memory){
        address locationOperator = msg.sender;
        return OperatorLocations[locationOperator];
    }
    
//LOCATION FUNCTIONS
    function activateMenu(string memory _itemname, string memory _price) public ManagerAccess{
        LocationMenus[msg.sender] = Menus (_itemname, _price);
    }
    function activateManager(address _manager, string memory _manager_name) public ManagerAccess {
        manager = _manager;
        Managers memory thisManager = Managers(_manager, _manager_name);
        LocationManagers[msg.sender].push(thisManager);
    }
    function activateManagers(address [] memory _managers, string [] memory _manager_names) public ManagerAccess{
        for (uint i=0; i <_managers.length; i++){
        Managers memory thisManager = Managers(_managers[i], _manager_names[i]);
        LocationManagers[msg.sender].push(thisManager);
        }
    }
    function deactivateAllManagers() public ManagerAccess{
        delete LocationManagers[msg.sender];
    }
    function deactivateManagers(address [] memory _managers) public ManagerAccess{
        Managers [] storage managers = LocationManagers[msg.sender];
        for (uint i = 0; i < managers.length; i++) {
            if(managers[i].manager==_managers[i]){
                delete managers[i];
        }}
    }
    function deactivateManager(address _manager) public ManagerAccess{
        Managers [] storage managers = LocationManagers[msg.sender];
        for (uint i = 0; i < managers.length; i++) {
            if(managers[i].manager==_manager){
                delete managers[i];
        }}
    }
    function viewManagers() public view returns(Managers [] memory) {
        address managerLocation = msg.sender;
        return LocationManagers[managerLocation];
    }
     
//MANAGER FUNCTIONS
    function activateSeller(address _seller, string memory _seller_name, string memory _sellerId) public ManagerAccess{
        seller = _seller;
        Sellers memory thisSeller = Sellers(_seller, _seller_name,_sellerId);
        ManagerSellers[msg.sender].push(thisSeller);
    }
    function deactivateAllSellers() public ManagerAccess{
        delete ManagerSellers[msg.sender];
    }
    function deactivateSeller(address _sellers) public ManagerAccess{
        Sellers [] storage sellers = ManagerSellers[msg.sender];
        for (uint i=0; i<sellers.length; i++) {
            if(sellers[i].seller==_sellers){
                delete sellers[i];
                }}
    }
    function deactivateSellers(address [] memory _sellers) public ManagerAccess{}
    function activateSellers(address [] memory _sellers, string [] memory _seller_names, string [] memory _sellerId) public ManagerAccess{
        for (uint i=0; i<_sellers.length; i++) {
        Sellers memory thisSeller = Sellers(_sellers[i], _seller_names[i], _sellerId[i]);
        ManagerSellers[msg.sender].push(thisSeller);
    }
    }
    function viewSellers() public view returns(Sellers [] memory) {
        address sellersManager = msg.sender;
        return ManagerSellers[sellersManager];
    }
   
    
//CUSTOMER FUNCTIONS
    function addSale(
        address payable _operator, 
        string memory _items, 
        string memory _sellerId, 
        string memory _customerLocation, 
        string memory _customer,
        uint256 _amount)
        payable external{
        Records memory thisRecord = Records(_operator,_items,_sellerId,_customerLocation,_customer);
        RecordOwners[_operator] = thisRecord;
        _operator.transfer(_amount);
    }
    
    
    function viewMenu() external view returns(Menus memory){
        address menuLocation = msg.sender;
        return LocationMenus[menuLocation];
    }
    
}