pragma solidity 0.4.24;

// File: contracts/saga-genesis/interfaces/IMintManager.sol

interface IMintManager {
    function getIndex() external view returns (uint256);
}

// File: contracts/saga-genesis/interfaces/ISGNTokenManager.sol

interface ISGNTokenManager {
    function convertSgnToSga(uint256 sgnAmount) external view returns (uint256);
    function exchangeSgnForSga(address sender, uint256 sgnAmount) external returns (uint256);
    function uponTransfer(address sender, address to, uint256 value) external;
    function uponTransferFrom(address sender, address from, address to, uint256 value) external;
}

// File: contracts/saga-genesis/interfaces/IConversionManager.sol

interface IConversionManager {
    function sgn2sga(uint256 amount, uint256 index) external view returns (uint256);
}

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

// File: contracts\saga-genesis\SGNTokenManager.sol

contract SGNTokenManager is ISGNTokenManager, ContractAddressLocatorHolder {

    constructor(IContractAddressLocator contractAddressLocator) ContractAddressLocatorHolder(contractAddressLocator) public {}

    function getSGNAuthorizationManager() public view returns (ISGNAuthorizationManager) {
        return ISGNAuthorizationManager(get("ISGNAuthorizationManager"));
    }

    function getConversionManager() public view returns (IConversionManager) {
        return IConversionManager(get("IConversionManager"));
    }

    function getMintManager() public view returns (IMintManager) {
        return IMintManager(get("IMintManager"));
    }

    /**
     * @dev Get the current SGA worth of a given SGN amount.
     * @param sgnAmount The amount of SGN to convert.
     * @return The equivalent amount of SGA.
     */
    function convertSgnToSga(uint256 sgnAmount) external view returns (uint256) {
        return _convertSgnToSga(sgnAmount);
    }

    /**
     * @dev Exchange SGN for SGA.
     * @param sender The address of the sender.
     * @param sgnAmount The amount of SGN received.
     * @return The amount of SGA that the sender is entitled to.
     */
    function exchangeSgnForSga(address sender, uint256 sgnAmount) external only("ISGNToken") returns (uint256) {
        require(getSGNAuthorizationManager().isAuthorizedToSell(sender));
        uint256 sgaAmount = _convertSgnToSga(sgnAmount);
        require(sgaAmount > 0);
        return sgaAmount;
    }

    /**
     * @dev Handle direct SGN transfer.
     * @param sender The address of the sender.
     * @param to The address of the destination account.
     * @param value The amount of SGN to be transferred.
     */
    function uponTransfer(address sender, address to, uint256 value) external only("ISGNToken") {
        require(getSGNAuthorizationManager().isAuthorizedToTransfer(sender, to));
        value;
    }

    /**
     * @dev Handle custodian SGN transfer.
     * @param sender The address of the sender.
     * @param from The address of the source account.
     * @param to The address of the destination account.
     * @param value The amount of SGN to be transferred.
     */
    function uponTransferFrom(address sender, address from, address to, uint256 value) external only("ISGNToken") {
        require(getSGNAuthorizationManager().isAuthorizedToTransferFrom(sender, from, to));
        value;
    }

    /**
     * @dev Compute the current SGA worth of a given SGN amount.
     * @param sgnAmount The amount of SGN to convert.
     * @return The equivalent amount of SGA.
     */
    function _convertSgnToSga(uint256 sgnAmount) private view returns (uint256) {
        return getConversionManager().sgn2sga(sgnAmount, getMintManager().getIndex());
    }
}