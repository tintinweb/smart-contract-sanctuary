/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.2;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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


contract VaultRegistry is Ownable {
    /// @dev Register vaults that can withdraw for free to each other
    /// mapping(fromVault => mapping(toVault => true/false))
    mapping(address => mapping(address => bool)) public canWithdrawForFree;

    /// @dev Register vaults that can trade with each other
    /// mapping(longVault => mapping(shortVault => true/false))
    mapping(address => mapping(address => bool)) public canCrossTrade;

    event RegisterWithdrawal(address fromVault, address toVault);

    event RevokeWithdrawal(address fromVault, address toVault);

    event RegisterCrossTrade(address longVault, address shortVault);

    event RevokeCrossTrade(address longVault, address shortVault);

    /**
     * @notice Register vaults that can withdraw to each other for free
     * @param fromVault is the vault to withdraw from
     * @param toVault is the vault to withdraw to
     */
    function registerFreeWithdrawal(address fromVault, address toVault)
        external
        onlyOwner
    {
        canWithdrawForFree[fromVault][toVault] = true;
        emit RegisterWithdrawal(fromVault, toVault);
    }

    /**
     * @notice Revoke withdrawal access between vaults
     * @param fromVault is the vault to withdraw from
     * @param toVault is the vault to withdraw to
     */
    function revokeFreeWithdrawal(address fromVault, address toVault)
        external
        onlyOwner
    {
        canWithdrawForFree[fromVault][toVault] = false;
        emit RevokeWithdrawal(fromVault, toVault);
    }

    /**
     * @notice Register vaults that can trade options with each other
     * @param longVault is the vault that is buying options
     * @param shortVault is the vault that is selling options
     */
    function registerCrossTrade(address longVault, address shortVault)
        external
        onlyOwner
    {
        canCrossTrade[longVault][shortVault] = true;
        emit RegisterCrossTrade(longVault, shortVault);
    }

    /**
     * @notice Revoke trading access between vaults
     * @param longVault is the vault that is buying options
     * @param shortVault is the vault that is selling options
     */
    function revokeCrossTrade(address longVault, address shortVault)
        external
        onlyOwner
    {
        canCrossTrade[longVault][shortVault] = false;
        emit RevokeCrossTrade(longVault, shortVault);
    }
}