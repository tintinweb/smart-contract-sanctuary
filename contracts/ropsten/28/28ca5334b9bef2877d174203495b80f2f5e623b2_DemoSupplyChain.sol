pragma solidity ^0.4.24;

contract DemoSupplyChain {

  //Due&#241;o del contrato
  address owner;

  //Estado del sensor
  enum deviceState { Active, Inactive, Deleted }

  //Estructura de datos para una medici&#243;n
  struct Reading {
    address sender;
    uint timestamp;
    uint temperature;
  }

  //Estructura de datos para el dispositivo
  struct Device {
    uint8 deviceId;
    bytes32 description;
    bool exists;
    deviceState state;
    Reading[] readings;
  }

  //Mapping para guardar sensores
  mapping(uint8 => Device) internal devices;

  //Estructura de datos para clave del dispositivo
  struct DeviceIds {
    uint8 deviceId;
  }

  //Array para guardar las claves
  DeviceIds[] private devicesIdsLUT;

  //Chequear que la acci&#243;n solo la ejecute el creado del contrato
  modifier onlyOwner() { // Modifier
    require(msg.sender == owner, "Acci&#243;n permitida solo al creador del contrato.");
    _;
  }

  //Constructor del contrato
  constructor() public {

    //Registrar el propietario
    owner = msg.sender;

    //Agregar dispositivo por defecto
    addDevice(1, "Sensor de temperatura", deviceState.Active);

  }

  //Funci&#243;n para agregar un nuevo dispositivo
  function addDevice(uint8 _deviceId, bytes32 _description, deviceState _state)
  public
  onlyOwner {
    //Si el dispositivo a&#250;n no existe
    if (!devices[_deviceId].exists) {
      //Agregar nuevo dispositivo 
      devices[_deviceId].deviceId = _deviceId;
      devices[_deviceId].description = _description;
      devices[_deviceId].exists = true;
      devices[_deviceId].state = _state;

      //Agregar la clave a la LUT
      devicesIdsLUT.push(DeviceIds(_deviceId));

    } else {
      revert("El id indicado ya existe");
    }
  }

  //Funci&#243;n para agregar una nueva medici&#243;n
  function addReading(uint8 _deviceId, uint _timestamp, uint _temperature)
  public {
    //Si el dispositivo existe
    if (devices[_deviceId].exists) {

      //Agregar nueva medici&#243;n
      devices[_deviceId].readings.push(Reading(msg.sender, _timestamp, _temperature));

    } else {
      revert("El id de dispositivo indicado no existe");
    }
  }

  //Obtener datos del dispositivo
  function getDeviceById(uint8 _deviceId)
  constant
  public
  returns(bytes32 description, deviceState state) {
    //Si el dispositivo existe
    if (devices[_deviceId].exists) {
      description = devices[_deviceId].description;
      state = devices[_deviceId].state;
    } else {
      revert("El dispositivo indicado no existe");
    }
  }

  //Obtener todos los dispositivos
  function getAllDevices()
  constant
  public
  returns(uint8[], bytes32[], deviceState[])
  {
    uint8[] memory deviceId = new uint8[](devicesIdsLUT.length);
    bytes32[] memory description = new bytes32[](devicesIdsLUT.length);
    deviceState[] memory state = new deviceState[](devicesIdsLUT.length);

    for (uint8 i = 0; i < devicesIdsLUT.length; i++) {
      deviceId[i] = devices[devicesIdsLUT[i].deviceId].deviceId;
      description[i] = devices[devicesIdsLUT[i].deviceId].description;
      state[i] = devices[devicesIdsLUT[i].deviceId].state;
    }

    return (deviceId, description, state);
  }

  //Obtener las &#250;ltimas N mediciones de un dispositivo
  function getLastNReadingsByDeviceId(uint8 _deviceId, uint8 _readingNumber)
  constant
  public
  returns(address[], uint[], uint[])
  {
    if (!devices[_deviceId].exists) {
      revert("El dispositivo indicado no existe");
    }

    //Obtener &#237;ndice desde, hasta y tama&#241;o del array
    uint fromIndex = devices[_deviceId].readings.length;
    uint toIndex = 0;
    //Si tiene menos lecturas de las que se piden
    if (devices[_deviceId].readings.length < _readingNumber) {
      toIndex = 1;
    } else {
      toIndex = devices[_deviceId].readings.length - _readingNumber + 1;
    }

    address[] memory sender = new address[](fromIndex - toIndex + 1);
    uint[] memory timestamp = new uint[](fromIndex - toIndex + 1);
    uint[] memory temperature = new uint[](fromIndex - toIndex + 1);
    uint index = 0;

    for(uint i = fromIndex; i >= toIndex; i--){
      sender[index] = devices[_deviceId].readings[i-1].sender;
      timestamp[index] = devices[_deviceId].readings[i-1].timestamp;
      temperature[index] = devices[_deviceId].readings[i-1].temperature;
      index++;
    }

    //Devolver valores
    return (sender, timestamp, temperature);
  }

}