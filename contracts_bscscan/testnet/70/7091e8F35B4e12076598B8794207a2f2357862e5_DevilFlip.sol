/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}


// File @chainlink/contracts/src/v0.8/[email protected]

pragma solidity ^0.8.0;

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
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
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
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}


// File @chainlink/contracts/src/v0.8/[email protected]

pragma solidity ^0.8.0;

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
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

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
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
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
    nonces[_keyHash] = nonces[_keyHash] + 1;
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
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}


// File contracts/interfaces/IPancakeRouter01.sol

pragma solidity ^0.8.0;

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


// File contracts/interfaces/IPancakeRouter02.sol

pragma solidity ^0.8.0;

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


// File contracts/interfaces/IPancakeSwapV2Pair.sol

pragma solidity >=0.5.0;

interface IPancakeSwapV2Pair {
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
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File contracts/interfaces/IPancakeV2Factory.sol

pragma solidity ^0.8.0;

interface IPancakeV2Factory {
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


// File contracts/DevilFlip.sol

pragma solidity ^0.8.0;







contract DevilFlip is
    IERC20,
    IERC20Metadata,
    Context,
    Ownable,
    VRFConsumerBase
{
    string private _name;
    string private _symbol;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    uint256 public nextSpinTimestamp;
    bool public isLocked;

    // eg. 0.01, 0.1 ... 1, 10, 100
    uint32 public constant FEE_DECIMALS = 2;

    // Wagyu
    address public WAGYU_DEV_TEAM;
    address public WAGYU;

    uint256 public devilAccountScore; // Counts in DFLIP
    uint256 public angelAccountScore; // Counts in WBNB

    // Configurable Fees
    // Consider the fee decimals:
    // 1 = 0.01%, 10 = 0.1%, 100 = 1%, 1.000 = 10%, 10.000 = 100%
    uint32 public FEE_GAME_TOKENOMICS = 500;
    uint32 public FEE_WAGYU_DEV_TEAM = 200;
    uint32 public FEE_WAGYU_BUYBACK = 200;
    uint32 public FEE_LIQUIDITY_POOL = 100;

    // Token Addresses
    address public WBNB;

    // Zero Address
    address public constant ZERO_ADDRESS = address(0);

    // PancakeSwap Router Address
    IPancakeRouter02 public immutable PancakeSwapRouter;
    address public pancakeswapV2Pair;

    mapping(address => bool) private _isPancakeSwapPair;

    uint256 private _gameTokenomicsFeeOnHold;
    uint256 private _liquidityPoolFeeOnHold;

    // ChainLink
    // FIXME: Later replace this with right addresses
    // Binance Smart Chain
    // LINK Token	                    0x404460C6A5EdE2D891e8297795264fDe62ADBB75
    // VRF Coordinator	                0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31
    // Key Hash	                        0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c
    // Fee	                            0.2 LINK
    address public VRFCoordinator = 0xa555fC018435bef5A13C6c6870a9d4C11DEC329C;
    address public LINKAddress = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06;
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 private lastRandomResult;

    event GameTokenomicsTransactionFeeCollected(uint256 amount);
    event WagyuDevTeamTransactionFeeCollected(uint256 amount);
    event WagyuBuybackTransactionFeeCollected(uint256 amount);
    event LiquidityPoolTransactionFeeCollected(uint256 amount);
    event Winner(uint256 winnerIndex);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor()
        VRFConsumerBase(VRFCoordinator, LINKAddress)
    {
        _name = "DevilFlip";
        _symbol = "DFLIP";

        WAGYU = 0xF4d447efa1A4Eaf2cf9D354D2c58B94B0adb9Abf;
        WAGYU_DEV_TEAM = 0x651F1B34370762e5D690f5817fa1464b596093a8;

        nextSpinTimestamp = block.timestamp + 1 days;

        // IPancakeRouter02 _pancakeswapV2Router = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        IPancakeRouter02 _pancakeswapV2Router = IPancakeRouter02(0xCc7aDc94F3D80127849D2b41b6439b7CF1eB4Ae0);
        WBNB = _pancakeswapV2Router.WETH();
        
        /// @notice We are going to creat PancakeSwapV2 Pair and add it to the list of Pairs
        pancakeswapV2Pair = IPancakeV2Factory(_pancakeswapV2Router.factory())
            .createPair(address(this), WBNB);
        _isPancakeSwapPair[pancakeswapV2Pair] = true;

        PancakeSwapRouter = _pancakeswapV2Router;

        /// @notice Setting Chainlink keyHash and fee amount
        /// @dev This data is provide by ChainLink
        keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
        fee = 0.1 * 10**18; // 0.1 LINK

        _mint(msg.sender, 10000000 * 10**18);
    }

    modifier lock() {
        require(
            !isLocked,
            "During 'dumping' or 'pumping' transactions will be reverted"
        );
        _;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        override
        lock
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        lock
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        lock
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        // If contract transfers or someone transfers to contract the fee will not be charged
        // Checks whether we are transfering to contract or contract transfers
        // Fees will not be charged in this way
        // If contract transfers or someone transfers to contract the fee will not be charged

        if (
            sender != address(this) &&
            recipient != address(this) &&
            sender != owner() &&
            recipient != owner() &&
            recipient != address(PancakeSwapRouter) &&
            sender != address(PancakeSwapRouter)
        ) {
            require(
                !isLocked,
                "During 'dumping' or 'pumping' transactions are reverted"
            );
            uint256 gameTokenomicsFeeAmount = (amount * FEE_GAME_TOKENOMICS) /
                (10**FEE_DECIMALS * 100);

            uint256 wagyuDevTeamFeeAmount = (amount * FEE_WAGYU_DEV_TEAM) /
                (10**FEE_DECIMALS * 100);

            uint256 wagyuBuybackFeeAmount = (amount * FEE_WAGYU_BUYBACK) /
                (10**FEE_DECIMALS * 100);

            uint256 liquidityPoolFeeAmount = (amount * FEE_LIQUIDITY_POOL) /
                (10**FEE_DECIMALS * 100);

            // Buying Token
            if (
                _isPancakeSwapPair[sender] 
            ) {
                // Collecting tokenomics and liquidity fees
                _gameTokenomicsFeeOnHold += gameTokenomicsFeeAmount;
                _liquidityPoolFeeOnHold += liquidityPoolFeeAmount;

                // // Charging Fee - FEE_WAGYU_DEV_TEAM
                _balances[WAGYU_DEV_TEAM] += wagyuDevTeamFeeAmount;
                emit WagyuDevTeamTransactionFeeCollected(wagyuDevTeamFeeAmount);

                // // Charging Fee - FEE_WAGYU_BUYBACK
                chargeBuybackFee(wagyuBuybackFeeAmount);

                amount -= (gameTokenomicsFeeAmount +
                    wagyuBuybackFeeAmount +
                    wagyuDevTeamFeeAmount +
                    liquidityPoolFeeAmount);

                _balances[recipient] += amount;

                emit Transfer(sender, recipient, amount);
            } else if (_isPancakeSwapPair[recipient]) {
                // Selling Token or Adding liquidity
                
                // Selling holding tokens
                chargeGametokenomicsFee(_gameTokenomicsFeeOnHold);
                chargeLiquidityFee(_liquidityPoolFeeOnHold);

                _gameTokenomicsFeeOnHold = 0;
                _liquidityPoolFeeOnHold = 0;

                // Charging Fee - FEE_GAME_TOKENOMICS
                chargeGametokenomicsFee(gameTokenomicsFeeAmount);

                // Charging Fee - FEE_WAGYU_DEV_TEAM
                _balances[WAGYU_DEV_TEAM] += wagyuDevTeamFeeAmount;
                emit WagyuDevTeamTransactionFeeCollected(wagyuDevTeamFeeAmount);

                // Charging Fee - FEE_WAGYU_BUYBACK
                chargeBuybackFee(wagyuBuybackFeeAmount);

                // Charging Fee - FEE_LIQUIDITY_POOL
                chargeLiquidityFee(liquidityPoolFeeAmount);

                // Net amount (initial amount - fees)
                amount -= (gameTokenomicsFeeAmount +
                    wagyuDevTeamFeeAmount +
                    wagyuBuybackFeeAmount +
                    liquidityPoolFeeAmount);

                _balances[recipient] += amount;
                emit Transfer(sender, recipient, amount);
            } else {
                _balances[recipient] += amount;

                emit Transfer(sender, recipient, amount);
            }
        } else {
            _balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);
        }
    }

