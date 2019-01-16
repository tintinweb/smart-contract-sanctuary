pragma solidity 0.4.24;

interface ISGNAuthorizationManager {
    function isAuthorized(address wallet) external view returns (bool);
}

interface IContractAddressLocator {
    function get(bytes32 interfaceName) external view returns (address);
}

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

interface IAuthorizationDataSource {
    function isAuthorized(address wallet) external view returns (bool);
    function isRestricted(address wallet) external view returns (bool);
    function tradingClass(address wallet) external view returns (uint);
}

contract SGNAuthorizationManager is ISGNAuthorizationManager, ContractAddressLocatorHolder {
    constructor(address contractAddressLocator) ContractAddressLocatorHolder(IContractAddressLocator(contractAddressLocator)) public {}

    function isAuthorized(address wallet) external view returns (bool) {
        IAuthorizationDataSource pAuthorizationDataSource = IAuthorizationDataSource(get("IAuthorizationDataSource"));
        return pAuthorizationDataSource.isAuthorized(wallet) && !pAuthorizationDataSource.isRestricted(wallet);
    }
}