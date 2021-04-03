/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

// File: contracts\Ownable.sol

pragma solidity ^0.6.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public newOwner;

    // There can be multiple controller (designated operator) accounts.
    address[] internal controllers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public {
        owner = msg.sender;
    }
   
    /**
    * @dev Throws if called by any account that's not a controller.
    */
    modifier onlyController() {
        require(isController(msg.sender), "only Controller");
        _;
    }

    modifier onlyOwnerOrController() {
        require(msg.sender == owner || isController(msg.sender), "only Owner Or Controller");
        _;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "sender address must be the owner's address");
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a new owner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(address(0) != _newOwner, "new owner address must not be the owner's address");
        newOwner = _newOwner;
    }

    /**
    * @dev Allows the new owner to confirm that they are taking control of the contract.
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner, "sender address must not be the new owner's address");
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        newOwner = address(0);
    }

    function isController(address _controller) internal view returns(bool) {
        for (uint8 index = 0; index < controllers.length; index++) {
            if (controllers[index] == _controller) {
                return true;
            }
        }
        return false;
    }

    function getControllers() public onlyOwner view returns(address[] memory) {
        return controllers;
    }

    /**
    * @dev Allows a new controllers to be added
    * @param _controller The address of the controller account.
    */
    function addController(address _controller) public onlyOwner {
        require(address(0) != _controller, "controller address must not be 0");
        require(_controller != owner, "controller address must not be the owner's address");
        for (uint8 index = 0; index < controllers.length; index++) {
            if (controllers[index] == _controller) {
                return;
            }
        }
        controllers.push(_controller);
    }

    /**
    * @dev Remove a controller from the list
    * @param _controller The address of the controller account.
    */
    function removeController(address _controller) public onlyOwner {
        require(address(0) != _controller, "controller address must not be 0");
        for (uint8 index = 0; index < controllers.length; index++) {
            if (controllers[index] == _controller) {
                delete controllers[index];
            }
        }
    }
}

// File: contracts\chainlink\vendor\SafeMathChainlink.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

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

// File: contracts\chainlink\interfaces\LinkTokenInterface.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

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

// File: contracts\chainlink\VRFRequestIDBase.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

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

// File: contracts\chainlink\VRFConsumerBase.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;




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
//contract VRFConsumerBase is VRFRequestIDBase {

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

// File: contracts\utils\Address.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

//https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/utils/Address.sol

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

// File: contracts\interfaces\IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

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

// File: @chainlink\contracts\src\v0.6\interfaces\AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: contracts\math\SafeMathInt.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;
 
