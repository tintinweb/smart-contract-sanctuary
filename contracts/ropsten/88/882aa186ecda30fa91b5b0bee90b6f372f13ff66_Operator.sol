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
    
    function addLocation(address _operator,address _location) public{
        require(msg.sender == operator);
        LocationsOperator[msg.sender].push(Locations(_operator,_location));
    }
    
    function getLocations() external view returns(Locations[] memory){
        return LocationsOperator[msg.sender];
    }
  
    
    Managers[] public managers;
    struct Managers { address location; address manager;}
    mapping(address => Managers[]) ManagersLocation;
    
    function addManager(address _location, address _manager) public {
        require(msg.sender == _location);
        ManagersLocation[msg.sender].push(Managers(_location, _manager));
    }
   
    function getManagers() external view returns(Managers[] memory) {
        return ManagersLocation[msg.sender];
    }
     

    Sellers[] public sellers;
    struct Sellers { address manager;address seller;}
    mapping(address => Sellers[]) SellersManager;
  
    function addSeller(address _manager, address _seller) public {
        require(msg.sender == _manager);
        SellersManager[msg.sender].push(Sellers(_manager, _seller));
    }

  
    function getSellers() external view returns(Sellers[] memory) {
        return SellersManager[msg.sender];
    }

   
}