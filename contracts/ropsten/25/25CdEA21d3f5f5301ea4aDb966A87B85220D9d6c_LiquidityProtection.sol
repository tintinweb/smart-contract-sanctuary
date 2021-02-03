/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.6.0;

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

// File: @bancor/token-governance/contracts/IClaimable.sol


pragma solidity 0.6.12;

/// @title Claimable contract interface
interface IClaimable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function acceptOwnership() external;
}

// File: @bancor/token-governance/contracts/IMintableToken.sol


pragma solidity 0.6.12;



/// @title Mintable Token interface
interface IMintableToken is IERC20, IClaimable {
    function issue(address to, uint256 amount) external;

    function destroy(address from, uint256 amount) external;
}

// File: @bancor/token-governance/contracts/ITokenGovernance.sol


pragma solidity 0.6.12;


/// @title The interface for mintable/burnable token governance.
interface ITokenGovernance {
    // The address of the mintable ERC20 token.
    function token() external view returns (IMintableToken);

    /// @dev Mints new tokens.
    ///
    /// @param to Account to receive the new amount.
    /// @param amount Amount to increase the supply by.
    ///
    function mint(address to, uint256 amount) external;

    /// @dev Burns tokens from the caller.
    ///
    /// @param amount Amount to decrease the supply by.
    ///
    function burn(uint256 amount) external;
}

// File: solidity/contracts/utility/interfaces/ICheckpointStore.sol


pragma solidity 0.6.12;

/**
 * @dev Checkpoint store contract interface
 */
interface ICheckpointStore {
    function addCheckpoint(address _address) external;

    function addPastCheckpoint(address _address, uint256 _time) external;

    function addPastCheckpoints(address[] calldata _addresses, uint256[] calldata _times) external;

    function checkpoint(address _address) external view returns (uint256);
}

// File: solidity/contracts/utility/MathEx.sol


pragma solidity 0.6.12;

/**
 * @dev This library provides a set of complex math operations.
 */
library MathEx {
    /**
     * @dev returns the largest integer smaller than or equal to the square root of a positive integer
     *
     * @param _num a positive integer
     *
     * @return the largest integer smaller than or equal to the square root of the positive integer
     */
    function floorSqrt(uint256 _num) internal pure returns (uint256) {
        uint256 x = _num / 2 + 1;
        uint256 y = (x + _num / x) / 2;
        while (x > y) {
            x = y;
            y = (x + _num / x) / 2;
        }
        return x;
    }

    /**
     * @dev returns the smallest integer larger than or equal to the square root of a positive integer
     *
     * @param _num a positive integer
     *
     * @return the smallest integer larger than or equal to the square root of the positive integer
     */
    function ceilSqrt(uint256 _num) internal pure returns (uint256) {
        uint256 x = floorSqrt(_num);
        return x * x == _num ? x : x + 1;
    }

    /**
     * @dev computes a reduced-scalar ratio
     *
     * @param _n   ratio numerator
     * @param _d   ratio denominator
     * @param _max maximum desired scalar
     *
     * @return ratio's numerator and denominator
     */
    function reducedRatio(
        uint256 _n,
        uint256 _d,
        uint256 _max
    ) internal pure returns (uint256, uint256) {
        (uint256 n, uint256 d) = (_n, _d);
        if (n > _max || d > _max) {
            (n, d) = normalizedRatio(n, d, _max);
        }
        if (n != d) {
            return (n, d);
        }
        return (1, 1);
    }

    /**
     * @dev computes "scale * a / (a + b)" and "scale * b / (a + b)".
     */
    function normalizedRatio(
        uint256 _a,
        uint256 _b,
        uint256 _scale
    ) internal pure returns (uint256, uint256) {
        if (_a <= _b) {
            return accurateRatio(_a, _b, _scale);
        }
        (uint256 y, uint256 x) = accurateRatio(_b, _a, _scale);
        return (x, y);
    }

    /**
     * @dev computes "scale * a / (a + b)" and "scale * b / (a + b)", assuming that "a <= b".
     */
    function accurateRatio(
        uint256 _a,
        uint256 _b,
        uint256 _scale
    ) internal pure returns (uint256, uint256) {
        uint256 maxVal = uint256(-1) / _scale;
        if (_a > maxVal) {
            uint256 c = _a / (maxVal + 1) + 1;
            _a /= c; // we can now safely compute `_a * _scale`
            _b /= c;
        }
        if (_a != _b) {
            uint256 n = _a * _scale;
            uint256 d = _a + _b; // can overflow
            if (d >= _a) {
                // no overflow in `_a + _b`
                uint256 x = roundDiv(n, d); // we can now safely compute `_scale - x`
                uint256 y = _scale - x;
                return (x, y);
            }
            if (n < _b - (_b - _a) / 2) {
                return (0, _scale); // `_a * _scale < (_a + _b) / 2 < MAX_UINT256 < _a + _b`
            }
            return (1, _scale - 1); // `(_a + _b) / 2 < _a * _scale < MAX_UINT256 < _a + _b`
        }
        return (_scale / 2, _scale / 2); // allow reduction to `(1, 1)` in the calling function
    }

    /**
     * @dev computes the nearest integer to a given quotient without overflowing or underflowing.
     */
    function roundDiv(uint256 _n, uint256 _d) internal pure returns (uint256) {
        return _n / _d + (_n % _d) / (_d - _d / 2);
    }

    /**
     * @dev returns the average number of decimal digits in a given list of positive integers
     *
     * @param _values  list of positive integers
     *
     * @return the average number of decimal digits in the given list of positive integers
     */
    function geometricMean(uint256[] memory _values) internal pure returns (uint256) {
        uint256 numOfDigits = 0;
        uint256 length = _values.length;
        for (uint256 i = 0; i < length; i++) {
            numOfDigits += decimalLength(_values[i]);
        }
        return uint256(10)**(roundDivUnsafe(numOfDigits, length) - 1);
    }

    /**
     * @dev returns the number of decimal digits in a given positive integer
     *
     * @param _x   positive integer
     *
     * @return the number of decimal digits in the given positive integer
     */
    function decimalLength(uint256 _x) internal pure returns (uint256) {
        uint256 y = 0;
        for (uint256 x = _x; x > 0; x /= 10) {
            y++;
        }
        return y;
    }

    /**
     * @dev returns the nearest integer to a given quotient
     * the computation is overflow-safe assuming that the input is sufficiently small
     *
     * @param _n   quotient numerator
     * @param _d   quotient denominator
     *
     * @return the nearest integer to the given quotient
     */
    function roundDivUnsafe(uint256 _n, uint256 _d) internal pure returns (uint256) {
        return (_n + _d / 2) / _d;
    }

    /**
     * @dev returns the larger of two values
     *
     * @param _val1 the first value
     * @param _val2 the second value
     */
    function max(uint256 _val1, uint256 _val2) internal pure returns (uint256) {
        return _val1 > _val2 ? _val1 : _val2;
    }
}

// File: solidity/contracts/utility/ReentrancyGuard.sol


pragma solidity 0.6.12;

/**
 * @dev This contract provides protection against calling a function
 * (directly or indirectly) from within itself.
 */
contract ReentrancyGuard {
    uint256 private constant UNLOCKED = 1;
    uint256 private constant LOCKED = 2;

    // LOCKED while protected code is being executed, UNLOCKED otherwise
    uint256 private state = UNLOCKED;

    /**
     * @dev ensures instantiation only by sub-contracts
     */
    constructor() internal {}

    // protects a function against reentrancy attacks
    modifier protected() {
        _protected();
        state = LOCKED;
        _;
        state = UNLOCKED;
    }

    // error message binary size optimization
    function _protected() internal view {
        require(state == UNLOCKED, "ERR_REENTRANCY");
    }
}

// File: solidity/contracts/utility/interfaces/IOwned.sol


pragma solidity 0.6.12;

/*
    Owned contract interface
*/
interface IOwned {
    // this function isn't since the compiler emits automatically generated getter functions as external
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function acceptOwnership() external;
}

// File: solidity/contracts/utility/Owned.sol


pragma solidity 0.6.12;


/**
 * @dev This contract provides support and utilities for contract ownership.
 */
