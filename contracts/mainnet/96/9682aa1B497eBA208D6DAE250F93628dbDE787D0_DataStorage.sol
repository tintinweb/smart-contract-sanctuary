/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity ^0.4.25;
pragma experimental "v0.5.0";

contract DataStorage {

    //--------------------------------------------------------------------------
    // Storage types, as key => value pairs
    //--------------------------------------------------------------------------
    mapping(bytes32 => uint256)    private uIntStorage;
    mapping(bytes32 => string)     private stringStorage;
    mapping(bytes32 => address)    private addressStorage;
    mapping(bytes32 => bytes)      private bytesStorage;
    mapping(bytes32 => bool)       private booleanStorage;
    mapping(bytes32 => int256)     private intStorage;
    mapping(bytes32 => bytes32)    private bytes32Storage;

    //--------------------------------------------------------------------------
    // modifier regulating access to DataStorage
    //--------------------------------------------------------------------------
    modifier onlyRegisteredContracts() {
        // Once the contract has been initialized, direct access is disabled
        if (booleanStorage[keccak256(abi.encodePacked("storage.init"))]) {
            // Only registered contracts have &#39;write&#39; access from then on
            require(
                //addressStorage[keccak256(abi.encodePacked("contract.address", msg.sender))] == msg.sender
                booleanStorage[keccak256(abi.encodePacked("contract.is.registered", msg.sender))]
            );
        }
        _;
    }
    //--------------------------------------------------------------------------
    // Functions
    //--------------------------------------------------------------------------
    //==============================Set=======================================
    function setUIntValue(bytes32 _key, uint256 _value) external onlyRegisteredContracts {
            uIntStorage[_key] = _value;

    }

    function setStringValue(bytes32 _key, string _value) external onlyRegisteredContracts {
        stringStorage[_key] = _value;
    }

    function setBytesValue(bytes32 _key, bytes _value) external onlyRegisteredContracts {
        bytesStorage[_key] = _value;
    }

    function setBytes32Value(bytes32 _key, bytes32 _value) external onlyRegisteredContracts {
            bytes32Storage[_key] = _value;
    }

    function setAddressValue(bytes32 _key, address _value) external onlyRegisteredContracts {
            addressStorage[_key] = _value;
    }

    function setBooleanValue(bytes32 _key, bool _value) external onlyRegisteredContracts {
            booleanStorage[_key] = _value;
    }

    function setIntValue(bytes32 _key, int _value) external onlyRegisteredContracts {
            intStorage[_key] = _value;
    }

    //============================== Delete =======================================
    function deleteUIntValue(bytes32 _key) external onlyRegisteredContracts {
      delete uIntStorage[_key];
    }


    function deleteStringValue(bytes32 _key) external onlyRegisteredContracts {
          delete stringStorage[_key];
    }

    function deleteAddressValue(bytes32 _key) external onlyRegisteredContracts {
          delete addressStorage[_key];
    }


    function deleteBytesValue(bytes32 _key) external onlyRegisteredContracts {
          delete bytesStorage[_key];
    }


    function deleteBytes32Value(bytes32 _key) external onlyRegisteredContracts {
          delete bytes32Storage[_key];
    }

    function deleteBooleanValue(bytes32 _key) external onlyRegisteredContracts {
          delete booleanStorage[_key];
    }

    function deleteIntValue(bytes32 _key) external onlyRegisteredContracts {
          delete intStorage[_key];
    }

    //============================== Get =======================================
    function getUIntValue(bytes32 _key) external view returns (uint) {
        return uIntStorage[_key];
    }

    function getStringValue(bytes32 _key) external view returns (string) {
        return stringStorage[_key];
    }

    function getAddressValue(bytes32 _key) external view returns (address) {
        return addressStorage[_key];
    }

    function getBytesValue(bytes32 _key) external view returns (bytes) {
        return bytesStorage[_key];
    }

    function getBytes32Value(bytes32 _key) external view returns (bytes32) {
        return bytes32Storage[_key];
    }

    function getBooleanValue(bytes32 _key) external view returns (bool) {
        return booleanStorage[_key];
    }

    function getIntValue(bytes32 _key) external view returns (int) {
        return intStorage[_key];
    }
}