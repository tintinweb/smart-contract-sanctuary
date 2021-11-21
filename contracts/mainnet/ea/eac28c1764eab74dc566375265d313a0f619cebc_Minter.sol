/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol



pragma solidity ^0.8.0;


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

// File: contracts/Rng.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title A pseudo random number generator
 *
 * @dev This is not a true random number generator because smart contracts must be deterministic (every node a transaction goes to must produce the same result).
 *      True randomness requires an oracle which is both expensive in terms of gas and would take a critical part of the project off the chain.
 */
struct Rng {
    bytes32 state;
}

/**
 * @title A library for working with the Rng struct.
 *
 * @dev Rng cannot be a contract because then anyone could manipulate it by generating random numbers.
 */
library RngLibrary {
    /**
     * Creates a new Rng.
     */
    function newRng() internal view returns (Rng memory) {
        return Rng(getEntropy());
    }

    /**
     * Creates a pseudo-random value from the current block miner's address and sender.
     */
    function getEntropy() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.coinbase, msg.sender));
    }

    /**
     * Generates a random uint256.
     */
    function generate(Rng memory self) internal view returns (uint256) {
        self.state = keccak256(abi.encodePacked(getEntropy(), self.state));
        return uint256(self.state);
    }

    /**
     * Generates a random uint256 from min to max inclusive.
     *
     * @dev This function is not subject to modulo bias.
     *      The chance that this function has to reroll is astronomically unlikely, but it can theoretically reroll forever.
     */
    function generate(Rng memory self, uint min, uint max) internal view returns (uint256) {
        require(min <= max, "min > max");

        uint delta = max - min;

        if (delta == 0) {
            return min;
        }

        return generate(self) % (delta + 1) + min;
    }
}

// File: contracts/Rarities.sol


pragma solidity ^0.8.0;

library Rarities {
    function dominant() internal pure returns (uint16[8] memory ret) {
        ret = [
            2500,
            2200,
            1900,
            1300,
            800,
            600,
            400,
            300
        ];
    }
    
    function recessive() internal pure returns (uint16[6] memory ret) {
        ret = [
            4000,
            2500,
            1500,
            1000,
            600,
            400
        ];
    }
    
    function outfit() internal pure returns (uint16[27] memory ret) {
        ret = [
            700,
            700,
            700,
            600,
            600,
            600,
            600,
            600,
            600,
            600,
            600,
            500,
            500,
            400,
            400,
            300,
            200,
            200,
            100,
            100,
            100,
            75,
            50,
            50,
            50,
            50,
            25
        ];
    }
    
    function handaccessory() internal pure returns (uint16[16] memory ret) {
        ret = [
            5000,
            600,
            600,
            600,
            600,
            510,
            500,
            500,
            300,
            300,
            150,
            100,
            100,
            75,
            40,
            25
        ];
    }
    
    function mouth() internal pure returns (uint16[22] memory ret) {
        ret = [
            2000,
            1000,
            1000,
            1000,
            700,
            700,
            700,
            700,
            400,
            300,
            300,
            300,
            175,
            100,
            100,
            100,
            100,
            100,
            75,
            75,
            50,
            25
        ];
    }
    
    function eyes() internal pure returns (uint16[24] memory ret) {
        ret = [
            2500,
            600,
            600,
            600,
            600,
            600,
            600,
            400,
            400,
            400,
            400,
            400,
            400,
            400,
            400,
            100,
            100,
            100,
            100,
            75,
            75,
            75,
            50,
            25
        ];
    }
    
    function headaccessory() internal pure returns (uint16[29] memory ret) {
        ret = [
            3000,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            400,
            300,
            300,
            200,
            200,
            200,
            200,
            200,
            100,
            100,
            100,
            100,
            100,
            100,
            100,
            100,
            75,
            50,
            50,
            25
        ];
    }
}
// File: contracts/Enums.sol


pragma solidity ^0.8.0;

enum RerollTrait {
    BgColor,
    Outfit,
    HandAccessory,
    Mouth,
    Eyes,
    HeadAccessory
}

enum Special {
    NONE,
    DEVIL,
    GHOST,
    HIPPIE,
    JOKER,
    PRISONER,
    SQUID_GAME,
    WHERES_WALDO,
    HAZMAT,
    ASTRONAUT
}

enum Dominant {
    SKELETON,
    VAMPIRE,
    MUMMY,
    GHOST,
    WITCH,
    FRANKENSTEIN,
    WEREWOLF,
    PUMPKINHEAD
}

enum Recessive {
    SKELETON,
    VAMPIRE,
    MUMMY,
    GHOST,
    DEVIL,
    KONG
}