    function chargeLiquidityFee(uint256 feeAmount) internal {
        if (feeAmount != 0) {
            uint256 halfOfLiquidityPoolFee = feeAmount / 2;
            uint256 otherHalf = feeAmount - halfOfLiquidityPoolFee;

            _balances[address(this)] += feeAmount;

            uint256 bnbAmount = swapDFLIPForBNBSupportingFees(
                otherHalf,
                address(this)
            );

            addLiquidity(halfOfLiquidityPoolFee, bnbAmount);

            emit LiquidityPoolTransactionFeeCollected(feeAmount);
        }
    }

    function chargeBuybackFee(uint256 feeAmount) internal {
        if (feeAmount != 0) {
            // FIXME: This address later will be replaced probably with swap logic
            _balances[
                address(WAGYU)
            ] += feeAmount;

            emit WagyuBuybackTransactionFeeCollected(feeAmount);
        }
    }

    function chargeGametokenomicsFee(uint256 feeAmount) internal {
        if (feeAmount != 0) {
            // Calculatung 50% of GameTokenomics
            uint256 halfOfTokenomicsFee = feeAmount / 2;
            uint256 otherHalf = feeAmount - halfOfTokenomicsFee;

            // 50 % of DFLIP goes to DevilAccount
            devilAccountScore += halfOfTokenomicsFee;

            // Another 50% will be converted to BNB and transferd to AngelAccount
            _balances[address(this)] += otherHalf;

            uint256 bnbAmount = swapDFLIPForBNBSupportingFees(
                otherHalf,
                address(this)
            );

            angelAccountScore += bnbAmount;

            emit GameTokenomicsTransactionFeeCollected(feeAmount);
        }
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @notice This function will change current WagyuDevTeam Address
    /// @param newAddress new address parameter
    function setWagyuDevTeamAddress(address newAddress) external onlyOwner {
        require(
            newAddress != WAGYU_DEV_TEAM,
            "Provided address is already set"
        );

        WAGYU_DEV_TEAM = newAddress;
    }

    /// @notice This function changes current GameTokenomics Fee
    /// @notice Provided Fee value will be charged for each transaction
    /// @param newValue uint32 new fee falue
    function setGameTokenomicsFee(uint32 newValue) external onlyOwner {
        require(
            FEE_GAME_TOKENOMICS != newValue,
            "Provided fee value is already set"
        );
        require(newValue <= 10000, "Provided fee value is greater than 100%");

        FEE_GAME_TOKENOMICS = newValue;
    }

    /// @notice This function changes current WagyDevTeam Fee
    /// @notice Provided Fee value will be charged for each transaction
    /// @param newValue uint32 new fee falue
    function setWagyuDevTeamFee(uint32 newValue) external onlyOwner {
        require(
            FEE_WAGYU_DEV_TEAM != newValue,
            "Provided fee value is already set"
        );
        require(newValue <= 10000, "Provided fee value is greater than 100%");

        FEE_WAGYU_DEV_TEAM = newValue;
    }

    /// @notice This function changes current WagyuBuyback Fee
    /// @notice Provided Fee value will be charged for each transaction
    /// @param newValue uint32 new fee falue
    function setWagyuBuybackFee(uint32 newValue) external onlyOwner {
        require(
            FEE_WAGYU_BUYBACK != newValue,
            "Provided fee value is already set"
        );
        require(newValue <= 10000, "Provided fee value is greater than 100%");

        FEE_WAGYU_BUYBACK = newValue;
    }

    /// @notice This function changes current LiquidityPool Fee
    /// @notice Provided Fee value will be charged for each transaction
    /// @param newValue uint32 new fee falue cannot be the same as current
    function setLiquidityPoolFee(uint32 newValue) external onlyOwner {
        require(
            FEE_LIQUIDITY_POOL != newValue,
            "Provided fee value is already set"
        );
        require(newValue <= 10000, "Provided fee value is greater than 100%");

        FEE_LIQUIDITY_POOL = newValue;
    }

    /// @notice Swaps an exact amount of tokens for as much BNB as possible
    /// @param tokenAmount The amount of input tokens to send
    /// @param to Recipient of BNB
    /// @return Returns uin256 swapped amount
    function swapDFLIPForBNBSupportingFees(uint256 tokenAmount, address to)
        private
        returns (uint256)
    {
        /// @dev path is an array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        /// @dev Contract should give the router an allowence to be able to perform swap
        _approve(address(this), address(PancakeSwapRouter), tokenAmount);

        uint256 balanceBefore = address(this).balance;

        PancakeSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );

        return (address(this).balance - balanceBefore);
    }

