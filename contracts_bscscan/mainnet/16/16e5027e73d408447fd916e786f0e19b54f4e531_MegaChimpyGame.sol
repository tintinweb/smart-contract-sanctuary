/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

// SPDX-License-Identifier: UNLICENSED
// File: @openzeppelin/contracts/GSN/Context.sol

// 
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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// 
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// 
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

// 
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

// 
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

library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
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
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
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
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
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
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}


interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}


pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
contract MegaChimpyGame is Ownable, VRFConsumerBase{
    using SafeMath for uint;

    uint256 private randomResult;
    uint public ticketPrice = 0.01 * 10**18;
    bool public ticketSaleOpen = false;
    uint public actualTicketNumberId = 0;
    uint public actualMegaChimpyDrawId = 0;
    uint[] public possibleNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 
    30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50];
    uint[] public possibleChimpies = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    uint[] public winningNumbers = [5, 5, 5, 4, 4, 3, 4, 2, 3, 3, 1, 2, 2];
    uint[] public winningChimpies = [2, 1, 0, 2, 1, 2, 0, 2, 1, 0, 2, 1, 0];
    
    uint[] public winningPrizes = [0.275 * 10**18, 0.014355 * 10**18, 0.003355 * 10**18, 0.001045 * 10**18, 0.001925 * 10**18, 0.002035 * 10**18, 0.00143 * 10**18, 0.00715 * 10**18, 0.007975 * 10**18, 0.01485 * 10**18, 0.017985 * 10**18, 0.05665 * 10**18, 0.091245 * 10**18];
    uint[] public totalWinnersByPrizePosition = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    /*
    * VRF Variables
    */
    bytes32 internal keyHash = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c;
    uint256 internal fee = 0.1 * 10 ** 18;
    address private LinkToken = 0x404460C6A5EdE2D891e8297795264fDe62ADBB75;
    address private VRFCoordinator = 0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31;

    // Function to receive Ether. msg.data must be empty
    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    event BuyTicket(
            address indexed _from,
            bytes32 indexed _id,
            uint _value
    );

    event MegaChimpyDrawWinnerCombination(
            uint indexed _id,
            uint[]  numbersAndChimpies
    );

    event PayWinner(
            address indexed _from,
            bytes32 indexed _id,
            uint _value
    );

    struct MegaChimpyDraw {
        uint[] ticketsBoughtIds;
        uint[] numbersAndChimpies;
        uint totalParticipants;
        uint totalJackpot;
        uint openTimestamp;
        uint closeTimestamp;
    }

    struct Ticket {
        uint megaChimpyDrawId;
        address participantWalletAddress;
        uint[] betNumbers;
        uint[] betChimpies;
        uint ticketPrice;
        uint timestamp;
        bool hasPrize;
        uint prizePosition;
        uint prizeToBePaid;
        bool claimedPrize;
    }

    mapping (uint => MegaChimpyDraw) megaChimpyDrawHistory;
    mapping (uint => Ticket) ticketsBought;
    uint[] public megaChimpyDrawHistoryIds;
    uint[] public ticketsBoughtIds;

    constructor() public VRFConsumerBase(VRFCoordinator, LinkToken){
    }
    
    /* General Getters */

    function getTicketsBought() view public returns (uint[] memory) {
        return ticketsBoughtIds;
    }

    function getTicketBoughtInformation(uint ticketId) view public returns (uint, address, uint[] memory, uint[] memory, uint, uint) {
        return (ticketsBought[ticketId].megaChimpyDrawId, ticketsBought[ticketId].participantWalletAddress, ticketsBought[ticketId].betNumbers, ticketsBought[ticketId].betChimpies, ticketsBought[ticketId].ticketPrice, ticketsBought[ticketId].timestamp);
    }

    function getMegaChimpyDrawHistory() view public returns (uint[] memory) {
        return megaChimpyDrawHistoryIds;
    }

    function getMegaChimpyDrawHistoryInformation(uint megaChimpyDrawId) view public returns (uint[] memory, uint[] memory, uint, uint, uint, uint) {
        return (
        megaChimpyDrawHistory[megaChimpyDrawId].ticketsBoughtIds, 
        megaChimpyDrawHistory[megaChimpyDrawId].numbersAndChimpies, 
        megaChimpyDrawHistory[megaChimpyDrawId].totalParticipants,       
        megaChimpyDrawHistory[megaChimpyDrawId].totalJackpot,    
        megaChimpyDrawHistory[megaChimpyDrawId].openTimestamp,
        megaChimpyDrawHistory[megaChimpyDrawId].closeTimestamp);
    }

    function countTicketsBought() view public returns (uint) {
        return ticketsBoughtIds.length;
    }

    function countMegaChimpyDraws() view public returns (uint) {
        return megaChimpyDrawHistoryIds.length;
    }
    
    function countPossibleNumbers() view public returns (uint) {
        return possibleNumbers.length;
    }
    
    function countPossibleChimpies() view public returns (uint) {
        return possibleChimpies.length;
    }

    /* Game Functions */

    /* Phase 2 - Buy Ticket */
    function buyTicket( uint[] memory _betNumbers, uint[] memory _betChimpies ) public payable {
        require(ticketSaleOpen, "Ticket Sale: Closed");
      
        require(msg.value % ticketPrice == 0 && msg.value > 0, "You should send exactly the price of the ticket");

        (bool success, ) = payable(address(this)).call{value: msg.value}(new bytes(0));
        require(success, 'BNB transfer failed');
        Ticket storage ticketBought = ticketsBought[actualTicketNumberId];

        ticketBought.megaChimpyDrawId = actualMegaChimpyDrawId;
        ticketBought.participantWalletAddress = msg.sender;
        ticketBought.betNumbers = _betNumbers;
        ticketBought.betChimpies = _betChimpies;
        ticketBought.ticketPrice = ticketPrice;
        ticketBought.timestamp = block.timestamp;
        ticketsBoughtIds.push(actualTicketNumberId);

        megaChimpyDrawHistory[actualMegaChimpyDrawId].ticketsBoughtIds.push(actualTicketNumberId);

        ++actualTicketNumberId;
        
        megaChimpyDrawHistory[actualMegaChimpyDrawId].totalParticipants++;
    }

    /** 
     * Requests randomness 
     * Returns a hash essentially (requestId)
     * expand() create array of randomness
     */

    /* Phase 4 - Generate Random Number */
    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /* Phase 5 - Wait 1 min for request fulfill */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
    
    function expand(uint256 randomValue, uint256 n) internal pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }
    
    /* Phase 6 - Generate Winning Combination */
    function generateWinningCombination() public onlyOwner {
        require(!ticketSaleOpen, "Ticket Sale: You cannot generate winners while ticket sale is open");

        megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies = expand(randomResult, 14);

        for (uint i = 0; i <  megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies.length -9; i++) { 
            megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i]=(megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i] % 50) + 1;
            if(existsNumbers(megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i])){
               megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i] = (megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i+7] % 50) + 1;
            }
        }
        for (uint i = 5; i <  megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies.length-7; i++) { 
            megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i]=(megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i] % 9) + 1;
            if(existsChimpies(megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i])){
               megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i] = (megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i+7] % 9) + 1;
            }
        }
        cleanDuplicate();
        emit MegaChimpyDrawWinnerCombination(actualMegaChimpyDrawId,  megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies);
        
    }

    /* Phase 6.1 - Check & Remove Duplicates */
    function existsNumbers(uint b) internal view returns (bool){
      for (uint i=0; i< megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies.length-9; i++){
          if (megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i]==b)
          return true;
      }
    }

   function existsChimpies(uint b) internal view returns (bool){
      for (uint i=5; i< megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies.length-7;i++){
          if (megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i]==b)
          return true;
      }
    }

    function cleanDuplicate() internal {
      for (uint i=0; i<6; i++){
        megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies.pop();
      }
      megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies.pop();
    }
    
    /* Phase 8 - Claim Rewards */
    function claimReward(uint _ticketId) public payable {
        Ticket storage participantTicket = ticketsBought[_ticketId];
        require(participantTicket.megaChimpyDrawId < actualMegaChimpyDrawId, "You cannot claim the ticket prize before the draw ends.");
        require(participantTicket.participantWalletAddress == address(msg.sender), "You cannot claim this ticket as it is not yours.");
        require(participantTicket.hasPrize == true, "The ticket does not have any prize!");
        require(participantTicket.claimedPrize == false, "You already claimed the ticket prize!");

        uint256 amount = participantTicket.prizeToBePaid;
        payable(msg.sender).call{value: amount}(new bytes(0));        
        participantTicket.claimedPrize = true;
    }

    /* Start & End Mega Chimpy Draw */

    /* Phase 1 - Start Draw */
    function startMegaChimpyDraw() public onlyOwner { 
        require(!ticketSaleOpen, "Ticket Sale: You cannot start a new draw while ticket sale is open");
        ++actualMegaChimpyDrawId;
        megaChimpyDrawHistoryIds.push(actualMegaChimpyDrawId);
        ticketSaleOpen = true;
        totalWinnersByPrizePosition = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        megaChimpyDrawHistory[actualMegaChimpyDrawId].openTimestamp = block.timestamp;
    }
    
    /* Phase 3 - Close Draw */
    function closeMegaChimpyDraw() public onlyOwner { 
        require(ticketSaleOpen, "Ticket Sale: You cannot end a draw while ticket sale is closed");
        ticketSaleOpen = false;
        
        megaChimpyDrawHistory[actualMegaChimpyDrawId].closeTimestamp = block.timestamp;
        megaChimpyDrawHistory[actualMegaChimpyDrawId].totalJackpot = (megaChimpyDrawHistory[actualMegaChimpyDrawId].totalParticipants)*ticketPrice;
    }
    
    /* Phase 7.1 - Generate Winners */
    function checkWinner(uint _ticketId) internal
    {
        if (ticketsBought[_ticketId].megaChimpyDrawId == actualMegaChimpyDrawId) {
            uint winningNCounter = 0;
            uint winningCCounter = 0;
            
            for (uint i = 0; i < 5 ; i++) {
                if (megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i] == ticketsBought[_ticketId].betNumbers[0]) {
                    ++winningNCounter;
                }
                if (megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i] == ticketsBought[_ticketId].betNumbers[1]) {
                    ++winningNCounter;
                }
                if (megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i] == ticketsBought[_ticketId].betNumbers[2]) {
                    ++winningNCounter;
                }
                if (megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i] == ticketsBought[_ticketId].betNumbers[3]) {
                    ++winningNCounter;
                }
                if (megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i] == ticketsBought[_ticketId].betNumbers[4]) {
                    ++winningNCounter;
                }
            }
            for (uint i = 5; i < 7 ; i++) {
                if (megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i] == ticketsBought[_ticketId].betChimpies[0]) {
                    ++winningCCounter;
                }  
                if (megaChimpyDrawHistory[actualMegaChimpyDrawId].numbersAndChimpies[i] == ticketsBought[_ticketId].betChimpies[1]) {
                    ++winningCCounter;
                }
            }
            
           for (uint i = 0; i < winningNumbers.length; i++) {
                if (winningNumbers[i] == winningNCounter && winningChimpies[i] == winningCCounter) {
                    ticketsBought[_ticketId].hasPrize = true;
                    ticketsBought[_ticketId].prizePosition = i;
                    totalWinnersByPrizePosition[i]++;
                    ticketsBought[_ticketId].prizeToBePaid = (winningPrizes[i]*megaChimpyDrawHistory[actualMegaChimpyDrawId].totalJackpot) / totalWinnersByPrizePosition[i];
                    break;
                } else {
                    ticketsBought[_ticketId].hasPrize = false;
                    ticketsBought[_ticketId].prizePosition = 0;
                    ticketsBought[_ticketId].prizeToBePaid = 0;
                }
            }
        }
    }

    /* Phase 7 - Generate Winners */
    function generateWinners() public onlyOwner {
        require(!ticketSaleOpen, "Ticket Sale: You cannot generate winners while ticket sale is open");
        
        uint actualNumberTicketToCheck = megaChimpyDrawHistory[actualMegaChimpyDrawId].ticketsBoughtIds[0];
        uint totalNumberOfParticipants = megaChimpyDrawHistory[actualMegaChimpyDrawId].totalParticipants-1;

        for (uint i = actualNumberTicketToCheck; i < totalNumberOfParticipants; i++) {
           uint actualTicketInCheck = megaChimpyDrawHistory[actualMegaChimpyDrawId].ticketsBoughtIds[i];
           checkWinner(actualTicketInCheck);
        }
    }

    /* MegaChimpy Player & Draw Information */
    function checkTicketPrize(uint _ticketId) public view returns ( bool hasPrize, uint prizePosition, uint prizeToBePaid) 
    {
        Ticket storage ticket = ticketsBought[_ticketId];
        hasPrize = ticket.hasPrize;
        prizePosition = ticket.prizePosition;
        prizeToBePaid = ticket.prizeToBePaid;
    }

    function getMegaChimpyPlayerHistory(address _walletAddress) view public returns (Ticket[] memory) {
        Ticket[] memory playerHistory;
        uint counter = 0;
        for (uint i = 0; i < ticketsBoughtIds.length; i++) {
            if (ticketsBought[i].participantWalletAddress == _walletAddress) {
                playerHistory[counter] = ticketsBought[i];
                counter++;
            }
        }
        return playerHistory;   
    }

    /* Check & Withdraw Prize Pool */
    function checkGameTreasury() view external returns (uint){
        return address(this).balance;
    }

    function withdrawAllGameTreasury() external payable onlyOwner {
        require(!ticketSaleOpen, "Ticket Sale: You cannot withdraw the game pool while ticket sale is open");
        payable(msg.sender).call{value: address(this).balance}(new bytes(0));
    }

    function withdrawGameTreasury(uint256 amount) external payable onlyOwner {
        require(!ticketSaleOpen, "Ticket Sale: You cannot withdraw the game pool while ticket sale is open");
        payable(msg.sender).call{value: amount}(new bytes(0));
    }

    function withdrawLink() public onlyOwner {
        LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
    }
}