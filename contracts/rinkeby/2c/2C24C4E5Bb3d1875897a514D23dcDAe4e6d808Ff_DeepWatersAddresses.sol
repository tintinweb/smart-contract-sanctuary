/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// File: ../deepwaters/contracts/libraries/Context.sol

pragma solidity ^0.8.10;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: ../deepwaters/contracts/access/Ownable.sol

pragma solidity ^0.8.10;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: ../deepwaters/contracts/interfaces/IDeepWatersAddresses.sol

pragma solidity ^0.8.10;

/**
* @dev Interface for a DeepWatersAddresses contract
**/

interface IDeepWatersAddresses {
    function vaultAddress() external view returns (address);
    function lendingContractAddress() external view returns (address);
    function dataAggregatorAddress() external view returns (address);
    function priceOracleAddress() external view returns (address);
    function liquidatorAddress() external view returns (address);
    function routerAddress() external view returns (address);
    function ethAddress() external view returns (address);
    
    function updateVaultAddress(address _newVaultAddress) external;
    function updateLendingContractAddress(address _newLendingContractAddress) external;
    function updateDataAggregatorAddress(address _newDataAggregatorAddress) external;
    function updatePriceOracleAddress(address _newPriceOracleAddress) external;
    function updateLiquidatorAddress(address _newLiquidatorAddress) external;
    function updateRouterAddress(address _newRouterAddress) external;
    function updateEtherAddress(address _newEthAddress) external;

    function updateAllAddresses(
        address _newVaultAddress,
        address _newLendingContractAddress,
        address _newDataAggregatorAddress,
        address _newPriceOracleAddress,
        address _newLiquidatorAddress,
        address _newRouterAddress,
        address _newEthAddress
    ) external;
}

// File: ../deepwaters/contracts/DeepWatersAddresses.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;



/**
* @title DeepWatersAddresses contract
* @notice Contains current addresses of all DeepWaters contracts.
* @author DeepWaters
**/
contract DeepWatersAddresses is Ownable, IDeepWatersAddresses {
    event LendingContractAddressUpdated(address indexed newAddress);
    event VaultAddressUpdated(address indexed newAddress);
    event DataAggregatorAddressUpdated(address indexed newAddress);
    event PriceOracleAddressUpdated(address indexed newAddress);
    event LiquidatorAddressUpdated(address indexed newAddress);
    event RouterAddressUpdated(address indexed newAddress);
    event EtherAddressUpdated(address indexed newAddress);
    
    event AllAddressesUpdated(
        address indexed _newVaultAddress,
        address indexed _newLendingContractAddress,
        address indexed _newDataAggregatorAddress,
        address _newPriceOracleAddress,
        address _newLiquidatorAddress,
        address _newRouterAddress,
        address _newEthAddress
    );
    
    address public vaultAddress;
    address public lendingContractAddress;
    address public dataAggregatorAddress;
    
    address public priceOracleAddress;
    address public liquidatorAddress;
    address public routerAddress;
    
    // the address used to identify ETH
    address public ethAddress;
    
    constructor(
        address _vaultAddress,
        address _lendingContractAddress,
        address _dataAggregatorAddress,
        address _priceOracleAddress,
        address _liquidatorAddress,
        address _routerAddress,
        address _ethAddress
    ) {
        vaultAddress = _vaultAddress;
        lendingContractAddress = _lendingContractAddress;
        dataAggregatorAddress = _dataAggregatorAddress;
        priceOracleAddress = _priceOracleAddress;
        liquidatorAddress = _liquidatorAddress;
        routerAddress = _routerAddress;
        ethAddress = _ethAddress;
    }
    
    /**
    * @dev updates the DeepWatersVault contract address
    * @param _newVaultAddress the new address of the DeepWatersVault contract
    **/
    function updateVaultAddress(address _newVaultAddress) external onlyOwner {
        vaultAddress = _newVaultAddress;
        emit VaultAddressUpdated(_newVaultAddress);
    }
    
    /**
    * @dev updates the DeepWatersLending contract address
    * @param _newLendingContractAddress the new address of the DeepWatersLending contract
    **/
    function updateLendingContractAddress(address _newLendingContractAddress) external onlyOwner {
        lendingContractAddress = _newLendingContractAddress;
        emit LendingContractAddressUpdated(_newLendingContractAddress);
    }

    /**
    * @dev updates the DeepWatersDataAggregator contract address
    * @param _newDataAggregatorAddress the new address of the DeepWatersDataAggregator contract
    **/
    function updateDataAggregatorAddress(address _newDataAggregatorAddress) external onlyOwner {
        dataAggregatorAddress = _newDataAggregatorAddress;
        emit DataAggregatorAddressUpdated(_newDataAggregatorAddress);
    }
    
    /**
    * @dev updates the DeepWatersPriceOracle contract address
    * @param _newPriceOracleAddress the new address of the DeepWatersPriceOracle contract
    **/
    function updatePriceOracleAddress(address _newPriceOracleAddress) external onlyOwner {
        priceOracleAddress = _newPriceOracleAddress;
        emit PriceOracleAddressUpdated(_newPriceOracleAddress);
    }

    /**
    * @dev updates the liquidator address
    * @param _newLiquidatorAddress the new address of the liquidator
    **/
    function updateLiquidatorAddress(address _newLiquidatorAddress) external onlyOwner {
        liquidatorAddress = _newLiquidatorAddress;
        emit LiquidatorAddressUpdated(_newLiquidatorAddress);
    }

    /**
    * @dev updates the DeepWatersRouter contract address
    * @param _newRouterAddress the new address of the DeepWatersRouter contract
    **/
    function updateRouterAddress(address _newRouterAddress) external onlyOwner {
        routerAddress = _newRouterAddress;
        emit RouterAddressUpdated(_newRouterAddress);
    }

    /**
    * @dev updates the ETH address
    * @param _newEthAddress the new address used to identify ETH
    **/
    function updateEtherAddress(address _newEthAddress) external onlyOwner {
        ethAddress = _newEthAddress;
        emit EtherAddressUpdated(_newEthAddress);
    }
    
    /**
    * @dev updates all addresses
    * @param _newVaultAddress the new address of the DeepWatersVault contract
    * @param _newLendingContractAddress the new address of the DeepWatersLending contract
    * @param _newDataAggregatorAddress the new address of the DeepWatersDataAggregator contract
    * @param _newPriceOracleAddress the new address of the DeepWatersPriceOracle contract
    * @param _newLiquidatorAddress the new address of the liquidator
    * @param _newRouterAddress the new address of the DeepWatersRouter contract
    * @param _newEthAddress the new address used to identify ETH
    **/
    function updateAllAddresses(
        address _newVaultAddress,
        address _newLendingContractAddress,
        address _newDataAggregatorAddress,
        address _newPriceOracleAddress,
        address _newLiquidatorAddress,
        address _newRouterAddress,
        address _newEthAddress
    ) external onlyOwner {
        vaultAddress = _newVaultAddress;
        lendingContractAddress = _newLendingContractAddress;
        dataAggregatorAddress = _newDataAggregatorAddress;
        priceOracleAddress = _newPriceOracleAddress;
        liquidatorAddress = _newLiquidatorAddress;
        routerAddress = _newRouterAddress;
        ethAddress = _newEthAddress;
        
        emit AllAddressesUpdated(
            _newVaultAddress,
            _newLendingContractAddress,
            _newDataAggregatorAddress,
            _newPriceOracleAddress,
            _newLiquidatorAddress,
            _newRouterAddress,
            _newEthAddress
        );
    }
}