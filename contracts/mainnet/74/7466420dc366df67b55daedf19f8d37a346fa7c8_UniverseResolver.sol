// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Context.sol";

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
    constructor () {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

import "../interfaces/Ownable.sol";

interface IVaultCommon {

    function token0() external returns(address);

    function token1() external returns(address);

}

contract UniverseResolver is Ownable {

    /// @dev Status of Universe Vault
    enum Status { unRegistered, working, abandon }

    /// @dev Have been Registered Vault Address
    address[] public vaultLists;
    /// @dev Status of Universe Vault
    mapping(address => Status) private vaultStatus;
    /// @dev Binding Vaults of UniverseVault and otherVault （Same Token0 and Token1）
    mapping(address => mapping(address => bool)) private bindingVault;

    /* ========== VIEW ========== */

    function checkUniverseVault(address universeVault) external view returns(bool status){
        if (vaultStatus[universeVault] == Status.working) {
            status = true;
        }
    }

    /// @dev Check Relationship of two vault
    function checkBindingStatus(address universeVault, address vault) external view returns(bool status){
        if (vaultStatus[universeVault] == Status.working && bindingVault[universeVault][vault]) {
            status = true;
        }
    }

    /// @dev Get All Official Vaults List
    function getAllVaultAddress() external view returns(address[] memory workingVaults) {
        address[] memory vaults = vaultLists;
        uint256 length = vaults.length;
        bool[] memory status = new bool[](length);
        // get abandon Vaults status
        uint256 workNumber;
        for (uint256 i; i < length; i++) {
            if (vaultStatus[vaults[i]] == Status.working) {
                status[i] = true;
                workNumber++;
            }
        }
        if(workNumber > 0){
            // get working vaults list
            workingVaults = new address[](workNumber);
            uint256 idx;
            for (uint256 i; i < length; i++) {
                if (status[i]) {
                    workingVaults[idx] = vaults[i];
                    idx += 1;
                }
            }
        }
    }

    /* ========== INTERNAL ========== */

    function _addVault(address universeVault) internal {
        Status oldStatus = vaultStatus[universeVault];
        if (oldStatus != Status.working) {
            vaultStatus[universeVault] = Status.working;
        }
        if (oldStatus == Status.unRegistered) {
            vaultLists.push(universeVault);
            emit AddVault(universeVault);
        }
    }

    function _removeVault(address universeVault) internal {
        if (vaultStatus[universeVault] == Status.working) {
            vaultStatus[universeVault] = Status.abandon;
            emit RemoveVault(universeVault);
        }
    }

    function _addBinding(address universeVault, address bonding) internal {
        if (!bindingVault[universeVault][bonding]) {
            if (   IVaultCommon(universeVault).token0() == IVaultCommon(bonding).token0()
                && IVaultCommon(universeVault).token1() == IVaultCommon(bonding).token1()
            ){
                bindingVault[universeVault][bonding] = true;
                emit AddBinding(universeVault, bonding);
            }
        }
    }

    function _removeBinding(address universeVault, address bonding) internal {
        bindingVault[universeVault][bonding] = false;
        emit RemoveBinding(universeVault, bonding);
    }

    /* ========== EXTERNAL ========== */

    function addVault(address[] memory universeVaults) external onlyOwner {
        for (uint256 i; i < universeVaults.length; i++) {
            _addVault(universeVaults[i]);
        }
    }

    function removeVault(address[] memory universeVaults) external onlyOwner {
        for (uint256 i; i < universeVaults.length; i++) {
            _removeVault(universeVaults[i]);
        }
    }

    function addBinding(address universeVault, address[] memory bindings) external onlyOwner {
        require(vaultStatus[universeVault] == Status.working, 'universeVault is not Working!');
        for (uint256 i; i < bindings.length; i++) {
            _addBinding(universeVault, bindings[i]);
        }
    }

    function removeBinding(address universeVault, address[] memory bindings) external onlyOwner {
        for (uint256 i; i < bindings.length; i++) {
            _removeBinding(universeVault, bindings[i]);
        }
    }

    /* ========== EVENT ========== */

    /// @dev Add Vault to the Vault List
    event AddVault(address indexed vault);
    /// @dev Set Status From Working to Abandon
    event RemoveVault(address indexed vault);
    /// @dev Binding RelationShip
    event AddBinding(address indexed vault, address bonding);
    /// @dev Remove RelationShip
    event RemoveBinding(address indexed vault, address bonding);

}