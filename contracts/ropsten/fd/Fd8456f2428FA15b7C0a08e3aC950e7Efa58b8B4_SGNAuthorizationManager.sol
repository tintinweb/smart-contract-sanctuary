pragma solidity 0.4.24;

// File: contracts/saga-genesis/interfaces/ISGNAuthorizationManager.sol

interface ISGNAuthorizationManager {
    function isAuthorizedToSell(address sender) external view returns (bool);
    function isAuthorizedToTransfer(address sender, address to) external view returns (bool);
    function isAuthorizedToTransferFrom(address sender, address from, address to) external view returns (bool);
}

// File: contracts/registry/interfaces/IContractAddressLocator.sol

interface IContractAddressLocator {
    function get(bytes32 interfaceName) external view returns (address);
}

// File: contracts/registry/ContractAddressLocatorHolder.sol

/**
 * @title Contract Address Locator Holder.
 * @dev Hold a contract address locator, which maps a unique interface name to every contract address in the system.
 * @dev Any contract which inherits from this contract can retrieve the address of any contract in the system.
 * @dev Thus, any contract can remain "oblivious" to the replacement of any other contract in the system.
 * @dev In addition to that, any function in any contract can be restricted to a specific caller.
 */
contract ContractAddressLocatorHolder {
    IContractAddressLocator private _contractAddressLocator;

    constructor(IContractAddressLocator contractAddressLocator) internal {
        require(contractAddressLocator != address(0));
        _contractAddressLocator = contractAddressLocator;
    }

    function getServer() external view returns (IContractAddressLocator) {
        return _contractAddressLocator;
    }

    function get(bytes32 interfaceName) internal view returns (address) {
        return _contractAddressLocator.get(interfaceName);
    }

    modifier only(bytes32 interfaceName) {
        require(msg.sender == get(interfaceName));
        _;
    }
}

// File: contracts/authorization/interfaces/IAuthorizationDataSource.sol

interface IAuthorizationDataSource {
    function isAuthorized(address wallet) external view returns (bool);
    function isRestricted(address wallet) external view returns (bool);
    function tradingClass(address wallet) external view returns (uint);
}

// File: contracts\saga-genesis\SGNAuthorizationManager.sol

contract SGNAuthorizationManager is ISGNAuthorizationManager, ContractAddressLocatorHolder {
    constructor(IContractAddressLocator contractAddressLocator) ContractAddressLocatorHolder(contractAddressLocator) public {}

    function getAuthorizationDataSource() public view returns (IAuthorizationDataSource) {
        return IAuthorizationDataSource(get("IAuthorizationDataSource"));
    }

    function isAuthorizedToSell(address sender) external view returns (bool) {
        IAuthorizationDataSource pAuthorizationDataSource = getAuthorizationDataSource();
        return pAuthorizationDataSource.isAuthorized(sender) && !pAuthorizationDataSource.isRestricted(sender);
    }

    function isAuthorizedToTransfer(address sender, address to) external view returns (bool) {
        IAuthorizationDataSource pAuthorizationDataSource = getAuthorizationDataSource();
        return pAuthorizationDataSource.isAuthorized(sender) && !pAuthorizationDataSource.isRestricted(sender)
            && pAuthorizationDataSource.isAuthorized(to) && !pAuthorizationDataSource.isRestricted(to);
    }

    function isAuthorizedToTransferFrom(address sender, address from, address to) external view returns (bool) {
        IAuthorizationDataSource pAuthorizationDataSource = getAuthorizationDataSource();
        return pAuthorizationDataSource.isAuthorized(sender) && !pAuthorizationDataSource.isRestricted(sender)
            && pAuthorizationDataSource.isAuthorized(from) && !pAuthorizationDataSource.isRestricted(from)
            && pAuthorizationDataSource.isAuthorized(to) && !pAuthorizationDataSource.isRestricted(to);
    }
}