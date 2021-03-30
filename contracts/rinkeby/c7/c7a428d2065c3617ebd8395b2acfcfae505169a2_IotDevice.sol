/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity ^0.5.16;


contract IotDevice{
    
    struct Iot{
        uint id;
        string name;
        string IpAddress;
        uint temp;
        uint humidity;
    }
    // iot address
    event IotAddress(uint id,string name);
    // iot temp
    event TempChange(uint id,uint temp);
    // iot humidity
    event HumidityChange(uint id,uint temp);
    // ipAddress
    event IpChange(uint id, string ipAddress);
    // mapping
    mapping(uint => address) public IotDeviceToOwner;
    
    mapping(uint => address) public ToIot;
    
    mapping(address => uint) public ownerIotCount;
    
    mapping(address => uint[]) public ownerToIot;
    
    // CurrentIotId
    uint CurrentIotId = 0;
    // Iot to iotdevice
    Iot[] public iotdevice;
    // function
    function createIotDevice(string memory _newName,address _newIotDevice) public {
        iotdevice.push(Iot(CurrentIotId, _newName, '', 0, 0));
        IotDeviceToOwner[CurrentIotId]=msg.sender;
        ToIot[CurrentIotId]= _newIotDevice;
        ownerIotCount[msg.sender] += 1;
        ownerToIot[msg.sender].push(CurrentIotId);
        emit IotAddress(CurrentIotId, _newName);
        CurrentIotId++;
    }
    function isPermittedAddress(uint _IotId, address _senderAddress) private view  returns (bool) {
    return _senderAddress == IotDeviceToOwner[_IotId] || _senderAddress == ToIot[_IotId];
    }
  
    function getIotCount(address _ownerAddress) public view  returns (uint) {
    return ownerIotCount[_ownerAddress];
    }
    
    function getIotIdByIndex(uint _index) public view returns (uint) {
    return ownerToIot[msg.sender][_index];
    }
  
    // Setters
    // Check that sender owns the Iot
    // Update stored value for a Iot
    // Trigger change event  
    function setTemp(uint _IotId, uint _newTemp) public {
    require(isPermittedAddress(_IotId, msg.sender));
    iotdevice[_IotId].temp = _newTemp;
    emit TempChange(_IotId, _newTemp);
    }

    function setHumidity(uint _IotId, uint _newHumidity) public {
    require(isPermittedAddress(_IotId, msg.sender));
    iotdevice[_IotId].humidity = _newHumidity;
    emit HumidityChange(_IotId, _newHumidity);
    }
    
    function setIpAddress(uint _IotId, string memory _newIpAddress) public {
    require(isPermittedAddress(_IotId, msg.sender));
    iotdevice[_IotId].IpAddress = _newIpAddress;
    emit IpChange(_IotId, _newIpAddress);
    }
  
    
    function getTemp(uint _IotId) public view returns (uint) {
    return iotdevice[_IotId].temp;
    }

    function getHumidity(uint _IotId) public view returns (uint) {
    return iotdevice[_IotId].humidity;
    }
    
    function getIpAddress(uint _IotId) public view returns (string memory) {
    return iotdevice[_IotId].IpAddress;
    }
    
}