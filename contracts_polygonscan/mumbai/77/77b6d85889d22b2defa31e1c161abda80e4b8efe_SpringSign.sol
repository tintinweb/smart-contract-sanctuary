/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.9;

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
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract SpringSign is Ownable {
    struct Consent {
        uint256 createdAt;
        string md5Checksum;
        string sha256Checksum;
        uint256 signedAt;
        address addedBy;
    }

    /**
     * @dev Mapping of hashed consentId to the Consent struct
     */
    mapping(bytes32 => Consent) public ConsentDetails;

    /**
     * @dev Mapping of authorized address.
     */
    mapping(address => bool) public authorizedAddress;

    /**
     * @dev Mapping of authorized address and name.
     */
    mapping(address => string) public authorityName;

    /**
     * @dev modifier throws if called by any unauthorized address.
     */
    modifier onlyAuthorized() {
        require(authorizedAddress[msg.sender] == true, "Not authorized");
        _;
    }

    /**
     * Event is fired when a consent is added. A consent is
     * added either by authorized address or the signer itself
     */
    event ConsentAdded(string consentId, bytes32 consentIdHash, address indexed addedBy);

    /**
     * Event fired when a new authorized address is added.
     */
    event AuthorityAdded(address indexed addressToAuthorize);

    /**
     * Event fired when a authorized address is revoked.
     */
    event AuthorityRevoked(address indexed authorizedAddress);

    constructor() public {
        emit AuthorityAdded(msg.sender);
        authorityName[msg.sender] = "SpringSign";
        authorizedAddress[msg.sender] = true;
    }

    /**
     * @dev Function to add an address to list of authorized adderesses.
     * @param authorityAddress - new authorized address
     * @param name - authority name
     */
    function addAuthority(address authorityAddress, string memory name) public onlyOwner {
        emit AuthorityAdded(authorityAddress);
        authorizedAddress[authorityAddress] = true;
        authorityName[authorityAddress] = name;
    }

    /**
     * @dev Function to remove address from list of authorized adderesses.
     * @param authorityAddress - new authorized address
     */
    function revokeAuthority(address authorityAddress) public onlyOwner {
        emit AuthorityRevoked(authorityAddress);
        authorizedAddress[authorityAddress] = false;
    }

    /**
     * @dev Function to add signed consent details
     * @param consentId - Consent Id
     * @param consentCreatedAt - consent creation timestamp
     * @param signedConsentMD5Checksum - computed SHA256 checksum of signed consent
     * @param signedConsentSHA256Checksum - computed SHA256 checksum of signed consent
     * @param consentSignedAt - timestamp when consent is signed
     */
    function addConsent(
        string memory consentId,
        uint256 consentCreatedAt,
        string memory signedConsentMD5Checksum,
        string memory signedConsentSHA256Checksum,
        uint256 consentSignedAt
    ) public onlyAuthorized {
        require(
            consentCreatedAt <= consentSignedAt,
            "consent cannot be signed before the creation"
        );

        bytes32 consentIdHash = keccak256(
            abi.encode(consentId, authorityName[msg.sender])
        );

        emit ConsentAdded(consentId, consentIdHash, msg.sender);

        ConsentDetails[consentIdHash] = Consent(
            consentCreatedAt,
            signedConsentMD5Checksum,
            signedConsentSHA256Checksum,
            consentSignedAt,
            msg.sender
        );
    }
}