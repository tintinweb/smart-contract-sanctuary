/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-13
*/

// File: contracts/interfaces/IBondCalculator.sol


pragma solidity 0.8.11;

interface IBondCalculator {
  function valuation(address _LP, uint256 _amount)
    external
    view
    returns (uint256);

  function markdown(address _LP) external view returns (uint256);
}

// File: contracts/interfaces/IStakingHelper.sol


pragma solidity 0.8.11;

interface IStakingHelper {
  function stake(uint256 _amount, address _recipient) external;
}

// File: contracts/interfaces/IStaking.sol


pragma solidity 0.8.11;

interface IStaking {
  function stake(uint256 _amount, address _recipient) external returns (bool);

  function claim(address _recipient) external;

  function unstake(uint256 _amount, address _recipient) external returns (bool);

  function index() external view returns (uint256);
}

// File: contracts/interfaces/ITreasury.sol


pragma solidity 0.8.11;

interface ITreasury {
  function deposit(
    uint256 _amount,
    address _token,
    uint256 _profit
  ) external returns (uint256 send_);

  function valueOf(address _token, uint256 _amount)
    external
    view
    returns (uint256 value_);

  function mintRewards(address _recipient, uint256 _amount) external;
}

// File: contracts/libraries/math/FullMath.sol



pragma solidity >=0.8.11;

// solhint-disable no-inline-assembly, reason-string, max-line-length

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
        unchecked {
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
            // EDIT for 0.8 compatibility:
            // see: https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint256
            uint256 twos = denominator & (~denominator + 1);

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
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
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
}
// File: contracts/libraries/math/FixedPoint.sol


pragma solidity 0.8.11;


library FixedPoint {
  struct uq112x112 {
    uint224 _x;
  }

  struct uq144x112 {
    uint256 _x;
  }

  uint8 private constant RESOLUTION = 112;
  uint256 private constant Q112 = 0x10000000000000000000000000000;
  uint256 private constant Q224 =
    0x100000000000000000000000000000000000000000000000000000000;
  uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

  function decode(uq112x112 memory self) internal pure returns (uint112) {
    return uint112(self._x >> RESOLUTION);
  }

  function decode112with18(uq112x112 memory self)
    internal
    pure
    returns (uint256)
  {
    return uint256(self._x) / 5192296858534827;
  }

  function fraction(uint256 numerator, uint256 denominator)
    internal
    pure
    returns (uq112x112 memory)
  {
    require(denominator > 0, "FixedPoint::fraction: division by zero");
    if (numerator == 0) return FixedPoint.uq112x112(0);

    if (numerator <= type(uint144).max) {
      uint256 result = (numerator << RESOLUTION) / denominator;
      require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    } else {
      uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
      require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    }
  }
}

// File: contracts/interfaces/ERC20/IERC20.sol


pragma solidity 0.8.11;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/libraries/helpers/RequiemErrors.sol


// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.11;