library SafeMathInt {
     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
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
    function sub(int256 a, int256 b) internal pure returns (int256) {
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
    function sub(int256 a, int256 b, string memory errorMessage) internal pure returns (int256) {
        require(b <= a, errorMessage);
        int256 c = a - b;

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
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        int256 c = a * b;
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
    function div(int256 a, int256 b) internal pure returns (int256) {
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
    function div(int256 a, int256 b, string memory errorMessage) internal pure returns (int256) {
        require(b > 0, errorMessage);
        int256 c = a / b;
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
    function mod(int256 a, int256 b) internal pure returns (int256) {
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
    function mod(int256 a, int256 b, string memory errorMessage) internal pure returns (int256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts\IChainGuardiansToken900.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;


/**
 * @title IChainGuardiansToken900
 * @dev 
 */
interface IChainGuardiansToken900 {

    function mint(address user, uint256 tokenId, uint256 _attributes) external;
    function mintWithUri(address user, uint256 tokenId, uint256 _attributes, string calldata _tokenURI) external;
    function getAttributes(uint256 _tokenId) external view returns (uint256 attributes);
    function tokenURI(uint256 _tokenId) external view returns (string memory responseTokenUri);
    function tokensOfOwner(address _owner) external view returns (uint256[] memory);
    function totalSupply() external view returns (uint256);
        
}

// File: contracts\ChainGuardiansMinter.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

// mint contract

// function: start mint function ():
// - - pay function contract in eth
// - - create randomized number for color and rarity using chainlink
// - - add color and rarity request id to contract storage


// function: Get randomized number response from chainlink function:
// - fulfillRandomness(bytes32 requestId, uint256 randomness):
// - - if request id exists, and is not yet saved, then store chain link value


// function: finalize mint function (nft id)
// - - verify that the nft has received randomness value for color and rarity
// - - convert color number to color value between 0-64 (maybe last 2 digits / 64 rounded down)
// - - convert rarity number to value between 0-15 (maybe last 4th+3rd digit)
// - - mint new NFT on NFT contract with hardcoded string + changed color number + changed rarity number

// function: increase experience level (nft id, ne experience level)
// - get the experience level from string
// - if the new experience level is higher than existing it is upgraded and the new string is created and saved to the nft


// flow
// 1
// mint(uint256 userProvidedSeed)  -> generateRandomNumberRequest(uint256 userProvidedSeed) -> getRandomNumber(uint256 userProvidedSeed) -> 
// -> requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
// 2
// fulfillRandomness(bytes32 requestId, uint256 randomness) -> 


//import "./math/SafeMath.sol";






//import "./IChainGuardiansToken.sol";


contract ChainGuardiansMinter is VRFConsumerBase, Ownable {
    //using SafeMath for uint256;// already used in SafeMathChainlink int he VRF Contract tree
    using SafeMathChainlink for uint256; 
    using SafeMathInt for int; 
    using Address for address payable;

    AggregatorV3Interface internal priceFeed;

    bytes32 internal keyHash;
    uint256 internal fee;

    // id (bytes32) -> request seed number
    mapping (bytes32 => uint256) internal requestSeedList;
    // id -> payable amount 
    mapping (bytes32 => uint256) internal requestPayableReceivedList;
    //
    mapping (bytes32 => address) internal requestedByList;
    //
    mapping (bytes32 => uint256) internal requestColorList; //to be removed?
    // id (bytes32) -> response randomness number
    mapping (bytes32 => uint256) internal requestResponseList;

    mapping (bytes32 => uint) internal requestTokenIds;
    mapping (bytes32 => uint256) internal requestTokenAttributes;
    mapping (bytes32 => string) internal requestTokenUris;

    constructor(
        address _vrfCoordinator,
        address _link,
        address _priceAggregator
        ) VRFConsumerBase(_vrfCoordinator, _link)
    public
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311; //updated? only for kovan??
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        priceFeed = AggregatorV3Interface(_priceAggregator);


        //default settings:
        cg_token_defaultUri = "https://api.chainguardians.com/api/tokens/";
        usdFee = 1000;
        lastCgTokenId = 899;
        maxCgTokenId = 1199;
    }

    /* configure cgtoken */

    //IChainGuardiansToken internal cgtoken;
    IChainGuardiansToken900 internal cg_token;
    address internal cg_token_address;
    string internal cg_token_defaultUri;

    function setCgToken(address _tokenaddress) public returns (bool result) { 
        require(msg.sender == owner, "only owner can setCgToken");

        cg_token_address = _tokenaddress;
        cg_token = IChainGuardiansToken900(cg_token_address);

        return true;
    }

    function setCgTokenUri(string memory _defaultUri) public returns (bool result) { 
        require(msg.sender == owner, "only owner can setCgTokenUri");

        cg_token_defaultUri = _defaultUri;

        return true;
    }

    function getCgTokenAddress() public view returns(address) {
        return cg_token_address;
    }

    function callCgToken_totalSupply() public view returns(uint256) {
        //IChainGuardiansToken cg_token = IChainGuardiansToken(cgtoken_address);
        //cg_token = IChainGuardiansToken900(cg_token_address);

        // return 111;
        return cg_token.totalSupply();
    }

    function testMintViaContract(address _to, uint256 _tokenid, uint256 _attributes, string memory _uri) public returns(bool) {
        require(msg.sender == owner, "only owner can testmint");

        //IChainGuardiansToken cg_token = IChainGuardiansToken(cgtoken_address);
        //cg_token = IChainGuardiansToken900(cg_token_address);

        // return 111;    
        //function mintWithUri(address user, uint256 tokenId, uint256 _attributes, string memory _tokenURI) public {

        cg_token.mintWithUri(_to, _tokenid, _attributes, _uri);
        return true;
    }

   /* DEPOSIT AND WITHDRAWAL */
    event Deposited(address tokenAddress, uint256 weiAmount);//0 is eth
    mapping(address => uint256) private deposits;

    event Withdrawn(address tokenAddress, uint256 weiAmount);
    mapping(address => uint256) private withdrawals;

    address payable internal withdrawalAddress;

    function setWithdrawWallet(address wallet) public returns (bool result) {
        require(msg.sender == owner, "only owner can setWithdrawWallet");

        withdrawalAddress = payable(wallet);
        return (true);
     }

    function deposit() public payable {
        uint256 amount = msg.value;
        deposits[address(0)] = deposits[address(0)].add(amount);

        emit Deposited(address(0),amount);
    }

    function depositToken(address tokenAddress, uint256 tokenAmount) public {
        IERC20 token = IERC20(tokenAddress);
        //uint tokenAmount = token.balanceOf(msg.sender);//transfer everything
        token.transferFrom(msg.sender, address(this), tokenAmount);

        deposits[tokenAddress] = deposits[tokenAddress].add(tokenAmount);
        emit Deposited(tokenAddress,tokenAmount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "insufficient eth balance in contract");

        //withdrawalAddress.sendValue(amount);
        withdrawalAddress.transfer(amount);

        emit Withdrawn(address(0), amount);
    }

    function withdrawToken(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        //require(LINK.balanceOf(address(this)) >= amount, "unsufficient token balance in contract");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= tokenAmount, "unsufficient token balance in contract");
        
        token.approve(withdrawalAddress, tokenAmount );
        token.transfer(withdrawalAddress, tokenAmount );

        emit Withdrawn(tokenAddress, tokenAmount);
    }


    // function depositsOf(address payee) public view returns (uint256) {
    //     return _deposits[payee];
    // }
   
    // function withdraw(uint8 assetType, uint256 amount) public returns (bool result) {
    //     require(withdrawalAddress != address(0), "withdrawalAddress has not been set");
    //     require(msg.sender == withdrawalAddress, "only withdrawalAddress can withdraw");
    //     require(assetType == 1 || assetType == 2, "Incorrect type (supported: 1=ETH, 2=LINK)");

    //     if(assetType == 1){
    //         require(assetType == 1 && address(this).balance >= amount, "Not enough ETH");
    //         withdrawalAddress.transfer(amount);

    //         //withdrawalAddress.transfer(amount);
    //     } else if(assetType == 2){
    //         require(assetType == 2 && LINK.balanceOf(address(this)) >= amount, "Not enough LINK");

    //         //LINK.approve(withdrawalAddress, amount);
    //         LINK.transferFrom(address(this), withdrawalAddress, amount);
    //     }
    //     return (true);
    // }

    /* ****** CONFIGURATION AND WITHDRAWAL ****** */

    uint256 internal usdFee;

    function setFee(uint256 _usdFee) public onlyOwner returns (bool result) {
        //require(msg.sender == owner, "only owner can setFee");
        usdFee = _usdFee;//1000
        return (true);
    }

    function getEthFee() public view returns (uint256 feeInEth) {
        ( 
            uint80 roundID, 
            int price, //10 decimals
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        return ( 
            //usdFee.div(uint256(price))
            //uint256(price)
            //price is in 10 decimals so we add 8 decimals to get 18 decimals for eth
            (usdFee*10**18).div(uint256(price))

        );
    }

    uint internal lastCgTokenId;
    uint internal maxCgTokenId;

    function setTokenIdConfigs(uint _lastCgTokenId, uint _maxCgTokenId ) public onlyOwner returns (bool result) {
        lastCgTokenId = _lastCgTokenId;//899
        maxCgTokenId = _maxCgTokenId;//1199
        return (true);
    }

    function getConfig() public view returns (
            address withdrawalAddressResponse,
            uint256 usdFeeResponse,
            uint lastCgTokenIdResponse,
            uint maxCgTokenIdResponse) {
        return ( 
            withdrawalAddress,
            usdFee,
            lastCgTokenId,
            maxCgTokenId
        );
    }


   /* MINTING */
    event MintRequestLog(bytes32 requestId, uint256 time);
    event MintFeeCheckLog(uint256 value, uint256 feeInEth);
    event MintCompletedLog(bytes32 requestId);
    //, uint lastCgTokenId, uint256 attributes, string uri, address sender);
 
    function mint(uint256 userProvidedSeed) public payable returns (bytes32 _requestId) {
        //verify that the payable value is higher than the usd fee
        uint256 ethFee = getEthFee() * 10**8;
        MintFeeCheckLog(msg.value, ethFee);
        require(msg.value >= ethFee, "eth value provided is below the required eth fee amount");


        bytes32 requestId = getRandomNumber(userProvidedSeed);
        requestSeedList[requestId] = userProvidedSeed;
        requestPayableReceivedList[requestId] = msg.value;
        requestedByList[requestId] = msg.sender;

        emit MintRequestLog(requestId, block.timestamp);
        return requestId;
    }
    
    function getRandomNumber(uint256 userProvidedSeed) internal returns (bytes32 _requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    // Callback function used by VRF Coordinator
    // rawFulfillRandomness is externally called by VRFCoordinator when it receives a valid VRF
    // rawFulfillRandomness calls the internal fulfillRandomness function
    // If the fulfillRandomness function uses more than 200k gas, the transaction will fail.
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(requestSeedList[requestId] != 0, "a request could not be found for the request Id");
        require(requestResponseList[requestId] == 0, "a response was already received for the request Id");
        // the VRFConsumerBase.rawFulfillRandomness is the external function, and it ensures that only the VRF coordinator can can this function

        require(lastCgTokenId <= maxCgTokenId, "cannot mint token id above allowed range");
        
        uint tokenId = lastCgTokenId+1;
        lastCgTokenId = tokenId;

        //require(!cg_token.exists(tokenId), "token id is already mint");

        uint256 attributes = getRandomColors(randomness); 

        //store request, get random color
        requestResponseList[requestId] = randomness;
        requestColorList[requestId] = attributes; 
        requestTokenIds[requestId] = tokenId;

        requestTokenAttributes[requestId] = attributes;
        requestTokenUris[requestId] = string(cg_token_defaultUri);

        //string(abi.encodePacked(cg_token_defaultUri, _lastCgTokenId));

        // v1 mint chain guardians tokens - reached gas fee max
        //IChainGuardiansToken cg_token = IChainGuardiansToken(cgtoken_address);
        //cg_token.create(_lastCgTokenId, attributes, new uint256[](0), requestedByList[requestId]);

        // 

        //         emit MintCompletedLog(
        //     requestId,
        //     _lastCgTokenId,
        //     attributes,
        //     requestTokenUris[requestId],
        //     requestedByList[requestId]
        // );

        // v2 mint CGT900
        //(bool success) = 
        cg_token.mintWithUri(
            requestedByList[requestId], 
            tokenId, 
            attributes, 
            requestTokenUris[requestId]
        );
        //require(success, "minting failed");
        
        emit MintCompletedLog(requestId);
    }


    /* GET PROPERTIES */
    function getRequestHistory(bytes32 requestId) public view 
        returns (
            uint256 requestSeed,
            uint256 requestPayableReceived,
            uint256 requestResponse,
            address requestedBy,
            uint256 color,
            uint requestTokenId,
            uint256 requestTokenAttribute
        ) 
    {
        return (
            requestSeedList[requestId],
            requestPayableReceivedList[requestId],
            requestResponseList[requestId],
            requestedByList[requestId],
            requestColorList[requestId],
            requestTokenIds[requestId],
            requestTokenAttributes[requestId] 
        );
    }

    function getRequestHistory2(bytes32 requestId) public view
        returns (
            string memory requestTokenUri,
            uint dummy
        )     
    {
        return (
            requestTokenUris[requestId],
            1
        );
    }


    function getRandomColors(uint256 seed) internal pure 
        returns (uint256 colorID)
    {
        return getRandomValue(seed, 128); 
    }

    // returns the random number reltive to the number of outcomes
    function getRandomValue(uint256 seed, uint256 possibleOutcomes) 
        public //internal 
        pure 
        returns (uint256 randomValue)
    { 
        uint256 rangePart = 115792089237316000000000000000000000000000000000000000000000000000000000000000 / possibleOutcomes;

        uint256 rangePartToCheck = 0;
        for(uint256 i=0;i<=possibleOutcomes;i++){
            rangePartToCheck = rangePartToCheck + rangePart;
            if(seed <= rangePartToCheck){
                return i+1;//zero based so need to start at 1
            }
        }

        return 1; 

    }
 
}