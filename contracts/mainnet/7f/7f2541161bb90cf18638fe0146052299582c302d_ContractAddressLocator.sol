pragma solidity 0.4.25;

// File: contracts/contract_address_locator/interfaces/IContractAddressLocator.sol

/**
 * @title Contract Address Locator Interface.
 */
interface IContractAddressLocator {
    /**
     * @dev Get the contract address mapped to a given identifier.
     * @param _identifier The identifier.
     * @return The contract address.
     */
    function getContractAddress(bytes32 _identifier) external view returns (address);

    /**
     * @dev Determine whether or not a contract address relates to one of the identifiers.
     * @param _contractAddress The contract address to look for.
     * @param _identifiers The identifiers.
     * @return A boolean indicating if the contract address relates to one of the identifiers.
     */
    function isContractAddressRelates(address _contractAddress, bytes32[] _identifiers) external view returns (bool);
}

// File: contracts/contract_address_locator/ContractAddressLocator.sol

/**
 * Details of usage of licenced software see here: https://www.sogur.com/software/readme_v1
 */

/**
 * @title Contract Address Locator.
 * @dev Map a unique identifier to every contract address in the system.
 * @dev On-chain, this contract is used for retrieving the address of any contract in the system.
 * @dev Off-chain, this contract is used for initializing the mapping between identifiers and contract addresses.
 */
contract ContractAddressLocator is IContractAddressLocator {
    string public constant VERSION = "1.0.0";

    uint256 identifiersCount;

    mapping(bytes32 => address) private contractAddresses;

    event Mapped(bytes32 indexed _identifier, address indexed _contractAddress);

    /**
     * @dev Create the contract.
     * @param _identifiers A list of identifiers.
     * @param _contractAddresses A list of contract addresses.
     * @notice This contract is designated to be deployed every time the system is upgraded.
     * @notice Deployment will fail if the length of the lists yields gas requirement larger than the block gas-limit.
     * @notice However, there is no point in setting a restriction on the length of the lists in order to prevent this scenario.
     * @notice Instead, if such scenario is ever encountered, this function will need to be adjusted in order to allow its execution.
     */
    constructor(bytes32[] memory _identifiers, address[] _contractAddresses) public {
        identifiersCount = _identifiers.length;
        require(identifiersCount == _contractAddresses.length, "list lengths are not equal");
        for (uint256 i = 0; i < identifiersCount; i++) {
            require(uint256(contractAddresses[_identifiers[i]]) == 0, "identifiers are not unique");
            contractAddresses[_identifiers[i]] = _contractAddresses[i];
            emit Mapped(_identifiers[i], _contractAddresses[i]);
        }
    }

    /**
     * @dev Get the contract address mapped to a given identifier.
     * @param _identifier The identifier.
     * @return The contract address.
     */
    function getContractAddress(bytes32 _identifier) external view returns (address) {
        return contractAddresses[_identifier];
    }

    /**
     * @dev Determine whether or not a contract address relates to one of the identifiers.
     * @param _contractAddress The contract address to look for.
     * @param _identifiers The identifiers.
     * @return A boolean indicating if the contract address relates to one of the identifiers.
     */
    function isContractAddressRelates(address _contractAddress, bytes32[] _identifiers) external view returns (bool){
        assert(_contractAddress != address(0));
        uint256 _identifiersCount = _identifiers.length;
        require(_identifiersCount <= identifiersCount, "cannot be more than actual identifiers count");
        bool isRelate = false;
        for (uint256 i = 0; i < _identifiersCount; i++) {
            if (_contractAddress == contractAddresses[_identifiers[i]]) {
                isRelate = true;
                break;
            }
        }
        return isRelate;
    }

}