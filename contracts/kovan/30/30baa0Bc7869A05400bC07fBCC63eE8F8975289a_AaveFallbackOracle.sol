// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";
import {IUniswapOracleGetter} from "../interfaces/IUniswapOracleGetter.sol";

contract AaveFallbackOracle is Ownable, IPriceOracleGetter {
    using SafeMathUpgradeable for uint256;

    struct Price {
        uint64 blockNumber;
        uint64 blockTimestamp;
        uint128 price;
    }

    event PricesSubmitted(address sybil, address[] assets, uint128[] prices);
    event SybilAuthorized(address indexed sybil);
    event SybilUnauthorized(address indexed sybil);

    uint256 public constant PERCENTAGE_BASE = 1e4;

    mapping(address => Price) private _prices;

    mapping(address => bool) private _sybils;

    address public _uniswapOracle;

    modifier onlySybil() {
        _requireWhitelistedSybil(msg.sender);
        _;
    }

    constructor(address uniswapOracle_) public {
        _uniswapOracle = uniswapOracle_;
    }

    function authorizeSybil(address sybil) external onlyOwner {
        _sybils[sybil] = true;

        emit SybilAuthorized(sybil);
    }

    function unauthorizeSybil(address sybil) external onlyOwner {
        _sybils[sybil] = false;

        emit SybilUnauthorized(sybil);
    }

    function submitPrices(address[] calldata assets, uint128[] calldata prices)
        external
        onlySybil
    {
        require(assets.length == prices.length, "INCONSISTENT_PARAMS_LENGTH");
        for (uint256 i = 0; i < assets.length; i++) {
            _prices[assets[i]] = Price(
                uint64(block.number),
                uint64(block.timestamp),
                prices[i]
            );
        }

        emit PricesSubmitted(msg.sender, assets, prices);
    }

    function getAssetPrice(address asset)
        external
        view
        override
        returns (uint256)
    {
        if (_uniswapOracle != address(0)) {
            return IUniswapOracleGetter(_uniswapOracle).getAssetPrice(asset);
        }

        return uint256(_prices[asset].price);
    }

    function isSybilWhitelisted(address sybil) public view returns (bool) {
        return _sybils[sybil];
    }

    function getPricesData(address[] calldata assets)
        external
        view
        returns (Price[] memory)
    {
        Price[] memory result = new Price[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            result[i] = _prices[assets[i]];
        }
        return result;
    }

    function filterCandidatePricesByDeviation(
        uint256 deviation,
        address[] calldata assets,
        uint256[] calldata candidatePrices
    ) external view returns (address[] memory, uint256[] memory) {
        require(
            assets.length == candidatePrices.length,
            "INCONSISTENT_PARAMS_LENGTH"
        );
        address[] memory filteredAssetsWith0s = new address[](assets.length);
        uint256[] memory filteredCandidatesWith0s = new uint256[](
            assets.length
        );
        uint256 end0sInLists;
        for (uint256 i = 0; i < assets.length; i++) {
            uint128 currentOraclePrice = _prices[assets[i]].price;
            if (
                uint256(currentOraclePrice) >
                candidatePrices[i].mul(PERCENTAGE_BASE.add(deviation)).div(
                    PERCENTAGE_BASE
                ) ||
                uint256(currentOraclePrice) <
                candidatePrices[i].mul(PERCENTAGE_BASE.sub(deviation)).div(
                    PERCENTAGE_BASE
                )
            ) {
                filteredAssetsWith0s[end0sInLists] = assets[i];
                filteredCandidatesWith0s[end0sInLists] = candidatePrices[i];
                end0sInLists++;
            }
        }
        address[] memory resultAssets = new address[](end0sInLists);
        uint256[] memory resultPrices = new uint256[](end0sInLists);
        for (uint256 i = 0; i < end0sInLists; i++) {
            resultAssets[i] = filteredAssetsWith0s[i];
            resultPrices[i] = filteredCandidatesWith0s[i];
        }

        return (resultAssets, resultPrices);
    }

    function _requireWhitelistedSybil(address sybil) internal view {
        require(isSybilWhitelisted(sybil), "INVALID_SYBIL");
    }

    function updateUniswapOracle(address oracle) external onlyOwner {
        _uniswapOracle = oracle;
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
library SafeMathUpgradeable {
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IPriceOracleGetter {
    /**
     * @dev returns the asset price in ETH wei
     * @param asset the address of the asset
     **/
    function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.0;

interface IUniswapOracleGetter {
    /**
     * @dev returns the asset price in ETH wei
     * @param asset the address of the asset
     **/
    function getAssetPrice(address asset) external view returns (uint256);
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