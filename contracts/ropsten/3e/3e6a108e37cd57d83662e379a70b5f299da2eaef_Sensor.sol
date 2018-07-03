pragma solidity 0.4.23;

contract Sensor{
    
    bytes32 public name;
    
    struct Sensor_Data{
        bytes32 timeStamp;
        bytes32 temprature;
        bytes32 latitude;
        bytes32 longitude;
    }
    
    Sensor_Data[] list; 
    uint public count;
    
    constructor(bytes32 _name) public {
        name = _name;
    }
    
    function addDataToList(bytes32 _timeStamp, bytes32 _temprature, bytes32 _latitude, bytes32 _longitude) public {
        
        Sensor_Data memory newData = Sensor_Data(_timeStamp, _temprature, _latitude, _longitude);
        
        list.push(newData);
        
        count++;
        
    }
    
    function getList() public view returns(bytes32[] timeStamp, bytes32[] temprature, bytes32[] latitude, bytes32[] longitude) {
        timeStamp = new bytes32[](count);
        temprature = new bytes32[](count);
        latitude = new bytes32[](count);
        longitude = new bytes32[](count);
        
        for (uint i = 0; i < count; i++){
        timeStamp[i] = list[i].timeStamp;
        temprature[i] = list[i].temprature;
        latitude[i] = list[i].latitude;
        longitude[i] = list[i].longitude;
        }

    }
}