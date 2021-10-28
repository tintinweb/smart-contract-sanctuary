pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./HorseUtilityContract.sol";
import "base64-sol/base64.sol";

//
//   ____ _           _                _   _   _                       _   _ _____ _____
//  / ___| |__   __ _(_)_ __   ___  __| | | | | | ___  _ __ ___  ___  | \ | |  ___|_   _|
// | |   | '_ \ / _` | | '_ \ / _ \/ _` | | |_| |/ _ \| '__/ __|/ _ \ |  \| | |_    | |
// | |___| | | | (_| | | | | |  __/ (_| | |  _  | (_) | |  \__ \  __/ | |\  |  _|   | |
//  \____|_| |_|\__,_|_|_| |_|\___|\__,_| |_| |_|\___/|_|  |___/\___| |_| \_|_|     |_|
//
//
//
//                                                 ,,  //
//                                              .//,,,,,,,,,
//                                              .//,,,,@@,,,,,,,
//                                            /////,,,,,,,,,,,,,
//                                            /////,,,,,,
//                                            /////,,,,,,
//                                          ///////,,,,,,
//                                      ///////////,,,,,,
//                        /////,,,,,,,,,,,,,,,,,,,,,,,,,,
//                      /////,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                      /////,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                      /////,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                    ////   ,,  //                ,,  //
//                    ////   ,,  //                ,,  //
//                    ////   ,,  //                ,,  //
//                    //     ,,  //                ,,  //
//                           @@  @@                @@  @@
//
// ** ChainedHorseNFT: ChainedHorseTokenContract.sol **
// Written and developed by: Moonfarm
// Twitter: @spacesh1pdev
// Discord: Moonfarm#1138
//

contract ChainedHorseTokenContract is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    /**
     * Structure of tokens traits
     */
    struct TokenTraits {
        uint8 maneColor;
        uint8 patternColor;
        uint8 hoofColor;
        uint8 bodyColor;
        uint8 background;
        uint8 tail;
        uint8 mane;
        uint8 pattern;
        uint8 headAccessory;
        uint8 bodyAccessory;
        uint8 utility;
        bool burned;
    }

    /**
     * Define the utility contract address so we know where to fetch svgs from
     */
    address public utilityContract = 0x0000000000000000000000000000000000000001;

    /**
     * Pretty standard NFT contract variables
     */
    uint256 public maxTokens = 10000;
    uint256 public mintedTokens = 0;
    uint256 public burnedTokens = 0;
    uint256 public rebirthedTokens = 0;
    uint256 public mintPrice = 0.02 ether;
    uint256 public rebirthPrice = 0.01 ether;
    uint8 public claimableTokensPerAddress = 20;
    uint8 public maxTokensPerTxn = 5;
    bool public saleActive = false;

    /**
     * Whitelist info
     */
    uint256 public whitelistTokensUnlocksAtBlockNumber = 0;
    uint256 public whitelistAddressCount = 0;

    /**
     * Burned horse base64-image
     */
    string ashes =
        "data:image/svg+xml;base64,PHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHZpZXdCb3g9JzAgMCAzMiAzMic+PHBhdGggZmlsbD0nI2QxZDNkNCcgZD0nTTAgMGgzMnYzMkgweicvPjxwYXRoIGZpbGw9JyM1ODU5NWInIGQ9J00xMCAyN0g5di0xaDF6bTEwIDBoLTF2LTFoMXptMiAwaC0xdi0xaDF6Jy8+PHBhdGggZmlsbD0nIzIzMWYyMCcgZD0nTTIzIDI3aC0xdi0xaDF6Jy8+PHBhdGggZmlsbD0nIzU4NTk1YicgZD0nTTI0IDI3aC0xdi0xaDF6bTEgMGgtMXYtMWgxem0tMTQgMGgtMXYtMWgxem0xIDBoLTF2LTFoMXptMSAwaC0xdi0xaDF6bTEgMGgtMXYtMWgxem0xIDBoLTF2LTFoMXptMSAwaC0xdi0xaDF6bTEgMGgtMXYtMWgxeicvPjxwYXRoIGZpbGw9JyM4MDgyODUnIGQ9J00xOCAyN2gtMXYtMWgxeicvPjxwYXRoIGZpbGw9JyM1ODU5NWInIGQ9J00xOSAyN2gtMXYtMWgxem0yIDBoLTF2LTFoMXptMC0xaC0xdi0xaDF6bS0xIDBoLTF2LTFoMXptLTEgMGgtMXYtMWgxem0tMSAwaC0xdi0xaDF6bS0xIDBoLTF2LTFoMXonLz48cGF0aCBmaWxsPScjMjMxZjIwJyBkPSdNMTYgMjZoLTF2LTFoMXonLz48cGF0aCBmaWxsPScjNTg1OTViJyBkPSdNMTUgMjZoLTF2LTFoMXptMS0xaC0xdi0xaDF6bTEgMGgtMXYtMWgxeicvPjxwYXRoIGZpbGw9JyMyMzFmMjAnIGQ9J00xOCAyNWgtMXYtMWgxeicvPjxwYXRoIGZpbGw9JyM1ODU5NWInIGQ9J00xOSAyNWgtMXYtMWgxem0xIDBoLTF2LTFoMXptLTEtMWgtMXYtMWgxeicvPjxwYXRoIGZpbGw9JyM4MDgyODUnIGQ9J00xNyAyNGgtMXYtMWgxeicvPjxwYXRoIGZpbGw9JyM1ODU5NWInIGQ9J00xOCAyNGgtMXYtMWgxem0tNCAyaC0xdi0xaDF6Jy8+PHBhdGggZmlsbD0nIzgwODI4NScgZD0nTTEzIDI2aC0xdi0xaDF6Jy8+PHBhdGggZmlsbD0nIzU4NTk1YicgZD0nTTEyIDI2aC0xdi0xaDF6Jy8+PC9zdmc+";

    /**
     * Amount of tokens a specific whitelist address has left to mint
     *
     * Always starts at 20 for each address added
     */
    mapping(address => uint256) public whitelistedAddressMintsLeft;

    /**
     * Save traits for each token
     */
    mapping(uint256 => TokenTraits) public traits;

    /**
     * Pretty standard constructor variables, nothing wierd here
     *
     * Mints #0 to the creator
     */
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 _maxTokens,
        address _utilityContract
    ) ERC721(tokenName, tokenSymbol) {
        maxTokens = _maxTokens;
        utilityContract = _utilityContract;
        mint(1);
    }

    /**
     * 1) Sets whitelisted tokens to be available for public mint in
     *    40320 blocks from the block this function was called (approximately a week)
     * 2) Starts the sale
     */
    function startSale() public onlyOwner {
        whitelistTokensUnlocksAtBlockNumber = block.number + 40320; // approximately a week
        saleActive = true;
    }

    /**
     * Standard withdraw function
     */
    function withdraw() public onlyOwner {
        uint256 balance = payable(address(this)).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Bundle metadata so it follows the standard
     */
    function packMetaData(
        string memory name,
        string memory svg,
        uint256 last
    ) private pure returns (bytes memory) {
        string memory comma = ",";
        if (last > 0) comma = "";
        return
            abi.encodePacked(
                '{"trait_type": "',
                name,
                '", "value": "',
                svg,
                '"}',
                comma
            );
    }

    /**
     * Private function so it can be called cheaper from tokenURI and tokenSVG
     */
    function _tokenSVG(uint256 tokenId) private view returns (string memory) {
        TokenTraits memory _traits = traits[tokenId];

        bytes memory _horseColors = HorseUtilityContract(utilityContract)
            .renderColors(
                _traits.maneColor,
                _traits.patternColor,
                _traits.hoofColor,
                _traits.bodyColor
            );

        return
            Base64.encode(
                HorseUtilityContract(utilityContract).renderHorse(
                    _horseColors,
                    _traits.background,
                    _traits.tail,
                    _traits.mane,
                    _traits.pattern,
                    _traits.headAccessory,
                    _traits.bodyAccessory,
                    _traits.utility
                )
            );
    }

    /**
     * Get the svg for a token in base64 format
     *
     * Comment:
     * Uses the UtilityContract to get svg-information for each attribute
     */
    function tokenSVG(uint256 tokenId) public view returns (string memory) {
        bool lessThanMinted = tokenId < mintedTokens;
        bool lessThanMintedRebirthOrMoreThanStartOfRebirth = tokenId <
            (maxTokens + burnedTokens) &&
            tokenId > maxTokens;
        if (
            !_exists(tokenId) &&
            (lessThanMinted || lessThanMintedRebirthOrMoreThanStartOfRebirth)
        ) {
            return ashes;
        }

        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    _tokenSVG(tokenId)
                )
            );
    }

    /**
     * Get the metadata for a token in base64 format
     *
     * Comment:
     * Uses the UtilityContract to get svg-information for each attribute
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        bool lessThanMinted = tokenId < mintedTokens;
        bool lessThanMintedRebirthOrMoreThanStartOfRebirth = tokenId <
            (maxTokens + burnedTokens) &&
            tokenId > maxTokens;
        if (
            !_exists(tokenId) &&
            (lessThanMinted || lessThanMintedRebirthOrMoreThanStartOfRebirth)
        ) {
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '{"name":"Burned Chained Horse #',
                                uint2str(tokenId),
                                '", "description": "A horse that lives on the ethereum blockchain.", "attributes": [',
                                packMetaData("status", "burned", 1),
                                '], "image":"',
                                ashes,
                                '"}'
                            )
                        )
                    )
                );
        }
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        TokenTraits memory _traits = traits[tokenId];

        bytes memory _properties = abi.encodePacked(
            packMetaData(
                "background",
                HorseUtilityContract(utilityContract).getBackground(
                    _traits.background
                ),
                0
            ),
            packMetaData(
                "tail",
                HorseUtilityContract(utilityContract).getTail(_traits.tail),
                0
            ),
            packMetaData(
                "mane",
                HorseUtilityContract(utilityContract).getMane(_traits.mane),
                0
            ),
            packMetaData(
                "pattern",
                HorseUtilityContract(utilityContract).getPattern(
                    _traits.pattern
                ),
                0
            ),
            packMetaData(
                "head accessory",
                HorseUtilityContract(utilityContract).getHeadAccessory(
                    _traits.headAccessory
                ),
                0
            ),
            packMetaData(
                "body accessory",
                HorseUtilityContract(utilityContract).getBodyAccessory(
                    _traits.bodyAccessory
                ),
                0
            ),
            packMetaData(
                "utility",
                HorseUtilityContract(utilityContract).getUtility(
                    _traits.utility
                ),
                0
            )
        );

        _properties = abi.encodePacked(
            _properties,
            packMetaData(
                "mane color",
                HorseUtilityContract(utilityContract).getManeColor(
                    traits[tokenId].maneColor
                ),
                0
            ),
            packMetaData(
                "pattern color",
                HorseUtilityContract(utilityContract).getPatternColor(
                    traits[tokenId].patternColor
                ),
                0
            ),
            packMetaData(
                "hoof color",
                HorseUtilityContract(utilityContract).getHoofColor(
                    traits[tokenId].hoofColor
                ),
                0
            ),
            packMetaData(
                "body color",
                HorseUtilityContract(utilityContract).getBodyColor(
                    traits[tokenId].bodyColor
                ),
                1
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"Chained Horse #',
                            uint2str(tokenId),
                            '", "description": "A horse that lives on the ethereum blockchain.", "attributes": [',
                            _properties,
                            '], "image":"data:image/svg+xml;base64,',
                            _tokenSVG(tokenId),
                            '"}'
                        )
                    )
                )
            );
    }

    /**
     * A claim function for whitelisted addresses until claim-period is over
     */
    function claim(uint256 amount) public {
        require(
            whitelistedAddressMintsLeft[msg.sender] >= amount,
            "Exceeded amount of claims left on address"
        );
        require(
            whitelistTokensUnlocksAtBlockNumber > block.number,
            "Claim period is over"
        );
        mint(amount);
        whitelistedAddressMintsLeft[msg.sender] -= amount;
    }

    /**
     * A mint function for anyone
     */
    function publicMint(uint256 amount) public payable {
        require(
            amount.add(mintedTokens) <=
                maxTokens -
                    (whitelistAddressCount * claimableTokensPerAddress) ||
                block.number > whitelistTokensUnlocksAtBlockNumber,
            "Tokens left are for whitelist"
        );
        require(mintPrice.mul(amount) <= msg.value, "Not enough ether to mint");
        require(saleActive, "Sale has not started");
        mint(amount);
    }

    /**
     * Mint with requirements that both claim and publicMint needs to follow
     */
    function mint(uint256 amount) private {
        require(
            amount <= maxTokensPerTxn,
            "Trying to mint more than allowed tokens"
        );
        require(
            amount.add(mintedTokens) <= maxTokens,
            "Amount exceeded max tokens"
        );
        for (uint256 i = 0; i < amount; i++) {
            generateTraits(mintedTokens + i);
            _safeMint(msg.sender, mintedTokens + i);
        }
        mintedTokens += amount;
    }

    /**
     * Rebirth a horse by burning two horses owned by the caller
     */
    function rebirth(uint256 tokenId1, uint256 tokenId2) public payable {
        require(tokenId1 != tokenId2, "Not different tokens");
        require(ownerOf(tokenId1) == msg.sender, "Not owner of token");
        require(ownerOf(tokenId2) == msg.sender, "Not owner of token");
        require(!traits[tokenId1].burned, "Already burned");
        require(!traits[tokenId2].burned, "Already burned");
        require(msg.value == rebirthPrice, "Not enough ether to rebirth");

        traits[tokenId1].burned = true;
        traits[tokenId2].burned = true;
        _burn(tokenId1);
        _burn(tokenId2);

        burnedTokens += 2;

        uint256 rebirthTokenId = maxTokens.add(rebirthedTokens);
        generateTraits(rebirthTokenId);
        _safeMint(msg.sender, rebirthTokenId);
        rebirthedTokens++;
    }

    function generateTraits(uint256 tokenId) private {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, tokenId)
            )
        );
        (
            uint8 maneColor,
            uint8 patternColor,
            uint8 hoofColor,
            uint8 bodyColor,
            uint8 background,
            uint8 tail,
            uint8 mane,
            uint8 pattern,
            uint8 headAccessory,
            uint8 bodyAccessory,
            uint8 utility
        ) = HorseUtilityContract(utilityContract).getRandomAttributes(
                randomNumber
            );
        traits[tokenId] = TokenTraits(
            maneColor,
            patternColor,
            hoofColor,
            bodyColor,
            background,
            tail,
            mane,
            pattern,
            headAccessory,
            bodyAccessory,
            utility,
            false
        );
    }

    /**
     * Add an address to the whitelist
     */
    function addWhitelistAddresses(address[] memory newWhitelistMembers)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < newWhitelistMembers.length; i++) {
            whitelistedAddressMintsLeft[
                newWhitelistMembers[i]
            ] = claimableTokensPerAddress;
            whitelistAddressCount++;
        }
    }

    /**
     * Small function to convert uint to string
     */
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT

