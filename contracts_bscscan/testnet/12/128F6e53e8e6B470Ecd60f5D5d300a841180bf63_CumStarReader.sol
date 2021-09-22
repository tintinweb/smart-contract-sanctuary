/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

// File: contracts/src/libs/Context.sol


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

// File: contracts/src/libs/Ownable.sol



pragma solidity ^0.8.7;


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

// File: contracts/src/utility/Ownable/WorkerOwnable.sol



pragma solidity ^0.8.7;


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
abstract contract WorkerOwnable is Ownable {
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {}
}

// File: contracts/src/model/CumStarNFTToken/CumStarNFTTokenModel.sol

/**
 *Submitted for verification at BscScan.com on
*/


pragma solidity ^0.8.7;

interface CumStarNFTTokenModel {
    struct Token {
        uint256 tokenId;
        address owner;
    }
}

// File: contracts/src/token/CumStarNFTToken/CumStarNFTTokenInterface.sol

/**
 *Submitted for verification at BscScan.com on
*/


pragma solidity ^0.8.7;


interface CumStarNFTTokenInterface {
    function mint(address tokenOwner, string memory tokenUri) external returns (uint256);
    function getNextTokenId() external returns (uint256);
}

interface CumStarNFTTokenStateInterface is CumStarNFTTokenModel {
    function getNextTokenId() external returns (uint256);
    function tokenTransferFrom(address from, address to, uint256 tokenId) external;
    function mintToken(address owner, string memory tokenUri) external returns (uint256);
    function addNewNFTState(Token memory token) external;
}

// File: contracts/src/model/PayableUserToken/PayableUserTokenModel.sol

/**
 *Submitted for verification at BscScan.com on
*/


pragma solidity ^0.8.7;

interface PayableUserTokenModel {
    struct PayableUserToken {
        uint256 cumStarNFTTokenId;
        address owner;
        uint256 tokenId;
        bool used;
    }
}

// File: contracts/src/token/PayableUserToken/PayableUserTokenInterface.sol

/**
 *Submitted for verification at BscScan.com on
*/


pragma solidity ^0.8.7;


interface PayableUserTokenInterface is PayableUserTokenModel{
    function mint(address artistAddress, uint256 cumStarNFTTokenId) external;
    function useToken(uint256 tokenId, address tokenOwner) external;
    function getPayableTokens(address userAddress) external view returns (PayableUserToken[] memory);
}

interface PayableTokenStateInterface is PayableUserTokenModel{
    function getNextTokenId() external returns (uint256);
    function addTokenToState(PayableUserToken memory payableUserToken) external;
    function useToken(uint256 tokenId, address tokenOwner) external;
    function getUserPayableTokens(address userAddress) external view returns (PayableUserToken[] memory);
}

// File: contracts/src/model/UserProfileToken/UserProfileTokenModel.sol

/**
 *Submitted for verification at BscScan.com on
*/


pragma solidity ^0.8.7;

interface UserProfileTokenModel {
    struct ProfileToken {
        uint256 cumStarNFTTokenId;
        uint256 tokenId;
        string username;
        address owner;
        uint256 userType;
    }
}

// File: contracts/src/token/UserProfileToken/UserProfileTokenInterface.sol

/**
 *Submitted for verification at BscScan.com on
*/


pragma solidity ^0.8.7;


interface UserProfileTokenInterface is UserProfileTokenModel {
    function deleteUserProfile(address userAddress, uint256 tokenId) external;
    function mintArtist(address artistAddress, string memory username, uint256 cumStarNFTTokenId) external;
    function mintCustomer(address customerAddress, string memory username, uint256 cumStarNFTTokenId) external;
    function getUserProfile(address userAddress, uint256 userProfileId) external view returns (ProfileToken memory);
    function getUserProfiles(address userAddress) external view returns (ProfileToken[] memory);
    function getProfiles(uint256 userType) external view returns (ProfileToken[] memory);
    function checkIfCustomerExist(address customerAddress) external;
}

interface TokenStateInterface is UserProfileTokenModel {
    function getNextTokenId() external returns (uint256);
    function deleteUserProfile(address userAddress, uint256 tokenId) external;
    function addTokenToState(ProfileToken memory profileToken) external;
    function getUserProfiles(address ownerAddress) external view returns (ProfileToken[] memory);
    function getProfiles(uint256 userType) external view returns (ProfileToken[] memory);
}

// File: contracts/src/model/ArtistToken/ArtistTokenModel.sol

/**
 *Submitted for verification at BscScan.com on
*/


pragma solidity ^0.8.7;

