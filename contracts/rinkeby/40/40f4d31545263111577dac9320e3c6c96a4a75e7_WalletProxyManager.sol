/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

interface IMerge {
    function tokenOf(address account) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IWallet {
    function setApprovalForAll() external;
}

contract WalletProxyManager is Ownable {

    address public walletProxyFactory;
    address public DAO;
    address public merge;
    uint256 private constant MAX_NUM_OF_WALLETS = 25;

    mapping(address => uint256) public classes;  // Find class given address
    mapping(uint256 => uint256) public currentIndex;  // Find the current index of a class
    mapping(uint256 => mapping(uint256 => address)) public indexToWallet;  // Find the wallet given the current index

    /**
     * @dev Sets `DAO_` and `merge_` smart contract addresses.
     */
    constructor(address DAO_, address merge_) {
        require(DAO_ != address(0), "Invalid address");
        require(merge_ != address(0), "Invalid address");
        DAO = DAO_;
        merge = merge_;
    }

    /**
     * @dev Sets the `walletProxyFactory_` smart contract.
     */
    function init(address walletProxyFactory_) public onlyOwner {
        require(walletProxyFactory_ != address(0), "Invalid address");
        walletProxyFactory = walletProxyFactory_;
    }

    /**
     * @dev A modifier only allows the access by factory contract
     */
    modifier onlyFactory {
        require(_msgSender() == walletProxyFactory, "Invalid caller");
        _;
    }

    /**
     * @dev A modifier only allows the access by DAO
     */
    modifier onlyDAO {
        require(_msgSender() == DAO, "Invalid caller");
        _;
    }

    /**
     * @dev Sets the wallet address `wallet` for a given `classId`.
     */
    function setWallet(uint256 classId, address wallet) public onlyFactory {
        require(classId < 100, "invalid class");
        if (indexToWallet[classId][0] == address(0)) {
            classes[wallet] = classId;
            indexToWallet[classId][0] = wallet;
        } else {
            uint256 index = currentIndex[classId];
            index++;
            indexToWallet[classId][index] = wallet;
            currentIndex[classId] = index;
            classes[wallet] = classId;
        }
    }

    /**
     * @dev Merges NFTs across multiple wallets for the same class with `classId`.
     */
    function mergeNFTsByClass(uint256 classId) public onlyDAO {
        require(classId < 100, "invalid class");
        uint256 index = currentIndex[classId];
        if (index != 0) {
            address target = indexToWallet[classId][0];
            address wallet;
            uint256 tokenId;
            for (uint256 i = 1; i < index + 1; i++) {
                wallet = indexToWallet[classId][i];
                tokenId = IMerge(merge).tokenOf(wallet);
                if (tokenId != 0) {
                    IWallet(wallet).setApprovalForAll();
                    IMerge(merge).safeTransferFrom(wallet, target, tokenId);
                }
            }
        }
    }

    /**
     * @dev Merges NFTs across multiple wallets that are not necessarily for the
     * same class to the `target` address.
     */
    function mergeNFTsByWallets(address[] calldata wallets, address target) public onlyDAO {
        uint256 nWallets = wallets.length;
        require(nWallets <= MAX_NUM_OF_WALLETS, "Exceeding the limit");
        address wallet;
        uint256 tokenId;
        for (uint256 i = 0; i < nWallets; i++) {
            wallet = wallets[i];
            tokenId = IMerge(merge).tokenOf(wallet);
            if (tokenId != 0) {
                IWallet(wallet).setApprovalForAll();
                IMerge(merge).safeTransferFrom(wallet, target, tokenId);
            }
        }
    }
}