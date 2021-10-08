pragma solidity ^0.7.0;
// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.
contract EternalStorage {

    address owner = msg.sender;
    address latestVersion;

    mapping(bytes32 => uint) uIntStorage;
    mapping(bytes32 => address) addressStorage;

    modifier onlyLatestVersion() {
       require(msg.sender == latestVersion);
        _;
    }

    function upgradeVersion(address _newVersion) public {
        require(msg.sender == owner);
        latestVersion = _newVersion;
    }

    // *** Getter Methods ***
    function getUint(bytes32 _key) external view returns(uint) {
        return uIntStorage[_key];
    }

    function getAddress(bytes32 _key) external view returns(address) {
        return addressStorage[_key];
    }

    // *** Setter Methods ***
    function setUint(bytes32 _key, uint _value) onlyLatestVersion external {
        uIntStorage[_key] = _value;
    }

    function setAddress(bytes32 _key, address _value) onlyLatestVersion external {
        addressStorage[_key] = _value;
    }

    // *** Delete Methods ***
    function deleteUint(bytes32 _key) onlyLatestVersion external {
        delete uIntStorage[_key];
    }

    function deleteAddress(bytes32 _key) onlyLatestVersion external {
        delete addressStorage[_key];
    }
}

contract A{
    function getUserHasVoted(address _eternalStorage) public view returns(address) {
        return EternalStorage(_eternalStorage).getAddress(keccak256(abi.encodePacked("voted",msg.sender)));
    }

    function setUserHasVoted(address _eternalStorage) public {
        EternalStorage(_eternalStorage).setAddress(keccak256(abi.encodePacked("voted",msg.sender)), msg.sender);
    }
}