/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
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
            for (uint256 i = 1; i < index + 1; i++) {
                address wallet = indexToWallet[classId][i];
                uint256 tokenId = IMerge(merge).tokenOf(wallet);
                IWallet(wallet).setApprovalForAll();
                IMerge(merge).safeTransferFrom(wallet, target, tokenId);
            }
        }
    }
}