interface ArtistTokenModel {
    struct ArtistSingleToken {
        uint256 cumStarNFTTokenId;
        uint256 tokenId;
        uint256 userProfileId;
        address owner;
        address creator;
        uint256 creatorFee;
        string name;
        string description;
        string category;
        uint256 price;
        bool deposited;
        uint256 likes;
        uint256 disLikes;
    }

    struct ArtistSingleTokenFee {
        address feeAddress;
        uint256 feePercentage;
    }

    struct TokenCategory {
        uint256 categoryId;
        string categoryName;
    }
}

// File: contracts/src/token/ArtistToken/ArtistTokenInterface.sol

/**
 *Submitted for verification at BscScan.com on
*/


pragma solidity ^0.8.7;


interface ArtistTokenInterface is ArtistTokenModel {
    function mintArtistToken(
        address artistAddress,
        uint256 userProfileId,
        uint256 artistFee,
        uint256 cumStarNFTTokenId,
        string memory name,
        string memory description,
        uint256 categoryId
    ) external;
    function getArtistToken(uint256 tokenId) external returns (ArtistSingleToken memory);
    function getArtistSingleTokens(address ownerAddress, uint256 ownerProfileId) external returns (ArtistSingleToken[] memory);
    function getArtistsSingleTokens() external returns (ArtistSingleToken[] memory);
    function depositToken(uint256 tokenId, address ownerAddress, uint256 price) external;
    function getDepositedArtistToken(uint256 tokenId) external returns (ArtistSingleToken memory);
    function getDepositedArtistTokens(address ownerAddress, uint256 ownerProfileId) external returns (ArtistSingleToken[] memory);
    function getDepositedArtistsTokens() external returns (ArtistSingleToken[] memory);
    function withdrawToken(uint256 tokenId, address ownerAddress) external;
    function transferToken(address to, uint256 newUserProfileId, uint256 tokenId) external;
    function addFee(address feeAddress, uint256 feePercentage) external;
    function removeFee(address feeAddress) external;
    function getTokenFees(uint256 tokenId) external view returns (ArtistSingleTokenFee[] memory);
    function getFee(address feeAddress) external view returns (uint256);
    function getFees() external view returns (ArtistSingleTokenFee[] memory);
    function addCategory(string memory categoryName) external;
    function removeCategory(uint256 categoryId) external;
    function getCategory(uint256 categoryId) external view returns (TokenCategory memory);
    function getCategories() external view returns (TokenCategory[] memory);
}

interface ArtistTokenStateInterface is ArtistTokenModel {
    function getNextTokenId() external returns (uint256);
    function getNextCategoryId() external returns (uint256);
    function getArtistToken(uint256 tokenId) external returns (ArtistSingleToken memory);
    function addTokenToState(ArtistSingleToken memory artistSingleToken) external;
    function getArtistSingleTokens(address ownerAddress, uint256 ownerProfileId) external returns (ArtistSingleToken[] memory);
    function getArtistsSingleTokens() external returns (ArtistSingleToken[] memory);
    function depositToken(uint256 tokenId, address ownerAddress, uint256 price) external;
    function getDepositedArtistToken(uint256 tokenId) external returns (ArtistSingleToken memory);
    function getDepositedArtistTokens(address ownerAddress, uint256 ownerProfileId) external returns (ArtistSingleToken[] memory);
    function getDepositedArtistsTokens() external returns (ArtistSingleToken[] memory);
    function withdrawToken(uint256 tokenId, address ownerAddress) external;
    function transferToken(address to, uint256 newUserProfileId, uint256 tokenId) external;
    function addFee(ArtistSingleTokenFee memory tokenFee) external;
    function removeFee(address feeAddress) external;
    function getTokenFees(uint256 tokenId) external view returns (ArtistSingleTokenFee[] memory);
    function getFee(address feeAddress) external view returns (uint256);
    function getFees() external view returns (ArtistSingleTokenFee[] memory);
    function addCategory(TokenCategory memory tokenCategory) external;
    function removeCategory(uint256 categoryId) external;
    function getCategory(uint256 categoryId) external view returns (TokenCategory memory);
    function getCategories() external view returns (TokenCategory[] memory);
}

// File: contracts/src/utility/InterfaceRegistry.sol

/**
 *Submitted for verification at BscScan.com on
*/







pragma solidity ^0.8.7;

abstract contract InterfaceRegistry is
    CumStarNFTTokenInterface,
    PayableUserTokenInterface,
    UserProfileTokenInterface,
    ArtistTokenInterface
{

}

// File: contracts/src/external/CumStar/CumStarTokenExternalInterface.sol

