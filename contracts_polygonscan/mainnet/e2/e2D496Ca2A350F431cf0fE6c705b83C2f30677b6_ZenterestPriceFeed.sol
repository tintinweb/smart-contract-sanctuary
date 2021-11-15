// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./AttoDecimal.sol";
import "./ICorroborativeToken.sol";
import "./TwoStageOwnable.sol";

contract ZenterestPriceFeed is TwoStageOwnable {
    using AttoDecimalLib for AttoDecimal;

    bytes32 internal constant CORROBORATIVE_ETH_SYMBOL_COMPORATOR = keccak256(abi.encodePacked("zenETH"));

    struct Price {
        AttoDecimal value;
        uint256 updatedAt;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct PriceUpdate {
        address token;
        uint256 newPriceMantissa;
        uint256 updatedAt;
    }

    struct DelegatedPriceUpdate {
        address token;
        uint256 newPriceMantissa;
        uint256 updatedAt;
        Signature signature;
    }

    address private _reporter;
    mapping(address => Price) private _prices;

    function reporter() public view returns (address) {
        return _reporter;
    }

    function prices(address token) public view returns (Price memory price) {
        return _prices[token];
    }

    function assetPrices(address token) public view returns (uint256 price) {
        return _prices[token].value.mantissa;
    }

    function getUnderlyingPrice(ICorroborativeToken corroborative) public view returns (uint256) {
        if (keccak256(abi.encodePacked(corroborative.symbol())) == CORROBORATIVE_ETH_SYMBOL_COMPORATOR) {
            return AttoDecimalLib.ONE_MANTISSA;
        }
        return assetPrices(corroborative.underlying());
    }

    event PriceDelegated(
        address indexed token,
        address indexed submittedBy,
        uint256 newPriceMantissa,
        uint256 updatedAt,
        uint8 v,
        bytes32 r,
        bytes32 s
    );

    event PriceUpdated(address indexed token, uint256 newPriceMantissa, uint256 updatedAt);
    event ReporterChanged(address reporter);

    constructor(address owner_, address reporter_) public TwoStageOwnable(owner_) {
        _changeReporter(reporter_);
    }

    function changeReporter(address newReporterAddress) external onlyOwner returns (bool success) {
        _changeReporter(newReporterAddress);
        return true;
    }

    function updateDelegatedPrice(DelegatedPriceUpdate memory update)
        external
        UpdatingTimeInPast(update.updatedAt)
        returns (bool success)
    {
        _delegatedPriceUpdate(update);
        return true;
    }

    function updateDelegatedPricesBatch(DelegatedPriceUpdate[] memory updates)
        external
        returns (uint256 updatedPricesCount)
    {
        uint256 updatesCount = updates.length;
        for (uint256 i = 0; i < updatesCount; i++) {
            DelegatedPriceUpdate memory update = updates[i];
            _checkUpdatingTime(update.updatedAt);
            Price storage actualPrice = _prices[update.token];
            if (actualPrice.updatedAt >= update.updatedAt) continue;
            _delegatedPriceUpdate(update);
            updatedPricesCount += 1;
        }
    }

    function updateDelegatedPricesSet(PriceUpdate[] memory updates, Signature memory signature)
        external
        returns (uint256 updatedPricesCount)
    {
        uint256 updatesCount = updates.length;
        uint256[] memory splittedUpdates = new uint256[](updatesCount * 3);
        uint256 pointer = 0;
        for (uint256 updateIndex = 0; updateIndex < updatesCount; updateIndex++) {
            PriceUpdate memory update = updates[updateIndex];
            splittedUpdates[pointer] = uint256(update.token);
            splittedUpdates[pointer + 1] = update.newPriceMantissa;
            splittedUpdates[pointer + 2] = update.updatedAt;
            pointer += 3;
        }
        bytes memory encodedUpdates = abi.encodePacked(splittedUpdates);
        _checkSignerIsReporter(encodedUpdates, signature);
        return _updatePricesBatch(updates);
    }

    function updatePrice(PriceUpdate memory update)
        external
        UpdatingTimeInPast(update.updatedAt)
        returns (bool success)
    {
        require(msg.sender == _reporter, "Caller not reporter");
        _updatePrice(update.token, update.newPriceMantissa, update.updatedAt);
        return true;
    }

    function updatePricesBatch(PriceUpdate[] memory updates) external returns (uint256 updatedPricesCount) {
        require(msg.sender == _reporter, "Caller not reporter");
        return _updatePricesBatch(updates);
    }

    function _checkSignerIsReporter(bytes memory data, Signature memory signature) internal view {
        bytes32 hash_ = keccak256(data);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash_));
        address signer = ecrecover(prefixedHash, signature.v, signature.r, signature.s);
        require(signer == _reporter, "Invalid signature");
    }

    function _checkUpdatingTime(uint256 updatingTime) internal view {
        require(updatingTime <= block.timestamp, "Invalid updating time");
    }

    function _changeReporter(address newReporterAddress) internal {
        if (_reporter == newReporterAddress) return;
        _reporter = newReporterAddress;
        emit ReporterChanged(newReporterAddress);
    }

    function _delegatedPriceUpdate(DelegatedPriceUpdate memory update) internal {
        bytes memory encodedUpdate = abi.encodePacked(update.token, update.newPriceMantissa, update.updatedAt);
        _checkSignerIsReporter(encodedUpdate, update.signature);
        emit PriceDelegated(
            update.token,
            msg.sender,
            update.newPriceMantissa,
            update.updatedAt,
            update.signature.v,
            update.signature.r,
            update.signature.s
        );
        _updatePrice(update.token, update.newPriceMantissa, update.updatedAt);
    }

    function _updatePrice(
        address token,
        uint256 newPriceMantissa,
        uint256 updatedAt
    ) internal {
        Price storage actualPrice = _prices[token];
        uint256 lastUpdatedAt = actualPrice.updatedAt;
        require(lastUpdatedAt < updatedAt, "Price already updated");
        actualPrice.value = AttoDecimal({mantissa: newPriceMantissa});
        actualPrice.updatedAt = updatedAt;
        emit PriceUpdated(token, newPriceMantissa, updatedAt);
    }

    function _updatePricesBatch(PriceUpdate[] memory updates) internal returns (uint256 updatedPricesCount) {
        uint256 updatesCount = updates.length;
        for (uint256 i = 0; i < updatesCount; i++) {
            PriceUpdate memory update = updates[i];
            _checkUpdatingTime(update.updatedAt);
            Price storage actualPrice = _prices[update.token];
            if (actualPrice.updatedAt >= update.updatedAt) continue;
            _updatePrice(update.token, update.newPriceMantissa, update.updatedAt);
            updatedPricesCount += 1;
        }
    }

    modifier UpdatingTimeInPast(uint256 updatingTime) {
        _checkUpdatingTime(updatingTime);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract TwoStageOwnable {
    address public nominatedOwner;
    address public owner;

    event OwnerChanged(address indexed newOwner);
    event OwnerNominated(address indexed nominatedOwner);

    constructor(address owner_) internal {
        require(owner_ != address(0), "Owner cannot be zero address");
        _setOwner(owner_);
    }

    function acceptOwnership() external returns (bool success) {
        require(msg.sender == nominatedOwner, "Not nominated to ownership");
        _setOwner(nominatedOwner);
        nominatedOwner = address(0);
        return true;
    }

    function nominateNewOwner(address owner_) external onlyOwner returns (bool success) {
        _nominateNewOwner(owner_);
        return true;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Caller not owner");
        _;
    }

    function _nominateNewOwner(address owner_) internal {
        nominatedOwner = owner_;
        emit OwnerNominated(owner_);
    }

    function _setOwner(address newOwner) internal {
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface ICorroborativeToken is IERC20 {
    function decimals() external view returns (uint8);
    function underlying() external view returns (address);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

struct AttoDecimal {
    uint256 mantissa;
}

library AttoDecimalLib {
    using SafeMath for uint256;

    uint256 internal constant BASE = 10;
    uint256 internal constant EXPONENTIATION = 18;
    uint256 internal constant ONE_MANTISSA = BASE**EXPONENTIATION;
    uint256 internal constant SQUARED_ONE_MANTISSA = ONE_MANTISSA * ONE_MANTISSA;

    function convert(uint256 integer) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: integer.mul(ONE_MANTISSA)});
    }

    function add(AttoDecimal memory a, AttoDecimal memory b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mantissa.add(b.mantissa)});
    }

    function sub(AttoDecimal memory a, uint256 b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mantissa.sub(b.mul(ONE_MANTISSA))});
    }

    function sub(AttoDecimal memory a, AttoDecimal memory b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mantissa.sub(b.mantissa)});
    }

    function mul(AttoDecimal memory a, uint256 b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mantissa.mul(b)});
    }

    function div(uint256 a, uint256 b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mul(ONE_MANTISSA).div(b)});
    }

    function div(uint256 a, AttoDecimal memory b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mul(SQUARED_ONE_MANTISSA).div(b.mantissa)});
    }

    function div(AttoDecimal memory a, AttoDecimal memory b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mantissa.mul(ONE_MANTISSA).div(b.mantissa)});
    }

    function ceil(AttoDecimal memory a) internal pure returns (uint256) {
        return a.mantissa.div(ONE_MANTISSA).add(a.mantissa % ONE_MANTISSA > 0 ? 1 : 0);
    }

    function floor(AttoDecimal memory a) internal pure returns (uint256) {
        return a.mantissa.div(ONE_MANTISSA);
    }

    function lte(AttoDecimal memory a, AttoDecimal memory b) internal pure returns (bool) {
        return a.mantissa <= b.mantissa;
    }

    function toTuple(AttoDecimal memory a)
        internal
        pure
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        return (a.mantissa, BASE, EXPONENTIATION);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
        return div(a, b, "SafeMath: division by zero");
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return mod(a, b, "SafeMath: modulo by zero");
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

