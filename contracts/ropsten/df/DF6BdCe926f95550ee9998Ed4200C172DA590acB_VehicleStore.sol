/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

pragma solidity 0.8.9;

/**
* Milan Bjegovic - Timacum
*/

contract VehicleStore {
    
    event NewVehicle(uint vehicleId, string name, uint color, uint yearm, uint registered);

    uint idDigits = 64;
    uint nameModulus = 10 ** idDigits;
    
    struct Vehicle {
      string name;
      uint color;
      uint yearm;
      uint registered;
    }

   Vehicle[] public vehicles;

    mapping (uint => address) public vehicleToOwner;
    mapping (address => uint) public ownerVehicleCount;



    function createVehicle(string memory _name, uint _color, uint _yearm, uint _registered) public {
        vehicles.push(Vehicle(_name, _color, _yearm, _registered));
 
    }

    modifier changeColor(uint _vehicleId, uint _newColor) {
    require(msg.sender == vehicleToOwner[_vehicleId]);
    require(msg.value == 1000000000000000000 wei);
    vehicles[_vehicleId].color = _newColor;
    _;
    }

    modifier changeRegistered(uint _vehicleId, uint _newRegistered) {
    require(msg.sender == vehicleToOwner[_vehicleId]);
    require(msg.value == 2000000000000000000 wei);
    vehicles[_vehicleId].registered = _newRegistered;
    _;
    }

    function getVehiclesByOwner(address _owner) external view returns(uint[] memory) {
    uint[] memory result = new uint[](ownerVehicleCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < vehicles.length; i++) {
      if (vehicleToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

}