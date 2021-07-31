/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


    contract Operator {
  
    Locations[] public locations;
    struct Locations { address _operator; address _location;}
    mapping(address => Locations[]) LocationsOperator;
    address operator;
    mapping (address => string) record;

    
    function createOperator(address _operator) public{
        require(msg.sender ==_operator);
        operator = _operator;
    }
    
    function addLocation(address _location) public{
        LocationsOperator[msg.sender].push(Locations(msg.sender,_location));
    }
    
    function getLocations(address _operator) external view returns(Locations[] memory){
        return LocationsOperator[_operator];
    }
  
    
    Managers[] public managers;
    struct Managers { address location; address manager;}
    mapping(address => Managers[]) ManagersLocation;
    
    function addManager(address _manager) public {
        ManagersLocation[msg.sender].push(Managers(msg.sender, _manager));
    }
   
    function getManagers(address _location) external view returns(Managers[] memory) {
        return ManagersLocation[_location];
    }
     

    Sellers[] public sellers;
    struct Sellers { address manager;address seller;}
    mapping(address => Sellers[]) SellersManager;
  
    function addSeller(address _seller) public {
        SellersManager[msg.sender].push(Sellers(msg.sender, _seller));
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