//
//   ____ _           _                _   _   _                       _   _ _____ _____
//  / ___| |__   __ _(_)_ __   ___  __| | | | | | ___  _ __ ___  ___  | \ | |  ___|_   _|
// | |   | '_ \ / _` | | '_ \ / _ \/ _` | | |_| |/ _ \| '__/ __|/ _ \ |  \| | |_    | |
// | |___| | | | (_| | | | | |  __/ (_| | |  _  | (_) | |  \__ \  __/ | |\  |  _|   | |
//  \____|_| |_|\__,_|_|_| |_|\___|\__,_| |_| |_|\___/|_|  |___/\___| |_| \_|_|     |_|
//
//
//
//                                                 ,,  //
//                                              .//,,,,,,,,,
//                                              .//,,,,@@,,,,,,,
//                                            /////,,,,,,,,,,,,,
//                                            /////,,,,,,
//                                            /////,,,,,,
//                                          ///////,,,,,,
//                                      ///////////,,,,,,
//                        /////,,,,,,,,,,,,,,,,,,,,,,,,,,
//                      /////,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                      /////,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                      /////,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                    ////   ,,  //                ,,  //
//                    ////   ,,  //                ,,  //
//                    ////   ,,  //                ,,  //
//                    //     ,,  //                ,,  //
//                           @@  @@                @@  @@
//
// ** ChainedHorseNFT: HorseUtilityContract.sol **
// Written and developed by: Moonfarm
// Twitter: @spacesh1pdev
// Discord: Moonfarm#1138
//

