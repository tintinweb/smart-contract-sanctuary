// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";

import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeFactory.sol";
import "../library/HomoraMath.sol";

contract PriceCalculatorBSC is IPriceCalculator, OwnableUpgradeable {
    using SafeMath for uint;
    using HomoraMath for uint;

    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    IPancakeFactory private constant factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

    /* ========== STATE VARIABLES ========== */

    address public keeper;
    mapping(address => ReferenceData) public references;
    mapping(address => address) private tokenFeeds;

    /* ========== Event ========== */

    event MarketListed(address qToken);
    event MarketEntered(address qToken, address account);
    event MarketExited(address qToken, address account);

    event CloseFactorUpdated(uint newCloseFactor);
    event CollateralFactorUpdated(address qToken, uint newCollateralFactor);
    event LiquidationIncentiveUpdated(uint newLiquidationIncentive);
    event BorrowCapUpdated(address indexed qToken, uint newBorrowCap);

    /* ========== MODIFIERS ========== */

    modifier onlyKeeper() {
        require(msg.sender == keeper || msg.sender == owner(), "Qore: caller is not the owner or keeper");
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setKeeper(address _keeper) external onlyKeeper {
        require(_keeper != address(0), "PriceCalculatorBSC: invalid keeper address");
        keeper = _keeper;
    }

    function setTokenFeed(address asset, address feed) external onlyKeeper {
        tokenFeeds[asset] = feed;
    }

    function setPrices(address[] memory assets, uint[] memory prices) external onlyKeeper {
        for (uint i = 0; i < assets.length; i++) {
            references[assets[i]] = ReferenceData({ lastData: prices[i], lastUpdated: block.timestamp });
        }
    }

    /* ========== VIEWS ========== */

    function priceOf(address asset) public view override returns (uint priceInUSD) {
        (, priceInUSD) = _oracleValueOf(asset, 1e18);
        return priceInUSD;
    }

    function pricesOf(address[] memory assets) public view override returns (uint[] memory) {
        uint[] memory prices = new uint[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            prices[i] = priceOf(assets[i]);
        }
        return prices;
    }

    function getUnderlyingPrice(address qToken) public view override returns (uint) {
        return priceOf(IQToken(qToken).underlying());
    }

    function getUnderlyingPrices(address[] memory qTokens) public view override returns (uint[] memory) {
        uint[] memory prices = new uint[](qTokens.length);
        for (uint i = 0; i < qTokens.length; i++) {
            prices[i] = priceOf(IQToken(qTokens[i]).underlying());
        }
        return prices;
    }

    function priceOfBNB() public view returns (uint) {
        (, int price, , , ) = AggregatorV3Interface(tokenFeeds[WBNB]).latestRoundData();
        return uint(price).mul(1e10);
    }

    function valueOfAsset(address asset, uint amount) public view override returns (uint valueInBNB, uint valueInUSD) {
        if (asset == address(0) || asset == WBNB) {
            return _oracleValueOf(asset, amount);
        } else if (keccak256(abi.encodePacked(IPancakePair(asset).symbol())) == keccak256("Cake-LP")) {
            return _getPairPrice(asset, amount);
        } else {
            return _oracleValueOf(asset, amount);
        }
    }

    function unsafeValueOfAsset(address asset, uint amount) public view returns (uint valueInBNB, uint valueInUSD) {
        valueInBNB = 0;
        valueInUSD = 0;

        if (asset == address(0) || asset == WBNB) {
            valueInBNB = amount;
            valueInUSD = amount.mul(priceOfBNB()).div(1e18);
        } else if (keccak256(abi.encodePacked(IPancakePair(asset).symbol())) == keccak256("Cake-LP")) {
            if (IPancakePair(asset).totalSupply() == 0) return (0, 0);

            (uint reserve0, uint reserve1, ) = IPancakePair(asset).getReserves();
            if (IPancakePair(asset).token0() == WBNB) {
                valueInBNB = amount.mul(reserve0).mul(2).div(IPancakePair(asset).totalSupply());
                valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
            } else if (IPancakePair(asset).token1() == WBNB) {
                valueInBNB = amount.mul(reserve1).mul(2).div(IPancakePair(asset).totalSupply());
                valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
            } else {
                (uint tokenPriceInBNB, ) = valueOfAsset(IPancakePair(asset).token0(), 1e18);
                if (tokenPriceInBNB == 0) {
                    (tokenPriceInBNB, ) = valueOfAsset(IPancakePair(asset).token1(), 1e18);
                    if (IBEP20(IPancakePair(asset).token1()).decimals() < uint8(18)) {
                        reserve1 = reserve1.mul(10**uint(uint8(18) - IBEP20(IPancakePair(asset).token1()).decimals()));
                    }
                    valueInBNB = amount.mul(reserve1).mul(2).mul(tokenPriceInBNB).div(1e18).div(
                        IPancakePair(asset).totalSupply()
                    );
                } else {
                    if (IBEP20(IPancakePair(asset).token0()).decimals() < uint8(18)) {
                        reserve0 = reserve0.mul(10**uint(uint8(18) - IBEP20(IPancakePair(asset).token0()).decimals()));
                    }
                    valueInBNB = amount.mul(reserve0).mul(2).mul(tokenPriceInBNB).div(1e18).div(
                        IPancakePair(asset).totalSupply()
                    );
                }
                valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
            }
        } else {
            address pair = factory.getPair(asset, WBNB);
            if (IBEP20(asset).balanceOf(pair) == 0) return (0, 0);
            address token0 = IPancakePair(pair).token0();
            address token1 = IPancakePair(pair).token1();
            (uint reserve0, uint reserve1, ) = IPancakePair(pair).getReserves();

            if (IBEP20(token0).decimals() < uint8(18)) {
                reserve0 = reserve0.mul(10**uint(uint8(18) - IBEP20(token0).decimals()));
            }

            if (IBEP20(token1).decimals() < uint8(18)) {
                reserve1 = reserve1.mul(10**uint(uint8(18) - IBEP20(token1).decimals()));
            }

            if (IPancakePair(pair).token0() == WBNB) {
                valueInBNB = reserve0.mul(amount).div(reserve1);
            } else if (IPancakePair(pair).token1() == WBNB) {
                valueInBNB = reserve1.mul(amount).div(reserve0);
            } else {
                return (0, 0);
            }
            valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getPairPrice(address pair, uint amount) private view returns (uint valueInBNB, uint valueInUSD) {
        address token0 = IPancakePair(pair).token0();
        address token1 = IPancakePair(pair).token1();
        uint totalSupply = IPancakePair(pair).totalSupply();
        (uint reserve0, uint reserve1, ) = IPancakePair(pair).getReserves();

        if (IBEP20(token0).decimals() < uint8(18)) {
            reserve0 = reserve0.mul(10**uint(uint8(18) - IBEP20(token0).decimals()));
        }

        if (IBEP20(token1).decimals() < uint8(18)) {
            reserve1 = reserve1.mul(10**uint(uint8(18) - IBEP20(token1).decimals()));
        }

        uint sqrtK = HomoraMath.sqrt(reserve0.mul(reserve1)).fdiv(totalSupply);
        (uint px0, ) = _oracleValueOf(token0, 1e18);
        (uint px1, ) = _oracleValueOf(token1, 1e18);
        uint fairPriceInBNB = sqrtK.mul(2).mul(HomoraMath.sqrt(px0)).div(2**56).mul(HomoraMath.sqrt(px1)).div(2**56);

        valueInBNB = fairPriceInBNB.mul(amount).div(1e18);
        valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
    }

    function _oracleValueOf(address asset, uint amount) private view returns (uint valueInBNB, uint valueInUSD) {
        valueInUSD = 0;
        if (tokenFeeds[asset] != address(0)) {
            (, int price, , , ) = AggregatorV3Interface(tokenFeeds[asset]).latestRoundData();
            valueInUSD = uint(price).mul(1e10).mul(amount).div(1e18);
        } else if (references[asset].lastUpdated > block.timestamp.sub(1 days)) {
            valueInUSD = references[asset].lastData.mul(amount).div(1e18);
        }
        valueInBNB = valueInUSD.mul(1e18).div(priceOfBNB());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
pragma solidity >=0.6.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

interface IPriceCalculator {
    struct ReferenceData {
        uint lastData;
        uint lastUpdated;
    }

    function priceOf(address asset) external view returns (uint);

    function pricesOf(address[] memory assets) external view returns (uint[] memory);

    function getUnderlyingPrice(address qToken) external view returns (uint);

    function getUnderlyingPrices(address[] memory qTokens) external view returns (uint[] memory);

    function valueOfAsset(address asset, uint amount) external view returns (uint valueInBNB, uint valueInUSD);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "../library/QConstant.sol";

interface IQToken {
    function underlying() external view returns (address);

    function totalSupply() external view returns (uint);

    function accountSnapshot(address account) external view returns (QConstant.AccountSnapshot memory);

    function underlyingBalanceOf(address account) external view returns (uint);

    function borrowBalanceOf(address account) external view returns (uint);

    function borrowRatePerSec() external view returns (uint);

    function supplyRatePerSec() external view returns (uint);

    function totalBorrow() external view returns (uint);

    function totalReserve() external view returns (uint);

    function reserveFactor() external view returns (uint);

    function exchangeRate() external view returns (uint);

    function getCash() external view returns (uint);

    function getAccInterestIndex() external view returns (uint);

    function accruedAccountSnapshot(address account) external returns (QConstant.AccountSnapshot memory);

    function accruedUnderlyingBalanceOf(address account) external returns (uint);

    function accruedBorrowBalanceOf(address account) external returns (uint);

    function accruedTotalBorrow() external returns (uint);

    function accruedExchangeRate() external returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address dst, uint amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint amount
    ) external returns (bool);

    function supply(address account, uint underlyingAmount) external payable returns (uint);

    function redeemToken(address account, uint qTokenAmount) external returns (uint);

    function redeemUnderlying(address account, uint underlyingAmount) external returns (uint);

    function borrow(address account, uint amount) external returns (uint);

    function repayBorrow(address account, uint amount) external payable returns (uint);

    function repayBorrowBehalf(
        address payer,
        address borrower,
        uint amount
    ) external payable returns (uint);

    function liquidateBorrow(
        address qTokenCollateral,
        address liquidator,
        address borrower,
        uint amount
    ) external payable returns (uint qAmountToSeize);

    function seize(
        address liquidator,
        address borrower,
        uint qTokenAmount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

library HomoraMath {
    using SafeMath for uint;

    function divCeil(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs.add(rhs).sub(1) / rhs;
    }

    function fmul(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs.mul(rhs) / (2**112);
    }

    function fdiv(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs.mul(2**112) / rhs;
    }

    // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
    // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint x) internal pure returns (uint) {
        if (x == 0) return 0;
        uint xx = x;
        uint r = 1;

        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }

        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }

        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

library QConstant {
    uint public constant CLOSE_FACTOR_MIN = 5e16;
    uint public constant CLOSE_FACTOR_MAX = 9e17;
    uint public constant COLLATERAL_FACTOR_MAX = 9e17;

    struct MarketInfo {
        bool isListed;
        uint borrowCap;
        uint collateralFactor;
    }

    struct BorrowInfo {
        uint borrow;
        uint interestIndex;
    }

    struct AccountSnapshot {
        uint qTokenBalance;
        uint borrowBalance;
        uint exchangeRate;
    }

    struct AccrueSnapshot {
        uint totalBorrow;
        uint totalReserve;
        uint accInterestIndex;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IQore.sol";
import "../interfaces/IBEP20.sol";
import "hardhat/console.sol";

contract ReentrancyTesterForRedeem {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant qore = 0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48;
    address public constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;
    address public constant qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;

    /* ========== STATE VARIABLES ========== */
    bool public receiveCalled = false;

    /* ========== INITIALIZER ========== */

    constructor() public {}

    //    receive() external payable {
    //        console.log("receive called");
    //        receiveCalled = true;
    //        IQore(qore).redeemToken(qBNB, uint(1).mul(1e18));
    //        console.log("redeemToken called");
    //    }
    receive() external payable {
        console.log("receive called");
        receiveCalled = true;
        IQore(qore).redeemUnderlying(qBNB, uint(1).mul(1e18));
        console.log("redeemUnderlying called");
    }

    /* ========== FUNCTIONS ========== */

    function resetReceiveCalled() external {
        receiveCalled = false;
    }

    function callSupply(address qToken, uint uAmount) external payable {
        IQore(qore).supply{ value: msg.value }(qToken, uAmount);
    }

    function callRepayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable {
        IQore(qore).repayBorrowBehalf{ value: msg.value }(qToken, borrower, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/QConstant.sol";

interface IQore {
    function qValidator() external view returns (address);

    function getTotalUserList() external view returns (address[] memory);

    function allMarkets() external view returns (address[] memory);

    function marketListOf(address account) external view returns (address[] memory);

    function marketInfoOf(address qToken) external view returns (QConstant.MarketInfo memory);

    function liquidationIncentive() external view returns (uint);

    function checkMembership(address account, address qToken) external view returns (bool);

    function enterMarkets(address[] memory qTokens) external;

    function exitMarket(address qToken) external;

    function supply(address qToken, uint underlyingAmount) external payable returns (uint);

    function redeemToken(address qToken, uint qTokenAmount) external returns (uint);

    function redeemUnderlying(address qToken, uint underlyingAmount) external returns (uint);

    function borrow(address qToken, uint amount) external;

    function repayBorrow(address qToken, uint amount) external payable;

    function repayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable;

    function liquidateBorrow(
        address qTokenBorrowed,
        address qTokenCollateral,
        address borrower,
        uint amount
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint);

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
    function approve(address spender, uint amount) external returns (bool);

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
        uint amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IQore.sol";
import "../interfaces/IBEP20.sol";
import "hardhat/console.sol";

contract ReentrancyTesterForLiquidateBorrow {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant qore = 0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48;
    address public constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;
    address public constant qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;

    /* ========== STATE VARIABLES ========== */
    bool public receiveCalled = false;

    address public liquidation_borrower;

    /* ========== INITIALIZER ========== */

    constructor(address _borrower) public {
        liquidation_borrower = _borrower;
    }

    receive() external payable {
        console.log("receive called");
        receiveCalled = true;
        IQore(qore).liquidateBorrow(qBNB, qBNB, liquidation_borrower, uint(1).mul(1e18));
        console.log("liquidateBorrow called");
    }

    /* ========== FUNCTIONS ========== */

    function resetReceiveCalled() external {
        receiveCalled = false;
    }

    function callSupply(address qToken, uint uAmount) external payable {
        IQore(qore).supply{ value: msg.value }(qToken, uAmount);
    }

    function callRepayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable {
        IQore(qore).repayBorrowBehalf{ value: msg.value }(qToken, borrower, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IQore.sol";
import "../interfaces/IBEP20.sol";
import "hardhat/console.sol";

contract ReentrancyTesterForBorrow {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant qore = 0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48;
    address public constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;
    address public constant qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;

    /* ========== STATE VARIABLES ========== */
    bool public receiveCalled = false;

    /* ========== INITIALIZER ========== */

    constructor() public {}

    receive() external payable {
        console.log("receive called");
        receiveCalled = true;
        IQore(qore).borrow(qBNB, uint(1).mul(1e18));
        console.log("borrow called");
    }

    /* ========== FUNCTIONS ========== */

    function resetReceiveCalled() external {
        receiveCalled = false;
    }

    function callSupply(address qToken, uint uAmount) external payable {
        IQore(qore).supply{ value: msg.value }(qToken, uAmount);
    }

    function callRepayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable {
        IQore(qore).repayBorrowBehalf{ value: msg.value }(qToken, borrower, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IQore.sol";
import "../interfaces/IBEP20.sol";
import "hardhat/console.sol";

contract ReentrancyTester2 {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant qore = 0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48;
    address public constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;
    address public constant qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;

    /* ========== STATE VARIABLES ========== */
    bool public receiveCalled = false;

    /* ========== INITIALIZER ========== */

    constructor() public {}

    receive() external payable {
        console.log("receive called");
        receiveCalled = true;
        IQore(qore).borrow(qBNB, uint(1).mul(1e18));
    }

    /* ========== FUNCTIONS ========== */

    function resetReceiveCalled() external {
        receiveCalled = false;
    }

    function deposit() external payable {}

    function callLiquidateBorrow(
        address qTokenBorrowed,
        address qTokenCollateral,
        address borrower,
        uint amount
    ) external payable {
        IQore(qore).liquidateBorrow{ value: msg.value }(qTokenBorrowed, qTokenCollateral, borrower, amount);
    }

    function callSupply(address qToken, uint uAmount) external payable {
        IQore(qore).supply{ value: msg.value }(qToken, uAmount);
    }

    function callBorrow(address qToken, uint amount) external {
        IQore(qore).borrow(qToken, amount);
    }

    function callRepayBorrow(address qToken, uint amount) external payable {
        IQore(qore).repayBorrow{ value: msg.value }(qToken, amount);
    }

    function callRepayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable {
        IQore(qore).repayBorrowBehalf{ value: msg.value }(qToken, borrower, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IQore.sol";
import "../interfaces/IBEP20.sol";
import "hardhat/console.sol";

contract ReentrancyTester {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant qore = 0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48;
    address public constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;

    /* ========== STATE VARIABLES ========== */
    bool public receiveCalled = false;

    /* ========== INITIALIZER ========== */

    constructor() public {}

    receive() external payable {
        console.log("receive called");
        receiveCalled = true;
    }

    /* ========== FUNCTIONS ========== */

    function resetReceiveCalled() external {
        receiveCalled = false;
    }

    function deposit() external payable {}

    function callLiquidateBorrow(
        address qTokenBorrowed,
        address qTokenCollateral,
        address borrower,
        uint amount
    ) external payable {
        IQore(qore).liquidateBorrow{ value: msg.value }(qTokenBorrowed, qTokenCollateral, borrower, amount);
    }

    function callSupply(address qToken, uint uAmount) external payable {
        IQore(qore).supply{ value: msg.value }(qToken, uAmount);
    }

    function callBorrow(address qToken, uint amount) external {
        IQore(qore).borrow(qToken, amount);
    }

    function callRepayBorrow(address qToken, uint amount) external payable {
        IQore(qore).repayBorrow{ value: msg.value }(qToken, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IQValidator.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IQore.sol";
import "../library/QConstant.sol";

contract QValidatorTester is IQValidator, OwnableUpgradeable {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    /* ========== STATE VARIABLES ========== */

    IQore public qore;
    IPriceCalculator oracle;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== VIEWS ========== */

    function getAccountLiquidity(
        address account,
        address qToken,
        uint redeemAmount,
        uint borrowAmount
    ) external view override returns (uint liquidity, uint shortfall) {
        uint accCollateralValueInUSD;
        uint accBorrowValueInUSD;

        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accountSnapshot(account);

            uint collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(prices[i])
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            accCollateralValueInUSD = accCollateralValueInUSD.add(
                snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18)
            );
            accBorrowValueInUSD = accBorrowValueInUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));

            if (assets[i] == qToken) {
                accBorrowValueInUSD = accBorrowValueInUSD.add(redeemAmount.mul(collateralValuePerShareInUSD).div(1e18));
                accBorrowValueInUSD = accBorrowValueInUSD.add(borrowAmount.mul(prices[i]).div(1e18));
            }
        }

        liquidity = accCollateralValueInUSD > accBorrowValueInUSD
            ? accCollateralValueInUSD.sub(accBorrowValueInUSD)
            : 0;
        shortfall = accCollateralValueInUSD > accBorrowValueInUSD
            ? 0
            : accBorrowValueInUSD.sub(accCollateralValueInUSD);
    }

    function getAccountLiquidityValue(address account)
        external
        view
        override
        returns (uint collateralUSD, uint borrowUSD)
    {
        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = oracle.getUnderlyingPrices(assets);
        collateralUSD = 0;
        borrowUSD = 0;
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accountSnapshot(account);

            uint collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(prices[i])
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            collateralUSD = collateralUSD.add(snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18));
            borrowUSD = borrowUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setQore(address _qore) external onlyOwner {
        require(_qore != address(0), "QValidator: invalid qore address");
        require(address(qore) == address(0), "QValidator: qore already set");
        qore = IQore(_qore);
    }

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "QValidator: invalid oracle address");
        oracle = IPriceCalculator(_oracle);
    }

    /* ========== ALLOWED FUNCTIONS ========== */

    function redeemAllowed(
        address qToken,
        address redeemer,
        uint redeemAmount
    ) external override returns (bool) {
        (, uint shortfall) = _getAccountLiquidityInternal(redeemer, qToken, redeemAmount, 0);
        return shortfall == 0;
    }

    function borrowAllowed(
        address qToken,
        address borrower,
        uint borrowAmount
    ) external override returns (bool) {
        require(qore.checkMembership(borrower, address(qToken)), "QValidator: enterMarket required");
        require(oracle.getUnderlyingPrice(address(qToken)) > 0, "QValidator: Underlying price error");

        // Borrow cap of 0 corresponds to unlimited borrowing
        uint borrowCap = qore.marketInfoOf(qToken).borrowCap;
        if (borrowCap != 0) {
            uint totalBorrows = IQToken(payable(qToken)).accruedTotalBorrow();
            uint nextTotalBorrows = totalBorrows.add(borrowAmount);
            require(nextTotalBorrows < borrowCap, "QValidator: market borrow cap reached");
        }

        (, uint shortfall) = _getAccountLiquidityInternal(borrower, qToken, 0, borrowAmount);
        return shortfall == 0;
    }

    function liquidateAllowed(
        address qToken,
        address borrower,
        uint liquidateAmount,
        uint closeFactor
    ) external override returns (bool) {
        // The borrower must have shortfall in order to be liquidate
        (, uint shortfall) = _getAccountLiquidityInternal(borrower, address(0), 0, 0);
        require(shortfall != 0, "QValidator: Insufficient shortfall");

        // The liquidator may not repay more than what is allowed by the closeFactor
        uint borrowBalance = IQToken(payable(qToken)).accruedBorrowBalanceOf(borrower);
        uint maxClose = closeFactor.mul(borrowBalance).div(1e18);
        return liquidateAmount <= maxClose;
    }

    function qTokenAmountToSeize(
        address qTokenBorrowed,
        address qTokenCollateral,
        uint amount
    ) external override returns (uint seizeQAmount) {
        uint priceBorrowed = oracle.getUnderlyingPrice(qTokenBorrowed);
        uint priceCollateral = oracle.getUnderlyingPrice(qTokenCollateral);
        require(priceBorrowed != 0 && priceCollateral != 0, "QValidator: price error");

        uint exchangeRate = IQToken(payable(qTokenCollateral)).accruedExchangeRate();
        require(exchangeRate != 0, "QValidator: exchangeRate of qTokenCollateral is zero");

        // seizeQTokenAmount = amount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
        return amount.mul(qore.liquidationIncentive()).mul(priceBorrowed).div(priceCollateral.mul(exchangeRate));
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getAccountLiquidityInternal(
        address account,
        address qToken,
        uint redeemAmount,
        uint borrowAmount
    ) private returns (uint liquidity, uint shortfall) {
        uint accCollateralValueInUSD;
        uint accBorrowValueInUSD;

        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accruedAccountSnapshot(account);

            uint collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(prices[i])
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            accCollateralValueInUSD = accCollateralValueInUSD.add(
                snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18)
            );
            accBorrowValueInUSD = accBorrowValueInUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));

            if (assets[i] == qToken) {
                accBorrowValueInUSD = accBorrowValueInUSD.add(redeemAmount.mul(collateralValuePerShareInUSD).div(1e18));
                accBorrowValueInUSD = accBorrowValueInUSD.add(borrowAmount.mul(prices[i]).div(1e18));
            }
        }

        liquidity = accCollateralValueInUSD > accBorrowValueInUSD
            ? accCollateralValueInUSD.sub(accBorrowValueInUSD)
            : 0;
        shortfall = accCollateralValueInUSD > accBorrowValueInUSD
            ? 0
            : accBorrowValueInUSD.sub(accCollateralValueInUSD);
    }

    function getAccountLiquidityTester(
        address account,
        address qToken,
        uint redeemAmount,
        uint borrowAmount
    ) external returns (uint liquidity, uint shortfall) {
        uint accCollateralValueInUSD;
        uint accBorrowValueInUSD;

        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = getUnderlyingPricesTester(assets);
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accruedAccountSnapshot(account);

            uint collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(prices[i])
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            accCollateralValueInUSD = accCollateralValueInUSD.add(
                snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18)
            );
            accBorrowValueInUSD = accBorrowValueInUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));

            if (assets[i] == qToken) {
                accBorrowValueInUSD = accBorrowValueInUSD.add(redeemAmount.mul(collateralValuePerShareInUSD).div(1e18));
                accBorrowValueInUSD = accBorrowValueInUSD.add(borrowAmount.mul(prices[i]).div(1e18));
            }
        }

        liquidity = accCollateralValueInUSD > accBorrowValueInUSD
            ? accCollateralValueInUSD.sub(accBorrowValueInUSD)
            : 0;
        shortfall = accCollateralValueInUSD > accBorrowValueInUSD
            ? 0
            : accBorrowValueInUSD.sub(accCollateralValueInUSD);
    }

    function getUnderlyingPricesTester(address[] memory assets) public view returns (uint[] memory) {
        uint[] memory returnValue = new uint[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            IQToken qToken = IQToken(payable(assets[i]));
            address addr = qToken.underlying();
            if (addr == USDT) {
                returnValue[i] = 1e18;
            } else if (addr == BUNNY) {
                returnValue[i] = 25e18;
            } else if (addr == CAKE) {
                returnValue[i] = 20e18;
            } else if (addr == BUSD) {
                returnValue[i] = 1e18;
            } else if (addr == USDT) {
                returnValue[i] = 1e18;
            } else if (addr == BNB || addr == WBNB) {
                returnValue[i] = 400e18;
            } else {
                returnValue[i] = 0;
            }
        }
        return returnValue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

interface IQValidator {
    function redeemAllowed(
        address qToken,
        address redeemer,
        uint redeemAmount
    ) external returns (bool);

    function borrowAllowed(
        address qToken,
        address borrower,
        uint borrowAmount
    ) external returns (bool);

    function liquidateAllowed(
        address qTokenBorrowed,
        address borrower,
        uint repayAmount,
        uint closeFactor
    ) external returns (bool);

    function qTokenAmountToSeize(
        address qTokenBorrowed,
        address qTokenCollateral,
        uint actualRepayAmount
    ) external returns (uint qTokenAmount);

    function getAccountLiquidity(
        address account,
        address qToken,
        uint redeemAmount,
        uint borrowAmount
    ) external view returns (uint liquidity, uint shortfall);

    function getAccountLiquidityValue(address account) external view returns (uint collateralUSD, uint borrowUSD);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../library/QConstant.sol";
pragma experimental ABIEncoderV2;

contract SimpleQTokenTester {
    address public underlying;
    uint public qTokenBalance;
    uint public borrowBalance;
    uint public exchangeRate;
    uint public exchangeRateStored;
    uint public totalBorrow;

    constructor(address _underlying) public {
        underlying = _underlying;
        exchangeRateStored = 50000000000000000;
    }

    function getAccountSnapshot(address)
        public
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        return (qTokenBalance, borrowBalance, exchangeRate);
    }

    function setAccountSnapshot(
        uint _qTokenBalance,
        uint _borrowBalance,
        uint _exchangeRate
    ) public {
        qTokenBalance = _qTokenBalance;
        borrowBalance = _borrowBalance;
        exchangeRate = _exchangeRate;
        totalBorrow = _borrowBalance;
    }

    function borrowBalanceOf(address) public view returns (uint) {
        return borrowBalance;
    }

    function accruedAccountSnapshot(address) external view returns (QConstant.AccountSnapshot memory) {
        QConstant.AccountSnapshot memory snapshot;
        snapshot.qTokenBalance = qTokenBalance;
        snapshot.borrowBalance = borrowBalance;
        snapshot.exchangeRate = exchangeRate;
        return snapshot;
    }

    function accruedTotalBorrow() public view returns (uint) {
        return totalBorrow;
    }

    function accruedBorrowBalanceOf(address) public view returns (uint) {
        return borrowBalance;
    }

    function accruedExchangeRate() public view returns (uint) {
        return exchangeRate;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";

import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IQDistributor.sol";
import "../library/QConstant.sol";
import "../library/SafeToken.sol";
import "../markets/QMarket.sol";

contract QTokenTester is QMarket {
    using SafeMath for uint;
    using SafeToken for address;

    // for test
    function setQDistributor(address _qDistributor) external onlyOwner {
        require(_qDistributor != address(0), "QTokenTester: invalid qDistributor address");
        qDistributor = IQDistributor(_qDistributor);
    }

    /* ========== CONSTANT ========== */

    IQDistributor public qDistributor;

    /* ========== STATE VARIABLES ========== */

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => mapping(address => uint)) private _transferAllowances;

    /* ========== EVENT ========== */

    event Mint(address minter, uint mintAmount);
    event Redeem(address account, uint underlyingAmount, uint qTokenAmount);

    event Borrow(address account, uint ammount, uint accountBorrow);
    event RepayBorrow(address payer, address borrower, uint amount, uint accountBorrow);
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint amount,
        address qTokenCollateral,
        uint seizeAmount
    );

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    /* ========== INITIALIZER ========== */

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external initializer {
        __QMarket_init();

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /* ========== VIEWS ========== */

    function allowance(address account, address spender) external view override returns (uint) {
        return _transferAllowances[account][spender];
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function transfer(address dst, uint amount) external override accrue nonReentrant returns (bool) {
        _transferTokens(msg.sender, msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint amount
    ) external override accrue nonReentrant returns (bool) {
        _transferTokens(msg.sender, src, dst, amount);
        return true;
    }

    function approve(address spender, uint amount) external override returns (bool) {
        _transferAllowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function supply(address account, uint uAmount)
        external
        payable
        override
        accrue
        onlyQore
        nonReentrant
        returns (uint)
    {
        uint exchangeRate = exchangeRate();
        uAmount = underlying == address(WBNB) ? msg.value : uAmount;
        uAmount = _doTransferIn(account, uAmount);
        uint qAmount = uAmount.mul(1e18).div(exchangeRate);

        totalSupply = totalSupply.add(qAmount);
        accountBalances[account] = accountBalances[account].add(qAmount);

        emit Mint(account, qAmount);
        emit Transfer(address(this), account, qAmount);
        return qAmount;
    }

    function redeemToken(address redeemer, uint qAmount) external override accrue onlyQore nonReentrant returns (uint) {
        return _redeem(redeemer, qAmount, 0);
    }

    function redeemUnderlying(address redeemer, uint uAmount)
        external
        override
        accrue
        onlyQore
        nonReentrant
        returns (uint)
    {
        return _redeem(redeemer, 0, uAmount);
    }

    function borrow(address account, uint amount) external override accrue onlyQore nonReentrant returns (uint) {
        require(getCash() >= amount, "QToken: borrow amount exceeds cash");
        updateBorrowInfo(account, amount, 0);
        _doTransferOut(account, amount);

        emit Borrow(account, amount, borrowBalanceOf(account));
        return amount;
    }

    function repayBorrow(address account, uint amount)
        external
        payable
        override
        accrue
        onlyQore
        nonReentrant
        returns (uint)
    {
        if (amount == uint(-1)) {
            amount = borrowBalanceOf(account);
        }
        return _repay(account, account, underlying == address(WBNB) ? msg.value : amount);
    }

    function repayBorrowBehalf(
        address payer,
        address borrower,
        uint amount
    ) external payable override accrue onlyQore nonReentrant returns (uint) {
        if (amount == uint(-1)) {
            amount = borrowBalanceOf(borrower);
        }
        return _repay(payer, borrower, underlying == address(WBNB) ? msg.value : amount);
    }

    function liquidateBorrow(
        address qTokenCollateral,
        address liquidator,
        address borrower,
        uint amount
    ) external payable override accrue onlyQore nonReentrant returns (uint qAmountToSeize) {
        require(borrower != liquidator, "QToken: cannot liquidate yourself");

        amount = underlying == address(WBNB) ? msg.value : amount;
        amount = _repay(liquidator, borrower, amount);
        require(amount > 0 && amount < uint(-1), "QToken: invalid repay amount");

        qAmountToSeize = IQValidator(qore.qValidator()).qTokenAmountToSeize(address(this), qTokenCollateral, amount);
        require(
            IQToken(payable(qTokenCollateral)).balanceOf(borrower) >= qAmountToSeize,
            "QToken: too much seize amount"
        );
        emit LiquidateBorrow(liquidator, borrower, amount, qTokenCollateral, qAmountToSeize);
    }

    function seize(
        address liquidator,
        address borrower,
        uint qAmount
    ) external override accrue onlyQore nonReentrant {
        accountBalances[borrower] = accountBalances[borrower].sub(qAmount);
        accountBalances[liquidator] = accountBalances[liquidator].add(qAmount);
        qDistributor.notifyTransferred(address(this), borrower, liquidator);
        emit Transfer(borrower, liquidator, qAmount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _transferTokens(
        address spender,
        address src,
        address dst,
        uint amount
    ) private {
        require(
            src != dst && IQValidator(qore.qValidator()).redeemAllowed(address(this), src, amount),
            "QToken: cannot transfer"
        );
        require(amount != 0, "QToken: zero amount");

        uint _allowance = spender == src ? uint(-1) : _transferAllowances[src][spender];
        uint _allowanceNew = _allowance.sub(amount, "QToken: transfer amount exceeds allowance");

        accountBalances[src] = accountBalances[src].sub(amount);
        accountBalances[dst] = accountBalances[dst].add(amount);

        qDistributor.notifyTransferred(address(this), src, dst);

        if (_allowance != uint(-1)) {
            _transferAllowances[src][msg.sender] = _allowanceNew;
        }
        emit Transfer(src, dst, amount);
    }

    function _doTransferIn(address from, uint amount) private returns (uint) {
        if (underlying == address(WBNB)) {
            require(msg.value >= amount, "QToken: value mismatch");
            return Math.min(msg.value, amount);
        } else {
            uint balanceBefore = IBEP20(underlying).balanceOf(address(this));
            underlying.safeTransferFrom(from, address(this), amount);
            return IBEP20(underlying).balanceOf(address(this)).sub(balanceBefore);
        }
    }

    function _doTransferOut(address to, uint amount) private {
        if (underlying == address(WBNB)) {
            SafeToken.safeTransferETH(to, amount);
        } else {
            underlying.safeTransfer(to, amount);
        }
    }

    function _redeem(
        address account,
        uint qAmountIn,
        uint uAmountIn
    ) private returns (uint) {
        require(qAmountIn == 0 || uAmountIn == 0, "QToken: one of qAmountIn or uAmountIn must be zero");
        require(totalSupply >= qAmountIn, "QToken: not enough total supply");
        require(getCash() >= uAmountIn || uAmountIn == 0, "QToken: not enough underlying");
        require(
            getCash() >= qAmountIn.mul(exchangeRate()).div(1e18) || qAmountIn == 0,
            "QToken: not enough underlying"
        );

        uint qAmountToRedeem = qAmountIn > 0 ? qAmountIn : uAmountIn.mul(1e18).div(exchangeRate());
        uint uAmountToRedeem = qAmountIn > 0 ? qAmountIn.mul(exchangeRate()).div(1e18) : uAmountIn;

        require(
            IQValidator(qore.qValidator()).redeemAllowed(address(this), account, qAmountToRedeem),
            "QToken: cannot redeem"
        );

        totalSupply = totalSupply.sub(qAmountToRedeem);
        accountBalances[account] = accountBalances[account].sub(qAmountToRedeem);
        _doTransferOut(account, uAmountToRedeem);

        emit Transfer(account, address(this), qAmountToRedeem);
        emit Redeem(account, uAmountToRedeem, qAmountToRedeem);
        return uAmountToRedeem;
    }

    function _repay(
        address payer,
        address borrower,
        uint amount
    ) private returns (uint) {
        uint borrowBalance = borrowBalanceOf(borrower);
        uint repayAmount = Math.min(borrowBalance, amount);
        repayAmount = _doTransferIn(payer, repayAmount);
        updateBorrowInfo(borrower, 0, repayAmount);

        if (underlying == address(WBNB)) {
            uint refundAmount = amount > repayAmount ? amount.sub(repayAmount) : 0;
            if (refundAmount > 0) {
                _doTransferOut(payer, refundAmount);
            }
        }

        emit RepayBorrow(payer, borrower, repayAmount, borrowBalanceOf(borrower));
        return repayAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

interface IQDistributor {
    struct UserInfo {
        uint accruedQubit;
        uint boostedSupply; // effective(boosted) supply balance of user  (since last_action)
        uint boostedBorrow; // effective(boosted) borrow balance of user  (since last_action)
        uint accPerShareSupply; // Last integral value of Qubit rewards per share. ∫(qubitRate(t) / totalShare(t) dt) from 0 till (last_action)
        uint accPerShareBorrow; // Last integral value of Qubit rewards per share. ∫(qubitRate(t) / totalShare(t) dt) from 0 till (last_action)
    }

    struct DistributionInfo {
        uint supplyRate;
        uint borrowRate;
        uint totalBoostedSupply;
        uint totalBoostedBorrow;
        uint accPerShareSupply;
        uint accPerShareBorrow;
        uint accruedAt;
    }

    function accruedQubit(address market, address user) external view returns (uint);

    function qubitRatesOf(address market) external view returns (uint supplyRate, uint borrowRate);

    function totalBoosted(address market) external view returns (uint boostedSupply, uint boostedBorrow);

    function boostedBalanceOf(address market, address account)
        external
        view
        returns (uint boostedSupply, uint boostedBorrow);

    function notifySupplyUpdated(address market, address user) external;

    function notifyBorrowUpdated(address market, address user) external;

    function notifyTransferred(
        address qToken,
        address sender,
        address receiver
    ) external;

    function claimQubit(address user) external;

    function kick(address user) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(
        address token,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(
        address token,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";

import "../interfaces/IQValidator.sol";
import "../interfaces/IRateModel.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IQore.sol";
import "../library/QConstant.sol";

abstract contract QMarket is IQToken, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    uint internal constant RESERVE_FACTOR_MAX = 1e18;
    uint internal constant DUST = 1000;

    address internal constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address internal constant BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;

    /* ========== STATE VARIABLES ========== */

    IQore public qore;
    IRateModel public rateModel;
    address public override underlying;

    uint public override totalSupply;
    uint public override totalReserve;
    uint private _totalBorrow;

    mapping(address => uint) internal accountBalances;
    mapping(address => QConstant.BorrowInfo) internal accountBorrows;

    uint public override reserveFactor;
    uint private lastAccruedTime;
    uint private accInterestIndex;

    /* ========== Event ========== */

    event RateModelUpdated(address newRateModel);
    event ReserveFactorUpdated(uint newReserveFactor);

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function __QMarket_init() internal initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        lastAccruedTime = block.timestamp;
        accInterestIndex = 1e18;
    }

    /* ========== MODIFIERS ========== */

    modifier accrue() {
        if (block.timestamp > lastAccruedTime && address(rateModel) != address(0)) {
            uint borrowRate = rateModel.getBorrowRate(getCashPrior(), _totalBorrow, totalReserve);
            uint interestFactor = borrowRate.mul(block.timestamp.sub(lastAccruedTime));
            uint pendingInterest = _totalBorrow.mul(interestFactor).div(1e18);

            _totalBorrow = _totalBorrow.add(pendingInterest);
            totalReserve = totalReserve.add(pendingInterest.mul(reserveFactor).div(1e18));
            accInterestIndex = accInterestIndex.add(interestFactor.mul(accInterestIndex).div(1e18));
            lastAccruedTime = block.timestamp;
        }
        _;
    }

    modifier onlyQore() {
        require(msg.sender == address(qore), "QToken: only Qore Contract");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setQore(address _qore) public onlyOwner {
        require(_qore != address(0), "QMarket: invalid qore address");
        require(address(qore) == address(0), "QMarket: qore already set");
        qore = IQore(_qore);
    }

    function setUnderlying(address _underlying) public onlyOwner {
        require(_underlying != address(0), "QMarket: invalid underlying address");
        require(underlying == address(0), "QMarket: set underlying already");
        underlying = _underlying;
    }

    function setRateModel(address _rateModel) public accrue onlyOwner {
        require(_rateModel != address(0), "QMarket: invalid rate model address");
        rateModel = IRateModel(_rateModel);
        emit RateModelUpdated(_rateModel);
    }

    function setReserveFactor(uint _reserveFactor) public accrue onlyOwner {
        require(_reserveFactor <= RESERVE_FACTOR_MAX, "QMarket: invalid reserve factor");
        reserveFactor = _reserveFactor;
        emit ReserveFactorUpdated(_reserveFactor);
    }

    /* ========== VIEWS ========== */

    function balanceOf(address account) external view override returns (uint) {
        return accountBalances[account];
    }

    function accountSnapshot(address account) external view override returns (QConstant.AccountSnapshot memory) {
        QConstant.AccountSnapshot memory snapshot;
        snapshot.qTokenBalance = accountBalances[account];
        snapshot.borrowBalance = borrowBalanceOf(account);
        snapshot.exchangeRate = exchangeRate();
        return snapshot;
    }

    function underlyingBalanceOf(address account) external view override returns (uint) {
        return accountBalances[account].mul(exchangeRate()).div(1e18);
    }

    function borrowBalanceOf(address account) public view override returns (uint) {
        QConstant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        QConstant.BorrowInfo storage info = accountBorrows[account];

        if (info.borrow == 0) return 0;
        return info.borrow.mul(snapshot.accInterestIndex).div(info.interestIndex);
    }

    function borrowRatePerSec() external view override returns (uint) {
        QConstant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return rateModel.getBorrowRate(getCashPrior(), snapshot.totalBorrow, snapshot.totalReserve);
    }

    function supplyRatePerSec() external view override returns (uint) {
        QConstant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return rateModel.getSupplyRate(getCashPrior(), snapshot.totalBorrow, snapshot.totalReserve, reserveFactor);
    }

    function totalBorrow() public view override returns (uint) {
        QConstant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return snapshot.totalBorrow;
    }

    function exchangeRate() public view override returns (uint) {
        if (totalSupply == 0) return 1e18;
        QConstant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return getCashPrior().add(snapshot.totalBorrow).sub(snapshot.totalReserve).mul(1e18).div(totalSupply);
    }

    function getCash() public view override returns (uint) {
        return getCashPrior();
    }

    function getAccInterestIndex() public view override returns (uint) {
        QConstant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return snapshot.accInterestIndex;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function accruedAccountSnapshot(address account)
        external
        override
        accrue
        returns (QConstant.AccountSnapshot memory)
    {
        QConstant.AccountSnapshot memory snapshot;
        QConstant.BorrowInfo storage info = accountBorrows[account];
        if (info.interestIndex != 0) {
            info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex);
            info.interestIndex = accInterestIndex;
        }

        snapshot.qTokenBalance = accountBalances[account];
        snapshot.borrowBalance = info.borrow;
        snapshot.exchangeRate = exchangeRate();
        return snapshot;
    }

    function accruedUnderlyingBalanceOf(address account) external override accrue returns (uint) {
        return accountBalances[account].mul(exchangeRate()).div(1e18);
    }

    function accruedBorrowBalanceOf(address account) external override accrue returns (uint) {
        QConstant.BorrowInfo storage info = accountBorrows[account];
        if (info.interestIndex != 0) {
            info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex);
            info.interestIndex = accInterestIndex;
        }
        return info.borrow;
    }

    function accruedTotalBorrow() external override accrue returns (uint) {
        return _totalBorrow;
    }

    function accruedExchangeRate() external override accrue returns (uint) {
        return exchangeRate();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function updateBorrowInfo(
        address account,
        uint addAmount,
        uint subAmount
    ) internal {
        QConstant.BorrowInfo storage info = accountBorrows[account];
        if (info.interestIndex == 0) {
            info.interestIndex = accInterestIndex;
        }

        info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex).add(addAmount).sub(subAmount);
        info.interestIndex = accInterestIndex;
        _totalBorrow = _totalBorrow.add(addAmount).sub(subAmount);

        info.borrow = (info.borrow < DUST) ? 0 : info.borrow;
        _totalBorrow = (_totalBorrow < DUST) ? 0 : _totalBorrow;
    }

    function updateSupplyInfo(
        address account,
        uint addAmount,
        uint subAmount
    ) internal {
        accountBalances[account] = accountBalances[account].add(addAmount).sub(subAmount);
        totalSupply = totalSupply.add(addAmount).sub(subAmount);

        totalSupply = (totalSupply < DUST) ? 0 : totalSupply;
    }

    function getCashPrior() internal view returns (uint) {
        return
            underlying == address(WBNB)
                ? address(this).balance.sub(msg.value)
                : IBEP20(underlying).balanceOf(address(this));
    }

    function pendingAccrueSnapshot() internal view returns (QConstant.AccrueSnapshot memory) {
        QConstant.AccrueSnapshot memory snapshot;
        snapshot.totalBorrow = _totalBorrow;
        snapshot.totalReserve = totalReserve;
        snapshot.accInterestIndex = accInterestIndex;

        if (block.timestamp > lastAccruedTime && _totalBorrow > 0) {
            uint borrowRate = rateModel.getBorrowRate(getCashPrior(), _totalBorrow, totalReserve);
            uint interestFactor = borrowRate.mul(block.timestamp.sub(lastAccruedTime));
            uint pendingInterest = _totalBorrow.mul(interestFactor).div(1e18);

            snapshot.totalBorrow = _totalBorrow.add(pendingInterest);
            snapshot.totalReserve = totalReserve.add(pendingInterest.mul(reserveFactor).div(1e18));
            snapshot.accInterestIndex = accInterestIndex.add(interestFactor.mul(accInterestIndex).div(1e18));
        }
        return snapshot;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

interface IRateModel {
    function getBorrowRate(
        uint cash,
        uint borrows,
        uint reserves
    ) external view returns (uint);

    function getSupplyRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint reserveFactor
    ) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";

import "../interfaces/IQDistributor.sol";
import "../library/SafeToken.sol";
import "./QMarket.sol";

contract QToken is QMarket {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT ========== */

    IQDistributor public constant qDistributor = IQDistributor(0xA2897BEDE359e56F67D06F42C39869719E59bEcc);

    /* ========== STATE VARIABLES ========== */

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => mapping(address => uint)) private _transferAllowances;

    /* ========== EVENT ========== */

    event Mint(address minter, uint mintAmount);
    event Redeem(address account, uint underlyingAmount, uint qTokenAmount);

    event Borrow(address account, uint ammount, uint accountBorrow);
    event RepayBorrow(address payer, address borrower, uint amount, uint accountBorrow);
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint amount,
        address qTokenCollateral,
        uint seizeAmount
    );

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    /* ========== INITIALIZER ========== */

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external initializer {
        __QMarket_init();

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /* ========== VIEWS ========== */

    function allowance(address account, address spender) external view override returns (uint) {
        return _transferAllowances[account][spender];
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function transfer(address dst, uint amount) external override accrue nonReentrant returns (bool) {
        _transferTokens(msg.sender, msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint amount
    ) external override accrue nonReentrant returns (bool) {
        _transferTokens(msg.sender, src, dst, amount);
        return true;
    }

    function approve(address spender, uint amount) external override returns (bool) {
        _transferAllowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function supply(address account, uint uAmount) external payable override accrue onlyQore returns (uint) {
        uint exchangeRate = exchangeRate();
        uAmount = underlying == address(WBNB) ? msg.value : uAmount;
        uAmount = _doTransferIn(account, uAmount);
        uint qAmount = uAmount.mul(1e18).div(exchangeRate);

        totalSupply = totalSupply.add(qAmount);
        accountBalances[account] = accountBalances[account].add(qAmount);

        emit Mint(account, qAmount);
        emit Transfer(address(0), account, qAmount);
        return qAmount;
    }

    function redeemToken(address redeemer, uint qAmount) external override accrue onlyQore returns (uint) {
        return _redeem(redeemer, qAmount, 0);
    }

    function redeemUnderlying(address redeemer, uint uAmount) external override accrue onlyQore returns (uint) {
        return _redeem(redeemer, 0, uAmount);
    }

    function borrow(address account, uint amount) external override accrue onlyQore returns (uint) {
        require(getCash() >= amount, "QToken: borrow amount exceeds cash");
        updateBorrowInfo(account, amount, 0);
        _doTransferOut(account, amount);

        emit Borrow(account, amount, borrowBalanceOf(account));
        return amount;
    }

    function repayBorrow(address account, uint amount) external payable override accrue onlyQore returns (uint) {
        if (amount == uint(-1)) {
            amount = borrowBalanceOf(account);
        }
        return _repay(account, account, underlying == address(WBNB) ? msg.value : amount);
    }

    function repayBorrowBehalf(
        address payer,
        address borrower,
        uint amount
    ) external payable override accrue onlyQore returns (uint) {
        return _repay(payer, borrower, underlying == address(WBNB) ? msg.value : amount);
    }

    function liquidateBorrow(
        address qTokenCollateral,
        address liquidator,
        address borrower,
        uint amount
    ) external payable override accrue onlyQore returns (uint qAmountToSeize) {
        require(borrower != liquidator, "QToken: cannot liquidate yourself");

        amount = underlying == address(WBNB) ? msg.value : amount;
        amount = _repay(liquidator, borrower, amount);
        require(amount > 0 && amount < uint(-1), "QToken: invalid repay amount");

        qAmountToSeize = IQValidator(qore.qValidator()).qTokenAmountToSeize(address(this), qTokenCollateral, amount);
        require(
            IQToken(payable(qTokenCollateral)).balanceOf(borrower) >= qAmountToSeize,
            "QToken: too much seize amount"
        );
        emit LiquidateBorrow(liquidator, borrower, amount, qTokenCollateral, qAmountToSeize);
    }

    function seize(
        address liquidator,
        address borrower,
        uint qAmount
    ) external override accrue onlyQore {
        accountBalances[borrower] = accountBalances[borrower].sub(qAmount);
        accountBalances[liquidator] = accountBalances[liquidator].add(qAmount);
        qDistributor.notifyTransferred(address(this), borrower, liquidator);
        emit Transfer(borrower, liquidator, qAmount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _transferTokens(
        address spender,
        address src,
        address dst,
        uint amount
    ) private {
        require(
            src != dst && IQValidator(qore.qValidator()).redeemAllowed(address(this), src, amount),
            "QToken: cannot transfer"
        );
        require(amount != 0, "QToken: zero amount");

        uint _allowance = spender == src ? uint(-1) : _transferAllowances[src][spender];
        uint _allowanceNew = _allowance.sub(amount, "QToken: transfer amount exceeds allowance");

        accountBalances[src] = accountBalances[src].sub(amount);
        accountBalances[dst] = accountBalances[dst].add(amount);

        qDistributor.notifyTransferred(address(this), src, dst);

        if (_allowance != uint(-1)) {
            _transferAllowances[src][msg.sender] = _allowanceNew;
        }
        emit Transfer(src, dst, amount);
    }

    function _doTransferIn(address from, uint amount) private returns (uint) {
        if (underlying == address(WBNB)) {
            require(msg.value >= amount, "QToken: value mismatch");
            return Math.min(msg.value, amount);
        } else {
            uint balanceBefore = IBEP20(underlying).balanceOf(address(this));
            underlying.safeTransferFrom(from, address(this), amount);
            return IBEP20(underlying).balanceOf(address(this)).sub(balanceBefore);
        }
    }

    function _doTransferOut(address to, uint amount) private {
        if (underlying == address(WBNB)) {
            SafeToken.safeTransferETH(to, amount);
        } else {
            underlying.safeTransfer(to, amount);
        }
    }

    function _redeem(
        address account,
        uint qAmountIn,
        uint uAmountIn
    ) private returns (uint) {
        require(qAmountIn == 0 || uAmountIn == 0, "QToken: one of qAmountIn or uAmountIn must be zero");
        require(totalSupply >= qAmountIn, "QToken: not enough total supply");
        require(getCash() >= uAmountIn || uAmountIn == 0, "QToken: not enough underlying");
        require(
            getCash() >= qAmountIn.mul(exchangeRate()).div(1e18) || qAmountIn == 0,
            "QToken: not enough underlying"
        );

        uint qAmountToRedeem = qAmountIn > 0 ? qAmountIn : uAmountIn.mul(1e18).div(exchangeRate());
        uint uAmountToRedeem = qAmountIn > 0 ? qAmountIn.mul(exchangeRate()).div(1e18) : uAmountIn;

        require(
            IQValidator(qore.qValidator()).redeemAllowed(address(this), account, qAmountToRedeem),
            "QToken: cannot redeem"
        );

        totalSupply = totalSupply.sub(qAmountToRedeem);
        accountBalances[account] = accountBalances[account].sub(qAmountToRedeem);
        _doTransferOut(account, uAmountToRedeem);

        emit Transfer(account, address(0), qAmountToRedeem);
        emit Redeem(account, uAmountToRedeem, qAmountToRedeem);
        return uAmountToRedeem;
    }

    function _repay(
        address payer,
        address borrower,
        uint amount
    ) private returns (uint) {
        uint borrowBalance = borrowBalanceOf(borrower);
        uint repayAmount = Math.min(borrowBalance, amount);
        repayAmount = _doTransferIn(payer, repayAmount);
        updateBorrowInfo(borrower, 0, repayAmount);

        if (underlying == address(WBNB)) {
            uint refundAmount = amount > repayAmount ? amount.sub(repayAmount) : 0;
            if (refundAmount > 0) {
                _doTransferOut(payer, refundAmount);
            }
        }

        emit RepayBorrow(payer, borrower, repayAmount, borrowBalanceOf(borrower));
        return repayAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IQDistributor.sol";
import "../interfaces/IQore.sol";
import "../interfaces/IQubitLocker.sol";
import "../library/WhitelistUpgradeable.sol";
import "hardhat/console.sol";

import "../markets/QToken.sol";

contract QDistributorTester is IQDistributor, WhitelistUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ======= TEST FUNCTIONS ====== */
    function setEffectiveSupply(
        address market,
        address user,
        uint effectiveSupply
    ) public {
        marketUsers[market][user].boostedSupply = effectiveSupply;
    }

    /* ========== CONSTANT VARIABLES ========== */

    address private constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;

    uint public constant BOOST_PORTION_Q = 60;
    uint public constant BOOST_PORTION_MAX = 100;

    address private constant QORE = 0x21824518e7E443812586c96aB5B05E9F91831E06;

    /* ========== STATE VARIABLES ========== */

    mapping(address => DistributionInfo) distributions;
    mapping(address => mapping(address => UserInfo)) marketUsers;

    IQubitLocker public qubitLocker;
    IQore public qore;

    /* ========== MODIFIERS ========== */

    modifier updateDistributionOf(address market) {
        DistributionInfo storage dist = distributions[market];
        if (dist.accruedAt == 0) {
            dist.accruedAt = block.timestamp;
        }

        uint timeElapsed = block.timestamp > dist.accruedAt ? block.timestamp.sub(dist.accruedAt) : 0;
        if (timeElapsed > 0) {
            if (dist.totalBoostedSupply > 0) {
                dist.accPerShareSupply = dist.accPerShareSupply.add(
                    dist.supplyRate.mul(timeElapsed).mul(1e18).div(dist.totalBoostedSupply)
                );
            }

            if (dist.totalBoostedBorrow > 0) {
                dist.accPerShareBorrow = dist.accPerShareBorrow.add(
                    dist.borrowRate.mul(timeElapsed).mul(1e18).div(dist.totalBoostedBorrow)
                );
            }
        }
        dist.accruedAt = block.timestamp;
        _;
    }

    modifier onlyQore() {
        require(msg.sender == address(qore), "QDistributor: caller is not Qore");
        _;
    }

    modifier onlyMarket() {
        bool fromMarket = false;
        address[] memory markets = qore.allMarkets();
        for (uint i = 0; i < markets.length; i++) {
            if (msg.sender == markets[i]) {
                fromMarket = true;
            }
        }
        require(fromMarket == true, "QDistributor: caller should be market");
        _;
    }

    /* ========== EVENTS ========== */

    event QubitDistributionRateUpdated(address indexed qToken, uint supplyRate, uint borrowRate);
    event QubitClaimed(address indexed user, uint amount);

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();
        qore = IQore(QORE);
    }

    /* ========== VIEWS ========== */

    function userInfoOf(address market, address user) external view returns (UserInfo memory) {
        return marketUsers[market][user];
    }

    function accruedQubit(address market, address user) external view override returns (uint) {
        DistributionInfo storage dist = distributions[market];
        UserInfo storage userInfo = marketUsers[market][user];

        uint _accruedQubit = userInfo.accruedQubit;
        uint accPerShareSupply = dist.accPerShareSupply;
        uint accPerShareBorrow = dist.accPerShareBorrow;

        uint timeElapsed = block.timestamp > dist.accruedAt ? block.timestamp.sub(dist.accruedAt) : 0;
        if (timeElapsed > 0) {
            if (dist.totalBoostedSupply > 0) {
                accPerShareSupply = accPerShareSupply.add(
                    dist.supplyRate.mul(timeElapsed).mul(1e18).div(dist.totalBoostedSupply)
                );

                uint pendingQubit = userInfo.boostedSupply.mul(accPerShareSupply.sub(userInfo.accPerShareSupply)).div(
                    1e18
                );
                _accruedQubit = _accruedQubit.add(pendingQubit);
            }

            if (dist.totalBoostedBorrow > 0) {
                accPerShareBorrow = accPerShareBorrow.add(
                    dist.borrowRate.mul(timeElapsed).mul(1e18).div(dist.totalBoostedBorrow)
                );

                uint pendingQubit = userInfo.boostedBorrow.mul(accPerShareBorrow.sub(userInfo.accPerShareBorrow)).div(
                    1e18
                );
                _accruedQubit = _accruedQubit.add(pendingQubit);
            }
        }
        return _accruedQubit;
    }

    function qubitRatesOf(address market) external view override returns (uint supplyRate, uint borrowRate) {
        return (distributions[market].supplyRate, distributions[market].borrowRate);
    }

    function totalBoosted(address market) external view override returns (uint boostedSupply, uint boostedBorrow) {
        return (distributions[market].totalBoostedSupply, distributions[market].totalBoostedBorrow);
    }

    function boostedBalanceOf(address market, address account)
        external
        view
        override
        returns (uint boostedSupply, uint boostedBorrow)
    {
        return (marketUsers[market][account].boostedSupply, marketUsers[market][account].boostedBorrow);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setQubitLocker(address _locker) external onlyOwner {
        require(address(_locker) != address(0), "QDistributor: invalid locker");
        qubitLocker = IQubitLocker(_locker);
    }

    function setQore(address _qore) external onlyOwner {
        require(address(_qore) != address(0), "QDistributor: invalid qore");
        require(address(qore) == address(0), "QValidator: qore already set");
        qore = IQore(_qore);
    }

    function setQubitDistributionRates(
        address qToken,
        uint supplyRate,
        uint borrowRate
    ) external onlyOwner updateDistributionOf(qToken) {
        DistributionInfo storage dist = distributions[qToken];
        dist.supplyRate = supplyRate;
        dist.borrowRate = borrowRate;
        emit QubitDistributionRateUpdated(qToken, supplyRate, borrowRate);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function notifySupplyUpdated(address market, address user)
        external
        override
        nonReentrant
        onlyQore
        updateDistributionOf(market)
    {
        DistributionInfo storage dist = distributions[market];
        UserInfo storage userInfo = marketUsers[market][user];

        if (userInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(userInfo.accPerShareSupply);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedSupply).div(1e18));
        }
        userInfo.accPerShareSupply = dist.accPerShareSupply;

        uint boostedSupply = _calculateBoostedSupply(market, user);
        dist.totalBoostedSupply = dist.totalBoostedSupply.add(boostedSupply).sub(userInfo.boostedSupply);
        userInfo.boostedSupply = boostedSupply;
    }

    function notifyBorrowUpdated(address market, address user)
        external
        override
        nonReentrant
        onlyQore
        updateDistributionOf(market)
    {
        DistributionInfo storage dist = distributions[market];
        UserInfo storage userInfo = marketUsers[market][user];

        if (userInfo.boostedBorrow > 0) {
            uint accQubitPerShare = dist.accPerShareBorrow.sub(userInfo.accPerShareBorrow);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedBorrow).div(1e18));
        }
        userInfo.accPerShareBorrow = dist.accPerShareBorrow;

        uint boostedBorrow = _calculateBoostedBorrow(market, user);
        dist.totalBoostedBorrow = dist.totalBoostedBorrow.add(boostedBorrow).sub(userInfo.boostedBorrow);
        userInfo.boostedBorrow = boostedBorrow;
    }

    function notifyTransferred(
        address qToken,
        address sender,
        address receiver
    ) external override nonReentrant onlyMarket updateDistributionOf(qToken) {
        DistributionInfo storage dist = distributions[qToken];
        UserInfo storage senderInfo = marketUsers[qToken][sender];
        UserInfo storage receiverInfo = marketUsers[qToken][receiver];

        if (senderInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(senderInfo.accPerShareSupply);
            senderInfo.accruedQubit = senderInfo.accruedQubit.add(
                accQubitPerShare.mul(senderInfo.boostedSupply).div(1e18)
            );
        }
        senderInfo.accPerShareSupply = dist.accPerShareSupply;

        if (receiverInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(receiverInfo.accPerShareSupply);
            receiverInfo.accruedQubit = receiverInfo.accruedQubit.add(
                accQubitPerShare.mul(receiverInfo.boostedSupply).div(1e18)
            );
        }
        receiverInfo.accPerShareSupply = dist.accPerShareSupply;

        uint boostedSenderSupply = _calculateBoostedSupply(qToken, sender);
        uint boostedReceiverSupply = _calculateBoostedSupply(qToken, receiver);
        dist.totalBoostedSupply = dist
            .totalBoostedSupply
            .add(boostedSenderSupply)
            .add(boostedReceiverSupply)
            .sub(senderInfo.boostedSupply)
            .sub(receiverInfo.boostedSupply);
        senderInfo.boostedSupply = boostedSenderSupply;
        receiverInfo.boostedSupply = boostedReceiverSupply;
    }

    function claimQubit(address user) external override nonReentrant {
        require(msg.sender == user, "QDistributor: invalid user");
        uint _accruedQubit = 0;

        address[] memory markets = qore.allMarkets();
        for (uint i = 0; i < markets.length; i++) {
            address market = markets[i];
            _accruedQubit = _accruedQubit.add(_claimQubit(market, user));
        }

        _transferQubit(user, _accruedQubit);
    }

    function claimQubit(address market, address user) external nonReentrant {
        require(msg.sender == user, "QDistributor: invalid user");

        uint _accruedQubit = _claimQubit(market, user);
        _transferQubit(user, _accruedQubit);
    }

    function kick(address user) external override nonReentrant {
        require(qubitLocker.scoreOf(user) == 0, "QDistributor: kick not allowed");

        address[] memory markets = qore.allMarkets();
        for (uint i = 0; i < markets.length; i++) {
            address market = markets[i];
            _updateSupplyOf(market, user);
            _updateBorrowOf(market, user);
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _claimQubit(address market, address user) private returns (uint _accruedQubit) {
        bool hasBoostedSupply = marketUsers[market][user].boostedSupply > 0;
        bool hasBoostedBorrow = marketUsers[market][user].boostedBorrow > 0;
        if (hasBoostedSupply) _updateSupplyOf(market, user);
        if (hasBoostedBorrow) _updateBorrowOf(market, user);

        if (hasBoostedSupply || hasBoostedBorrow) {
            UserInfo storage userInfo = marketUsers[market][user];
            _accruedQubit = _accruedQubit.add(userInfo.accruedQubit);
            userInfo.accruedQubit = 0;
        }

        return _accruedQubit;
    }

    function _transferQubit(address user, uint amount) private {
        amount = Math.min(amount, IBEP20(QBT).balanceOf(address(this)));
        QBT.safeTransfer(user, amount);
        emit QubitClaimed(user, amount);
    }

    function _calculateBoostedSupply(address market, address user) private view returns (uint) {
        uint defaultSupply = IQToken(market).balanceOf(user);
        uint boostedSupply = defaultSupply.mul(BOOST_PORTION_MAX - BOOST_PORTION_Q).div(BOOST_PORTION_MAX);

        uint userScore = qubitLocker.scoreOf(user);
        (uint totalScore, ) = qubitLocker.totalScore();
        if (userScore > 0 && totalScore > 0) {
            uint scoreBoosted = IQToken(market).totalSupply().mul(userScore).div(totalScore).mul(BOOST_PORTION_Q).div(
                100
            );
            boostedSupply = boostedSupply.add(scoreBoosted);
        }
        return Math.min(boostedSupply, defaultSupply);
    }

    function _calculateBoostedBorrow(address market, address user) private view returns (uint) {
        uint accInterestIndex = IQToken(market).getAccInterestIndex();
        uint defaultBorrow = IQToken(market).borrowBalanceOf(user).mul(1e18).div(accInterestIndex);
        uint boostedBorrow = defaultBorrow.mul(BOOST_PORTION_MAX - BOOST_PORTION_Q).div(BOOST_PORTION_MAX);

        uint userScore = qubitLocker.scoreOf(user);
        (uint totalScore, ) = qubitLocker.totalScore();
        if (userScore > 0 && totalScore > 0) {
            uint totalBorrow = IQToken(market).totalBorrow().mul(1e18).div(accInterestIndex);
            uint scoreBoosted = totalBorrow.mul(userScore).div(totalScore).mul(BOOST_PORTION_Q).div(100);
            boostedBorrow = boostedBorrow.add(scoreBoosted);
        }
        return Math.min(boostedBorrow, defaultBorrow);
    }

    function _updateSupplyOf(address market, address user) private updateDistributionOf(market) {
        DistributionInfo storage dist = distributions[market];
        UserInfo storage userInfo = marketUsers[market][user];

        if (userInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(userInfo.accPerShareSupply);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedSupply).div(1e18));
        }
        userInfo.accPerShareSupply = dist.accPerShareSupply;

        uint boostedSupply = _calculateBoostedSupply(market, user);
        dist.totalBoostedSupply = dist.totalBoostedSupply.add(boostedSupply).sub(userInfo.boostedSupply);
        userInfo.boostedSupply = boostedSupply;
    }

    function _updateBorrowOf(address market, address user) private updateDistributionOf(market) {
        DistributionInfo storage dist = distributions[market];
        UserInfo storage userInfo = marketUsers[market][user];

        if (userInfo.boostedBorrow > 0) {
            uint accQubitPerShare = dist.accPerShareBorrow.sub(userInfo.accPerShareBorrow);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedBorrow).div(1e18));
        }
        userInfo.accPerShareBorrow = dist.accPerShareBorrow;

        uint boostedBorrow = _calculateBoostedBorrow(market, user);
        dist.totalBoostedBorrow = dist.totalBoostedBorrow.add(boostedBorrow).sub(userInfo.boostedBorrow);
        userInfo.boostedBorrow = boostedBorrow;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

interface IQubitLocker {
    struct CheckPoint {
        uint totalWeightedBalance;
        uint slope;
        uint ts;
    }

    function totalBalance() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function expiryOf(address account) external view returns (uint);

    function availableOf(address account) external view returns (uint);

    function balanceExpiryOf(address account) external view returns (uint balance, uint expiry);

    function totalScore() external view returns (uint score, uint slope);

    function scoreOf(address account) external view returns (uint);

    function deposit(uint amount, uint unlockTime) external;

    function extendLock(uint expiryTime) external;

    function withdraw() external;

    function depositBehalf(
        address account,
        uint amount,
        uint unlockTime
    ) external;

    function withdrawBehalf(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract WhitelistUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private _whitelist;
    bool private _disable; // default - false means whitelist feature is working on. if true no more use of whitelist

    event Whitelisted(address indexed _address, bool whitelist);
    event EnableWhitelist();
    event DisableWhitelist();

    modifier onlyWhitelisted() {
        require(_disable || _whitelist[msg.sender], "Whitelist: caller is not on the whitelist");
        _;
    }

    function __WhitelistUpgradeable_init() internal initializer {
        __Ownable_init();
    }

    function isWhitelist(address _address) public view returns (bool) {
        return _whitelist[_address];
    }

    function setWhitelist(address _address, bool _on) external onlyOwner {
        _whitelist[_address] = _on;

        emit Whitelisted(_address, _on);
    }

    function disableWhitelist(bool disable) external onlyOwner {
        _disable = disable;
        if (disable) {
            emit DisableWhitelist();
        } else {
            emit EnableWhitelist();
        }
    }

    uint[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IQubitLocker.sol";
import "../library/WhitelistUpgradeable.sol";
import "../library/SafeToken.sol";

contract QubitLocker is IQubitLocker, WhitelistUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    address public constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;

    uint public constant LOCK_UNIT_BASE = 7 days;
    uint public constant LOCK_UNIT_MAX = 2 * 365 days;

    /* ========== STATE VARIABLES ========== */

    mapping(address => uint) public balances;
    mapping(address => uint) public expires;

    uint public override totalBalance;

    uint private _lastTotalScore;
    uint private _lastSlope;
    uint private _lastTimestamp;
    mapping(uint => uint) private _slopeChanges;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();
        _lastTimestamp = block.timestamp;
    }

    /* ========== VIEWS ========== */

    function balanceOf(address account) external view override returns (uint) {
        return balances[account];
    }

    function expiryOf(address account) external view override returns (uint) {
        return expires[account];
    }

    function availableOf(address account) external view override returns (uint) {
        return expires[account] < block.timestamp ? balances[account] : 0;
    }

    function balanceExpiryOf(address account) external view override returns (uint balance, uint expiry) {
        return (balances[account], expires[account]);
    }

    function totalScore() public view override returns (uint score, uint slope) {
        score = _lastTotalScore;
        slope = _lastSlope;

        uint prevTimestamp = _lastTimestamp;
        uint nextTimestamp = truncateExpiry(_lastTimestamp).add(LOCK_UNIT_BASE);
        while (nextTimestamp < block.timestamp) {
            uint deltaScore = nextTimestamp.sub(prevTimestamp).mul(slope);
            score = score < deltaScore ? 0 : score.sub(deltaScore);
            slope = slope.sub(_slopeChanges[nextTimestamp]);

            prevTimestamp = nextTimestamp;
            nextTimestamp = nextTimestamp.add(LOCK_UNIT_BASE);
        }

        uint deltaScore = block.timestamp > prevTimestamp ? block.timestamp.sub(prevTimestamp).mul(slope) : 0;
        score = score > deltaScore ? score.sub(deltaScore) : 0;
    }

    /**
     * @notice Calculate time-weighted balance of account
     * @param account Account of which the balance will be calculated
     */
    function scoreOf(address account) external view override returns (uint) {
        if (expires[account] < block.timestamp) return 0;
        return expires[account].sub(block.timestamp).mul(balances[account].div(LOCK_UNIT_MAX));
    }

    function truncateExpiry(uint time) public pure returns (uint) {
        return time.div(LOCK_UNIT_BASE).mul(LOCK_UNIT_BASE);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint amount, uint expiry) external override nonReentrant {
        require(amount > 0, "QubitLocker: invalid amount");

        expiry = balances[msg.sender] == 0 ? truncateExpiry(expiry) : expires[msg.sender];
        require(block.timestamp < expiry && expiry <= block.timestamp + LOCK_UNIT_MAX, "QubitLocker: invalid expiry");

        _slopeChanges[expiry] = _slopeChanges[expiry].add(amount.div(LOCK_UNIT_MAX));
        _updateTotalScore(amount, expiry);

        QBT.safeTransferFrom(msg.sender, address(this), amount);
        totalBalance = totalBalance.add(amount);

        balances[msg.sender] = balances[msg.sender].add(amount);
        expires[msg.sender] = expiry;
    }

    function extendLock(uint nextExpiry) external override nonReentrant {
        uint amount = balances[msg.sender];
        require(amount > 0, "QubitLocker: zero balance");

        uint prevExpiry = expires[msg.sender];
        nextExpiry = truncateExpiry(nextExpiry);
        require(
            Math.max(prevExpiry, block.timestamp) < nextExpiry && nextExpiry <= block.timestamp + LOCK_UNIT_MAX,
            "QubitLocker: invalid expiry time"
        );

        uint slopeChange = (_slopeChanges[prevExpiry] < amount.div(LOCK_UNIT_MAX))
            ? _slopeChanges[prevExpiry]
            : amount.div(LOCK_UNIT_MAX);
        _slopeChanges[prevExpiry] = _slopeChanges[prevExpiry].sub(slopeChange);
        _slopeChanges[nextExpiry] = _slopeChanges[nextExpiry].add(slopeChange);
        _updateTotalScoreExtendingLock(amount, prevExpiry, nextExpiry);
        expires[msg.sender] = nextExpiry;
    }

    /**
     * @notice Withdraw all tokens for `msg.sender`
     * @dev Only possible if the lock has expired
     */
    function withdraw() external override nonReentrant {
        require(balances[msg.sender] > 0 && block.timestamp >= expires[msg.sender], "QubitLocker: invalid state");
        _updateTotalScore(0, 0);

        uint amount = balances[msg.sender];
        totalBalance = totalBalance.sub(amount);
        delete balances[msg.sender];
        delete expires[msg.sender];
        QBT.safeTransfer(msg.sender, amount);
    }

    function depositBehalf(
        address account,
        uint amount,
        uint expiry
    ) external override onlyWhitelisted nonReentrant {
        require(amount > 0, "QubitLocker: invalid amount");

        expiry = balances[account] == 0 ? truncateExpiry(expiry) : expires[account];
        require(block.timestamp < expiry && expiry <= block.timestamp + LOCK_UNIT_MAX, "QubitLocker: invalid expiry");

        _slopeChanges[expiry] = _slopeChanges[expiry].add(amount.div(LOCK_UNIT_MAX));
        _updateTotalScore(amount, expiry);

        QBT.safeTransferFrom(msg.sender, address(this), amount);
        totalBalance = totalBalance.add(amount);

        balances[account] = balances[account].add(amount);
        expires[account] = expiry;
    }

    function withdrawBehalf(address account) external override onlyWhitelisted nonReentrant {
        require(balances[account] > 0 && block.timestamp >= expires[account], "QubitLocker: invalid state");
        _updateTotalScore(0, 0);

        uint amount = balances[account];
        totalBalance = totalBalance.sub(amount);
        delete balances[account];
        delete expires[account];
        QBT.safeTransfer(account, amount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _updateTotalScore(uint newAmount, uint nextExpiry) private {
        (uint score, uint slope) = totalScore();

        if (newAmount > 0) {
            uint slopeChange = newAmount.div(LOCK_UNIT_MAX);
            uint newAmountDeltaScore = nextExpiry.sub(block.timestamp).mul(slopeChange);

            slope = slope.add(slopeChange);
            score = score.add(newAmountDeltaScore);
        }

        _lastTotalScore = score;
        _lastSlope = slope;
        _lastTimestamp = block.timestamp;
    }

    function _updateTotalScoreExtendingLock(
        uint amount,
        uint prevExpiry,
        uint nextExpiry
    ) private {
        (uint score, uint slope) = totalScore();

        uint deltaScore = nextExpiry.sub(prevExpiry).mul(amount.div(LOCK_UNIT_MAX));
        score = score.add(deltaScore);

        _lastTotalScore = score;
        _lastSlope = slope;
        _lastTimestamp = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPresaleLocker.sol";
import "../interfaces/IQubitPresale.sol";
import "../interfaces/IPriceCalculator.sol";
import "../library/SafeToken.sol";

contract QubitPresaleTester is IQubitPresale, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address public constant BUNNY_WBNB_LP = 0x5aFEf8567414F29f0f927A0F2787b188624c10E2;
    address public constant QBT_WBNB_LP = 0x67EFeF66A55c4562144B9AcfCFbc62F9E4269b3e;

    address public constant DEPLOYER = 0xbeE397129374D0b4db7bf1654936951e5bdfe5a6;

    IPancakeRouter02 private constant router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IPancakeFactory private constant factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    IPriceCalculator public constant priceCalculator = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    /* ========== STATE VARIABLES ========== */

    uint public startTime;
    uint public endTime;
    uint public presaleAmountUSD;
    uint public totalBunnyBnbLp;
    uint public qbtAmount;
    uint public override qbtBnbLpAmount;
    uint public override lpPriceAtArchive;
    uint private _distributionCursor;

    mapping(address => uint) public bunnyBnbLpOf;
    mapping(address => bool) public claimedOf;
    address[] public accountList;
    bool public archived;

    IPresaleLocker public qbtBnbLocker;

    mapping(address => uint) public refundLpOf;
    address public QBT;

    /* ========== EVENTS ========== */

    event Deposit(address indexed user, uint amount);
    event Distributed(uint length, uint remain);

    /* ========== INITIALIZER ========== */

    function initialize(
        uint _startTime,
        uint _endTime,
        uint _presaleAmountUSD,
        uint _qbtAmount,
        address _qbtAddress
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        startTime = _startTime;
        endTime = _endTime;
        presaleAmountUSD = _presaleAmountUSD;
        qbtAmount = _qbtAmount;
        QBT = _qbtAddress;

        BUNNY_WBNB_LP.safeApprove(address(router), uint(~0));
        QBT.safeApprove(address(router), uint(~0));
        BUNNY.safeApprove(address(router), uint(~0));
        WBNB.safeApprove(address(router), uint(~0));
    }

    /* ========== VIEWS ========== */

    function allocationOf(address _user) public view override returns (uint) {
        return totalBunnyBnbLp == 0 ? 0 : bunnyBnbLpOf[_user].mul(1e18).div(totalBunnyBnbLp);
    }

    function refundOf(address _user) public view override returns (uint) {
        uint lpPriceNow = lpPriceAtArchive;
        if (lpPriceAtArchive == 0) {
            (, lpPriceNow) = priceCalculator.valueOfAsset(BUNNY_WBNB_LP, 1e18);
        }

        if (totalBunnyBnbLp.mul(lpPriceNow).div(1e18) <= presaleAmountUSD) {
            return 0;
        }

        uint lpAmountToPay = presaleAmountUSD.mul(allocationOf(_user)).div(lpPriceNow);
        return bunnyBnbLpOf[_user].sub(lpAmountToPay);
    }

    function accountListLength() external view override returns (uint) {
        return accountList.length;
    }

    function presaleDataOf(address account) public view returns (PresaleData memory) {
        PresaleData memory presaleData;
        presaleData.startTime = startTime;
        presaleData.endTime = endTime;
        presaleData.userLpAmount = bunnyBnbLpOf[account];
        presaleData.totalLpAmount = totalBunnyBnbLp;
        presaleData.claimedOf = claimedOf[account];
        presaleData.refundLpAmount = refundLpOf[account];
        presaleData.qbtBnbLpAmount = qbtBnbLpAmount;

        return presaleData;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setQubitBnbLocker(address _qubitBnbLocker) public override onlyOwner {
        require(_qubitBnbLocker != address(0), "QubitPresale: invalid address");

        qbtBnbLocker = IPresaleLocker(_qubitBnbLocker);
        qbtBnbLocker.setPresaleEndTime(endTime);
        QBT_WBNB_LP.safeApprove(address(qbtBnbLocker), uint(~0));
    }

    function setPresaleAmountUSD(uint _presaleAmountUSD) public override onlyOwner {
        require(block.timestamp < startTime, "QubitPresale: already started");

        presaleAmountUSD = _presaleAmountUSD;
    }

    function setPeriod(uint _start, uint _end) public override onlyOwner {
        require(block.timestamp < startTime, "QubitPresale: already started");
        require(block.timestamp < _start && _start < _end, "QubitPresale: invalid time values");
        require(address(qbtBnbLocker) != address(0), "QubitPresale: QbtBnbLocker must be set");

        startTime = _start;
        endTime = _end;

        qbtBnbLocker.setPresaleEndTime(endTime);
    }

    function setQbtAmount(uint _qbtAmount) public override onlyOwner {
        require(block.timestamp < startTime, "QubitPresale: already started");

        qbtAmount = _qbtAmount;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function deposit(uint _amount) public override {
        require(block.timestamp > startTime && block.timestamp < endTime, "QubitPresale: not in presale");
        require(_amount > 0, "QubitPresale: invalid amount");

        if (bunnyBnbLpOf[msg.sender] == 0) {
            accountList.push(msg.sender);
        }
        bunnyBnbLpOf[msg.sender] = bunnyBnbLpOf[msg.sender].add(_amount);
        totalBunnyBnbLp = totalBunnyBnbLp.add(_amount);

        BUNNY_WBNB_LP.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _amount);
    }

    function archive() public override onlyOwner returns (uint bunnyAmount, uint wbnbAmount) {
        require(!archived && qbtBnbLpAmount == 0, "QubitPresale: already archived");
        require(IBEP20(QBT).balanceOf(address(this)) == qbtAmount, "QubitPresale: lack of QBT");
        require(block.timestamp > endTime, "QubitPresale: not harvest time");
        (, lpPriceAtArchive) = priceCalculator.valueOfAsset(BUNNY_WBNB_LP, 1e18);
        require(lpPriceAtArchive > 0, "QubitPresale: invalid lp price");
        uint presaleAmount = presaleAmountUSD.div(lpPriceAtArchive).mul(1e18);

        // burn manually transferred LP token
        if (IPancakePair(BUNNY_WBNB_LP).balanceOf(BUNNY_WBNB_LP) > 0) {
            IPancakePair(BUNNY_WBNB_LP).burn(DEPLOYER);
        }

        uint amount = Math.min(totalBunnyBnbLp, presaleAmount);
        (bunnyAmount, wbnbAmount) = router.removeLiquidity(BUNNY, WBNB, amount, 0, 0, address(this), block.timestamp);
        BUNNY.safeTransfer(DEAD, bunnyAmount);

        uint qbtAmountFixed = presaleAmount < totalBunnyBnbLp
            ? qbtAmount
            : qbtAmount.mul(totalBunnyBnbLp).div(presaleAmount);
        (, , qbtBnbLpAmount) = router.addLiquidity(
            QBT,
            WBNB,
            qbtAmountFixed,
            wbnbAmount,
            0,
            0,
            address(this),
            block.timestamp
        );

        archived = true;
    }

    function distribute(uint distributeThreshold) external override onlyOwner {
        require(block.timestamp > endTime, "QubitPresale: not harvest time");
        require(archived, "QubitPresale: not yet archived");
        uint start = _distributionCursor;
        uint totalUserCount = accountList.length;
        uint remain = totalUserCount > _distributionCursor ? totalUserCount - _distributionCursor : 0;
        uint length = Math.min(remain, distributeThreshold);
        for (uint i = start; i < start + length; i++) {
            address account = accountList[i];
            if (!claimedOf[account]) {
                claimedOf[account] = true;

                uint refundingLpAmount = refundOf(account);
                if (refundingLpAmount > 0 && refundLpOf[account] == 0) {
                    refundLpOf[account] = refundingLpAmount;
                    BUNNY_WBNB_LP.safeTransfer(account, refundingLpAmount);
                }

                uint depositLpAmount = qbtBnbLpAmount.mul(allocationOf(account)).div(1e18);
                if (depositLpAmount > 0) {
                    delete bunnyBnbLpOf[account];
                    // block qbtBnbLocker for test
                    // qbtBnbLocker.depositBehalf(account, depositLpAmount);
                }
            }
            _distributionCursor++;
        }
        remain = totalUserCount > _distributionCursor ? totalUserCount - _distributionCursor : 0;
        emit Distributed(length, remain);
    }

    function sweep(uint _lpAmount, uint _offerAmount) public override onlyOwner {
        require(_lpAmount <= IBEP20(BUNNY_WBNB_LP).balanceOf(address(this)), "QubitPresale: not enough token 0");
        require(_offerAmount <= IBEP20(QBT).balanceOf(address(this)), "QubitPresale: not enough token 1");
        BUNNY_WBNB_LP.safeTransfer(msg.sender, _lpAmount);
        QBT.safeTransfer(msg.sender, _offerAmount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

interface IPresaleLocker {
    function setPresale(address _presaleContract) external;

    function setPresaleEndTime(uint endTime) external;

    function balanceOf(address account) external view returns (uint);

    function withdrawableBalanceOf(address account) external view returns (uint);

    function depositBehalf(address account, uint balance) external;

    function withdraw(uint amount) external;

    function withdrawAll() external;

    function recoverToken(address tokenAddress, uint tokenAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

interface IQubitPresale {
    struct PresaleData {
        uint startTime;
        uint endTime;
        uint userLpAmount;
        uint totalLpAmount;
        bool claimedOf;
        uint refundLpAmount;
        uint qbtBnbLpAmount;
    }

    function lpPriceAtArchive() external view returns (uint);

    function qbtBnbLpAmount() external view returns (uint);

    function allocationOf(address _user) external view returns (uint);

    function refundOf(address _user) external view returns (uint);

    function accountListLength() external view returns (uint);

    function setQubitBnbLocker(address _qubitBnbLocker) external;

    function setPresaleAmountUSD(uint _limitAmount) external;

    function setPeriod(uint _start, uint _end) external;

    function setQbtAmount(uint _qbtAmount) external;

    function deposit(uint _amount) external;

    function archive() external returns (uint bunnyAmount, uint wbnbAmount);

    function distribute(uint distributeThreshold) external;

    function sweep(uint _lpAmount, uint _offerAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IQore.sol";
import "./interfaces/IQDistributor.sol";
import "./interfaces/IPriceCalculator.sol";
import "./library/WhitelistUpgradeable.sol";
import { QConstant } from "./library/QConstant.sol";
import "./interfaces/IQToken.sol";

abstract contract QoreAdmin is IQore, WhitelistUpgradeable, ReentrancyGuardUpgradeable {
    /* ========== CONSTANT VARIABLES ========== */

    IPriceCalculator public constant priceCalculator = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    /* ========== STATE VARIABLES ========== */

    address public keeper;
    address public override qValidator;
    IQDistributor public qDistributor;

    address[] public markets; // qTokenAddress[]
    mapping(address => QConstant.MarketInfo) public marketInfos; // (qTokenAddress => MarketInfo)

    uint public closeFactor;
    uint public override liquidationIncentive;

    /* ========== Event ========== */

    event MarketListed(address qToken);
    event MarketEntered(address qToken, address account);
    event MarketExited(address qToken, address account);

    event CloseFactorUpdated(uint newCloseFactor);
    event CollateralFactorUpdated(address qToken, uint newCollateralFactor);
    event LiquidationIncentiveUpdated(uint newLiquidationIncentive);
    event BorrowCapUpdated(address indexed qToken, uint newBorrowCap);
    event KeeperUpdated(address newKeeper);
    event QValidatorUpdated(address newQValidator);
    event QDistributorUpdated(address newQDistributor);

    /* ========== MODIFIERS ========== */

    modifier onlyKeeper() {
        require(msg.sender == keeper || msg.sender == owner(), "Qore: caller is not the owner or keeper");
        _;
    }

    modifier onlyListedMarket(address qToken) {
        require(marketInfos[qToken].isListed, "Qore: invalid market");
        _;
    }

    /* ========== INITIALIZER ========== */

    function __Qore_init() internal initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();

        closeFactor = 5e17;
        liquidationIncentive = 11e17;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setKeeper(address _keeper) external onlyKeeper {
        require(_keeper != address(0), "Qore: invalid keeper address");
        keeper = _keeper;
        emit KeeperUpdated(_keeper);
    }

    function setQValidator(address _qValidator) external onlyKeeper {
        require(_qValidator != address(0), "Qore: invalid qValidator address");
        qValidator = _qValidator;
        emit QValidatorUpdated(_qValidator);
    }

    function setQDistributor(address _qDistributor) external onlyKeeper {
        require(_qDistributor != address(0), "Qore: invalid qDistributor address");
        qDistributor = IQDistributor(_qDistributor);
        emit QDistributorUpdated(_qDistributor);
    }

    function setCloseFactor(uint newCloseFactor) external onlyKeeper {
        require(
            newCloseFactor >= QConstant.CLOSE_FACTOR_MIN && newCloseFactor <= QConstant.CLOSE_FACTOR_MAX,
            "Qore: invalid close factor"
        );
        closeFactor = newCloseFactor;
        emit CloseFactorUpdated(newCloseFactor);
    }

    function setCollateralFactor(address qToken, uint newCollateralFactor)
        external
        onlyKeeper
        onlyListedMarket(qToken)
    {
        require(newCollateralFactor <= QConstant.COLLATERAL_FACTOR_MAX, "Qore: invalid collateral factor");
        if (newCollateralFactor != 0 && priceCalculator.getUnderlyingPrice(qToken) == 0) {
            revert("Qore: invalid underlying price");
        }

        marketInfos[qToken].collateralFactor = newCollateralFactor;
        emit CollateralFactorUpdated(qToken, newCollateralFactor);
    }

    function setLiquidationIncentive(uint newLiquidationIncentive) external onlyKeeper {
        liquidationIncentive = newLiquidationIncentive;
        emit LiquidationIncentiveUpdated(newLiquidationIncentive);
    }

    function setMarketBorrowCaps(address[] calldata qTokens, uint[] calldata newBorrowCaps) external onlyKeeper {
        require(qTokens.length != 0 && qTokens.length == newBorrowCaps.length, "Qore: invalid data");

        for (uint i = 0; i < qTokens.length; i++) {
            marketInfos[qTokens[i]].borrowCap = newBorrowCaps[i];
            emit BorrowCapUpdated(qTokens[i], newBorrowCaps[i]);
        }
    }

    function listMarket(
        address payable qToken,
        uint borrowCap,
        uint collateralFactor
    ) external onlyKeeper {
        require(!marketInfos[qToken].isListed, "Qore: already listed market");
        for (uint i = 0; i < markets.length; i++) {
            require(markets[i] != qToken, "Qore: already listed market");
        }

        marketInfos[qToken] = QConstant.MarketInfo({
            isListed: true,
            borrowCap: borrowCap,
            collateralFactor: collateralFactor
        });
        markets.push(qToken);
        emit MarketListed(qToken);
    }

    function removeMarket(address payable qToken) external onlyKeeper {
        require(marketInfos[qToken].isListed, "Qore: unlisted market");
        require(IQToken(qToken).totalSupply() == 0 && IQToken(qToken).totalBorrow() == 0, "Qore: cannot remove market");

        uint length = markets.length;
        for (uint i = 0; i < length; i++) {
            if (markets[i] == qToken) {
                markets[i] = markets[length - 1];
                markets.pop();
                delete marketInfos[qToken];
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IQValidator.sol";

import "../QoreAdmin.sol";

contract QoreTester is QoreAdmin {
    using SafeMath for uint;

    function notifySupplyUpdated(address market, address user) external {
        qDistributor.notifySupplyUpdated(market, user);
    }

    /* ========== CONSTANT VARIABLES ========== */

    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    /* ========== STATE VARIABLES ========== */

    mapping(address => address[]) public marketListOfUsers; // (account => qTokenAddress[])
    mapping(address => mapping(address => bool)) public usersOfMarket; // (qTokenAddress => (account => joined))
    address[] public totalUserList;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Qore_init();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyMemberOfMarket(address qToken) {
        require(usersOfMarket[qToken][msg.sender], "Qore: must enter market");
        _;
    }

    /* ========== VIEWS ========== */

    function allMarkets() external view override returns (address[] memory) {
        return markets;
    }

    function marketInfoOf(address qToken) external view override returns (QConstant.MarketInfo memory) {
        return marketInfos[qToken];
    }

    function marketListOf(address account) external view override returns (address[] memory) {
        return marketListOfUsers[account];
    }

    function checkMembership(address account, address qToken) external view override returns (bool) {
        return usersOfMarket[qToken][account];
    }

    function getTotalUserList() external view override returns (address[] memory) {
        return totalUserList;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function enterMarkets(address[] memory qTokens) public override {
        for (uint i = 0; i < qTokens.length; i++) {
            _enterMarket(payable(qTokens[i]), msg.sender);
        }
    }

    function exitMarket(address qToken) external override onlyListedMarket(qToken) onlyMemberOfMarket(qToken) {
        QConstant.AccountSnapshot memory snapshot = IQToken(qToken).accruedAccountSnapshot(msg.sender);
        require(snapshot.borrowBalance == 0, "Qore: borrow balance must be zero");
        require(
            IQValidator(qValidator).redeemAllowed(qToken, msg.sender, snapshot.qTokenBalance),
            "Qore: cannot redeem"
        );

        delete usersOfMarket[qToken][msg.sender];
        _removeUserMarket(qToken, msg.sender);
        emit MarketExited(qToken, msg.sender);
    }

    function supply(address qToken, uint uAmount) external payable override onlyListedMarket(qToken) returns (uint) {
        uAmount = IQToken(qToken).underlying() == address(WBNB) ? msg.value : uAmount;

        uint qAmount = IQToken(qToken).supply{ value: msg.value }(msg.sender, uAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return qAmount;
    }

    function redeemToken(address qToken, uint qAmount) external override onlyListedMarket(qToken) returns (uint) {
        uint uAmountRedeem = IQToken(qToken).redeemToken(msg.sender, qAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return uAmountRedeem;
    }

    function redeemUnderlying(address qToken, uint uAmount) external override onlyListedMarket(qToken) returns (uint) {
        uint uAmountRedeem = IQToken(qToken).redeemUnderlying(msg.sender, uAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return uAmountRedeem;
    }

    function borrow(address qToken, uint amount) external override onlyListedMarket(qToken) {
        _enterMarket(qToken, msg.sender);
        require(IQValidator(qValidator).borrowAllowed(qToken, msg.sender, amount), "Qore: cannot borrow");

        IQToken(payable(qToken)).borrow(msg.sender, amount);
        qDistributor.notifyBorrowUpdated(qToken, msg.sender);
    }

    function repayBorrow(address qToken, uint amount) external payable override onlyListedMarket(qToken) {
        IQToken(payable(qToken)).repayBorrow{ value: msg.value }(msg.sender, amount);
        qDistributor.notifyBorrowUpdated(qToken, msg.sender);
    }

    function repayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable override onlyListedMarket(qToken) {
        IQToken(payable(qToken)).repayBorrowBehalf{ value: msg.value }(msg.sender, borrower, amount);
        qDistributor.notifyBorrowUpdated(qToken, borrower);
    }

    function liquidateBorrow(
        address qTokenBorrowed,
        address qTokenCollateral,
        address borrower,
        uint amount
    ) external payable override {
        require(marketInfos[qTokenBorrowed].isListed && marketInfos[qTokenCollateral].isListed, "Qore: invalid market");
        require(
            IQValidator(qValidator).liquidateAllowed(qTokenBorrowed, borrower, amount, closeFactor),
            "Qore: cannot liquidate borrow"
        );

        // TODO need a test for distribution update

        uint qAmountToSeize = IQToken(qTokenBorrowed).liquidateBorrow{ value: msg.value }(
            qTokenCollateral,
            msg.sender,
            borrower,
            amount
        );
        IQToken(qTokenCollateral).seize(msg.sender, borrower, qAmountToSeize);
        qDistributor.notifySupplyUpdated(qTokenCollateral, borrower);
        qDistributor.notifySupplyUpdated(qTokenCollateral, msg.sender);
        qDistributor.notifyBorrowUpdated(qTokenBorrowed, borrower);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _enterMarket(address qToken, address _account) internal onlyListedMarket(qToken) {
        if (!usersOfMarket[qToken][_account]) {
            usersOfMarket[qToken][_account] = true;
            marketListOfUsers[_account].push(qToken);
            emit MarketEntered(qToken, _account);
        }
    }

    function _removeUserMarket(address qTokenToExit, address _account) private {
        require(marketListOfUsers[_account].length > 0, "Qore: cannot pop user market");

        address[] memory updatedMarkets = new address[](marketListOfUsers[_account].length - 1);
        uint counter = 0;
        for (uint i = 0; i < marketListOfUsers[_account].length; i++) {
            if (marketListOfUsers[_account][i] != qTokenToExit) {
                updatedMarkets[counter++] = marketListOfUsers[_account][i];
            }
        }
        marketListOfUsers[_account] = updatedMarkets;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IQToken.sol";
import "./interfaces/IQValidator.sol";

import "./QoreAdmin.sol";

contract Qore is QoreAdmin {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    /* ========== STATE VARIABLES ========== */

    mapping(address => address[]) public marketListOfUsers; // (account => qTokenAddress[])
    mapping(address => mapping(address => bool)) public usersOfMarket; // (qTokenAddress => (account => joined))
    address[] public totalUserList;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Qore_init();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyMemberOfMarket(address qToken) {
        require(usersOfMarket[qToken][msg.sender], "Qore: must enter market");
        _;
    }

    /* ========== VIEWS ========== */

    function allMarkets() external view override returns (address[] memory) {
        return markets;
    }

    function marketInfoOf(address qToken) external view override returns (QConstant.MarketInfo memory) {
        return marketInfos[qToken];
    }

    function marketListOf(address account) external view override returns (address[] memory) {
        return marketListOfUsers[account];
    }

    function checkMembership(address account, address qToken) external view override returns (bool) {
        return usersOfMarket[qToken][account];
    }

    function getTotalUserList() external view override returns (address[] memory) {
        return totalUserList;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function enterMarkets(address[] memory qTokens) public override {
        for (uint i = 0; i < qTokens.length; i++) {
            _enterMarket(payable(qTokens[i]), msg.sender);
        }
    }

    function exitMarket(address qToken) external override onlyListedMarket(qToken) onlyMemberOfMarket(qToken) {
        QConstant.AccountSnapshot memory snapshot = IQToken(qToken).accruedAccountSnapshot(msg.sender);
        require(snapshot.borrowBalance == 0, "Qore: borrow balance must be zero");
        require(
            IQValidator(qValidator).redeemAllowed(qToken, msg.sender, snapshot.qTokenBalance),
            "Qore: cannot redeem"
        );

        delete usersOfMarket[qToken][msg.sender];
        _removeUserMarket(qToken, msg.sender);
        emit MarketExited(qToken, msg.sender);
    }

    function supply(address qToken, uint uAmount)
        external
        payable
        override
        onlyListedMarket(qToken)
        nonReentrant
        returns (uint)
    {
        uAmount = IQToken(qToken).underlying() == address(WBNB) ? msg.value : uAmount;

        uint qAmount = IQToken(qToken).supply{ value: msg.value }(msg.sender, uAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return qAmount;
    }

    function redeemToken(address qToken, uint qAmount)
        external
        override
        onlyListedMarket(qToken)
        nonReentrant
        returns (uint)
    {
        uint uAmountRedeem = IQToken(qToken).redeemToken(msg.sender, qAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return uAmountRedeem;
    }

    function redeemUnderlying(address qToken, uint uAmount)
        external
        override
        onlyListedMarket(qToken)
        nonReentrant
        returns (uint)
    {
        uint uAmountRedeem = IQToken(qToken).redeemUnderlying(msg.sender, uAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return uAmountRedeem;
    }

    function borrow(address qToken, uint amount) external override onlyListedMarket(qToken) nonReentrant {
        _enterMarket(qToken, msg.sender);
        require(IQValidator(qValidator).borrowAllowed(qToken, msg.sender, amount), "Qore: cannot borrow");

        IQToken(payable(qToken)).borrow(msg.sender, amount);
        qDistributor.notifyBorrowUpdated(qToken, msg.sender);
    }

    function repayBorrow(address qToken, uint amount) external payable override onlyListedMarket(qToken) nonReentrant {
        IQToken(payable(qToken)).repayBorrow{ value: msg.value }(msg.sender, amount);
        qDistributor.notifyBorrowUpdated(qToken, msg.sender);
    }

    function repayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable override onlyListedMarket(qToken) nonReentrant {
        IQToken(payable(qToken)).repayBorrowBehalf{ value: msg.value }(msg.sender, borrower, amount);
        qDistributor.notifyBorrowUpdated(qToken, borrower);
    }

    function liquidateBorrow(
        address qTokenBorrowed,
        address qTokenCollateral,
        address borrower,
        uint amount
    ) external payable override nonReentrant {
        amount = IQToken(qTokenBorrowed).underlying() == address(WBNB) ? msg.value : amount;
        require(marketInfos[qTokenBorrowed].isListed && marketInfos[qTokenCollateral].isListed, "Qore: invalid market");
        require(
            IQValidator(qValidator).liquidateAllowed(qTokenBorrowed, borrower, amount, closeFactor),
            "Qore: cannot liquidate borrow"
        );

        uint qAmountToSeize = IQToken(qTokenBorrowed).liquidateBorrow{ value: msg.value }(
            qTokenCollateral,
            msg.sender,
            borrower,
            amount
        );
        IQToken(qTokenCollateral).seize(msg.sender, borrower, qAmountToSeize);
        qDistributor.notifyBorrowUpdated(qTokenBorrowed, borrower);
    }

    function removeUserFromList(address _account) external onlyKeeper {
        require(marketListOfUsers[_account].length == 0, "Qore: cannot remove user");

        uint length = totalUserList.length;
        for (uint i = 0; i < length; i++) {
            if (totalUserList[i] == _account) {
                totalUserList[i] = totalUserList[length - 1];
                totalUserList.pop();
                break;
            }
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _enterMarket(address qToken, address _account) internal onlyListedMarket(qToken) {
        if (!usersOfMarket[qToken][_account]) {
            usersOfMarket[qToken][_account] = true;
            if (marketListOfUsers[_account].length == 0) {
                totalUserList.push(_account);
            }
            marketListOfUsers[_account].push(qToken);
            emit MarketEntered(qToken, _account);
        }
    }

    function _removeUserMarket(address qTokenToExit, address _account) private {
        require(marketListOfUsers[_account].length > 0, "Qore: cannot pop user market");

        uint length = marketListOfUsers[_account].length;
        for (uint i = 0; i < length; i++) {
            if (marketListOfUsers[_account][i] == qTokenToExit) {
                marketListOfUsers[_account][i] = marketListOfUsers[_account][length - 1];
                marketListOfUsers[_account].pop();
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "../interfaces/IQToken.sol";

contract SimplePriceCalculatorTester {
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint public priceBunny;
    uint public priceCake;
    uint public priceBNB;

    constructor() public {
        priceBunny = 20e18;
        priceCake = 15e18;
        priceBNB = 400e18;
    }

    function setUnderlyingPrice(address qTokenAddress, uint price) public {
        IQToken qToken = IQToken(qTokenAddress);
        address addr = qToken.underlying();
        if (addr == BUNNY) {
            priceBunny = price;
        } else if (addr == CAKE) {
            priceCake = price;
        } else if (addr == BNB || addr == WBNB) {
            priceBNB = price;
        }
    }

    function getUnderlyingPrice(address qTokenAddress) public view returns (uint) {
        IQToken qToken = IQToken(qTokenAddress);
        address addr = qToken.underlying();
        if (addr == BUNNY) {
            return priceBunny;
        } else if (addr == CAKE) {
            return priceCake;
        } else if (addr == BUSD) {
            return 1e18;
        } else if (addr == USDT) {
            return 1e18;
        } else if (addr == BNB || addr == WBNB) {
            return priceBNB;
        } else {
            return 0;
        }
    }

    function getUnderlyingPrices(address[] memory assets) public view returns (uint[] memory) {
        uint[] memory returnValue = new uint[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            IQToken qToken = IQToken(payable(assets[i]));
            address addr = qToken.underlying();
            if (addr == BUNNY) {
                returnValue[i] = priceBunny;
            } else if (addr == CAKE) {
                returnValue[i] = priceCake;
            } else if (addr == BUSD) {
                returnValue[i] = 1e18;
            } else if (addr == USDT) {
                returnValue[i] = 1e18;
            } else if (addr == BNB || addr == WBNB) {
                returnValue[i] = priceBNB;
            } else {
                returnValue[i] = 0;
            }
        }
        return returnValue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IQToken.sol";
import "../interfaces/IBEP20.sol";
import "hardhat/console.sol";

contract QTokenTransferTester {
    /* ========== CONSTANT VARIABLES ========== */

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant qore = 0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48;
    address public constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;

    /* ========== STATE VARIABLES ========== */

    /* ========== INITIALIZER ========== */

    constructor() public {}

    function transfer(
        address qToken,
        address sender,
        address receiver,
        uint amount
    ) external {
        IQToken(qToken).transferFrom(sender, receiver, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./library/WhitelistUpgradeable.sol";
import "./library/SafeToken.sol";
import "./interfaces/IBEP20.sol";
import "./interfaces/IQDistributor.sol";
import "./interfaces/IQubitLocker.sol";
import "./interfaces/IQToken.sol";
import "./interfaces/IQore.sol";

contract QDistributor is IQDistributor, WhitelistUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    address private constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;

    uint public constant BOOST_PORTION_Q = 60;
    uint public constant BOOST_PORTION_MAX = 100;

    IQore public constant qore = IQore(0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48);
    IQubitLocker public constant qubitLocker = IQubitLocker(0xB8243be1D145a528687479723B394485cE3cE773);

    /* ========== STATE VARIABLES ========== */

    mapping(address => DistributionInfo) distributions;
    mapping(address => mapping(address => UserInfo)) marketUsers;

    /* ========== MODIFIERS ========== */

    modifier updateDistributionOf(address market) {
        DistributionInfo storage dist = distributions[market];
        if (dist.accruedAt == 0) {
            dist.accruedAt = block.timestamp;
        }

        uint timeElapsed = block.timestamp > dist.accruedAt ? block.timestamp.sub(dist.accruedAt) : 0;
        if (timeElapsed > 0) {
            if (dist.totalBoostedSupply > 0) {
                dist.accPerShareSupply = dist.accPerShareSupply.add(
                    dist.supplyRate.mul(timeElapsed).mul(1e18).div(dist.totalBoostedSupply)
                );
            }

            if (dist.totalBoostedBorrow > 0) {
                dist.accPerShareBorrow = dist.accPerShareBorrow.add(
                    dist.borrowRate.mul(timeElapsed).mul(1e18).div(dist.totalBoostedBorrow)
                );
            }
        }
        dist.accruedAt = block.timestamp;
        _;
    }

    modifier onlyQore() {
        require(msg.sender == address(qore), "QDistributor: caller is not Qore");
        _;
    }

    modifier onlyMarket() {
        bool fromMarket = false;
        address[] memory markets = qore.allMarkets();
        for (uint i = 0; i < markets.length; i++) {
            if (msg.sender == markets[i]) {
                fromMarket = true;
                break;
            }
        }
        require(fromMarket == true, "QDistributor: caller should be market");
        _;
    }

    /* ========== EVENTS ========== */

    event QubitDistributionRateUpdated(address indexed qToken, uint supplyRate, uint borrowRate);
    event QubitClaimed(address indexed user, uint amount);

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();
    }

    /* ========== VIEWS ========== */

    function userInfoOf(address market, address user) external view returns (UserInfo memory) {
        return marketUsers[market][user];
    }

    function accruedQubit(address market, address user) external view override returns (uint) {
        DistributionInfo memory dist = distributions[market];
        UserInfo memory userInfo = marketUsers[market][user];

        uint _accruedQubit = userInfo.accruedQubit;
        uint accPerShareSupply = dist.accPerShareSupply;
        uint accPerShareBorrow = dist.accPerShareBorrow;

        uint timeElapsed = block.timestamp > dist.accruedAt ? block.timestamp.sub(dist.accruedAt) : 0;
        if (
            timeElapsed > 0 ||
            (accPerShareSupply != userInfo.accPerShareSupply) ||
            (accPerShareBorrow != userInfo.accPerShareBorrow)
        ) {
            if (dist.totalBoostedSupply > 0) {
                accPerShareSupply = accPerShareSupply.add(
                    dist.supplyRate.mul(timeElapsed).mul(1e18).div(dist.totalBoostedSupply)
                );

                uint pendingQubit = userInfo.boostedSupply.mul(accPerShareSupply.sub(userInfo.accPerShareSupply)).div(
                    1e18
                );
                _accruedQubit = _accruedQubit.add(pendingQubit);
            }

            if (dist.totalBoostedBorrow > 0) {
                accPerShareBorrow = accPerShareBorrow.add(
                    dist.borrowRate.mul(timeElapsed).mul(1e18).div(dist.totalBoostedBorrow)
                );

                uint pendingQubit = userInfo.boostedBorrow.mul(accPerShareBorrow.sub(userInfo.accPerShareBorrow)).div(
                    1e18
                );
                _accruedQubit = _accruedQubit.add(pendingQubit);
            }
        }
        return _accruedQubit;
    }

    function qubitRatesOf(address market) external view override returns (uint supplyRate, uint borrowRate) {
        return (distributions[market].supplyRate, distributions[market].borrowRate);
    }

    function totalBoosted(address market) external view override returns (uint boostedSupply, uint boostedBorrow) {
        return (distributions[market].totalBoostedSupply, distributions[market].totalBoostedBorrow);
    }

    function boostedBalanceOf(address market, address account)
        external
        view
        override
        returns (uint boostedSupply, uint boostedBorrow)
    {
        return (marketUsers[market][account].boostedSupply, marketUsers[market][account].boostedBorrow);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setQubitDistributionRates(
        address qToken,
        uint supplyRate,
        uint borrowRate
    ) external onlyOwner updateDistributionOf(qToken) {
        DistributionInfo storage dist = distributions[qToken];
        dist.supplyRate = supplyRate;
        dist.borrowRate = borrowRate;
        emit QubitDistributionRateUpdated(qToken, supplyRate, borrowRate);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function notifySupplyUpdated(address market, address user)
        external
        override
        nonReentrant
        onlyQore
        updateDistributionOf(market)
    {
        DistributionInfo storage dist = distributions[market];
        UserInfo storage userInfo = marketUsers[market][user];

        if (userInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(userInfo.accPerShareSupply);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedSupply).div(1e18));
        }
        userInfo.accPerShareSupply = dist.accPerShareSupply;

        uint boostedSupply = _calculateBoostedSupply(market, user);
        dist.totalBoostedSupply = dist.totalBoostedSupply.add(boostedSupply).sub(userInfo.boostedSupply);
        userInfo.boostedSupply = boostedSupply;
    }

    function notifyBorrowUpdated(address market, address user)
        external
        override
        nonReentrant
        onlyQore
        updateDistributionOf(market)
    {
        DistributionInfo storage dist = distributions[market];
        UserInfo storage userInfo = marketUsers[market][user];

        if (userInfo.boostedBorrow > 0) {
            uint accQubitPerShare = dist.accPerShareBorrow.sub(userInfo.accPerShareBorrow);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedBorrow).div(1e18));
        }
        userInfo.accPerShareBorrow = dist.accPerShareBorrow;

        uint boostedBorrow = _calculateBoostedBorrow(market, user);
        dist.totalBoostedBorrow = dist.totalBoostedBorrow.add(boostedBorrow).sub(userInfo.boostedBorrow);
        userInfo.boostedBorrow = boostedBorrow;
    }

    function notifyTransferred(
        address qToken,
        address sender,
        address receiver
    ) external override nonReentrant onlyMarket updateDistributionOf(qToken) {
        require(sender != receiver, "QDistributor: invalid transfer");
        DistributionInfo storage dist = distributions[qToken];
        UserInfo storage senderInfo = marketUsers[qToken][sender];
        UserInfo storage receiverInfo = marketUsers[qToken][receiver];

        if (senderInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(senderInfo.accPerShareSupply);
            senderInfo.accruedQubit = senderInfo.accruedQubit.add(
                accQubitPerShare.mul(senderInfo.boostedSupply).div(1e18)
            );
        }
        senderInfo.accPerShareSupply = dist.accPerShareSupply;

        if (receiverInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(receiverInfo.accPerShareSupply);
            receiverInfo.accruedQubit = receiverInfo.accruedQubit.add(
                accQubitPerShare.mul(receiverInfo.boostedSupply).div(1e18)
            );
        }
        receiverInfo.accPerShareSupply = dist.accPerShareSupply;

        uint boostedSenderSupply = _calculateBoostedSupply(qToken, sender);
        uint boostedReceiverSupply = _calculateBoostedSupply(qToken, receiver);
        dist.totalBoostedSupply = dist
            .totalBoostedSupply
            .add(boostedSenderSupply)
            .add(boostedReceiverSupply)
            .sub(senderInfo.boostedSupply)
            .sub(receiverInfo.boostedSupply);
        senderInfo.boostedSupply = boostedSenderSupply;
        receiverInfo.boostedSupply = boostedReceiverSupply;
    }

    function claimQubit(address user) external override nonReentrant {
        require(msg.sender == user, "QDistributor: invalid user");
        uint _accruedQubit = 0;

        address[] memory markets = qore.allMarkets();
        for (uint i = 0; i < markets.length; i++) {
            address market = markets[i];
            _accruedQubit = _accruedQubit.add(_claimQubit(market, user));
        }

        _transferQubit(user, _accruedQubit);
    }

    function claimQubit(address market, address user) external nonReentrant {
        require(msg.sender == user, "QDistributor: invalid user");

        uint _accruedQubit = _claimQubit(market, user);
        _transferQubit(user, _accruedQubit);
    }

    function kick(address user) external override nonReentrant {
        require(qubitLocker.scoreOf(user) == 0, "QDistributor: kick not allowed");

        address[] memory markets = qore.allMarkets();
        for (uint i = 0; i < markets.length; i++) {
            address market = markets[i];
            _updateSupplyOf(market, user);
            _updateBorrowOf(market, user);
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _claimQubit(address market, address user) private returns (uint _accruedQubit) {
        bool hasBoostedSupply = marketUsers[market][user].boostedSupply > 0;
        bool hasBoostedBorrow = marketUsers[market][user].boostedBorrow > 0;
        if (hasBoostedSupply) _updateSupplyOf(market, user);
        if (hasBoostedBorrow) _updateBorrowOf(market, user);

        UserInfo storage userInfo = marketUsers[market][user];
        _accruedQubit = _accruedQubit.add(userInfo.accruedQubit);
        userInfo.accruedQubit = 0;

        return _accruedQubit;
    }

    function _transferQubit(address user, uint amount) private {
        amount = Math.min(amount, IBEP20(QBT).balanceOf(address(this)));
        QBT.safeTransfer(user, amount);
        emit QubitClaimed(user, amount);
    }

    function _calculateBoostedSupply(address market, address user) private view returns (uint) {
        uint defaultSupply = IQToken(market).balanceOf(user);
        uint boostedSupply = defaultSupply.mul(BOOST_PORTION_MAX - BOOST_PORTION_Q).div(BOOST_PORTION_MAX);

        uint userScore = qubitLocker.scoreOf(user);
        (uint totalScore, ) = qubitLocker.totalScore();
        if (userScore > 0 && totalScore > 0) {
            uint scoreBoosted = IQToken(market).totalSupply().mul(userScore).div(totalScore).mul(BOOST_PORTION_Q).div(
                100
            );
            boostedSupply = boostedSupply.add(scoreBoosted);
        }
        return Math.min(boostedSupply, defaultSupply);
    }

    function _calculateBoostedBorrow(address market, address user) private view returns (uint) {
        uint accInterestIndex = IQToken(market).getAccInterestIndex();
        uint defaultBorrow = IQToken(market).borrowBalanceOf(user).mul(1e18).div(accInterestIndex);
        uint boostedBorrow = defaultBorrow.mul(BOOST_PORTION_MAX - BOOST_PORTION_Q).div(BOOST_PORTION_MAX);

        uint userScore = qubitLocker.scoreOf(user);
        (uint totalScore, ) = qubitLocker.totalScore();
        if (userScore > 0 && totalScore > 0) {
            uint totalBorrow = IQToken(market).totalBorrow().mul(1e18).div(accInterestIndex);
            uint scoreBoosted = totalBorrow.mul(userScore).div(totalScore).mul(BOOST_PORTION_Q).div(100);
            boostedBorrow = boostedBorrow.add(scoreBoosted);
        }
        return Math.min(boostedBorrow, defaultBorrow);
    }

    function _updateSupplyOf(address market, address user) private updateDistributionOf(market) {
        DistributionInfo storage dist = distributions[market];
        UserInfo storage userInfo = marketUsers[market][user];

        if (userInfo.boostedSupply > 0) {
            uint accQubitPerShare = dist.accPerShareSupply.sub(userInfo.accPerShareSupply);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedSupply).div(1e18));
        }
        userInfo.accPerShareSupply = dist.accPerShareSupply;

        uint boostedSupply = _calculateBoostedSupply(market, user);
        dist.totalBoostedSupply = dist.totalBoostedSupply.add(boostedSupply).sub(userInfo.boostedSupply);
        userInfo.boostedSupply = boostedSupply;
    }

    function _updateBorrowOf(address market, address user) private updateDistributionOf(market) {
        DistributionInfo storage dist = distributions[market];
        UserInfo storage userInfo = marketUsers[market][user];

        if (userInfo.boostedBorrow > 0) {
            uint accQubitPerShare = dist.accPerShareBorrow.sub(userInfo.accPerShareBorrow);
            userInfo.accruedQubit = userInfo.accruedQubit.add(accQubitPerShare.mul(userInfo.boostedBorrow).div(1e18));
        }
        userInfo.accPerShareBorrow = dist.accPerShareBorrow;

        uint boostedBorrow = _calculateBoostedBorrow(market, user);
        dist.totalBoostedBorrow = dist.totalBoostedBorrow.add(boostedBorrow).sub(userInfo.boostedBorrow);
        userInfo.boostedBorrow = boostedBorrow;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "./library/WhitelistUpgradeable.sol";
import "./library/SafeToken.sol";
import "./interfaces/IQubitLocker.sol";

contract QubitDevReservoir is WhitelistUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    address internal constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;

    /* ========== STATE VARIABLES ========== */

    address public receiver;
    IQubitLocker public qubitLocker;

    uint public startAt;
    uint public ratePerSec;
    uint public dripped;

    /* ========== INITIALIZER ========== */

    function initialize(
        address _receiver,
        uint _ratePerSec,
        uint _startAt
    ) external initializer {
        __WhitelistUpgradeable_init();

        require(_receiver != address(0), "QubitDevReservoir: invalid receiver");
        require(_ratePerSec > 0, "QubitDevReservoir: invalid rate");

        receiver = _receiver;
        ratePerSec = _ratePerSec;
        startAt = _startAt;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setLocker(address _qubitLocker) external onlyOwner {
        require(_qubitLocker != address(0), "QubitDevReservoir: invalid locker address");
        qubitLocker = IQubitLocker(_qubitLocker);
        IBEP20(QBT).approve(_qubitLocker, uint(-1));
    }

    /* ========== VIEWS ========== */

    function getDripInfo()
        external
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        return (startAt, ratePerSec, dripped);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function drip() public onlyOwner returns (uint) {
        require(block.timestamp >= startAt, "QubitDevReservoir: not started");

        uint balance = IBEP20(QBT).balanceOf(address(this));
        uint totalDrip = ratePerSec.mul(block.timestamp.sub(startAt));
        uint amountToDrip = Math.min(balance, totalDrip.sub(dripped));
        dripped = dripped.add(amountToDrip);
        QBT.safeTransfer(receiver, amountToDrip);
        return amountToDrip;
    }

    function dripToLocker() public onlyOwner returns (uint) {
        require(address(qubitLocker) != address(0), "QubitDevReservoir: no locker assigned");
        require(block.timestamp >= startAt, "QubitDevReservoir: not started");
        uint balance = IBEP20(QBT).balanceOf(address(this));
        uint totalDrip = ratePerSec.mul(block.timestamp.sub(startAt));
        uint amountToDrip = Math.min(balance, totalDrip.sub(dripped));
        dripped = dripped.add(amountToDrip);

        if (qubitLocker.expiryOf(receiver) > block.timestamp) {
            qubitLocker.depositBehalf(receiver, amountToDrip, 0);
            return amountToDrip;
        } else {
            qubitLocker.depositBehalf(receiver, amountToDrip, block.timestamp + 365 days * 2);
            return amountToDrip;
        }
    }

    function setStartAt(uint _startAt) public onlyOwner {
        require(startAt <= _startAt, "QubitDevReservoir: invalid startAt");
        startAt = _startAt;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";

contract QTokenBulkTransfer {
    function bulkSend(
        address qToken,
        uint amount,
        address[] memory accounts
    ) external {
        require(IBEP20(qToken).balanceOf(address(this)) > 0, "no balance");

        for (uint i = 0; i < accounts.length; i++) {
            IBEP20(qToken).transfer(accounts[i], amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "./library/WhitelistUpgradeable.sol";
import "./library/SafeToken.sol";

contract QubitReservoir is WhitelistUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    address private constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;

    /* ========== STATE VARIABLES ========== */

    address public receiver;

    uint public startAt;
    uint public ratePerSec;
    uint public ratePerSec2;
    uint public ratePerSec3;
    uint public dripped;

    /* ========== INITIALIZER ========== */

    function initialize(
        address _receiver,
        uint _ratePerSec,
        uint _ratePerSec2,
        uint _ratePerSec3,
        uint _startAt
    ) external initializer {
        __WhitelistUpgradeable_init();

        require(_receiver != address(0), "QubitReservoir: invalid receiver");
        require(_ratePerSec > 0, "QubitReservoir: invalid rate");

        receiver = _receiver;
        ratePerSec = _ratePerSec;
        ratePerSec2 = _ratePerSec2;
        ratePerSec3 = _ratePerSec3;
        startAt = _startAt;
    }

    /* ========== VIEWS ========== */

    function getDripInfo()
        external
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        if (block.timestamp < startAt || block.timestamp.sub(startAt) <= 30 days) {
            return (startAt, ratePerSec, dripped);
        } else if (30 days < block.timestamp.sub(startAt) && block.timestamp.sub(startAt) <= 60 days) {
            return (startAt, ratePerSec2, dripped);
        } else {
            return (startAt, ratePerSec3, dripped);
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function drip() public onlyOwner returns (uint) {
        require(block.timestamp >= startAt, "QubitReservoir: not started");

        uint balance = IBEP20(QBT).balanceOf(address(this));
        uint totalDrip;
        if (block.timestamp.sub(startAt) <= 30 days) {
            totalDrip = ratePerSec.mul(block.timestamp.sub(startAt));
        } else if (block.timestamp.sub(startAt) <= 60 days) {
            totalDrip = ratePerSec.mul(30 days);
            totalDrip = totalDrip.add(ratePerSec2.mul(block.timestamp.sub(startAt + 30 days)));
        } else {
            totalDrip = ratePerSec.mul(30 days);
            totalDrip = totalDrip.add(ratePerSec2.mul(30 days));
            totalDrip = totalDrip.add(ratePerSec3.mul(block.timestamp.sub(startAt + 60 days)));
        }

        uint amountToDrip = Math.min(balance, totalDrip.sub(dripped));
        dripped = dripped.add(amountToDrip);
        QBT.safeTransfer(receiver, amountToDrip);
        return amountToDrip;
    }

    function setStartAt(uint _startAt) public onlyOwner {
        require(startAt <= _startAt, "QubitReservoir: invalid startAt");
        startAt = _startAt;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPresaleLocker.sol";
import "../interfaces/IQubitPresale.sol";
import "../interfaces/IPriceCalculator.sol";
import "../library/SafeToken.sol";

contract QubitPresale is IQubitPresale, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address public constant BUNNY_WBNB_LP = 0x5aFEf8567414F29f0f927A0F2787b188624c10E2;
    address public constant QBT_WBNB_LP = 0x67EFeF66A55c4562144B9AcfCFbc62F9E4269b3e;

    address public constant DEPLOYER = 0xbeE397129374D0b4db7bf1654936951e5bdfe5a6;

    IPancakeRouter02 private constant router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IPancakeFactory private constant factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    IPriceCalculator public constant priceCalculator = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    /* ========== STATE VARIABLES ========== */

    uint public startTime;
    uint public endTime;
    uint public presaleAmountUSD;
    uint public totalBunnyBnbLp;
    uint public qbtAmount;
    uint public override qbtBnbLpAmount;
    uint public override lpPriceAtArchive;
    uint private _distributionCursor;

    mapping(address => uint) public bunnyBnbLpOf;
    mapping(address => bool) public claimedOf;
    address[] public accountList;
    bool public archived;

    IPresaleLocker public qbtBnbLocker;

    mapping(address => uint) public refundLpOf;

    /* ========== EVENTS ========== */

    event Deposit(address indexed user, uint amount);
    event Distributed(uint length, uint remain);

    /* ========== INITIALIZER ========== */

    function initialize(
        uint _startTime,
        uint _endTime,
        uint _presaleAmountUSD,
        uint _qbtAmount
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        startTime = _startTime;
        endTime = _endTime;
        presaleAmountUSD = _presaleAmountUSD;
        qbtAmount = _qbtAmount;

        BUNNY_WBNB_LP.safeApprove(address(router), uint(~0));
        QBT.safeApprove(address(router), uint(~0));
        BUNNY.safeApprove(address(router), uint(~0));
        WBNB.safeApprove(address(router), uint(~0));
    }

    /* ========== VIEWS ========== */

    function allocationOf(address _user) public view override returns (uint) {
        return totalBunnyBnbLp == 0 ? 0 : bunnyBnbLpOf[_user].mul(1e18).div(totalBunnyBnbLp);
    }

    function refundOf(address _user) public view override returns (uint) {
        uint lpPriceNow = lpPriceAtArchive;
        if (lpPriceAtArchive == 0) {
            (, lpPriceNow) = priceCalculator.valueOfAsset(BUNNY_WBNB_LP, 1e18);
        }

        if (totalBunnyBnbLp.mul(lpPriceNow).div(1e18) <= presaleAmountUSD) {
            return 0;
        }

        uint lpAmountToPay = presaleAmountUSD.mul(allocationOf(_user)).div(lpPriceNow);
        return bunnyBnbLpOf[_user].sub(lpAmountToPay);
    }

    function accountListLength() external view override returns (uint) {
        return accountList.length;
    }

    function presaleDataOf(address account) public view returns (PresaleData memory) {
        PresaleData memory presaleData;
        presaleData.startTime = startTime;
        presaleData.endTime = endTime;
        presaleData.userLpAmount = bunnyBnbLpOf[account];
        presaleData.totalLpAmount = totalBunnyBnbLp;
        presaleData.claimedOf = claimedOf[account];
        presaleData.refundLpAmount = refundLpOf[account];
        presaleData.qbtBnbLpAmount = qbtBnbLpAmount;

        return presaleData;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setQubitBnbLocker(address _qubitBnbLocker) public override onlyOwner {
        require(_qubitBnbLocker != address(0), "QubitPresale: invalid address");

        qbtBnbLocker = IPresaleLocker(_qubitBnbLocker);
        qbtBnbLocker.setPresaleEndTime(endTime);
        QBT_WBNB_LP.safeApprove(address(qbtBnbLocker), uint(~0));
    }

    function setPresaleAmountUSD(uint _presaleAmountUSD) public override onlyOwner {
        require(block.timestamp < startTime, "QubitPresale: already started");

        presaleAmountUSD = _presaleAmountUSD;
    }

    function setPeriod(uint _start, uint _end) public override onlyOwner {
        require(block.timestamp < startTime, "QubitPresale: already started");
        require(block.timestamp < _start && _start < _end, "QubitPresale: invalid time values");
        require(address(qbtBnbLocker) != address(0), "QubitPresale: QbtBnbLocker must be set");

        startTime = _start;
        endTime = _end;

        qbtBnbLocker.setPresaleEndTime(endTime);
    }

    function setQbtAmount(uint _qbtAmount) public override onlyOwner {
        require(block.timestamp < startTime, "QubitPresale: already started");

        qbtAmount = _qbtAmount;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function deposit(uint _amount) public override {
        require(block.timestamp > startTime && block.timestamp < endTime, "QubitPresale: not in presale");
        require(_amount > 0, "QubitPresale: invalid amount");

        if (bunnyBnbLpOf[msg.sender] == 0) {
            accountList.push(msg.sender);
        }
        bunnyBnbLpOf[msg.sender] = bunnyBnbLpOf[msg.sender].add(_amount);
        totalBunnyBnbLp = totalBunnyBnbLp.add(_amount);

        BUNNY_WBNB_LP.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _amount);
    }

    function archive() public override onlyOwner returns (uint bunnyAmount, uint wbnbAmount) {
        require(!archived && qbtBnbLpAmount == 0, "QubitPresale: already archived");
        require(IBEP20(QBT).balanceOf(address(this)) == qbtAmount, "QubitPresale: lack of QBT");
        require(block.timestamp > endTime, "QubitPresale: not harvest time");
        (, lpPriceAtArchive) = priceCalculator.valueOfAsset(BUNNY_WBNB_LP, 1e18);
        require(lpPriceAtArchive > 0, "QubitPresale: invalid lp price");
        uint presaleAmount = presaleAmountUSD.div(lpPriceAtArchive).mul(1e18);

        // burn manually transferred LP token
        if (IPancakePair(BUNNY_WBNB_LP).balanceOf(BUNNY_WBNB_LP) > 0) {
            IPancakePair(BUNNY_WBNB_LP).burn(DEPLOYER);
        }

        uint amount = Math.min(totalBunnyBnbLp, presaleAmount);
        (bunnyAmount, wbnbAmount) = router.removeLiquidity(BUNNY, WBNB, amount, 0, 0, address(this), block.timestamp);
        BUNNY.safeTransfer(DEAD, bunnyAmount);

        uint qbtAmountFixed = presaleAmount < totalBunnyBnbLp
            ? qbtAmount
            : qbtAmount.mul(totalBunnyBnbLp).div(presaleAmount);
        (, , qbtBnbLpAmount) = router.addLiquidity(
            QBT,
            WBNB,
            qbtAmountFixed,
            wbnbAmount,
            0,
            0,
            address(this),
            block.timestamp
        );

        archived = true;
    }

    function distribute(uint distributeThreshold) external override onlyOwner {
        require(block.timestamp > endTime, "QubitPresale: not harvest time");
        require(archived, "QubitPresale: not yet archived");
        uint start = _distributionCursor;
        uint totalUserCount = accountList.length;
        uint remain = totalUserCount > _distributionCursor ? totalUserCount - _distributionCursor : 0;
        uint length = Math.min(remain, distributeThreshold);
        for (uint i = start; i < start + length; i++) {
            address account = accountList[i];
            if (!claimedOf[account]) {
                claimedOf[account] = true;

                uint refundingLpAmount = refundOf(account);
                if (refundingLpAmount > 0 && refundLpOf[account] == 0) {
                    refundLpOf[account] = refundingLpAmount;
                    BUNNY_WBNB_LP.safeTransfer(account, refundingLpAmount);
                }

                uint depositLpAmount = qbtBnbLpAmount.mul(allocationOf(account)).div(1e18);
                if (depositLpAmount > 0) {
                    delete bunnyBnbLpOf[account];
                    qbtBnbLocker.depositBehalf(account, depositLpAmount);
                }
            }
            _distributionCursor++;
        }
        remain = totalUserCount > _distributionCursor ? totalUserCount - _distributionCursor : 0;
        emit Distributed(length, remain);
    }

    function sweep(uint _lpAmount, uint _offerAmount) public override onlyOwner {
        require(_lpAmount <= IBEP20(BUNNY_WBNB_LP).balanceOf(address(this)), "QubitPresale: not enough token 0");
        require(_offerAmount <= IBEP20(QBT).balanceOf(address(this)), "QubitPresale: not enough token 1");
        BUNNY_WBNB_LP.safeTransfer(msg.sender, _lpAmount);
        QBT.safeTransfer(msg.sender, _offerAmount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../interfaces/IRateModel.sol";

contract RateModelSlope is IRateModel, OwnableUpgradeable {
    using SafeMath for uint;

    uint private baseRatePerYear;
    uint private slopePerYearFirst;
    uint private slopePerYearSecond;
    uint private optimal;

    function initialize(
        uint _baseRatePerYear,
        uint _slopePerYearFirst,
        uint _slopePerYearSecond,
        uint _optimal
    ) external initializer {
        __Ownable_init();

        baseRatePerYear = _baseRatePerYear;
        slopePerYearFirst = _slopePerYearFirst;
        slopePerYearSecond = _slopePerYearSecond;
        optimal = _optimal;
    }

    function utilizationRate(
        uint cash,
        uint borrows,
        uint reserves
    ) public pure returns (uint) {
        if (reserves >= cash.add(borrows)) return 0;
        return Math.min(borrows.mul(1e18).div(cash.add(borrows).sub(reserves)), 1e18);
    }

    function getBorrowRate(
        uint cash,
        uint borrows,
        uint reserves
    ) public view override returns (uint) {
        uint utilization = utilizationRate(cash, borrows, reserves);
        if (optimal > 0 && utilization < optimal) {
            return baseRatePerYear.add(utilization.mul(slopePerYearFirst).div(optimal)).div(365 days);
        } else {
            uint ratio = utilization.sub(optimal).mul(1e18).div(uint(1e18).sub(optimal));
            return baseRatePerYear.add(slopePerYearFirst).add(ratio.mul(slopePerYearSecond).div(1e18)).div(365 days);
        }
    }

    function getSupplyRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint reserveFactor
    ) public view override returns (uint) {
        uint oneMinusReserveFactor = uint(1e18).sub(reserveFactor);
        uint borrowRate = getBorrowRate(cash, borrows, reserves);
        uint rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
        return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IRateModel.sol";

contract InterestRateModelHarness is IRateModel {
    uint public constant opaqueBorrowFailureCode = 20;
    bool public failBorrowRate;
    uint public borrowRate;

    constructor(uint borrowRate_) public {
        borrowRate = borrowRate_;
    }

    function setFailBorrowRate(bool failBorrowRate_) public {
        failBorrowRate = failBorrowRate_;
    }

    function setBorrowRate(uint borrowRate_) public {
        borrowRate = borrowRate_;
    }

    function getBorrowRate(
        uint _cash,
        uint _borrows,
        uint _reserves
    ) public view override returns (uint) {
        _cash; // unused
        _borrows; // unused
        _reserves; // unused
        require(!failBorrowRate, "INTEREST_RATE_MODEL_ERROR");
        return borrowRate;
    }

    function getSupplyRate(
        uint _cash,
        uint _borrows,
        uint _reserves,
        uint _reserveFactor
    ) external view override returns (uint) {
        _cash; // unused
        _borrows; // unused
        _reserves; // unused
        return borrowRate * (1 - _reserveFactor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../interfaces/IRateModel.sol";

contract RateModelLinear is IRateModel, OwnableUpgradeable {
    using SafeMath for uint;

    uint private baseRatePerYear;
    uint private multiplierPerYear;

    function initialize(uint _baseRatePerYear, uint _multiplierPerYear) external initializer {
        __Ownable_init();
        baseRatePerYear = _baseRatePerYear;
        multiplierPerYear = _multiplierPerYear;
    }

    function utilizationRate(
        uint cash,
        uint borrows,
        uint reserves
    ) public pure returns (uint) {
        if (reserves >= cash.add(borrows)) return 0;
        return Math.min(borrows.mul(1e18).div(cash.add(borrows).sub(reserves)), 1e18);
    }

    function getBorrowRate(
        uint cash,
        uint borrows,
        uint reserves
    ) public view override returns (uint) {
        uint utilization = utilizationRate(cash, borrows, reserves);
        return (utilization.mul(multiplierPerYear).div(1e18).add(baseRatePerYear)).div(365 days);
    }

    function getSupplyRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint reserveFactor
    ) public view override returns (uint) {
        uint oneMinusReserveFactor = uint(1e18).sub(reserveFactor);
        uint borrowRate = getBorrowRate(cash, borrows, reserves);
        uint rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
        return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IQValidator.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IQore.sol";
import "../library/QConstant.sol";

contract QValidator is IQValidator, OwnableUpgradeable {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    IPriceCalculator public constant oracle = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    /* ========== STATE VARIABLES ========== */

    IQore public qore;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== VIEWS ========== */

    function getAccountLiquidity(
        address account,
        address qToken,
        uint redeemAmount,
        uint borrowAmount
    ) external view override returns (uint liquidity, uint shortfall) {
        uint accCollateralValueInUSD;
        uint accBorrowValueInUSD;

        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accountSnapshot(account);

            uint collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(prices[i])
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            accCollateralValueInUSD = accCollateralValueInUSD.add(
                snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18)
            );
            accBorrowValueInUSD = accBorrowValueInUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));

            if (assets[i] == qToken) {
                accBorrowValueInUSD = accBorrowValueInUSD.add(redeemAmount.mul(collateralValuePerShareInUSD).div(1e18));
                accBorrowValueInUSD = accBorrowValueInUSD.add(borrowAmount.mul(prices[i]).div(1e18));
            }
        }

        liquidity = accCollateralValueInUSD > accBorrowValueInUSD
            ? accCollateralValueInUSD.sub(accBorrowValueInUSD)
            : 0;
        shortfall = accCollateralValueInUSD > accBorrowValueInUSD
            ? 0
            : accBorrowValueInUSD.sub(accCollateralValueInUSD);
    }

    function getAccountLiquidityValue(address account)
        external
        view
        override
        returns (uint collateralUSD, uint borrowUSD)
    {
        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = oracle.getUnderlyingPrices(assets);
        collateralUSD = 0;
        borrowUSD = 0;
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accountSnapshot(account);

            uint collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(prices[i])
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            collateralUSD = collateralUSD.add(snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18));
            borrowUSD = borrowUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setQore(address _qore) external onlyOwner {
        require(_qore != address(0), "QValidator: invalid qore address");
        require(address(qore) == address(0), "QValidator: qore already set");
        qore = IQore(_qore);
    }

    /* ========== ALLOWED FUNCTIONS ========== */

    function redeemAllowed(
        address qToken,
        address redeemer,
        uint redeemAmount
    ) external override returns (bool) {
        (, uint shortfall) = _getAccountLiquidityInternal(redeemer, qToken, redeemAmount, 0);
        return shortfall == 0;
    }

    function borrowAllowed(
        address qToken,
        address borrower,
        uint borrowAmount
    ) external override returns (bool) {
        require(qore.checkMembership(borrower, address(qToken)), "QValidator: enterMarket required");
        require(oracle.getUnderlyingPrice(address(qToken)) > 0, "QValidator: Underlying price error");

        // Borrow cap of 0 corresponds to unlimited borrowing
        uint borrowCap = qore.marketInfoOf(qToken).borrowCap;
        if (borrowCap != 0) {
            uint totalBorrows = IQToken(payable(qToken)).accruedTotalBorrow();
            uint nextTotalBorrows = totalBorrows.add(borrowAmount);
            require(nextTotalBorrows < borrowCap, "QValidator: market borrow cap reached");
        }

        (, uint shortfall) = _getAccountLiquidityInternal(borrower, qToken, 0, borrowAmount);
        return shortfall == 0;
    }

    function liquidateAllowed(
        address qToken,
        address borrower,
        uint liquidateAmount,
        uint closeFactor
    ) external override returns (bool) {
        // The borrower must have shortfall in order to be liquidate
        (, uint shortfall) = _getAccountLiquidityInternal(borrower, address(0), 0, 0);
        require(shortfall != 0, "QValidator: Insufficient shortfall");

        // The liquidator may not repay more than what is allowed by the closeFactor
        uint borrowBalance = IQToken(payable(qToken)).accruedBorrowBalanceOf(borrower);
        uint maxClose = closeFactor.mul(borrowBalance).div(1e18);
        return liquidateAmount <= maxClose;
    }

    function qTokenAmountToSeize(
        address qTokenBorrowed,
        address qTokenCollateral,
        uint amount
    ) external override returns (uint seizeQAmount) {
        uint priceBorrowed = oracle.getUnderlyingPrice(qTokenBorrowed);
        uint priceCollateral = oracle.getUnderlyingPrice(qTokenCollateral);
        require(priceBorrowed != 0 && priceCollateral != 0, "QValidator: price error");

        uint exchangeRate = IQToken(payable(qTokenCollateral)).accruedExchangeRate();
        require(exchangeRate != 0, "QValidator: exchangeRate of qTokenCollateral is zero");

        // seizeQTokenAmount = amount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
        return amount.mul(qore.liquidationIncentive()).mul(priceBorrowed).div(priceCollateral.mul(exchangeRate));
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getAccountLiquidityInternal(
        address account,
        address qToken,
        uint redeemAmount,
        uint borrowAmount
    ) private returns (uint liquidity, uint shortfall) {
        uint accCollateralValueInUSD;
        uint accBorrowValueInUSD;

        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accruedAccountSnapshot(account);

            uint collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(prices[i])
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            accCollateralValueInUSD = accCollateralValueInUSD.add(
                snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18)
            );
            accBorrowValueInUSD = accBorrowValueInUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));

            if (assets[i] == qToken) {
                accBorrowValueInUSD = accBorrowValueInUSD.add(redeemAmount.mul(collateralValuePerShareInUSD).div(1e18));
                accBorrowValueInUSD = accBorrowValueInUSD.add(borrowAmount.mul(prices[i]).div(1e18));
            }
        }

        liquidity = accCollateralValueInUSD > accBorrowValueInUSD
            ? accCollateralValueInUSD.sub(accBorrowValueInUSD)
            : 0;
        shortfall = accCollateralValueInUSD > accBorrowValueInUSD
            ? 0
            : accBorrowValueInUSD.sub(accCollateralValueInUSD);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract BEP20Upgradeable is IBEP20, OwnableUpgradeable {
    using SafeMath for uint;

    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    uint private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint[50] private __gap;

    /**
     * @dev sets initials supply and the owner
     */
    function __BEP20__init(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal initializer {
        __Ownable_init();
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view override returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) external view override returns (uint) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Burn `amount` tokens and decreasing the total supply.
     */
    function burn(uint amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint amount
    ) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance")
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "../library/BEP20Upgradeable.sol";

contract QubitTokenTester is BEP20Upgradeable {
    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private _minters;

    /* ========== MODIFIERS ========== */

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __BEP20__init("Qubit Token", "QBT", 18);
        _minters[owner()] = true;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(address minter, bool canMint) external onlyOwner {
        _minters[minter] = canMint;
    }

    function mint(address _to, uint _amount) public {
        _mint(_to, _amount);
    }

    /* ========== VIEWS ========== */

    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "./library/BEP20Upgradeable.sol";

contract QubitToken is BEP20Upgradeable {
    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private _minters;

    /* ========== MODIFIERS ========== */

    modifier onlyMinter() {
        require(isMinter(msg.sender), "QBT: caller is not the minter");
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __BEP20__init("Qubit Token", "QBT", 18);
        _minters[owner()] = true;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(address minter, bool canMint) external onlyOwner {
        _minters[minter] = canMint;
    }

    function mint(address _to, uint _amount) public onlyMinter {
        _mint(_to, _amount);
    }

    /* ========== VIEWS ========== */

    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IQore.sol";
import "../interfaces/IDashboard.sol";
import "../interfaces/IQDistributor.sol";
import "../interfaces/IQubitLocker.sol";
import "../interfaces/IQValidator.sol";

contract DashboardBSC is IDashboard, OwnableUpgradeable {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address private constant QBT = 0xF523e4478d909968090a232eB380E2dd6f802518;
    IPriceCalculator public constant priceCalculator = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    /* ========== STATE VARIABLES ========== */

    IQore public qore;
    IQDistributor public qDistributor;
    IQubitLocker public qubitLocker;
    IQValidator public qValidator;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setQore(address _qore) external onlyOwner {
        require(_qore != address(0), "DashboardBSC: invalid qore address");
        require(address(qore) == address(0), "DashboardBSC: qore already set");
        qore = IQore(_qore);
    }

    function setQDistributor(address _qDistributor) external onlyOwner {
        require(_qDistributor != address(0), "DashboardBSC: invalid qDistributor address");
        qDistributor = IQDistributor(_qDistributor);
    }

    function setLocker(address _qubitLocker) external onlyOwner {
        require(_qubitLocker != address(0), "DashboardBSC: invalid locker address");
        qubitLocker = IQubitLocker(_qubitLocker);
    }

    function setQValidator(address _qValidator) external onlyOwner {
        require(_qValidator != address(0), "DashboardBSC: invalid qValidator address");
        qValidator = IQValidator(_qValidator);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function statusOf(address account, address[] memory markets)
        external
        view
        override
        returns (LockerData memory, MarketData[] memory)
    {
        MarketData[] memory results = new MarketData[](markets.length);
        for (uint i = 0; i < markets.length; i++) {
            results[i] = marketDataOf(account, markets[i]);
        }
        return (lockerDataOf(account), results);
    }

    function apyDistributionOf(address market) public view returns (uint apySupplyQBT, uint apyBorrowQBT) {
        (uint supplyRate, uint borrowRate) = qDistributor.qubitRatesOf(market);
        (uint boostedSupply, uint boostedBorrow) = qDistributor.totalBoosted(market);

        // base supply QBT APY == (qubitRate * 365 days * price Of Qubit) / (Total effective balance * exchangeRate * price of asset) / 2.5
        uint numerSupply = supplyRate.mul(365 days).mul(priceCalculator.priceOf(QBT));
        uint denomSupply = boostedSupply
            .mul(IQToken(market).exchangeRate())
            .mul(priceCalculator.getUnderlyingPrice(market))
            .div(1e36);
        apySupplyQBT = (denomSupply > 0) ? numerSupply.div(denomSupply).mul(100).div(250) : 0;

        // base borrow QBT APY == (qubitRate * 365 days * price Of Qubit) / (Total effective balance * interestIndex * price of asset) / 2.5
        uint numerBorrow = borrowRate.mul(365 days).mul(priceCalculator.priceOf(QBT));
        uint denomBorrow = boostedBorrow
            .mul(IQToken(market).getAccInterestIndex())
            .mul(priceCalculator.getUnderlyingPrice(market))
            .div(1e36);
        apyBorrowQBT = (denomBorrow > 0) ? numerBorrow.div(denomBorrow).mul(100).div(250) : 0;
    }

    function userApyDistributionOf(address account, address market)
        public
        view
        returns (uint userApySupplyQBT, uint userApyBorrowQBT)
    {
        (uint apySupplyQBT, uint apyBorrowQBT) = apyDistributionOf(market);

        (uint userBoostedSupply, uint userBoostedBorrow) = qDistributor.boostedBalanceOf(market, account);
        uint userSupply = IQToken(market).balanceOf(account);
        uint userBorrow = IQToken(market).borrowBalanceOf(account).mul(1e18).div(IQToken(market).getAccInterestIndex());

        // user supply QBT APY == ((qubitRate * 365 days * price Of Qubit) / (Total effective balance * exchangeRate * price of asset) ) * my boosted balance  / my balance
        userApySupplyQBT = (userSupply > 0) ? apySupplyQBT.mul(250).div(100).mul(userBoostedSupply).div(userSupply) : 0;
        // user borrow QBT APY == (qubitRate * 365 days * price Of Qubit) / (Total effective balance * interestIndex * price of asset) * my boosted balance  / my balance
        userApyBorrowQBT = (userBorrow > 0) ? apyBorrowQBT.mul(250).div(100).mul(userBoostedBorrow).div(userBorrow) : 0;
    }

    function marketDataOf(address account, address market) public view returns (MarketData memory) {
        MarketData memory marketData;

        (uint apySupplyQBT, uint apyBorrowQBT) = apyDistributionOf(market);
        marketData.apySupply = IQToken(market).supplyRatePerSec().mul(365 days);
        marketData.apySupplyQBT = apySupplyQBT;
        marketData.apyBorrow = IQToken(market).borrowRatePerSec().mul(365 days);
        marketData.apyBorrowQBT = apyBorrowQBT;

        // calculate my APY for QBT reward
        (uint userBoostedSupply, uint userBoostedBorrow) = qDistributor.boostedBalanceOf(market, account);
        uint userSupply = IQToken(market).balanceOf(account);
        uint userBorrow = IQToken(market).borrowBalanceOf(account).mul(1e18).div(IQToken(market).getAccInterestIndex());
        // user supply QBT APY == ((qubitRate * 365 days * price Of Qubit) / (Total effective balance * exchangeRate * price of asset) ) * my boosted balance  / my balance
        marketData.apyMySupplyQBT = (userSupply > 0)
            ? apySupplyQBT.mul(250).div(100).mul(userBoostedSupply).div(userSupply)
            : 0;
        // user borrow QBT APY == (qubitRate * 365 days * price Of Qubit) / (Total effective balance * interestIndex * price of asset) * my boosted balance  / my balance
        marketData.apyMyBorrowQBT = (userBorrow > 0)
            ? apyBorrowQBT.mul(250).div(100).mul(userBoostedBorrow).div(userBorrow)
            : 0;

        marketData.liquidity = IQToken(market).getCash();
        marketData.collateralFactor = qore.marketInfoOf(market).collateralFactor;

        marketData.membership = qore.checkMembership(account, market);
        marketData.supply = IQToken(market).underlyingBalanceOf(account);
        marketData.borrow = IQToken(market).borrowBalanceOf(account);
        marketData.totalSupply = IQToken(market).totalSupply().mul(IQToken(market).exchangeRate()).div(1e18);
        marketData.totalBorrow = IQToken(market).totalBorrow();
        (marketData.supplyBoosted, marketData.borrowBoosted) = qDistributor.boostedBalanceOf(market, account);
        (marketData.totalSupplyBoosted, marketData.totalBorrowBoosted) = qDistributor.totalBoosted(market);
        return marketData;
    }

    function marketsOf(address account, address[] memory markets) public view returns (MarketData[] memory) {
        MarketData[] memory results = new MarketData[](markets.length);
        for (uint i = 0; i < markets.length; i++) {
            results[i] = marketDataOf(account, markets[i]);
        }
        return results;
    }

    function lockerDataOf(address account) public view returns (LockerData memory) {
        LockerData memory lockerInfo;

        lockerInfo.totalLocked = qubitLocker.totalBalance();
        lockerInfo.locked = qubitLocker.balanceOf(account);

        (uint totalScore, ) = qubitLocker.totalScore();
        lockerInfo.totalScore = totalScore;
        lockerInfo.score = qubitLocker.scoreOf(account);

        lockerInfo.available = qubitLocker.availableOf(account);
        lockerInfo.expiry = qubitLocker.expiryOf(account);
        return lockerInfo;
    }

    function portfolioDataOf(address account) public view returns (PortfolioData memory) {
        PortfolioData memory portfolioData;
        address[] memory markets = qore.allMarkets();
        uint supplyEarnInUSD;
        uint supplyQBTEarnInUSD;
        uint borrowInterestInUSD;
        uint borrowQBTEarnInUSD;
        uint totalInUSD;

        for (uint i = 0; i < markets.length; i++) {
            MarketData memory marketData;
            marketData = marketDataOf(account, markets[i]);

            uint marketSupplyInUSD = marketData.supply.mul(priceCalculator.getUnderlyingPrice(markets[i])).div(1e18);
            uint marketBorrowInUSD = marketData.borrow.mul(priceCalculator.getUnderlyingPrice(markets[i])).div(1e18);

            supplyEarnInUSD = supplyEarnInUSD.add(marketSupplyInUSD.mul(marketData.apySupply).div(1e18));
            borrowInterestInUSD = borrowInterestInUSD.add(marketBorrowInUSD.mul(marketData.apyBorrow).div(1e18));
            supplyQBTEarnInUSD = supplyQBTEarnInUSD.add(marketSupplyInUSD.mul(marketData.apyMySupplyQBT).div(1e18));
            borrowQBTEarnInUSD = borrowQBTEarnInUSD.add(marketBorrowInUSD.mul(marketData.apyMyBorrowQBT).div(1e18));
            totalInUSD = totalInUSD.add(marketSupplyInUSD).add(marketBorrowInUSD);

            portfolioData.supplyInUSD = portfolioData.supplyInUSD.add(marketSupplyInUSD);
            portfolioData.borrowInUSD = portfolioData.borrowInUSD.add(marketBorrowInUSD);
            if (marketData.membership) {
                portfolioData.limitInUSD = portfolioData.limitInUSD.add(
                    marketSupplyInUSD.mul(marketData.collateralFactor).div(1e18)
                );
            }
        }
        if (totalInUSD > 0) {
            if (supplyEarnInUSD.add(supplyQBTEarnInUSD).add(borrowQBTEarnInUSD) > borrowInterestInUSD) {
                portfolioData.userApy = int(
                    supplyEarnInUSD
                        .add(supplyQBTEarnInUSD)
                        .add(borrowQBTEarnInUSD)
                        .sub(borrowInterestInUSD)
                        .mul(1e18)
                        .div(totalInUSD)
                );
            } else {
                portfolioData.userApy =
                    int(-1) *
                    int(
                        borrowInterestInUSD
                            .sub(supplyEarnInUSD.add(supplyQBTEarnInUSD).add(borrowQBTEarnInUSD))
                            .mul(1e18)
                            .div(totalInUSD)
                    );
            }
            portfolioData.userApySupply = supplyEarnInUSD.mul(1e18).div(totalInUSD);
            portfolioData.userApySupplyQBT = supplyQBTEarnInUSD.mul(1e18).div(totalInUSD);
            portfolioData.userApyBorrow = borrowInterestInUSD.mul(1e18).div(totalInUSD);
            portfolioData.userApyBorrowQBT = borrowQBTEarnInUSD.mul(1e18).div(totalInUSD);
        }

        return portfolioData;
    }

    function getUserLiquidityData(uint page, uint resultPerPage)
        external
        view
        returns (AccountLiquidityData[] memory, uint next)
    {
        uint index = page.mul(resultPerPage);
        uint limit = page.add(1).mul(resultPerPage);
        next = page.add(1);

        if (limit > qore.getTotalUserList().length) {
            limit = qore.getTotalUserList().length;
            next = 0;
        }

        if (qore.getTotalUserList().length == 0 || index > qore.getTotalUserList().length - 1) {
            return (new AccountLiquidityData[](0), 0);
        }

        AccountLiquidityData[] memory segment = new AccountLiquidityData[](limit.sub(index));

        uint cursor = 0;
        for (index; index < limit; index++) {
            if (index < qore.getTotalUserList().length) {
                address account = qore.getTotalUserList()[index];
                uint marketCount = qore.marketListOf(account).length;
                (uint collateralUSD, uint borrowUSD) = qValidator.getAccountLiquidityValue(account);
                segment[cursor] = AccountLiquidityData({
                    account: account,
                    marketCount: marketCount,
                    collateralUSD: collateralUSD,
                    borrowUSD: borrowUSD
                });
            }
            cursor++;
        }
        return (segment, next);
        //
        //        uint start;
        //        uint size;
        //        if (pageSize == 0) {
        //            start = 0;
        //            size = totalUserList.length;
        //        } else if (totalUserList.length < pageSize) {
        //            start = 0;
        //            size = page == 0 ? totalUserList.length : 0;
        //        } else {
        //            start = page.mul(pageSize);
        //            if (start <= totalUserList.length) {
        //                if (page == totalUserList.length.div(pageSize)) {
        //                    size = totalUserList.length.mod(pageSize);
        //                } else {
        //                    size = pageSize;
        //                }
        //            } else {
        //                size = 0;
        //            }
        //        }
        //
        //        AccountPortfolio[] memory portfolioList = new AccountPortfolio[](size);
        //        for (uint i = start; i < start.add(size); i ++) {
        //            portfolioList[i.sub(start)].userAddress = totalUserList[i];
        //            (portfolioList[i.sub(start)].collateralUSD, portfolioList[i.sub(start)].borrowUSD) = qValidator.getAccountLiquidityValue(totalUserList[i]);
        //            portfolioList[i.sub(start)].marketListLength = marketListOfUsers[totalUserList[i]].length;
        //        }
        //        return portfolioList;
    }

    function getUnclaimedQBT(address account) public view returns (uint unclaimedQBT) {
        address[] memory markets = qore.allMarkets();

        for (uint i = 0; i < markets.length; i++) {
            unclaimedQBT = unclaimedQBT.add(qDistributor.accruedQubit(markets[i], account));
        }
    }

    function getAvgBoost(address account) public view returns (uint) {
        address[] memory markets = qore.allMarkets();
        uint boostSum;
        uint boostNum;

        for (uint i = 0; i < markets.length; i++) {
            (uint userBoostedSupply, uint userBoostedBorrow) = qDistributor.boostedBalanceOf(markets[i], account);
            uint userSupply = IQToken(markets[i]).balanceOf(account);
            uint userBorrow = IQToken(markets[i]).borrowBalanceOf(account).mul(1e18).div(
                IQToken(markets[i]).getAccInterestIndex()
            );

            uint supplyBoost = (userSupply > 0) ? userBoostedSupply.mul(1e18).div(userSupply).mul(250).div(100) : 0;
            uint borrowBoost = (userBorrow > 0) ? userBoostedBorrow.mul(1e18).div(userBorrow).mul(250).div(100) : 0;

            if (supplyBoost > 0) {
                boostSum = boostSum.add(supplyBoost);
                boostNum = boostNum.add(1);
            }
            if (borrowBoost > 0) {
                boostSum = boostSum.add(borrowBoost);
                boostNum = boostNum.add(1);
            }
        }
        return (boostNum > 0) ? boostSum.div(boostNum) : 0;
    }

    function marketDetailDataOf(address market) public view returns (MarketDetailData memory) {
        MarketDetailData memory marketDetailData;
        IQToken qToken = IQToken(market);

        marketDetailData.qToken = market;
        marketDetailData.underlyingPrice = priceCalculator.getUnderlyingPrice(market);
        marketDetailData.cash = qToken.getCash();
        marketDetailData.borrowCap = qore.marketInfoOf(market).borrowCap;
        marketDetailData.reserve = qToken.totalReserve().mul(1e18).div(qToken.exchangeRate());
        marketDetailData.reserveFactor = qToken.reserveFactor();
        marketDetailData.collateralFactor = qore.marketInfoOf(market).collateralFactor;
        marketDetailData.totalSupply = qToken.totalSupply();
        marketDetailData.totalBorrows = qToken.totalBorrow();
        marketDetailData.exchangeRate = qToken.exchangeRate();

        marketDetailData.apySupply = qToken.supplyRatePerSec().mul(365 days);
        marketDetailData.apyBorrow = qToken.borrowRatePerSec().mul(365 days);
        (marketDetailData.apySupplyQBT, marketDetailData.apyBorrowQBT) = apyDistributionOf(market);

        return marketDetailData;
    }

    function getAllMarketInfo()
        public
        view
        returns (
            uint,
            uint,
            MarketDetailData[] memory
        )
    {
        address[] memory markets = qore.allMarkets();

        MarketDetailData[] memory marketDetailDatas = new MarketDetailData[](markets.length);

        (uint qScoreTotal, ) = qubitLocker.totalScore();
        uint averageBoostTotal;

        uint boostedSupply;
        uint boostedBorrows;
        uint usdAmountTotalSupply;
        uint usdAmountTotalBorrows;

        for (uint i = 0; i < markets.length; i++) {
            uint qTokenToUSD = IQToken(markets[i])
                .exchangeRate()
                .mul(priceCalculator.getUnderlyingPrice(markets[i]))
                .div(1e18);

            usdAmountTotalSupply = usdAmountTotalSupply.add(
                IQToken(markets[i]).totalSupply().mul(qTokenToUSD).div(1e18)
            );
            usdAmountTotalBorrows = usdAmountTotalBorrows.add(
                IQToken(markets[i]).totalBorrow().mul(qTokenToUSD).div(1e18)
            );

            (boostedSupply, boostedBorrows) = qDistributor.totalBoosted(markets[i]);

            boostedSupply = boostedSupply.add(boostedSupply.mul(qTokenToUSD).div(1e18));
            boostedBorrows = boostedBorrows.add(boostedBorrows.mul(qTokenToUSD).div(1e18));
            marketDetailDatas[i] = marketDetailDataOf(markets[i]);
        }

        averageBoostTotal = usdAmountTotalSupply.add(usdAmountTotalBorrows) == 0
            ? 1e18
            : (boostedSupply.add(boostedBorrows)).mul(25e17).div(usdAmountTotalSupply.add(usdAmountTotalBorrows));

        return (qScoreTotal, averageBoostTotal, marketDetailDatas);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/QConstant.sol";

interface IDashboard {
    struct LockerData {
        uint totalLocked;
        uint locked;
        uint totalScore;
        uint score;
        uint available;
        uint expiry;
    }

    struct MarketData {
        uint apySupply;
        uint apySupplyQBT;
        uint apyMySupplyQBT;
        uint apyBorrow;
        uint apyBorrowQBT;
        uint apyMyBorrowQBT;
        uint liquidity;
        uint collateralFactor;
        bool membership;
        uint supply;
        uint borrow;
        uint totalSupply;
        uint totalBorrow;
        uint supplyBoosted;
        uint borrowBoosted;
        uint totalSupplyBoosted;
        uint totalBorrowBoosted;
    }

    struct PortfolioData {
        int userApy;
        uint userApySupply;
        uint userApySupplyQBT;
        uint userApyBorrow;
        uint userApyBorrowQBT;
        uint supplyInUSD;
        uint borrowInUSD;
        uint limitInUSD;
    }

    struct AccountLiquidityData {
        address account;
        uint marketCount;
        uint collateralUSD;
        uint borrowUSD;
    }

    struct MarketDetailData {
        address qToken;
        uint underlyingPrice;
        uint cash;
        uint borrowCap;
        uint reserve;
        uint reserveFactor;
        uint collateralFactor;
        uint totalSupply;
        uint totalBorrows;
        uint exchangeRate;
        uint apySupply;
        uint apyBorrow;
        uint apySupplyQBT;
        uint apyBorrowQBT;
    }

    function statusOf(address account, address[] memory markets)
        external
        view
        returns (LockerData memory, MarketData[] memory);
}