contract Owned is IOwned {
    address public override owner;
    address public newOwner;

    /**
     * @dev triggered when the owner is updated
     *
     * @param _prevOwner previous owner
     * @param _newOwner  new owner
     */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
     * @dev initializes a new Owned instance
     */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        _ownerOnly();
        _;
    }

    // error message binary size optimization
    function _ownerOnly() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    /**
     * @dev allows transferring the contract ownership
     * the new owner still needs to accept the transfer
     * can only be called by the contract owner
     *
     * @param _newOwner    new contract owner
     */
    function transferOwnership(address _newOwner) public override ownerOnly {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    /**
     * @dev used by a new owner to accept an ownership transfer
     */
    function acceptOwnership() public override {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: solidity/contracts/token/interfaces/IERC20Token.sol


pragma solidity 0.6.12;

/*
    ERC20 Standard Token interface
*/
interface IERC20Token {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);
}

// File: solidity/contracts/utility/TokenHandler.sol


pragma solidity 0.6.12;


contract TokenHandler {
    bytes4 private constant APPROVE_FUNC_SELECTOR = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant TRANSFER_FUNC_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant TRANSFER_FROM_FUNC_SELECTOR = bytes4(keccak256("transferFrom(address,address,uint256)"));

    /**
     * @dev executes the ERC20 token's `approve` function and reverts upon failure
     * the main purpose of this function is to prevent a non standard ERC20 token
     * from failing silently
     *
     * @param _token   ERC20 token address
     * @param _spender approved address
     * @param _value   allowance amount
     */
    function safeApprove(
        IERC20Token _token,
        address _spender,
        uint256 _value
    ) internal {
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(APPROVE_FUNC_SELECTOR, _spender, _value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ERR_APPROVE_FAILED");
    }

    /**
     * @dev executes the ERC20 token's `transfer` function and reverts upon failure
     * the main purpose of this function is to prevent a non standard ERC20 token
     * from failing silently
     *
     * @param _token   ERC20 token address
     * @param _to      target address
     * @param _value   transfer amount
     */
    function safeTransfer(
        IERC20Token _token,
        address _to,
        uint256 _value
    ) internal {
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(TRANSFER_FUNC_SELECTOR, _to, _value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ERR_TRANSFER_FAILED");
    }

    /**
     * @dev executes the ERC20 token's `transferFrom` function and reverts upon failure
     * the main purpose of this function is to prevent a non standard ERC20 token
     * from failing silently
     *
     * @param _token   ERC20 token address
     * @param _from    source address
     * @param _to      target address
     * @param _value   transfer amount
     */
    function safeTransferFrom(
        IERC20Token _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(TRANSFER_FROM_FUNC_SELECTOR, _from, _to, _value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ERR_TRANSFER_FROM_FAILED");
    }
}

// File: solidity/contracts/utility/Types.sol


pragma solidity 0.6.12;

/**
 * @dev This contract provides types which can be used by various contracts.
 */

struct Fraction {
    uint256 n; // numerator
    uint256 d; // denominator
}

// File: solidity/contracts/utility/Time.sol


pragma solidity 0.6.12;

/*
    Time implementing contract
*/
contract Time {
    /**
     * @dev returns the current time
     */
    function time() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

// File: solidity/contracts/utility/Utils.sol


pragma solidity 0.6.12;

/**
 * @dev Utilities & Common Modifiers
 */
contract Utils {
    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        _notThis(_address);
        _;
    }

    // error message binary size optimization
    function _notThis(address _address) internal view {
        require(_address != address(this), "ERR_ADDRESS_IS_SELF");
    }

    // validates an external address - currently only checks that it isn't null or this
    modifier validExternalAddress(address _address) {
        _validExternalAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validExternalAddress(address _address) internal view {
        require(_address != address(0) && _address != address(this), "ERR_INVALID_EXTERNAL_ADDRESS");
    }
}

// File: solidity/contracts/converter/interfaces/IConverterAnchor.sol


pragma solidity 0.6.12;


/*
    Converter Anchor interface
*/
interface IConverterAnchor is IOwned {

}

// File: solidity/contracts/token/interfaces/IDSToken.sol


pragma solidity 0.6.12;




/*
    DSToken interface
*/
interface IDSToken is IConverterAnchor, IERC20Token {
    function issue(address _to, uint256 _amount) external;

    function destroy(address _from, uint256 _amount) external;
}

// File: solidity/contracts/liquidity-protection/interfaces/ILiquidityProtectionStore.sol


pragma solidity 0.6.12;





/*
    Liquidity Protection Store interface
*/
interface ILiquidityProtectionStore is IOwned {
    function withdrawTokens(
        IERC20Token _token,
        address _to,
        uint256 _amount
    ) external;

    function protectedLiquidity(uint256 _id)
        external
        view
        returns (
            address,
            IDSToken,
            IERC20Token,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function addProtectedLiquidity(
        address _provider,
        IDSToken _poolToken,
        IERC20Token _reserveToken,
        uint256 _poolAmount,
        uint256 _reserveAmount,
        uint256 _reserveRateN,
        uint256 _reserveRateD,
        uint256 _timestamp
    ) external returns (uint256);

    function updateProtectedLiquidityAmounts(
        uint256 _id,
        uint256 _poolNewAmount,
        uint256 _reserveNewAmount
    ) external;

    function removeProtectedLiquidity(uint256 _id) external;

    function lockedBalance(address _provider, uint256 _index) external view returns (uint256, uint256);

    function lockedBalanceRange(
        address _provider,
        uint256 _startIndex,
        uint256 _endIndex
    ) external view returns (uint256[] memory, uint256[] memory);

    function addLockedBalance(
        address _provider,
        uint256 _reserveAmount,
        uint256 _expirationTime
    ) external returns (uint256);

    function removeLockedBalance(address _provider, uint256 _index) external;

    function systemBalance(IERC20Token _poolToken) external view returns (uint256);

    function incSystemBalance(IERC20Token _poolToken, uint256 _poolAmount) external;

    function decSystemBalance(IERC20Token _poolToken, uint256 _poolAmount) external;
}

// File: solidity/contracts/liquidity-protection/interfaces/ILiquidityProtectionStats.sol


pragma solidity 0.6.12;




/*
    Liquidity Protection Stats interface
*/
interface ILiquidityProtectionStats {
    function increaseTotalAmounts(
        address provider,
        IDSToken poolToken,
        IERC20Token reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;

    function decreaseTotalAmounts(
        address provider,
        IDSToken poolToken,
        IERC20Token reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;

    function addProviderPool(address provider, IDSToken poolToken) external returns (bool);

    function removeProviderPool(address provider, IDSToken poolToken) external returns (bool);

    function totalPoolAmount(IDSToken poolToken) external view returns (uint256);

    function totalReserveAmount(IDSToken poolToken, IERC20Token reserveToken) external view returns (uint256);

    function totalProviderAmount(
        address provider,
        IDSToken poolToken,
        IERC20Token reserveToken
    ) external view returns (uint256);

    function providerPools(address provider) external view returns (IDSToken[] memory);
}

// File: solidity/contracts/liquidity-protection/interfaces/ILiquidityProtectionSettings.sol


pragma solidity 0.6.12;


/*
    Liquidity Protection Store Settings interface
*/
interface ILiquidityProtectionSettings {
    function addPoolToWhitelist(IConverterAnchor _poolAnchor) external;

    function removePoolFromWhitelist(IConverterAnchor _poolAnchor) external;

    function isPoolWhitelisted(IConverterAnchor _poolAnchor) external view returns (bool);

    function poolWhitelist() external view returns (address[] memory);

    function isPoolSupported(IConverterAnchor _poolAnchor) external view returns (bool);

    function minNetworkTokenLiquidityForMinting() external view returns (uint256);

    function defaultNetworkTokenMintingLimit() external view returns (uint256);

    function networkTokenMintingLimits(IConverterAnchor _poolAnchor) external view returns (uint256);

    function networkTokensMinted(IConverterAnchor _poolAnchor) external view returns (uint256);

    function incNetworkTokensMinted(IConverterAnchor _poolAnchor, uint256 _amount) external;

    function decNetworkTokensMinted(IConverterAnchor _poolAnchor, uint256 _amount) external;

    function minProtectionDelay() external view returns (uint256);

    function maxProtectionDelay() external view returns (uint256);

    function setProtectionDelays(uint256 _minProtectionDelay, uint256 _maxProtectionDelay) external;

    function minNetworkCompensation() external view returns (uint256);

    function setMinNetworkCompensation(uint256 _minCompensation) external;

    function lockDuration() external view returns (uint256);

    function setLockDuration(uint256 _lockDuration) external;

    function averageRateMaxDeviation() external view returns (uint32);

    function setAverageRateMaxDeviation(uint32 _averageRateMaxDeviation) external;
}

// File: solidity/contracts/liquidity-protection/interfaces/ILiquidityProtectionSystemStore.sol


pragma solidity 0.6.12;



/*
    Liquidity Protection System Store interface
*/
interface ILiquidityProtectionSystemStore {
    function systemBalance(IERC20Token poolToken) external view returns (uint256);

    function incSystemBalance(IERC20Token poolToken, uint256 poolAmount) external;

    function decSystemBalance(IERC20Token poolToken, uint256 poolAmount) external;

    function networkTokensMinted(IConverterAnchor poolAnchor) external view returns (uint256);

    function incNetworkTokensMinted(IConverterAnchor poolAnchor, uint256 amount) external;

    function decNetworkTokensMinted(IConverterAnchor poolAnchor, uint256 amount) external;
}

// File: solidity/contracts/utility/interfaces/ITokenHolder.sol


pragma solidity 0.6.12;



/*
    Token Holder interface
*/
interface ITokenHolder is IOwned {
    function withdrawTokens(
        IERC20Token _token,
        address _to,
        uint256 _amount
    ) external;
}

// File: solidity/contracts/liquidity-protection/interfaces/ILiquidityProtection.sol


pragma solidity 0.6.12;








/*
    Liquidity Protection interface
*/
interface ILiquidityProtection {
    function store() external view returns (ILiquidityProtectionStore);

    function stats() external view returns (ILiquidityProtectionStats);

    function settings() external view returns (ILiquidityProtectionSettings);

    function systemStore() external view returns (ILiquidityProtectionSystemStore);

    function wallet() external view returns (ITokenHolder);

    function addLiquidityFor(
        address owner,
        IConverterAnchor poolAnchor,
        IERC20Token reserveToken,
        uint256 amount
    ) external payable returns (uint256);

    function addLiquidity(
        IConverterAnchor poolAnchor,
        IERC20Token reserveToken,
        uint256 amount
    ) external payable returns (uint256);

    function removeLiquidity(uint256 id, uint32 portion) external;
}

// File: solidity/contracts/liquidity-protection/interfaces/ILiquidityProtectionEventsSubscriber.sol


pragma solidity 0.6.12;



/**
 * @dev Liquidity protection events subscriber interface
 */
interface ILiquidityProtectionEventsSubscriber {
    function onAddingLiquidity(
        address provider,
        IConverterAnchor poolAnchor,
        IERC20Token reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;

    function onRemovingLiquidity(
        uint256 id,
        address provider,
        IConverterAnchor poolAnchor,
        IERC20Token reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;
}

// File: solidity/contracts/converter/interfaces/IConverter.sol


pragma solidity 0.6.12;




/*
    Converter interface
*/
interface IConverter is IOwned {
    function converterType() external pure returns (uint16);

    function anchor() external view returns (IConverterAnchor);

    function isActive() external view returns (bool);

    function targetAmountAndFee(
        IERC20Token _sourceToken,
        IERC20Token _targetToken,
        uint256 _amount
    ) external view returns (uint256, uint256);

    function convert(
        IERC20Token _sourceToken,
        IERC20Token _targetToken,
        uint256 _amount,
        address _trader,
        address payable _beneficiary
    ) external payable returns (uint256);

    function conversionFee() external view returns (uint32);

    function maxConversionFee() external view returns (uint32);

    function reserveBalance(IERC20Token _reserveToken) external view returns (uint256);

    receive() external payable;

    function transferAnchorOwnership(address _newOwner) external;

    function acceptAnchorOwnership() external;

    function setConversionFee(uint32 _conversionFee) external;

    function withdrawTokens(
        IERC20Token _token,
        address _to,
        uint256 _amount
    ) external;

    function withdrawETH(address payable _to) external;

    function addReserve(IERC20Token _token, uint32 _ratio) external;

    // deprecated, backward compatibility
    function token() external view returns (IConverterAnchor);

    function transferTokenOwnership(address _newOwner) external;

    function acceptTokenOwnership() external;

    function connectors(IERC20Token _address)
        external
        view
        returns (
            uint256,
            uint32,
            bool,
            bool,
            bool
        );

    function getConnectorBalance(IERC20Token _connectorToken) external view returns (uint256);

    function connectorTokens(uint256 _index) external view returns (IERC20Token);

    function connectorTokenCount() external view returns (uint16);

    /**
     * @dev triggered when the converter is activated
     *
     * @param _type        converter type
     * @param _anchor      converter anchor
     * @param _activated   true if the converter was activated, false if it was deactivated
     */
    event Activation(uint16 indexed _type, IConverterAnchor indexed _anchor, bool indexed _activated);

    /**
     * @dev triggered when a conversion between two tokens occurs
     *
     * @param _fromToken       source ERC20 token
     * @param _toToken         target ERC20 token
     * @param _trader          wallet that initiated the trade
     * @param _amount          input amount in units of the source token
     * @param _return          output amount minus conversion fee in units of the target token
     * @param _conversionFee   conversion fee in units of the target token
     */
    event Conversion(
        IERC20Token indexed _fromToken,
        IERC20Token indexed _toToken,
        address indexed _trader,
        uint256 _amount,
        uint256 _return,
        int256 _conversionFee
    );

    /**
     * @dev triggered when the rate between two tokens in the converter changes
     * note that the event might be dispatched for rate updates between any two tokens in the converter
     *
     * @param  _token1 address of the first token
     * @param  _token2 address of the second token
     * @param  _rateN  rate of 1 unit of `_token1` in `_token2` (numerator)
     * @param  _rateD  rate of 1 unit of `_token1` in `_token2` (denominator)
     */
    event TokenRateUpdate(IERC20Token indexed _token1, IERC20Token indexed _token2, uint256 _rateN, uint256 _rateD);

    /**
     * @dev triggered when the conversion fee is updated
     *
     * @param  _prevFee    previous fee percentage, represented in ppm
     * @param  _newFee     new fee percentage, represented in ppm
     */
    event ConversionFeeUpdate(uint32 _prevFee, uint32 _newFee);
}

// File: solidity/contracts/converter/interfaces/IConverterRegistry.sol


pragma solidity 0.6.12;



interface IConverterRegistry {
    function getAnchorCount() external view returns (uint256);

    function getAnchors() external view returns (address[] memory);

    function getAnchor(uint256 _index) external view returns (IConverterAnchor);

    function isAnchor(address _value) external view returns (bool);

    function getLiquidityPoolCount() external view returns (uint256);

    function getLiquidityPools() external view returns (address[] memory);

    function getLiquidityPool(uint256 _index) external view returns (IConverterAnchor);

    function isLiquidityPool(address _value) external view returns (bool);

    function getConvertibleTokenCount() external view returns (uint256);

    function getConvertibleTokens() external view returns (address[] memory);

    function getConvertibleToken(uint256 _index) external view returns (IERC20Token);

    function isConvertibleToken(address _value) external view returns (bool);

    function getConvertibleTokenAnchorCount(IERC20Token _convertibleToken) external view returns (uint256);

    function getConvertibleTokenAnchors(IERC20Token _convertibleToken) external view returns (address[] memory);

    function getConvertibleTokenAnchor(IERC20Token _convertibleToken, uint256 _index)
        external
        view
        returns (IConverterAnchor);

    function isConvertibleTokenAnchor(IERC20Token _convertibleToken, address _value) external view returns (bool);
}

// File: solidity/contracts/liquidity-protection/LiquidityProtection.sol


pragma solidity 0.6.12;



















interface ILiquidityPoolConverter is IConverter {
    function addLiquidity(
        IERC20Token[] memory _reserveTokens,
        uint256[] memory _reserveAmounts,
        uint256 _minReturn
    ) external payable;

    function removeLiquidity(
        uint256 _amount,
        IERC20Token[] memory _reserveTokens,
        uint256[] memory _reserveMinReturnAmounts
    ) external;

    function recentAverageRate(IERC20Token _reserveToken) external view returns (uint256, uint256);
}

/**
 * @dev This contract implements the liquidity protection mechanism.
 */
contract LiquidityProtection is ILiquidityProtection, TokenHandler, Utils, Owned, ReentrancyGuard, Time {
    using SafeMath for uint256;
    using MathEx for *;

    struct ProtectedLiquidity {
        address provider; // liquidity provider
        IDSToken poolToken; // pool token address
        IERC20Token reserveToken; // reserve token address
        uint256 poolAmount; // pool token amount
        uint256 reserveAmount; // reserve token amount
        uint256 reserveRateN; // rate of 1 protected reserve token in units of the other reserve token (numerator)
        uint256 reserveRateD; // rate of 1 protected reserve token in units of the other reserve token (denominator)
        uint256 timestamp; // timestamp
    }

    // various rates between the two reserve tokens. the rate is of 1 unit of the protected reserve token in units of the other reserve token
    struct PackedRates {
        uint128 addSpotRateN; // spot rate of 1 A in units of B when liquidity was added (numerator)
        uint128 addSpotRateD; // spot rate of 1 A in units of B when liquidity was added (denominator)
        uint128 removeSpotRateN; // spot rate of 1 A in units of B when liquidity is removed (numerator)
        uint128 removeSpotRateD; // spot rate of 1 A in units of B when liquidity is removed (denominator)
        uint128 removeAverageRateN; // average rate of 1 A in units of B when liquidity is removed (numerator)
        uint128 removeAverageRateD; // average rate of 1 A in units of B when liquidity is removed (denominator)
    }

    IERC20Token internal constant ETH_RESERVE_ADDRESS = IERC20Token(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint32 internal constant PPM_RESOLUTION = 1000000;
    uint256 internal constant MAX_UINT128 = 2**128 - 1;
    uint256 internal constant MAX_UINT256 = uint256(-1);

    ILiquidityProtectionSettings public immutable override settings;
    ILiquidityProtectionStore public immutable override store;
    ILiquidityProtectionStats public immutable override stats;
    ILiquidityProtectionSystemStore public immutable override systemStore;
    ITokenHolder public immutable override wallet;
    IERC20Token public immutable networkToken;
    ITokenGovernance public immutable networkTokenGovernance;
    IERC20Token public immutable govToken;
    ITokenGovernance public immutable govTokenGovernance;
    ICheckpointStore public immutable lastRemoveCheckpointStore;
    ILiquidityProtectionEventsSubscriber public eventsSubscriber;

    // true if the contract is currently adding/removing liquidity from a converter, used for accepting ETH
    bool private updatingLiquidity = false;

    /**
     * @dev updates the event subscriber
     *
     * @param _prevEventsSubscriber the previous events subscriber
     * @param _newEventsSubscriber the new events subscriber
     */
    event EventSubscriberUpdated(
        ILiquidityProtectionEventsSubscriber indexed _prevEventsSubscriber,
        ILiquidityProtectionEventsSubscriber indexed _newEventsSubscriber
    );

    /**
     * @dev initializes a new LiquidityProtection contract
     *
     * @param _contractAddresses:
     * - [0] liquidity protection settings
     * - [1] liquidity protection store
     * - [2] liquidity protection stats
     * - [3] liquidity protection system store
     * - [4] liquidity protection wallet
     * - [5] network token governance
     * - [6] governance token governance
     * - [7] last liquidity removal/unprotection checkpoints store
     */
    constructor(address[8] memory _contractAddresses) public {
        for (uint256 i = 0; i < _contractAddresses.length; i++) {
            _validAddress(_contractAddresses[i]);
        }

        settings = ILiquidityProtectionSettings(_contractAddresses[0]);
        store = ILiquidityProtectionStore(_contractAddresses[1]);
        stats = ILiquidityProtectionStats(_contractAddresses[2]);
        systemStore = ILiquidityProtectionSystemStore(_contractAddresses[3]);
        wallet = ITokenHolder(_contractAddresses[4]);
        networkTokenGovernance = ITokenGovernance(_contractAddresses[5]);
        govTokenGovernance = ITokenGovernance(_contractAddresses[6]);
        lastRemoveCheckpointStore = ICheckpointStore(_contractAddresses[7]);

        networkToken = IERC20Token(address(ITokenGovernance(_contractAddresses[5]).token()));
        govToken = IERC20Token(address(ITokenGovernance(_contractAddresses[6]).token()));
    }

    // ensures that the contract is currently removing liquidity from a converter
    modifier updatingLiquidityOnly() {
        require(updatingLiquidity, "ERR_NOT_UPDATING_LIQUIDITY");
        _;
    }

    // ensures that the portion is valid
    modifier validPortion(uint32 _portion) {
        _validPortion(_portion);
        _;
    }

    // error message binary size optimization
    function _validPortion(uint32 _portion) internal pure {
        require(_portion > 0 && _portion <= PPM_RESOLUTION, "ERR_INVALID_PORTION");
    }

    // ensures that the pool is supported and whitelisted
    modifier poolSupportedAndWhitelisted(IConverterAnchor _poolAnchor) {
        _poolSupported(_poolAnchor);
        _poolWhitelisted(_poolAnchor);
        _;
    }

    // error message binary size optimization
    function _poolSupported(IConverterAnchor _poolAnchor) internal view {
        require(settings.isPoolSupported(_poolAnchor), "ERR_POOL_NOT_SUPPORTED");
    }

    // error message binary size optimization
    function _poolWhitelisted(IConverterAnchor _poolAnchor) internal view {
        require(settings.isPoolWhitelisted(_poolAnchor), "ERR_POOL_NOT_WHITELISTED");
    }

    // error message binary size optimization
    function verifyEthAmount(uint256 _value) internal view {
        require(msg.value == _value, "ERR_ETH_AMOUNT_MISMATCH");
    }

    /**
     * @dev accept ETH
     * used when removing liquidity from ETH converters
     */
    receive() external payable updatingLiquidityOnly() {}

    /**
     * @dev transfers the ownership of the store
     * can only be called by the contract owner
     *
     * @param _newOwner    the new owner of the store
     */
    function transferStoreOwnership(address _newOwner) external ownerOnly {
        store.transferOwnership(_newOwner);
    }

    /**
     * @dev accepts the ownership of the store
     * can only be called by the contract owner
     */
    function acceptStoreOwnership() external ownerOnly {
        store.acceptOwnership();
    }

    /**
     * @dev transfers the ownership of the wallet
     * can only be called by the contract owner
     *
     * @param _newOwner    the new owner of the wallet
     */
    function transferWalletOwnership(address _newOwner) external ownerOnly {
        wallet.transferOwnership(_newOwner);
    }

    /**
     * @dev accepts the ownership of the wallet
     * can only be called by the contract owner
     */
    function acceptWalletOwnership() external ownerOnly {
        wallet.acceptOwnership();
    }

    /**
     * @dev migrates all funds from the store to the wallet
     * @dev migrates system balances from the store to the system-store
     * @dev migrates minted amounts from the settings to the system-store
     */
    function migrateData() external {
        // save local copies of storage variables
        address storeAddress = address(store);
        address walletAddress = address(wallet);
        IERC20Token networkTokenLocal = networkToken;

        address[] memory poolWhitelist = settings.poolWhitelist();
        for (uint256 i = 0; i < poolWhitelist.length; i++) {
            IERC20Token poolToken = IERC20Token(poolWhitelist[i]);
            store.withdrawTokens(poolToken, walletAddress, poolToken.balanceOf(storeAddress));
            uint256 systemBalance = store.systemBalance(poolToken);
            systemStore.incSystemBalance(poolToken, systemBalance);
            store.decSystemBalance(poolToken, systemBalance);
            uint256 networkTokensMinted = settings.networkTokensMinted(IConverterAnchor(address(poolToken)));
            systemStore.incNetworkTokensMinted(IConverterAnchor(address(poolToken)), networkTokensMinted);
            settings.decNetworkTokensMinted(IConverterAnchor(address(poolToken)), networkTokensMinted);
        }

        store.withdrawTokens(networkTokenLocal, walletAddress, networkTokenLocal.balanceOf(storeAddress));
    }

    /**
     * @dev sets the events subscriber
     */
    function setEventsSubscriber(ILiquidityProtectionEventsSubscriber _eventsSubscriber)
        external
        ownerOnly
        validAddress(address(_eventsSubscriber))
        notThis(address(_eventsSubscriber))
    {
        emit EventSubscriberUpdated(eventsSubscriber, _eventsSubscriber);

        eventsSubscriber = _eventsSubscriber;
    }

    /**
     * @dev adds protected liquidity to a pool for a specific recipient
     * also mints new governance tokens for the caller if the caller adds network tokens
     *
     * @param _owner       protected liquidity owner
     * @param _poolAnchor      anchor of the pool
     * @param _reserveToken    reserve token to add to the pool
     * @param _amount          amount of tokens to add to the pool
     * @return new protected liquidity id
     */
    function addLiquidityFor(
        address _owner,
        IConverterAnchor _poolAnchor,
        IERC20Token _reserveToken,
        uint256 _amount
    )
        external
        payable
        override
        protected
        validAddress(_owner)
        poolSupportedAndWhitelisted(_poolAnchor)
        greaterThanZero(_amount)
        returns (uint256)
    {
        return addLiquidity(_owner, _poolAnchor, _reserveToken, _amount);
    }

    /**
     * @dev adds protected liquidity to a pool
     * also mints new governance tokens for the caller if the caller adds network tokens
     *
     * @param _poolAnchor      anchor of the pool
     * @param _reserveToken    reserve token to add to the pool
     * @param _amount          amount of tokens to add to the pool
     * @return new protected liquidity id
     */
    function addLiquidity(
        IConverterAnchor _poolAnchor,
        IERC20Token _reserveToken,
        uint256 _amount
    )
        external
        payable
        override
        protected
        poolSupportedAndWhitelisted(_poolAnchor)
        greaterThanZero(_amount)
        returns (uint256)
    {
        return addLiquidity(msg.sender, _poolAnchor, _reserveToken, _amount);
    }

    /**
     * @dev adds protected liquidity to a pool for a specific recipient
     * also mints new governance tokens for the caller if the caller adds network tokens
     *
     * @param _owner       protected liquidity owner
     * @param _poolAnchor      anchor of the pool
     * @param _reserveToken    reserve token to add to the pool
     * @param _amount          amount of tokens to add to the pool
     * @return new protected liquidity id
     */
    function addLiquidity(
        address _owner,
        IConverterAnchor _poolAnchor,
        IERC20Token _reserveToken,
        uint256 _amount
    ) private returns (uint256) {
        // save a local copy of `networkToken`
        IERC20Token networkTokenLocal = networkToken;

        if (_reserveToken == networkTokenLocal) {
            verifyEthAmount(0);
            return addNetworkTokenLiquidity(_owner, _poolAnchor, networkTokenLocal, _amount);
        }

        // verify that ETH was passed with the call if needed
        verifyEthAmount(_reserveToken == ETH_RESERVE_ADDRESS ? _amount : 0);
        return addBaseTokenLiquidity(_owner, _poolAnchor, _reserveToken, networkTokenLocal, _amount);
    }

    /**
     * @dev adds protected network token liquidity to a pool
     * also mints new governance tokens for the caller
     *
     * @param _owner    protected liquidity owner
     * @param _poolAnchor   anchor of the pool
     * @param _networkToken the network reserve token of the pool
     * @param _amount       amount of tokens to add to the pool
     * @return new protected liquidity id
     */
    function addNetworkTokenLiquidity(
        address _owner,
        IConverterAnchor _poolAnchor,
        IERC20Token _networkToken,
        uint256 _amount
    ) internal returns (uint256) {
        IDSToken poolToken = IDSToken(address(_poolAnchor));

        // get the rate between the pool token and the reserve
        Fraction memory poolRate = poolTokenRate(poolToken, _networkToken);

        // calculate the amount of pool tokens based on the amount of reserve tokens
        uint256 poolTokenAmount = _amount.mul(poolRate.d).div(poolRate.n);

        // remove the pool tokens from the system's ownership (will revert if not enough tokens are available)
        systemStore.decSystemBalance(poolToken, poolTokenAmount);

        // add protected liquidity for the recipient
        uint256 id = addProtectedLiquidity(_owner, poolToken, _networkToken, poolTokenAmount, _amount);

        // burns the network tokens from the caller. we need to transfer the tokens to the contract itself, since only
        // token holders can burn their tokens
        safeTransferFrom(_networkToken, msg.sender, address(this), _amount);
        burnNetworkTokens(_poolAnchor, _amount);

        // mint governance tokens to the recipient
        govTokenGovernance.mint(_owner, _amount);

        return id;
    }

    /**
     * @dev adds protected base token liquidity to a pool
     *
     * @param _owner    protected liquidity owner
     * @param _poolAnchor   anchor of the pool
     * @param _baseToken    the base reserve token of the pool
     * @param _networkToken the network reserve token of the pool
     * @param _amount       amount of tokens to add to the pool
     * @return new protected liquidity id
     */
    function addBaseTokenLiquidity(
        address _owner,
        IConverterAnchor _poolAnchor,
        IERC20Token _baseToken,
        IERC20Token _networkToken,
        uint256 _amount
    ) internal returns (uint256) {
        IDSToken poolToken = IDSToken(address(_poolAnchor));

        // get the reserve balances
        ILiquidityPoolConverter converter = ILiquidityPoolConverter(payable(ownedBy(_poolAnchor)));
        (uint256 reserveBalanceBase, uint256 reserveBalanceNetwork) =
            converterReserveBalances(converter, _baseToken, _networkToken);

        require(reserveBalanceNetwork >= settings.minNetworkTokenLiquidityForMinting(), "ERR_NOT_ENOUGH_LIQUIDITY");

        // calculate and mint the required amount of network tokens for adding liquidity
        uint256 newNetworkLiquidityAmount = _amount.mul(reserveBalanceNetwork).div(reserveBalanceBase);

        // verify network token minting limit
        uint256 mintingLimit = settings.networkTokenMintingLimits(_poolAnchor);
        if (mintingLimit == 0) {
            mintingLimit = settings.defaultNetworkTokenMintingLimit();
        }

        uint256 newNetworkTokensMinted = systemStore.networkTokensMinted(_poolAnchor).add(newNetworkLiquidityAmount);
        require(newNetworkTokensMinted <= mintingLimit, "ERR_MAX_AMOUNT_REACHED");

        // issue new network tokens to the system
        mintNetworkTokens(address(this), _poolAnchor, newNetworkLiquidityAmount);

        // transfer the base tokens from the caller and approve the converter
        ensureAllowance(_networkToken, address(converter), newNetworkLiquidityAmount);
        if (_baseToken != ETH_RESERVE_ADDRESS) {
            safeTransferFrom(_baseToken, msg.sender, address(this), _amount);
            ensureAllowance(_baseToken, address(converter), _amount);
        }

        // add liquidity
        addLiquidity(converter, _baseToken, _networkToken, _amount, newNetworkLiquidityAmount, msg.value);

        // transfer the new pool tokens to the wallet
        uint256 poolTokenAmount = poolToken.balanceOf(address(this));
        safeTransfer(poolToken, address(wallet), poolTokenAmount);

        // the system splits the pool tokens with the caller
        // increase the system's pool token balance and add protected liquidity for the caller
        systemStore.incSystemBalance(poolToken, poolTokenAmount - poolTokenAmount / 2); // account for rounding errors
        return addProtectedLiquidity(_owner, poolToken, _baseToken, poolTokenAmount / 2, _amount);
    }

    /**
     * @dev returns the single-side staking limits of a given pool
     *
     * @param _poolAnchor   anchor of the pool
     * @return maximum amount of base tokens that can be single-side staked in the pool
     * @return maximum amount of network tokens that can be single-side staked in the pool
     */
    function poolAvailableSpace(IConverterAnchor _poolAnchor)
        external
        view
        poolSupportedAndWhitelisted(_poolAnchor)
        returns (uint256, uint256)
    {
        IERC20Token networkTokenLocal = networkToken;
        return (
            baseTokenAvailableSpace(_poolAnchor, networkTokenLocal),
            networkTokenAvailableSpace(_poolAnchor, networkTokenLocal)
        );
    }

    /**
     * @dev returns the base-token staking limits of a given pool
     *
     * @param _poolAnchor   anchor of the pool
     * @return maximum amount of base tokens that can be single-side staked in the pool
     */
    function baseTokenAvailableSpace(IConverterAnchor _poolAnchor)
        external
        view
        poolSupportedAndWhitelisted(_poolAnchor)
        returns (uint256)
    {
        return baseTokenAvailableSpace(_poolAnchor, networkToken);
    }

    /**
     * @dev returns the network-token staking limits of a given pool
     *
     * @param _poolAnchor   anchor of the pool
     * @return maximum amount of network tokens that can be single-side staked in the pool
     */
    function networkTokenAvailableSpace(IConverterAnchor _poolAnchor)
        external
        view
        poolSupportedAndWhitelisted(_poolAnchor)
        returns (uint256)
    {
        return networkTokenAvailableSpace(_poolAnchor, networkToken);
    }

    /**
     * @dev returns the base-token staking limits of a given pool
     *
     * @param _poolAnchor   anchor of the pool
     * @param _networkToken the network token
     * @return maximum amount of base tokens that can be single-side staked in the pool
     */
    function baseTokenAvailableSpace(IConverterAnchor _poolAnchor, IERC20Token _networkToken)
        internal
        view
        returns (uint256)
    {
        // get the pool converter
        ILiquidityPoolConverter converter = ILiquidityPoolConverter(payable(ownedBy(_poolAnchor)));

        // get the base token
        IERC20Token baseToken = converterOtherReserve(converter, _networkToken);

        // get the reserve balances
        (uint256 reserveBalanceBase, uint256 reserveBalanceNetwork) =
            converterReserveBalances(converter, baseToken, _networkToken);

        // get the network token minting limit
        uint256 mintingLimit = settings.networkTokenMintingLimits(_poolAnchor);
        if (mintingLimit == 0) {
            mintingLimit = settings.defaultNetworkTokenMintingLimit();
        }

        // get the amount of network tokens already minted for the pool
        uint256 networkTokensMinted = systemStore.networkTokensMinted(_poolAnchor);

        // get the amount of network tokens which can minted for the pool
        uint256 networkTokensCanBeMinted = MathEx.max(mintingLimit, networkTokensMinted) - networkTokensMinted;

        // return the maximum amount of base token liquidity that can be single-sided staked in the pool
        return networkTokensCanBeMinted.mul(reserveBalanceBase).div(reserveBalanceNetwork);
    }

    /**
     * @dev returns the network-token staking limits of a given pool
     *
     * @param _poolAnchor   anchor of the pool
     * @param _networkToken the network token
     * @return maximum amount of network tokens that can be single-side staked in the pool
     */
    function networkTokenAvailableSpace(IConverterAnchor _poolAnchor, IERC20Token _networkToken)
        internal
        view
        returns (uint256)
    {
        // get the pool token
        IDSToken poolToken = IDSToken(address(_poolAnchor));

        // get the pool token rate
        Fraction memory poolRate = poolTokenRate(poolToken, _networkToken);

        // return the maximum amount of network token liquidity that can be single-sided staked in the pool
        return systemStore.systemBalance(poolToken).mul(poolRate.n).add(poolRate.n).sub(1).div(poolRate.d);
    }

    /**
     * @dev returns the expected/actual amounts the provider will receive for removing liquidity
     * it's also possible to provide the remove liquidity time to get an estimation
     * for the return at that given point
     *
     * @param _id              protected liquidity id
     * @param _portion         portion of liquidity to remove, in PPM
     * @param _removeTimestamp time at which the liquidity is removed
     * @return expected return amount in the reserve token
     * @return actual return amount in the reserve token
     * @return compensation in the network token
     */
    function removeLiquidityReturn(
        uint256 _id,
        uint32 _portion,
        uint256 _removeTimestamp
    )
        external
        view
        validPortion(_portion)
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        ProtectedLiquidity memory liquidity = protectedLiquidity(_id);

        // verify input
        require(liquidity.provider != address(0), "ERR_INVALID_ID");
        require(_removeTimestamp >= liquidity.timestamp, "ERR_INVALID_TIMESTAMP");

        // calculate the portion of the liquidity to remove
        if (_portion != PPM_RESOLUTION) {
            liquidity.poolAmount = liquidity.poolAmount.mul(_portion) / PPM_RESOLUTION;
            liquidity.reserveAmount = liquidity.reserveAmount.mul(_portion) / PPM_RESOLUTION;
        }

        // get the various rates between the reserves upon adding liquidity and now
        PackedRates memory packedRates =
            packRates(
                liquidity.poolToken,
                liquidity.reserveToken,
                liquidity.reserveRateN,
                liquidity.reserveRateD,
                false
            );

        uint256 targetAmount =
            removeLiquidityTargetAmount(
                liquidity.poolToken,
                liquidity.reserveToken,
                liquidity.poolAmount,
                liquidity.reserveAmount,
                packedRates,
                liquidity.timestamp,
                _removeTimestamp
            );

        // for network token, the return amount is identical to the target amount
        if (liquidity.reserveToken == networkToken) {
            return (targetAmount, targetAmount, 0);
        }

        // handle base token return

        // calculate the amount of pool tokens required for liquidation
        // note that the amount is doubled since it's not possible to liquidate one reserve only
        Fraction memory poolRate = poolTokenRate(liquidity.poolToken, liquidity.reserveToken);
        uint256 poolAmount = targetAmount.mul(poolRate.d).div(poolRate.n / 2);

        // limit the amount of pool tokens by the amount the system/caller holds
        uint256 availableBalance = systemStore.systemBalance(liquidity.poolToken).add(liquidity.poolAmount);
        poolAmount = poolAmount > availableBalance ? availableBalance : poolAmount;

        // calculate the base token amount received by liquidating the pool tokens
        // note that the amount is divided by 2 since the pool amount represents both reserves
        uint256 baseAmount = poolAmount.mul(poolRate.n / 2).div(poolRate.d);
        uint256 networkAmount = getNetworkCompensation(targetAmount, baseAmount, packedRates);

        return (targetAmount, baseAmount, networkAmount);
    }

    /**
     * @dev removes protected liquidity from a pool
     * also burns governance tokens from the caller if the caller removes network tokens
     *
     * @param _id      id in the caller's list of protected liquidity
     * @param _portion portion of liquidity to remove, in PPM
     */
    function removeLiquidity(uint256 _id, uint32 _portion) external override protected validPortion(_portion) {
        removeLiquidity(msg.sender, _id, _portion);
    }

    /**
     * @dev removes protected liquidity from a pool
     * also burns governance tokens from the caller if the caller removes network tokens
     *
     * @param _provider protected liquidity provider
     * @param _id id in the caller's list of protected liquidity
     * @param _portion portion of liquidity to remove, in PPM
     */
    function removeLiquidity(
        address payable _provider,
        uint256 _id,
        uint32 _portion
    ) internal {
        ProtectedLiquidity memory liquidity = protectedLiquidity(_id, _provider);

        // save a local copy of `networkToken`
        IERC20Token networkTokenLocal = networkToken;

        // verify that the pool is whitelisted
        _poolWhitelisted(liquidity.poolToken);

        // verify that the protected liquidity is not removed on the same block in which it was added
        require(liquidity.timestamp < time(), "ERR_TOO_EARLY");

        if (_portion == PPM_RESOLUTION) {
            // notify event subscribers
            if (address(eventsSubscriber) != address(0)) {
                eventsSubscriber.onRemovingLiquidity(
                    _id,
                    _provider,
                    liquidity.poolToken,
                    liquidity.reserveToken,
                    liquidity.poolAmount,
                    liquidity.reserveAmount
                );
            }

            // remove the protected liquidity from the provider
            store.removeProtectedLiquidity(_id);
        } else {
            // remove a portion of the protected liquidity from the provider
            uint256 fullPoolAmount = liquidity.poolAmount;
            uint256 fullReserveAmount = liquidity.reserveAmount;
            liquidity.poolAmount = liquidity.poolAmount.mul(_portion) / PPM_RESOLUTION;
            liquidity.reserveAmount = liquidity.reserveAmount.mul(_portion) / PPM_RESOLUTION;

            // notify event subscribers
            if (address(eventsSubscriber) != address(0)) {
                eventsSubscriber.onRemovingLiquidity(
                    _id,
                    _provider,
                    liquidity.poolToken,
                    liquidity.reserveToken,
                    liquidity.poolAmount,
                    liquidity.reserveAmount
                );
            }

            store.updateProtectedLiquidityAmounts(
                _id,
                fullPoolAmount - liquidity.poolAmount,
                fullReserveAmount - liquidity.reserveAmount
            );
        }

        // update the statistics
        stats.decreaseTotalAmounts(
            liquidity.provider,
            liquidity.poolToken,
            liquidity.reserveToken,
            liquidity.poolAmount,
            liquidity.reserveAmount
        );

        // update last liquidity removal checkpoint
        lastRemoveCheckpointStore.addCheckpoint(_provider);

        // add the pool tokens to the system
        systemStore.incSystemBalance(liquidity.poolToken, liquidity.poolAmount);

        // if removing network token liquidity, burn the governance tokens from the caller. we need to transfer the
        // tokens to the contract itself, since only token holders can burn their tokens
        if (liquidity.reserveToken == networkTokenLocal) {
            safeTransferFrom(govToken, _provider, address(this), liquidity.reserveAmount);
            govTokenGovernance.burn(liquidity.reserveAmount);
        }

        // get the various rates between the reserves upon adding liquidity and now
        PackedRates memory packedRates =
            packRates(
                liquidity.poolToken,
                liquidity.reserveToken,
                liquidity.reserveRateN,
                liquidity.reserveRateD,
                true
            );

        // get the target token amount
        uint256 targetAmount =
            removeLiquidityTargetAmount(
                liquidity.poolToken,
                liquidity.reserveToken,
                liquidity.poolAmount,
                liquidity.reserveAmount,
                packedRates,
                liquidity.timestamp,
                time()
            );

        // remove network token liquidity
        if (liquidity.reserveToken == networkTokenLocal) {
            // mint network tokens for the caller and lock them
            mintNetworkTokens(address(wallet), liquidity.poolToken, targetAmount);
            lockTokens(_provider, targetAmount);
            return;
        }

        // remove base token liquidity

        // calculate the amount of pool tokens required for liquidation
        // note that the amount is doubled since it's not possible to liquidate one reserve only
        Fraction memory poolRate = poolTokenRate(liquidity.poolToken, liquidity.reserveToken);
        uint256 poolAmount = targetAmount.mul(poolRate.d).div(poolRate.n / 2);

        // limit the amount of pool tokens by the amount the system holds
        uint256 systemBalance = systemStore.systemBalance(liquidity.poolToken);
        poolAmount = poolAmount > systemBalance ? systemBalance : poolAmount;

        // withdraw the pool tokens from the wallet
        systemStore.decSystemBalance(liquidity.poolToken, poolAmount);
        wallet.withdrawTokens(liquidity.poolToken, address(this), poolAmount);

        // remove liquidity
        removeLiquidity(liquidity.poolToken, poolAmount, liquidity.reserveToken, networkTokenLocal);

        // transfer the base tokens to the caller
        uint256 baseBalance;
        if (liquidity.reserveToken == ETH_RESERVE_ADDRESS) {
            baseBalance = address(this).balance;
            _provider.transfer(baseBalance);
        } else {
            baseBalance = liquidity.reserveToken.balanceOf(address(this));
            safeTransfer(liquidity.reserveToken, _provider, baseBalance);
        }

        // compensate the caller with network tokens if still needed
        uint256 delta = getNetworkCompensation(targetAmount, baseBalance, packedRates);
        if (delta > 0) {
            // check if there's enough network token balance, otherwise mint more
            uint256 networkBalance = networkTokenLocal.balanceOf(address(this));
            if (networkBalance < delta) {
                networkTokenGovernance.mint(address(this), delta - networkBalance);
            }

            // lock network tokens for the caller
            safeTransfer(networkTokenLocal, address(wallet), delta);
            lockTokens(_provider, delta);
        }

        // if the contract still holds network tokens, burn them
        uint256 networkBalance = networkTokenLocal.balanceOf(address(this));
        if (networkBalance > 0) {
            burnNetworkTokens(liquidity.poolToken, networkBalance);
        }
    }

    /**
     * @dev returns the amount the provider will receive for removing liquidity
     * it's also possible to provide the remove liquidity rate & time to get an estimation
     * for the return at that given point
     *
     * @param _poolToken       pool token
     * @param _reserveToken    reserve token
     * @param _poolAmount      pool token amount when the liquidity was added
     * @param _reserveAmount   reserve token amount that was added
     * @param _packedRates     see `struct PackedRates`
     * @param _addTimestamp    time at which the liquidity was added
     * @param _removeTimestamp time at which the liquidity is removed
     * @return amount received for removing liquidity
     */
    function removeLiquidityTargetAmount(
        IDSToken _poolToken,
        IERC20Token _reserveToken,
        uint256 _poolAmount,
        uint256 _reserveAmount,
        PackedRates memory _packedRates,
        uint256 _addTimestamp,
        uint256 _removeTimestamp
    ) internal view returns (uint256) {
        // get the rate between the pool token and the reserve token
        Fraction memory poolRate = poolTokenRate(_poolToken, _reserveToken);

        // get the rate between the reserves upon adding liquidity and now
        Fraction memory addSpotRate = Fraction({ n: _packedRates.addSpotRateN, d: _packedRates.addSpotRateD });
        Fraction memory removeSpotRate = Fraction({ n: _packedRates.removeSpotRateN, d: _packedRates.removeSpotRateD });
        Fraction memory removeAverageRate =
            Fraction({ n: _packedRates.removeAverageRateN, d: _packedRates.removeAverageRateD });

        // calculate the protected amount of reserve tokens plus accumulated fee before compensation
        uint256 total = protectedAmountPlusFee(_poolAmount, poolRate, addSpotRate, removeSpotRate);

        // calculate the impermanent loss
        Fraction memory loss = impLoss(addSpotRate, removeAverageRate);

        // calculate the protection level
        Fraction memory level = protectionLevel(_addTimestamp, _removeTimestamp);

        // calculate the compensation amount
        return compensationAmount(_reserveAmount, MathEx.max(_reserveAmount, total), loss, level);
    }

    /**
     * @dev allows the caller to claim network token balance that is no longer locked
     * note that the function can revert if the range is too large
     *
     * @param _startIndex  start index in the caller's list of locked balances
     * @param _endIndex    end index in the caller's list of locked balances (exclusive)
     */
    function claimBalance(uint256 _startIndex, uint256 _endIndex) external protected {
        // get the locked balances from the store
        (uint256[] memory amounts, uint256[] memory expirationTimes) =
            store.lockedBalanceRange(msg.sender, _startIndex, _endIndex);

        uint256 totalAmount = 0;
        uint256 length = amounts.length;
        assert(length == expirationTimes.length);

        // reverse iteration since we're removing from the list
        for (uint256 i = length; i > 0; i--) {
            uint256 index = i - 1;
            if (expirationTimes[index] > time()) {
                continue;
            }

            // remove the locked balance item
            store.removeLockedBalance(msg.sender, _startIndex + index);
            totalAmount = totalAmount.add(amounts[index]);
        }

        if (totalAmount > 0) {
            // transfer the tokens to the caller in a single call
            wallet.withdrawTokens(networkToken, msg.sender, totalAmount);
        }
    }

    /**
     * @dev returns the ROI for removing liquidity in the current state after providing liquidity with the given args
     * the function assumes full protection is in effect
     * return value is in PPM and can be larger than PPM_RESOLUTION for positive ROI, 1M = 0% ROI
     *
     * @param _poolToken       pool token
     * @param _reserveToken    reserve token
     * @param _reserveAmount   reserve token amount that was added
     * @param _poolRateN       rate of 1 pool token in reserve token units when the liquidity was added (numerator)
     * @param _poolRateD       rate of 1 pool token in reserve token units when the liquidity was added (denominator)
     * @param _reserveRateN    rate of 1 reserve token in the other reserve token units when the liquidity was added (numerator)
     * @param _reserveRateD    rate of 1 reserve token in the other reserve token units when the liquidity was added (denominator)
     * @return ROI in PPM
     */
    function poolROI(
        IDSToken _poolToken,
        IERC20Token _reserveToken,
        uint256 _reserveAmount,
        uint256 _poolRateN,
        uint256 _poolRateD,
        uint256 _reserveRateN,
        uint256 _reserveRateD
    ) external view returns (uint256) {
        // calculate the amount of pool tokens based on the amount of reserve tokens
        uint256 poolAmount = _reserveAmount.mul(_poolRateD).div(_poolRateN);

        // get the various rates between the reserves upon adding liquidity and now
        PackedRates memory packedRates = packRates(_poolToken, _reserveToken, _reserveRateN, _reserveRateD, false);

        // get the current return
        uint256 protectedReturn =
            removeLiquidityTargetAmount(
                _poolToken,
                _reserveToken,
                poolAmount,
                _reserveAmount,
                packedRates,
                time().sub(settings.maxProtectionDelay()),
                time()
            );

        // calculate the ROI as the ratio between the current fully protected return and the initial amount
        return protectedReturn.mul(PPM_RESOLUTION).div(_reserveAmount);
    }

    /**
     * @dev adds protected liquidity for the caller to the store
     *
     * @param _provider        protected liquidity provider
     * @param _poolToken       pool token
     * @param _reserveToken    reserve token
     * @param _poolAmount      amount of pool tokens to protect
     * @param _reserveAmount   amount of reserve tokens to protect
     * @return new protected liquidity id
     */
    function addProtectedLiquidity(
        address _provider,
        IDSToken _poolToken,
        IERC20Token _reserveToken,
        uint256 _poolAmount,
        uint256 _reserveAmount
    ) internal returns (uint256) {
        // notify event subscribers
        if (address(eventsSubscriber) != address(0)) {
            eventsSubscriber.onAddingLiquidity(_provider, _poolToken, _reserveToken, _poolAmount, _reserveAmount);
        }

        Fraction memory rate = reserveTokenAverageRate(_poolToken, _reserveToken, true);
        stats.increaseTotalAmounts(_provider, _poolToken, _reserveToken, _poolAmount, _reserveAmount);
        stats.addProviderPool(_provider, _poolToken);
        return
            store.addProtectedLiquidity(
                _provider,
                _poolToken,
                _reserveToken,
                _poolAmount,
                _reserveAmount,
                rate.n,
                rate.d,
                time()
            );
    }

    /**
     * @dev locks network tokens for the provider and emits the tokens locked event
     *
     * @param _provider    tokens provider
     * @param _amount      amount of network tokens
     */
    function lockTokens(address _provider, uint256 _amount) internal {
        uint256 expirationTime = time().add(settings.lockDuration());
        store.addLockedBalance(_provider, _amount, expirationTime);
    }

    /**
     * @dev returns the rate of 1 pool token in reserve token units
     *
     * @param _poolToken       pool token
     * @param _reserveToken    reserve token
     */
    function poolTokenRate(IDSToken _poolToken, IERC20Token _reserveToken)
        internal
        view
        virtual
        returns (Fraction memory)
    {
        // get the pool token supply
        uint256 poolTokenSupply = _poolToken.totalSupply();

        // get the reserve balance
        IConverter converter = IConverter(payable(ownedBy(_poolToken)));
        uint256 reserveBalance = converter.getConnectorBalance(_reserveToken);

        // for standard pools, 50% of the pool supply value equals the value of each reserve
        return Fraction({ n: reserveBalance.mul(2), d: poolTokenSupply });
    }

    /**
     * @dev returns the average rate of 1 reserve token in the other reserve token units
     *
     * @param _poolToken            pool token
     * @param _reserveToken         reserve token
     * @param _validateAverageRate  true to validate the average rate; false otherwise
     */
    function reserveTokenAverageRate(
        IDSToken _poolToken,
        IERC20Token _reserveToken,
        bool _validateAverageRate
    ) internal view returns (Fraction memory) {
        (, , uint256 averageRateN, uint256 averageRateD) =
            reserveTokenRates(_poolToken, _reserveToken, _validateAverageRate);
        return Fraction(averageRateN, averageRateD);
    }

    /**
     * @dev returns the spot rate and average rate of 1 reserve token in the other reserve token units
     *
     * @param _poolToken            pool token
     * @param _reserveToken         reserve token
     * @param _validateAverageRate  true to validate the average rate; false otherwise
     */
    function reserveTokenRates(
        IDSToken _poolToken,
        IERC20Token _reserveToken,
        bool _validateAverageRate
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        ILiquidityPoolConverter converter = ILiquidityPoolConverter(payable(ownedBy(_poolToken)));
        IERC20Token otherReserve = converterOtherReserve(converter, _reserveToken);

        (uint256 spotRateN, uint256 spotRateD) = converterReserveBalances(converter, otherReserve, _reserveToken);
        (uint256 averageRateN, uint256 averageRateD) = converter.recentAverageRate(_reserveToken);

        require(
            !_validateAverageRate ||
                averageRateInRange(
                    spotRateN,
                    spotRateD,
                    averageRateN,
                    averageRateD,
                    settings.averageRateMaxDeviation()
                ),
            "ERR_INVALID_RATE"
        );

        return (spotRateN, spotRateD, averageRateN, averageRateD);
    }

    /**
     * @dev returns the various rates between the reserves
     *
     * @param _poolToken            pool token
     * @param _reserveToken         reserve token
     * @param _addSpotRateN         add spot rate numerator
     * @param _addSpotRateD         add spot rate denominator
     * @param _validateAverageRate  true to validate the average rate; false otherwise
     * @return see `struct PackedRates`
     */
    function packRates(
        IDSToken _poolToken,
        IERC20Token _reserveToken,
        uint256 _addSpotRateN,
        uint256 _addSpotRateD,
        bool _validateAverageRate
    ) internal view returns (PackedRates memory) {
        (uint256 removeSpotRateN, uint256 removeSpotRateD, uint256 removeAverageRateN, uint256 removeAverageRateD) =
            reserveTokenRates(_poolToken, _reserveToken, _validateAverageRate);

        require(
            (_addSpotRateN <= MAX_UINT128 && _addSpotRateD <= MAX_UINT128) &&
                (removeSpotRateN <= MAX_UINT128 && removeSpotRateD <= MAX_UINT128) &&
                (removeAverageRateN <= MAX_UINT128 && removeAverageRateD <= MAX_UINT128),
            "ERR_INVALID_RATE"
        );

        return
            PackedRates({
                addSpotRateN: uint128(_addSpotRateN),
                addSpotRateD: uint128(_addSpotRateD),
                removeSpotRateN: uint128(removeSpotRateN),
                removeSpotRateD: uint128(removeSpotRateD),
                removeAverageRateN: uint128(removeAverageRateN),
                removeAverageRateD: uint128(removeAverageRateD)
            });
    }

    /**
     * @dev returns whether or not the deviation of the average rate from the spot rate is within range
     * for example, if the maximum permitted deviation is 5%, then return `95/100 <= average/spot <= 100/95`
     *
     * @param _spotRateN       spot rate numerator
     * @param _spotRateD       spot rate denominator
     * @param _averageRateN    average rate numerator
     * @param _averageRateD    average rate denominator
     * @param _maxDeviation    the maximum permitted deviation of the average rate from the spot rate
     */
    function averageRateInRange(
        uint256 _spotRateN,
        uint256 _spotRateD,
        uint256 _averageRateN,
        uint256 _averageRateD,
        uint32 _maxDeviation
    ) internal pure returns (bool) {
        uint256 ppmDelta = PPM_RESOLUTION - _maxDeviation;
        uint256 min = _spotRateN.mul(_averageRateD).mul(ppmDelta).mul(ppmDelta);
        uint256 mid = _spotRateD.mul(_averageRateN).mul(ppmDelta).mul(PPM_RESOLUTION);
        uint256 max = _spotRateN.mul(_averageRateD).mul(PPM_RESOLUTION).mul(PPM_RESOLUTION);
        return min <= mid && mid <= max;
    }

    /**
     * @dev utility to add liquidity to a converter
     *
     * @param _converter       converter
     * @param _reserveToken1   reserve token 1
     * @param _reserveToken2   reserve token 2
     * @param _reserveAmount1  reserve amount 1
     * @param _reserveAmount2  reserve amount 2
     * @param _value           ETH amount to add
     */
    function addLiquidity(
        ILiquidityPoolConverter _converter,
        IERC20Token _reserveToken1,
        IERC20Token _reserveToken2,
        uint256 _reserveAmount1,
        uint256 _reserveAmount2,
        uint256 _value
    ) internal {
        // ensure that the contract can receive ETH
        updatingLiquidity = true;

        IERC20Token[] memory reserveTokens = new IERC20Token[](2);
        uint256[] memory amounts = new uint256[](2);
        reserveTokens[0] = _reserveToken1;
        reserveTokens[1] = _reserveToken2;
        amounts[0] = _reserveAmount1;
        amounts[1] = _reserveAmount2;
        _converter.addLiquidity{ value: _value }(reserveTokens, amounts, 1);

        // ensure that the contract can receive ETH
        updatingLiquidity = false;
    }

    /**
     * @dev utility to remove liquidity from a converter
     *
     * @param _poolToken       pool token of the converter
     * @param _poolAmount      amount of pool tokens to remove
     * @param _reserveToken1   reserve token 1
     * @param _reserveToken2   reserve token 2
     */
    function removeLiquidity(
        IDSToken _poolToken,
        uint256 _poolAmount,
        IERC20Token _reserveToken1,
        IERC20Token _reserveToken2
    ) internal {
        ILiquidityPoolConverter converter = ILiquidityPoolConverter(payable(ownedBy(_poolToken)));

        // ensure that the contract can receive ETH
        updatingLiquidity = true;

        IERC20Token[] memory reserveTokens = new IERC20Token[](2);
        uint256[] memory minReturns = new uint256[](2);
        reserveTokens[0] = _reserveToken1;
        reserveTokens[1] = _reserveToken2;
        minReturns[0] = 1;
        minReturns[1] = 1;
        converter.removeLiquidity(_poolAmount, reserveTokens, minReturns);

        // ensure that the contract can receive ETH
        updatingLiquidity = false;
    }

    /**
     * @dev returns a protected liquidity from the store
     *
     * @param _id  protected liquidity id
     * @return protected liquidity
     */
    function protectedLiquidity(uint256 _id) internal view returns (ProtectedLiquidity memory) {
        ProtectedLiquidity memory liquidity;
        (
            liquidity.provider,
            liquidity.poolToken,
            liquidity.reserveToken,
            liquidity.poolAmount,
            liquidity.reserveAmount,
            liquidity.reserveRateN,
            liquidity.reserveRateD,
            liquidity.timestamp
        ) = store.protectedLiquidity(_id);

        return liquidity;
    }

    /**
     * @dev returns a protected liquidity from the store
     *
     * @param _id          protected liquidity id
     * @param _provider    authorized provider
     * @return protected liquidity
     */
    function protectedLiquidity(uint256 _id, address _provider) internal view returns (ProtectedLiquidity memory) {
        ProtectedLiquidity memory liquidity = protectedLiquidity(_id);
        require(liquidity.provider == _provider, "ERR_ACCESS_DENIED");
        return liquidity;
    }

    /**
     * @dev returns the protected amount of reserve tokens plus accumulated fee before compensation
     *
     * @param _poolAmount      pool token amount when the liquidity was added
     * @param _poolRate        rate of 1 pool token in the related reserve token units
     * @param _addRate         rate of 1 reserve token in the other reserve token units when the liquidity was added
     * @param _removeRate      rate of 1 reserve token in the other reserve token units when the liquidity is removed
     * @return protected amount of reserve tokens plus accumulated fee = sqrt(_removeRate / _addRate) * _poolRate * _poolAmount
     */
    function protectedAmountPlusFee(
        uint256 _poolAmount,
        Fraction memory _poolRate,
        Fraction memory _addRate,
        Fraction memory _removeRate
    ) internal pure returns (uint256) {
        uint256 n = MathEx.ceilSqrt(_addRate.d.mul(_removeRate.n)).mul(_poolRate.n);
        uint256 d = MathEx.floorSqrt(_addRate.n.mul(_removeRate.d)).mul(_poolRate.d);

        uint256 x = n * _poolAmount;
        if (x / n == _poolAmount) {
            return x / d;
        }

        (uint256 hi, uint256 lo) = n > _poolAmount ? (n, _poolAmount) : (_poolAmount, n);
        (uint256 p, uint256 q) = MathEx.reducedRatio(hi, d, MAX_UINT256 / lo);
        uint256 min = (hi / d).mul(lo);

        if (q > 0) {
            return MathEx.max(min, (p * lo) / q);
        }
        return min;
    }

    /**
     * @dev returns the impermanent loss incurred due to the change in rates between the reserve tokens
     *
     * @param _prevRate    previous rate between the reserves
     * @param _newRate     new rate between the reserves
     * @return impermanent loss (as a ratio)
     */
    function impLoss(Fraction memory _prevRate, Fraction memory _newRate) internal pure returns (Fraction memory) {
        uint256 ratioN = _newRate.n.mul(_prevRate.d);
        uint256 ratioD = _newRate.d.mul(_prevRate.n);

        uint256 prod = ratioN * ratioD;
        uint256 root =
            prod / ratioN == ratioD ? MathEx.floorSqrt(prod) : MathEx.floorSqrt(ratioN) * MathEx.floorSqrt(ratioD);
        uint256 sum = ratioN.add(ratioD);

        // the arithmetic below is safe because `x + y >= sqrt(x * y) * 2`
        if (sum % 2 == 0) {
            sum /= 2;
            return Fraction({ n: sum - root, d: sum });
        }
        return Fraction({ n: sum - root * 2, d: sum });
    }

    /**
     * @dev returns the protection level based on the timestamp and protection delays
     *
     * @param _addTimestamp    time at which the liquidity was added
     * @param _removeTimestamp time at which the liquidity is removed
     * @return protection level (as a ratio)
     */
    function protectionLevel(uint256 _addTimestamp, uint256 _removeTimestamp) internal view returns (Fraction memory) {
        uint256 timeElapsed = _removeTimestamp.sub(_addTimestamp);
        uint256 minProtectionDelay = settings.minProtectionDelay();
        uint256 maxProtectionDelay = settings.maxProtectionDelay();
        if (timeElapsed < minProtectionDelay) {
            return Fraction({ n: 0, d: 1 });
        }

        if (timeElapsed >= maxProtectionDelay) {
            return Fraction({ n: 1, d: 1 });
        }

        return Fraction({ n: timeElapsed, d: maxProtectionDelay });
    }

    /**
     * @dev returns the compensation amount based on the impermanent loss and the protection level
     *
     * @param _amount  protected amount in units of the reserve token
     * @param _total   amount plus fee in units of the reserve token
     * @param _loss    protection level (as a ratio between 0 and 1)
     * @param _level   impermanent loss (as a ratio between 0 and 1)
     * @return compensation amount
     */
    function compensationAmount(
        uint256 _amount,
        uint256 _total,
        Fraction memory _loss,
        Fraction memory _level
    ) internal pure returns (uint256) {
        uint256 levelN = _level.n.mul(_amount);
        uint256 levelD = _level.d;
        uint256 maxVal = MathEx.max(MathEx.max(levelN, levelD), _total);
        (uint256 lossN, uint256 lossD) = MathEx.reducedRatio(_loss.n, _loss.d, MAX_UINT256 / maxVal);
        return _total.mul(lossD.sub(lossN)).div(lossD).add(lossN.mul(levelN).div(lossD.mul(levelD)));
    }

    function getNetworkCompensation(
        uint256 _targetAmount,
        uint256 _baseAmount,
        PackedRates memory _packedRates
    ) internal view returns (uint256) {
        if (_targetAmount <= _baseAmount) {
            return 0;
        }

        // calculate the delta in network tokens
        uint256 delta =
            (_targetAmount - _baseAmount).mul(_packedRates.removeAverageRateN).div(_packedRates.removeAverageRateD);

        // the delta might be very small due to precision loss
        // in which case no compensation will take place (gas optimization)
        if (delta >= settings.minNetworkCompensation()) {
            return delta;
        }

        return 0;
    }

    /**
     * @dev utility, checks whether allowance for the given spender exists and approves one if it doesn't.
     * note that we use the non standard erc-20 interface in which `approve` has no return value so that
     * this function will work for both standard and non standard tokens
     *
     * @param _token   token to check the allowance in
     * @param _spender approved address
     * @param _value   allowance amount
     */
    function ensureAllowance(
        IERC20Token _token,
        address _spender,
        uint256 _value
    ) private {
        uint256 allowance = _token.allowance(address(this), _spender);
        if (allowance < _value) {
            if (allowance > 0) safeApprove(_token, _spender, 0);
            safeApprove(_token, _spender, _value);
        }
    }

    // utility to mint network tokens
    function mintNetworkTokens(
        address _owner,
        IConverterAnchor _poolAnchor,
        uint256 _amount
    ) private {
        networkTokenGovernance.mint(_owner, _amount);
        systemStore.incNetworkTokensMinted(_poolAnchor, _amount);
    }

    // utility to burn network tokens
    function burnNetworkTokens(IConverterAnchor _poolAnchor, uint256 _amount) private {
        networkTokenGovernance.burn(_amount);
        systemStore.decNetworkTokensMinted(_poolAnchor, _amount);
    }

    // utility to get the reserve balances
    function converterReserveBalances(
        IConverter _converter,
        IERC20Token _reserveToken1,
        IERC20Token _reserveToken2
    ) private view returns (uint256, uint256) {
        return (_converter.getConnectorBalance(_reserveToken1), _converter.getConnectorBalance(_reserveToken2));
    }

    // utility to get the other reserve
    function converterOtherReserve(IConverter _converter, IERC20Token _thisReserve) private view returns (IERC20Token) {
        IERC20Token otherReserve = _converter.connectorTokens(0);
        return otherReserve != _thisReserve ? otherReserve : _converter.connectorTokens(1);
    }

    // utility to get the owner
    function ownedBy(IOwned _owned) private view returns (address) {
        return _owned.owner();
    }
}