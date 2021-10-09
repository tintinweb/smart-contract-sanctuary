/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

interface IStorage {
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
    //setter 
    //single
    
    function setIntAddress(uint256 _keyId, address _value) external;
    function setStrAddress(string memory _keyName, address _value) external;
    function setAdrString(address _address, string memory _value) external;
    function setAdrByte32(address _address, bytes32 _value) external;
    function setAdrUint(address _address, uint256 _value) external;
    function setAdrBool(address _address, bool _value) external;
    
    function setIntStrAddress(uint256 _keyId, string memory _name, address _value) external;
    function setIntStrString(uint256 _keyId, string memory _name, string memory _value) external;
    function setIntStrByte32(uint256 _keyId, string memory _name, bytes32 _value) external;
    function setIntStrUint(uint256 _keyId, string memory _name, uint256 _value) external;
    function setIntStrBool(uint256 _keyId, string memory _name, bool _value) external;
    
    //many
    function setIntStrManyAddress(uint256 _keyId, string memory _name, address _value) external;
    function setIntStrManyString(uint256 _keyId, string memory _name, string memory _value) external;
    function setIntStrManyByte32(uint256 _keyId, string memory _name, bytes32 _value) external;
    function setIntStrManyUint(uint256 _keyId, string memory _name, uint256 _value) external;
    function setIntStrManyBool(uint256 _keyId, string memory _name, bool _value) external;
    
    //getter
    
    function getIntAddress(uint256 _keyId) external view returns(address);
    function getStrAddress(string memory _keyName) external view returns(address);
    function getAdrString(address _address) external view returns(string memory);
    function getAdrByte32(address _address) external view returns(bytes32);
    function getAdrUint(address _address) external view returns(uint256);
    function getAdrBool(address _address) external view returns(bool);
    
    function getIntStrAddress(uint256 _keyId, string memory _keyName) external view returns(address);
    function getIntStrString(uint256 _keyId, string memory _keyName) external view returns(string memory);
    function getIntStrByte32(uint256 _keyId, string memory _keyName) external view returns(bytes32);
    function getIntStrUint(uint256 _keyId, string memory _keyName) external view returns(uint256);
    function getIntStrBool(uint256 _keyId, string memory _keyName) external view returns(bool);
    
    function getIntStrManyAddresses(uint256 _keyId, string memory _keyName) external view returns(address[] memory);
    function getIntStrManyStrings(uint256 _keyId, string memory _keyName) external view returns(string[] memory);
    function getIntStrManyByte32(uint256 _keyId, string memory _keyName) external view returns(bytes32[] memory);
    function getIntStrManyUint(uint256 _keyId, string memory _keyName) external view returns(uint256[] memory);

}



contract AccessControl {
    address public owner;
    mapping(address => bool) whitelistController;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner, "invalid owner");
        _;
    }
    modifier onlyController {
        require(whitelistController[msg.sender] == true, "invalid controller");
        _;
    }
    function TransferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
    
    function WhitelistController(address _controller) public onlyOwner {
        whitelistController[_controller] = true;
    }
    function BlacklistController(address _controller) public onlyOwner {
        whitelistController[_controller] = false;
    }
    
    function Controller(address _controller) public view returns(bool) {
        return whitelistController[_controller];
    }
}