/**
 *Submitted for verification at BscScan.com on
*/



pragma solidity ^0.8.7;

interface CumStarTokenExternalInterface {
    function balanceOf(address userAddress) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external;
    function getMinBalance() external view returns (uint256);
    function setMinBalance(uint256 customerMinCumStarBalance) external;
}

interface CumStarTokenStateInterface {
    function getMinBalance() external view returns (uint256);
    function setMinBalance(uint256 customerMinCumStarBalance) external;
}

interface CumStarPayableTokenStateInterface {
    function transferFrom(address from, address to, uint256 amount) external;
}

// File: contracts/src/utility/ExternalInterfaceRegistry.sol

/**
 *Submitted for verification at BscScan.com on
*/




pragma solidity ^0.8.7;


abstract contract ExternalInterfaceRegistry is
    CumStarTokenExternalInterface
{
}

// File: contracts/src/utility/ModelRegistry.sol

/**
 *Submitted for verification at BscScan.com on
*/






pragma solidity ^0.8.7;

abstract contract ModelRegistry is
UserProfileTokenModel,
PayableUserTokenModel,
ArtistTokenModel
{
}

// File: contracts/src/worker/CumStarReader.sol

/**
 *Submitted for verification at BscScan.com on
*/



pragma solidity ^0.8.7;





contract CumStarReader is WorkerOwnable, ModelRegistry {
    address _userProfileTokenContractAddress;
    address _payableUserTokenContractAddress;
    address _externalCumStarContractAddress;
    address _artistTokenContractAddress;

    constructor (
        address userProfileTokenContractAddress_,
        address payableUserTokenContractAddress_,
        address externalCumStarContractAddress_,
        address artistTokenContractAddress_
    ) {
        _userProfileTokenContractAddress = userProfileTokenContractAddress_;
        _payableUserTokenContractAddress = payableUserTokenContractAddress_;
        _externalCumStarContractAddress = externalCumStarContractAddress_;
        _artistTokenContractAddress = artistTokenContractAddress_;
    }

    function getUserProfiles(address userAddress) external view returns (ProfileToken[] memory) {
        require(userAddress != address(0), "Ownable: User address is the zero address");

        return UserProfileTokenInterface(_userProfileTokenContractAddress).getUserProfiles(userAddress);
    }

    function getPayableUserTokens(address userAddress) external view returns (PayableUserToken[] memory) {
        require(userAddress != address(0), "Ownable: User address is the zero address");

        return PayableUserTokenInterface(_payableUserTokenContractAddress).getPayableTokens(userAddress);
    }

    function getProfiles(uint256 userType) external view returns (ProfileToken[] memory) {
        return UserProfileTokenInterface(_userProfileTokenContractAddress).getProfiles(userType);
    }

    function getMinBalanceOfCumStar() external view returns (uint256) {
        return CumStarTokenExternalInterface(_externalCumStarContractAddress).getMinBalance();
    }

    function getDepositedArtistTokens(address ownerAddress, uint256 ownerProfileId) external returns (ArtistSingleToken[] memory){
        return ArtistTokenInterface(_artistTokenContractAddress).getDepositedArtistTokens(ownerAddress, ownerProfileId);
    }

    function getDepositedArtistsTokens() external returns (ArtistSingleToken[] memory){
        return ArtistTokenInterface(_artistTokenContractAddress).getDepositedArtistsTokens();
    }

    function getArtistSingleTokens(address ownerAddress, uint256 ownerProfileId) external returns (ArtistSingleToken[] memory) {
        require(ownerAddress != address(0), "Ownable: owner address is the zero address");
        return ArtistTokenInterface(_artistTokenContractAddress).getArtistSingleTokens(ownerAddress, ownerProfileId);
    }

    function getArtistsSingleTokens() external returns (ArtistSingleToken[] memory) {
        return ArtistTokenInterface(_artistTokenContractAddress).getArtistsSingleTokens();
    }

    function getFee(address feeAddress) external view returns (uint256) {
        require(feeAddress != address(0), "Ownable: fee address is the zero address");
        return ArtistTokenInterface(_artistTokenContractAddress).getFee(feeAddress);
    }

    function getFees() external view returns (ArtistSingleTokenFee[] memory) {
        return ArtistTokenInterface(_artistTokenContractAddress).getFees();
    }

    function getCategory(uint256 categoryId) external view returns (TokenCategory memory) {
        return ArtistTokenInterface(_artistTokenContractAddress).getCategory(categoryId);
    }

    function getCategories() external view returns (TokenCategory[] memory) {
        return ArtistTokenInterface(_artistTokenContractAddress).getCategories();
    }
}