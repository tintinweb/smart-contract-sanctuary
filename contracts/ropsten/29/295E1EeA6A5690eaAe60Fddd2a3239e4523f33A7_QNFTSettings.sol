// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interface/structs.sol";
import "../interface/IQStk.sol";
import "../interface/IQNFT.sol";
import "../interface/IQNFTSettings.sol";

/**
 * @author fantasy
 */
contract QNFTSettings is Ownable, IQNFTSettings {
    using SafeMath for uint256;

    // events
    event SetNonTokenPriceMultiplier(
        address indexed owner,
        uint256 nonTokenPriceMultiplier
    );
    event SetTokenPriceMultiplier(
        address indexed owner,
        uint256 tokenPriceMultiplier
    );
    event AddLockOption(
        address indexed owner,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 indexed lockDuration,
        uint256 discount // percent
    );
    event RemoveLockOption(address indexed owner, uint256 indexed lockOptionId);
    event AddImageSets(
        address indexed owner,
        uint256[] mintPrices,
        address[] designers,
        string[] dataUrls
    );
    event RemoveImageSet(address indexed owner, uint256 indexed nftImageId);
    event AddBgImages(address indexed owner, string[] dataUrls);
    event RemoveBgImage(address indexed owner, uint256 indexed bgImageId);
    event AddFavCoins(
        address indexed owner,
        uint256[] mintPrices,
        string[] dataUrls
    );
    event RemoveFavCoin(address indexed owner, uint256 favCoinId);

    // constants
    uint256 public constant EMOTION_COUNT_PER_NFT = 5;
    uint256 public constant BACKGROUND_IMAGE_COUNT = 4;
    uint256 public constant ARROW_IMAGE_COUNT = 3;
    uint256 public constant PERCENT_MAX = 100;

    // mint options set
    uint256 public qstkPrice; // qstk price
    uint256 public nonTokenPriceMultiplier; // percentage - should be multiplied to non token price - image + coin
    uint256 public tokenPriceMultiplier; // percentage - should be multiplied to token price - qstk

    LockOption[] public lockOptions; // array of lock options
    string[] public bgImages; // array of background image data urls
    NFTImage[] public nftImages; // array of nft images
    NFTFavCoin[] public favCoins; // array of favorite coins

    IQNFT public qnft; // QNFT contract address

    constructor() {
        qstkPrice = 0.00001 ether; // qstk price = 0.00001 ether
        nonTokenPriceMultiplier = PERCENT_MAX; // non token price multiplier = 100%;
        tokenPriceMultiplier = PERCENT_MAX; // token price multiplier = 100%;
    }

    /**
     * @dev returns the count of lock options
     */
    function lockOptionsCount() public view override returns (uint256) {
        return lockOptions.length;
    }

    /**
     * @dev returns the lock duration of given lock option id
     */
    function lockOptionLockDuration(uint256 _lockOptionId)
        public
        view
        override
        returns (uint256)
    {
        require(
            _lockOptionId < lockOptions.length,
            "QNFTSettings: invalid lock option"
        );

        return lockOptions[_lockOptionId].lockDuration;
    }

    /**
     * @dev adds a new lock option
     */
    function addLockOption(
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _lockDuration,
        uint256 _discount
    ) public onlyOwner {
        require(_discount < PERCENT_MAX, "QNFTSettings: invalid discount");
        lockOptions.push(
            LockOption(_minAmount, _maxAmount, _lockDuration, _discount)
        );

        emit AddLockOption(
            msg.sender,
            _minAmount,
            _maxAmount,
            _lockDuration,
            _discount
        );
    }

    /**
     * @dev remove a lock option
     */
    function removeLockOption(uint256 _lockOptionId) public onlyOwner {
        require(
            qnft.mintStarted() == false,
            "QNFTSettings: mint already started"
        );

        uint256 length = lockOptions.length;
        require(length > _lockOptionId, "QNFTSettings: invalid lock option id");

        lockOptions[_lockOptionId] = lockOptions[length - 1];
        lockOptions.pop();

        emit RemoveLockOption(msg.sender, _lockOptionId);
    }

    /**
     * @dev returns the count of nft images sets
     */
    function nftImagesCount() public view override returns (uint256) {
        return nftImages.length;
    }

    /**
     * @dev returns the mint price of given nft image id
     */
    function nftImageMintPrice(uint256 _nftImageId)
        public
        view
        override
        returns (uint256)
    {
        require(
            _nftImageId < nftImages.length,
            "QNFTSettings: invalid image id"
        );
        return nftImages[_nftImageId].mintPrice;
    }

    /**
     * @dev adds a new nft iamges set
     */
    function addImageSets(
        uint256[] memory _mintPrices,
        address[] memory _designers,
        string[] memory _dataUrls
    ) public onlyOwner {
        uint256 length = _mintPrices.length;
        require(
            length > 0 &&
                length == _designers.length &&
                length == _dataUrls.length,
            "QNFTSettings: invalid arguments"
        );

        for (uint16 i = 0; i < length; i++) {
            nftImages.push(
                NFTImage(_mintPrices[i], _designers[i], _dataUrls[i])
            );
        }

        emit AddImageSets(msg.sender, _mintPrices, _designers, _dataUrls);
    }

    /**
     * @dev removes a nft images set
     */
    function removeImageSet(uint256 _nftImageId) public onlyOwner {
        require(
            qnft.mintStarted() == false,
            "QNFTSettings: mint already started"
        );

        uint256 length = nftImages.length;
        require(length > _nftImageId, "QNFTSettings: invalid id");

        nftImages[_nftImageId] = nftImages[length - 1];
        nftImages.pop();

        emit RemoveImageSet(msg.sender, _nftImageId);
    }

    /**
     * @dev returns the count of background images
     */
    function bgImagesCount() public view override returns (uint256) {
        return bgImages.length;
    }

    /**
     * @dev adds a new background image
     */
    function addBgImages(string[] memory _dataUrls) public onlyOwner {
        uint256 length = _dataUrls.length;
        require(length > 0, "QNFTSettings: no data");

        for (uint16 i = 0; i < length; i++) {
            bgImages.push(_dataUrls[i]);
        }

        emit AddBgImages(msg.sender, _dataUrls);
    }

    /**
     * @dev removes a background image
     */
    function removeBgImage(uint256 _bgImageId) public onlyOwner {
        require(
            qnft.mintStarted() == false,
            "QNFTSettings: mint already started"
        );

        uint256 length = bgImages.length;
        require(length > _bgImageId, "QNFTSettings: invalid id");

        bgImages[_bgImageId] = bgImages[length - 1];
        bgImages.pop();

        emit RemoveBgImage(msg.sender, _bgImageId);
    }

    /**
     * @dev returns the count of favorite coins
     */
    function favCoinsCount() public view override returns (uint256) {
        return favCoins.length;
    }

    /**
     * @dev returns the mint price of given favorite coin
     */
    function favCoinMintPrice(uint256 _favCoinId)
        public
        view
        override
        returns (uint256)
    {
        require(
            _favCoinId < favCoins.length,
            "QNFTSettings: invalid favcoin id"
        );

        return favCoins[_favCoinId].mintPrice;
    }

    /**
     * @dev adds a new favorite coin
     */
    function addFavCoins(
        uint256[] memory _mintPrices,
        string[] memory _dataUrls
    ) public onlyOwner {
        uint256 length = _mintPrices.length;
        require(
            length > 0 && length == _dataUrls.length,
            "QNFTSettings: invalid arguments"
        );

        for (uint16 i = 0; i < length; i++) {
            favCoins.push(NFTFavCoin(_mintPrices[i], _dataUrls[i]));
        }

        emit AddFavCoins(msg.sender, _mintPrices, _dataUrls);
    }

    /**
     * @dev removes a favorite coin
     */
    function removeFavCoin(uint256 _favCoinId) public onlyOwner {
        require(
            qnft.mintStarted() == false,
            "QNFTSettings: mint already started"
        );

        uint256 length = favCoins.length;
        require(length > _favCoinId, "QNFTSettings: invalid id");

        favCoins[_favCoinId] = favCoins[length - 1];
        favCoins.pop();

        emit RemoveFavCoin(msg.sender, _favCoinId);
    }

    /**
     * @dev calculate mint price of given mint options
     */
    function calcMintPrice(
        uint256 _imageId,
        uint256 _bgImageId,
        uint256 _favCoinId,
        uint256 _lockOptionId,
        uint256 _lockAmount,
        uint256 _freeAmount
    ) public view override returns (uint256) {
        require(
            nftImages.length > _imageId,
            "QNFTSettings: invalid image option"
        );
        require(
            bgImages.length > _bgImageId,
            "QNFTSettings: invalid background option"
        );
        require(
            lockOptions.length > _lockOptionId,
            "QNFTSettings: invalid lock option"
        );

        LockOption memory lockOption = lockOptions[_lockOptionId];

        require(
            lockOption.minAmount <= _lockAmount + _freeAmount &&
                _lockAmount <= lockOption.maxAmount,
            "QNFTSettings: invalid mint amount"
        );
        require(favCoins.length > _favCoinId, "QNFTSettings: invalid fav coin");

        // mintPrice = qstkPrice * lockAmount * discountRate * tokenPriceMultiplier + (imageMintPrice + favCoinMintPrice) * nonTokenPriceMultiplier

        uint256 decimal = IQStk(qnft.qstk()).decimals();
        uint256 tokenPrice =
            qstkPrice
                .mul(_lockAmount)
                .mul(uint256(PERCENT_MAX).sub(lockOption.discount))
                .div(10**decimal)
                .div(PERCENT_MAX);
        tokenPrice = tokenPrice.mul(tokenPriceMultiplier).div(PERCENT_MAX);

        uint256 nonTokenPrice =
            nftImages[_imageId].mintPrice.add(favCoins[_favCoinId].mintPrice);
        nonTokenPrice = nonTokenPrice.mul(nonTokenPriceMultiplier).div(
            PERCENT_MAX
        );

        return tokenPrice.add(nonTokenPrice);
    }

    /**
     * @dev sets QNFT contract address
     */
    function setQNft(IQNFT _qnft) public onlyOwner {
        require(qnft != _qnft, "QNFTSettings: QNFT already set");

        qnft = _qnft;
    }

    /**
     * @dev sets token price multiplier - qstk
     */
    function setTokenPriceMultiplier(uint256 _tokenPriceMultiplier)
        public
        onlyOwner
    {
        tokenPriceMultiplier = _tokenPriceMultiplier;

        emit SetTokenPriceMultiplier(msg.sender, tokenPriceMultiplier);
    }

    /**
     * @dev sets non token price multiplier - image + coins
     */
    function setNonTokenPriceMultiplier(uint256 _nonTokenPriceMultiplier)
        public
        onlyOwner
    {
        nonTokenPriceMultiplier = _nonTokenPriceMultiplier;

        emit SetNonTokenPriceMultiplier(msg.sender, nonTokenPriceMultiplier);
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
    constructor () {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// structs
enum VoteStatus {
    NotStarted, // vote not started
    InProgress, // vote started, min vote duration not passed
    AbleToWithdraw, // vote started, min vote duration passed, safe vote end time not passed
    AbleToSafeWithdraw // vote started, min vote duration passed, safe vote end time passed
}

struct LockOption {
    uint256 minAmount; // e.g. 0QSTK, 100QSTK, 200QSTK, 300QSTK
    uint256 maxAmount; // e.g. 0QSTK, 100QSTK, 200QSTK, 300QSTK
    uint256 lockDuration; // e.g. 3 months, 6 months, 1 year
    uint256 discount; // percent e.g. 10%, 20%, 30%
}

/** @dev NFTBackgroundImage dataUrl will have following json data
nft_bg_data = string[4]
*/

struct NFTImage {
    uint256 mintPrice;
    address designer;
    string dataUrl;
}

/** @dev NFTImage dataUrl will have following json data
nft_image_data = {
    emotions: string[5],
    designer: {
        name: string,
        info: string,
    },
}
 */

struct NFTFavCoin {
    uint256 mintPrice;
    string dataUrl;
}

/** @dev NFTFavCoin dataUrl will have following json data
nft_fav_coin = {
    name: string,
    symbol: string,
    icon: string,
    website: string,
    social: string,
    erc20: address,
    other: string,
}
 */

struct NFTCreator {
    // NFT minter informations
    string name;
    address wallet;
}
struct NFTMeta {
    // NFT meta informations
    string name;
    string color;
    string story;
}
struct NFTData {
    // NFT data
    uint256 imageId;
    uint256 bgImageId;
    uint256 favCoinId;
    uint256 lockOptionId;
    uint256 lockAmount;
    uint256 defaultImageIndex;
    uint256 createdAt;
    bool withdrawn;
    NFTMeta meta;
    NFTCreator creator;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IQStk {
    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./structs.sol";

interface IQNFT {
    function qstk() external view returns (address);

    function mintStarted() external view returns (bool);

    function mintFinished() external view returns (bool);

    function voteStatus() external view returns (VoteStatus);

    function qstkBalances(address user) external view returns (uint256);

    function totalAssignedQstk() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IQNFTSettings {
    function favCoinsCount() external view returns (uint256);

    function lockOptionsCount() external view returns (uint256);

    function nftImagesCount() external view returns (uint256);

    function bgImagesCount() external view returns (uint256);

    function nftImageMintPrice(uint256 _nftImageId)
        external
        view
        returns (uint256);

    function favCoinMintPrice(uint256 _favCoinId)
        external
        view
        returns (uint256);

    function lockOptionLockDuration(uint256 _lockOptionId)
        external
        view
        returns (uint256);

    function calcMintPrice(
        uint256 _imageId,
        uint256 _bgImageId,
        uint256 _favCoinId,
        uint256 _lockOptionId,
        uint256 _lockAmount,
        uint256 _freeAmount
    ) external view returns (uint256);
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}