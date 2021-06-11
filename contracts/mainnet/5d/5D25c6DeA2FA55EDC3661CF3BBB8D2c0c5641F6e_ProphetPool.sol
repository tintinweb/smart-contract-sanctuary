/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

// Dependency file: @chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol

// SPDX-License-Identifier: MIT
// pragma solidity ^0.6.0;

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


// Dependency file: @chainlink/contracts/src/v0.6/interfaces/LinkTokenInterface.sol

// pragma solidity ^0.6.0;

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


// Dependency file: @chainlink/contracts/src/v0.6/VRFRequestIDBase.sol

// pragma solidity ^0.6.0;

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


// Dependency file: @chainlink/contracts/src/v0.6/VRFConsumerBase.sol

// pragma solidity ^0.6.0;

// import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

// import "@chainlink/contracts/src/v0.6/interfaces/LinkTokenInterface.sol";

// import "@chainlink/contracts/src/v0.6/VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
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
   * @param _seed seed mixed into the input of the VRF.
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
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


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol


// pragma solidity ^0.6.0;

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


// Dependency file: @openzeppelin/contracts/utils/Address.sol


// pragma solidity ^0.6.2;

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
        assembly { codehash := extcodehash(account) }
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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


// Dependency file: @openzeppelin/contracts/utils/ReentrancyGuard.sol


// pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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


// Dependency file: @openzeppelin/contracts/GSN/Context.sol


