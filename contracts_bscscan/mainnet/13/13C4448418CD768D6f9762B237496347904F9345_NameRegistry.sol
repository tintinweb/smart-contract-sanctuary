pragma solidity ^0.5.15;

contract NameRegistry {
    struct ContractDetails {
        // registered contract address
        address contractAddress;
    }
    event RegisteredNewContract(bytes32 name, address contractAddr);
    mapping(bytes32 => ContractDetails) registry;

    function registerName(bytes32 name, address addr) external returns (bool) {
        ContractDetails memory info = registry[name];
        // create info if it doesn't exist in the registry
        if (info.contractAddress == address(0)) {
            info.contractAddress = addr;
            registry[name] = info;
            // added to registry
            return true;
        } else {
            // already was registered
            return false;
        }
    }

    function getContractDetails(bytes32 name) external view returns (address) {
        return (registry[name].contractAddress);
    }

    function updateContractDetails(bytes32 name, address addr) external {
        // TODO not sure if we should do this
        // If we do we need a plan on how to remove this
    }
}

