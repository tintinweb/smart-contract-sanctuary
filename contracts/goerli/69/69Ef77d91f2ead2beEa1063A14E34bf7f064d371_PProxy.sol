pragma solidity ^0.7.1;

import "./PProxyStorage.sol";

contract PProxy is PProxyStorage {

    bytes32 constant IMPLEMENTATION_SLOT = keccak256(abi.encodePacked("IMPLEMENTATION_SLOT"));
    bytes32 constant OWNER_SLOT = keccak256(abi.encodePacked("OWNER_SLOT"));

    modifier onlyProxyOwner() {
        require(msg.sender == readAddress(OWNER_SLOT), "PProxy.onlyProxyOwner: msg sender not owner");
        _;
    }

    constructor () public {
        setAddress(OWNER_SLOT, msg.sender);
    }

    function getProxyOwner() public view returns (address) {
       return readAddress(OWNER_SLOT);
    }

    function setProxyOwner(address _newOwner) onlyProxyOwner public {
        setAddress(OWNER_SLOT, _newOwner);
    }

    function getImplementation() public view returns (address) {
        return readAddress(IMPLEMENTATION_SLOT);
    }

    function setImplementation(address _newImplementation) onlyProxyOwner public {
        setAddress(IMPLEMENTATION_SLOT, _newImplementation);
    }


    fallback () external payable {
       return internalFallback();
    }

    function internalFallback() internal virtual {
        address contractAddr = readAddress(IMPLEMENTATION_SLOT);
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), contractAddr, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

}

pragma solidity ^0.7.1;

contract PProxyStorage {

    function readBool(bytes32 _key) public view returns(bool) {
        return storageRead(_key) == bytes32(uint256(1));
    }

    function setBool(bytes32 _key, bool _value) internal {
        if(_value) {
            storageSet(_key, bytes32(uint256(1)));
        } else {
            storageSet(_key, bytes32(uint256(0)));
        }
    }

    function readAddress(bytes32 _key) public view returns(address) {
        return bytes32ToAddress(storageRead(_key));
    }

    function setAddress(bytes32 _key, address _value) internal {
        storageSet(_key, addressToBytes32(_value));
    }

    function storageRead(bytes32 _key) public view returns(bytes32) {
        bytes32 value;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            value := sload(_key)
        }
        return value;
    }

    function storageSet(bytes32 _key, bytes32 _value) internal {
        // targetAddress = _address;  // No!
        bytes32 implAddressStorageKey = _key;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            sstore(implAddressStorageKey, _value)
        }
    }

    function bytes32ToAddress(bytes32 _value) public pure returns(address) {
        return address(uint160(uint256(_value)));
    }

    function addressToBytes32(address _value) public pure returns(bytes32) {
        return bytes32(uint256(_value));
    }

}

