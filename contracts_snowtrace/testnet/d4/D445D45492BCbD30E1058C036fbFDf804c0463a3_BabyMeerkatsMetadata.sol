// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./BabyMeerkatsStrings.sol";

library MeerkatSharedStructs {
    // using SafeMath for uint256;
    struct BabyMeerkatBuildInfo {
        string background;
        uint8 backgroundRarity;
        string body;
        uint8 bodyRarity;
        string hat;
        uint8 hatRarity;
        string neck;
        uint8 neckRarity;
        string eye;
        uint8 eyeRarity;
        string mouth;
        uint8 mouthRarity;
        string overallRarity;
        uint256 score;
    }

    struct BabyMeerkat {
        string background;
        string body;
        string hat;
        string neck;
        string eye;
        string mouth;
        string rarity;
        uint256 score;
        uint256 parent1;
        uint256 parent2;
    }

        // function setMetadataContract(address _address) external onlyOwner {
    //     babyMeerkatsMetadata = BabyMeerkatsMetadata(_address);
    // }

    function getBabyMeerkatData(mapping(uint256 => BabyMeerkat) storage babyMeerkats,uint256 tokenId)
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256
        )
    {
         MeerkatSharedStructs.BabyMeerkat memory babyMeerkat = babyMeerkats[tokenId];
        return (
            babyMeerkat.background,
            babyMeerkat.body,
            babyMeerkat.hat,
            babyMeerkat.neck,
            babyMeerkat.eye,
            babyMeerkat.mouth,
            babyMeerkat.rarity,
            babyMeerkat.score,
            babyMeerkat.parent1,
            babyMeerkat.parent2
        );
    }

    // function pow(uint n, uint e) public pure returns (uint) {
    
    // if (e == 0) {
    //     return 1;
    // } else if (e == 1) {
    //     return n;
    // } else {
    //     uint p = pow(n, e.div(2));
    //     p = p.mul(p);
    //     if (e.mod(2) == 1) {
    //         p = p.mul(n);
    //     }
    //     return p;
    //     }
    // }
}

