pragma solidity 0.4.24;

// File: contracts/registry/interfaces/IContractAddressLocator.sol

interface IContractAddressLocator {
    function get(bytes32 interfaceName) external view returns (address);
}

// File: contracts\registry\ContractAddressLocator.sol

/**
 * @title Contract Address Locator.
 * @dev Map a unique interface name to every contract address in the system.
 * @dev On-chain, this contract is used for retrieving the address of any contract in the system.
 * @dev Off-chain, this contract is used for initializing the mapping between interface names and contract addresses.
 */
contract ContractAddressLocator is IContractAddressLocator {
    event Register(bytes32 indexed interfaceName, address indexed contractAddress);

    mapping(bytes32 => address) private _registry;

    constructor(bytes32[] interfaceNames, address[] contractAddresses) public {
        uint256 length = interfaceNames.length;
        require(length == contractAddresses.length);
        for (uint256 i = 0; i < length; i++) {
            _registry[interfaceNames[i]] = contractAddresses[i];
            emit Register(interfaceNames[i], contractAddresses[i]);
        }
    }

    function get(bytes32 interfaceName) external view returns (address) {
        return _registry[interfaceName];
    }
}