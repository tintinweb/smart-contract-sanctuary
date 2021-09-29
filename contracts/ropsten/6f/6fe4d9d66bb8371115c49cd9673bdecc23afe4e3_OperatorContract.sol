/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract OperatorContract{
    address public operator;
    address location;
    address manager;
    address seller;
    address []  operator_array;
    address []  location_array;
    address []  manager_array;
    address []  seller_array;
    address []  asset_array;

    struct Operator { address operator; Location [] locations;}
    Operator[] public operators;
    mapping(address => Operator)  Operators;
    
    struct Location {address location; address [] managers;}
    mapping(address => Location)   Locations;
    
    struct Manager {address manager; Seller [] sellers;}
    mapping(address => Manager)   Managers;
    
    struct Seller {address seller; string seller_name; string sellerId;}
    //mapping(address => Seller [])   ManagerSellers;

    struct Record {address operator; string items; string sellerId; string customerLocation; string customer;}
    mapping(address => Record)   RecordOwners;

    struct Menu {string item; string price;}
    mapping (address => Menu [])   LocationMenus;
    
    struct Asset {address asset; address verifier; uint expiration; uint assetRate; uint assetRange; uint assetRating;}
    mapping(address => Asset[]) AssetOperators;

    modifier onlyNewOperator(){
        require(Operators[msg.sender].operator != msg.sender);
        _;
    }

    modifier OperatorAccess(){
        require(Operators[msg.sender].operator == msg.sender);
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

    //OPERATOR FUNCTIONS
    function createOperator() public onlyNewOperator {
        Operators[msg.sender].operator = msg.sender;
        operator_array.push(msg.sender);
    }
    function createLocation(address _location) public OperatorAccess {
        address [] storage insert;
        Location memory thisLocation = Location(_location,insert);
        Operators[msg.sender].locations.push(thisLocation);
    }
    function getLocations() public view returns(Location[] memory){
        return Operators[msg.sender].locations;
    }
    function deleteAllLocations() public OperatorAccess{
        delete Operators[msg.sender].locations;
    }   
    function createManager(address _manager) public LocationAccess {
        Locations[msg.sender].managers.push(_manager);
    }
    function getManagers() public view returns(address [] memory){
        return Locations[msg.sender].managers;
    }
    function deleteAllManagers() public LocationAccess{
        delete Locations[msg.sender].managers;
    }
    
    //function deactivateLocation(address _location) public OperatorAccess{
    //    Location[] storage locations = OperatorLocations[msg.sender];
    //     for (uint i = 0; i < locations.length; i++) {
     //        if (locations[i].location==_location) {
     //            delete locations[i];
     //            delete location_array[i];
     //    }}
    //}
    //function activateLocation(address _location, string memory _location_name) public OperatorAccess{
     //   location_array.push(location);
     //   Location memory thisLocation = Location(_location,_location_name);
     //   OperatorLocations[msg.sender].push(thisLocation);
    //}
    /*
    //LOCATION FUNCTIONS
    function activateMenu(string [] memory _itemname, string [] memory _price) public ManagerAccess{
        for (uint i=0; i <_itemname.length; i++){
        Menu memory thisMenu = Menu(_itemname[i], _price[i]);
        LocationMenus[msg.sender].push(thisMenu);
        }
    }
    function activateManager(address _manager, string memory _manager_name) public ManagerAccess {
        Manager memory thisManager = Manager(_manager, _manager_name);
        Locations[msg.sender].push(thisManager);
    }
    function activateManagers(address [] memory _managers, string [] memory _manager_names) public ManagerAccess{
        for (uint i=0; i <_managers.length; i++){
        Manager memory thisManager = Manager(_managers[i], _manager_names[i]);
        Locations[msg.sender].push(thisManager);
        manager_array.push(_managers[i]);
        }
    }
    function deactivateAllManagers() public ManagerAccess{
        delete Locations[msg.sender];
        delete manager_array;
    }
    function deactivateManagers(address [] memory _managers) public ManagerAccess{
        Manager [] storage managers = Locations[msg.sender];
        for (uint i = 0; i < managers.length; i++) {
            if(managers[i].manager==_managers[i]){
                delete managers[i];
                delete manager_array[i];
        }}
    }
    function deactivateManager(address _manager) public ManagerAccess{
        Manager [] storage managers = Locations[msg.sender];
        for (uint i = 0; i < managers.length; i++) {
            if(managers[i].manager==_manager){
                delete managers[i];
                delete manager_array[i];
        }}
    }
   
    //MANAGER FUNCTIONS
    function activateSeller(address _seller, string memory _seller_name, string memory _sellerId) public ManagerAccess{
        seller = _seller;
        seller_array.push(seller);
        Seller memory thisSeller = Seller(_seller, _seller_name,_sellerId);
        Managers[msg.sender].push(thisSeller);
    }
    function activateSellers(address [] memory _sellers, string [] memory _seller_names, string [] memory _sellerId) public ManagerAccess{
        for (uint i=0; i<_sellers.length; i++) {
        Seller memory thisSeller = Seller(_sellers[i], _seller_names[i], _sellerId[i]);
        Managers[msg.sender].push(thisSeller);
        seller_array.push(_sellers[i]);
    }
    }
    function deactivateAllSellers() public ManagerAccess{
        delete Managers[msg.sender];
        delete seller_array;
    }
    function deactivateSeller(address _sellers) public ManagerAccess{
        Seller [] storage sellers = Managers[msg.sender];
        for (uint i=0; i<sellers.length; i++) {
            if(sellers[i].seller==_sellers){
                delete sellers[i];
                delete seller_array[i];
                }}
    }
    function deactivateSellers(address [] memory _sellers) public ManagerAccess{}
    function getSellers() public view returns(address [] memory){
        return seller_array;
    }

    function addAsset(address _asset, address _verifier, uint _expiration, uint _assetRate, uint _assetRange) public ManagerAccess{
        require(_verifier == msg.sender);
        asset_array.push(_asset);
        Asset memory thisAsset = Asset(_asset,msg.sender,_expiration,_assetRate,_assetRange,100);
        AssetOperators[msg.sender].push(thisAsset);
    }
    
    function getAssets() public view returns(address [] memory){
        return asset_array;
    }
*/
    //CUSTOMER FUNCTIONS
    function addSale(
        address payable _operator,
        string calldata _items,
        string calldata _sellerId,
        string calldata _customerLocation,
        string calldata _customer,
        uint itemTotal,
        uint _burnAmount) payable external{
        require(itemTotal >= msg.value);
        Record memory thisRecord = Record(_operator,_items,_sellerId,_customerLocation,_customer);
        RecordOwners[_operator] = thisRecord;
       // _burnAmount = SafeMath.mul(current_rate,msg.value);
  //      emit Burn(msg.sender, _burnAmount);
        _operator.transfer(msg.value);

    }
    

    //function startAssetSale(address _operator, address _location) payable external{
    //    require(OperatorLocations[_operator].location ==_location);
    //}

   


   // function viewMenu(address _manager) public view returns(Menu [] memory){
   //     return LocationMenus[_manager];
  //  }
    
    
   
}