enum BgColor {
    DARK_BLUE,
    GRAY,
    LIGHT_BLUE,
    ORANGE,
    PINK,
    PURPLE,
    RED,
    TAN,
    TEAL,
    GREEN,
    RAINBOW
}

enum Outfit {
    WHITE_SHORTS,
    PINK_SHORTS,
    GRAY_PANTS,
    WHITE_AND_BLUE,
    PURPLE_SHORTS,
    PINK_AND_PURPLE,
    BROWN_AND_WHITE,
    BROWN_AND_BLUE,
    BLUE_SHORTS,
    BLUE_AND_WHITE,
    UNDERGARMENTS,
    LOUNGEWEAR,
    HOBO,
    SPORTS_JERSEY,
    GOLD_CHAIN,
    PAJAMAS,
    OVERALLS,
    SPEEDO,
    NINJA_SUIT,
    KARATE_UNIFORM,
    NONE,
    LUMBERJACK,
    PRIEST,
    TUX,
    SKELETON,
    CAMO,
    ARMOR
}

enum HandAccessory {
    NONE,
    BLOODY_KNIFE,
    BOW_AND_ARROW,
    SWORD,
    PITCHFORK,
    WAND,
    SPIKED_BASEBALL_BAT,
    ENERGY_DRINK,
    NINJA_STARS,
    NUNCHUCKS,
    POOP,
    FLAMETHROWER,
    HOOKS,
    WEIGHTS,
    SKULL,
    BRAIN
}

enum Mouth {
    NONE,
    HAPPY,
    MAD,
    SMILE,
    FANGS,
    HAPPY_FANGS,
    MAD_FANGS,
    SMILE_FANGS,
    SINGLE_TOOTH,
    DIRTY_TEETH,
    SMILE_DIRTY_TEETH,
    MAD_DIRTY_TEETH,
    BLOODY_FANGS,
    BLACK_MASK,
    HAPPY_BUCK_TEETH,
    HAPPY_SINGLE_TOOTH,
    MAD_SINGLE_TOOTH,
    SMILE_SINGLE_TOOTH,
    BREATHING_FIRE,
    GOLD_GRILLS,
    KISS,
    SMOKING_JOINT
}

enum Eyes {
    NONE,
    BLACK_EYE,
    BLACKOUT,
    BLEEDING,
    BLOODSHOT,
    WATERY,
    WHITE,
    BIGGER_BLACK_EYES,
    BIGGER_BLEEDING,
    BIGGER_WATERY,
    SMALLER_BLACK_EYES,
    SMALLER_BLEEDING,
    SMALLER_BLOODSHOT,
    SMALLER_WATERY,
    SMALLER,
    SUNGLASSES,
    EYE_PATCH,
    VR_HEADSET,
    DEAD,
    _3D_GLASSES,
    HEART_EYES,
    LASER_GLASSES,
    NINJA_MASK,
    LASER_EYES
}

enum HeadAccessory {
    NONE,
    BUCKET_HAT,
    FLOWER,
    SPORTS_HEADBAND,
    CHEF_HAT,
    BLUE_DURAG,
    RED_DURAG,
    SPIKY_HAIR,
    BONES,
    RICE_HAT,
    BEANIE_CAP,
    SANTA_HAT,
    HEAD_WOUND,
    HEADPHONES,
    GOLD_STUDS,
    WIZARD_HAT,
    LONG_HAIR,
    AIR_PODS,
    WHITE_PARTY_HAT,
    BLUE_PARTY_HAT,
    RED_PARTY_HAT,
    GREEN_PARTY_HAT,
    YELLOW_PARTY_HAT,
    PURPLE_PARTY_HAT,
    PIRATE_HAT,
    KING_CROWN,
    JOKER_HAT,
    DEVIL_HORNS,
    BRAINS
}

