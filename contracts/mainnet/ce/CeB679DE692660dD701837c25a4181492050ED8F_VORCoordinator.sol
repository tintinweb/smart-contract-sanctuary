/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IVORConsumerBase {
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external;
}

interface BlockHashStoreInterface {
    function getBlockhash(uint256 number) external view returns (bytes32);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20_Ex {
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
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
abstract contract ReentrancyGuard {
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

    constructor () internal {
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
}


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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () internal {
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

/**
 * @title VOR
 */
contract VOR {
    // See https://www.secg.org/sec2-v2.pdf, section 2.4.1, for these constants.
    uint256 private constant GROUP_ORDER = // Number of points in Secp256k1
        // solium-disable-next-line indentation
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    // Prime characteristic of the galois field over which Secp256k1 is defined
    uint256 private constant FIELD_SIZE =
        // solium-disable-next-line indentation
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 private constant WORD_LENGTH_BYTES = 0x20;

    // (base^exponent) % FIELD_SIZE
    // Cribbed from https://medium.com/@rbkhmrcr/precompiles-solidity-e5d29bd428c4
    function bigModExp(uint256 base, uint256 exponent) internal view returns (uint256 exponentiation) {
        uint256 callResult;
        uint256[6] memory bigModExpContractInputs;
        bigModExpContractInputs[0] = WORD_LENGTH_BYTES; // Length of base
        bigModExpContractInputs[1] = WORD_LENGTH_BYTES; // Length of exponent
        bigModExpContractInputs[2] = WORD_LENGTH_BYTES; // Length of modulus
        bigModExpContractInputs[3] = base;
        bigModExpContractInputs[4] = exponent;
        bigModExpContractInputs[5] = FIELD_SIZE;
        uint256[1] memory output;
        assembly {
            // solhint-disable-line no-inline-assembly
            callResult := staticcall(
                not(0), // Gas cost: no limit
                0x05, // Bigmodexp contract address
                bigModExpContractInputs,
                0xc0, // Length of input segment: 6*0x20-bytes
                output,
                0x20 // Length of output segment
            )
        }
        if (callResult == 0) {
            revert("bigModExp failure!");
        }
        return output[0];
    }

    // Let q=FIELD_SIZE. q % 4 = 3, ∴ x≡r^2 mod q ⇒ x^SQRT_POWER≡±r mod q.  See
    // https://en.wikipedia.org/wiki/Modular_square_root#Prime_or_prime_power_modulus
    uint256 private constant SQRT_POWER = (FIELD_SIZE + 1) >> 2;

    // Computes a s.t. a^2 = x in the field. Assumes a exists
    function squareRoot(uint256 x) internal view returns (uint256) {
        return bigModExp(x, SQRT_POWER);
    }

    // The value of y^2 given that (x,y) is on secp256k1.
    function ySquared(uint256 x) internal pure returns (uint256) {
        // Curve is y^2=x^3+7. See section 2.4.1 of https://www.secg.org/sec2-v2.pdf
        uint256 xCubed = mulmod(x, mulmod(x, x, FIELD_SIZE), FIELD_SIZE);
        return addmod(xCubed, 7, FIELD_SIZE);
    }

    // True iff p is on secp256k1
    function isOnCurve(uint256[2] memory p) internal pure returns (bool) {
        return ySquared(p[0]) == mulmod(p[1], p[1], FIELD_SIZE);
    }

    // Hash x uniformly into {0, ..., FIELD_SIZE-1}.
    function fieldHash(bytes memory b) internal pure returns (uint256 x_) {
        x_ = uint256(keccak256(b));
        // Rejecting if x >= FIELD_SIZE corresponds to step 2.1 in section 2.3.4 of
        // http://www.secg.org/sec1-v2.pdf , which is part of the definition of
        // string_to_point in the IETF draft
        while (x_ >= FIELD_SIZE) {
            x_ = uint256(keccak256(abi.encodePacked(x_)));
        }
    }

    // Hash b to a random point which hopefully lies on secp256k1.
    function newCandidateSecp256k1Point(bytes memory b) internal view returns (uint256[2] memory p) {
        p[0] = fieldHash(b);
        p[1] = squareRoot(ySquared(p[0]));
        if (p[1] % 2 == 1) {
            p[1] = FIELD_SIZE - p[1];
        }
    }

    // Domain-separation tag for initial hash in hashToCurve.
    uint256 constant HASH_TO_CURVE_HASH_PREFIX = 1;

    // Cryptographic hash function onto the curve.
    //
    // Corresponds to algorithm in section 5.4.1.1 of the draft standard. (But see
    // DESIGN NOTES above for slight differences.)
    //
    // TODO(alx): Implement a bounded-computation hash-to-curve, as described in
    // "Construction of Rational Points on Elliptic Curves over Finite Fields"
    // http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.831.5299&rep=rep1&type=pdf
    // and suggested by
    // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-01#section-5.2.2
    // (Though we can't used exactly that because secp256k1's j-invariant is 0.)
    //
    // This would greatly simplify the analysis in "OTHER SECURITY CONSIDERATIONS"
    // https://www.pivotaltracker.com/story/show/171120900
    function hashToCurve(uint256[2] memory pk, uint256 input) internal view returns (uint256[2] memory rv) {
        rv = newCandidateSecp256k1Point(abi.encodePacked(HASH_TO_CURVE_HASH_PREFIX, pk, input));
        while (!isOnCurve(rv)) {
            rv = newCandidateSecp256k1Point(abi.encodePacked(rv[0]));
        }
    }

    /** *********************************************************************
     * @notice Check that product==scalar*multiplicand
     *
     * @dev Based on Vitalik Buterin's idea in ethresear.ch post cited below.
     *
     * @param multiplicand: secp256k1 point
     * @param scalar: non-zero GF(GROUP_ORDER) scalar
     * @param product: secp256k1 expected to be multiplier * multiplicand
     * @return verifies true iff product==scalar*multiplicand, with cryptographically high probability
     */
    function ecmulVerify(
        uint256[2] memory multiplicand,
        uint256 scalar,
        uint256[2] memory product
    ) internal pure returns (bool verifies) {
        require(scalar != 0, "scalar must not be 0"); // Rules out an ecrecover failure case
        uint256 x = multiplicand[0]; // x ordinate of multiplicand
        uint8 v = multiplicand[1] % 2 == 0 ? 27 : 28; // parity of y ordinate
        // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
        // Point corresponding to address ecrecover(0, v, x, s=scalar*x) is
        // (x⁻¹ mod GROUP_ORDER) * (scalar * x * multiplicand - 0 * g), i.e.
        // scalar*multiplicand. See https://crypto.stackexchange.com/a/18106
        bytes32 scalarTimesX = bytes32(mulmod(scalar, x, GROUP_ORDER));
        address actual = ecrecover(bytes32(0), v, bytes32(x), scalarTimesX);
        // Explicit conversion to address takes bottom 160 bits
        address expected = address(uint256(keccak256(abi.encodePacked(product))));
        return (actual == expected);
    }

    // Returns x1/z1-x2/z2=(x1z2-x2z1)/(z1z2) in projective coordinates on P¹(𝔽ₙ)
    function projectiveSub(
        uint256 x1,
        uint256 z1,
        uint256 x2,
        uint256 z2
    ) internal pure returns (uint256 x3, uint256 z3) {
        uint256 num1 = mulmod(z2, x1, FIELD_SIZE);
        uint256 num2 = mulmod(FIELD_SIZE - x2, z1, FIELD_SIZE);
        (x3, z3) = (addmod(num1, num2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
    }

    // Returns x1/z1*x2/z2=(x1x2)/(z1z2), in projective coordinates on P¹(𝔽ₙ)
    function projectiveMul(
        uint256 x1,
        uint256 z1,
        uint256 x2,
        uint256 z2
    ) internal pure returns (uint256 x3, uint256 z3) {
        (x3, z3) = (mulmod(x1, x2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
    }

    /** **************************************************************************
      @notice Computes elliptic-curve sum, in projective co-ordinates

      @dev Using projective coordinates avoids costly divisions

      @dev To use this with p and q in affine coordinates, call
      @dev projectiveECAdd(px, py, qx, qy). This will return
      @dev the addition of (px, py, 1) and (qx, qy, 1), in the
      @dev secp256k1 group.

      @dev This can be used to calculate the z which is the inverse to zInv
      @dev in isValidVOROutput. But consider using a faster

      @dev This function assumes [px,py,1],[qx,qy,1] are valid projective
           coordinates of secp256k1 points. That is safe in this contract,
           because this method is only used by linearCombination, which checks
           points are on the curve via ecrecover.
      **************************************************************************
      @param px The first affine coordinate of the first summand
      @param py The second affine coordinate of the first summand
      @param qx The first affine coordinate of the second summand
      @param qy The second affine coordinate of the second summand

      (px,py) and (qx,qy) must be distinct, valid secp256k1 points.
      **************************************************************************
      Return values are projective coordinates of [px,py,1]+[qx,qy,1] as points
      on secp256k1, in P²(𝔽ₙ)
      @return sx 
      @return sy
      @return sz
  */
    function projectiveECAdd(
        uint256 px,
        uint256 py,
        uint256 qx,
        uint256 qy
    )
        internal
        pure
        returns (uint256 sx, uint256 sy, uint256 sz)
    {
        // See "Group law for E/K : y^2 = x^3 + ax + b", in section 3.1.2, p. 80,
        // "Guide to Elliptic Curve Cryptography" by Hankerson, Menezes and Vanstone
        // We take the equations there for (sx,sy), and homogenize them to
        // projective coordinates. That way, no inverses are required, here, and we
        // only need the one inverse in affineECAdd.

        // We only need the "point addition" equations from Hankerson et al. Can
        // skip the "point doubling" equations because p1 == p2 is cryptographically
        // impossible, and require'd not to be the case in linearCombination.

        // Add extra "projective coordinate" to the two points
        (uint256 z1, uint256 z2) = (1, 1);

        // (lx, lz) = (qy-py)/(qx-px), i.e., gradient of secant line.
        uint256 lx = addmod(qy, FIELD_SIZE - py, FIELD_SIZE);
        uint256 lz = addmod(qx, FIELD_SIZE - px, FIELD_SIZE);

        uint256 dx; // Accumulates denominator from sx calculation
        // sx=((qy-py)/(qx-px))^2-px-qx
        (sx, dx) = projectiveMul(lx, lz, lx, lz); // ((qy-py)/(qx-px))^2
        (sx, dx) = projectiveSub(sx, dx, px, z1); // ((qy-py)/(qx-px))^2-px
        (sx, dx) = projectiveSub(sx, dx, qx, z2); // ((qy-py)/(qx-px))^2-px-qx

        uint256 dy; // Accumulates denominator from sy calculation
        // sy=((qy-py)/(qx-px))(px-sx)-py
        (sy, dy) = projectiveSub(px, z1, sx, dx); // px-sx
        (sy, dy) = projectiveMul(sy, dy, lx, lz); // ((qy-py)/(qx-px))(px-sx)
        (sy, dy) = projectiveSub(sy, dy, py, z1); // ((qy-py)/(qx-px))(px-sx)-py

        if (dx != dy) {
            // Cross-multiply to put everything over a common denominator
            sx = mulmod(sx, dy, FIELD_SIZE);
            sy = mulmod(sy, dx, FIELD_SIZE);
            sz = mulmod(dx, dy, FIELD_SIZE);
        } else {
            // Already over a common denominator, use that for z ordinate
            sz = dx;
        }
    }

    // p1+p2, as affine points on secp256k1.
    //
    // invZ must be the inverse of the z returned by projectiveECAdd(p1, p2).
    // It is computed off-chain to save gas.
    //
    // p1 and p2 must be distinct, because projectiveECAdd doesn't handle
    // point doubling.
    function affineECAdd(
        uint256[2] memory p1,
        uint256[2] memory p2,
        uint256 invZ
    ) internal pure returns (uint256[2] memory) {
        uint256 x;
        uint256 y;
        uint256 z;
        (x, y, z) = projectiveECAdd(p1[0], p1[1], p2[0], p2[1]);
        require(mulmod(z, invZ, FIELD_SIZE) == 1, "invZ must be inverse of z");
        // Clear the z ordinate of the projective representation by dividing through
        // by it, to obtain the affine representation
        return [mulmod(x, invZ, FIELD_SIZE), mulmod(y, invZ, FIELD_SIZE)];
    }

    // True iff address(c*p+s*g) == lcWitness, where g is generator. (With
    // cryptographically high probability.)
    function verifyLinearCombinationWithGenerator(
        uint256 c,
        uint256[2] memory p,
        uint256 s,
        address lcWitness
    ) internal pure returns (bool) {
        // Rule out ecrecover failure modes which return address 0.
        require(lcWitness != address(0), "bad witness");
        uint8 v = (p[1] % 2 == 0) ? 27 : 28; // parity of y-ordinate of p
        bytes32 pseudoHash = bytes32(GROUP_ORDER - mulmod(p[0], s, GROUP_ORDER)); // -s*p[0]
        bytes32 pseudoSignature = bytes32(mulmod(c, p[0], GROUP_ORDER)); // c*p[0]
        // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
        // The point corresponding to the address returned by
        // ecrecover(-s*p[0],v,p[0],c*p[0]) is
        // (p[0]⁻¹ mod GROUP_ORDER)*(c*p[0]-(-s)*p[0]*g)=c*p+s*g.
        // See https://crypto.stackexchange.com/a/18106
        // https://bitcoin.stackexchange.com/questions/38351/ecdsa-v-r-s-what-is-v
        address computed = ecrecover(pseudoHash, v, bytes32(p[0]), pseudoSignature);
        return computed == lcWitness;
    }

    // c*p1 + s*p2. Requires cp1Witness=c*p1 and sp2Witness=s*p2. Also
    // requires cp1Witness != sp2Witness (which is fine for this application,
    // since it is cryptographically impossible for them to be equal. In the
    // (cryptographically impossible) case that a prover accidentally derives
    // a proof with equal c*p1 and s*p2, they should retry with a different
    // proof nonce.) Assumes that all points are on secp256k1
    // (which is checked in verifyVORProof below.)
    function linearCombination(
        uint256 c,
        uint256[2] memory p1,
        uint256[2] memory cp1Witness,
        uint256 s,
        uint256[2] memory p2,
        uint256[2] memory sp2Witness,
        uint256 zInv
    ) internal pure returns (uint256[2] memory) {
        require((cp1Witness[0] - sp2Witness[0]) % FIELD_SIZE != 0, "points in sum must be distinct");
        require(ecmulVerify(p1, c, cp1Witness), "First multiplication check failed");
        require(ecmulVerify(p2, s, sp2Witness), "Second multiplication check failed");
        return affineECAdd(cp1Witness, sp2Witness, zInv);
    }

    // Domain-separation tag for the hash taken in scalarFromCurvePoints.
    uint256 constant SCALAR_FROM_CURVE_POINTS_HASH_PREFIX = 2;

    // Pseudo-random number from inputs.
    // TODO(alx): We could save a bit of gas by following the standard here and
    // using the compressed representation of the points, if we collated the y
    // parities into a single bytes32.
    // https://www.pivotaltracker.com/story/show/171120588
    function scalarFromCurvePoints(
        uint256[2] memory hash,
        uint256[2] memory pk,
        uint256[2] memory gamma,
        address uWitness,
        uint256[2] memory v
    ) internal pure returns (uint256 s) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        SCALAR_FROM_CURVE_POINTS_HASH_PREFIX,
                        hash,
                        pk,
                        gamma,
                        v,
                        uWitness
                    )
                )
            );
    }

    // True if (gamma, c, s) is a correctly constructed randomness proof from pk
    // and seed. zInv must be the inverse of the third ordinate from
    // projectiveECAdd applied to cGammaWitness and sHashWitness. Corresponds to
    // section 5.3 of the IETF draft.
    //
    // TODO(alx): Since I'm only using pk in the ecrecover call, I could only pass
    // the x ordinate, and the parity of the y ordinate in the top bit of uWitness
    // (which I could make a uint256 without using any extra space.) Would save
    // about 2000 gas. https://www.pivotaltracker.com/story/show/170828567
    function verifyVORProof(
        uint256[2] memory pk,
        uint256[2] memory gamma,
        uint256 c,
        uint256 s,
        uint256 seed,
        address uWitness,
        uint256[2] memory cGammaWitness,
        uint256[2] memory sHashWitness,
        uint256 zInv
    ) internal view {
        require(isOnCurve(pk), "public key is not on curve");
        require(isOnCurve(gamma), "gamma is not on curve");
        require(isOnCurve(cGammaWitness), "cGammaWitness is not on curve");
        require(isOnCurve(sHashWitness), "sHashWitness is not on curve");
        require(verifyLinearCombinationWithGenerator(c, pk, s, uWitness), "addr(c*pk+s*g)≠_uWitness");
        // Step 4. of IETF draft section 5.3 (pk corresponds to Y, seed to alpha_string)
        uint256[2] memory hash = hashToCurve(pk, seed);
        // Step 6. of IETF draft section 5.3, but see note for step 5 about +/- terms
        uint256[2] memory v =
            linearCombination(
                c,
                gamma,
                cGammaWitness,
                s,
                hash,
                sHashWitness,
                zInv
            );
        // Steps 7. and 8. of IETF draft section 5.3
        uint256 derivedC = scalarFromCurvePoints(hash, pk, gamma, uWitness, v);
        require(c == derivedC, "invalid proof");
    }

    // Domain-separation tag for the hash used as the final VOR output.
    uint256 constant VOR_RANDOM_OUTPUT_HASH_PREFIX = 3;

    // Length of proof marshaled to bytes array. Shows layout of proof
    uint256 public constant PROOF_LENGTH =
        64 + // PublicKey (uncompressed format.)
        64 + // Gamma
        32 + // C
        32 + // S
        32 + // Seed
        0 +  // Dummy entry: The following elements are included for gas efficiency:
        32 + // uWitness (gets padded to 256 bits, even though it's only 160)
        64 + // cGammaWitness
        64 + // sHashWitness
        32;  // zInv  (Leave Output out, because that can be efficiently calculated)

    /* ***************************************************************************
   * @notice Returns proof's output, if proof is valid. Otherwise reverts

   * @param proof A binary-encoded proof
   *
   * Throws if proof is invalid, otherwise:
   * @return output i.e., the random output implied by the proof
   * ***************************************************************************
   * @dev See the calculation of PROOF_LENGTH for the binary layout of proof.
   */
    function randomValueFromVORProof(bytes memory proof) internal view returns (uint256 output) {
        require(proof.length == PROOF_LENGTH, "wrong proof length");

        uint256[2] memory pk; // parse proof contents into these variables
        uint256[2] memory gamma;
        // c, s and seed combined (prevents "stack too deep" compilation error)
        uint256[3] memory cSSeed;
        address uWitness;
        uint256[2] memory cGammaWitness;
        uint256[2] memory sHashWitness;
        uint256 zInv;

        (pk, gamma, cSSeed, uWitness, cGammaWitness, sHashWitness, zInv) =
            abi.decode(proof,
                (
                    uint256[2],
                    uint256[2],
                    uint256[3],
                    address,
                    uint256[2],
                    uint256[2],
                    uint256
                )
            );

        verifyVORProof(
            pk,
            gamma,
            cSSeed[0], // c
            cSSeed[1], // s
            cSSeed[2], // seed
            uWitness,
            cGammaWitness,
            sHashWitness,
            zInv
        );

        output = uint256(keccak256(abi.encode(VOR_RANDOM_OUTPUT_HASH_PREFIX, gamma)));
    }
}




/**
 * @title VORRequestIDBase
 */
contract VORRequestIDBase {
    /**
     * @notice returns the seed which is actually input to the VOR coordinator
     *
     * @dev To prevent repetition of VOR output due to repetition of the
     * @dev user-supplied seed, that seed is combined in a hash with the
     * @dev user-specific nonce, and the address of the consuming contract. The
     * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
     * @dev the final seed, but the nonce does protect against repetition in
     * @dev requests which are included in a single block.
     *
     * @param _userSeed VOR seed input provided by user
     * @param _requester Address of the requesting contract
     * @param _nonce User-specific nonce at the time of the request
     */
    function makeVORInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

    /**
     * @notice Returns the id for this request
     * @param _keyHash The serviceAgreement ID to be used for this request
     * @param _vORInputSeed The seed to be passed directly to the VOR
     * @return The id for this request
     *
     * @dev Note that _vORInputSeed is not the seed passed by the consuming
     * @dev contract, but the one generated by makeVORInputSeed
     */
    function makeRequestId(bytes32 _keyHash, uint256 _vORInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vORInputSeed));
    }
}


/**
 * @title VORCoordinator
 * @dev Coordinates on-chain verifiable-randomness requests
 */
contract VORCoordinator is Ownable, ReentrancyGuard, VOR, VORRequestIDBase {
    using SafeMath for uint256;
    using Address for address;

    IERC20_Ex internal xFUND;
    BlockHashStoreInterface internal blockHashStore;

    constructor(address _xfund, address _blockHashStore) public {
        xFUND = IERC20_Ex(_xfund);
        blockHashStore = BlockHashStoreInterface(_blockHashStore);
    }

    struct Callback {
        // Tracks an ongoing request
        address callbackContract; // Requesting contract, which will receive response
        // Amount of xFUND paid at request time. Total xFUND = 1e9 * 1e18 < 2^96, so
        // this representation is adequate, and saves a word of storage when this
        // field follows the 160-bit callbackContract address.
        uint96 randomnessFee;
        // Commitment to seed passed to oracle by this contract, and the number of
        // the block in which the request appeared. This is the keccak256 of the
        // concatenation of those values. Storing this commitment saves a word of
        // storage.
        bytes32 seedAndBlockNum;
    }

    struct ServiceAgreement {
        // Tracks oracle commitments to VOR service
        address payable vOROracle; // Oracle committing to respond with VOR service
        uint96 fee; // Minimum payment for oracle response. Total xFUND=1e9*1e18<2^96
        mapping(address => uint96) granularFees; // Per consumer fees if required
    }

    struct Consumer {
        uint256 amount;
        mapping(address => uint256) providers;
    }

    /* (provingKey, seed) */
    mapping(bytes32 => Callback) public callbacks;
    /* provingKey */
    mapping(bytes32 => ServiceAgreement) public serviceAgreements;
    /* oracle */
    /* xFUND balance */
    mapping(address => uint256) public withdrawableTokens;
    /* provingKey */
    /* consumer */
    mapping(bytes32 => mapping(address => uint256)) private nonces;

    event RandomnessRequest(
        bytes32 keyHash,
        uint256 seed,
        address sender,
        uint256 fee,
        bytes32 requestID
    );

    event NewServiceAgreement(bytes32 keyHash, uint256 fee);

    event ChangeFee(bytes32 keyHash, uint256 fee);
    event ChangeGranularFee(bytes32 keyHash, address consumer, uint256 fee);

    event RandomnessRequestFulfilled(bytes32 requestId, uint256 output);

    /**
     * @dev getProviderAddress - get provider address
     * @return address
     */
    function getProviderAddress(bytes32 _keyHash) external view returns (address) {
        return serviceAgreements[_keyHash].vOROracle;
    }

    /**
     * @dev getProviderFee - get provider's base fee
     * @return address
     */
    function getProviderFee(bytes32 _keyHash) external view returns (uint96) {
        return serviceAgreements[_keyHash].fee;
    }

    /**
     * @dev getProviderGranularFee - get provider's granular fee for selected consumer
     * @return address
     */
    function getProviderGranularFee(bytes32 _keyHash, address _consumer) external view returns (uint96) {
        if(serviceAgreements[_keyHash].granularFees[_consumer] > 0) {
            return serviceAgreements[_keyHash].granularFees[_consumer];
        } else {
            return serviceAgreements[_keyHash].fee;
        }
    }

    /**
     * @notice Commits calling address to serve randomness
     * @param _fee minimum xFUND payment required to serve randomness
     * @param _oracle the address of the node with the proving key
     * @param _publicProvingKey public key used to prove randomness
     */
    function registerProvingKey(
        uint256 _fee,
        address payable _oracle,
        uint256[2] calldata _publicProvingKey
    ) external {
        bytes32 keyHash = hashOfKey(_publicProvingKey);
        address oldVOROracle = serviceAgreements[keyHash].vOROracle;
        require(oldVOROracle == address(0), "please register a new key");
        require(_oracle != address(0), "_oracle must not be 0x0");
        serviceAgreements[keyHash].vOROracle = _oracle;

        require(_fee > 0, "fee cannot be zero");
        require(_fee <= 1e9 ether, "fee too high");
        serviceAgreements[keyHash].fee = uint96(_fee);
        emit NewServiceAgreement(keyHash, _fee);
    }

    /**
     * @notice Changes the provider's base fee
     * @param _publicProvingKey public key used to prove randomness
     * @param _fee minimum xFUND payment required to serve randomness
     */
    function changeFee(uint256[2] calldata _publicProvingKey, uint256 _fee) external {
        bytes32 keyHash = hashOfKey(_publicProvingKey);
        require(serviceAgreements[keyHash].vOROracle == _msgSender(), "only oracle can change the fee");
        require(_fee > 0, "fee cannot be zero");
        require(_fee <= 1e9 ether, "fee too high");
        serviceAgreements[keyHash].fee = uint96(_fee);
        emit ChangeFee(keyHash, _fee);
    }

    /**
     * @notice Changes the provider's fee for a consumer contract
     * @param _publicProvingKey public key used to prove randomness
     * @param _fee minimum xFUND payment required to serve randomness
     */
    function changeGranularFee(uint256[2] calldata _publicProvingKey, uint256 _fee, address _consumer) external {
        bytes32 keyHash = hashOfKey(_publicProvingKey);
        require(serviceAgreements[keyHash].vOROracle == _msgSender(), "only oracle can change the fee");
        require(_fee > 0, "fee cannot be zero");
        require(_fee <= 1e9 ether, "fee too high");
        serviceAgreements[keyHash].granularFees[_consumer] = uint96(_fee);
        emit ChangeGranularFee(keyHash, _consumer, _fee);
    }

    /**
     * @dev Allows the oracle operator to withdraw their xFUND
     * @param _recipient is the address the funds will be sent to
     * @param _amount is the amount of xFUND transferred from the Coordinator contract
     */
    function withdraw(address _recipient, uint256 _amount) external hasAvailableFunds(_amount) {
        withdrawableTokens[_msgSender()] = withdrawableTokens[_msgSender()].sub(_amount);
        assert(xFUND.transfer(_recipient, _amount));
    }

    /**
     * @notice creates the request for randomness
     *
     * @param _keyHash ID of the VOR public key against which to generate output
     * @param _consumerSeed Input to the VOR, from which randomness is generated
     * @param _feePaid Amount of xFUND sent with request. Must exceed fee for key
     *
     * @dev _consumerSeed is mixed with key hash, sender address and nonce to
     * @dev obtain preSeed, which is passed to VOR oracle, which mixes it with the
     * @dev hash of the block containing this request, to compute the final seed.
     *
     * @dev The requestId used to store the request data is constructed from the
     * @dev preSeed and keyHash.
     */
    function randomnessRequest(
        bytes32 _keyHash,
        uint256 _consumerSeed,
        uint256 _feePaid
    ) external sufficientXFUND(_feePaid, _keyHash) {
        require(address(_msgSender()).isContract(), "request can only be made by a contract");

        xFUND.transferFrom(_msgSender(), address(this), _feePaid);

        uint256 nonce = nonces[_keyHash][_msgSender()];
        uint256 preSeed = makeVORInputSeed(_keyHash, _consumerSeed, _msgSender(), nonce);
        bytes32 requestId = makeRequestId(_keyHash, preSeed);

        // Cryptographically guaranteed by preSeed including an increasing nonce
        assert(callbacks[requestId].callbackContract == address(0));
        callbacks[requestId].callbackContract = _msgSender();

        assert(_feePaid < 1e27); // Total xFUND fits in uint96
        callbacks[requestId].randomnessFee = uint96(_feePaid);

        callbacks[requestId].seedAndBlockNum = keccak256(abi.encodePacked(preSeed, block.number));
        emit RandomnessRequest(_keyHash, preSeed, _msgSender(), _feePaid, requestId);
        nonces[_keyHash][_msgSender()] = nonces[_keyHash][_msgSender()].add(1);
    }

    /**
     * @notice Returns the serviceAgreements key associated with this public key
     * @param _publicKey the key to return the address for
     */
    function hashOfKey(uint256[2] memory _publicKey) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_publicKey));
    }

    /**
     * @notice Called by the node to fulfill requests
     *
     * @param _proof the proof of randomness. Actual random output built from this
     */
    function fulfillRandomnessRequest(bytes memory _proof) public {
        (bytes32 currentKeyHash, Callback memory callback, bytes32 requestId, uint256 randomness) =
            getRandomnessFromProof(_proof);

        // Pay oracle
        address payable oracle = serviceAgreements[currentKeyHash].vOROracle;
        withdrawableTokens[oracle] = withdrawableTokens[oracle].add(callback.randomnessFee);

        // Forget request. Must precede callback (prevents reentrancy)
        delete callbacks[requestId];
        callBackWithRandomness(requestId, randomness, callback.callbackContract);

        emit RandomnessRequestFulfilled(requestId, randomness);
    }

    // Offsets into fulfillRandomnessRequest's _proof of various values
    //
    // Public key. Skips byte array's length prefix.
    uint256 public constant PUBLIC_KEY_OFFSET = 0x20;
    // Seed is 7th word in proof, plus word for length, (6+1)*0x20=0xe0
    uint256 public constant PRESEED_OFFSET = 0xe0;

    function callBackWithRandomness(bytes32 requestId, uint256 randomness, address consumerContract) internal {
        // Dummy variable; allows access to method selector in next line. See
        // https://github.com/ethereum/solidity/issues/3506#issuecomment-553727797
        IVORConsumerBase v;
        bytes memory resp = abi.encodeWithSelector(v.rawFulfillRandomness.selector, requestId, randomness);
        // The bound b here comes from https://eips.ethereum.org/EIPS/eip-150. The
        // actual gas available to the consuming contract will be b-floor(b/64).
        // This is chosen to leave the consuming contract ~200k gas, after the cost
        // of the call itself.
        uint256 b = 206000;
        require(gasleft() >= b, "not enough gas for consumer");
        // A low-level call is necessary, here, because we don't want the consuming
        // contract to be able to revert this execution, and thus deny the oracle
        // payment for a valid randomness response. This also necessitates the above
        // check on the gasleft, as otherwise there would be no indication if the
        // callback method ran out of gas.
        //
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = consumerContract.call(resp);
        // Avoid unused-local-variable warning. (success is only present to prevent
        // a warning that the return value of consumerContract.call is unused.)
        (success);
    }

    function getRandomnessFromProof(bytes memory _proof)
        internal
        view
        returns (
            bytes32 currentKeyHash,
            Callback memory callback,
            bytes32 requestId,
            uint256 randomness
        )
    {
        // blockNum follows proof, which follows length word (only direct-number
        // constants are allowed in assembly, so have to compute this in code)
        uint256 blocknumOffset = 0x20 + PROOF_LENGTH;
        // _proof.length skips the initial length word, so not including the
        // blocknum in this length check balances out.
        require(_proof.length == blocknumOffset, "wrong proof length");
        uint256[2] memory publicKey;
        uint256 preSeed;
        uint256 blockNum;
        assembly {
            // solhint-disable-line no-inline-assembly
            publicKey := add(_proof, PUBLIC_KEY_OFFSET)
            preSeed := mload(add(_proof, PRESEED_OFFSET))
            blockNum := mload(add(_proof, blocknumOffset))
        }
        currentKeyHash = hashOfKey(publicKey);
        requestId = makeRequestId(currentKeyHash, preSeed);
        callback = callbacks[requestId];
        require(callback.callbackContract != address(0), "no corresponding request");
        require(callback.seedAndBlockNum == keccak256(abi.encodePacked(preSeed, blockNum)), "wrong preSeed or block num");

        bytes32 blockHash = blockhash(blockNum);
        if (blockHash == bytes32(0)) {
            blockHash = blockHashStore.getBlockhash(blockNum);
            require(blockHash != bytes32(0), "please prove blockhash");
        }
        // The seed actually used by the VOR machinery, mixing in the blockhash
        uint256 actualSeed = uint256(keccak256(abi.encodePacked(preSeed, blockHash)));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Construct the actual proof from the remains of _proof
            mstore(add(_proof, PRESEED_OFFSET), actualSeed)
            mstore(_proof, PROOF_LENGTH)
        }
        randomness = VOR.randomValueFromVORProof(_proof); // Reverts on failure
    }

    /**
     * @dev Reverts if amount is not at least what was agreed upon in the service agreement
     * @param _feePaid The payment for the request
     * @param _keyHash The key which the request is for
     */
    modifier sufficientXFUND(uint256 _feePaid, bytes32 _keyHash) {
        if(serviceAgreements[_keyHash].granularFees[_msgSender()] > 0) {
            require(_feePaid >= serviceAgreements[_keyHash].granularFees[_msgSender()], "Below agreed payment");
        } else {
            require(_feePaid >= serviceAgreements[_keyHash].fee, "Below agreed payment");
        }
        _;
    }

    /**
     * @dev Reverts if amount requested is greater than withdrawable balance
     * @param _amount The given amount to compare to `withdrawableTokens`
     */
    modifier hasAvailableFunds(uint256 _amount) {
        require(withdrawableTokens[_msgSender()] >= _amount, "can't withdraw more than balance");
        _;
    }
}