contract BabyMeerkatsMetadata is Ownable {
    using SafeMath for uint256;
    BabyMeerkatsStrings metadataStrings;
    uint256 public constant MAX_POINT = 300;
    string[] public rarities = ["Common", "Rare", "Epic", "Legendary"];

    mapping(uint8 => uint8[]) public backgrounds;
    mapping(uint8 => uint8[]) public bodies;
    mapping(uint8 => uint8[]) public hats;
    mapping(uint8 => uint8[]) public necks;
    mapping(uint8 => uint8[]) public eyes;
    mapping(uint8 => uint8[]) public mouths;

    constructor(BabyMeerkatsStrings _metadataStrings) {
        metadataStrings = _metadataStrings;
        backgrounds[3].push(0);
        backgrounds[3].push(1);
        backgrounds[3].push(2);
        backgrounds[3].push(3);
        backgrounds[3].push(4);
        backgrounds[3].push(5);
        backgrounds[3].push(6);
        backgrounds[3].push(7);
        backgrounds[2].push(8);
        backgrounds[2].push(9);
        backgrounds[2].push(10);
        backgrounds[2].push(11);
        backgrounds[2].push(12);
        backgrounds[2].push(13);
        backgrounds[2].push(14);
        backgrounds[2].push(15);
        backgrounds[2].push(16);
        backgrounds[1].push(17);
        backgrounds[1].push(18);
        backgrounds[1].push(19);
        backgrounds[1].push(20);
        backgrounds[1].push(21);
        backgrounds[1].push(22);
        backgrounds[1].push(23);
        backgrounds[1].push(24);
        backgrounds[0].push(25);
        backgrounds[0].push(26);
        backgrounds[0].push(27);
        backgrounds[0].push(28);
        backgrounds[0].push(29);
        backgrounds[0].push(30);
        backgrounds[0].push(31);

        bodies[3].push(0);
        bodies[3].push(1);
        bodies[2].push(2);
        bodies[2].push(3);
        bodies[1].push(4);
        bodies[1].push(5);
        bodies[1].push(6);
        bodies[0].push(7);
        bodies[0].push(8);
        bodies[0].push(9);

        hats[3].push(0);
        hats[3].push(1);
        hats[3].push(2);
        hats[3].push(3);
        hats[2].push(4);
        hats[2].push(5);
        hats[2].push(6);
        hats[2].push(7);
        hats[2].push(8);
        hats[2].push(9);
        hats[1].push(10);
        hats[1].push(11);
        hats[1].push(12);
        hats[1].push(13);
        hats[1].push(14);
        hats[1].push(15);
        hats[1].push(16);
        hats[0].push(17);
        hats[0].push(18);
        hats[0].push(19);
        hats[0].push(20);
        hats[0].push(21);
        hats[0].push(22);
        hats[0].push(23);

        necks[3].push(0);
        necks[3].push(1);
        necks[3].push(2);
        necks[3].push(3);
        necks[3].push(4);
        necks[3].push(5);
        necks[2].push(6);
        necks[2].push(7);
        necks[2].push(8);
        necks[2].push(9);
        necks[2].push(10);
        necks[2].push(11);
        necks[2].push(12);
        necks[2].push(13);
        necks[1].push(14);
        necks[1].push(15);
        necks[1].push(16);
        necks[1].push(17);
        necks[1].push(18);
        necks[1].push(19);
        necks[1].push(20);
        necks[1].push(21);
        necks[0].push(22);
        
        eyes[3].push(0);
        eyes[3].push(1);
        eyes[3].push(2);
        eyes[3].push(3);
        eyes[3].push(4);
        eyes[3].push(5);
        eyes[2].push(6);
        eyes[2].push(7);
        eyes[2].push(8);
        eyes[2].push(9);
        eyes[2].push(10);
        eyes[2].push(11);
        eyes[1].push(12);
        eyes[1].push(13);
        eyes[1].push(14);
        eyes[1].push(15);
        eyes[1].push(16);
        eyes[1].push(17);
        eyes[1].push(18);
        eyes[0].push(19);
        eyes[0].push(20);
        eyes[0].push(21);
        eyes[0].push(22);
        eyes[0].push(23);

        mouths[0].push(0);
    }

    function getRandomMetaData(uint256 _nonce) public view returns (MeerkatSharedStructs.BabyMeerkatBuildInfo memory) {
        string[] memory allRarities = new string[](5);
        MeerkatSharedStructs.BabyMeerkatBuildInfo memory info;
        uint256 roll = (getRandomNumber(_nonce) % 100);
        info.backgroundRarity = getRandomizedTier(roll);
        allRarities[0] = rarities[info.backgroundRarity];
        roll = (getRandomNumber(roll) %
            backgrounds[info.backgroundRarity].length);
        info.background = metadataStrings.getBackground(backgrounds[info.backgroundRarity][roll]);

        roll = (getRandomNumber(_nonce + 1) % 100);
        info.bodyRarity = getRandomizedTier(roll);
        allRarities[0] = rarities[info.bodyRarity];
        roll = (getRandomNumber(roll) % bodies[info.bodyRarity].length);
        info.body = metadataStrings.getBody(bodies[info.bodyRarity][roll]);

        roll = (getRandomNumber(_nonce + 3) % 100);
        info.hatRarity = getRandomizedTier(roll);
        allRarities[1] = rarities[info.hatRarity];
        roll = (getRandomNumber(roll) % hats[info.hatRarity].length);
        info.hat = metadataStrings.getHat(hats[info.hatRarity][roll]);

        roll = (getRandomNumber(_nonce + 5) % 100);
        info.neckRarity = getRandomizedTier(roll);
        allRarities[2] = rarities[info.neckRarity];
        roll = (getRandomNumber(roll) % necks[info.neckRarity].length);
        info.neck = metadataStrings.getNeck(necks[info.neckRarity][roll]);

        roll = (getRandomNumber(_nonce + 7) % 100);
        info.eyeRarity = getRandomizedTier(roll);
        allRarities[3] = rarities[info.eyeRarity];
        roll = (getRandomNumber(roll) % eyes[info.eyeRarity].length);
        info.eye = metadataStrings.getEye(eyes[info.eyeRarity][roll]);

        info.mouth = metadataStrings.getMouth(mouths[0][0]);

        (info.overallRarity, info.score) = getOverallNFTRarity(allRarities);
        return info;
    }

    function getOverallNFTRarity(string[] memory _rarities)
        private
        pure
        returns (string memory, uint256)
    {
        uint256 totalRarity = 0;
        for (uint256 i = 0; i < _rarities.length; i++) {
            if (compareStrings(_rarities[i], "Legendary")) totalRarity += 3;
            else if (compareStrings(_rarities[i], "Epic")) totalRarity += 10;
            else if (compareStrings(_rarities[i], "Rare")) totalRarity += 22;
            else totalRarity += 51;
        }
        return (getElementRarity(totalRarity.div(_rarities.length)),(MAX_POINT.sub(totalRarity)));
    }

    function getRandomNumber(uint256 nonce) private view returns (uint256) {
        return (
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, nonce, blockhash(block.number-1))
                )
            )
        );
    }

    function getElementRarity(uint256 _weight)
        private
        pure
        returns (string memory)
    {
        return
            _weight < 11 ? "Legendary" : _weight < 21 ? "Epic" : _weight < 31 ? "Rare" : "Common";
    }

    function compareStrings(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function getRandomizedTier(uint256 _weight)
        private
        pure
        returns (uint8)
    {
        return
            _weight < 6 ? 3 : _weight < 21 ? 2 : _weight < 51
                ? 1
                : 0;
    }

    function setStringContract(address _address) external onlyOwner {
        metadataStrings = BabyMeerkatsStrings(_address);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BabyMeerkatsStrings {
    string[] public backgroundStrings = ["space", "sunset", "gold", "sky", "mars", "deep space", "rainbow", "lake"
    "bitcoin", "big dots", "avax", "fire", "city", "silver", "ethereum", "pinky", "dots", 
    "green cartoon", "soft blue", "gradient cartoon","purple cartoon", "fire yellow", "pink blue", "blue leaf", "blue sand", 
    "sand", "purple", "nature", "green", "blue", "red", "half blue"];

     string[] public bodyStrings = ["gold","leopard",
     "cow","silver",
     "blue","red","brown",
     "classic","nature","grey"];

     string[] public hatStrings = ["angel","gold gentleman","green punk","unicorn",
     "painter", "crown", "orange ice cream", "santa", "blue punk", "red punk",
     "frank", "silver crown", "pirate", "headphone", "fez", "party", "wizard",
     "beanie","cowboy","none","egg", "gentleman","blue ice cream", "chef"];

     string[] public neckStrings = 
     ["devil","yellow wings", "black wings", "gold wings", "angel wings", "purple wings",
     "black devil", "bow tie", "devil wings", "blue wings", "red wings", "bat wings", "avax chain", "silver wings",
     "gold chain", "black tie", "dollar chain", "bitcoin chain", "grey chain", "iota chain", "solana chain", "black chain",
     "none"];

     string[] public eyeStrings = ["gold thug", "retro", "retro green", "fire", "red fire", "3d glass",
     "blue velvet", "silver thug", "black glasses","thug", "purple rain", "green glasses", 
     "red glasses", "yellow star", "red star", "pink glass", "purple star", "green star", "turquose glasses"
     "tear", "yellow glasses", "close", "none", "blue glasses"];

     string[] public mouthStrings = ["baby"];

    function getBackground(uint8 i) public view returns(string memory){
        return backgroundStrings[i];
    }

        function getBody(uint8 i) public view returns(string memory){
        return bodyStrings[i];
    }

        function getHat(uint8 i) public view returns(string memory){
        return hatStrings[i];
    }

        function getEye(uint8 i) public view returns(string memory){
        return eyeStrings[i];
    }

        function getNeck(uint8 i) public view returns(string memory){
        return neckStrings[i];
    }

        function getMouth(uint8 i) public view returns(string memory){
        return mouthStrings[i];
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