library Enums {
    function toString(Special v) external pure returns (string memory) {
        if (v == Special.NONE) {
            return "";
        }
    
        if (v == Special.DEVIL) {
            return "Devil";
        }
    
        if (v == Special.GHOST) {
            return "Ghost";
        }
    
        if (v == Special.HIPPIE) {
            return "Hippie";
        }
    
        if (v == Special.JOKER) {
            return "Society";
        }
    
        if (v == Special.PRISONER) {
            return "Prisoner";
        }
    
        if (v == Special.SQUID_GAME) {
            return "Squid Girl";
        }
    
        if (v == Special.WHERES_WALDO) {
            return "Where's Waldo?";
        }
    
        if (v == Special.HAZMAT) {
            return "Hazmat";
        }
    
        if (v == Special.ASTRONAUT) {
            return "Astronaut";
        }
        revert("invalid special");
    }
    
    function toString(Dominant v) external pure returns (string memory) {
        if (v == Dominant.SKELETON) {
            return "Skeleton";
        }
    
        if (v == Dominant.VAMPIRE) {
            return "Vampire";
        }
    
        if (v == Dominant.MUMMY) {
            return "Mummy";
        }
    
        if (v == Dominant.GHOST) {
            return "Ghost";
        }
    
        if (v == Dominant.WITCH) {
            return "Witch";
        }
    
        if (v == Dominant.FRANKENSTEIN) {
            return "Frankenstein";
        }
    
        if (v == Dominant.WEREWOLF) {
            return "Werewolf";
        }
    
        if (v == Dominant.PUMPKINHEAD) {
            return "Pumpkinhead";
        }
        revert("invalid dominant");
    }
    
    function toString(Recessive v) external pure returns (string memory) {
        if (v == Recessive.SKELETON) {
            return "Skeleton";
        }
    
        if (v == Recessive.VAMPIRE) {
            return "Vampire";
        }
    
        if (v == Recessive.MUMMY) {
            return "Mummy";
        }
    
        if (v == Recessive.GHOST) {
            return "Ghost";
        }
    
        if (v == Recessive.DEVIL) {
            return "Devil";
        }
    
        if (v == Recessive.KONG) {
            return "Kong";
        }
        revert("invalid recessive");
    }
    
    function toString(BgColor v) external pure returns (string memory) {
        if (v == BgColor.DARK_BLUE) {
            return "Dark Blue";
        }
    
        if (v == BgColor.GRAY) {
            return "Gray";
        }
    
        if (v == BgColor.LIGHT_BLUE) {
            return "Light Blue";
        }
    
        if (v == BgColor.ORANGE) {
            return "Orange";
        }
    
        if (v == BgColor.PINK) {
            return "Pink";
        }
    
        if (v == BgColor.PURPLE) {
            return "Purple";
        }
    
        if (v == BgColor.RED) {
            return "Red";
        }
    
        if (v == BgColor.TAN) {
            return "Tan";
        }
    
        if (v == BgColor.TEAL) {
            return "Teal";
        }
    
        if (v == BgColor.GREEN) {
            return "Green";
        }
    
        if (v == BgColor.RAINBOW) {
            return "Rainbow";
        }
        revert("invalid bgcolor");
    }
    
    function toString(Outfit v) external pure returns (string memory) {
        if (v == Outfit.WHITE_SHORTS) {
            return "White Shorts";
        }
    
        if (v == Outfit.PINK_SHORTS) {
            return "Pink Shorts";
        }
    
        if (v == Outfit.GRAY_PANTS) {
            return "Gray Pants";
        }
    
        if (v == Outfit.WHITE_AND_BLUE) {
            return "White and Blue";
        }
    
        if (v == Outfit.PURPLE_SHORTS) {
            return "Purple Shorts";
        }
    
        if (v == Outfit.PINK_AND_PURPLE) {
            return "Pink and Purple";
        }
    
        if (v == Outfit.BROWN_AND_WHITE) {
            return "Brown and White";
        }
    
        if (v == Outfit.BROWN_AND_BLUE) {
            return "Brown and Blue";
        }
    
        if (v == Outfit.BLUE_SHORTS) {
            return "Blue Shorts";
        }
    
        if (v == Outfit.BLUE_AND_WHITE) {
            return "Blue and White";
        }
    
        if (v == Outfit.UNDERGARMENTS) {
            return "Undergarments";
        }
    
        if (v == Outfit.LOUNGEWEAR) {
            return "Loungewear";
        }
    
        if (v == Outfit.HOBO) {
            return "Hobo";
        }
    
        if (v == Outfit.SPORTS_JERSEY) {
            return "Sports Jersey";
        }
    
        if (v == Outfit.GOLD_CHAIN) {
            return "Gold Chain";
        }
    
        if (v == Outfit.PAJAMAS) {
            return "Pajamas";
        }
    
        if (v == Outfit.OVERALLS) {
            return "Overalls";
        }
    
        if (v == Outfit.SPEEDO) {
            return "Speedo";
        }
    
        if (v == Outfit.NINJA_SUIT) {
            return "Ninja Suit";
        }
    
        if (v == Outfit.KARATE_UNIFORM) {
            return "Karate Uniform";
        }
    
        if (v == Outfit.NONE) {
            return "";
        }
    
        if (v == Outfit.LUMBERJACK) {
            return "Lumberjack";
        }
    
        if (v == Outfit.PRIEST) {
            return "Priest";
        }
    
        if (v == Outfit.TUX) {
            return "Tux";
        }
    
        if (v == Outfit.SKELETON) {
            return "Skeleton";
        }
    
        if (v == Outfit.CAMO) {
            return "Camo";
        }
    
        if (v == Outfit.ARMOR) {
            return "Armor";
        }
        revert("invalid outfit");
    }
    
    function toString(HandAccessory v) external pure returns (string memory) {
        if (v == HandAccessory.NONE) {
            return "";
        }
    
        if (v == HandAccessory.BLOODY_KNIFE) {
            return "Bloody Knife";
        }
    
        if (v == HandAccessory.BOW_AND_ARROW) {
            return "Bow and Arrow";
        }
    
        if (v == HandAccessory.SWORD) {
            return "Sword";
        }
    
        if (v == HandAccessory.PITCHFORK) {
            return "Pitchfork";
        }
    
        if (v == HandAccessory.WAND) {
            return "Wand";
        }
    
        if (v == HandAccessory.SPIKED_BASEBALL_BAT) {
            return "Spiked Baseball Bat";
        }
    
        if (v == HandAccessory.ENERGY_DRINK) {
            return "Energy Drink";
        }
    
        if (v == HandAccessory.NINJA_STARS) {
            return "Ninja Stars";
        }
    
        if (v == HandAccessory.NUNCHUCKS) {
            return "Nunchucks";
        }
    
        if (v == HandAccessory.POOP) {
            return "Poop";
        }
    
        if (v == HandAccessory.FLAMETHROWER) {
            return "Flamethrower";
        }
    
        if (v == HandAccessory.HOOKS) {
            return "Hooks";
        }
    
        if (v == HandAccessory.WEIGHTS) {
            return "Weights";
        }
    
        if (v == HandAccessory.SKULL) {
            return "Skull";
        }
    
        if (v == HandAccessory.BRAIN) {
            return "Brain";
        }
        revert("invalid handaccessory");
    }
    
    function toString(Mouth v) external pure returns (string memory) {
        if (v == Mouth.NONE) {
            return "";
        }
    
        if (v == Mouth.HAPPY) {
            return "Happy";
        }
    
        if (v == Mouth.MAD) {
            return "Mad";
        }
    
        if (v == Mouth.SMILE) {
            return "Smile";
        }
    
        if (v == Mouth.FANGS) {
            return "Fangs";
        }
    
        if (v == Mouth.HAPPY_FANGS) {
            return "Happy Fangs";
        }
    
        if (v == Mouth.MAD_FANGS) {
            return "Mad Fangs";
        }
    
        if (v == Mouth.SMILE_FANGS) {
            return "Smile Fangs";
        }
    
        if (v == Mouth.SINGLE_TOOTH) {
            return "Single Tooth";
        }
    
        if (v == Mouth.DIRTY_TEETH) {
            return "Dirty Teeth";
        }
    
        if (v == Mouth.SMILE_DIRTY_TEETH) {
            return "Smile Dirty Teeth";
        }
    
        if (v == Mouth.MAD_DIRTY_TEETH) {
            return "Mad Dirty Teeth";
        }
    
        if (v == Mouth.BLOODY_FANGS) {
            return "Bloody Fangs";
        }
    
        if (v == Mouth.BLACK_MASK) {
            return "Black Mask";
        }
    
        if (v == Mouth.HAPPY_BUCK_TEETH) {
            return "Happy Buck Teeth";
        }
    
        if (v == Mouth.HAPPY_SINGLE_TOOTH) {
            return "Happy Single Tooth";
        }
    
        if (v == Mouth.MAD_SINGLE_TOOTH) {
            return "Mad Single Tooth";
        }
    
        if (v == Mouth.SMILE_SINGLE_TOOTH) {
            return "Smile Single Tooth";
        }
    
        if (v == Mouth.BREATHING_FIRE) {
            return "Breathing Fire";
        }
    
        if (v == Mouth.GOLD_GRILLS) {
            return "Gold Grills";
        }
    
        if (v == Mouth.KISS) {
            return "Kiss";
        }
    
        if (v == Mouth.SMOKING_JOINT) {
            return "Smoking Joint";
        }
        revert("invalid mouth");
    }
    
    function toString(Eyes v) external pure returns (string memory) {
        if (v == Eyes.NONE) {
            return "";
        }
    
        if (v == Eyes.BLACK_EYE) {
            return "Black Eye";
        }
    
        if (v == Eyes.BLACKOUT) {
            return "Blackout";
        }
    
        if (v == Eyes.BLEEDING) {
            return "Bleeding";
        }
    
        if (v == Eyes.BLOODSHOT) {
            return "Bloodshot";
        }
    
        if (v == Eyes.WATERY) {
            return "Watery";
        }
    
        if (v == Eyes.WHITE) {
            return "White";
        }
    
        if (v == Eyes.BIGGER_BLACK_EYES) {
            return "Bigger Black Eyes";
        }
    
        if (v == Eyes.BIGGER_BLEEDING) {
            return "Bigger Bleeding";
        }
    
        if (v == Eyes.BIGGER_WATERY) {
            return "Bigger Watery";
        }
    
        if (v == Eyes.SMALLER_BLACK_EYES) {
            return "Smaller Black Eyes";
        }
    
        if (v == Eyes.SMALLER_BLEEDING) {
            return "Smaller Bleeding";
        }
    
        if (v == Eyes.SMALLER_BLOODSHOT) {
            return "Smaller Bloodshot";
        }
    
        if (v == Eyes.SMALLER_WATERY) {
            return "Smaller Watery";
        }
    
        if (v == Eyes.SMALLER) {
            return "Smaller";
        }
    
        if (v == Eyes.SUNGLASSES) {
            return "Sunglasses";
        }
    
        if (v == Eyes.EYE_PATCH) {
            return "Eye Patch";
        }
    
        if (v == Eyes.VR_HEADSET) {
            return "VR Headset";
        }
    
        if (v == Eyes.DEAD) {
            return "Dead";
        }
    
        if (v == Eyes._3D_GLASSES) {
            return "3D Glasses";
        }
    
        if (v == Eyes.HEART_EYES) {
            return "Heart Eyes";
        }
    
        if (v == Eyes.LASER_GLASSES) {
            return "Laser Glasses";
        }
    
        if (v == Eyes.NINJA_MASK) {
            return "Ninja Mask";
        }
    
        if (v == Eyes.LASER_EYES) {
            return "Laser Eyes";
        }
        revert("invalid eyes");
    }
    
    function toString(HeadAccessory v) external pure returns (string memory) {
        if (v == HeadAccessory.NONE) {
            return "";
        }
    
        if (v == HeadAccessory.BUCKET_HAT) {
            return "Bucket Hat";
        }
    
        if (v == HeadAccessory.FLOWER) {
            return "Flower";
        }
    
        if (v == HeadAccessory.SPORTS_HEADBAND) {
            return "Sports Headband";
        }
    
        if (v == HeadAccessory.CHEF_HAT) {
            return "Chef Hat";
        }
    
        if (v == HeadAccessory.BLUE_DURAG) {
            return "Blue Durag";
        }
    
        if (v == HeadAccessory.RED_DURAG) {
            return "Red Durag";
        }
    
        if (v == HeadAccessory.SPIKY_HAIR) {
            return "Spiky Hair";
        }
    
        if (v == HeadAccessory.BONES) {
            return "Bones";
        }
    
        if (v == HeadAccessory.RICE_HAT) {
            return "Rice Hat";
        }
    
        if (v == HeadAccessory.BEANIE_CAP) {
            return "Beanie Cap";
        }
    
        if (v == HeadAccessory.SANTA_HAT) {
            return "Santa Hat";
        }
    
        if (v == HeadAccessory.HEAD_WOUND) {
            return "Head Wound";
        }
    
        if (v == HeadAccessory.HEADPHONES) {
            return "Headphones";
        }
    
        if (v == HeadAccessory.GOLD_STUDS) {
            return "Gold Studs";
        }
    
        if (v == HeadAccessory.WIZARD_HAT) {
            return "Wizard Hat";
        }
    
        if (v == HeadAccessory.LONG_HAIR) {
            return "Long Hair";
        }
    
        if (v == HeadAccessory.AIR_PODS) {
            return "Air Pods";
        }
    
        if (v == HeadAccessory.WHITE_PARTY_HAT) {
            return "White Party Hat";
        }
    
        if (v == HeadAccessory.BLUE_PARTY_HAT) {
            return "Blue Party Hat";
        }
    
        if (v == HeadAccessory.RED_PARTY_HAT) {
            return "Red Party Hat";
        }
    
        if (v == HeadAccessory.GREEN_PARTY_HAT) {
            return "Green Party Hat";
        }
    
        if (v == HeadAccessory.YELLOW_PARTY_HAT) {
            return "Yellow Party Hat";
        }
    
        if (v == HeadAccessory.PURPLE_PARTY_HAT) {
            return "Purple Party Hat";
        }
    
        if (v == HeadAccessory.PIRATE_HAT) {
            return "Pirate Hat";
        }
    
        if (v == HeadAccessory.KING_CROWN) {
            return "King Crown";
        }
    
        if (v == HeadAccessory.JOKER_HAT) {
            return "Joker Hat";
        }
    
        if (v == HeadAccessory.DEVIL_HORNS) {
            return "Devil Horns";
        }
    
        if (v == HeadAccessory.BRAINS) {
            return "Brains";
        }
        revert("invalid headaccessory");
    }
}