contract xStorage is IStorage, AccessControl {
  // scalars
  mapping(uint256 => address) intAddress;
  mapping(string => address) strAddress;
  mapping(address => string) adrString;
  mapping(address => uint256) adrUint256;
  mapping(address => bytes32) adrBytes32;
  mapping(address => bool) adrBool;
  
   // key value
  mapping(uint256 => mapping(string => address)) str_dataAddress;
  mapping(uint256 => mapping(string => string)) str_dataString;
  mapping(uint256 => mapping(string => bytes32)) str_dataBytes32;
  mapping(uint256 => mapping(string => uint256)) str_dataUint256;
  mapping(uint256 => mapping(string => bool)) str_dataBool;

  mapping(uint256 => mapping(string => address[])) str_dataManyAddresses;
  mapping(uint256 => mapping(string => bytes32[])) str_dataManyBytes32s;
  mapping(uint256 => mapping(string => string[])) str_dataManyStrings;
  mapping(uint256 => mapping(string => uint256[])) str_dataManyUint256;
  mapping(uint256 => mapping(string => bool[])) str_dataManyBool;
  
  
  constructor() {
        AccessControl.owner = msg.sender;
    }
  
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //set int  => data type
  function setIntAddress(uint256 _keyId, address _value) onlyController override external virtual  {
      intAddress[_keyId] = _value;
  }
  
  function setStrAddress(string memory _keyName, address _value) onlyController override external virtual  {
      strAddress[_keyName] = _value;
  }
  function setAdrString(address _address, string memory _value) onlyController override external virtual  {
      adrString[_address] = _value;
  }
  function setAdrByte32(address _address,bytes32 _value) onlyController override external virtual  {
      adrBytes32[_address]  = _value;
  }
  function setAdrUint(address _address, uint256 _value) onlyController override external virtual  {
      adrUint256[_address] = _value;
  }
  function setAdrBool(address _address, bool _value) onlyController override external virtual  {
      adrBool[_address] = _value;
  }
  
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //set int => string => data type
  
  function setIntStrAddress(uint256 _keyId, string memory _name, address _value) onlyController override external virtual  {
      str_dataAddress[_keyId][_name] = _value;
  }
  function setIntStrString(uint256 _keyId, string memory _name, string memory _value) onlyController override external virtual  {
      str_dataString[_keyId][_name] = _value;
  }
  function setIntStrByte32(uint256 _keyId, string memory _name, bytes32 _value) onlyController override external virtual  {
      str_dataBytes32[_keyId][_name] = _value;
  }
  function setIntStrUint(uint256 _keyId, string memory _name, uint256 _value) onlyController override external virtual  {
      str_dataUint256[_keyId][_name] = _value;
  }
  function setIntStrBool(uint256 _keyId, string memory _name, bool _value) onlyController override external virtual  {
      str_dataBool[_keyId][_name] = _value;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //set int => string => many 
  function setIntStrManyAddress(uint256 _keyId, string memory _name, address _value) onlyController override external  virtual  {
      str_dataManyAddresses[_keyId][_name].push(_value);
  }
  function setIntStrManyString(uint256 _keyId, string memory _name, string memory _value) onlyController override external virtual  {
      str_dataManyStrings[_keyId][_name].push(_value);
  }
  function setIntStrManyByte32(uint256 _keyId, string memory _name, bytes32 _value) onlyController override external virtual  {
      str_dataManyBytes32s[_keyId][_name].push(_value);
  }
  function setIntStrManyUint(uint256 _keyId, string memory _name, uint256 _value) onlyController override external virtual  {
      str_dataManyUint256[_keyId][_name].push(_value);
  }
  function setIntStrManyBool(uint256 _keyId, string memory _name, bool _value)  onlyController override external virtual  {
      str_dataManyBool[_keyId][_name].push(_value);
  }
  
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //get
  
  function getIntAddress(uint256 _keyId) override public view virtual returns(address){
      return intAddress[_keyId];
  }
  
  function getStrAddress(string memory _keyName) override public view virtual returns(address){
      return strAddress[_keyName];
  }
  function getAdrString(address _address)  override public view virtual  returns(string memory){
      return adrString[_address];
  }
  function getAdrByte32(address _address) override public view virtual returns(bytes32) {
      return adrBytes32[_address];
  }
  function getAdrUint(address _address) override public view virtual  returns(uint256){
      return adrUint256[_address];
  }
  function getAdrBool(address _address) override public view virtual  returns(bool){
      return adrBool[_address];
  }
  
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //returns single data
  
  function getIntStrAddress(uint256 _keyId, string memory _keyName) override public view virtual returns(address){
      return str_dataAddress[_keyId][_keyName];
  }
  
  function getIntStrString(uint256 _keyId, string memory _keyName)  override public view virtual  returns(string memory){
      return str_dataString[_keyId][_keyName];
  }
  function getIntStrByte32(uint256 _keyId, string memory _keyName) override public view virtual returns(bytes32) {
      return str_dataBytes32[_keyId][_keyName];
  }
  function getIntStrUint(uint256 _keyId, string memory _keyName) override public view virtual  returns(uint256){
      return str_dataUint256[_keyId][_keyName];
  }
  function getIntStrBool(uint256 _keyId, string memory _keyName) override public view virtual  returns(bool){
      return str_dataBool[_keyId][_keyName];
  }
  
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //returns array
  
  function getIntStrManyAddresses(uint256 _keyId, string memory _keyName) override public view virtual returns(address[] memory){
      return str_dataManyAddresses[_keyId][_keyName];
  }
  
  function getIntStrManyStrings(uint256 _keyId, string memory _keyName)  override public view virtual  returns(string[] memory){
      return str_dataManyStrings[_keyId][_keyName];
  }
  function getIntStrManyByte32(uint256 _keyId, string memory _keyName) override public view virtual returns(bytes32[] memory) {
      return str_dataManyBytes32s[_keyId][_keyName];
  }
  function getIntStrManyUint(uint256 _keyId, string memory _keyName) override public view virtual  returns(uint256[] memory){
      return str_dataManyUint256[_keyId][_keyName];
  }


}