// pragma solidity ^0.6.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/GSN/Context.sol";
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
    constructor () internal {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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


// Dependency file: contracts/lib/Uint256ArrayUtils.sol

// pragma solidity 0.6.10;

/**
 * @title Uint256ArrayUtils
 * @author Prophecy
 *
 * Utility functions to handle uint256 Arrays
 */
library Uint256ArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(uint256[] memory A, uint256 a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
    * Returns true if the value is present in the list. Uses indexOf internally.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns isIn for the first occurrence starting from index 0
    */
    function contains(uint256[] memory A, uint256 a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
    * Returns true if there are 2 elements that are the same in an array
    * @param A The input array to search
    * @return Returns boolean for the first occurrence of a duplicate
    */
    function hasDuplicate(uint256[] memory A) internal pure returns(bool) {
        require(A.length > 0, "A is empty");

        for (uint256 i = 0; i < A.length - 1; i++) {
            uint256 current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (current == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The uint256 to remove     
     * @return Returns the array with the object removed.
     */
    function remove(uint256[] memory A, uint256 a)
        internal
        pure
        returns (uint256[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("uint256 not in array.");
        } else {
            (uint256[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    /**
     * @param A The input array to search
     * @param a The uint256 to remove
     */
    function removeStorage(uint256[] storage A, uint256 a)
        internal
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("uint256 not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) { A[index] = A[lastIndex]; }
            A.pop();
        }
    }

    /**
    * Removes specified index from array
    * @param A The input array to search
    * @param index The index to remove
    * @return Returns the new array and the removed entry
    */
    function pop(uint256[] memory A, uint256 index)
        internal
        pure
        returns (uint256[] memory, uint256)
    {
        uint256 length = A.length;
        require(index < A.length, "Index must be < A length");
        uint256[] memory newUint256s = new uint256[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newUint256s[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newUint256s[j - 1] = A[j];
        }
        return (newUint256s, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(uint256[] memory A, uint256[] memory B) internal pure returns (uint256[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        uint256[] memory newUint256s = new uint256[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newUint256s[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newUint256s[aLength + j] = B[j];
        }
        return newUint256s;
    }

    /**
     * Validate uint256 array is not empty and contains no duplicate elements.
     *
     * @param A          Array of uint256
     */
    function _validateLengthAndUniqueness(uint256[] memory A) internal pure {
        require(A.length > 0, "Array length must be > 0");
        require(!hasDuplicate(A), "Cannot duplicate uint256");
    }
}

// Dependency file: contracts/lib/AddressArrayUtils.sol

// pragma solidity 0.6.10;

/**
 * @title AddressArrayUtils
 * @author Prophecy
 *
 * Utility functions to handle uint256 Arrays
 */
library AddressArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
    * Returns true if the value is present in the list. Uses indexOf internally.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns isIn for the first occurrence starting from index 0
    */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
    * Returns true if there are 2 elements that are the same in an array
    * @param A The input array to search
    * @return Returns boolean for the first occurrence of a duplicate
    */
    function hasDuplicate(address[] memory A) internal pure returns(bool) {
        require(A.length > 0, "A is empty");

        for (uint256 i = 0; i < A.length - 1; i++) {
            address current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (current == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The address to remove     
     * @return Returns the array with the object removed.
     */
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     */
    function removeStorage(address[] storage A, address a)
        internal
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) { A[index] = A[lastIndex]; }
            A.pop();
        }
    }

    /**
    * Removes specified index from array
    * @param A The input array to search
    * @param index The index to remove
    * @return Returns the new array and the removed entry
    */
    function pop(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        require(index < A.length, "Index must be < A length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

    /**
     * Validate that address and uint array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of uint
     */
    function validatePairsWithArray(address[] memory A, uint[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bool array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bool
     */
    function validatePairsWithArray(address[] memory A, bool[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and string array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of strings
     */
    function validatePairsWithArray(address[] memory A, string[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address array lengths match, and calling address array are not empty
     * and contain no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of addresses
     */
    function validatePairsWithArray(address[] memory A, address[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bytes array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bytes
     */
    function validatePairsWithArray(address[] memory A, bytes[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param A          Array of addresses
     */
    function _validateLengthAndUniqueness(address[] memory A) internal pure {
        require(A.length > 0, "Array length must be > 0");
        require(!hasDuplicate(A), "Cannot duplicate addresses");
    }
}

// Dependency file: contracts/interfaces/IWETH.sol

// pragma solidity 0.6.10;

// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWETH
 * @author Prophecy
 *
 * Interface for Wrapped Ether. This interface allows for interaction for wrapped ether's deposit and withdrawal
 * functionality.
 */
interface IWETH is IERC20{
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// Dependency file: contracts/interfaces/IProphetPoolFactory.sol

// pragma solidity ^0.6.10;

/**
 * @title IProphetPoolFactory
 * @author Prophecy
 */
interface IProphetPoolFactory {
    /**
     * Creates a ProphetPool smart contract set the manager(owner) of the pool.
     */
    function create(string memory, address, address, address) external returns (address);

    /**
     * Return WETH address.
     */
    function getWeth() external view returns (address);

    /**
     * Return VRF Key Hash.
     */
    function getVrfKeyHash() external view returns (bytes32);

    /**
     * Return VRF Fee.
     */
    function getVrfFee() external view returns (uint256);

    /**
     * Return Link Token address for VRF.
     */
    function getLinkToken() external view returns (address);

    /**
     * Return VRF coordinator.
     */
    function getVrfCoordinator() external view returns (address);

    /**
     * Return all pools addreses
     */
    function getAllPools() external view returns (address[] memory);
}


// Root file: contracts/ProphetPool.sol

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

// import { VRFConsumerBase } from "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import { Address } from "@openzeppelin/contracts/utils/Address.sol";
// import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// import { Uint256ArrayUtils } from "contracts/lib/Uint256ArrayUtils.sol";
// import { AddressArrayUtils } from "contracts/lib/AddressArrayUtils.sol";
// import { IWETH } from "contracts/interfaces/IWETH.sol";
// import { IProphetPoolFactory } from "contracts/interfaces/IProphetPoolFactory.sol";

/**
 * @title ProphetPool
 * @author Prophecy
 *
 * Smart contract that facilitates that draws lucky winners in the pool and distribut rewards to the winners.
 */
contract ProphetPool is VRFConsumerBase, ReentrancyGuard, Ownable {
    using Address for address;
    using Uint256ArrayUtils for uint256[];
    using AddressArrayUtils for address[];

    /* ============ Structs ============ */

    struct PoolConfig {
        uint256 numOfWinners;
        uint256 participantLimit;
        uint256 enterAmount;
        uint256 feePercentage;
        uint256 randomSeed;
        uint256 startedAt;
    }

    /* ============ Enums ============ */

    enum PoolStatus { NOTSTARTED, INPROGRESS, CLOSED }

    /* ============ Events ============ */

    event FeeRecipientSet(address indexed _feeRecipient);
    event MaxParticipationCompleted(address indexed _from);
    event RandomNumberGenerated(uint256 indexed randomness);
    event WinnersGenerated(uint256[] winnerIndexes);
    event PoolSettled();
    event PoolStarted(
        uint256 participantLimit,
        uint256 numOfWinners,
        uint256 enterAmount,
        uint256 feePercentage,
        uint256 startedAt
    );
    event PoolReset();
    event EnteredPool(address indexed _participant, uint256 _amount, uint256 indexed _participantIndex);

    /* ============ State Variables ============ */

    IProphetPoolFactory private factory;
    address private feeRecipient;
    string private poolName;
    IERC20 private enterToken;
    PoolStatus private poolStatus;
    PoolConfig private poolConfig;

    address[] private participants;
    uint256[] private winnerIndexes;
    uint256 private totalEnteredAmount;
    uint256 private rewardPerParticipant;

    uint256 internal randomResult;
    bool internal areWinnersGenerated;

    /* ============ Modifiers ============ */

    modifier onlyValidPool() {
        require(participants.length < poolConfig.participantLimit, "Max Participation for the Pool Reached");
        require(poolStatus == PoolStatus.INPROGRESS, "The Pool is not started or closed");
        _;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Only EOA allowed");
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Create the ProphetPool with Chainlink VRF configuration for Random number generation.
     *
     * @param _poolName             Pool name
     * @param _enterToken           ERC20 token to enter the pool. If it's ETH pool, it should be WETH address
     * @param _factory              ProphetPoolFactory
     * @param _feeRecipient         Where the fee go
     */
    constructor(
        string memory _poolName,
        address _enterToken,
        address _factory,
        address _feeRecipient
    )
        public
        VRFConsumerBase(IProphetPoolFactory(_factory).getVrfCoordinator(), IProphetPoolFactory(_factory).getLinkToken())
    {
        poolName = _poolName;
        enterToken = IERC20(_enterToken);
        factory = IProphetPoolFactory(_factory);
        feeRecipient = _feeRecipient;

        poolStatus = PoolStatus.NOTSTARTED;
    }

    /* ============ External/Public Functions ============ */

    /**
     * Set the Pool Config, initializes an instance of and start the pool.
     *
     * @param _numOfWinners         Number of winners in the pool
     * @param _participantLimit     Maximum number of paricipants
     * @param _enterAmount          Exact amount to enter this pool
     * @param _feePercentage        Manager fee of this pool
     * @param _randomSeed           Seed for Random Number Generation
     */
    function setPoolRules(
        uint256 _numOfWinners,
        uint256 _participantLimit,
        uint256 _enterAmount,
        uint256 _feePercentage,
        uint256 _randomSeed
    ) external onlyOwner {
        require(poolStatus == PoolStatus.NOTSTARTED, "A Pool is in progress");
        require(_numOfWinners != 0, "Number of winner must not be 0");
        require(_numOfWinners < _participantLimit, "Too much number of winners");

        poolConfig = PoolConfig(
            _numOfWinners,
            _participantLimit,
            _enterAmount,
            _feePercentage,
            _randomSeed,
            block.timestamp
        );
        poolStatus = PoolStatus.INPROGRESS;
        emit PoolStarted(
            _participantLimit,
            _numOfWinners,
            _enterAmount,
            _feePercentage,
            block.timestamp
        );
    }

    /**
     * Set the Pool Config, initializes an instance of and start the pool.
     *
     * @param _feeRecipient         Number of winners in the pool
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid address");
        feeRecipient = _feeRecipient;

        emit FeeRecipientSet(feeRecipient);
    }

    /**
     * Enter pool with ETH
     */
    function enterPoolEth() external payable onlyValidPool onlyEOA returns (uint256) {
        require(msg.value == poolConfig.enterAmount, "Insufficent registration amount provided");
        if (!_isEthPool()) {
            revert("ETH isn't accepted");
        }
        // wrap ETH to WETH
        IWETH(factory.getWeth()).deposit{ value: msg.value }();

        return _enterPool();
    }

    /**
     * Enter pool with ERC20 token
     */
    function enterPool() external onlyValidPool onlyEOA returns (uint256) {
        enterToken.transferFrom(
                msg.sender,
                address(this),
                poolConfig.enterAmount
            );

        return _enterPool();
    }

    /**
     * Settle the pool, the winners are selected randomly and fee is transfer to the manager.
     */
    function settlePool() external {
        require(randomResult > 0, "RND in progress");
        require(poolStatus == PoolStatus.INPROGRESS, "The Pool is in progress");

        // generate winnerIndexes until the numOfWinners reach
        uint256 newRandom = randomResult;
        uint256 offset = 0;
        while(winnerIndexes.length < poolConfig.numOfWinners) {
            uint256 winningIndex = newRandom.mod(poolConfig.participantLimit);
            if (!winnerIndexes.contains(winningIndex)) {
                winnerIndexes.push(winningIndex);
            }
            offset.add(1);
            newRandom = _getRandomNumberBlockchain(offset, newRandom);
        }
        areWinnersGenerated = true;
        emit WinnersGenerated(winnerIndexes);

        // set pool CLOSED status
        poolStatus = PoolStatus.CLOSED;

        // transfer fees
        uint256 feeAmount = totalEnteredAmount.mul(poolConfig.feePercentage).div(100);
        rewardPerParticipant = (totalEnteredAmount.sub(feeAmount)).div(poolConfig.numOfWinners);
        _transferEnterToken(feeRecipient, feeAmount);

        // collectRewards();
        emit PoolSettled();
    }

    /**
     * The winners of the pool can call this function to transfer their winnings
     * from the pool contract to their own address.
     */
    function collectRewards() external nonReentrant {
        require(poolStatus == PoolStatus.CLOSED, "The Pool is not settled.");

        for (uint256 i = 0; i < poolConfig.participantLimit; i = i.add(1)) {
            address player = participants[i];
            if (winnerIndexes.contains(i)) {
                // if winner
                _transferEnterToken(player, rewardPerParticipant);
            }
        }
        _resetPool();
    }

    /**
     * The contract will receive Ether
     */
    receive() external payable {}

    /**
     * Getter for factory
     */
    function getFactory() external view returns (address) {
        return address(factory);
    }

    /**
     * Getter for fee recipient
     */
    function getFeeRecipient() external view returns (address) {
        return feeRecipient;
    }

    /**
     * Getter for poolName
     */
    function getPoolName() external view returns (string memory) {
        return poolName;
    }

    /**
     * Getter for enterToken
     */
    function getEnterToken() external view returns (address) {
        return address(enterToken);
    }

    /**
     * Getter for poolStatus
     */
    function getPoolStatus() external view returns (PoolStatus) {
        return poolStatus;
    }

    /**
     * Getter for poolConfig
     */
    function getPoolConfig() external view returns (PoolConfig memory) {
        return poolConfig;
    }

    /**
     * Getter for totalEnteredAmount
     */
    function getTotalEnteredAmount() external view returns (uint256) {
        return totalEnteredAmount;
    }

    /**
     * Getter for rewardPerParticipant
     */
    function getRewardPerParticipant() external view returns (uint256) {
        return rewardPerParticipant;
    }

    /**
     * Get all participants
     */
    function getParticipants() external view returns(address[] memory) {
        return participants;
    }

    /**
     * Get one participant by index
     * @param _index                 Index of the participants array
     */
    function getParticipant(uint256 _index) external view returns(address) {
        return participants[_index];
    }

    /**
     * Getter for winnerIndexes
     */
    function getWinnerIndexes() external view returns(uint256[] memory) {
        return winnerIndexes;
    }

    /**
     * Get if the account is winner
     */
    function isWinner(address _account) external view returns(bool) {
        (uint256 index, bool isExist) = participants.indexOf(_account);
        if (isExist) {
            return winnerIndexes.contains(index);
        } else {
            return false;
        }
    }

    /* ============ Private/Internal Functions ============ */

    /**
     * Participant enters the pool and enter amount is transferred from the user to the pool.
     */
    function _enterPool() internal returns(uint256 _participantIndex) {
        participants.push(msg.sender);

        totalEnteredAmount = totalEnteredAmount.add(poolConfig.enterAmount);

        if (participants.length == poolConfig.participantLimit) {
            emit MaxParticipationCompleted(msg.sender);
            _getRandomNumber(poolConfig.randomSeed);
        }

        _participantIndex = (participants.length).sub(1);
        emit EnteredPool(msg.sender, poolConfig.enterAmount, _participantIndex);
    }

    /**
     * Reset the pool, clears the existing state variable values and the pool can be initialized again.
     */
    function _resetPool() internal {
        poolStatus = PoolStatus.INPROGRESS;
        delete totalEnteredAmount;
        delete rewardPerParticipant;
        randomResult = 0;
        areWinnersGenerated = false;
        delete winnerIndexes;
        delete participants;
        emit PoolReset();

        uint256 tokenBalance = enterToken.balanceOf(address(this));
        if (tokenBalance > 0) {
            enterToken.transfer(feeRecipient, tokenBalance);
        }
    }

    /**
     * Transfer enterToken even it's ETH or ERC20.
     *
     * @param _to                   Offset to generate the random number
     * @param _amount               Random number to generate the other random number
     */
    function _transferEnterToken(address _to, uint256 _amount) internal {
        if (_isEthPool()) {
            IWETH(factory.getWeth()).withdraw(_amount);
            (bool status, ) = payable(_to).call{value: _amount}("");
            require(status, "ETH not transferred");
        } else {
            enterToken.transfer(address(_to), _amount);
        }
    }

    /**
     * Check pool is ETH pool or not
     */
    function _isEthPool() internal view returns (bool) {
        return address(enterToken) == factory.getWeth();
    }

    /**
     * Generate a random number based on the blockHash and random offset
     *
     * @param _offset               Offset to generate the random number
     * @param _randomness           Random number to generate the other random number
     */
    function _getRandomNumberBlockchain(uint256 _offset, uint256 _randomness)
        internal
        view
        returns (uint256)
    {
        bytes32 baseHash = keccak256(
            abi.encodePacked(
                blockhash(block.number),
                bytes32(_offset),
                bytes32(_randomness)
            )
        );
        return uint256(baseHash);
    }

    /**
     * Calls ChainLink Oracle's inherited function for Random Number Generation.
     * The contract must have enough LINK required for VRF.
     *
     * @param _userProvidedSeed     Seed to generate the random number
     */
    function _getRandomNumber(uint256 _userProvidedSeed)
        internal
        returns (bytes32 requestId)
    {
        require(
            IERC20(factory.getLinkToken()).balanceOf(address(this)) >= factory.getVrfFee(),
            "Not enough LINK for VRF"
        );
        randomResult = 0;
        return
            requestRandomness(
                factory.getVrfKeyHash(),
                factory.getVrfFee(),
                _userProvidedSeed
            );
    }

    /**
     * Callback function used by VRF Coordinator.
     *
     * @param _randomness     Generated random number
     */
    function fulfillRandomness(bytes32, uint256 _randomness) internal override {
        randomResult = _randomness;
        emit RandomNumberGenerated(_randomness);
    }
}