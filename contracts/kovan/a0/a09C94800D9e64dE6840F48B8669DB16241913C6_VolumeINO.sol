// SPDX-License-Identifier: GPL-v3
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVolumeFactory.sol";

contract VolumeINO is Context {
    using SafeMath for uint256;

    uint256 constant BASE = 10 ** 18;

    address owner;
    address daiAddress;
    address treasuryAddress;
    address nftFactoryAddress;

    // Applications
    struct Application {
        string name;
        string symbol;
        string description;
        string URI;
        uint256 totalSupply;
        uint256 minPrice;
        uint256 maxPrice;
        uint8[] perkLevels;
        address applicant;
        
        // artist
        string artistName;
        string artistSocial;
    }
    mapping(address => Application) addressToApplication;
    mapping(address => bool) addressToApplied;

    // Moderator
    mapping(address => bool) addressToIsMod;

    // Modifiers
    modifier onlyOwner() {
        require(_msgSender() == owner, "Not owner");
        _;
    }

    modifier onlyMod() {
        require(addressToIsMod[_msgSender()] || _msgSender() == owner, "Not mod or owner");
        _;
    }

    // Events
    event APPLIED_FOR_CATEGORY(address indexed applicant, string indexed name, string indexed symbol, uint256 totalSupply);
    event ACCEPTED_CATEGORY(string indexed name, string indexed symbol);

    constructor(address _nftFactoryAddress, address _treasuryAddress, address _daiAddress) {
        owner = _msgSender();
        nftFactoryAddress = _nftFactoryAddress;
        treasuryAddress = _treasuryAddress;
        daiAddress = _daiAddress;
    }

    /**
      * This function should only be called if you want to apply to launch your
      * NFT collection. 
      * NOTE There is a 20 usd application fee that will be deducted when applying.
      *
      * @dev The _URI should resolve to the storage address of the tokens.
      * Please use IPFS and number each image from 1 to the amount of NFTs you want to create.
      * For instance if your storage location is {"path/to/images/"} you want to name each image
      * their number in the enumeration. So image 1 will be called "0" with a full path of {"path/to/images/0"}.
      * The {_URI} will then be set to {"path/to/images"}.
      * Please see {VolumeNFT.sol-_baseURI}
     */
    function applyForCategory(
        string memory _name, 
        string memory _symbol, 
        string memory _description,
        string memory _URI, 
        uint256 _minPrice, 
        uint256 _maxPrice, 
        uint256 _numTokens, 
        uint8[] memory _perkLevels,
        string memory _artistName,
        string memory _artistSocial
    )
        external 
    {
        require(_perkLevels.length == _numTokens, "NUM PERK LEVELS");
        require(!addressToApplied[_msgSender()], "Already applied");
        
        uint256 transferAmount = 20 * BASE;
        IERC20 dai = IERC20(daiAddress);
        require(dai.balanceOf(_msgSender()) >= transferAmount, "Insufficient DAI");

        if(dai.transferFrom(_msgSender(), treasuryAddress, transferAmount)) {
            addressToApplication[_msgSender()] = Application(_name, _symbol, _description, _URI, _numTokens, _minPrice, _maxPrice, _perkLevels, _msgSender(), _artistName, _artistSocial);
            addressToApplied[_msgSender()] = true;
            emit APPLIED_FOR_CATEGORY(_msgSender(), _name, _symbol, _numTokens);
        }
    }

    /**
      * @dev The owner can call this function to accept the application
      * created by a specific address. This will create the category and 
      * immediately make it available for purchase by the public.
     */
    function acceptAddress(address _accepted) external onlyMod {
        require(addressToApplied[_accepted], "No application");

        Application memory application = addressToApplication[_accepted];

        // Call Factory
        IVolumeFactory nftFactory = IVolumeFactory(nftFactoryAddress);
        nftFactory.addCategory(
            application.name, 
            application.symbol,
            application.description,
            application.URI, 
            application.minPrice, 
            application.maxPrice, 
            application.totalSupply, 
            application.perkLevels, 
            application.applicant,
            application.artistName,
            application.artistSocial
        );

        emit ACCEPTED_CATEGORY(application.name, application.symbol);

        delete(addressToApplication[_accepted]);
        delete(addressToApplied[_accepted]);
    }

    /**
      * @dev The owner can call this function to decline an 
      * application made by a specific address. This will reset 
      * applied to false and open up the address for another application.
     */
    function declineAddress(address _declined) external onlyMod {
        require(addressToApplied[_declined], "No application");

        delete(addressToApplication[_declined]);
        delete(addressToApplied[_declined]);
    }

    function getApplicationForAddress(address _applicant) external view returns (Application memory) {
        require(addressToApplied[_applicant], "No application");

        return addressToApplication[_applicant];
    }

    function getAppliedForAddress(address _applicant) external view returns (bool) {
        return addressToApplied[_applicant];
    }

    // === MODERATOR
    function giveModerator(address _newMod) external onlyOwner {
        addressToIsMod[_newMod] = true;
    }

    function revokeModerator(address _mod) external onlyOwner {
        addressToIsMod[_mod] = false;
    }
}

// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.4;

struct Listing {
    address nftAddress;
    uint256 id;
    uint256 price;
    uint status; // 0 - empty listing, 1 - waiting for nft, 2 - listed

    address owner;
    uint256 listingNumber;

    bool mutex;
}

struct MileStone {
    uint256 startBlock;
    uint256 endBlock;
    string name;
    uint256 amountInPot; // total Vol deposited for this milestone rewards
    uint256 totalFuelAdded; // total fuel added during this milestone
}

struct UserFuel {
    address user;
    uint256 fuelAdded;
}

struct Category {
    string name;
        string description;
        address nftAddress;
        uint256 number;
        uint256 totalSupply;
        uint256 minPrice;
        uint256 maxPrice;
        uint256 leftForPurchase;
        uint8[] perkLevels;
        address categoryOwner;

        //artist
        string artistName;
        string artistSocial;

        // track
        bool mutex;
        uint256 createdAt; // block it was created at - used to keep track of timeline of launches
}

struct Application {
    string name;
        string symbol;
        string description;
        string URI;
        uint256 totalSupply;
        uint256 minPrice;
        uint256 maxPrice;
        uint8[] perkLevels;
        address applicant;
        
        // artist
        string artistName;
        string artistSocial;
}

// SPDX-License-Identifier: GPLV3
// contracts/VolumeNFTFactory.sol
pragma solidity ^0.8.4;

import "../data/structs.sol";

interface IVolumeFactory {
    function addCategory(
        string memory _name, 
        string memory _symbol,
        string memory _description,
        string memory _URI, 
        uint256 _minPrice, 
        uint256 _maxPrice, 
        uint256 _numTokens, 
        uint8[] memory _perkLevels, 
        address _collectionOwner,
        string memory _artistName,
        string memory _artistSocial
    ) external;
    function buyNFTForAddress(address _address, uint256 amount, uint256 slippage) external;
    function getNumberOfCategories() external view returns (uint256);
    function getCategoryByNumber(uint256 _categoryNum) external view returns (Category memory);
    function getAllCategories() external view returns (Category[] memory);
    function getCategoryByNFTAddress(address _address) external view returns (Category memory);
    function getAddressIsCreator(address _c) external view returns (bool isCreator);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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