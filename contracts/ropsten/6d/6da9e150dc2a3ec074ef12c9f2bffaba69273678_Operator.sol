/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


    contract Operator {
  
    Locations[] public locations;
    struct Locations { address _operator; address _location; string _location_name;}
    mapping(address => Locations[]) LocationsOperator;
    address operator;
    mapping (address => string) record;

    
    function createOperator(address _operator) public{
        require(msg.sender ==_operator);
        operator = _operator;
    }
    
    function addLocation(address _location, string memory _location_name) public{
        LocationsOperator[msg.sender].push(Locations(msg.sender,_location,_location_name));
    }
    
    function getLocations(address _operator) external view returns(Locations[] memory){
        return LocationsOperator[_operator];
    }
  
    
    Managers[] public managers;
    struct Managers { address location; address manager; string manager_name;}
    mapping(address => Managers[]) ManagersLocation;
    
    function addManager(address _manager, string memory _manager_name) public {
        ManagersLocation[msg.sender].push(Managers(msg.sender, _manager, _manager_name));
    }
   
    function getManagers(address _location) external view returns(Managers[] memory) {
        return ManagersLocation[_location];
    }
     

    Sellers[] public sellers;
    struct Sellers { address manager; address seller; string seller_name;}
    mapping(address => Sellers[]) SellersManager;
  
    function addSeller(address _seller, string memory _seller_name) public {
        SellersManager[msg.sender].push(Sellers(msg.sender, _seller, _seller_name));
    }
  
    function getSellers(address _manager) external view returns(Sellers[] memory) {
        return SellersManager[_manager];
    }
    
    function addSale(address _seller, string memory _location, string memory _items, string memory _sellerId, string memory _customer)public returns (bytes32  _record){
        _record = keccak256(abi.encodePacked(_sellerId,_location,_items,_seller,_customer));
        record[_seller] = string(abi.encodePacked(_record));
        
    }
    
    /*
    function sendLocationSales(address _operator)
    function sendManagedSales(address _location)
    function sendSales(address _manager){}
    function addSellers(address[] _sellers) public{}
    function removeSeller(address _seller) public{}

    */
   
}