// solhint-disable
library RequiemErrors {
    /**
     * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
     * supported.
     */
    function _require(bool condition, uint256 errorCode) internal pure {
        if (!condition) RequiemErrors._revert(errorCode);
    }

    /**
     * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
     */
    function _revert(uint256 errorCode) internal pure {
        // We're going to dynamically create a revert string based on the error code, with the following format:
        // 'REQ#{errorCode}'
        // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
        //
        // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
        // number (8 to 16 bits) than the individual string characters.
        //
        // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
        // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
        // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
        assembly {
            // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
            // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
            // the '0' character.

            let units := add(mod(errorCode, 10), 0x30)

            errorCode := div(errorCode, 10)
            let tenths := add(mod(errorCode, 10), 0x30)

            errorCode := div(errorCode, 10)
            let hundreds := add(mod(errorCode, 10), 0x30)

            // With the individual characters, we can now construct the full string. The "REQ#" part is a known constant
            // (0x52455123): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
            // characters to it, each shifted by a multiple of 8.
            // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
            // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
            // array).

            let revertReason := shl(200, add(0x52455123000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

            // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
            // message will have the following layout:
            // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

            // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
            // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
            mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
            // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
            mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
            // The string length is fixed: 7 characters.
            mstore(0x24, 7)
            // Finally, the string itself is stored.
            mstore(0x44, revertReason)

            // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
            // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
            revert(0, 100)
        }
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;
    uint256 internal constant NOT_TWO_TOKENS = 210;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;
    uint256 internal constant AMP_END_TIME_TOO_CLOSE = 317;
    uint256 internal constant AMP_ONGOING_UPDATE = 318;
    uint256 internal constant AMP_RATE_TOO_HIGH = 319;
    uint256 internal constant AMP_NO_ONGOING_UPDATE = 320;
    uint256 internal constant STABLE_INVARIANT_DIDNT_CONVERGE = 321;
    uint256 internal constant STABLE_GET_BALANCE_DIDNT_CONVERGE = 322;
    uint256 internal constant RELAYER_NOT_CONTRACT = 323;
    uint256 internal constant BASE_POOL_RELAYER_NOT_CALLED = 324;
    uint256 internal constant REBALANCING_RELAYER_REENTERED = 325;
    uint256 internal constant GRADUAL_UPDATE_TIME_TRAVEL = 326;
    uint256 internal constant SWAPS_DISABLED = 327;
    uint256 internal constant CALLER_IS_NOT_LBP_OWNER = 328;
    uint256 internal constant PRICE_RATE_OVERFLOW = 329;
    uint256 internal constant INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED = 330;
    uint256 internal constant WEIGHT_CHANGE_TOO_FAST = 331;
    uint256 internal constant LOWER_GREATER_THAN_UPPER_TARGET = 332;
    uint256 internal constant UPPER_TARGET_TOO_HIGH = 333;
    uint256 internal constant UNHANDLED_BY_LINEAR_POOL = 334;
    uint256 internal constant OUT_OF_TARGET_RANGE = 335;
    uint256 internal constant UNHANDLED_EXIT_KIND = 336;
    uint256 internal constant UNAUTHORIZED_EXIT = 337;
    uint256 internal constant MAX_MANAGEMENT_SWAP_FEE_PERCENTAGE = 338;
    uint256 internal constant UNHANDLED_BY_MANAGED_POOL = 339;
    uint256 internal constant UNHANDLED_BY_PHANTOM_POOL = 340;
    uint256 internal constant TOKEN_DOES_NOT_HAVE_RATE_PROVIDER = 341;
    uint256 internal constant INVALID_INITIALIZATION = 342;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;
    uint256 internal constant CALLER_IS_NOT_OWNER = 426;
    uint256 internal constant NEW_OWNER_IS_ZERO = 427;
    uint256 internal constant CODE_DEPLOYMENT_FAILED = 428;
    uint256 internal constant CALL_TO_NON_CONTRACT = 429;
    uint256 internal constant LOW_LEVEL_CALL_FAILED = 430;
    uint256 internal constant NOT_PAUSED = 431;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
}

// File: contracts/libraries/SafeERC20.sol



// Based on the ReentrancyGuard library from OpenZeppelin Contracts, altered to reduce gas costs.
// The `safeTransfer` and `safeTransferFrom` functions assume that `token` is a contract (an account with code), and
// work differently from the OpenZeppelin version if it is not.

pragma solidity ^0.8.11;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   *
   * WARNING: `token` is assumed to be a contract: calls to EOAs will *not* revert.
   */
  function _callOptionalReturn(address token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves.
    (bool success, bytes memory returndata) = token.call(data);

    // If the low-level call didn't succeed we return whatever was returned from it.
    assembly {
      if eq(success, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Finally we check the returndata size is either zero or true - note that this check will always pass for EOAs
    RequiemErrors._require(
      returndata.length == 0 || abi.decode(returndata, (bool)),
      Errors.SAFE_ERC20_CALL_FAILED
    );
  }
}

// File: contracts/interfaces/IManageable.sol


pragma solidity 0.8.11;


interface IManageable {
  function policy() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}
// File: contracts/libraries/Manageable.sol



pragma solidity 0.8.11;


contract Manageable is IManageable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    modifier onlyManager() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyPolicy() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyPolicy() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}
// File: contracts/RequiemQBondDepository.sol



pragma solidity 0.8.11;








contract RequiemQBondDepository is Manageable {
  using FixedPoint for *;
  using SafeERC20 for IERC20;

  /* ======== EVENTS ======== */

  event BondCreated(
    uint256 deposit,
    uint256 indexed payout,
    uint256 indexed expires,
    uint256 indexed priceInUSD
  );
  event BondRedeemed(
    address indexed recipient,
    uint256 payout,
    uint256 remaining
  );
  event BondPriceChanged(
    uint256 indexed priceInUSD,
    uint256 indexed internalPrice,
    uint256 indexed debtRatio
  );
  event ControlVariableAdjustment(
    uint256 initialBCV,
    uint256 newBCV,
    uint256 adjustment,
    bool addition
  );

  /* ======== STATE VARIABLES ======== */

  address public immutable REQT; // token given as payment for bond
  address public immutable principle; // token used to create bond
  address public immutable treasury; // mints REQT when receives principle
  address public immutable DAO; // receives profit share from bond

  bool public immutable isLiquidityBond; // LP and Reserve bonds are treated slightly different
  address public immutable bondCalculator; // calculates value of LP tokens

  address public staking; // to auto-stake payout
  address public stakingHelper; // to stake and claim if no staking warmup
  bool public useHelper;

  Terms public terms; // stores terms for new bonds
  Adjust public adjustment; // stores adjustment to BCV data

  mapping(address => Bond) public bondInfo; // stores bond information for depositors

  uint256 public totalDebt; // total value of outstanding bonds; used for pricing
  uint256 public lastDecay; // reference block for debt decay

  /* ======== STRUCTS ======== */

  // Info for creating new bonds
  struct Terms {
    uint256 controlVariable; // scaling variable for price
    uint256 vestingTerm; // in blocks
    uint256 minimumPrice; // vs principle value
    uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
    uint256 fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
    uint256 maxDebt; // 9 decimal debt ratio, max % total supply created as debt
  }

  // Info for bond holder
  struct Bond {
    uint256 payout; // REQT remaining to be paid
    uint256 vesting; // Blocks left to vest
    uint256 lastBlock; // Last interaction
    uint256 pricePaid; // In DAI, for front end viewing
  }

  // Info for incremental adjustments to control variable
  struct Adjust {
    bool add; // addition or subtraction
    uint256 rate; // increment
    uint256 target; // BCV when adjustment finished
    uint256 buffer; // minimum length (in blocks) between adjustments
    uint256 lastBlock; // block when last adjustment made
  }

  /* ======== INITIALIZATION ======== */

  constructor(
    address _REQT,
    address _principle,
    address _treasury,
    address _DAO,
    address _bondCalculator
  ) {
    require(_REQT != address(0));
    REQT = _REQT;
    require(_principle != address(0));
    principle = _principle;
    require(_treasury != address(0));
    treasury = _treasury;
    require(_DAO != address(0));
    DAO = _DAO;
    // bondCalculator should be address(0) if not LP bond
    bondCalculator = _bondCalculator;
    isLiquidityBond = (_bondCalculator != address(0));
  }

  /**
   *  @notice initializes bond parameters
   *  @param _controlVariable uint
   *  @param _vestingTerm uint
   *  @param _minimumPrice uint
   *  @param _maxPayout uint
   *  @param _fee uint
   *  @param _maxDebt uint
   *  @param _initialDebt uint
   */
  function initializeBondTerms(
    uint256 _controlVariable,
    uint256 _vestingTerm,
    uint256 _minimumPrice,
    uint256 _maxPayout,
    uint256 _fee,
    uint256 _maxDebt,
    uint256 _initialDebt
  ) external onlyPolicy {
    require(terms.controlVariable == 0, "Bonds must be initialized from 0");
    terms = Terms({
      controlVariable: _controlVariable,
      vestingTerm: _vestingTerm,
      minimumPrice: _minimumPrice,
      maxPayout: _maxPayout,
      fee: _fee,
      maxDebt: _maxDebt
    });
    totalDebt = _initialDebt;
    lastDecay = block.number;
  }

  /* ======== POLICY FUNCTIONS ======== */

  enum PARAMETER {
    VESTING,
    PAYOUT,
    FEE,
    DEBT
  }

  /**
   *  @notice set parameters for new bonds
   *  @param _parameter PARAMETER
   *  @param _input uint
   */
  function setBondTerms(PARAMETER _parameter, uint256 _input)
    external
    onlyPolicy
  {
    if (_parameter == PARAMETER.VESTING) {
      // 0
      require(_input >= 10000, "Vesting must be longer than 36 hours");
      terms.vestingTerm = _input;
    } else if (_parameter == PARAMETER.PAYOUT) {
      // 1
      require(_input <= 1000, "Payout cannot be above 1 percent");
      terms.maxPayout = _input;
    } else if (_parameter == PARAMETER.FEE) {
      // 2
      require(_input <= 10000, "DAO fee cannot exceed payout");
      terms.fee = _input;
    } else if (_parameter == PARAMETER.DEBT) {
      // 3
      terms.maxDebt = _input;
    }
  }

  /**
   *  @notice set control variable adjustment
   *  @param _addition bool
   *  @param _increment uint
   *  @param _target uint
   *  @param _buffer uint
   */
  function setAdjustment(
    bool _addition,
    uint256 _increment,
    uint256 _target,
    uint256 _buffer
  ) external onlyPolicy {
    require(
      _increment <= (terms.controlVariable * 25) / 1000,
      "Increment too large"
    );

    adjustment = Adjust({
      add: _addition,
      rate: _increment,
      target: _target,
      buffer: _buffer,
      lastBlock: block.number
    });
  }

  /**
   *  @notice set contract for auto stake
   *  @param _staking address
   *  @param _helper bool
   */
  function setStaking(address _staking, bool _helper) external onlyPolicy {
    require(_staking != address(0));
    if (_helper) {
      useHelper = true;
      stakingHelper = _staking;
    } else {
      useHelper = false;
      staking = _staking;
    }
  }

  /* ======== USER FUNCTIONS ======== */

  /**
   *  @notice deposit bond
   *  @param _amount uint
   *  @param _maxPrice uint
   *  @param _depositor address
   *  @return uint
   */
  function deposit(
    uint256 _amount,
    uint256 _maxPrice,
    address _depositor
  ) external returns (uint256) {
    require(_depositor != address(0), "Invalid address");

    decayDebt();
    require(totalDebt <= terms.maxDebt, "Max capacity reached");

    uint256 priceInUSD = bondPriceInUSD(); // Stored in bond info
    uint256 nativePrice = _bondPrice();

    require(_maxPrice >= nativePrice, "Slippage limit: more than max price"); // slippage protection

    uint256 value = ITreasury(treasury).valueOf(principle, _amount);

    uint256 payout = payoutFor(value); // payout to bonder is computed

    require(payout >= 1e16, "Bond too small"); // must be > 0.01 REQT ( underflow protection )
    require(payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

    // profits are calculated
    uint256 fee = (payout * terms.fee) / 10000;
    require(value >= payout, "payout to large");
    uint256 profit = (value - payout) - fee;

    /**
            principle is transferred in
            approved and
            deposited into the treasury, returning (_amount - profit) REQT
         */
    IERC20(principle).safeTransferFrom(msg.sender, address(this), _amount);
    IERC20(principle).approve(address(treasury), _amount);
    ITreasury(treasury).deposit(_amount, principle, profit);

    if (fee != 0) {
      // fee is transferred to dao
      IERC20(REQT).safeTransfer(DAO, fee);
    }

    // total debt is increased
    totalDebt = totalDebt + value;

    // depositor info is stored
    bondInfo[_depositor] = Bond({
      payout: bondInfo[_depositor].payout + payout,
      vesting: terms.vestingTerm,
      lastBlock: block.number,
      pricePaid: priceInUSD
    });

    // indexed events are emitted
    emit BondCreated(
      _amount,
      payout,
      block.number + terms.vestingTerm,
      priceInUSD
    );
    emit BondPriceChanged(bondPriceInUSD(), _bondPrice(), debtRatio());

    adjust(); // control variable is adjusted
    return payout;
  }

  /**
   *  @notice redeem bond for user
   *  @param _recipient address
   *  @param _stake bool
   *  @return uint
   */
  function redeem(address _recipient, bool _stake) external returns (uint256) {
    Bond memory info = bondInfo[_recipient];
    uint256 percentVested = percentVestedFor(_recipient); // (blocks since last interaction / vesting term remaining)

    if (percentVested >= 10000) {
      // if fully vested
      delete bondInfo[_recipient]; // delete user info
      emit BondRedeemed(_recipient, info.payout, 0); // emit bond data
      return stakeOrSend(_recipient, _stake, info.payout); // pay user everything due
    } else {
      // if unfinished
      // calculate payout vested
      uint256 payout = (info.payout * percentVested) / 10000;

      // store updated deposit info
      bondInfo[_recipient] = Bond({
        payout: info.payout - payout,
        vesting: info.vesting - (block.number - info.lastBlock),
        lastBlock: block.number,
        pricePaid: info.pricePaid
      });

      emit BondRedeemed(_recipient, payout, bondInfo[_recipient].payout);
      return stakeOrSend(_recipient, _stake, payout);
    }
  }

  /* ======== INTERNAL HELPER FUNCTIONS ======== */

  /**
   *  @notice allow user to stake payout automatically
   *  @param _stake bool
   *  @param _amount uint
   *  @return uint
   */
  function stakeOrSend(
    address _recipient,
    bool _stake,
    uint256 _amount
  ) internal returns (uint256) {
    if (!_stake) {
      // if user does not want to stake
      IERC20(REQT).transfer(_recipient, _amount); // send payout
    } else {
      // if user wants to stake
      if (useHelper) {
        // use if staking warmup is 0
        IERC20(REQT).approve(stakingHelper, _amount);
        IStakingHelper(stakingHelper).stake(_amount, _recipient);
      } else {
        IERC20(REQT).approve(staking, _amount);
        IStaking(staking).stake(_amount, _recipient);
      }
    }
    return _amount;
  }

  /**
   *  @notice makes incremental adjustment to control variable
   */
  function adjust() internal {
    uint256 blockCanAdjust = adjustment.lastBlock + adjustment.buffer;
    if (adjustment.rate != 0 && block.number >= blockCanAdjust) {
      uint256 initial = terms.controlVariable;
      if (adjustment.add) {
        terms.controlVariable = terms.controlVariable + adjustment.rate;
        if (terms.controlVariable >= adjustment.target) {
          adjustment.rate = 0;
        }
      } else {
        terms.controlVariable = terms.controlVariable - adjustment.rate;
        if (terms.controlVariable <= adjustment.target) {
          adjustment.rate = 0;
        }
      }
      adjustment.lastBlock = block.number;
      emit ControlVariableAdjustment(
        initial,
        terms.controlVariable,
        adjustment.rate,
        adjustment.add
      );
    }
  }

  /**
   *  @notice reduce total debt
   */
  function decayDebt() internal {
    totalDebt -= debtDecay();
    lastDecay = block.number;
  }

  /* ======== VIEW FUNCTIONS ======== */

  /**
   *  @notice determine maximum bond size
   *  @return uint
   */
  function maxPayout() public view returns (uint256) {
    return (IERC20(REQT).totalSupply() * terms.maxPayout) / 100000;
  }

  /**
   *  @notice calculate interest due for new bond
   *  @param _value uint
   *  @return uint
   */
  function payoutFor(uint256 _value) public view returns (uint256) {
    return FixedPoint.fraction(_value, bondPrice()).decode112with18() / 1e16;
  }

  /**
   *  @notice calculate current bond premium
   *  @return price_ uint
   */
  function bondPrice() public view returns (uint256 price_) {
    price_ = (terms.controlVariable * debtRatio() + 1e18) / 1e16;
    if (price_ < terms.minimumPrice) {
      price_ = terms.minimumPrice;
    }
  }

  /**
   *  @notice calculate current bond price and remove floor if above
   *  @return price_ uint
   */
  function _bondPrice() internal returns (uint256 price_) {
    price_ = (terms.controlVariable * debtRatio() + 1e18) / 1e16;
    if (price_ < terms.minimumPrice) {
      price_ = terms.minimumPrice;
    } else if (terms.minimumPrice != 0) {
      terms.minimumPrice = 0;
    }
  }

  /**
   *  @notice converts bond price to DAI value
   *  @return price_ uint
   */
  function bondPriceInUSD() public view returns (uint256 price_) {
    if (isLiquidityBond) {
      price_ =
        (bondPrice() * IBondCalculator(bondCalculator).markdown(principle)) /
        100;
    } else {
      price_ = (bondPrice() * 10**IERC20(principle).decimals()) / 100;
    }
  }

  /**
   *  @notice calculate current ratio of debt to REQT supply
   *  @return debtRatio_ uint
   */
  function debtRatio() public view returns (uint256 debtRatio_) {
    uint256 supply = IERC20(REQT).totalSupply();
    debtRatio_ =
      FixedPoint.fraction(currentDebt() * 1e9, supply).decode112with18() /
      1e18;
  }

  /**
   *  @notice debt ratio in same terms for reserve or liquidity bonds
   *  @return uint
   */
  function standardizedDebtRatio() external view returns (uint256) {
    if (isLiquidityBond) {
      return
        (debtRatio() * IBondCalculator(bondCalculator).markdown(principle)) /
        10**IERC20(principle).decimals();
    } else {
      return debtRatio();
    }
  }

  /**
   *  @notice calculate debt factoring in decay
   *  @return uint
   */
  function currentDebt() public view returns (uint256) {
    return totalDebt - debtDecay();
  }

  /**
   *  @notice amount to decay total debt by
   *  @return decay_ uint
   */
  function debtDecay() public view returns (uint256 decay_) {
    uint256 blocksSinceLast = block.number - lastDecay;
    decay_ = (totalDebt * blocksSinceLast) / terms.vestingTerm;
    if (decay_ > totalDebt) {
      decay_ = totalDebt;
    }
  }

  /**
   *  @notice calculate how far into vesting a depositor is
   *  @param _depositor address
   *  @return percentVested_ uint
   */
  function percentVestedFor(address _depositor)
    public
    view
    returns (uint256 percentVested_)
  {
    Bond memory bond = bondInfo[_depositor];
    uint256 blocksSinceLast = block.number - bond.lastBlock;
    uint256 vesting = bond.vesting;

    if (vesting > 0) {
      percentVested_ = (blocksSinceLast * 10000) / vesting;
    } else {
      percentVested_ = 0;
    }
  }

  /**
   *  @notice calculate amount of REQT available for claim by depositor
   *  @param _depositor address
   *  @return pendingPayout_ uint
   */
  function pendingPayoutFor(address _depositor)
    external
    view
    returns (uint256 pendingPayout_)
  {
    uint256 percentVested = percentVestedFor(_depositor);
    uint256 payout = bondInfo[_depositor].payout;

    if (percentVested >= 10000) {
      pendingPayout_ = payout;
    } else {
      pendingPayout_ = (payout * percentVested) / 10000;
    }
  }

  // a view function that shows the full data at once
  function viewBondData()
    external
    view
    returns (
      uint256 _bondPrice_,
      uint256 _bondPriceInUsd_,
      uint256 _currentDebt_
    )
  {
    _currentDebt_ = totalDebt - debtDecay();

    _bondPrice_ = (terms.controlVariable * debtRatio() + 1000000000) / 1e7;
    if (_bondPrice_ < terms.minimumPrice) {
      _bondPrice_ = terms.minimumPrice;
    }

    if (isLiquidityBond) {
      _bondPriceInUsd_ =
        (bondPrice() * IBondCalculator(bondCalculator).markdown(principle)) /
        100;
    } else {
      _bondPriceInUsd_ = (bondPrice() * 10**IERC20(principle).decimals()) / 100;
    }
  }

  /* ======= AUXILLIARY ======= */

  /**
   *  @notice allow anyone to send lost tokens (excluding principle or REQT) to the DAO
   *  @return bool
   */
  function recoverLostToken(address _token) external returns (bool) {
    require(_token != REQT);
    require(_token != principle);
    IERC20(_token).safeTransfer(DAO, IERC20(_token).balanceOf(address(this)));
    return true;
  }
}