/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


    contract Operator {
  
    Locations[] public locations;
    struct Locations { address _operator; address _location;}
    mapping(address => Locations[]) LocationsOperator;
    address operator;
  
    
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

   
}