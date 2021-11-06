/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// The MIT License (MIT)
// Copyright (c) 2016-2019 zOS Global Limited
// Copyright (c) 2019-2021 ABC Hosting Ltd.

pragma solidity ^0.4.18;

contract EternalStorage {
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
}

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

contract TokenImplAddress is EternalStorage, UpgradeabilityStorage {}

contract Proxy {
    TokenImplAddress implAddress;

    function getImplementation() public view returns (address) {
        return implAddress.implementation();
    }

    function () payable public {
        address _impl = getImplementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

library SafeMath {}

contract Token is EternalStorage, Proxy {
    using SafeMath for uint256;

    function Token(address impl) public {
        implAddress = TokenImplAddress(impl);
        addressStorage[keccak256("owner")] = msg.sender;
    }
}