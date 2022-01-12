//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BookManager is Ownable {
/*  Smart contract name                   Code 
    Book Factory Contract V1	     ===> BFC_V1
    Book Factory Contract V2	     ===> BFC_V2
    Book Marketplace Contract V1	 ===> BMC_V1
    Book Marketplace Contract V2	 ===> BMC_V2
    NFTBS V1	                     ===> NFTBS_V1             
    NFTBS V2	                     ===> NFTBS_V2
    Book NFT V1	                     ===> BNFT_V1
    Book NFT V2	                     ===> BNFT_V2
*/

    address public deployerAddress;

    mapping(string => address) public marketplaceList;
    mapping(string => address) public factoryList;
    mapping(string => address) public buyTokenList;
    mapping(string => address) public nftList;

    mapping(address => string[]) public marketplaceVersionList;
    mapping(address => string[]) public factoryVersionList;
    mapping(address => string[]) public buyTokenVersionList;
    mapping(address => string[]) public nftVersionList;

    string public currentMarketplaceVersion;
    string public currentFactoryVersion;
    string public currentBuyTokenVersion;
    string public currentNFTVersion;

    function addMarketplaceContract(address _contractAddress, string memory _version) external onlyOwner {
        marketplaceList[_version] = _contractAddress;
        marketplaceVersionList[owner()].push(_version);
    }

    function getMarkeplace(string memory _version) external view returns (address) {
        return marketplaceList[_version];
    }

    function getMarketplaceVersion(address _ownerAddress) public view returns (string[] memory) {
        return marketplaceVersionList[_ownerAddress];
    }

    function setCurrentMarketplaceVersion (string memory _version) external onlyOwner {
        currentMarketplaceVersion = _version;
    }

    function getCurrentMarketplaceVersion () public view returns (string memory) {
        return currentMarketplaceVersion;
    }

    function addFactoryContract(address _contractAddress, string memory _version) external onlyOwner {
        factoryList[_version] = _contractAddress;
        factoryVersionList[owner()].push(_version);
    }

    function getFactory(string memory _version) external view returns (address) {
        return factoryList[_version];
    }

    function getFactoryVersion(address _ownerAddress) public view returns (string[] memory) {
        return factoryVersionList[_ownerAddress];
    }

    function setCurrentFactoryVersion (string memory _version) external onlyOwner {
        currentFactoryVersion = _version;
    }

    function getCurrentFactoryVersion() public view returns (string memory) {
        return currentFactoryVersion;
    }

    function addBuyContract(address _contractAddress, string memory _version) external onlyOwner {
        buyTokenList[_version] = _contractAddress;
        buyTokenVersionList[owner()].push(_version);
    }

    function getBuyToken(string memory _version) external view returns (address) {
        return buyTokenList[_version];
    }

    function getBuyVersion(address _ownerAddress) public view returns (string[] memory) {
        return buyTokenVersionList[_ownerAddress];
    }

    function setCurrentBuyTokenVersion (string memory _version) external onlyOwner {
        currentBuyTokenVersion = _version;
    }

    function getCurrentBuyTokenVersion () public view returns (string memory) {
        return currentBuyTokenVersion;
    }

    function addNFTContract(address _contractAddress, string memory _version) external onlyOwner {
        nftList[_version] = _contractAddress;
        nftVersionList[owner()].push(_version);
    }

    function getNFTContract(string memory _version) external view returns (address) {
        return nftList[_version];
    }

    function getNFTVersion(address _ownerAddress) public view returns (string[] memory) {
        return nftVersionList[_ownerAddress];
    }

    function setCurrentNFTVersion (string memory _version) external onlyOwner {
        currentNFTVersion = _version;
    }

    function getCurrentNFTVersion () public view returns (string memory) {
        return currentNFTVersion;
    }

    function setDeployerAddress(address _deployerAddress) public onlyOwner {
        deployerAddress = _deployerAddress;
    }

    function getDeployerAddress() public view returns(address) {
        return deployerAddress;
    }
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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