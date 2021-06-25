/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// Sources flattened with hardhat v2.0.11 https://hardhat.org

// File contracts/solidity/testing/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/solidity/util/Ownable.sol



pragma solidity ^0.8.0;

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/solidity/interface/IAdminUpgradeabilityProxy.sol



pragma solidity ^0.8.0;

interface IAdminUpgradeabilityProxy {
    // Read functions.
    function admin() external view returns (address);
    function implementation() external view returns (address);

    // Write functions.
    function changeAdmin(address newAdmin) external;
    function upgradeTo(address newImplementation) external;
}


// File contracts/solidity/proxy/ProxyController.sol



pragma solidity ^0.8.0;


contract ProxyController is Ownable {
    address public vaultFactoryImpl;
    address public eligManagerImpl;
    address public stakingProviderImpl;
    address public stakingImpl;
    address public feeDistribImpl;

    IAdminUpgradeabilityProxy private vaultFactoryProxy;
    IAdminUpgradeabilityProxy private eligManagerProxy;
    IAdminUpgradeabilityProxy private stakingProviderProxy;
    IAdminUpgradeabilityProxy private stakingProxy;
    IAdminUpgradeabilityProxy private feeDistribProxy;

    event ImplAddressSet(uint256 index, address impl);
    event ProxyAdminChanged(uint256 index, address newAdmin);

    constructor(
        address vaultFactory,
        address eligManager,
        address stakingProvider,
        address staking,
        address feeDistrib
    ) {
        vaultFactoryProxy = IAdminUpgradeabilityProxy(vaultFactory);
        eligManagerProxy = IAdminUpgradeabilityProxy(eligManager);
        stakingProviderProxy = IAdminUpgradeabilityProxy(stakingProvider);
        stakingProxy = IAdminUpgradeabilityProxy(staking);
        feeDistribProxy = IAdminUpgradeabilityProxy(feeDistrib);
    }

    function getAdmin(uint256 index) public view returns (address admin) {
        if (index == 0) {
            return vaultFactoryProxy.admin();
        } else if (index == 1) {
            return eligManagerProxy.admin();
        } else if (index == 2) {
            return stakingProviderProxy.admin();
        } else if (index == 3) {
            return stakingProxy.admin();
        } else if (index == 4) {
            return feeDistribProxy.admin();
        }
    }

    function fetchImplAddress(uint256 index) public {
        if (index == 0) {
            vaultFactoryImpl = vaultFactoryProxy.implementation();
            emit ImplAddressSet(0, vaultFactoryImpl);
        } else if (index == 1) {
            eligManagerImpl = eligManagerProxy.implementation();
            emit ImplAddressSet(index, eligManagerImpl);
        } else if (index == 2) {
            stakingProviderImpl = stakingProviderProxy.implementation();
            emit ImplAddressSet(index, stakingProviderImpl);
        } else if (index == 3) {
            stakingImpl = stakingProxy.implementation();
            emit ImplAddressSet(index, stakingImpl);
        } else if (index == 4) {
            feeDistribImpl = feeDistribProxy.implementation();
            emit ImplAddressSet(index, feeDistribImpl);
        }
    }

    function changeAllProxyAdmins(address newAdmin) public onlyOwner {
        changeProxyAdmin(0, newAdmin);
        changeProxyAdmin(1, newAdmin);
        changeProxyAdmin(2, newAdmin);
        changeProxyAdmin(3, newAdmin);
        changeProxyAdmin(4, newAdmin);
    }

    function changeProxyAdmin(uint256 index, address newAdmin)
        public
        onlyOwner
    {
        if (index == 0) {
            vaultFactoryProxy.changeAdmin(newAdmin);
        } else if (index == 1) {
            eligManagerProxy.changeAdmin(newAdmin);
        } else if (index == 2) {
            stakingProviderProxy.changeAdmin(newAdmin);
        } else if (index == 3) {
            stakingProxy.changeAdmin(newAdmin);
        } else if (index == 4) {
            feeDistribProxy.changeAdmin(newAdmin);
        }
        emit ProxyAdminChanged(index, newAdmin);
    }

    function upgradeProxyTo(uint256 index, address newImpl) public onlyOwner {
        if (index == 0) {
            vaultFactoryProxy.upgradeTo(newImpl);
        } else if (index == 1) {
            eligManagerProxy.upgradeTo(newImpl);
        } else if (index == 2) {
            stakingProviderProxy.upgradeTo(newImpl);
        } else if (index == 3) {
            stakingProxy.upgradeTo(newImpl);
        } else if (index == 4) {
            feeDistribProxy.upgradeTo(newImpl);
        }
    }
}