// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () internal {
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
}

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./Signable.sol";
import "./IPocketstarsCollection.sol";
import "./ISignable.sol";

contract Auction is Ownable, Signable, ReentrancyGuard {
    struct Auction {
        uint256 tokenId;
        address signer;
        uint256 minBid;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    // EIP712
    bytes32 public DOMAIN_SEPARATOR;

    // bytes32 public constant AUCTION_TYPEHASH = keccak256("Auction(uint256 tokenId,address signer,uint256 minBid,uint256 startTimestamp,uint256 endTimestamp)");
    bytes32 public constant AUCTION_TYPEHASH = 0xc5c14bcda141a565f3a3ea8b635557e14c57478fd5bb14d518af52617d6c8e93;

    mapping (uint256 => Auction) auctions;
    mapping (uint256 => address) highestBidders;
    mapping (uint256 => uint256) highestBids;
    mapping (uint256 => bool) claimedTokens;
    mapping(address => uint) refunds;

    address private _collectionContract;

    constructor(address collectionContract, uint256 chainId) {
        _collectionContract = collectionContract;

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("PocketStars")),
            chainId,
            address(this)
        ));
    }

    function bid(uint256 tokenId, address signer, uint256 minBid, uint256 startTimestamp, uint256 endTimestamp, uint8 v, bytes32 r, bytes32 s) payable external nonReentrant {
        if (auctions[tokenId].signer == address(0)) {
            bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    AUCTION_TYPEHASH,
                    tokenId,
                    signer,
                    startTimestamp,
                    endTimestamp
                ))
            ));

            require(signer != address(0), "Invalid address");
            // Make sure the auction was signed by a PocketStars signer
            require(this.signers(ecrecover(digest, v, r, s)), "Invalid signer");
            require(claimedTokens[tokenId] == false, "Token already claimed");

            Auction memory auction = Auction(tokenId, signer, minBid, startTimestamp, endTimestamp);
            auctions[tokenId] = auction;
        }

        Auction memory auction = auctions[tokenId];

        require(block.timestamp > auction.startTimestamp, "Auction not started");
        require(block.timestamp < auction.endTimestamp, "Auction finished");

        require(msg.value >= auction.minBid, "Amount too low compared to minimum bid");
        require(msg.value > highestBids[tokenId], "Amount too low to previous bid");

        if (highestBidders[tokenId] != address(0)) {
            // record the refund that this user can claim
            refunds[highestBidders[tokenId]] += highestBids[tokenId];
        }

        highestBidders[tokenId] = msg.sender;
        highestBids[tokenId] = msg.value;
    }

    function withdrawRefund() external nonReentrant {
        uint refund = refunds[msg.sender];
        refunds[msg.sender] = 0;
        (bool success, ) = msg.sender.call{ value: refund }("");
        require(success);
    }

    function claimToken(uint256 tokenId) external nonReentrant {
        require(auctions[tokenId].signer != address(0), "Auction not set");
        require(block.timestamp > auctions[tokenId].endTimestamp, "Auction not finished");
        require(claimedTokens[tokenId] == false, "Token already claimed");
        require(highestBidders[tokenId] == msg.sender, "Wrong claimant");

        claimedTokens[tokenId] = true;

        (bool success) = IPocketstarsCollection(_collectionContract).mint(msg.sender, tokenId, 1);
        require(success);
    }

    // TODO: Add a check to prevent withdrawing the refunds
    function withdraw(uint256 amount) external onlyOwner {
        (bool success, ) = owner().call{ value: amount }("");
        require(success);
    }

    function addSigner(address account) public onlyOwner {
        _addSigner(account);
    }

    function removeSigner(address account) public onlyOwner {
        _removeSigner(account);
    }
}

pragma solidity ^0.7.0;

interface IPocketstarsCollection {
    function setURI(string calldata newuri) external;
    function addMinter(address account) external;
    function removeMinter(address account) external;
    function mint(address account, uint256 id, uint256 amount) external returns (bool);
}

pragma solidity ^0.7.0;

contract IMintable {
    mapping (address => bool) public signers;
}

pragma solidity ^0.7.0;

contract Signable {
    mapping (address => bool) public signers;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    /**
     * @dev Throws if called by any account other than a signer.
     */
    modifier onlySigner() {
        require(signers[msg.sender], "Signable: caller is not a signer");
        _;
    }

    function _addSigner(address account) internal {
        signers[account] = true;
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        signers[account] = false;
        emit SignerRemoved(account);
    }
}