// File: contracts/BitMonster.sol


pragma solidity ^0.8.0;


struct BitMonster {
    bool genesis;
    bool superYield;
    Special special;
    Dominant dominant;
    Recessive recessive;
    BgColor bgColor;
    Outfit outfit;
    HandAccessory handAccessory;
    Mouth mouth;
    Eyes eyes;
    HeadAccessory headAccessory;
}

// File: contracts/IBitMonsters.sol


pragma solidity ^0.8.0;



interface IBitMonsters is IERC721Enumerable {
    function getBitMonster(uint256 tokenId) external view returns (BitMonster memory);
    function setBitMonster(uint256 tokenId, BitMonster memory bm) external;
    function createBitMonster(BitMonster memory bm, address owner) external;
    function isAdmin(address addr) external view returns (bool);
}
// File: contracts/BitMonstersAddon.sol


pragma solidity ^0.8.0;



/**
 * @title A contract should inherit this if it provides functionality for the Bit Monsters contract.
 */
abstract contract BitMonstersAddon is Ownable {
    IBitMonsters internal bitMonsters;

    modifier onlyAdmin() {
        require(bitMonsters.isAdmin(msg.sender), "admins only");
        _;
    }

    modifier ownsToken(uint tokenId) {
        require(bitMonsters.ownerOf(tokenId) == msg.sender, "you don't own this shit");
        _;
    }

    /**
     * @notice This must be called before the Brainz contract can be used.
     *
     * @dev Within the BitMonsters contract, call initializeBrainz().
     */
    function setBitMonstersContract(IBitMonsters _contract) external onlyOwner {
        bitMonsters = _contract;
    }
}

