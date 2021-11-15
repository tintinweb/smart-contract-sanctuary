// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OpenApeRegistry {

    mapping(address => bool) public isRegistered;

    struct RegisteredAddresses {
        uint count;
        mapping(uint => address) registeredAddress;
    }
    RegisteredAddresses Registry;

    event NativeRegistration(address _deployer, address _contract);
    event ExternalRegistration(address _deployer, address _contract);

    function nativeRegister(address _deployer, address _contract) internal {
        Registry.registeredAddress[Registry.count] = _contract;
        Registry.count += 1;

        isRegistered[_contract] = true;

        emit NativeRegistration(_deployer, _contract);
    }

    function externalRegister(address _deployer, address _contract) external {
        Registry.registeredAddress[Registry.count] = _contract;
        Registry.count += 1;

        isRegistered[_contract] = true;

        emit ExternalRegistration(_deployer, _contract);
    }

    function deployNFT(bytes memory code, uint256 salt) public {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        nativeRegister(msg.sender, addr);  
    }

}

