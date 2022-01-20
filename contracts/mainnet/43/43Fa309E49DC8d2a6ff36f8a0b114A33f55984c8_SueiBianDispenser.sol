// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

enum SaleStage {
    None,
    FirstWhiteList,
    SecondWhiteList,
    PublicSale
}

interface NFT {
    function mint(address receiver) external;
}

contract SueiBianDispenser is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 public firstWhiteListSaleStartTime = 1642683600; // Jan 20th 2022. 9:00PM UTC+8
    uint256 public firstWhiteListSaleEndTime = 1642685400; // Jan 20th 2022. 9:30PM UTC+8
    uint256 public firstWhiteListSaleRemainingCount = 120;

    uint256 public secondWhiteListSaleStartTime = 1642685400; // Jan 20th 2022. 9:30PM UTC+8
    uint256 public secondWhiteListSaleEndTime = 1642687200; // Jan 20th 2022. 10:00PM UTC+8
    uint256 public secondWhiteListSaleRemainingCount = 180;

    uint256 public publicSaleStartTime = 1642687200; // Jan 20th 2022. 10:00PM UTC+8
    uint256 public publicSaleEndTime = 1642689000; // Jan 20th 2022. 10:30PM UTC+8
    uint256 public publicSalePurchasedCount = 0;
    uint256 public publicSaleMaxPurchaseAmount = 3;

    uint256 public maxDispenseCount = 300;

    uint256 public mintPrice = 0.08 ether;

    bytes32 private _firstWhiteListMerkleRoot;
    bytes32 private _secondWhiteListMerkleRoot;

    address public sueiBianDAOAddress;
    mapping(address => bool) public firstWhiteListPurchased;
    mapping(address => bool) public secondWhiteListPurchased;

    constructor(address _sueiBianDAOAddress) {
        sueiBianDAOAddress = _sueiBianDAOAddress;
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */
    function publicSaleRemainingCount() public view returns (uint256) {
        uint256 totalWhiteListRemainingCount = firstWhiteListSaleRemainingCount +
                secondWhiteListSaleRemainingCount;
        return
            publicSalePurchasedCount <= totalWhiteListRemainingCount
                ? totalWhiteListRemainingCount - publicSalePurchasedCount
                : 0;
    }

    // @notice This function returns the current active sale stage
    // @notice 0: NONE, 1: First Whitelist Sale, 2: Second Whitelist Sale, 3: Public Sale
    function getCurrentActiveSaleStage() public view returns (SaleStage) {
        bool firstWhiteListSaleIsActive = (block.timestamp >
            firstWhiteListSaleStartTime) &&
            (block.timestamp < firstWhiteListSaleEndTime);
        if (firstWhiteListSaleIsActive) {
            return SaleStage.FirstWhiteList;
        }
        bool secondWhiteListSaleIsActive = (block.timestamp >
            secondWhiteListSaleStartTime) &&
            (block.timestamp < secondWhiteListSaleEndTime);
        if (secondWhiteListSaleIsActive) {
            return SaleStage.SecondWhiteList;
        }
        bool publicSaleIsActive = (block.timestamp > publicSaleStartTime) &&
            (block.timestamp < publicSaleEndTime);
        if (publicSaleIsActive) {
            return SaleStage.PublicSale;
        }
        return SaleStage.None;
    }

    function sueiBianBuy(bytes32[] calldata proof, uint256 numberOfTokens)
        external
        payable
        nonReentrant
    {
        require(
            msg.value == mintPrice * numberOfTokens,
            "sent ether value incorrect"
        );
        SaleStage currentActiveSaleStage = getCurrentActiveSaleStage();
        require(
            currentActiveSaleStage != SaleStage.None,
            "no active sale right now"
        );
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        if (currentActiveSaleStage == SaleStage.FirstWhiteList) {
            _sueiBianBuyFirstWhiteList(proof, numberOfTokens);
        } else if (currentActiveSaleStage == SaleStage.SecondWhiteList) {
            _sueiBianBuySecondWhiteList(proof, numberOfTokens);
        } else {
            _sueiBianBuyPublicSale(numberOfTokens);
        }
    }

    function _sueiBianBuyFirstWhiteList(
        bytes32[] calldata proof,
        uint256 numberOfTokens
    ) internal {
        require(
            !firstWhiteListPurchased[msg.sender],
            "firstWhiteListPurchased already"
        );
        require(
            proof.verify(
                _firstWhiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, numberOfTokens))
            ),
            "failed to verify first WL merkle root"
        );
        require(
            firstWhiteListSaleRemainingCount >= numberOfTokens,
            "first whitelist sold out"
        );
        firstWhiteListPurchased[msg.sender] = true;
        firstWhiteListSaleRemainingCount -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            NFT(sueiBianDAOAddress).mint(msg.sender);
        }
    }

    function _sueiBianBuySecondWhiteList(
        bytes32[] calldata proof,
        uint256 numberOfTokens
    ) internal {
        require(
            !secondWhiteListPurchased[msg.sender],
            "secondWhiteListPurchased already"
        );
        require(
            proof.verify(
                _secondWhiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, numberOfTokens))
            ),
            "failed to verify second WL merkle root"
        );
        require(
            secondWhiteListSaleRemainingCount >= numberOfTokens,
            "second whitelist sold out"
        );
        secondWhiteListPurchased[msg.sender] = true;
        secondWhiteListSaleRemainingCount -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            NFT(sueiBianDAOAddress).mint(msg.sender);
        }
    }

    function _sueiBianBuyPublicSale(uint256 numberOfTokens) internal {
        require(
            publicSaleRemainingCount() >= numberOfTokens,
            "public sale sold out"
        );
        require(
            numberOfTokens <= publicSaleMaxPurchaseAmount,
            "numberOfTokens exceeds publicSaleMaxPurchaseAmount"
        );

        publicSalePurchasedCount += numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            NFT(sueiBianDAOAddress).mint(msg.sender);
        }
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setMerkleRoots(bytes32 _firstMerkleRoot, bytes32 _secondMerkleRoot)
        external
        onlyOwner
    {
        _firstWhiteListMerkleRoot = _firstMerkleRoot;
        _secondWhiteListMerkleRoot = _secondMerkleRoot;
    }

    function setSaleData(
        uint256 _firstWhiteListSaleStartTime,
        uint256 _firstWhiteListSaleEndTime,
        uint256 _firstWhiteListSaleRemainingCount,
        uint256 _secondWhiteListSaleStartTime,
        uint256 _secondWhiteListSaleEndTime,
        uint256 _secondWhiteListSaleRemainingCount,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _publicSalePurchasedCount,
        uint256 _publicSaleMaxPurchaseAmount,
        uint256 _maxDispenseCount,
        uint256 _mintPrice
    ) external onlyOwner {
        firstWhiteListSaleStartTime = _firstWhiteListSaleStartTime;
        firstWhiteListSaleEndTime = _firstWhiteListSaleEndTime;
        firstWhiteListSaleRemainingCount = _firstWhiteListSaleRemainingCount;
        secondWhiteListSaleStartTime = _secondWhiteListSaleStartTime;
        secondWhiteListSaleEndTime = _secondWhiteListSaleEndTime;
        secondWhiteListSaleRemainingCount = _secondWhiteListSaleRemainingCount;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;
        publicSalePurchasedCount = _publicSalePurchasedCount;
        publicSaleMaxPurchaseAmount = _publicSaleMaxPurchaseAmount;
        maxDispenseCount = _maxDispenseCount;
        mintPrice = _mintPrice;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor() {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

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