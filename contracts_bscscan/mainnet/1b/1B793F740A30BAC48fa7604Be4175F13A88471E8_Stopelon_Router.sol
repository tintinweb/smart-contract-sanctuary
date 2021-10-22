pragma solidity ^0.8.7;

import * as ownable from "./../commons/Ownable.sol";
import * as whitelist from "./../commons/WhitelistAdminRole.sol";
import * as IERC20Sol from "./../commons/IERC20.sol";
import * as storageInterface from "./../staking/interface/IVault.sol";
import * as stakingInterface from "./../staking/interface/IStaking.sol";
import * as farmingInterface from "./../nft-farm/interface/INFTFarming.sol";
import * as routerInterface from "./interface/IRouter.sol";

contract Stopelon_Router is ownable.Ownable, whitelist.WhitelistAdminRole, routerInterface.IRouter {
    storageInterface.IVault private _vaultImplementation;
    stakingInterface.IStaking private _stakingImplementation;
    farmingInterface.INFTFarming private _farmingImplementation;

    constructor() whitelist.WhitelistAdminRole() ownable.Ownable() {}

    //PUBLIC VIEWS
    function vaultImplementation() external view returns (address) {
        return address(_vaultImplementation);
    }

    function stakingImplementation() external view returns (address) {
        return address(_stakingImplementation);
    }
    
    function nftFarmingImplementation() external view returns (address) {
        return address(_farmingImplementation);
    }

    function rewardProviders() external view returns (address[] memory) {
        uint256 count = 0;
        if (address(_farmingImplementation) != address(0)) count++;
        if (address(_vaultImplementation) != address(0)) count++;
        address[] memory data = new address[](count);
        if (address(_farmingImplementation) != address(0)) data[0] = address(_farmingImplementation);
        if (address(_vaultImplementation) != address(0)) data[data.length - 1] = address(_vaultImplementation);
        return data;
    }

    //PUBLIC FUNCTIONS [ADMIN]
    function assignVault(storageInterface.IVault contractAddress) public onlyWhitelistAdmin {
        require(contractAddress != _vaultImplementation, "Provided contract is the same as current");
        require(address(contractAddress) != address(0), "Provided contract is the empty one");

        _vaultImplementation = contractAddress;
    }

    function assignStaking(stakingInterface.IStaking contractAddress) public onlyWhitelistAdmin {
        require(contractAddress != _stakingImplementation, "Provided contract is the same as current");
        require(address(contractAddress) != address(0), "Provided contract is the empty one");

        _stakingImplementation = contractAddress;
    }

    function assignNftFarming(farmingInterface.INFTFarming contractAddress) public onlyWhitelistAdmin {
        require(contractAddress != _farmingImplementation, "Provided contract is the same as current");
        require(address(contractAddress) != address(0), "Provided contract is the empty one");

        _farmingImplementation = contractAddress;
    }

    function vaultSync(address account) external {
        require(msg.sender == address(_vaultImplementation), "Only current Vault can call for syncronisation!");

	    if (address(_stakingImplementation) != address(0)) { 
            if (_stakingImplementation.roundCanBeIncremented())
                _stakingImplementation.incrementRound();
            if (_stakingImplementation.getLastClaimedRound(account) < _stakingImplementation.currentRound())
                _stakingImplementation.claimPendingReflectionsFor(account);
	    }
        if (address(_farmingImplementation) != address(0)) { 
            _farmingImplementation.updatePointsFor(account);
	    }
    }

    
}

pragma solidity ^0.8.7;

interface IRouter {
    function vaultImplementation() external view returns (address);
    function stakingImplementation() external view returns (address);
    function nftFarmingImplementation() external view returns (address);
    function rewardProviders() external view returns (address[] memory);

    function vaultSync(address account) external;
}

pragma solidity ^0.8.7;

import * as balanceOf from "./../../commons/IBalanceOfContract.sol";
import * as rewards from "./IPendingRewardProvider.sol";
interface IVault is balanceOf.IBalanceOfContract, rewards.IPendingRewardProvider {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function lock(uint256 amount, uint256 rounds) external;

    function totalSupply() external view returns (uint256);

    function vaultSharesOf(address account) external view returns (uint256);
    function totalVaultShares() external view returns (uint256);
}

pragma solidity ^0.8.7;

interface IStaking {
    function roundCanBeIncremented() external view returns (bool); 
    function incrementRound() external;
    function currentRound() external view returns (uint256);

    function getLastClaimedRound(address token) external view returns (uint256);
    function pendingReflections(address token, address account) external view returns (uint256);
    function claimPendingReflectionsFor(address account) external;
}

pragma solidity ^0.8.7;

interface IPendingRewardProvider {
    function getRewardTokens() external view returns(address[] memory);
    function getPendingRewards(address rewardToken, address receiver) external view returns(uint256);
    function withdrawTokenRewards(address rewardToken) external;
}

pragma solidity ^0.8.7;

import * as rewards from "./../../staking/interface/IPendingRewardProvider.sol";
interface INFTFarming is rewards.IPendingRewardProvider {    
    function updatePointsFor(address account) external;
}

pragma solidity ^0.8.7;

import * as context from "./Context.sol";
import * as roles from "./Roles.sol";

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
abstract contract WhitelistAdminRole is context.Context {
    using roles.Roles for roles.Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    roles.Roles.Role private _whitelistAdmins;

    function initWhiteListAdmin() internal{
        _addWhitelistAdmin(_msgSender());
    }

    constructor () {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

pragma solidity ^0.8.7;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity ^0.8.7;

import * as context from "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is context.Context {
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

pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IBalanceOfContract {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

pragma solidity ^0.8.7;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}