pragma solidity ^0.4.23;



contract EternalStorage {

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;

}

pragma solidity ^0.4.23;


contract Proxy {

    function () public payable {
        address _impl = implementation();
        require(_impl != address(0));
        bytes memory data = msg.data;

        assembly {
            let result := delegatecall(gas, _impl, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function implementation() public view returns (address);
}

pragma solidity ^0.4.23;


contract UpgradeabilityStorage {
    string internal _version;

    address internal _implementation;

    function version() public view returns (string) {
        return _version;
    }

    function implementation() public view returns (address) {
        return _implementation;
    }
}

pragma solidity ^0.4.23;



contract UpgradeabilityProxy is Proxy, UpgradeabilityStorage {

    event Upgraded(string version, address indexed implementation);


    function _upgradeTo(string version, address implementation) internal {
        require(_implementation != implementation);
        _version = version;
        _implementation = implementation;
        Upgraded(version, implementation);
    }
}

pragma solidity ^0.4.23;


contract UpgradeabilityOwnerStorage {
    address private _upgradeabilityOwner;

    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }


    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }

}

pragma solidity ^0.4.23;




contract OwnedUpgradeabilityProxy is UpgradeabilityOwnerStorage, UpgradeabilityProxy {

    event ProxyOwnershipTransferred(address previousOwner, address newOwner);


    function OwnedUpgradeabilityProxy(address _owner) public {
        setUpgradeabilityOwner(_owner);
    }


    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }


    function proxyOwner() public view returns (address) {
        return upgradeabilityOwner();
    }


    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0));
        ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }


    function upgradeTo(string version, address implementation) public onlyProxyOwner {
        _upgradeTo(version, implementation);
    }


    function upgradeToAndCall(string version, address implementation, bytes data) payable public onlyProxyOwner {
        upgradeTo(version, implementation);
        require(this.call.value(msg.value)(data));
    }
}

pragma solidity ^0.4.23;



contract EternalStorageProxyForPayinMultisender is OwnedUpgradeabilityProxy, EternalStorage {

    function EternalStorageProxyForPayinMultisender(address _owner) public OwnedUpgradeabilityProxy(_owner) {}

}