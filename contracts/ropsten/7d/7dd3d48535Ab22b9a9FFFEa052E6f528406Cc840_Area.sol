// STATUS: RELEASE CANDIDATE 1
// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.9; // code below expects that integer overflows will revert
import "./AreaNFT.sol";
import "./RandomDropVending.sol";
import "./Utilities/PlusCodes.sol";
import "./Vendor/openzeppelin-contracts-3dadd40034961d5ca75fa209a4188b01d7129501/access/Ownable.sol";

/// @title  Area main contract, 🌐 the earth on the blockchain, 📌 geolocation NFTs
/// @notice This contract is responsible for initial allocation and non-fungible tokens.
///         ⚠️ Bad things will happen if the reveals do not happen a sufficient amount for more than ~60 minutes.
/// @author William Entriken
contract Area is Ownable, AreaNFT, RandomDropVending {
    /// @param inventorySize  inventory for code length 4 tokens for sale (normally 43,200)
    /// @param teamAllocation how many set aside for team
    /// @param pricePerPack   the cost in Wei for each pack
    /// @param packSize       how many drops can be purchased at a time
    /// @param name           ERC721 contract name
    /// @param symbol         ERC721 symbol name
    /// @param baseURI        prefix for all token URIs
    /// @param priceToSplit   value (in Wei) required to split Area tokens
    constructor(
        uint256 inventorySize,
        uint256 teamAllocation,
        uint256 pricePerPack,
        uint32 packSize,
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 priceToSplit
    )
        RandomDropVending(inventorySize, teamAllocation, pricePerPack, packSize)
        AreaNFT(name, symbol, baseURI, priceToSplit)
    {
    }

    /// @notice Start the sale
    function beginSale() external onlyOwner {
        _beginSale();
    }

    /// @notice In case of emergency, the number of allocations set aside for the team can be adjusted
    /// @param  teamAllocation the new allocation amount
    function setTeamAllocation(uint256 teamAllocation) external onlyOwner {
        _setTeamAllocation(teamAllocation);
    }

    /// @notice A quantity of Area tokens that were committed by anybody and are now mature are revealed
    /// @param  revealsLeft up to how many reveals will occur
    function reveal(uint32 revealsLeft) external onlyOwner {
        RandomDropVending._reveal(revealsLeft);
    }

    /// @notice Takes some of the code length 4 codes that are not near the poles and assigns them. Team is unable to
    ///         take tokens until all other tokens are allocated from sale.
    /// @param  recipient the account that is assigned the tokens
    /// @param  quantity  how many to assign
    function mintTeamAllocation(address recipient, uint256 quantity) external onlyOwner {
        RandomDropVending._takeTeamAllocation(recipient, quantity);
    }

    /// @notice Takes some of the code length 2 codes that are near the poles and assigns them. Team is unable to take
    ///         tokens until all other tokens are allocated from sale.
    /// @param  recipient    the account that is assigned the tokens
    /// @param  indexFromOne a number in the closed range [1, 54]
    function mintWaterAndIceReserve(address recipient, uint256 indexFromOne) external onlyOwner {
        require(RandomDropVending._inventoryForSale() == 0, "Cannot take during sale");
        uint256 tokenId = PlusCodes.getNthCodeLength2CodeNearPoles(indexFromOne);
        AreaNFT._mint(recipient, tokenId);
    }

    /// @notice Pay the bills
    function withdrawBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @dev Convert a Plus Code token ID to an ASCII (and UTF-8) string
    /// @param  plusCode  the Plus Code token ID to format
    /// @return the ASCII (and UTF-8) string showing the Plus Code token ID
    function tokenIdToString(uint256 plusCode) external pure returns(string memory) {
        return PlusCodes.toString(plusCode);
    }

    /// @dev Convert ASCII string to a Plus Code token ID
    /// @param  stringPlusCode the ASCII (UTF-8) Plus Code token ID
    /// @return plusCode       the Plus Code token ID representing the provided ASCII string
    function stringToTokenId(string memory stringPlusCode) external pure returns(uint256 plusCode) {
        return PlusCodes.fromString(stringPlusCode);
    }

    /// @inheritdoc RandomDropVending
    function _revealCallback(address recipient, uint256 allocation) internal override(RandomDropVending) {
        uint256 tokenId = PlusCodes.getNthCodeLength4CodeNotNearPoles(allocation);
        AreaNFT._mint(recipient, tokenId);
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

// STATUS: RELEASE CANDIDATE 1
// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.9;

/* Quick reference of valid Plus Codes (full code) formats, where D is some Plus Codes digit
 *
 * Code length 2:  DD000000+
 * Code length 4:  DDDD0000+
 * Code length 6:  DDDDDD00+
 * Code length 8:  DDDDDDDD+
 * Code length 10: DDDDDDDD+DD
 * Code length 11: DDDDDDDD+DDD
 * Code length 12: DDDDDDDD+DDDD
 * Code length 13: DDDDDDDD+DDDDD
 * Code length 14: DDDDDDDD+DDDDDD
 * Code length 15: DDDDDDDD+DDDDDDD
 */

/// @title  Part of Area, 🌐 the earth on the blockchain, 📌 geolocation NFTs
/// @notice Utilities for working with a subset (upper case and no higher than code length 12) of Plus Codes
/// @dev    A Plus Code is a character string representing GPS coordinates. See complete specification at
///         https://github.com/google/open-location-code.
///         We encode this string using ASCII, little endian, into a 256-bit integer. Following is an example code
///         length 8 Plus Code:
/// String:                                                  2 2 2 2 0 0 0 0 +
/// Hex:    0x000000000000000000000000000000000000000000000032323232303030302B
/// @author William Entriken
library PlusCodes {
    struct ChildTemplate {
        uint256 setBits;       // Every child is guaranteed to set these bits
        uint32 childCount;     // How many children are there, either 20 or 400
        uint32 digitsLocation; // How many bits must the child's significant digit(s) be left-shifted before adding
                               // (oring) to `setBits`?
    }

    /// @dev Plus Codes digits use base-20, these are the constituent digits
    bytes20 private constant _PLUS_CODES_DIGITS = bytes20("23456789CFGHJMPQRVWX");

    /// @notice Get the Plus Code at a certain index from the list of all code level 4 Plus Codes which are not near the
    ///         north or south poles
    /// @dev    Code length 4 Plus Codes represent 1 degree latitude by 1 degree longitude. We consider 40 degrees from
    ///         the South Pole and 20 degrees from the North Pole as "near". Therefore 360 × 120 = 43,200 Plus Codes are
    ///         here.
    /// @param  indexFromOne a number in the closed range [1, 43,200]
    /// @return plusCode     the n-th (one-indexed) Plus Code from the alphabetized list of all code length 4 Plus Codes
    ///                      which are not "near" a pole
    function getNthCodeLength4CodeNotNearPoles(uint256 indexFromOne) internal pure returns (uint256 plusCode) {
        require((indexFromOne >= 1) && (indexFromOne <= 43200), "Out of range");
        uint256 indexFromZero = indexFromOne - 1; // In the half-open range [0, 43,200)

        plusCode = uint256(uint40(bytes5("0000+")));
        // 0x000000000000000000000000000000000000000000000000000000303030302B;

        // Least significant digit can take any of 20 values
        plusCode |= uint256(uint8(_PLUS_CODES_DIGITS[indexFromZero % 20])) << 8*5;
        // 0x0000000000000000000000000000000000000000000000000000__303030302B;
        indexFromZero /= 20;

        // Next digit can take any of 20 values
        plusCode |= uint256(uint8(_PLUS_CODES_DIGITS[indexFromZero % 20])) << 8*6;
        // 0x00000000000000000000000000000000000000000000000000____303030302B;
        indexFromZero /= 20;

        // Next digit can take any of 18 values (18 × 20 degrees = 360 degrees)
        plusCode |= uint256(uint8(_PLUS_CODES_DIGITS[indexFromZero % 18])) << 8*7;
        // 0x000000000000000000000000000000000000000000000000______303030302B;
        indexFromZero /= 18;

        // Most significant digit can be not the lowest 2 nor highest 1 (6 options)
        plusCode |= uint256(uint8(_PLUS_CODES_DIGITS[2 + indexFromZero])) << 8*8;
        // 0x0000000000000000000000000000000000000000000000________303030302B;
    }

    /// @notice Get the Plus Code at a certain index from the list of all code level 2 Plus Codes which are near the
    ///         north or south poles
    /// @dev    Code length 2 Plus Codes represent 20 degrees latitude by 20 degrees longitude. We consider 40 degrees
    ///         from the South Pole and 20 degrees from the North Pole as "near". Therefore 360 × 60 ÷ 20 ÷ 20 = 54 Plus
    ///         Codes are here.
    /// @param  indexFromOne a number in the closed range [1, 54]
    /// @return plusCode     the n-th (one-indexed) Plus Code from the alphabetized list of all code length 2 Plus Codes
    ///                      which are "near" a pole
    function getNthCodeLength2CodeNearPoles(uint256 indexFromOne) internal pure returns (uint256 plusCode) {
        require((indexFromOne >= 1) && (indexFromOne <= 54), "Out of range");
        uint256 indexFromZero = indexFromOne - 1; // In the half-open range [0, 54)

        plusCode = uint256(uint56(bytes7("000000+")));
        // 0x000000000000000000000000000000000000000000000000003030303030302B;

        // Least significant digit can take any of 18 values (18 × 20 degrees = 360 degrees)
        plusCode |= uint256(uint8(_PLUS_CODES_DIGITS[indexFromZero % 18])) << 8*7;
        // 0x000000000000000000000000000000000000000000000000__3030303030302B;
        indexFromZero /= 18;

        // Most significant digit determines latitude
        if (indexFromZero <= 1) {
            // indexFromZero ∈ {0, 1}, this is the 40 degrees near South Pole
            plusCode |= uint256(uint8(_PLUS_CODES_DIGITS[indexFromZero])) << 8*8;
            // 0x0000000000000000000000000000000000000000000000____3030303030302B;
        } else {
            // indexFromZero = 2, this is the 20 degrees near North Pole
            plusCode |= uint256(uint8(_PLUS_CODES_DIGITS[8])) << 8*8;
            // 0x000000000000000000000000000000000000000000000043__3030303030302B;
        }
    }

    /// @notice Find the Plus Code representing `childCode` plus some more area if input is a valid Plus Code; otherwise
    ///         revert
    /// @param  childCode  a Plus Code
    /// @return parentCode the Plus Code representing the smallest area which contains the `childCode` area plus some
    ///                    additional area
    function getParent(uint256 childCode) internal pure returns (uint256 parentCode) {
        uint8 childCodeLength = getCodeLength(childCode);
        if (childCodeLength == 2) {
            revert("Code length 2 Plus Codes do not have parents");
        }
        if (childCodeLength == 4) {
            return childCode & 0xFFFF00000000000000 | 0x3030303030302B;
        }
        if (childCodeLength == 6) {
            return childCode & 0xFFFFFFFF0000000000 | 0x303030302B;
        }
        if (childCodeLength == 8) {
            return childCode & 0xFFFFFFFFFFFF000000 | 0x30302B;
        }
        if (childCodeLength == 10) {
            return childCode >> 8*2;
        }
        // childCodeLength ∈ {11, 12}
        return childCode >> 8*1;
    }

    /// @notice Create a template for enumerating Plus Codes that are a portion of `parentCode` if input is a valid Plus
    ///         Code; otherwise revert
    /// @dev    A "child" is a Plus Code representing the largest area which contains some of the `parentCode` area
    ///         minus some area.
    /// @param  parentCode    a Plus Code to operate on
    /// @return childTemplate bit pattern and offsets every child will have
    function getChildTemplate(uint256 parentCode) internal pure returns (ChildTemplate memory) {
        uint8 parentCodeLength = getCodeLength(parentCode);
        if (parentCodeLength == 2) {
            return ChildTemplate(parentCode & 0xFFFF0000FFFFFFFFFF, 400, 8*5);
            // DD__0000+
        }
        if (parentCodeLength == 4) {
            return ChildTemplate(parentCode & 0xFFFFFFFF0000FFFFFF, 400, 8*3);
            // DDDD__00+
        }
        if (parentCodeLength == 6) {
            return ChildTemplate(parentCode & 0xFFFFFFFFFFFF0000FF, 400, 8*1);
            // DDDDDD__+
        }
        if (parentCodeLength == 8) {
            return ChildTemplate(parentCode << 8*2, 400, 0);
            // DDDDDDDD+__
        }
        if (parentCodeLength == 10) {
            return ChildTemplate(parentCode << 8*1, 20, 0);
            // DDDDDDDD+DD_
        }
        if (parentCodeLength == 11) {
            return ChildTemplate(parentCode << 8*1, 20, 0);
            // DDDDDDDD+DDD_
        }
        revert("Plus Codes with code length greater than 12 not supported");
    }

    /// @notice Find a child Plus Code based on a template
    /// @dev    A "child" is a Plus Code representing the largest area which contains some of a "parent" area minus some
    ///         area.
    /// @param  indexFromZero which child (zero-indexed) to generate, must be less than `template.childCount`
    /// @param  template      tit pattern and offsets to generate child
    function getNthChildFromTemplate(uint32 indexFromZero, ChildTemplate memory template)
        internal
        pure
        returns (uint256 childCode)
    {
        // This may run in a 400-wide loop (for Transfer events), keep it tight

        // These bits are guaranteed
        childCode = template.setBits;

        // Add rightmost digit
        uint8 rightmostDigit = uint8(_PLUS_CODES_DIGITS[indexFromZero % 20]);
        childCode |= uint256(rightmostDigit) << template.digitsLocation;
        // 0xTEMPLATETEMPLATETEMPLATETEMPLATETEMPLATETEMPLATETEMPLATETEML=ATE;

        // Do we need to add a second digit?
        if (template.childCount == 400) {
            uint8 secondDigit = uint8(_PLUS_CODES_DIGITS[indexFromZero / 20]);
            childCode |= uint256(secondDigit) << (template.digitsLocation + 8*1);
            // 0xTEMPLATETEMPLATETEMPLATETEMPLATETEMPLATETEMPLATETEMPLATETEM==ATE;
        }
    }

    /// @dev Returns 2, 4, 6, 8, 10, 11, or 12 for valid Plus Codes, otherwise reverts
    /// @param  plusCode the Plus Code to format
    /// @return the code length
    function getCodeLength(uint256 plusCode) internal pure returns(uint8) {
        if (bytes1(uint8(plusCode)) == "+") {
            // Code lengths 2, 4, 6 and 8 are the only ones that end with the format separator (+) and they have exactly
            // 9 characters.
            require((plusCode >> 8*9) == 0, "Too many characters in Plus Code");
            _requireValidDigit(plusCode, 8);
            _requireValidDigit(plusCode, 7);
            require(bytes1(uint8(plusCode >> 8*8)) <= "C", "Beyond North Pole");
            require(bytes1(uint8(plusCode >> 8*7)) <= "V", "Beyond antimeridian");
            if (bytes7(uint56(plusCode & 0xFFFFFFFFFFFFFF)) == "000000+") {
                return 2;
            }
            _requireValidDigit(plusCode, 6);
            _requireValidDigit(plusCode, 5);
            if (bytes5(uint40(plusCode & 0xFFFFFFFFFF)) == "0000+") {
                return 4;
            }
            _requireValidDigit(plusCode, 4);
            _requireValidDigit(plusCode, 3);
            if (bytes3(uint24(plusCode & 0xFFFFFF)) == "00+") {
                return 6;
            }
            _requireValidDigit(plusCode, 2);
            _requireValidDigit(plusCode, 1);
            return 8;
        }
        // Only code lengths 10, 11 and 12 (or more) don't end with a format separator.
        _requireValidDigit(plusCode, 0);
        _requireValidDigit(plusCode, 1);
        if (bytes1(uint8(plusCode >> 8*2)) == "+") {
            require(getCodeLength(plusCode >> 8*2) == 8, "Invalid before +");
            return 10;
        }
        _requireValidDigit(plusCode, 2);
        if (bytes1(uint8(plusCode >> 8*3)) == "+") {
            require(getCodeLength(plusCode >> 8*3) == 8, "Invalid before +");
            return 11;
        }
        _requireValidDigit(plusCode, 3);
        if (bytes1(uint8(plusCode >> 8*4)) == "+") {
            require(getCodeLength(plusCode >> 8*4) == 8, "Invalid before +");
            return 12;
        }
        revert("Code lengths greater than 12 are not supported");
    }

    /// @dev Convert a Plus Code to an ASCII (and UTF-8) string
    /// @param  plusCode the Plus Code to format
    /// @return the ASCII (and UTF-8) string showing the Plus Code
    function toString(uint256 plusCode) internal pure returns(string memory) {
        getCodeLength(plusCode);
        bytes memory retval = new bytes(0);
        while (plusCode > 0) {
            retval = abi.encodePacked(uint8(plusCode % 2**8), retval);
            plusCode >>= 8;
        }
        return string(retval);
    }

    /// @dev Convert ASCII string to a Plus Code
    /// @param  stringPlusCode the ASCII (UTF-8) Plus Code
    /// @return plusCode       the Plus Code representing the provided ASCII string
    function fromString(string memory stringPlusCode) internal pure returns(uint256 plusCode) {
        bytes memory bytesPlusCode = bytes(stringPlusCode);
        for (uint index=0; index<bytesPlusCode.length; index++) {
            plusCode = (plusCode << 8) + uint8(bytesPlusCode[index]);
        }
        PlusCodes.getCodeLength(plusCode);
    }

    /// @dev Reverts if the given byte is not a valid Plus Codes digit
    function _requireValidDigit(uint256 plusCode, uint8 offsetFromRightmostByte) private pure {
        uint8 digit = uint8(plusCode >> (8 * offsetFromRightmostByte));
        for (uint256 index = 0; index < 20; index++) {
            if (uint8(_PLUS_CODES_DIGITS[index]) == digit) {
                return;
            }
        }
        revert("Not a valid Plus Codes digit");
    }
}

// STATUS: RELEASE CANDIDATE 1
// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.9; // code below expects that integer overflows will revert
import "./Utilities/LazyArray.sol";
import "./Utilities/PlusCodes.sol";
import "./Utilities/CommitQueue.sol";

/// @title  Area commit-reveal drop contract, 🌐 the earth on the blockchain, 📌 geolocation NFTs
/// @notice This contract assigns all code length 4 Plus Codes to participants with randomness provided by a
///         commit-reveal mechanism. ⚠️ Bad things will happen if the reveals do not happen a sufficient amount for more
///         than ~60 minutes.
/// @dev    Each commit must be revealed (by the next committer or a benevolent revealer) to ensure that the intended
///         randomness for that, and subsequent, commits are used.
/// @author William Entriken
abstract contract RandomDropVending {
    using CommitQueue for CommitQueue.Self;
    CommitQueue.Self private _commitQueue;

    using LazyArray for LazyArray.Self;
    LazyArray.Self private _dropInventoryIntegers;

    uint256 private immutable _pricePerPack;
    uint32 private immutable _packSize;
    bool private _saleDidNotBeginYet;
    uint256 private _teamAllocation;

    /// @notice Some code length 4 Plus Codes were purchased, but not yet revealed
    /// @param  buyer    who purchased
    /// @param  quantity how many were purchased
    event Purchased(address buyer, uint32 quantity);

    /// @param inventorySize   integers [1, quantity] are available
    /// @param teamAllocation_ how many set aside for team
    /// @param pricePerPack_   the cost in Wei for each pack
    /// @param packSize_       how many drops can be purchased at a time
    constructor(uint256 inventorySize, uint256 teamAllocation_, uint256 pricePerPack_, uint32 packSize_) {
        require((inventorySize - teamAllocation_) % packSize_ == 0, "Pack size must evenly divide sale quantity");
        require(inventorySize > teamAllocation_, "None for sale, no fun");
        _dropInventoryIntegers.initialize(inventorySize);
        _teamAllocation = teamAllocation_;
        _pricePerPack = pricePerPack_;
        _packSize = packSize_;
        _saleDidNotBeginYet = true;
    }

    /// @notice A quantity of code length 4 Areas are committed for the benefit of the message sender, to be revealed
    ///         soon later. And a quantity of code length 4 Areas that were committed by anybody and are now mature are
    ///         revealed.
    /// @dev    ⚠️ If a commitment is made and is mature more than ~60 minutes without being revealed, then assignment
    ///         will use randomness from the then-current block hash, rather than the intended block hash.
    /// @param  benevolence how many reveals will be attempted in addition to the number of commits
    function purchaseTokensAndReveal(uint32 benevolence) external payable {
        require(msg.value == _pricePerPack, "Did not send correct Ether amount");
        require(_inventoryForSale() >= _packSize, "Sold out");
        require(msg.sender == tx.origin, "Only externally-owned accounts are eligible to purchase");
        require(_saleDidNotBeginYet == false, "The sale did not begin yet");
        _commit();
        _reveal(_packSize + benevolence); // overflow reverts
    }

    /// @notice Important numbers about the drop
    /// @return inventoryForSale how many more can be committed for sale
    /// @return queueCount       how many were committed but not yet revealed
    /// @return setAside         how many are remaining for team to claim
    function dropStatistics() external view returns (uint256 inventoryForSale, uint256 queueCount, uint256 setAside) {
        return (
            _inventoryForSale(),
            _commitQueue.count(),
            _teamAllocation <= _dropInventoryIntegers.count()
                ? _teamAllocation
                : _dropInventoryIntegers.count()
        );
    }

    /// @notice Start the sale
    function _beginSale() internal {
        _saleDidNotBeginYet = false;
    }

    /// @notice In case of emergency, the number of allocations set aside for the team can be adjusted
    /// @param  teamAllocation_ the new allocation amount
    function _setTeamAllocation(uint256 teamAllocation_) internal {
        _teamAllocation = teamAllocation_;
    }

    /// @notice A quantity of integers that were committed by anybody and are now mature are revealed
    /// @param  revealsLeft up to how many reveals will occur
    function _reveal(uint32 revealsLeft) internal {
        for (; revealsLeft > 0 && _commitQueue.isMature(); revealsLeft--) {
            // Get one from queue
            address recipient;
            uint64 maturityBlock;
            (recipient, maturityBlock) = _commitQueue.dequeue();

            // Allocate randomly
            uint256 randomNumber = _random(maturityBlock);
            uint256 randomIndex = randomNumber % _dropInventoryIntegers.count();
            uint allocatedNumber = _dropInventoryIntegers.popByIndex(randomIndex);
            _revealCallback(recipient, allocatedNumber);
        }
    }

    /// @dev   This callback triggers when some drop is revealed.
    /// @param recipient  the beneficiary of the drop
    /// @param allocation which number was dropped
    function _revealCallback(address recipient, uint256 allocation) internal virtual;

    /// @notice Takes some integers (not randomly) in inventory and assigns them. Team does not get tokens until all
    ///         other integers are allocated.
    /// @param  recipient the account that is assigned the integers
    /// @param  quantity  how many integers to assign
    function _takeTeamAllocation(address recipient, uint256 quantity) internal {
        require(_inventoryForSale() == 0, "Cannot take during sale");
        require(quantity <= _dropInventoryIntegers.count(), "Not enough to take");
        for (; quantity > 0; quantity--) {
            uint256 lastIndex = _dropInventoryIntegers.count() - 1;
            uint256 allocatedNumber = _dropInventoryIntegers.popByIndex(lastIndex);
            _revealCallback(recipient, allocatedNumber);
        }
    }

    /// @dev Get a random number based on the given block's hash; or some other hash if not available
    function _random(uint256 blockNumber) internal view returns (uint256) {
        // Blockhash produces non-zero values only for the input range [block.number - 256, block.number - 1]
        if (blockhash(blockNumber) != 0) {
            return uint256(blockhash(blockNumber));
        }
        return uint256(blockhash(((block.number - 1)>>8)<<8));
    }

    /// @notice How many more can be committed for sale
    function _inventoryForSale() internal view returns (uint256) {
        uint256 inventoryAvailable = _commitQueue.count() >= _dropInventoryIntegers.count()
            ? 0
            : _dropInventoryIntegers.count() - _commitQueue.count();
        return _teamAllocation >= inventoryAvailable
            ? 0
            : inventoryAvailable - _teamAllocation;
    }

    /// @notice A quantity of integers are committed for the benefit of the message sender, to be revealed soon later.
    /// @dev    ⚠️ If a commitment is made and is mature more than ~60 minutes without being revealed, then assignment
    ///         will use randomness from the then-current block hash, rather than the intended block hash.
    function _commit() private {
        _commitQueue.enqueue(msg.sender, _packSize);
        emit Purchased(msg.sender, _packSize);
    }
}

// STATUS: RELEASE CANDIDATE 1
// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.9; // code below expects that integer overflows will revert
import "./Vendor/openzeppelin-contracts-3dadd40034961d5ca75fa209a4188b01d7129501/token/ERC721/ERC721.sol";
import "./Vendor/openzeppelin-contracts-3dadd40034961d5ca75fa209a4188b01d7129501/access/Ownable.sol";
import "./Utilities/PlusCodes.sol";

/// @title  Area NFT contract, 🌐 the earth on the blockchain, 📌 geolocation NFTs
/// @notice This implementation adds features to the baseline ERC-721 standard:
///         - groups of tokens (siblings) are stored efficiently
///         - tokens can be split
/// @dev    This builds on the OpenZeppelin Contracts implementation
/// @author William Entriken
abstract contract AreaNFT is ERC721, Ownable {
    // The prefix for all token URIs
    string internal _baseTokenURI;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _explicitOwners;

    // Mapping from token ID to owner address, if a token is split
    mapping(uint256 => address) private _splitOwners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Price to split an area in Wei
    uint256 private _priceToSplit;

    /// @dev Contract constructor
    /// @param name_         ERC721 contract name
    /// @param symbol_       ERC721 symbol name
    /// @param baseURI       prefix for all token URIs
    /// @param priceToSplit_ value (in Wei) required to split Area tokens
    constructor(string memory name_, string memory symbol_, string memory baseURI, uint256 priceToSplit_)
        ERC721(name_, symbol_)
    {
        _baseTokenURI = baseURI;
        _priceToSplit = priceToSplit_;
    }

    /// @notice The owner of an Area Token can irrevocably split it into Plus Codes at one greater level of precision.
    /// @dev    This is the only function with burn functionality
    /// @param  tokenId the token that will be split
    function split(uint256 tokenId) external payable {
        require(msg.value == _priceToSplit, "Did not send correct Ether amount");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "AreaNFT: split caller is not owner nor approved");
        _burn(tokenId);

        // Split. This causes our ownerOf(childTokenId) to return the owner
        _splitOwners[tokenId] = _msgSender();

        // Ghost mint the child tokens
        // Ghost mint (verb): create N tokens on-chain (i.e. ownerOf returns something) without using N storage slots
        PlusCodes.ChildTemplate memory template = PlusCodes.getChildTemplate(tokenId);
        _balances[_msgSender()] += template.childCount; // Solidity 0.8+
        for (uint32 index = 0; index < template.childCount; index++) {
            uint256 childTokenId = PlusCodes.getNthChildFromTemplate(index, template);
            emit Transfer(address(0), _msgSender(), childTokenId);
        }
    }

    /// @notice Update the price to split Area tokens
    /// @param  newPrice value (in Wei) required to split Area tokens
    function setPriceToSplit(uint256 newPrice) external onlyOwner {
        _priceToSplit = newPrice;
    }

    /// @notice Update the base URI for token metadata
    /// @dev    All data you need is on-chain via token ID, and metadata is real world data. This Base URI is completely
    ///         optional and is only here to facilitate serving to marketplaces.
    /// @param  baseURI the new URI to prepend to all token URIs
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @inheritdoc ERC721
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /// @inheritdoc ERC721
    function ownerOf(uint256 tokenId) public view override returns (address owner) {
        owner = _explicitOwners[tokenId];
        if (owner != address(0)) {
            return owner;
        }
        require(_splitOwners[tokenId] == address(0), "AreaNFT: owner query for invalid (split) token");
        uint256 parentTokenId = PlusCodes.getParent(tokenId);
        owner = _splitOwners[parentTokenId];
        if (owner != address(0)) {
            return owner;
        }
        revert("ERC721: owner query for nonexistent token");
    }

    /// @inheritdoc ERC721
    /// @dev We must override because we need to access the derived `_tokenApprovals` variable that is set by the
    ///      derived`_approved`.
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /// @inheritdoc ERC721
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /// @inheritdoc ERC721
    function _burn(uint256 tokenId) internal virtual override {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _explicitOwners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /// @inheritdoc ERC721
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _explicitOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /// @inheritdoc ERC721
    /// @dev We must override because we need the derived `ownerOf` function.
    function _approve(address to, uint256 tokenId) internal virtual override {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /// @inheritdoc ERC721
    function _mint(address to, uint256 tokenId) internal virtual override {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        require(_splitOwners[tokenId] == address(0), "AreaNFT: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _explicitOwners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /// @inheritdoc ERC721
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /// @inheritdoc ERC721
    function _exists(uint256 tokenId) internal view virtual override returns (bool) {
        address owner;
        owner = _explicitOwners[tokenId];
        if (owner != address(0)) {
            return true;
        }
        if (_splitOwners[tokenId] != address(0)) { // query for invalid (split) token
            return false;
        }
        if (PlusCodes.getCodeLength(tokenId) > 2) { // It has a parent; This throws if it's not a valid plus code.
            uint256 parentTokenId = PlusCodes.getParent(tokenId);
            owner = _splitOwners[parentTokenId];
            if (owner != address(0)) {
                return true;
            }
        }
        return false;
    }

    /// @inheritdoc ERC721
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
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

// STATUS: RELEASE CANDIDATE 1
// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.9; // code below expects that integer overflows will revert

/// @title  Part of Area, 🌐 the earth on the blockchain, 📌 geolocation NFTs
/// @notice A multi-queue data structure for commits that are waiting to be revealed
/// @author William Entriken
library CommitQueue {
    struct Self {
        // Storage of all elements
        mapping(uint256 => Element) elements;

        // The position of the first element if queue is not empty
        uint32 startIndex;

        // The queue’s “past the end” position, i.e. one greater than the last valid subscript argument
        uint32 endIndex;

        // How many items (sum of Element.quantity) are in the queue
        uint256 length;
    }

    struct Element {
        // These sizes are chosen to fit in one EVM word
        address beneficiary;
        uint64 maturityBlock;
        uint32 quantity; // this must be greater than zero
    }

    /// @notice Adds a new entry to the end of the queue
    /// @param  self        the data structure
    /// @param  beneficiary an address associated with the commitment
    /// @param  quantity    how many to enqueue
    function enqueue(Self storage self, address beneficiary, uint32 quantity) internal {
        require(quantity > 0, "Quantity is missing");
        self.elements[self.endIndex] = Element(
            beneficiary,
            uint64(block.number), // maturityBlock, hash thereof not yet known
            quantity
        );
        self.endIndex += 1;
        self.length += quantity;
    }

    /// @notice Removes and returns the first element of the multi-queue; reverts if queue is empty
    /// @param  self          the data structure
    /// @return beneficiary   an address associated with the commitment
    /// @return maturityBlock when this commitment matured
    function dequeue(Self storage self) internal returns (address beneficiary, uint64 maturityBlock) {
        require(!_isEmpty(self), "Queue is empty");
        beneficiary = self.elements[self.startIndex].beneficiary;
        maturityBlock = self.elements[self.startIndex].maturityBlock;
        if (self.elements[self.startIndex].quantity == 1) {
            delete self.elements[self.startIndex];
            self.startIndex += 1;
        } else {
            self.elements[self.startIndex].quantity -= 1;
        }
        self.length -= 1;
    }

    /// @notice Checks whether the first element can be revealed
    /// @dev    Elements are added to the queue in order, so if the first element is not mature than neither are all
    ///         remaining elements.
    /// @param  self the data structure
    /// @return true if the first element exists and is mature; false otherwise
    function isMature(Self storage self) internal view returns (bool) {
        if (_isEmpty(self)) {
            return false;
        }
        return block.number > self.elements[self.startIndex].maturityBlock;
    }

    /// @notice Finds how many items are remaining to be dequeued
    /// @dev    This is the sum of Element.quantity.
    /// @param  self the data structure
    /// @return how many items are in the queue (i.e. how many dequeues can happen)
    function count(Self storage self) internal view returns (uint256) {
        return self.length;
    }

    /// @notice Whether or not the queue is empty
    /// @param  self the data structure
    /// @return true if the queue is empty; false otherwise
    function _isEmpty(Self storage self) private view returns (bool) {
        return self.startIndex == self.endIndex;
    }
}

// STATUS: RELEASE CANDIDATE 1
// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.9; // code below expects that integer overflows will revert

/// @title  Part of Area, 🌐 the earth on the blockchain, 📌 geolocation NFTs
/// @notice A data structure that supports random read and delete access and that efficiently initializes to a range of
///         [1, N]
/// @author William Entriken
library LazyArray {
    struct Self {
        // This stores element values and cannot represent an underlying value of zero.
        //
        // A zero value at index i represents an element of (i+1). Any other value stored in the array represents an
        // element of that value. We employ this technique because all storage in Solidity starts at zero.
        //
        // e.g. the array [0, 135, 243, 0, 500] represents the values [1, 135, 243, 5, 500]. Then if we remove the 135
        // that becomes [0, 500, 243, 0] which represents the values [1, 500, 243, 5].
        mapping(uint256 => uint256) elements;

        // Adding to this value logically appends a sequence to the array ending in `length`. E.g. changing from 0 to 2
        // makes [1, 2].
        uint256 length;
    }

    /// @notice Sets the logical contents to a range of [1, N]. Setting near 2**(256-DIFFICULTY) creates a security
    ///         vulnerability.
    /// @param  self          the data structure
    /// @param  initialLength how big to make the range
    function initialize(Self storage self, uint256 initialLength) internal {
        require(self.length == 0, "Cannot initialize non-empty structure");
        self.length = initialLength;
    }

    /// @notice Removes and returns the n-th logical element
    /// @param  self   the data structure
    /// @param  index  which element (zero indexed) to remove and return
    /// @return popped the specified element
    function popByIndex(Self storage self, uint256 index) internal returns (uint256 popped) {
        popped = getByIndex(self, index);
        uint256 lastIndex = self.length - 1; // will not underflow b/c prior get
        if (index < lastIndex) {
            uint256 lastElement = getByIndex(self, lastIndex);
            self.elements[index] = lastElement;
        }
        delete self.elements[lastIndex];
        self.length -= 1;
    }

    /// @notice Returns the n-th logical element
    /// @param  self    the data structure
    /// @param  index   which element (zero indexed) to get
    /// @return element the specified element
    function getByIndex(Self storage self, uint256 index) internal view returns (uint256 element) {
        require(index < self.length, "Out of bounds");
        return self.elements[index] == 0
            ? index + 1 // revert on overflow
            : self.elements[index];
    }

    /// @notice Finds how many items remain
    /// @param  self   the data structure
    /// @return the number of remaining items
    function count(Self storage self) internal view returns (uint256) {
        return self.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

