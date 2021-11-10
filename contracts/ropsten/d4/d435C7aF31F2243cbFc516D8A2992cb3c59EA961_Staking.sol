// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CompoundRateKeeperV2.sol";
import "./IStaking.sol";

contract Staking is IStaking, CompoundRateKeeperV2 {
    /// @notice Staking token contract address.
    IERC20 public token;

    struct Stake {
        uint256 lastUpdate;
        uint256 amount;
        uint256 normalizedAmount;
    }

    /// @notice Staker address to staker info.
    mapping(address => Stake) public addressToStake;
    /// @notice Stake start timestamp.
    uint64 public startTimestamp;
    /// @notice Stake end timestamp.
    uint64 public endTimestamp;
    /// @notice Period when address can't withdraw after stake.
    uint64 public lockPeriod;

    uint256 aggregatedAmount;
    uint256 aggregatedNormalizedAmount;

    constructor(
        IERC20 _token,
        uint64 _startTimestamp,
        uint64 _endTimestamp,
        uint64 _lockPeriod
    ) {
        require(_endTimestamp > block.timestamp, "Staking: incorrect end timestamps.");
        require(_endTimestamp > _startTimestamp, "Staking: incorrect start timestamps.");

        token = _token;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        lockPeriod = _lockPeriod;
    }

    /// @notice Stake tokens to contract.
    /// @param _amount Stake amount
    function stake(uint256 _amount) external override returns (bool) {
        require(_amount > 0, "Staking: the amount cannot be a zero.");
        require(startTimestamp <= block.timestamp, "Staking: staking is not started.");
        require(endTimestamp >= block.timestamp, "Staking: staking is ended.");

        token.transferFrom(msg.sender, address(this), _amount);

        uint256 _compoundRate = getCompoundRate();
        uint256 _normalizedAmount = addressToStake[msg.sender].normalizedAmount;
        uint256 _newAmount;
        uint256 _newNormalizedAmount;

        if (_normalizedAmount > 0) {
            _newAmount = _getDenormalizedAmount(_normalizedAmount, _compoundRate) + _amount;
        } else {
            _newAmount = _amount;
        }
        _newNormalizedAmount = safeMul(_newAmount, _getDecimals(), _compoundRate);

        aggregatedAmount = aggregatedAmount - addressToStake[msg.sender].amount + _newAmount;
        aggregatedNormalizedAmount = aggregatedNormalizedAmount - _normalizedAmount + _newNormalizedAmount;

        addressToStake[msg.sender].amount = _newAmount;
        addressToStake[msg.sender].normalizedAmount = _newNormalizedAmount;
        addressToStake[msg.sender].lastUpdate = block.timestamp;

        return true;
    }

    /// @notice Withdraw tokens from stake.
    /// @param _holderAddress Staker address
    /// @param _withdrawAmount Tokens amount to withdraw
    function withdraw(address _holderAddress, uint256 _withdrawAmount) external override returns (bool) {
        require(_withdrawAmount > 0, "Staking: the amount cannot be a zero.");

        uint256 _compoundRate = getCompoundRate();
        uint256 _normalizedAmount = addressToStake[_holderAddress].normalizedAmount;
        uint256 _availableAmount = _getDenormalizedAmount(_normalizedAmount, _compoundRate);

        require(_availableAmount > 0, "Staking: available amount is zero.");
        require(
            addressToStake[_holderAddress].lastUpdate + lockPeriod < block.timestamp,
            "Staking: wait for the lockout period to expire."
        );

        if (_availableAmount < _withdrawAmount) _withdrawAmount = _availableAmount;

        uint256 _newAmount = _availableAmount - _withdrawAmount;
        uint256 _newNormalizedAmount = safeMul(_newAmount, _getDecimals(), _compoundRate);

        aggregatedAmount = aggregatedAmount - addressToStake[_holderAddress].amount + _newAmount;
        aggregatedNormalizedAmount = aggregatedNormalizedAmount - _normalizedAmount + _newNormalizedAmount;

        addressToStake[_holderAddress].amount = _newAmount;
        addressToStake[_holderAddress].normalizedAmount = _newNormalizedAmount;

        token.transfer(_holderAddress, _withdrawAmount);

        return true;
    }

    /// @notice Return amount of tokens + percents at this moment.
    /// @param _address Staker address
    function getDenormalizedAmount(address _address) external view override returns (uint256) {
        return _getDenormalizedAmount(addressToStake[_address].normalizedAmount, getCompoundRate());
    }

    /// @notice Return amount of tokens + percents at given timestamp.
    /// @param _address Staker address
    /// @param _timestamp Given timestamp (seconds)
    function getPotentialAmount(address _address, uint64 _timestamp) external view override returns (uint256) {
        return safeMul(addressToStake[_address].normalizedAmount, getPotentialCompoundRate(_timestamp), _getDecimals());
    }

    /// @notice Transfer tokens to contract as reward.
    /// @param _amount Token amount
    function supplyRewardPool(uint256 _amount) external override onlyOwner returns (bool) {
        return token.transferFrom(msg.sender, address(this), _amount);
    }

    /// @notice Return aggregated staked amount (without percents).
    function getAggregatedAmount() external view override onlyOwner returns (uint256) {
        return aggregatedAmount;
    }

    /// @notice Return aggregated normalized amount.
    function getAggregatedNormalizedAmount() external view override onlyOwner returns (uint256) {
        return aggregatedNormalizedAmount;
    }

    /// @notice Return coefficient in decimals. If coefficient more than 1, all holders will be able to receive awards.
    function monitorSecurityMargin() external view override onlyOwner returns (uint256) {
        uint256 _toWithdraw = safeMul(aggregatedNormalizedAmount, getCompoundRate(), _getDecimals());

        if (_toWithdraw == 0) return _getDecimals();
        return safeMul(token.balanceOf(address(this)), _getDecimals(), _toWithdraw);
    }

    /// @notice Transfer stuck ERC20 tokens.
    /// @param _token Token address
    /// @param _to Address 'to'
    /// @param _amount Token amount
    function transferStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner returns (bool) {
        if (address(token) == address(_token)) {
            uint256 _availableAmount = token.balanceOf(address(this)) -
                safeMul(aggregatedNormalizedAmount, getCompoundRate(), _getDecimals());
            _amount = _availableAmount < _amount ? _availableAmount : _amount;
        }

        return _token.transfer(_to, _amount);
    }

    /// @notice Reset compound rate to 1.
    function resetCompoundRate() external override {
        require(
            aggregatedAmount == 0,
            "Staking: there are holders in the contract, withdraw funds before resetting compound rate."
        );

        safeResetCompoundRate();
    }

    /// @dev Calculate denormalized amount.
    function _getDenormalizedAmount(uint256 _normalizedAmount, uint256 _compoundRate) private view returns (uint256) {
        return safeMul(_normalizedAmount, _compoundRate, _getDecimals());
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICompoundRateKeeperV2.sol";
import "./libraries/FullMath.sol";

/// @notice CompoundRateKeeperV2 contract.
contract CompoundRateKeeperV2 is Ownable, ICompoundRateKeeperV2 {
    /// @notice Contain actual compound rate.
    uint256 public compoundRate;
    /// @notice Contain last update of percentPerSecond value.
    uint64 public compoundRateLastUpdate;
    /// @notice Compound interest per second. ((1 + <interest_for_the_period> / 100)^(1 / <period>)) * 10^27
    /// @dev <interest_for_the_period> - 5% (5) if you want to get 5% for each period.
    /// @dev <period> - capitalization period in seconds.
    uint256 public percentPerSecond;

    constructor() {
        compoundRate = _getDecimals();
        percentPerSecond = _getDecimals();
        compoundRateLastUpdate = uint64(block.timestamp);
    }

    /// @notice Set percent per second, update compound rate and last compound rate update.
    /// @dev Call this function only when percent per period will change
    /// @param _newPercentPerSecond New percent per period
    function setPercentPerSecond(uint256 _newPercentPerSecond) external override onlyOwner {
        compoundRate = _calculatePotentialSafeCompoundRate(uint64(block.timestamp));
        compoundRateLastUpdate = uint64(block.timestamp);
        percentPerSecond = _newPercentPerSecond;

        emit PercentPerSecondUpdated(_newPercentPerSecond);
    }

    /// @notice Calculate compound rate for this moment.
    /// @dev Call this function always when you need actual compound rate.
    function getCompoundRate() public view override returns (uint256) {
        return _calculatePotentialSafeCompoundRate(uint64(block.timestamp));
    }

    /// @notice Calculate compound rate at a particular time.
    /// @dev Call this function always when you need compound rate at a particular time.
    function getPotentialCompoundRate(uint64 _timestamp) public view override returns (uint256) {
        return _calculatePotentialSafeCompoundRate(_timestamp);
    }

    /// @notice Calculate not safe compound rate. Can be reverted on big values.
    /// @dev Needed to reduce gas costs.
    /// @param _compoundRate Current compound rate
    /// @param _percentPerSecond Percents per seconds
    /// @param _timestamp Particular timestamp
    /// @param _compoundRateLastUpdate Last compound rate update
    function calculatePotentialCompoundRate(
        uint256 _compoundRate,
        uint256 _percentPerSecond,
        uint64 _timestamp,
        uint64 _compoundRateLastUpdate
    ) external pure override returns (uint256) {
        return
            (_compoundRate * FullMath.pow(_percentPerSecond, _timestamp - _compoundRateLastUpdate, _getDecimals())) /
            _getDecimals();
    }

    /// @notice Modulo exponentiation.
    /// @param _num Number
    /// @param _exponent Exponent
    /// @param _base (_num * _base). Base - precision index, is assumed to be _getDecimals()
    function pow(
        uint256 _num,
        uint256 _exponent,
        uint256 _base
    ) external pure override returns (uint256) {
        return FullMath.pow(_num, _exponent, _base);
    }

    /// @notice Multiply function. See FullMath library for details.
    /// @param _a Num 1
    /// @param _b Num 2
    /// @param _denominator (_a * _b / _denominator)
    function mul(
        uint256 _a,
        uint256 _b,
        uint256 _denominator
    ) external pure override returns (uint256) {
        return FullMath.mulDiv(_a, _b, _denominator);
    }

    /// @notice Reset compound rate to 1.
    function safeResetCompoundRate() internal {
        require(
            _calculatePotentialSafeCompoundRate(uint64(block.timestamp)) == 2**256 - 1,
            "CompoundRateKeeperV2: compound rate has not reached the limit values."
        );

        compoundRate = _getDecimals();
        compoundRateLastUpdate = uint64(block.timestamp);
    }

    /// @notice Safe compound rate calculation.
    /// @param _timestamp Calculated timestamp
    function _calculatePotentialSafeCompoundRate(uint64 _timestamp) private view returns (uint256) {
        uint256 _compoundRate = compoundRate;
        uint256 _percentPerSecond = percentPerSecond;
        uint64 _compoundRateLastUpdate = compoundRateLastUpdate;

        require(
            _timestamp >= _compoundRateLastUpdate,
            "CompoundRateKeeperV2: the compound rate last update timestamp is bigger than the calculated timestamp."
        );

        // Try to calculate compound rate with unsafe function to reduce gas costs, otherwise a safe calculation method is used
        try
            this.calculatePotentialCompoundRate(_compoundRate, _percentPerSecond, _timestamp, _compoundRateLastUpdate)
        returns (uint256 _res) {
            return _res;
        } catch {
            return
                safeMul(
                    _compoundRate,
                    _safePow(_percentPerSecond, _timestamp - _compoundRateLastUpdate, _getDecimals()),
                    _getDecimals()
                );
        }
    }

    /// @dev Safe modulo exponentiation.
    function _safePow(
        uint256 _num,
        uint256 _exponent,
        uint256 _base
    ) private view returns (uint256) {
        try this.pow(_num, _exponent, _base) returns (uint256 _res) {
            return _res;
        } catch {
            uint256 _halfExponent = _exponent - _exponent / 2;
            uint256 _resHalf = _safePow(_num, _halfExponent, _base);

            return safeMul(_resHalf, _resHalf, _base);
        }
    }

    /// @dev Safe multiply. Always returns (2 ** 256 - 1) if result value too big.
    function safeMul(
        uint256 _a,
        uint256 _b,
        uint256 _denominator
    ) internal view returns (uint256) {
        try this.mul(_a, _b, _denominator) returns (uint256 _res) {
            return _res;
        } catch {
            return 2**256 - 1;
        }
    }

    /// @dev Decimals for number.
    function _getDecimals() internal pure returns (uint256) {
        return 10**27;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICompoundRateKeeperV2.sol";

interface IStaking is ICompoundRateKeeperV2 {
    /// @notice Stake tokens to contract.
    /// @param _amount Stake amount
    function stake(uint256 _amount) external returns (bool);

    /// @notice Withdraw tokens from stake.
    /// @param _holderAddress Staker address
    /// @param _withdrawAmount Tokens amount to withdraw
    function withdraw(address _holderAddress, uint256 _withdrawAmount) external returns (bool);

    /// @notice Return amount of tokens + percents at this moment.
    /// @param _address Staker address
    function getDenormalizedAmount(address _address) external view returns (uint256);

    /// @notice Return amount of tokens + percents at given timestamp.
    /// @param _address Staker address
    /// @param _timestamp Given timestamp (seconds)
    function getPotentialAmount(address _address, uint64 _timestamp) external view returns (uint256);

    /// @notice Transfer tokens to contract as reward.
    /// @param _amount Token amount
    function supplyRewardPool(uint256 _amount) external returns (bool);

    /// @notice Return aggregated staked amount (without percents).
    function getAggregatedAmount() external view returns (uint256);

    /// @notice Return aggregated normalized amount.
    function getAggregatedNormalizedAmount() external view returns (uint256);

    /// @notice Return coefficient in decimals. If coefficient more than 1, all holders will be able to receive awards.
    function monitorSecurityMargin() external view returns (uint256);

    /// @notice Transfer stuck ERC20 tokens.
    /// @param _token Token address
    /// @param _to Address 'to'
    /// @param _amount Token amount
    function transferStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external returns (bool);

    /// @notice Reset compound rate to 1.
    function resetCompoundRate() external;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @notice Interface for CompoundRateKeeperV2 contract.
interface ICompoundRateKeeperV2 {
    /// @notice Emit on setPercentPerSecond().
    event PercentPerSecondUpdated(uint256 indexed percentPerSecond);

    /// @notice Set percent per second, update compound rate and last compound rate update.
    /// @dev Call this function only when percent per period will change
    /// @param _newPercentPerSecond New percent per period
    function setPercentPerSecond(uint256 _newPercentPerSecond) external;

    /// @notice Calculate compound rate for this moment.
    /// @dev Call this function always when you need actual compound rate.
    function getCompoundRate() external view returns (uint256);

    /// @notice Calculate compound rate at a particular time.
    /// @dev Call this function always when you need compound rate at a particular time.
    function getPotentialCompoundRate(uint64 _timestamp) external view returns (uint256);

    /// @notice Calculate not safe compound rate. Can be reverted on big values.
    /// @dev Needed to reduce gas costs.
    /// @param _compoundRate Current compound rate
    /// @param _percentPerSecond Percents per seconds
    /// @param _timestamp Particular timestamp
    /// @param _compoundRateLastUpdate Last compound rate update
    function calculatePotentialCompoundRate(
        uint256 _compoundRate,
        uint256 _percentPerSecond,
        uint64 _timestamp,
        uint64 _compoundRateLastUpdate
    ) external pure returns (uint256);

    /// @notice Modulo exponentiation.
    /// @param _num Number
    /// @param _exponent Exponent
    /// @param _base (_num * _base). Base - precision index, is assumed to be _getDecimals()
    function pow(
        uint256 _num,
        uint256 _exponent,
        uint256 _base
    ) external pure returns (uint256);

    /// @notice Multiply function. See FullMath library for details.
    /// @param _a Num 1
    /// @param _b Num 2
    /// @param _denominator (_a * _b / _denominator)
    function mul(
        uint256 _a,
        uint256 _b,
        uint256 _denominator
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (type(uint256).max - denominator + 1) & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
            prod0 := add(prod0, mul(prod1, twos))
        }

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        assembly {
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**8
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**16
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**32
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**64
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**128
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result := mul(prod0, inv)
        }

        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }

    /// @dev github.com/makerdao/dss implementation of exponentiation by squaring
    function pow(uint256 _num, uint256 _exponent, uint256 _base) internal pure returns (uint256 _res) {
        assembly {
            function power(x, n, b) -> z {
                switch x
                case 0 {
                    switch n
                    case 0 {
                        z := b
                    }
                    default {
                        z := 0
                    }
                }
                default {
                    switch mod(n, 2)
                    case 0 {
                        z := b
                    } default {
                        z := x
                    }

                    let half := div(b, 2)
                    for
                        { n := div(n, 2) }
                        n
                        { n := div(n, 2) }
                    {
                        let xx := mul(x, x)
                        if iszero(eq(div(xx, x), x)) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }

                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }

                            z := div(zxRound, b)
                        }
                    }
                }
            }

            _res := power(_num, _exponent, _base)
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