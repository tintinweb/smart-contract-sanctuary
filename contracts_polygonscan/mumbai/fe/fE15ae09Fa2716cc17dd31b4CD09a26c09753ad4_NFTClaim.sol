// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../../utils/AccessProtectedUpgradeable.sol";
import "../../utils/BaseRelayRecipient.sol";

interface IERC1155Tradeable {
    function issueToken(
        address recipient,
        uint256 tokenId,
        uint256 amount
    ) external;
}

contract NFTClaim is Initializable, AccessProtectedUpgradeable, BaseRelayRecipient, ReentrancyGuardUpgradeable {

    function initialize(IERC1155Tradeable _token) public virtual initializer {
        __NFTClaim_init(_token);
    }

    IERC1155Tradeable private token; // NFT

    mapping(address => mapping(uint256 => uint256)) public userClaimableNFTs;
    mapping(address => mapping(uint256 => uint256)) public userClaimedNFTs;

    event SetUserClaimableNFT(
        address indexed _admin,
        address indexed _user,
        uint256 indexed _tokenId,
        uint256 _amount
    );
    event SetUserClaimableNFTBatch(
        address indexed _admin,
        address[] _users,
        uint256[] _tokenIds,
        uint256[] amounts
    );
    event Claimed(address indexed _user, uint256 indexed _tokenId, uint256 indexed _amount);
    event ClaimedBatch(address indexed _user, uint256[] _tokenIds, uint256[] _amounts);

    function __NFTClaim_init(IERC1155Tradeable _token) internal initializer {
        __Ownable_init_unchained();
        __AccessProtected_init_unchained();

        __ReentrancyGuard_init_unchained();

        __NFTClaim_init_unchained(_token);
    }

    function __NFTClaim_init_unchained(IERC1155Tradeable _token) internal initializer {
        token = _token;
    }

    /**
     * Set Claim NftTypes for a Given User
     *
     * @param user - User for which the nftType needs to be added
     * @param tokenId - NftType which needs to be added for the given user
     */
    function setUserClaimableNFT(
        address user,
        uint8 tokenId,
        uint256 amount
    ) external onlyAdmin {
        require(user != address(0), "Cannot set claim for address 0");
        require(tokenId > 0, "tokenId must be greater than 0");
        require(amount > 0, "amount must be greater than 0");

        userClaimableNFTs[user][tokenId] = userClaimableNFTs[user][tokenId] + amount;

        emit SetUserClaimableNFT(_msgSender(), user, tokenId, amount);
    }

    function setUserClaimableNFTBatch(
        address[] memory users,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external onlyAdmin {
        require(users.length == tokenIds.length, "NFTClaim: users length and tokenIds don't match");
        require(amounts.length == tokenIds.length, "NFTClaim: tokenIds and amounts don't match");

        for (uint256 i = 0; i < amounts.length; ++i) {
            address user = users[i];
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];

            userClaimableNFTs[user][tokenId] = userClaimableNFTs[user][tokenId] + amount;
        }

        emit SetUserClaimableNFTBatch(_msgSender(), users, tokenIds, amounts);
    }

    /**
     * Get Claim NftTypes for a Given User
     *
     * @param _user - User for which the nftTypes needs to be fetched
     * @param _tokenId - specified NFT id
     */
    function getClaimableNFTsForTokenId(address _user, uint256 _tokenId) public view returns (uint256) {
        return userClaimableNFTs[_user][_tokenId];
    }

    /**
     * Fetch NFT amount of specified tokenId claimed by a User
     */
    function getNFTAmountClaimedByUser(address _user, uint256 _tokenId) public view returns (uint256) {
        return userClaimedNFTs[_user][_tokenId];
    }

    /**
     * Claim NFTs based on the NftTypes allocated to a user
     */
    function claim(uint256 _tokenId, uint256 _amount) external nonReentrant {
        
        address operator = _msgSender();

        // check how many nfts user can claim for the given tokenId
        uint256 availabletokens = getClaimableNFTsForTokenId(operator, _tokenId);

        require(availabletokens >= _amount, "NFTClaim: invalid claim amount");

        // issue token amount to user
        token.issueToken(operator, _tokenId, _amount);

        // increment user claimed nfts based on tokenId
        userClaimedNFTs[operator][_tokenId] = userClaimedNFTs[operator][_tokenId] + _amount;

        // decrement claimable nfts based on tokenId
        userClaimableNFTs[operator][_tokenId] = userClaimableNFTs[operator][_tokenId] - _amount;

        // emit claimed event
        emit Claimed(operator, _tokenId, _amount);
    }

    // batch version of the function above
    function claimBatch(uint256[] memory _tokenIds, uint256[] memory _amounts) external nonReentrant {
        require(_tokenIds.length > 0, "NFTClaim: number of NFTs claiming must be greater than 0");
        require(_tokenIds.length == _amounts.length, "NFTClaim: ids and amounts length mismatch");
        
        address operator = _msgSender();

        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            uint256 tokenId = _tokenIds[i];
            uint256 amount = _amounts[i];

            uint256 availabletokens = getClaimableNFTsForTokenId(operator, tokenId);

            require(availabletokens >= amount, "NFTClaim: invalid claim amount");

            token.issueToken(operator, tokenId, amount);

            userClaimedNFTs[operator][tokenId] = userClaimedNFTs[operator][tokenId] + amount;

            userClaimableNFTs[operator][tokenId] = userClaimableNFTs[operator][tokenId] - amount;
        }

        emit ClaimedBatch(operator, _tokenIds, _amounts);
    }

    /**
     * Set Trusted Forwarder
     *
     * @param _trustedForwarder - Trusted Forwarder address
     */
    function setTrustedForwarder(address _trustedForwarder) external onlyAdmin {
        trustedForwarder = _trustedForwarder;
    }

    /**
     * returns the message sender
     */
    function _msgSender() internal view override(ContextUpgradeable, BaseRelayRecipient) returns (address) {
        return BaseRelayRecipient._msgSender();
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract AccessProtectedUpgradeable is Initializable, OwnableUpgradeable {
    mapping(address => bool) private _admins; // user address => admin? mapping

    event AdminAccess(address _admin, bool _isEnabled);

    /**
     * @dev Initializes the contract
     */
    function __AccessProtected_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __AccessProtected_init_unchained();
    }

    function __AccessProtected_init_unchained() internal initializer {

    }

    /**
     * @notice Set Admin Access
     *
     * @param admin - Address of Minter
     * @param isEnabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool isEnabled) external onlyAdmin {
        _admins[admin] = isEnabled;
        emit AdminAccess(admin, isEnabled);
    }

    /**
     * @notice Check Admin Access
     *
     * @param admin - Address of Admin
     * @return whether minter has access (or is owner)
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin] || (admin == owner());
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(_admins[_msgSender()] || _msgSender() == owner(), "Caller does not have Admin Access");
        _;
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient {
    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == address(trustedForwarder), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view virtual returns (address ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender; //msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}