contract HorseUtilityContract {
    //SVG-parts
    string constant svgStart =
        "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 32 32'>";
    string constant svgEnd = "</svg>";
    string constant base =
        "<path fill='url(#body-color)' d='M19 7h1v1h-1zm2 0h1v1h-1zm-2 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1zm-1 0h1v1H9zm0 1h1v1H9zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1H9zm0-1h1v1H9zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-3 3h1v1H9zm0 1h1v1H9zm0 1h1v1H9zm0 1h1v1H9zm2 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm8 0h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm2 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1z' /><path fill='#000' opacity='.35' d='M21 7h1v1h-1zm0 14h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm-10 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1z' /><path fill='url(#hoof-color)' d='M9 25h1v1H9zm2 0h1v1h-1zm8 0h1v1h-1zm2 0h1v1h-1z' /><path fill='#000' d='M21 10h1v1h-1z' />";

    // attribute svgs
    string[] private maneColorSvgs = [
        "#000",
        "#da5d97",
        "#806bd5",
        "#b05ecd",
        "#f25a5f",
        "#ff8c2f",
        "#fff",
        "#00b7e6",
        "#3fa966",
        "#3d6ccd",
        "#ebbd54"
    ];
    string[] private patternColorSvgs = [
        "#643323",
        "#333",
        "#72d2ff",
        "#f1c5d1",
        "#dad4f7",
        "#6ecb63",
        "#da3832",
        "#fffac8",
        "#df6436",
        "#50b7e6",
        "#ff0075",
        "#fff"
    ];
    string[] private hoofColorSvgs = [
        "#000",
        "#544116",
        "#22577a",
        "#7e5b24",
        "#004927",
        "#008762",
        "#d53832",
        "#b0c7e6",
        "#76267b",
        "#e6adb0",
        "#ebbd54"
    ];
    string[] private bodyColorSvgs = [
        "#dfc969",
        "#685991",
        "#6d6e71",
        "#845f36",
        "#fff",
        "#6ecb63",
        "#b4255b",
        "#418151",
        "#007791",
        "#ebbd54"
    ];
    string[] private headAccessorySvgs = [
        "",
        "<path fill='#912b61' d='M19 8h1v1h-1zM19 7h1v1h-1zM20 7h1v1h-1zM21 7h1v1h-1zM21 8h1v1h-1zM20 8h1v1h-1zM22 8h1v1h-1zM23 8h1v1h-1zM24 8h1v1h-1zM22 7h1v1h-1z' />",
        "<path fill='#da3832' d='M19 8h1v1h-1zM19 7h1v1h-1zM20 7h1v1h-1z' /><path fill='#fae84b' d='M20 8h1v1h-1zM21 8h1v1h-1zM21 7h1v1h-1z' /><path fill='#4a549f' d='M22 7h1v1h-1zM22 8h1v1h-1z' /><path fill='#119b55' d='M23 8h1v1h-1zM24 8h1v1h-1z' /><path fill='#3e4e9c' d='M21 6h1v1h-1zM21 5h1v1h-1zM20 5h1v1h-1zM22 5h1v1h-1z' />",
        "<path fill='#ebbd54' d='M18 15h1v1h-1zM18 16h1v1h-1zM19 17h1v1h-1zM20 18h1v1h-1zM21 18h1v1h-1zM22 18h1v1h-1zM22 19h1v1h-1zM21 19h1v1h-1z' />",
        "<path fill='#1fafff' d='M22 9h1v1h-1zM22 8h1v1h-1zM23 8h1v1h-1zM23 7h1v1h-1zM24 7h1v1h-1zM24 6h1v1h-1zM24 5h1v1h-1z' />",
        "<path fill='#ebbc53' d='M26 10h1v1h-1zM25 11h1v1h-1zM27 10h1v1h-1zM27 12h1v1h-1zM28 12h1v1h-1zM28 11h1v1h-1zM29 12h1v1h-1zM29 11h1v1h-1zM30 11h1v1h-1z' /><path fill='#d53931' d='M27 11h1v1h-1zM26 11h1v1h-1z' /><path fill='#ebbc53' d='M28 10h1v1h-1z' />",
        "<path fill='#000' d='M18 8h1v1h-1zM19 8h1v1h-1zM19 7h1v1h-1zM19 6h1v1h-1zM20 6h1v1h-1zM20 7h1v1h-1zM19 5h1v1h-1zM20 5h1v1h-1zM21 5h1v1h-1zM22 5h1v1h-1zM20 8h1v1h-1zM21 8h1v1h-1zM21 7h1v1h-1zM21 6h1v1h-1zM22 8h1v1h-1zM22 7h1v1h-1zM22 6h1v1h-1zM23 8h1v1h-1z' />",
        "<path fill='#af3034' d='M19 9h1v1h-1zM19 8h1v1h-1zM19 7h1v1h-1zM19 6h1v1h-1z' /><path fill='#7c231f' d='M21 8h1v1h-1zM21 7h1v1h-1zM21 6h1v1h-1z' />",
        "<path fill='#2d388b' d='M17 9h1v1h-1zM17 8h1v1h-1zM18 9h1v1h-1z' /><path fill='#ebbd54' d='M19 7h1v1h-1z' /><path fill='#2d388b' d='M19 6h1v1h-1zM19 5h1v1h-1zM19 4h1v1h-1zM18 4h1v1h-1zM17 4h1v1h-1zM17 5h1v1h-1zM20 5h1v1h-1zM21 6h1v1h-1zM20 6h1v1h-1zM20 7h1v1h-1zM21 7h1v1h-1z' /><path fill='#ebbd54' d='M21 8h1v1h-1z' /><path fill='#2d388b' d='M22 8h1v1h-1zM22 7h1v1h-1zM24 7h1v1h-1zM23 8h1v1h-1zM20 8h1v1h-1zM19 9h1v1h-1zM19 8h1v1h-1z' />",
        "<path fill='#e65157' d='M21 10h1v1h-1zM22 10h1v1h-1zM23 10h1v1h-1zM24 10h1v1h-1zM25 10h1v1h-1zM26 10h1v1h-1zM27 10h1v1h-1zM28 10h1v1h-1zM29 10h1v1h-1zM30 10h1v1h-1zM31 10h1v1h-1z' />",
        "<path fill='#7f5748' d='M19 9h1v1h-1zM19 8h1v1h-1zM20 7h1v1h-1z' /><path fill='#b2b6ba' d='M20 8h1v1h-1z' /><path fill='#7f5748' d='M20 9h1v1h-1zM21 9h1v1h-1zM21 8h1v1h-1z' /><path fill='#b2b6ba' d='M19 7h1v1h-1zM19 6h1v1h-1zM19 5h1v1h-1z' /><path fill='#8e959c' d='M22 6h1v1h-1zM22 5h1v1h-1z' /><path fill='#7f5748' d='M21 7h1v1h-1zM22 7h1v1h-1zM22 8h1v1h-1zM22 9h1v1h-1zM23 8h1v1h-1zM23 9h1v1h-1z' />",
        "<path fill='#ebbd54' d='M18 4h1v1h-1zM19 5h1v1h-1zM20 5h1v1h-1zM21 5h1v1h-1zM22 5h1v1h-1zM23 4h1v1h-1zM22 3h1v1h-1zM21 3h1v1h-1zM20 3h1v1h-1zM19 3h1v1h-1z' />",
        "<path fill='#86c661' d='M25 14h1v1h-1zm0 1h1v1h-1z' /><path fill='#04b3e9' d='M25 16h1v1h-1z' /><path fill='#86c661' d='M25 19h1v1h-1zm0-1h1v1h-1z' /><path fill='#04b3e9' d='M25 21h1v1h-1z' /><path fill='#fbee41' d='M24 12h1v1h-1zm0 2h1v1h-1z' /><path fill='#f58220' d='M24 13h1v1h-1z' /><path fill='#fbee41' d='M24 16h1v1h-1zm0 2h1v1h-1zm0-3h1v1h-1z' /><path fill='#ef4354' d='M23 12h1v1h-1z' /><path fill='#f58220' d='M23 16h1v1h-1z' /><path fill='#ef4354' d='M23 15h1v1h-1zm0 2h1v1h-1zm0 2h1v1h-1zm0-6h1v1h-1z' />",
        "<path fill='#ebbd54' d='M19 9h1v1h-1zM19 8h1v1h-1zM19 7h1v1h-1zM19 6h1v1h-1zM20 7h1v1h-1zM20 8h1v1h-1zM20 9h1v1h-1zM21 9h1v1h-1zM21 8h1v1h-1zM21 7h1v1h-1zM21 6h1v1h-1zM22 7h1v1h-1zM22 8h1v1h-1zM22 9h1v1h-1zM23 6h1v1h-1zM23 7h1v1h-1zM23 8h1v1h-1zM23 9h1v1h-1z' />"
    ];
    string[] private bodyAccessorySvgs = [
        "",
        "<path fill='#898989' d='M12 16h1v1h-1zM12 17h1v1h-1zM12 18h1v1h-1zM12 19h1v1h-1zM12 20h1v1h-1zM17 20h1v1h-1zM17 19h1v1h-1zM17 18h1v1h-1zM17 17h1v1h-1z' /><path fill='#221f20' d='M14 17h1v1h-1z' /><path fill='#fff' d='M14 16h1v1h-1zM15 16h1v1h-1zM16 16h1v1h-1zM16 17h1v1h-1zM16 18h1v1h-1zM16 19h1v1h-1zM16 20h1v1h-1zM14 20h1v1h-1zM14 19h1v1h-1zM14 18h1v1h-1zM13 18h1v1h-1zM13 17h1v1h-1zM13 16h1v1h-1zM13 19h1v1h-1zM13 20h1v1h-1z' /><path fill='#221f20' d='M15 17h1v1h-1zM15 18h1v1h-1zM15 19h1v1h-1zM15 20h1v1h-1z' /><path fill='#898989' d='M17 16h1v1h-1z' />",
        "<path fill='#af7139' d='M9 23h1v1H9zM9 24h1v1H9zM9 25h1v1H9zM10 25h1v1h-1z' /><path fill='#643323' d='M11 23h1v1h-1zM11 24h1v1h-1zM11 25h1v1h-1zM12 25h1v1h-1z' /><path fill='#af7139' d='M19 23h1v1h-1zM19 24h1v1h-1zM19 25h1v1h-1zM20 25h1v1h-1z' /><path fill='#643323' d='M21 23h1v1h-1zM21 24h1v1h-1zM21 25h1v1h-1zM22 25h1v1h-1z' />",
        "<path fill='#ff8c2f' d='M15 16h1v1h-1z' /><path fill='#e65157' d='M15 15h1v1h-1z' /><path fill='#ff8c2f' d='M14 15h1v1h-1z' /><path fill='#fff560' d='M14 16h1v1h-1z' /><path fill='#94ce6e' d='M13 16h1v1h-1z' /><path fill='#fff560' d='M13 15h1v1h-1z' /><path fill='#94ce6e' d='M12 15h1v1h-1z' /><path fill='#1db1e3' d='M12 16h1v1h-1zM11 15h1v1h-1z' /><path fill='#e65157' d='M14 14h1v1h-1z' /><path fill='#ff8c2f' d='M13 14h1v1h-1z' /><path fill='#fff560' d='M12 14h1v1h-1z' /><path fill='#94ce6e' d='M11 14h1v1h-1z' /><path fill='#1db1e3' d='M10 14h1v1h-1z' /><path fill='#e65157' d='M12 13h1v1h-1z' /><path fill='#ff8c2f' d='M11 13h1v1h-1z' /><path fill='#fff560' d='M10 13h1v1h-1z' /><path fill='#94ce6e' d='M9 13h1v1H9z' /><path fill='#1db1e3' d='M8 13h1v1H8z' /><path fill='#e65157' d='M10 12h1v1h-1z' /><path fill='#ff8c2f' d='M9 12h1v1H9z' /><path fill='#fff560' d='M8 12h1v1H8z' /><path fill='#94ce6e' d='M7 12h1v1H7z' /><path fill='#1db1e3' d='M6 12h1v1H6z' /><path fill='#e65157' d='M8 11h1v1H8z' /><path fill='#ff8c2f' d='M7 11h1v1H7z' /><path fill='#fff560' d='M6 11h1v1H6z' /><path fill='#94ce6e' d='M5 11h1v1H5z' /><path fill='#1db1e3' d='M4 11h1v1H4z' /><path fill='#e65157' d='M5 10h1v1H5z' /><path fill='#ff8c2f' d='M4 10h1v1H4z' /><path fill='#fff560' d='M3 10h1v1H3z' /><path fill='#94ce6e' d='M2 10h1v1H2z' /><path fill='#1db1e3' d='M1 10h1v1H1z' /><path fill='#e65157' d='M2 9h1v1H2z' /><path fill='#ff8c2f' d='M1 9h1v1H1z' /><path fill='#fff560' d='M0 9h1v1H0z' />",
        "<path fill='#fdef38' d='M14 12h1v1h-1zM13 12h1v1h-1zM12 11h1v1h-1zM9 13h1v1H9zM9 14h1v1H9zM10 15h1v1h-1zM13 17h1v1h-1zM13 18h1v1h-1zM14 19h1v1h-1zM14 20h1v1h-1zM15 21h1v1h-1zM23 18h1v1h-1zM23 17h1v1h-1zM22 16h1v1h-1zM23 24h1v1h-1zM24 24h1v1h-1zM25 23h1v1h-1zM26 23h1v1h-1zM25 14h1v1h-1zM24 13h1v1h-1zM13 23h1v1h-1zM14 24h1v1h-1zM15 24h1v1h-1zM19 17h1v1h-1zM19 16h1v1h-1zM19 15h1v1h-1zM18 14h1v1h-1zM18 13h1v1h-1z' />",
        "<path fill='#4487ab' d='M15 16h1v1h-1z' /><path fill='#addbfb' d='M14 16h1v1h-1zM14 14h1v1h-1z' /><path fill='#4487ab' d='M15 14h1v1h-1zM15 13h1v1h-1zM14 13h1v1h-1zM13 14h1v1h-1z' /><path fill='#addbfb' d='M13 13h1v1h-1z' /><path fill='#4487ab' d='M12 13h1v1h-1z' /><path fill='#addbfb' d='M12 14h1v1h-1zM11 13h1v1h-1zM11 12h1v1h-1zM10 13h1v1h-1zM9 12h1v1H9zM8 11h1v1H8z' /><path fill='#4487ab' d='M8 10h1v1H8zM9 13h1v1H9z' /><path fill='#addbfb' d='M9 11h1v1H9zM10 12h1v1h-1z' /><path fill='#4487ab' d='M14 12h1v1h-1zM13 12h1v1h-1z' /><path fill='#addbfb' d='M12 12h1v1h-1z' /><path fill='#4487ab' d='M12 11h1v1h-1zM11 11h1v1h-1zM10 11h1v1h-1z' /><path fill='#addbfb' d='M11 14h1v1h-1zM10 14h1v1h-1z' /><path fill='#4487ab' d='M15 15h1v1h-1z' /><path fill='#addbfb' d='M14 15h1v1h-1zM13 15h1v1h-1zM12 15h1v1h-1z' /><path fill='#4487ab' d='M9 10h1v1H9z' />",
        "<path fill='#afadb0' d='M14 15h1v1h-1zM15 15h1v1h-1zM15 14h1v1h-1zM14 14h1v1h-1zM14 13h1v1h-1zM15 13h1v1h-1zM16 13h1v1h-1zM16 14h1v1h-1zM14 12h1v1h-1zM13 12h1v1h-1zM13 13h1v1h-1zM13 14h1v1h-1zM12 14h1v1h-1zM12 13h1v1h-1zM12 12h1v1h-1zM11 12h1v1h-1zM11 13h1v1h-1zM11 14h1v1h-1z' /><path fill='#f25a5f' d='M10 13h1v1h-1z' /><path fill='#f3cb4e' d='M10 12h1v1h-1zM9 12h1v1H9z' /><path fill='#f25a5f' d='M9 13h1v1H9z' /><path fill='#f3cb4e' d='M8 13h1v1H8zM8 12h1v1H8zM7 12h1v1H7zM7 13h1v1H7zM6 13h1v1H6zM10 14h1v1h-1zM9 14h1v1H9zM8 14h1v1H8z' />",
        "<path d='M14 15h1v1h-1zM14 14h1v1h-1zM13 14h1v1h-1zM13 15h1v1h-1zM12 15h1v1h-1zM12 14h1v1h-1zM11 14h1v1h-1zM11 15h1v1h-1zM11 16h1v1h-1zM11 17h1v1h-1zM11 18h1v1h-1zM14 13h1v1h-1zM14 12h1v1h-1zM13 12h1v1h-1zM13 13h1v1h-1zM12 13h1v1h-1zM13 11h1v1h-1zM13 10h1v1h-1zM14 10h1v1h-1zM14 11h1v1h-1zM13 9h1v1h-1zM15 11h1v1h-1zM15 10h1v1h-1z' /><path fill='#f8e100' d='M14 10h1v1h-1z' />",
        "<path fill='#221f20' d='M15 16h1v1h-1z' /><path fill='#5d5e60' d='M14 16h1v1h-1zM14 14h1v1h-1z' /><path fill='#221f20' d='M15 14h1v1h-1zM15 13h1v1h-1zM14 13h1v1h-1zM13 14h1v1h-1z' /><path fill='#5d5e60' d='M13 13h1v1h-1z' /><path fill='#221f20' d='M12 13h1v1h-1z' /><path fill='#5d5e60' d='M12 14h1v1h-1zM11 13h1v1h-1zM11 12h1v1h-1zM10 13h1v1h-1zM9 12h1v1H9zM8 11h1v1H8z' /><path fill='#221f20' d='M8 10h1v1H8zM9 13h1v1H9z' /><path fill='#5d5e60' d='M9 11h1v1H9zM10 12h1v1h-1z' /><path fill='#221f20' d='M14 12h1v1h-1zM13 12h1v1h-1z' /><path fill='#5d5e60' d='M12 12h1v1h-1z' /><path fill='#221f20' d='M12 11h1v1h-1zM11 11h1v1h-1zM10 11h1v1h-1z' /><path fill='#5d5e60' d='M11 14h1v1h-1zM10 14h1v1h-1z' /><path fill='#221f20' d='M15 15h1v1h-1z' /><path fill='#5d5e60' d='M14 15h1v1h-1zM13 15h1v1h-1zM12 15h1v1h-1z' /><path fill='#221f20' d='M9 10h1v1H9z' />"
    ];
    string[] private patternSvgs = [
        "<path fill='url(#pattern-color)' d='M19 7h1v1h-1zM21 7h1v1h-1zM23 10h1v1h-1zM24 10h1v1h-1zM19 12h1v1h-1zM19 13h1v1h-1zM21 14h1v1h-1zM21 15h1v1h-1zM19 17h1v1h-1zM20 18h1v1h-1zM16 18h1v1h-1zM16 17h1v1h-1zM14 16h1v1h-1zM13 17h1v1h-1zM14 20h1v1h-1zM13 20h1v1h-1zM18 20h1v1h-1zM19 21h1v1h-1zM21 24h1v1h-1zM21 23h1v1h-1zM9 20h1v1H9zM9 21h1v1H9zM11 16h1v1h-1zM11 17h1v1h-1z' />",
        "<path fill='url(#pattern-color)' d='M19 14h1v1h-1zM21 17h1v1h-1zM18 19h1v1h-1zM20 20h1v1h-1zM14 16h1v1h-1zM12 19h1v1h-1zM11 17h1v1h-1zM16 20h1v1h-1zM9 23h1v1H9z' />",
        "<path fill='url(#pattern-color)' d='M16 16h1v1h-1zM15 17h1v1h-1zM16 17h1v1h-1zM16 18h1v1h-1zM16 19h1v1h-1zM17 19h1v1h-1zM17 20h1v1h-1zM15 18h1v1h-1zM15 19h1v1h-1zM16 20h1v1h-1zM15 20h1v1h-1zM14 20h1v1h-1zM13 20h1v1h-1zM12 20h1v1h-1zM11 20h1v1h-1zM11 21h1v1h-1zM11 22h1v1h-1zM11 23h1v1h-1zM11 24h1v1h-1zM9 24h1v1H9zM9 23h1v1H9zM9 22h1v1H9zM9 21h1v1H9zM9 20h1v1H9zM10 20h1v1h-1zM10 19h1v1h-1zM9 19h1v1H9zM9 18h1v1H9zM9 17h1v1H9zM10 17h1v1h-1zM10 16h1v1h-1zM11 16h1v1h-1zM12 16h1v1h-1zM13 16h1v1h-1zM14 16h1v1h-1zM15 16h1v1h-1zM14 17h1v1h-1zM14 18h1v1h-1zM14 19h1v1h-1zM13 19h1v1h-1zM13 18h1v1h-1zM13 17h1v1h-1zM12 17h1v1h-1zM12 18h1v1h-1zM12 19h1v1h-1zM11 19h1v1h-1zM11 18h1v1h-1zM11 17h1v1h-1zM10 18h1v1h-1z' />",
        "<path fill='url(#pattern-color)' d='M24 10h1v1h-1zM19 7h1v1h-1zM21 7h1v1h-1z' />",
        "<path fill='url(#pattern-color)' d='M9 19h1v1H9zM10 19h1v1h-1zM11 18h1v1h-1zM12 18h1v1h-1zM13 17h1v1h-1zM14 17h1v1h-1zM15 17h1v1h-1zM16 18h1v1h-1zM17 18h1v1h-1zM18 18h1v1h-1zM19 19h1v1h-1zM20 19h1v1h-1zM21 18h1v1h-1zM19 12h1v1h-1zM20 13h1v1h-1zM21 14h1v1h-1zM21 15h1v1h-1zM17 20h1v1h-1zM16 20h1v1h-1zM15 20h1v1h-1zM9 22h1v1H9zM9 23h1v1H9zM9 24h1v1H9z' />",
        "<path fill='url(#pattern-color)' d='M12 16h1v1h-1zM11 17h1v1h-1zM10 18h1v1h-1zM9 19h1v1H9zM9 23h1v1H9zM12 20h1v1h-1zM13 19h1v1h-1zM14 18h1v1h-1zM15 17h1v1h-1zM15 16h1v1h-1zM18 16h1v1h-1zM18 17h1v1h-1zM18 18h1v1h-1zM18 19h1v1h-1zM17 20h1v1h-1zM21 17h1v1h-1zM20 16h1v1h-1zM20 15h1v1h-1zM19 14h1v1h-1zM19 11h1v1h-1zM20 12h1v1h-1zM21 13h1v1h-1zM19 22h1v1h-1zM21 24h1v1h-1zM11 22h1v1h-1z'/>",
        "<path fill='url(#pattern-color)' d='M9 18h1v1H9zM10 17h1v1h-1zM11 18h1v1h-1zM12 17h1v1h-1zM13 18h1v1h-1zM14 17h1v1h-1zM15 18h1v1h-1zM16 17h1v1h-1zM17 18h1v1h-1zM18 17h1v1h-1zM19 18h1v1h-1zM20 17h1v1h-1zM21 18h1v1h-1zM10 19h1v1h-1zM9 20h1v1H9zM11 20h1v1h-1zM12 19h1v1h-1zM13 20h1v1h-1zM14 19h1v1h-1zM15 20h1v1h-1zM16 19h1v1h-1zM17 20h1v1h-1zM18 19h1v1h-1zM19 20h1v1h-1zM20 19h1v1h-1zM21 20h1v1h-1zM21 16h1v1h-1zM19 16h1v1h-1zM20 15h1v1h-1zM19 14h1v1h-1zM20 13h1v1h-1zM19 12h1v1h-1zM19 22h1v1h-1zM19 24h1v1h-1zM9 22h1v1H9zM9 24h1v1H9zM11 24h1v1h-1zM11 22h1v1h-1zM21 22h1v1h-1zM21 24h1v1h-1z' />",
        "<path fill='url(#pattern-color)' d='M12 17h1v1h-1zM12 18h1v1h-1zM11 18h1v1h-1zM11 19h1v1h-1zM12 19h1v1h-1zM12 20h1v1h-1zM13 20h1v1h-1zM13 19h1v1h-1zM14 19h1v1h-1zM15 19h1v1h-1zM15 18h1v1h-1zM14 18h1v1h-1zM13 18h1v1h-1zM13 17h1v1h-1zM16 16h1v1h-1zM17 16h1v1h-1zM18 16h1v1h-1zM18 17h1v1h-1zM17 17h1v1h-1zM19 17h1v1h-1zM21 12h1v1h-1zM21 13h1v1h-1zM21 14h1v1h-1zM20 14h1v1h-1zM20 13h1v1h-1zM21 19h1v1h-1zM20 19h1v1h-1zM20 20h1v1h-1zM21 20h1v1h-1zM19 21h1v1h-1zM19 22h1v1h-1zM19 20h1v1h-1z'/>",
        "",
        "<path fill='url(#pattern-color)' d='M21 9h1v1h-1zM20 9h1v1h-1zM20 10h1v1h-1zM20 11h1v1h-1zM21 11h1v1h-1z' /><path fill='#fff' d='M21 10h1v1h-1z' /><path fill='url(#pattern-color)'  d='M22 11h1v1h-1zM22 10h1v1h-1zM22 9h1v1h-1zM23 10h1v1h-1zM23 11h1v1h-1zM24 10h1v1h-1zM24 11h1v1h-1zM20 13h1v1h-1zM20 14h1v1h-1zM20 15h1v1h-1zM20 16h1v1h-1zM19 16h1v1h-1zM18 16h1v1h-1zM17 16h1v1h-1zM16 16h1v1h-1zM15 16h1v1h-1zM14 16h1v1h-1zM13 16h1v1h-1zM12 16h1v1h-1zM11 16h1v1h-1zM10 16h1v1h-1zM11 17h1v1h-1zM10 18h1v1h-1zM10 19h1v1h-1zM14 17h1v1h-1zM13 18h1v1h-1zM13 19h1v1h-1zM17 17h1v1h-1zM16 18h1v1h-1zM16 19h1v1h-1zM19 17h1v1h-1zM19 18h1v1h-1zM19 19h1v1h-1z' />"
    ];
    string[] private tailSvgs = [
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1zM9 17H8v-1h1zM8 18H7v-1h1zM9 18H8v-1h1zM9 19H8v-1h1zM8 19H7v-1h1zM8 20H7v-1h1zM9 20H8v-1h1zM9 21H8v-1h1zM8 21H7v-1h1zM8 22H7v-1h1zM7 22H6v-1h1zM8 23H7v-1h1zM7 23H6v-1h1zM7 24H6v-1h1zM8 24H7v-1h1zM7 25H6v-1h1z' />",
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1zM9 17H8v-1h1zM9 18H8v-1h1zM8 18H7v-1h1zM8 19H7v-1h1zM8 20H7v-1h1zM8 21H7v-1h1zM9 21H8v-1h1zM9 20H8v-1h1zM9 19H8v-1h1zM8 22H7v-1h1zM7 22H6v-1h1zM7 21H6v-1h1zM6 21H5v-1h1zM6 20H5v-1h1z' />",
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1zM10 16H9v-1h1zM10 15H9v-1h1z'/>",
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1zM9 17H8v-1h1zM8 18H7v-1h1zM9 18H8v-1h1zM9 19H8v-1h1zM8 19H7v-1h1zM8 20H7v-1h1zM9 20H8v-1h1zM9 21H8v-1h1zM8 21H7v-1h1zM8 22H7v-1h1zM7 22H6v-1h1zM8 23H7v-1h1zM7 23H6v-1h1zM7 24H6v-1h1zM8 24H7v-1h1zM7 25H6v-1h1zM7 26H6v-1h1zM6 26H5v-1h1zM5 26H4v-1h1zM4 26H3v-1h1zM3 26H2v-1h1zM6 25H5v-1h1zM6 24H5v-1h1zM5 25H4v-1h1zM2 26H1v-1h1zM1 26H0v-1h1zM4 25H3v-1h1z' />",
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1z' />",
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1zM9 17H8v-1h1zM9 18H8v-1h1zM9 20H8v-1h1zM9 21H8v-1h1z' />",
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1zM9 17H8v-1h1zM9 18H8v-1h1zM9 20H8v-1h1zM9 21H8v-1h1z' />",
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1zM9 18H8v-1h1zM9 17H8v-1h1zM8 18H7v-1h1zM9 19H8v-1h1zM9 20H8v-1h1zM9 21H8v-1h1zM9 22H8v-1h1zM8 20H7v-1h1zM8 22H7v-1h1zM9 23H8v-1h1zM9 24H8v-1h1z'/>"
    ];

    string[] private maneSvgs = [
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zm-2 1h-1V9h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm2-1h-1v-1h1zm1 0h-1v-1h1zm0-1h-1v-1h1zm0-1h-1v-1h1zm0-1h-1v-1h1zm4-3h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zM21 10h-1V9h1zM19 10h-1V9h1zM19 11h-1v-1h1zM19 12h-1v-1h1zM19 13h-1v-1h1zM19 14h-1v-1h1zM19 15h-1v-1h1zM19 16h-1v-1h1zM18 16h-1v-1h1zM17 16h-1v-1h1zM16 16h-1v-1h1zM16 17h-1v-1h1zM15 17h-1v-1h1zM14 17h-1v-1h1zM14 18h-1v-1h1zM15 18h-1v-1h1zM15 19h-1v-1h1zM14 19h-1v-1h1zM14 20h-1v-1h1zM14 21h-1v-1h1zM13 20h-1v-1h1zM13 21h-1v-1h1zM13 22h-1v-1h1zM13 23h-1v-1h1zM15 16h-1v-1h1zM17 15h-1v-1h1zM18 15h-1v-1h1zM18 14h-1v-1h1zM18 13h-1v-1h1zM18 12h-1v-1h1zM22 9h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zM19 10h-1V9h1zM19 11h-1v-1h1zM19 12h-1v-1h1zM19 13h-1v-1h1zM19 14h-1v-1h1zM19 15h-1v-1h1zM19 16h-1v-1h1zM18 16h-1v-1h1zM22 9h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zM19 10h-1V9h1zM19 11h-1v-1h1zM19 12h-1v-1h1zM19 13h-1v-1h1zM19 14h-1v-1h1zM19 15h-1v-1h1zM19 16h-1v-1h1zM18 16h-1v-1h1zM17 16h-1v-1h1zM17 17h-1v-1h1zM16 17h-1v-1h1zM16 18h-1v-1h1zM16 19h-1v-1h1zM15 18h-1v-1h1zM15 19h-1v-1h1zM15 20h-1v-1h1zM15 21h-1v-1h1zM15 22h-1v-1h1zM15 23h-1v-1h1zM15 24h-1v-1h1zM16 16h-1v-1h1zM15 16h-1v-1h1zM15 17h-1v-1h1zM14 17h-1v-1h1zM14 18h-1v-1h1zM14 19h-1v-1h1zM14 20h-1v-1h1zM14 21h-1v-1h1zM14 22h-1v-1h1zM14 23h-1v-1h1zM17 15h-1v-1h1zM18 15h-1v-1h1zM18 14h-1v-1h1zM18 13h-1v-1h1zM18 12h-1v-1h1zM22 9h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zM19 10h-1V9h1zM19 11h-1v-1h1zM19 12h-1v-1h1zM19 13h-1v-1h1zM19 14h-1v-1h1zM22 9h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zM19 10h-1V9h1zM19 11h-1v-1h1zM19 12h-1v-1h1zM19 13h-1v-1h1zM19 14h-1v-1h1zM19 15h-1v-1h1zM19 16h-1v-1h1zM18 16h-1v-1h1zM17 16h-1v-1h1zM16 16h-1v-1h1zM17 15h-1v-1h1zM18 15h-1v-1h1zM18 14h-1v-1h1zM18 13h-1v-1h1zM18 12h-1v-1h1zM15 16h-1v-1h1zM24 13h-1v-1h1zM24 14h-1v-1h1zM24 15h-1v-1h1zM25 13h-1v-1h1zM22 9h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zM19 10h-1V9h1zM18 10h-1V9h1zM18 12h-1v-1h1zM19 11h-1v-1h1zM19 12h-1v-1h1zM19 13h-1v-1h1zM19 14h-1v-1h1zM19 15h-1v-1h1zM18 14h-1v-1h1zM22 9h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zM19 10h-1V9h1zM19 11h-1v-1h1zM19 13h-1v-1h1zM19 14h-1v-1h1zM19 16h-1v-1h1zM18 16h-1v-1h1zM22 9h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zm-2 1h-1V9h1zm-1 0h-1V9h1zm0 2h-1v-1h1zm1-1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm4-1h-1v-1h1zm-2 0h-1v-1h1zm10-2h-1v-1h1zm1 0h-1v-1h1zm-1 1h-1v-1h1zm0 1h-1v-1h1zm-6-1h-1v-1h1zm4-5h-1V8h1z' />"
    ];
    string[] private backgroundSvgs = [
        "<rect width='32' height='32' fill='#fff9d0' />",
        "<rect width='32' height='32' fill='#dfefff' />",
        "<rect width='32' height='32' fill='#aaffcf' />",
        "<rect width='32' height='32' fill='#efefcf' />",
        "<rect width='32' height='32' fill='#dadee9' />",
        "<rect width='32' height='32' fill='#ddadaf' />",
        "<rect width='32' height='32' fill='#ffefcf' />",
        "<rect width='32' height='32' fill='#bbe4ea' />",
        "<rect width='32' height='32' fill='#ffefbf' />",
        "<rect width='32' height='32' fill='#ffdfff' />"
    ];

    string[] private utilitySvgs = [
        "",
        "<path fill='#7f5748' d='M28 3h1v1h-1zM28 4h1v1h-1zM27 2h1v1h-1zM29 2h1v1h-1z' /><path fill='#ffda69' d='M29 3h1v1h-1zM29 5h1v1h-1zM27 3h1v1h-1zM27 5h1v1h-1z' />",
        "<path fill='#93d0f3' d='M27 23h1v1h-1zM27 24h1v1h-1zM28 22h1v1h-1z' /><path fill='#a4d18a' d='M28 21h1v1h-1z' /><path fill='#ffea84' d='M27 22h1v1h-1z' /><path fill='#93d0f3' d='M27 25h1v1h-1zM26 25h1v1h-1zM28 25h1v1h-1zM26 22h1v1h-1z' />",
        "<path fill='#ffda69' d='M27 20h1v1h-1zM26 21h1v1h-1z' /><path fill='#7f5748' d='M27 21h1v1h-1z' /><path fill='#ffda69' d='M28 21h1v1h-1zM28 22h1v1h-1zM27 22h1v1h-1zM26 22h1v1h-1zM27 23h1v1h-1zM27 24h1v1h-1zM26 25h1v1h-1zM27 25h1v1h-1zM28 25h1v1h-1z' />",
        "<path fill='#ffda69' d='M27 18h1v1h-1zM28 20h1v1h-1zM27 22h1v1h-1zM27 23h1v1h-1zM26 23h1v1h-1zM26 24h1v1h-1z' /><path fill='#d9554d' d='M27 24h1v1h-1z' /><path fill='#ffda69' d='M28 24h1v1h-1z' /><path fill='#a85f44' d='M28 25h1v1h-1zM27 25h1v1h-1zM26 25h1v1h-1zM25 25h1v1h-1zM29 25h1v1h-1z' />",
        "<path fill='#4dc7f6' d='M26 16h1v1h-1z' /><path fill='#555' d='M27 24h1v1h-1zm1-1h1v1h-1zm1-1h1v1h-1zm1-1h1v1h-1zm1-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm-1-1h1v1h-1zm-1-1h1v1h-1zm-1-1h1v1h-1zm-1 0h1v1h-1zm0 8h1v1h-1zm0 2h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm3 0h1v1h-1zm1 0h1v1h-1z' /><path fill='#4dc7f6' d='M25 17h1v1h-1z' /><path fill='#56b746' d='M24 18h1v1h-1zm0 1h1v1h-1z' /><path fill='#4dc7f6' d='M24 20h1v1h-1zm1 1h1v1h-1zm1 1h1v1h-1z' /><path fill='#56b746' d='M27 22h1v1h-1z' /><path fill='#4dc7f6' d='M28 22h1v1h-1zm1-1h1v1h-1z' /><path fill='#56b746' d='M30 20h1v1h-1z' /><path fill='#4dc7f6' d='M30 19h1v1h-1z' /><path fill='#56b746' d='M30 18h1v1h-1z' /><path fill='#4dc7f6' d='M29 17h1v1h-1zm-1-1h1v1h-1z' /><path fill='#56b746' d='M27 16h1v1h-1z' /><path fill='#4dc7f6' d='M26 17h1v1h-1z' /><path fill='#56b746' d='M26 18h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1zm1 1h1v1h-1z' /><path fill='#4dc7f6' d='M26 19h1v1h-1zm-1 1h1v1h-1zm1 1h1v1h-1z' /><path fill='#56b746' d='M27 21h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1z' /><path fill='#4dc7f6' d='M29 20h1v1h-1z' /><path fill='#56b746' d='M29 19h1v1h-1zm0-1h1v1h-1z' /><path fill='#4dc7f6' d='M28 18h1v1h-1z' /><path fill='#56b746' d='M27 18h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1z' />",
        "<path fill='#000' d='M27 8h1v1h-1zM26 7h1v1h-1zM28 7h1v1h-1zM22 4h1v1h-1zM21 3h1v1h-1zM23 3h1v1h-1zM28 3h1v1h-1zM27 2h1v1h-1zM29 2h1v1h-1z' />",
        "<path fill='#555' d='M27 25h1v1h-1zM27 24h1v1h-1zM27 23h1v1h-1zM27 22h1v1h-1zM26 25h1v1h-1zM26 22h1v1h-1zM28 22h1v1h-1zM28 25h1v1h-1z' /><path fill='#27aae1' d='M26 18h1v1h-1zM25 19h1v1h-1zM25 20h1v1h-1zM26 21h1v1h-1zM27 21h1v1h-1zM28 21h1v1h-1zM29 20h1v1h-1zM29 19h1v1h-1zM29 18h1v1h-1zM28 17h1v1h-1zM27 17h1v1h-1zM26 17h1v1h-1zM25 18h1v1h-1zM26 19h1v1h-1zM26 20h1v1h-1zM27 20h1v1h-1zM28 20h1v1h-1zM28 19h1v1h-1z' /><path fill='#fff' d='M28 18h1v1h-1z' /><path fill='#27aae1' d='M27 18h1v1h-1zM27 19h1v1h-1z' />",
        "<path fill='#75c164' d='M27 25h1v1h-1zM27 24h1v1h-1zM27 23h1v1h-1z' /><path fill='#ffda6a' d='M27 22h1v1h-1z' /><path fill='#ee2636' d='M27 21h1v1h-1z' /><path fill='#ffda6a' d='M27 20h1v1h-1z' /><path fill='#fff' d='M26 20h1v1h-1z' /><path fill='#ffda6a' d='M26 21h1v1h-1z' /><path fill='#fff' d='M26 22h1v1h-1zM28 22h1v1h-1z' /><path fill='#ffda6a' d='M28 21h1v1h-1z' /><path fill='#fff' d='M28 20h1v1h-1z' /><path fill='#75c164' d='M28 24h1v1h-1z' />",
        "<path fill='#1c75bc' d='M27 22h1v1h-1zm-1 1h1v1h-1zm0 1h1v1h-1zm1 1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1-1h1v1h-1zm0-1h1v1h-1zm-1-1h1v1h-1z' /><path fill='#00aeef' d='M27 23h1v1h-1zm1 0h1v1h-1z' /><path fill='#fbb040' d='M29 23h1v1h-1z' /><path fill='#00aeef' d='M29 24h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1z' />",
        "<path fill='#754c29' d='M26 24h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm-1 1h1v1h-1zm-1 0h1v1h-1z' /><path fill='#a97c50' d='M28 23h1v1h-1zm-1-1h1v1h-1zm1-1h1v1h-1zm1 0h1v1h-1zm1-1h1v1h-1z' /><path fill='#75c164' d='M30 19h1v1h-1zm0-1h1v1h-1zm-1 0h1v1h-1zm0-1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1z' />",
        "<path fill='#8b5e3c' d='M26 25h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm-2 0h1v1h-1zm-1 0h1v1h-1z' /><path fill='#ffda6a' d='M27 22h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm-3 0h1v1h-1zm1-1h1v1h-1zm1 0h1v1h-1z' /><path fill='#8b5e3c' d='M26 24h1v1h-1z' /><path fill='#414042' d='M27 24h1v1h-1zm1 0h1v1h-1z' /><path fill='#8b5e3c' d='M28 23h1v1h-1zm2-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm1 1h1v1h-1zm0 1h1v1h-1z' />",
        "<path fill='#a97c50' d='M29 25h1v1h-1zm-2 0h1v1h-1z' /><path fill='#4eb74a' d='M24 23h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm-1 0h1v1h-1zm2 0h1v1h-1z' /><path fill='#408251' d='M27 24h1v1h-1zm0-1h1v1h-1zm1-1h1v1h-1zm1 0h1v1h-1zm1 2h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1z' /><path fill='#4eb74a' d='M31 24h1v1h-1z' />",
        "<path fill='#f57f20' d='M26 25h1v1h-1zM28 25h1v1h-1z' /><path fill='#fff' d='M29 23h1v1h-1zM29 22h1v1h-1zM29 24h1v1h-1zM28 24h1v1h-1zM27 24h1v1h-1zM26 24h1v1h-1zM26 23h1v1h-1zM25 23h1v1h-1zM25 22h1v1h-1zM25 21h1v1h-1zM25 20h1v1h-1zM26 20h1v1h-1zM26 21h1v1h-1zM26 22h1v1h-1zM27 23h1v1h-1zM28 23h1v1h-1z' /><path fill='#ebbd54' d='M24 21h1v1h-1z' />",
        "<path fill='#939598' opacity='.5' d='M26 23h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm1 0h1v1h-1zm0 2h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm-1-1h1v1h-1zm-1 1h1v1h-1zm-1-1h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm-1-1h1v1h-1zm-1 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm1-1h1v1h-1z' /><path fill='#fff200' d='M30 19h1v1h-1zm-2 0h1v1h-1z' />"
    ];

    // attribute names
    string[] private patternNames = [
        "giraffe",
        "small spots",
        "two tone",
        "tips",
        "curves",
        "stripes",
        "racing",
        "big spots",
        "butt naked",
        "death"
    ];
    string[] private headAccessoryNames = [
        "none",
        "purple cap",
        "propeller cap",
        "golden necklace",
        "unicorn horn",
        "flame breath",
        "top hat",
        "devil horns",
        "wizard hat",
        "laser",
        "viking helmet",
        "golden halo",
        "rainbow puke",
        "crown"
    ];
    string[] private bodyAccessoryNames = [
        "none",
        "winner",
        "bravery boots",
        "rainbow",
        "charged",
        "wings",
        "speed booster",
        "black cat",
        "hell wings"
    ];
    string[] private maneColorNames = [
        "black",
        "strawberry",
        "blackberry",
        "juneberry",
        "cranberry",
        "cloudberry",
        "snowberry",
        "blueberry",
        "caperberry",
        "dewberry",
        "gold"
    ];
    string[] private patternColorNames = [
        "brown",
        "dark",
        "light blue",
        "pink",
        "purple",
        "green",
        "red",
        "cream",
        "orange",
        "blue",
        "deep pink",
        "white"
    ];
    string[] private hoofColorNames = [
        "black",
        "dark brown",
        "dark blue",
        "brown",
        "dark green",
        "light green",
        "red",
        "light purple",
        "purple",
        "pink",
        "gold"
    ];
    string[] private bodyColorNames = [
        "giraffe",
        "butterfly",
        "elephant",
        "bear",
        "polar bear",
        "frog",
        "lobster",
        "turtle",
        "whale",
        "gold"
    ];
    string[] private tailNames = [
        "normal",
        "pointy",
        "dog",
        "long",
        "bun",
        "baked",
        "pile",
        "dragon"
    ];
    string[] private maneNames = [
        "normal",
        "messy",
        "tidy",
        "overwhelming",
        "short",
        "bearded",
        "dragon",
        "baked",
        "mother of dragons"
    ];
    string[] private backgroundNames = [
        "curd",
        "starlight",
        "seafoam",
        "ghost green",
        "fog",
        "chestnut",
        "sand",
        "ice",
        "banana",
        "grape"
    ];
    string[] private utilityNames = [
        "none",
        "butterfly of fortune",
        "martini with alcohol",
        "grail of gold",
        "bonfire from hell",
        "globe of nastyness",
        "bats of mayhem",
        "orb of future",
        "flower of goodwill",
        "bowl of gold fish",
        "bonsai of life",
        "chest with bling",
        "turtle of speed",
        "duck of doom",
        "ghost of death"
    ];

    // attribute rarities
    uint256[] private maneColorRarities = [
        4000,
        1000,
        1000,
        1000,
        800,
        800,
        500,
        300,
        300,
        200,
        100
    ];
    uint256[] private patternColorRarities = [
        3000,
        1700,
        1350,
        900,
        800,
        800,
        500,
        300,
        200,
        200,
        150,
        100
    ];
    uint256[] private hoofColorRarities = [
        3500,
        1500,
        1100,
        1000,
        1000,
        500,
        500,
        400,
        200,
        200,
        100
    ];
    uint256[] private bodyColorRarities = [
        2900,
        1500,
        1500,
        1500,
        700,
        600,
        500,
        500,
        200,
        100
    ];
    uint256[] private backgroundRarities = [
        1000,
        1000,
        1000,
        1000,
        1000,
        1000,
        1000,
        1000,
        1000,
        1000
    ];
    uint256[] private tailRarities = [
        3000,
        2000,
        1500,
        1200,
        1000,
        750,
        350,
        200
    ];
    uint256[] private maneRarities = [
        3000,
        1800,
        1600,
        900,
        800,
        700,
        600,
        400,
        200
    ];
    uint256[] private patternRarities = [
        2000,
        1500,
        1500,
        1100,
        1000,
        800,
        800,
        500,
        500,
        300
    ];
    uint256[] private headAccessoryRarities = [
        3100,
        1500,
        1000,
        800,
        700,
        700,
        500,
        550,
        250,
        300,
        300,
        150,
        100,
        50
    ];
    uint256[] private bodyAccessoryRarities = [
        2500,
        2300,
        1400,
        1000,
        800,
        800,
        600,
        400,
        200
    ];
    uint256[] private utilityRarities = [
        3700,
        1000,
        900,
        500,
        400,
        500,
        200,
        600,
        900,
        500,
        300,
        250,
        100,
        100,
        50
    ];

    // amount of attributes
    uint8 constant maneColorCount = 11;
    uint8 constant patternColorCount = 12;
    uint8 constant hoofColorCount = 11;
    uint8 constant bodyColorCount = 10;
    uint8 constant backgroundCount = 10;
    uint8 constant tailCount = 8;
    uint8 constant maneCount = 9;
    uint8 constant patternCount = 10;
    uint8 constant headAccessoryCount = 14;
    uint8 constant bodyAccessoryCount = 9;
    uint8 constant utilityCount = 15;

    /**
     * Use:
     * Get a random attribute using the rarities defined
     */
    function getRandomIndex(
        uint256[] memory attributeRarities,
        uint8 attributeCount,
        uint256 randomNumber
    ) private pure returns (uint8 index) {
        uint256 random10k = randomNumber % 10000;
        uint256 steps = 0;
        for (uint8 i = 0; i < attributeCount; i++) {
            uint256 currentRarity = attributeRarities[i] + steps;
            if (random10k < currentRarity) {
                return i;
            }
            steps = currentRarity;
        }
        return 0;
    }

    /**
     * Use:
     * Get random attributes for each different property of the token
     *
     * Comment:
     * Can only be used by the TokenContract defined by address tokenContract
     */
    function getRandomAttributes(uint256 randomNumber)
        public
        view
        returns (
            uint8 maneColor,
            uint8 patternColor,
            uint8 hoofColor,
            uint8 bodyColor,
            uint8 background,
            uint8 tail,
            uint8 mane,
            uint8 pattern,
            uint8 headAccessory,
            uint8 bodyAccessory,
            uint8 utility
        )
    {
        maneColor = getRandomManeColor(randomNumber);
        randomNumber = randomNumber / 10;
        patternColor = getRandomPatternColor(randomNumber);
        randomNumber = randomNumber / 10;
        hoofColor = getRandomHoofColor(randomNumber);
        randomNumber = randomNumber / 10;
        bodyColor = getRandomBodyColor(randomNumber);
        randomNumber = randomNumber / 10;
        background = getRandomBackground(randomNumber);
        randomNumber = randomNumber / 10;
        tail = getRandomTail(randomNumber);
        randomNumber = randomNumber / 10;
        mane = getRandomMane(randomNumber);
        randomNumber = randomNumber / 10;
        pattern = getRandomPattern(randomNumber);
        randomNumber = randomNumber / 10;
        headAccessory = getRandomHeadAccessory(randomNumber);
        randomNumber = randomNumber / 10;
        bodyAccessory = getRandomBodyAccessory(randomNumber);
        randomNumber = randomNumber / 10;
        utility = getRandomUtility(randomNumber);

        return (
            maneColor,
            patternColor,
            hoofColor,
            bodyColor,
            background,
            tail,
            mane,
            pattern,
            headAccessory,
            bodyAccessory,
            utility
        );
    }

    function getRandomManeColor(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return getRandomIndex(maneColorRarities, maneColorCount, randomNumber);
    }

    function getRandomPatternColor(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return
            getRandomIndex(
                patternColorRarities,
                patternColorCount,
                randomNumber
            );
    }

    function getRandomHoofColor(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return getRandomIndex(hoofColorRarities, hoofColorCount, randomNumber);
    }

    function getRandomBodyColor(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return getRandomIndex(bodyColorRarities, bodyColorCount, randomNumber);
    }

    function getRandomBackground(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return
            getRandomIndex(backgroundRarities, backgroundCount, randomNumber);
    }

    function getRandomTail(uint256 randomNumber) private view returns (uint8) {
        return getRandomIndex(tailRarities, tailCount, randomNumber);
    }

    function getRandomMane(uint256 randomNumber) private view returns (uint8) {
        return getRandomIndex(maneRarities, maneCount, randomNumber);
    }

    function getRandomPattern(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return getRandomIndex(patternRarities, patternCount, randomNumber);
    }

    function getRandomHeadAccessory(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return
            getRandomIndex(
                headAccessoryRarities,
                headAccessoryCount,
                randomNumber
            );
    }

    function getRandomBodyAccessory(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return
            getRandomIndex(
                bodyAccessoryRarities,
                bodyAccessoryCount,
                randomNumber
            );
    }

    function getRandomUtility(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return getRandomIndex(utilityRarities, utilityCount, randomNumber);
    }

    /**
     * Use:
     * Get the attribute name for the properties of the token
     *
     * Comment:
     * Can only be used by the TokenContract defined by address tokenContract
     */
    function getManeColor(uint8 index) public view returns (string memory) {
        return maneColorNames[index];
    }

    function getPatternColor(uint8 index) public view returns (string memory) {
        return patternColorNames[index];
    }

    function getHoofColor(uint8 index) public view returns (string memory) {
        return hoofColorNames[index];
    }

    function getBodyColor(uint8 index) public view returns (string memory) {
        return bodyColorNames[index];
    }

    function getBackground(uint8 index) public view returns (string memory) {
        return backgroundNames[index];
    }

    function getTail(uint8 index) public view returns (string memory) {
        return tailNames[index];
    }

    function getMane(uint8 index) public view returns (string memory) {
        return maneNames[index];
    }

    function getPattern(uint8 index) public view returns (string memory) {
        return patternNames[index];
    }

    function getHeadAccessory(uint8 index) public view returns (string memory) {
        return headAccessoryNames[index];
    }

    function getBodyAccessory(uint8 index) public view returns (string memory) {
        return bodyAccessoryNames[index];
    }

    function getUtility(uint8 index) public view returns (string memory) {
        return utilityNames[index];
    }

    /**
     * Use:
     * Get the attribute svg for a different property of the token
     *
     * Comment:
     * Can only be used by the TokenContract defined by address tokenContract
     */
    function renderHorse(
        bytes memory colors,
        uint8 background,
        uint8 tail,
        uint8 mane,
        uint8 pattern,
        uint8 headAccessory,
        uint8 bodyAccessory,
        uint8 utility
    ) public view returns (bytes memory) {
        bytes memory start = abi.encodePacked(
            svgStart,
            colors,
            backgroundSvgs[background],
            base,
            patternSvgs[pattern]
        );
        return
            abi.encodePacked(
                start,
                tailSvgs[tail],
                maneSvgs[mane],
                headAccessorySvgs[headAccessory],
                bodyAccessorySvgs[bodyAccessory],
                utilitySvgs[utility],
                svgEnd
            );
    }

    /**
     * Use:
     * Create color definitions for the svg
     */
    function packColor(string memory colorName, string memory colorSvg)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                "<linearGradient id='",
                colorName,
                "'><stop stop-color='",
                colorSvg,
                "'/></linearGradient>"
            );
    }

    /**
     * Use:
     * Pack all colors together
     */
    function renderColors(
        uint8 maneColor,
        uint8 patternColor,
        uint8 hoofColor,
        uint8 bodyColor
    ) public view returns (bytes memory) {
        return
            abi.encodePacked(
                "<defs>",
                packColor("mane-color", maneColorSvgs[maneColor]),
                packColor("pattern-color", patternColorSvgs[patternColor]),
                packColor("hoof-color", hoofColorSvgs[hoofColor]),
                packColor("body-color", bodyColorSvgs[bodyColor]),
                "</defs>"
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}