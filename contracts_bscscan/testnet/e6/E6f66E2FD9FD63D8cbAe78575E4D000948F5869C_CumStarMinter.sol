/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

// File: contracts/src/model/CumStarNFTToken/CumStarNFTTokenModel.sol

/**
 *Submitted for verification at BscScan.com on
*/

// SPDX-License-Identifier: MIT
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

// File: contracts/src/utility/InterfaceRegistry.sol

/**
 *Submitted for verification at BscScan.com on
*/






pragma solidity ^0.8.7;

abstract contract InterfaceRegistry is
    CumStarNFTTokenInterface,
    PayableUserTokenInterface,
    UserProfileTokenInterface
{

}

// File: contracts/src/external/CumStar/CumStarTokenExternalInterface.sol

/**
 *Submitted for verification at BscScan.com on
*/



pragma solidity ^0.8.7;

interface CumStarTokenExternalInterface {
    function balanceOf(address userAddress) external view returns (uint256);
    function getMinBalance() external view returns (uint256);
    function setMinBalance(uint256 customerMinCumStarBalance) external;
}

interface CumStarTokenStateInterface {
    function getMinBalance() external view returns (uint256);
    function setMinBalance(uint256 customerMinCumStarBalance) external;
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

// File: contracts/src/libs/Context.sol



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

// File: contracts/src/worker/CumStarMinter.sol

/**
 *Submitted for verification at BscScan.com on
*/



pragma solidity ^0.8.7;




contract CumStarMinter is WorkerOwnable {
    address _cumStarTokenContractAddress;
    address _cumStarNFTTokenContractAddress;
    address _userProfileTokenContractAddress;
    address _payableUserTokenContractAddress;

    string public _artistUserProfileType = 'artist';
    string public _customerUserProfileType = 'customer';

    // Token state Events
    event CumStarMinterMintedPayableUserToken(address indexed tokenOwner, uint256 tokenId);
    event CumStarMinterMintedUserProfileToken(address indexed tokenOwner, uint256 tokenId, string userProfileType);

    constructor (
        address cumStarTokenContractAddress_,
        address cumStarNFTTokenContractAddress_,
        address userProfileTokenContractAddress_,
        address payableUserTokenContractAddress_
    ) {
        _cumStarTokenContractAddress = cumStarTokenContractAddress_;
        _cumStarNFTTokenContractAddress = cumStarNFTTokenContractAddress_;
        _userProfileTokenContractAddress = userProfileTokenContractAddress_;
        _payableUserTokenContractAddress = payableUserTokenContractAddress_;
    }

    function mintPayableUserToken(address artistAddress, string memory tokenUri) external payable onlyOwner {
        require(artistAddress != address(0), "Ownable: Artist address is the zero address");
        uint256 cumStarNFTTokenId = CumStarNFTTokenInterface(_cumStarNFTTokenContractAddress).mint(artistAddress, tokenUri);

        PayableUserTokenInterface(_payableUserTokenContractAddress).mint(artistAddress, cumStarNFTTokenId);

        emit CumStarMinterMintedPayableUserToken(artistAddress, cumStarNFTTokenId);
    }

    function mintArtist(
        address artistAddress,
        string memory username,
        string memory tokenUri,
        uint256 payableNFTTokenId
    ) external payable {
        require(artistAddress != address(0), "Ownable: Artist address is the zero address");

        PayableUserTokenInterface(_payableUserTokenContractAddress).useToken(payableNFTTokenId, artistAddress);
        uint256 cumStarNFTTokenId = CumStarNFTTokenInterface(_cumStarNFTTokenContractAddress).mint(artistAddress, tokenUri);

        UserProfileTokenInterface(_userProfileTokenContractAddress).mintArtist(
            artistAddress,
                username,
                cumStarNFTTokenId
        );

        emit CumStarMinterMintedUserProfileToken(artistAddress, cumStarNFTTokenId, _artistUserProfileType);
    }

    function mintCustomer(
        address customerAddress,
        string memory username,
        string memory tokenUri
    ) external payable {
        require(customerAddress != address(0), "Ownable: Artist address is the zero address");
        uint256 cumStarBalance = CumStarTokenExternalInterface(_cumStarTokenContractAddress).balanceOf(customerAddress);
        uint256 customerMinCumStarBalance = CumStarTokenExternalInterface(_cumStarTokenContractAddress).getMinBalance();
        require(cumStarBalance > customerMinCumStarBalance, "Balance: User does not have enough CumStar tokens to become a customer.");
        UserProfileTokenInterface(_userProfileTokenContractAddress).checkIfCustomerExist(customerAddress);

        uint256 cumStarNFTTokenId = CumStarNFTTokenInterface(_cumStarNFTTokenContractAddress).mint(customerAddress, tokenUri);
        UserProfileTokenInterface(_userProfileTokenContractAddress).mintCustomer(
            customerAddress,
                username,
                cumStarNFTTokenId
        );

        emit CumStarMinterMintedUserProfileToken(customerAddress, cumStarNFTTokenId, _customerUserProfileType);
    }
}