    /// @notice Adds liquidity to an DFLIP <-> BNB pool with BNB
    /// @param tokenAmount The amount of token to add
    /// @return amountToken The amount of token sent to the pool
    /// @return amountBNB The amount of ETH converted to WETH and sent to the pool
    /// @return liquidity The amount of liquidity tokens minted
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount)
        private
        returns (
            uint256 amountToken,
            uint256 amountBNB,
            uint256 liquidity
        )
    {
        /// @dev Contract should give the router an allowence to be able to perform swap
        _approve(address(this), address(PancakeSwapRouter), tokenAmount);

        /// @notice The recipient of liquidity tokens will be owner (contract deployer)
        /// @param value: tokenAmount is actually bnbAmount to be sent
        /// @param address(this) is current contracts address (token)
        return
            PancakeSwapRouter.addLiquidityETH{value: bnbAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                owner(),
                block.timestamp
            );
    }

    /// @notice Adds Approved PancakeSwarpPair
    /// @param _address Adds provided address to the mapping
    function addPancakeSwapV2PairAddress(address _address) public onlyOwner {
        require(
            !_isPancakeSwapPair[_address],
            "Provided pair address already exists"
        );
        _isPancakeSwapPair[_address] = true;
    }

    /// @notice Removes Approved PancakeSwarpPair
    /// @param _address Removes provided address from the mapping
    function removePancakeSwapV2PairAddress(address _address) public onlyOwner {
        require(_isPancakeSwapPair[_address], "Provided address doesnt exist");
        _isPancakeSwapPair[_address] = false;
    }

