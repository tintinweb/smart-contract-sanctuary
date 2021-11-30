// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {IUniswapV2Router02 as ISwapRouter} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./GrantRegistry.sol";
import "./GrantRound.sol";

/**
 * @notice dGrants GrantRoundManager implementation that uses Uniswap V2 to swap a user's tokens to the donationToken
 * in the `donate` method
 * @dev This implementation is intended to be used on L2s or sidechains that don't have a Uniswap V3 deployment
 * and therefore swaps during donations must be done on a Uniswap V2 fork. Because we are less concerned about
 * gas costs on these networks, and because there are many different forks that may have slight differences, we
 * call to an external router instead of inheriting from a router.
 * @dev Current implementation is hardcoded for Polygon mainnet + SushiSwap
 */
contract GrantRoundManagerUniV2 {
  // --- Libraries ---
  using Address for address;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // --- Data ---
  /// @notice Address of a router conforming to the Uniswap V2 interface
  ISwapRouter public constant router = ISwapRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

  /// @notice WETH address
  IERC20 public constant WETH = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

  /// @notice Address of the GrantRegistry
  GrantRegistry public immutable registry;

  /// @notice Address of the ERC20 token in which donations are made
  IERC20 public immutable donationToken;

  /// @dev Used for saving off swap output amounts for verifying input parameters
  mapping(IERC20 => uint256) internal swapOutputs;

  /// @dev Used for saving off contribution ratios for verifying input parameters
  mapping(IERC20 => uint256) internal donationRatios;

  /// @dev Scale factor on percentages when constructing `Donation` objects. One WAD represents 100%
  uint256 internal constant WAD = 1e18;

  /// --- Types ---
  /// @dev Defines the total `amountIn` of the first token in `path` that needs to be swapped to `donationToken`
  struct SwapSummary {
    uint256 amountIn;
    uint256 amountOutMin; // minimum amount to be returned after swap
    address[] path; // Use `path == [donationToken]` to indicate no swap is required and just transfer the tokens directly
  }

  /// @dev Donation inputs and Uniswap V3 swap inputs: https://docs.uniswap.org/protocol/guides/swaps/multihop-swaps
  struct Donation {
    uint96 grantId; // grant ID to which donation is being made
    IERC20 token; // address of the token to donate
    uint256 ratio; // ratio of `token` to donate, specified as numerator where WAD = 1e18 = 100%
    GrantRound[] rounds; // rounds against which the donation should be counted
  }

  // --- Events ---
  /// @notice Emitted when a new GrantRound contract is created
  event GrantRoundCreated(address grantRound);

  /// @notice Emitted when a donation has been made
  event GrantDonation(
    uint96 indexed grantId,
    IERC20 indexed tokenIn,
    uint256 donationAmount,
    GrantRound[] rounds,
    uint256 time
  );

  // --- Constructor ---
  constructor(GrantRegistry _registry, IERC20 _donationToken) {
    // Validation
    require(_registry.grantCount() >= 0, "GrantRoundManager: Invalid registry");
    require(_donationToken.totalSupply() > 0, "GrantRoundManager: Invalid token");

    // Set state
    registry = _registry;
    donationToken = _donationToken;
  }

  // --- Core methods ---
  /**
   * @notice Creates a new GrantRound
   * @param _owner Grant round owner that has permission to update the metadata pointer
   * @param _payoutAdmin Grant round administrator that has permission to payout the matching pool
   * @param _matchingToken Address for the token used to payout match amounts at the end of a round
   * @param _startTime Unix timestamp of the start of the round
   * @param _endTime Unix timestamp of the end of the round
   * @param _metaPtr URL pointing to the grant round metadata
   */
  function createGrantRound(
    address _owner,
    address _payoutAdmin,
    IERC20 _matchingToken,
    uint256 _startTime,
    uint256 _endTime,
    MetaPtr calldata _metaPtr
  ) external {
    require(_matchingToken.totalSupply() > 0, "GrantRoundManager: Invalid matching token");
    GrantRound _grantRound = new GrantRound(
      _owner,
      _payoutAdmin,
      registry,
      donationToken,
      _matchingToken,
      _startTime,
      _endTime,
      _metaPtr
    );

    emit GrantRoundCreated(address(_grantRound));
  }

  /**
   * @notice Performs swaps if necessary and donates funds as specified
   * @param _swaps Array of SwapSummary objects describing the swaps required
   * @param _deadline Unix timestamp after which a swap will revert, i.e. swap must be executed before this
   * @param _donations Array of donations to execute
   * @dev `_deadline` is not part of the `_swaps` array since all swaps can use the same `_deadline` to save some gas
   * @dev Caller must ensure the input tokens to the _swaps array are unique
   */
  function donate(
    SwapSummary[] calldata _swaps,
    uint256 _deadline,
    Donation[] calldata _donations
  ) external payable {
    // Main logic
    _validateDonations(_donations);
    _executeDonationSwaps(_swaps, _deadline);
    _transferDonations(_donations);

    // Clear storage for refunds (this is set in _executeDonationSwaps)
    for (uint256 i = 0; i < _swaps.length; i++) {
      IERC20 _tokenIn = IERC20(_swaps[i].path[0]);
      swapOutputs[_tokenIn] = 0;
      donationRatios[_tokenIn] = 0;
    }
    for (uint256 i = 0; i < _donations.length; i++) {
      donationRatios[_donations[i].token] = 0;
    }
  }

  /**
   * @dev Validates the inputs to a donation call are valid, and reverts if any requirements are violated
   * @param _donations Array of donations that will be executed
   */
  function _validateDonations(Donation[] calldata _donations) internal {
    // TODO consider moving this to the section where we already loop through donations in case that saves a lot of
    // gas. Leaving it here for now to improve readability

    for (uint256 i = 0; i < _donations.length; i++) {
      // Validate grant exists
      require(_donations[i].grantId < registry.grantCount(), "GrantRoundManager: Grant does not exist in registry");

      // Used later to validate ratios are correctly provided
      donationRatios[_donations[i].token] = donationRatios[_donations[i].token].add(_donations[i].ratio);

      // Validate round parameters
      GrantRound[] calldata _rounds = _donations[i].rounds;
      for (uint256 j = 0; j < _rounds.length; j++) {
        require(_rounds[j].isActive(), "GrantRoundManager: GrantRound is not active");
        require(_rounds[j].registry() == registry, "GrantRoundManager: Round-Registry mismatch");
        require(
          donationToken == _rounds[j].donationToken(),
          "GrantRoundManager: GrantRound's donation token does not match GrantRoundManager's donation token"
        );
      }
    }
  }

  /**
   * @dev Performs swaps if necessary
   * @param _swaps Array of SwapSummary objects describing the swaps required
   * @param _deadline Unix timestamp after which a swap will revert, i.e. swap must be executed before this
   */
  function _executeDonationSwaps(SwapSummary[] calldata _swaps, uint256 _deadline) internal {
    for (uint256 i = 0; i < _swaps.length; i++) {
      // Validate output token is donation token (this can be done after the `continue` to save gas, but leaving it
      // here for now to minimize diff against GrantRoundManager.sol)
      address[] calldata _path = _swaps[i].path;
      IERC20 _outputToken = IERC20(_path[_path.length - 1]);
      require(_outputToken == donationToken, "GrantRoundManager: Output token must match donation token");

      // Validate ratios sum to 100%
      IERC20 _tokenIn = IERC20(_path[0]);
      require(donationRatios[_tokenIn] == WAD, "GrantRoundManager: Ratios do not sum to 100%");
      require(swapOutputs[_tokenIn] == 0, "GrantRoundManager: Swap parameter has duplicate input tokens");

      // WETH token donations are not supported, and only one WETH swap per transaction allowed
      require(
        _tokenIn != WETH || (_tokenIn == WETH && msg.value == _swaps[i].amountIn && msg.value > 0),
        "GrantRoundManager: WETH token donation issue"
      );

      // Do nothing if the swap input token equals donationToken
      if (_tokenIn == donationToken) {
        swapOutputs[_tokenIn] = _swaps[i].amountIn;
        continue;
      }

      // Get current balance of donation token, used to track swap outputss
      uint256 _initBalance = donationToken.balanceOf(address(this));

      // Execute swap
      if (_tokenIn != WETH) {
        // Swapping a token
        _tokenIn.safeTransferFrom(msg.sender, address(this), _swaps[i].amountIn);
        if (_tokenIn.allowance(address(this), address(router)) == 0) {
          _tokenIn.safeApprove(address(router), type(uint256).max);
        }

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
          _swaps[i].amountIn,
          _swaps[i].amountOutMin,
          _path,
          address(this),
          _deadline
        );
      } else {
        // Swapping ETH
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
          _swaps[i].amountOutMin,
          _path,
          address(this),
          _deadline
        );
      }

      // Save off output amount for later
      swapOutputs[_tokenIn] = donationToken.balanceOf(address(this)).sub(_initBalance);
    }
  }

  /**
   * @dev Core donation logic that transfers funds to grants
   * @param _donations Array of donations to execute
   */
  function _transferDonations(Donation[] calldata _donations) internal {
    for (uint256 i = 0; i < _donations.length; i++) {
      // Get data for this donation
      GrantRound[] calldata _rounds = _donations[i].rounds;
      uint96 _grantId = _donations[i].grantId;
      IERC20 _tokenIn = _donations[i].token;
      uint256 _donationAmount = (swapOutputs[_tokenIn].mul(_donations[i].ratio)) / WAD;
      require(_donationAmount > 0, "GrantRoundManager: Donation amount must be greater than zero"); // verifies that swap and donation inputs are consistent

      // Execute transfer
      emit GrantDonation(_grantId, _tokenIn, _donationAmount, _rounds, block.timestamp);
      address _payee = registry.getGrantPayee(_grantId);
      if (_tokenIn == donationToken) {
        _tokenIn.safeTransferFrom(msg.sender, _payee, _donationAmount); // transfer token directly from caller
      } else {
        donationToken.transfer(_payee, _donationAmount); // transfer swap output
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interfaces/IMetadataPointer.sol";

/**
 * @notice The Gitcoin GrantRegistry contract keeps track of all grants that have been created.
 * It is designed to be a singleton, i.e. there is only one instance of a GrantRegistry which
 * tracks all grants. It behaves as follows:
 *   - Anyone can create a grant by calling `createGrant`
 *   - A grant's `owner` can edit their grant using the `updateGrant` family of method
 *   - The `getAllGrants` and `getGrants` view methods are used to fetch grant data
 */
contract GrantRegistry {
  // --- Data ---
  /// @notice Number of grants stored in this registry
  uint96 public grantCount;

  /// @notice Grant object
  struct Grant {
    // Slot 1 (within this struct)
    // Using a uint96 for the grant ID means a max of 2^96-1 = 7.9e28 grants
    uint96 id; // grant ID, as
    address owner; // grant owner (has permissions to modify grant information)
    // Slot 2
    // Using uint48 for timestamps means a maximum timestamp of 2^48-1 = 281474976710655 = year 8.9 million
    uint48 createdAt; // timestamp the grant was created, uint48
    uint48 lastUpdated; // timestamp the grant data was last updated in this registry
    address payee; // address that receives funds donated to this grant
    // Slots 3+
    MetaPtr metaPtr; // metadata pointer
  }

  /// @notice Mapping from Grant ID to grant data
  mapping(uint96 => Grant) public grants;

  // --- Events ---
  /// @notice Emitted when a new grant is created
  event GrantCreated(uint96 indexed id, address indexed owner, address indexed payee, MetaPtr metaPtr, uint256 time);

  /// @notice Emitted when a grant's owner is changed
  event GrantUpdated(uint96 indexed id, address indexed owner, address indexed payee, MetaPtr metaPtr, uint256 time);

  // --- Core methods ---
  /**
   * @notice Create a new grant in the registry
   * @param _owner Grant owner (has permissions to modify grant information)
   * @param _payee Address that receives funds donated to this grant
   * @param _metaPtr metadata pointer
   */
  function createGrant(
    address _owner,
    address _payee,
    MetaPtr calldata _metaPtr
  ) external {
    uint96 _id = grantCount;
    grants[_id] = Grant(_id, _owner, uint48(block.timestamp), uint48(block.timestamp), _payee, _metaPtr);
    emit GrantCreated(_id, _owner, _payee, _metaPtr, block.timestamp);
    grantCount += 1;
  }

  /**
   * @notice Update the owner of a grant
   * @param _id ID of grant to update
   * @param _owner New owner address
   */
  function updateGrantOwner(uint96 _id, address _owner) external {
    Grant storage grant = grants[_id];
    require(msg.sender == grant.owner, "GrantRegistry: Not authorized");
    grant.owner = _owner;
    grant.lastUpdated = uint48(block.timestamp);
    emit GrantUpdated(grant.id, grant.owner, grant.payee, grant.metaPtr, block.timestamp);
  }

  /**
   * @notice Update the payee of a grant
   * @param _id ID of grant to update
   * @param _payee New payee address
   */
  function updateGrantPayee(uint96 _id, address _payee) external {
    Grant storage grant = grants[_id];
    require(msg.sender == grant.owner, "GrantRegistry: Not authorized");
    grant.payee = _payee;
    grant.lastUpdated = uint48(block.timestamp);
    emit GrantUpdated(grant.id, grant.owner, grant.payee, grant.metaPtr, block.timestamp);
  }

  /**
   * @notice Update the metadata pointer of a grant
   * @param _id ID of grant to update
   * @param _metaPtr New URL that points to grant metadata
   */
  function updateGrantMetaPtr(uint96 _id, MetaPtr calldata _metaPtr) external {
    Grant storage grant = grants[_id];
    require(msg.sender == grant.owner, "GrantRegistry: Not authorized");
    grant.metaPtr = _metaPtr;
    grant.lastUpdated = uint48(block.timestamp);
    emit GrantUpdated(grant.id, grant.owner, grant.payee, grant.metaPtr, block.timestamp);
  }

  /**
   * @notice Update multiple fields of a grant at once
   * @dev To leave a field unchanged, you must pass in the same value as the current value
   * @param _id ID of grant to update
   * @param _owner New owner address
   * @param _payee New payee address
   * @param _metaPtr New URL that points to grant metadata
   */
  function updateGrant(
    uint96 _id,
    address _owner,
    address _payee,
    MetaPtr calldata _metaPtr
  ) external {
    Grant memory _grant = grants[_id];
    require(msg.sender == _grant.owner, "GrantRegistry: Not authorized");
    grants[_id] = Grant(_id, _owner, _grant.createdAt, uint48(block.timestamp), _payee, _metaPtr);
    emit GrantUpdated(_id, _owner, _payee, _metaPtr, block.timestamp);
  }

  // --- View functions ---
  /**
   * @notice Returns an array of all grants and their on-chain data
   * @dev May run out of gas for large values `grantCount`, depending on the node's RpcGasLimit. In these cases,
   * `getGrants` can be used to fetch a subset of grants and aggregate the results of various calls off-chain
   */
  function getAllGrants() external view returns (Grant[] memory) {
    return getGrants(0, grantCount);
  }

  /**
   * @notice Returns a range of grants and their on-chain data
   * @param _startId Grant ID of first grant to return, inclusive, i.e. this grant ID is included in return data
   * @param _endId Grant ID of last grant to return, exclusive, i.e. this grant ID is NOT included in return data
   */
  function getGrants(uint96 _startId, uint96 _endId) public view returns (Grant[] memory) {
    require(_endId <= grantCount, "GrantRegistry: _endId must be <= grantCount");
    require(_startId <= _endId, "GrantRegistry: Invalid ID range");
    Grant[] memory grantList = new Grant[](_endId - _startId);
    for (uint96 i = _startId; i < _endId; i++) {
      grantList[i - _startId] = grants[i]; // use index of `i - _startId` so index starts at zero
    }
    return grantList;
  }

  /**
   * @notice Returns the address that will be used to pay out donations for a given grant
   * @dev The payee may be set to null address
   * @param _id Grant ID used to retrieve the payee address in the registry
   */
  function getGrantPayee(uint96 _id) public view returns (address) {
    require(_id < grantCount, "GrantRegistry: Grant does not exist");
    return grants[_id].payee;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IMetadataPointer.sol";
import "./GrantRegistry.sol";

contract GrantRound {
  using SafeERC20 for IERC20;

  // --- Data ---
  /// @notice Unix timestamp of the start of the round
  uint256 public immutable startTime;

  /// @notice Unix timestamp of the end of the round
  uint256 public immutable endTime;

  /// @notice Grant round payout administrator
  address public immutable payoutAdmin;

  /// @notice Grant round metadata administrator
  address public immutable metadataAdmin;

  /// @notice GrantsRegistry
  GrantRegistry public immutable registry;

  /// @notice Token used for all contributions. Contributions in a different token are swapped to this token
  IERC20 public immutable donationToken;

  /// @notice Token used to payout match amounts at the end of a round
  IERC20 public immutable matchingToken;

  /// @notice URL pointing to grant round metadata (for off-chain use)
  MetaPtr public metaPtr;

  /// @notice Set to true if grant round has ended and payouts have been released
  bool public hasPaidOut;

  // --- Events ---
  /// @notice Emitted when a grant round metadata pointer is updated
  event MetadataUpdated(MetaPtr oldMetaPtr, MetaPtr newMetaPtr);

  /// @notice Emitted when a contributor adds funds using the matching pool token
  event AddMatchingFunds(uint256 amount, address indexed contributor);

  /// @notice Emitted when the matching token is paid out
  event PaidOutGrants(uint256 amount);

  // --- Core methods ---
  /**
   * @notice Instantiates a new grant round
   * @param _metadataAdmin The address with the role that has permission to update the metadata pointer
   * @param _payoutAdmin Grant round administrator that has permission to payout the matching pool
   * @param _registry Address that contains the grant metadata
   * @param _donationToken Address of the ERC20 token in which donations are made
   * @param _matchingToken Address of the ERC20 token for accepting matching pool contributions
   * @param _startTime Unix timestamp of the start of the round
   * @param _endTime Unix timestamp of the end of the round
   * @param _metaPtr URL pointing to the grant round metadata
   */
  constructor(
    address _metadataAdmin,
    address _payoutAdmin,
    GrantRegistry _registry,
    IERC20 _donationToken,
    IERC20 _matchingToken,
    uint256 _startTime,
    uint256 _endTime,
    MetaPtr memory _metaPtr
  ) {
    require(_donationToken.totalSupply() > 0, "GrantRound: Invalid donation token");
    require(_matchingToken.totalSupply() > 0, "GrantRound: Invalid matching token");
    require(_startTime >= block.timestamp, "GrantRound: Start time has already passed");
    require(_endTime > _startTime, "GrantRound: End time must be after start time");

    metadataAdmin = _metadataAdmin;
    payoutAdmin = _payoutAdmin;
    hasPaidOut = false;
    registry = _registry;
    donationToken = _donationToken;
    matchingToken = _matchingToken;
    startTime = _startTime;
    endTime = _endTime;
    metaPtr = _metaPtr;
  }

  /**
   * @notice Before the round ends this method accepts matching pool funds
   * @param _amount The amount of matching token that will be sent to the contract for the matching pool
   */
  function addMatchingFunds(uint256 _amount) external {
    require(block.timestamp < endTime, "GrantRound: Method must be called before round has ended");
    matchingToken.safeTransferFrom(msg.sender, address(this), _amount);
    emit AddMatchingFunds(_amount, msg.sender);
  }

  /**
   * @notice When the round ends the payoutAdmin can send the remaining matching pool funds to a given address
   * @param _payoutAddress An address to receive the remaining matching pool funds in the contract
   */
  function payoutGrants(address _payoutAddress) external {
    require(block.timestamp >= endTime, "GrantRound: Method must be called after round has ended");
    require(msg.sender == payoutAdmin, "GrantRound: Only the payout administrator can call this method");
    uint256 balance = matchingToken.balanceOf(address(this));
    hasPaidOut = true;
    matchingToken.safeTransfer(_payoutAddress, balance);
    emit PaidOutGrants(balance);
  }

  /**
   * @notice Updates the metadata pointer to a new location
   * @param _newMetaPtr A string where the updated metadata is stored
   */
  function updateMetadataPtr(MetaPtr calldata _newMetaPtr) external {
    require(msg.sender == metadataAdmin, "GrantRound: Action can be performed only by metadataAdmin");
    emit MetadataUpdated(metaPtr, _newMetaPtr);
    metaPtr = _newMetaPtr;
  }

  /**
   * @notice Returns true if the round is active, false otherwise
   */
  function isActive() public view returns (bool) {
    return block.timestamp >= startTime && block.timestamp < endTime;
  }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.7.6;

struct MetaPtr {
  // Protocol ID corresponding to a specific protocol. More info at https://github.com/dcgtc/protocol-ids
  uint256 protocol;
  // Pointer to fetch metadata for the specified protocol
  string pointer;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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