// File: contracts/BitMonsterGen.sol


pragma solidity ^0.8.0;





library BitMonsterGen {
    using RngLibrary for Rng;

    function getRandomBgColor(Rng memory rng) internal view returns (BgColor) {
        if (rng.generate(1, 1000) == 1) {
            return BgColor.RAINBOW;
        }
        return BgColor(rng.generate(0, 9));
    }

    function getRandomDominant(Rng memory rng) internal view returns (Dominant) {
        // all rarities are out of 10000
        uint rn = rng.generate(0, 9999);
        uint16[8] memory rarities = Rarities.dominant();
    
        for (uint i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return Dominant(i);
            }
            rn -= rarities[i];
        }
        revert("getRandomDominant() is fucked");
    } 
    
    function getRandomRecessive(Rng memory rng) internal view returns (Recessive) {
        // all rarities are out of 10000
        uint rn = rng.generate(0, 9999);
        uint16[6] memory rarities = Rarities.recessive();
    
        for (uint i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return Recessive(i);
            }
            rn -= rarities[i];
        }
        revert("getRandomRecessive() is fucked");
    } 
    
    function getRandomOutfit(Rng memory rng) internal view returns (Outfit) {
        // all rarities are out of 10000
        uint rn = rng.generate(0, 9999);
        uint16[27] memory rarities = Rarities.outfit();
    
        for (uint i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return Outfit(i);
            }
            rn -= rarities[i];
        }
        revert("getRandomOutfit() is fucked");
    } 
    
    function getRandomHandAccessory(Rng memory rng) internal view returns (HandAccessory) {
        // all rarities are out of 10000
        uint rn = rng.generate(0, 9999);
        uint16[16] memory rarities = Rarities.handaccessory();
    
        for (uint i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return HandAccessory(i);
            }
            rn -= rarities[i];
        }
        revert("getRandomHandAccessory() is fucked");
    } 
    
    function getRandomMouth(Rng memory rng) internal view returns (Mouth) {
        // all rarities are out of 10000
        uint rn = rng.generate(0, 9999);
        uint16[22] memory rarities = Rarities.mouth();
    
        for (uint i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return Mouth(i);
            }
            rn -= rarities[i];
        }
        revert("getRandomMouth() is fucked");
    } 
    
    function getRandomEyes(Rng memory rng) internal view returns (Eyes) {
        // all rarities are out of 10000
        uint rn = rng.generate(0, 9999);
        uint16[24] memory rarities = Rarities.eyes();
    
        for (uint i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return Eyes(i);
            }
            rn -= rarities[i];
        }
        revert("getRandomEyes() is fucked");
    } 
    
    function getRandomHeadAccessory(Rng memory rng) internal view returns (HeadAccessory) {
        // all rarities are out of 10000
        uint rn = rng.generate(0, 9999);
        uint16[29] memory rarities = Rarities.headaccessory();
    
        for (uint i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return HeadAccessory(i);
            }
            rn -= rarities[i];
        }
        revert("getRandomHeadAccessory() is fucked");
    } 

    function generateUnspecialBitMonster(Rng memory rng) internal view returns (BitMonster memory) {
        BitMonster memory ret = BitMonster({
            genesis:       true,
            superYield:    rng.generate(0, 99) == 0,
            special:       Special.NONE,
            dominant:      getRandomDominant(rng),
            recessive:     getRandomRecessive(rng),
            bgColor:       getRandomBgColor(rng),
            outfit:        getRandomOutfit(rng),
            handAccessory: getRandomHandAccessory(rng),
            mouth:         getRandomMouth(rng),
            eyes:          getRandomEyes(rng),
            headAccessory: getRandomHeadAccessory(rng)
        });

        return ret;
    }

    function generateSpecialBitMonster(Rng memory rng, bool[9] memory mintedSpecials) internal view returns (BitMonster memory) {
        uint available = mintedSpecials.length;
        for (uint i = 0; i < mintedSpecials.length; ++i) {
            if (mintedSpecials[i]) {
                available--;
            }
        }

        if (available == 0) {
            return generateUnspecialBitMonster(rng);
        }

        uint rn = rng.generate(0, available - 1);
        uint special;

        // generate a random special index, skipping specials that do not exist
        for (special = 0; special < 9; ++special) {
            if (mintedSpecials[special]) {
                continue;
            }
            if (rn == 0) {
                break;
            }
            rn -= 1;
        }

        require(!mintedSpecials[special]);
        mintedSpecials[special] = true;

        return BitMonster({
            genesis:       true,
            superYield:    rng.generate(0, 4) == 0,
            // + 1 because 0 is None
            special:       Special(special + 1),
            dominant:      getRandomDominant(rng),
            recessive:     getRandomRecessive(rng),
            bgColor:       BgColor.DARK_BLUE,
            outfit:        Outfit.NONE,
            handAccessory: HandAccessory.NONE,
            mouth:         Mouth.NONE,
            eyes:          Eyes.NONE,
            headAccessory: HeadAccessory.NONE
        });
    }

    function rerollTrait(Rng memory rng, BitMonster memory bm, RerollTrait trait) internal view {
        bm.genesis = false;
        if (trait == RerollTrait.BgColor) {
            BgColor existing = bm.bgColor;
            while (bm.bgColor == existing) {
                bm.bgColor = getRandomBgColor(rng);
            }
        }
        else if (trait == RerollTrait.Outfit) {
            Outfit existing = bm.outfit;
            while (bm.outfit == existing) {
                bm.outfit = getRandomOutfit(rng);
            }
        }
        else if (trait == RerollTrait.HandAccessory) {
            HandAccessory existing = bm.handAccessory;
            while (bm.handAccessory == existing) {
                bm.handAccessory = getRandomHandAccessory(rng);
            }
        }
        else if (trait == RerollTrait.Mouth) {
            Mouth existing = bm.mouth;
            while (bm.mouth == existing) {
                bm.mouth = getRandomMouth(rng);
            }
        }
        else if (trait == RerollTrait.Eyes) {
            Eyes existing = bm.eyes;
            while (bm.eyes == existing) {
                bm.eyes = getRandomEyes(rng);
            }
        }
        else if (trait == RerollTrait.HeadAccessory) {
            HeadAccessory existing = bm.headAccessory;
            while (bm.headAccessory == existing) {
                bm.headAccessory = getRandomHeadAccessory(rng);
            }
        }
        else {
            revert("Invalid reroll trait");
        }
    }

    function rerollAll(Rng memory rng, BitMonster memory bm) internal view {
        bm.genesis = false;
        bm.bgColor = getRandomBgColor(rng);
        bm.outfit = getRandomOutfit(rng);
        bm.handAccessory = getRandomHandAccessory(rng);
        bm.mouth = getRandomMouth(rng);
        bm.eyes = getRandomEyes(rng);
        bm.headAccessory = getRandomHeadAccessory(rng);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: contracts/Minter.sol


pragma solidity ^0.8.0;







/**
 * @title Controls who (if anyone) can mint a Bit Monster.
 *
 * @dev In web3, these are represented as 0 (NotAllowed), 1 (WhitelistOnly), and 2 (AllAllowed).
 */
enum MintingState {
    NotAllowed,
    WhitelistOnly,
    AllAllowed
}

contract Minter is BitMonstersAddon {
    using RngLibrary for Rng;

    uint256 constant public WHITELIST_PER = 6;

    address payable private payHere;
    // 0 == "not whitelisted"
    // 1000 + x == "whitelisted and x whitelists left"
    mapping (address => uint256) public whitelist;
    MintingState public mintingState;

    bool[9] public mintedSpecials;
    uint private mintedSpecialsCount = 0;

    Rng private rng;

    constructor(address payable paymentAddress, address[] memory whitelistedAddrs) {
        payHere = paymentAddress;
        whitelist[paymentAddress] = WHITELIST_PER + 1000;
        for (uint i = 0; i < whitelistedAddrs.length; ++i) {
            whitelist[whitelistedAddrs[i]] = WHITELIST_PER + 1000;
        }
        rng = RngLibrary.newRng();
    }

    /**
     * Adds someone to the whitelist.
     */
    function addToWhitelist(address[] memory addrs) external onlyAdmin {
        for (uint i = 0; i < addrs.length; ++i) {
            if (whitelist[addrs[i]] == 0) {
                whitelist[addrs[i]] = WHITELIST_PER + 1000;
            }
        }
    }

    /**
     * Removes someone from the whitelist.
     */
    function removeFromWhitelist(address addr) external onlyAdmin {
        delete whitelist[addr];
    }

    /**
     * Generates a random Bit Monster.
     *
     * 9/6666 bit monsters will be special, which means they're prebuilt images instead of assembled from the 6 attributes a normal Bit Monster has.
     * All 9 specials are guaranteed to be minted by the time all 6666 Bit Monsters are minted.
     * The chance of a special at each roll is roughly even, although there's a slight dip in chance in the mid-range.
     */
    function generateBitMonster(Rng memory rn, bool[9] memory ms) internal returns (BitMonster memory) {
        uint count = bitMonsters.totalSupply();

        int ub = 6666 - int(count) - 1 - (90 - int(mintedSpecialsCount) * 10);
        if (ub < 0) {
            ub = 0;
        }

        BitMonster memory m;
        if (rn.generate(0, uint(ub)) <= (6666 - count) / 666) {
            m = BitMonsterGen.generateSpecialBitMonster(rn, ms);
        }
        else {
            m = BitMonsterGen.generateUnspecialBitMonster(rn);
        }

        if (m.special != Special.NONE) {
            mintedSpecialsCount++;
        }
        rng = rn;
        return m;
    }

    /**
     * Sets the MintingState. See MintingState above.
     * By default, no one is allowed to mint. This function must be called before any Bit Monsters can be minted.
     */
    function setMintingState(MintingState state) external onlyAdmin {
        mintingState = state;
    }

    /**
     * Mints some Bit Monsters.
     *
     * @param count The number of Bit Monsters to mint. Must be >= 1 and <= 10.
     *              You must send 0.06 ETH for each Bit Monster you want to mint.
     */
    function mint(uint count) external payable {
        require(count >= 1 && count <= 10, "Count must be >=1 and <=10");
        require(!Address.isContract(msg.sender), "Contracts cannot mint");
        require(mintingState != MintingState.NotAllowed, "Minting is not allowed atm");

        if (mintingState == MintingState.WhitelistOnly) {
            require(whitelist[msg.sender] >= 1000 + count, "Not enough whitelisted mints");
            whitelist[msg.sender] -= count;
        }

        require(msg.value == count * 0.06 ether, "Send exactly 0.06 ETH for each mint");

        Rng memory rn = rng;
        bool[9] memory ms = mintedSpecials;

        for (uint i = 0; i < count; ++i) {
            bitMonsters.createBitMonster(generateBitMonster(rn, ms), msg.sender);
        }

        rng = rn;
        mintedSpecials = ms;

        Address.sendValue(payHere, msg.value);
    }

    /**
     * Mint for a giveaway.
     */
    function giveawayMint(address[] memory winners) external onlyAdmin {
        Rng memory rn = rng;

        for (uint i = 0; i < winners.length; ++i) {
            bitMonsters.createBitMonster(BitMonsterGen.generateUnspecialBitMonster(rn), winners[i]);
        }

        rng = rn;
    }
}