    /// @notice Uses random number to choose winner
    /// @param randomNumber uint256 random number generated by ChainLink
    function _spin(uint256 randomNumber) public {
        /// @dev Perhaps there are some tokens on hold
        chargeGametokenomicsFee(_gameTokenomicsFeeOnHold);
        chargeLiquidityFee(_liquidityPoolFeeOnHold);

        /// @notice If (randomNumber) % 2 equals:
        //          0 - Devil Wins
        //          1 - Angel Wins
        if ((randomNumber % 2) > 0) {
            // Angel Won
            _balances[address(this)] += devilAccountScore;

            _approve(
                address(this),
                address(PancakeSwapRouter),
                devilAccountScore
            );
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = WBNB;

            uint256[] memory amounts = PancakeSwapRouter.swapExactTokensForETH(
                devilAccountScore,
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 tokenAmount = amounts[0];
            uint256 bnbAmount = amounts[1];

            devilAccountScore -= tokenAmount;
            angelAccountScore += bnbAmount;

            emit Winner(1);
        } else {
            // Devil Won
            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = address(this);

            uint256[] memory amounts = PancakeSwapRouter.swapExactETHForTokens{
                value: angelAccountScore
            }(0, path, owner(), block.timestamp);
            uint256 bnbAmount = amounts[0];
            uint256 tokenAmount = amounts[1];

            devilAccountScore += tokenAmount;
            angelAccountScore -= bnbAmount;

            emit Winner(0);
        }

        // FIXME: 24 hours should be
        nextSpinTimestamp += 5 minutes;
    }

    /// @notice Generates random number via Chainlink VRF
    function spin() public returns (bytes32 requestId) {
        require(
            block.timestamp >= nextSpinTimestamp,
            "It's too early to call this function"
        );
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );

        isLocked = true;

        return requestRandomness(keyHash, fee);
    }

    /// @notice Callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        lastRandomResult = randomness;

        _spin(lastRandomResult);

        isLocked = false;
    }

    /// @notice Changes current keyHash
    /// @param newKeyHash bytes32 new hash value
    function changeKeyHash(bytes32 newKeyHash) external onlyOwner {
        keyHash = newKeyHash;
    }

    /// @notice Changes current link fee amount
    /// @dev Perhaps chainlink will change this value in the future, so we should change it here also
    /// @param newFee uint256 new fee amount
    function changeLINKFee(uint256 newFee) external onlyOwner {
        fee = newFee;
    }

    /// @notice Withdraws ERC20 Tokens from contract
    /// @param tokenAddress ERC20 token address
    /// @param to to whom it will be transfered
    /// @param amount amount to be transfered
    function withdrawERC20Token(
        address tokenAddress,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(to, amount);
    }

    receive() external payable {}
}