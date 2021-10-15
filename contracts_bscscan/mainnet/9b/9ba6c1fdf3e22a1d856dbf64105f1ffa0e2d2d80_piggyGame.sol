/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}



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




/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


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







/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}










/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}




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

abstract contract ProxySafeVRFConsumerBase is VRFRequestIDBase {

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

  LinkTokenInterface internal LINK;
  address internal vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;



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


// import "./ProxySafeOwnable.sol";

interface IRewardNFT is IERC721 {
    function mint(address to, uint16 set, uint8 number) external;
    function metadataOf(uint256 id) external returns (uint16, uint8);
    function totalCardsOf(uint16 id) external returns (uint8);
    function forgeBurn(uint256 id) external;
    function addSet(uint16 set, uint8 number) external;
}

contract piggyGame is OwnableUpgradeable, ProxySafeVRFConsumerBase  {
    // using Address for address;

    // Reward NFT address
    IRewardNFT public rewardNFT;
    
    // The swap router, modifiable.
    IUniswapV2Router02 public pancakeSwapRouter;

    // Chainlink randomness requests
    struct ChainlinkRequest {
        address requester;
        bool fulfilled;
        uint8[] grades;
        uint256 seed;
    }

    mapping(bytes32 => ChainlinkRequest) requests;

    struct BoosterPack {
        uint256 seed;
        uint8[] grades;
    }

    struct Player {
        uint256 gamesPlayed;
        uint16 season;
        address team;
        uint32 winsBeforeJoin;
        uint256 experience;
        bytes32[] boosterPacks;
        uint256 numBoosterPacks;
        uint8[] unclaimedPacks;
    }
    // Players
    mapping(address => Player) public players;

    struct Team {
        bool enabled;
        uint32 wins;
        uint256 damagePoints;
    }

    // Teams
    mapping(address => Team) public teams;

    uint32 public latestTeam;

    address[] public activeTeams;

    // User Piggy Balance
    mapping(address => uint256) public balances;

    struct RewardPool {
        uint256 balance; // BNB Balance
        uint256 remainingClaims; // claims not yet made
        uint256 rewardPerNFT; // How much each NFT gets
        bool open; // Whether it can be withdrawn from
        mapping(uint256 => bool) nftsClaimed; // ID of NFTs that have already claimed this prize
    }
    // Reward pools (season -> pools)
    mapping (uint16 => RewardPool) public rewardPools;
    
    // Thresholds for different booster pack grades
    struct Thresholds {
        uint256 grade1;
        uint256 grade2;
        uint256 grade3;
        uint256 grade4;
    }

    
    mapping(address => Thresholds) thresholds;
    struct RareChance {
        uint8 grade2;
        uint8 grade3;
        uint8 grade4;
    }
    RareChance public rareChance;

    mapping (uint8 => uint256) public createdCards; // Counter for each card number created
    
    bool public open;

    uint16 public season;

    uint256 public joinFee; // 0.01 BNB
    
    // Chainlink
    bytes32 internal keyHash;
    uint256 internal fee;

    // Dev rewards
    uint256 public devPool;

    address piggyAddress;
    uint256 public minPiggy; // Min piggy to hold in order to join

    uint256 public redeemFee;

    address public feeDestination;

    // constructor(address _piggyToken, address _secondToken, address _router, address _coordinator, address _linkToken, bytes32 _hash, uint256 _fee)
    //  {
    //     _setOwner(_msgSender());
    //     vrfCoordinator = _coordinator;
    //     LINK = LinkTokenInterface(_linkToken);

    //     keyHash = _hash;
    //     fee = _fee;
    //     pancakeSwapRouter = IUniswapV2Router02(_router);
    //     piggyAddress = _piggyToken;
    //     linkAddress = _linkToken;

    //     addTeam(_piggyToken, 1 * 10**9 * 10**9, 2 * 10**9 * 10**9, 3 * 10**9 * 10**9,  5 * 10**9 * 10**9);

    //     addTeam(_secondToken, 1 * 10**9 * 10**9, 2 * 10**9 * 10**9, 3 * 10**9 * 10**9,  5 * 10**9 * 10**9);
    // }

    function initialize(address _piggyToken, address _secondToken, address _router, address _coordinator, address _linkToken, bytes32 _hash, uint256 _fee) external initializer {

        vrfCoordinator = _coordinator;
        LINK = LinkTokenInterface(_linkToken);

        keyHash = _hash;
        fee = _fee;
        pancakeSwapRouter = IUniswapV2Router02(_router);
        piggyAddress = _piggyToken;


        rareChance = RareChance({
            grade2: 60, // 1 in 30 Chance
            grade3: 10, // 1 in 10 Chance
            grade4: 5   // 1 in 5 Chance
        });
        feeDestination = msg.sender;
        OwnableUpgradeable.__Ownable_init_unchained();
        joinFee = 10000000000000000;
        minPiggy = 0 * 10**9;
        redeemFee = 10000000000000000;
        // Loss target: 0.003, 0.01, 0.06, 0.12 BNB

        // 0.01 BNB, 0.03 BNB, 0.18 BNB, 0.36 BNB
        addTeam(_piggyToken, 2182910000 * 10**9, 6548650000 * 10**9, 39288500000 * 10**9,  78568700000 * 10**9);

        // 0.018 BNB, 0.08 BNB, 0.48 BNB, 0.96 BNB
        addTeam(_secondToken, 5809940000 * 10**9, 25563400000 * 10**9, 144074000000 * 10**9, 268593000000 * 10**9);

        // Monsta
        // 2397 27993 167958 335916
    }

    event SeasonClose(address indexed owner, uint32 indexed season, address indexed winner);
    event SeasonOpen(address indexed owner, uint32 indexed season);
    event TeamAdded(address indexed owner, address indexed team);
    event JoinedGame(address indexed player, uint256 indexed season, address indexed team);
    event TokensPurchased(address indexed player, uint256 amount, uint256 minAmount, uint256 BNBSent);
    event Deposit(address indexed player, uint256 amount);
    event Withdrawal(address indexed player, uint256 amount);
    event Attack(address indexed player, address indexed team, uint256 amount, uint256 ethAmount, uint256 tokensReturned, uint256 BalanceChange);
    event ReceivedBoosterPack(address indexed requester, uint256 randomness);
    event TeamAssigned(address indexed player, address indexed team);
    event BoosterPackOpened(address indexed player, uint8 nonce);
    event NFTAwarded(address indexed player, uint16 indexed set, uint8 indexed number, bool rare);
    event LegendaryForged(address indexed player, uint16 indexed set);
    event ThresholdsSet(address indexed owner, uint256 grade1, uint256 grade2, uint256 grade3, uint256 grade4);
    event RareChanceSet(address indexed owner, uint256 grade2, uint256 grade3, uint256 grade4);
    event PoolOpened(uint16 indexed season, uint256 totalClaims, uint256 initialBalance, uint256 rewardPerNFT);
    event LegendaryRewardClaimed(uint16 indexed rewardSeason, uint16 indexed currentSeason, uint256 indexed NFT, uint16 NFTSet);
    event PoolClosedAndFundsTransferred(uint16 indexed poolSeason, uint16 indexed currentSeason, uint256 amount);

    // To receive BNB from pancakeSwapRouter when swapping
    receive() external payable {}

    function getJoinFee() external view returns (uint256) {
        return joinFee;
    }
    function getRedeemFee() external view returns (uint256) {
        return redeemFee;
    }
    function getMinPiggy() external view returns (uint256) {
        return minPiggy;
    }
    function isGameOpen() external view returns (bool) {
        return open;
    }
    function currentSeason() external view returns (uint16) {
        return season;
    }
    function balanceOf(address _player) external view returns (uint256) {
        return balances[_player];
    }
    function boosterPackBalanceOf(address _player) external view returns(uint256){
        return players[_player].numBoosterPacks;
    }
    function totalExperienceOf(address _player) external view returns(uint256){
        return players[_player].experience;
    }
    function teamOf(address _player) external view returns(address){
        return players[_player].team;
    }
    function getThresholds(address _player) external view returns(uint256, uint256, uint256, uint256) {
        address teamAddress = players[_player].team;
        return (thresholds[teamAddress].grade1, thresholds[teamAddress].grade2, thresholds[teamAddress].grade3, thresholds[teamAddress].grade4);
    }
    function hasPlayerJoined(address _player) external view returns(bool) {
        return players[_player].season == season;
    }
    function getRareChances() external view returns(uint8, uint8, uint8) {
        return (rareChance.grade2, rareChance.grade3, rareChance.grade4);
    }
    function teamDamageOf(address teamId) external view returns(uint256) {
        return teams[teamId].damagePoints;
    }
    function teamWinsOf(address teamId) external view returns(uint32) {
        return teams[teamId].wins;
    }
    function getActiveTeams() external view returns(address[] memory) {
        return activeTeams;
    }
    function playerWins(address _player) external view returns(uint32){
        address team = players[_player].team;
        uint32 winsBeforeJoin = players[_player].winsBeforeJoin;
        require(teams[team].wins >= winsBeforeJoin, "Wins before join higher than total wins");
        return teams[team].wins - winsBeforeJoin;
    }
    function tokenInfo(address teamAddress) external view returns (uint8, string memory, string memory) {
        return (IBEP20(teamAddress).decimals(), IBEP20(teamAddress).symbol(), IBEP20(teamAddress).name());
    }

    function tokenBalanceOf(address player) external view returns (uint256) {
        address teamAddress = players[player].team;
        return IBEP20(teamAddress).balanceOf(player);
    }
    function unclaimedBoosterPacksOf(address player) external view returns (uint256) {
        return players[player].unclaimedPacks.length;
    }

    function isNFTRedeemable(uint256 nftId, uint16 poolId) external view returns (bool) {
        return rewardPools[poolId].nftsClaimed[nftId] == false;
    }
    function setOpen(bool isOpen) external onlyOwner {
        open = isOpen;
    }
    function setSeason(uint16 _season) external onlyOwner {
        season = _season;
    }
    function openSeason() external onlyOwner {
        require(open == false, "Season Open");
        season += 1;
        open = true;
        rewardNFT.addSet(season, 7);
        emit SeasonOpen(msg.sender, season);
    }
    function closeSeason() external onlyOwner {
        open = false;
        uint256 lowestDamagePoints = teams[activeTeams[0]].damagePoints;
        address winningTeam = activeTeams[0];
        for (uint32 i = 0; i < activeTeams.length; i++) {
            uint256 teamDamagePoints = teams[activeTeams[i]].damagePoints;
            if (teamDamagePoints < lowestDamagePoints){
                lowestDamagePoints = teamDamagePoints;
                winningTeam = activeTeams[i];
            }
            teams[activeTeams[i]].damagePoints = 0;
        }
        teams[winningTeam].wins += 1;
        openPool();
        emit SeasonClose(msg.sender, season, winningTeam);
    }

    function addTeam(address teamTokenAddress, uint256 grade1, uint256 grade2, uint256 grade3, uint256 grade4) public onlyOwner {
        teams[teamTokenAddress].enabled = true;
        activeTeams.push(teamTokenAddress);
        setThresholds(teamTokenAddress, grade1, grade2, grade3, grade4);
        emit TeamAdded(msg.sender, teamTokenAddress);
    }
    function withdrawAllDevETH(address payable _to) external {
        require(devPool > 0, "No funds");
        require(msg.sender == feeDestination);
        uint256 withdrawAmount = devPool;
        devPool = 0;
        _to.transfer(withdrawAmount);
    }
    function changeFeeDestination(address newFeeDestination) external {
        require(msg.sender == feeDestination);
        feeDestination = newFeeDestination;
    }
    function withdrawLink(address payable _to, uint256 amount) external onlyOwner {
        LINK.transfer(_to, amount);
    }
    function setFeesAndJoinReq(uint256 newJoinFee, uint256 newMinPiggy, uint256 newRedeemFee) external onlyOwner {
        joinFee = newJoinFee;
        minPiggy = newMinPiggy;
        redeemFee = newRedeemFee;
    }
    function setTeamEnabled(address teamAddress, bool enabled) external onlyOwner {
        teams[teamAddress].enabled = enabled;
    }
    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updatePancakeSwapRouter(address _router) external onlyOwner {
        pancakeSwapRouter = IUniswapV2Router02(_router);
    }
    function updateNFTAddress(IRewardNFT _rewardNFTAddress) external onlyOwner {
        rewardNFT = _rewardNFTAddress;
    }

    function join(address teamTokenAddress) external payable {
        require(open, "Game closed");
        require(msg.value == joinFee, "Value != fee");
        require(players[msg.sender].season != season, "Already joined");
        require(IBEP20(piggyAddress).balanceOf(msg.sender) >= minPiggy, "Insuff. piggy");
        players[msg.sender].season = season;

        // Add join fee to reward pool for this season
        uint256 userDeposit = msg.value;
        devPool += userDeposit/2;
        userDeposit -= userDeposit/2;
        rewardPools[season].balance += userDeposit;
        
        if (players[msg.sender].team == address(0)) {
            require(teams[teamTokenAddress].enabled == true, "Team invalid");
            players[msg.sender].team = teamTokenAddress;
            emit TeamAssigned(msg.sender, teamTokenAddress);
        }
        emit JoinedGame(msg.sender, season, teamTokenAddress);
    }

    function buyTokens(uint256 minTokens) external payable {
        require(open, "Game closed");
        require(msg.value > 0, "No BNB");
        require(players[msg.sender].team != address(0), "User not in team");
        require(teams[players[msg.sender].team].enabled, "Own Team disabled");
        IBEP20 teamToken = IBEP20(players[msg.sender].team);
        // Initial ETH (BNB) balance of the contract without the BNB just sent to it
        uint256 initialETHBalance = address(this).balance - msg.value;
        uint256 initialTokenBalance = teamToken.balanceOf(address(this));
        swapEthForExactTokens(msg.value, minTokens);
        uint256 finalTokenBalance = teamToken.balanceOf(address(this));
        require(finalTokenBalance > initialTokenBalance, "No Tokens");
        balances[msg.sender] = balances[msg.sender] + finalTokenBalance - initialTokenBalance;
        // Send back leftover
        require(address(this).balance >= initialETHBalance, "Balance < initial pretransfer");
        uint256 leftoverETH = address(this).balance - initialETHBalance; // The eth sent but left over
        require(leftoverETH < msg.value, "Leftover >= sent");
        payable(msg.sender).transfer(leftoverETH);
        require(address(this).balance >= initialETHBalance, "Balance < initial");
        emit TokensPurchased(msg.sender, finalTokenBalance - initialTokenBalance, minTokens, msg.value);
    }

    // function deposit(uint256 amount) external {
    //     require(open, "Game closed");
    //     require(players[msg.sender].team != address(0), "User not in team");
    //     IBEP20 teamToken = IBEP20(players[msg.sender].team);
    //     uint256 tokenbalance = teamToken.balanceOf(msg.sender);
    //     require(tokenbalance >= amount, "Insufficient funds");
    //     uint256 previousBalance = teamToken.balanceOf(address(this));
    //     // Transfer tokens to the game contract
    //     teamToken.transferFrom(msg.sender, address(this), amount);
    //     uint256 currentBalance = teamToken.balanceOf(address(this));
    //     require(currentBalance > previousBalance, "Negative Increase");
    //     balances[msg.sender] = balances[msg.sender] + (currentBalance - previousBalance);
    //     emit Deposit(msg.sender, amount);
    // }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insuff. balance");
        require(players[msg.sender].team != address(0), "Not in team");
        IBEP20 teamToken = IBEP20(players[msg.sender].team);
        uint256 previousBalance = teamToken.balanceOf(address(this));
        teamToken.transfer(msg.sender, amount);
        balances[msg.sender] = balances[msg.sender] - amount;
        require((previousBalance - teamToken.balanceOf(address(this))) <= amount, "Balance dec > amount");
        emit Withdrawal(msg.sender, amount);
    }

    function attack(uint256 amount, address team) external {
        require(open, "Game closed");
        require(season > 0, "Season 0");
        require(players[msg.sender].season == season, "Player not joined");
        require(players[msg.sender].team != team, "Friendly Fire");
        require(players[msg.sender].team != address(0), "Not on a team");
        require(teams[team].enabled, "Team invalid");
        require(teams[players[msg.sender].team].enabled, "Own Team disabled");
        require(balances[msg.sender] >= amount, "Insuff. balance");
        // The team's corresponding token
        IBEP20 teamToken = IBEP20(players[msg.sender].team);

        uint256 initialBalance = teamToken.balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amount); // Sell tokens for ETH

        uint256 afterBalance = teamToken.balanceOf(address(this));
        uint256 afterETHBalance = address(this).balance;

        uint256 tokensSold = initialBalance - afterBalance; // Tokens sold in the first swap
        require(tokensSold <= amount, "Contract balance dec > amount"); // Fails on ==, why?

        uint256 ETHReceived = afterETHBalance - initialETHBalance; // ETH Received from token sale
        require(afterETHBalance > initialETHBalance, "Neg. BNB from selling tokens");

        swapEthForTokens(ETHReceived); // Buy tokens for ETH

        require(address(this).balance == initialETHBalance, "Contract BNB var.");

        uint256 tokensReceived = teamToken.balanceOf(address(this)) - afterBalance;
        require(teamToken.balanceOf(address(this)) > afterBalance, "Tokens lost in purchase");
        require(tokensReceived < amount, "Tokens inc. after atk");
        require(initialBalance > teamToken.balanceOf(address(this)), "Token Balance not dec.");
        require((initialBalance - teamToken.balanceOf(address(this))) < balances[msg.sender], "Balance dec > Pl. Balance");

        // Change in piggy balance is charged to the player
        balances[msg.sender] -= initialBalance - teamToken.balanceOf(address(this));

        requestReward(amount);
        players[msg.sender].gamesPlayed += 1;
        players[msg.sender].experience += ETHReceived;
        teams[team].damagePoints += ETHReceived;
        emit Attack(
        msg.sender, 
        team,
        amount, 
        ETHReceived,
        tokensReceived,
        initialBalance - teamToken.balanceOf(address(this)));
    }

    function getRandomNumber() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Insuff. LINK");
        return requestRandomness(keyHash, fee);
    }

    function requestReward(uint256 amount) private {
        address teamAddress = players[msg.sender].team;
        if (amount < thresholds[teamAddress].grade1) {
            return;
        }
        if (amount < thresholds[teamAddress].grade2) {
            players[msg.sender].unclaimedPacks.push(1);
        } else if (amount < thresholds[teamAddress].grade3) {
            players[msg.sender].unclaimedPacks.push(2);
        } else if (amount < thresholds[teamAddress].grade4) {
            players[msg.sender].unclaimedPacks.push(3);
        } else if (amount >= thresholds[teamAddress].grade4) {
            players[msg.sender].unclaimedPacks.push(4);
        }
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if (requests[requestId].fulfilled) {
            return;
        }
        requests[requestId].fulfilled = true;
        requests[requestId].seed = randomness;
        players[requests[requestId].requester].boosterPacks.push(requestId);
        players[requests[requestId].requester].numBoosterPacks += requests[requestId].grades.length;
        emit ReceivedBoosterPack(requests[requestId].requester, randomness);
    }
    function claimBoosterPacks() external payable {
        require(open, "Closed");
        require(players[msg.sender].unclaimedPacks.length > 0, "No booster packs");
        require(msg.value == redeemFee, "Fee required");
        devPool += redeemFee;
        bytes32 requestId = getRandomNumber();
        requests[requestId].requester = msg.sender;
        requests[requestId].fulfilled = false;
        requests[requestId].grades = players[msg.sender].unclaimedPacks;
        // Reset player unclaimed packs
        players[msg.sender].unclaimedPacks = new uint8[](0);
    }
    function unpackBoosterPack() external {
        require(open, "Closed");
        uint numPacks = players[msg.sender].boosterPacks.length;
        require(numPacks > 0, "No booster packs");
        bytes32 requestId = players[msg.sender].boosterPacks[numPacks-1];
        uint256 seed = requests[requestId].seed;

        uint256 numGrades = requests[requestId].grades.length;
        for (uint256 i = 0; i < numGrades; i++) {
            uint8 grade = requests[requestId].grades[i];
            (uint8 numCommon, bool getRare) = getNumRewards(seed, uint8(i), grade, rareChance.grade2-1, rareChance.grade3-1, rareChance.grade4-1);
            assignNFTs(numCommon, getRare, seed, uint8(i));
            emit BoosterPackOpened(msg.sender, uint8(i));
        }
        players[msg.sender].boosterPacks.pop();
        players[msg.sender].numBoosterPacks -= numGrades;
        delete requests[requestId];
    }

    function getNumRewards(uint256 seed, uint8 nonce, uint8 grade, uint8 grade2RareChance, uint8 grade3RareChance, uint8 grade4RareChance) public pure returns(uint8, bool) { // Common, Rare
        require(grade > 0, "G. too low");
        require(grade <= 4, "G. too high");
        if (grade == 1) { // Grade 1: 1 in 3 chance of Common NFT, No Rare
            // Common, 1 in 3 chance
            if (getRandomInt(2, seed, nonce) == 0) {
                return (1, false);
            }
        } else if (grade == 2) { // Grade 2: 0 to 1 Common NFTs, 1 in grade2RareChance Chance of Rare
            // Rare
            if (getRandomInt(grade2RareChance, seed, nonce) == 0) {
                return (0, true);
            }
            nonce +=1;
            // Common
            return (getRandomInt(1, seed, nonce), false);
        } else if (grade == 3) { // Grade 2: 0 to 2 Common NFTs, 1 in grade3RareChance Chance of Rare
            // Rare
            if (getRandomInt(grade3RareChance, seed, nonce) == 0) {
                return (0, true);
            }
            nonce +=1;
            // Common
            return (getRandomInt(2, seed, nonce), false);

        } else if (grade == 4) { // Grade 2: 1 to 3 Common NFTs, 1 in grade4RareChance Chance of Rare
            // Rare
            if (getRandomInt(grade4RareChance, seed, nonce) == 0) {
                return (0, true);
            }
            nonce +=1;
            // Common
            return (getRandomInt(2, seed, nonce) + 1, false);
        }
        return (0, false);
    }

    function assignNFTs(uint8 numCommon, bool getRare, uint256 seed, uint8 nonceIncrement) private {
        uint8 nonce = 64 + nonceIncrement;
        require(numCommon <= 3, "Too many commons");
        if (getRare) {
            nonce +=1;
            // Mint Rare NFT
            uint8 number = getRandomInt(2, seed, nonce) + 5; // 0-2 + 5 = 5-7
            rewardNFT.mint(msg.sender, season, number);
            createdCards[number] += 1;
            emit NFTAwarded(msg.sender, season, number, true);
            return;
        }
        for (uint8 i = 0 ; i < numCommon; i++) {
            nonce += 1;
            // Mint Common NFT
            uint8 number = getRandomInt(3, seed, nonce) + 1; // 0-3 + 1 = 1-4
            rewardNFT.mint(msg.sender, season, number);
            createdCards[number] += 1;
            emit NFTAwarded(msg.sender, season, number, false);
        }
    }

    function getRandomInt(uint8 max, uint256 seed, uint8 nonce) pure private returns(uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(seed, nonce))) % (max+1));
    }

    function forgeLegendary(uint256[] calldata ids) external {
        (uint16 cardSet, uint8 _number) = rewardNFT.metadataOf(ids[0]);
        require(_number == 1, "First card != 1");
        uint8 totalCards = rewardNFT.totalCardsOf(cardSet);
        require(totalCards == ids.length, "Wrong n of cards");

        for (uint8 i = 0 ; i < totalCards; i++) {
            require(rewardNFT.ownerOf(ids[i]) == msg.sender, "Not NFT owner");
            (uint16 set, uint8 number) = rewardNFT.metadataOf(ids[i]);
            require(set == cardSet, "Wrong set");
            require(number == (i+1), "Wrong number/order"); // Cards are from 1 to totalCards, i is from 0 to totalCards - 1
            rewardNFT.forgeBurn(ids[i]); // Burn NFT
        }
        rewardNFT.mint(msg.sender, cardSet, 0); // Card 0 of set is Legendary
        createdCards[0] += 1;
        emit LegendaryForged(msg.sender, cardSet);
    }

    function openPool() private {
        require(rewardPools[season].open == false, "Pool is open");
        require(address(this).balance >= rewardPools[season].balance, "Insuff. funds to open");
        require(rewardPools[season].balance > 0, "No balance");
        rewardPools[season].open = true;
        // The rare that has been issued in the smallest number
        uint256 rarestRare = createdCards[5];
        if (createdCards[6] < rarestRare) {
            rarestRare = createdCards[6];
        }
        if (createdCards[7] < rarestRare) {
            rarestRare = createdCards[7];
        }
        if (rarestRare == 0) { // No rares have been issued
            rarestRare = 1;
        }
        // the number of rarest rare issued is the max number of legendaries possible
        rewardPools[season].remainingClaims = rarestRare;
        // Get BNB per claim
        rewardPools[season].rewardPerNFT = rewardPools[season].balance / rewardPools[season].remainingClaims;
        emit PoolOpened(season, rewardPools[season].remainingClaims, rewardPools[season].balance, rewardPools[season].rewardPerNFT);
    }

    function claimLegendaryReward(uint256 nftId, uint16 rewardSeason) external {
        require(rewardPools[rewardSeason].open == true, "Claims not open");
        require(rewardNFT.ownerOf(nftId) == msg.sender, "Not NFT owner");
        (uint16 cardSet, uint8 num) = rewardNFT.metadataOf(nftId);
        require(num == 0, "Not Legendary");
        require(cardSet <= rewardSeason, "NFT Season not <= reward season");
        require(rewardPools[rewardSeason].nftsClaimed[nftId] == false, "NFT claimed for season");
        rewardPools[rewardSeason].nftsClaimed[nftId] = true; // Reward claimed for this NFT

        require(rewardPools[rewardSeason].remainingClaims >= 1, "No claims left");
        require(rewardPools[rewardSeason].rewardPerNFT <= rewardPools[rewardSeason].balance, "Insolvent");
        rewardPools[rewardSeason].remainingClaims -= 1;
        rewardPools[rewardSeason].balance -= rewardPools[rewardSeason].rewardPerNFT;
        payable(msg.sender).transfer(rewardPools[rewardSeason].rewardPerNFT);
        emit LegendaryRewardClaimed(rewardSeason, season, nftId, cardSet);
    }

    function transferPoolFunds(uint16 from) external onlyOwner {
        require(rewardPools[from].open == true, "From is closed");
        require(open == true, "Season closed");
        require(season > from, "Pool is current");
        require(rewardPools[from].balance > 0, "Pool is zero");
        rewardPools[from].open = false;
        emit PoolClosedAndFundsTransferred(from, season, rewardPools[from].balance);
        rewardPools[season].balance += rewardPools[from].balance;
        rewardPools[from].balance = 0;
    }
    
    function setThresholds(address teamAddress, uint256 grade1, uint256 grade2, uint256 grade3, uint256 grade4) public onlyOwner {
        thresholds[teamAddress] = Thresholds({
            grade1: grade1, 
            grade2: grade2,
            grade3: grade3,
            grade4: grade4
        });
        emit ThresholdsSet(msg.sender, grade1, grade2, grade3, grade4);
    }

    function setRareChance(uint8 grade2, uint8 grade3, uint8 grade4) external onlyOwner {
        rareChance = RareChance({
            grade2: grade2,
            grade3: grade3,
            grade4: grade4
        });
        emit RareChanceSet(msg.sender, grade2, grade3, grade4);
    }

    /// @dev Swap tokens for eth
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the testSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = players[msg.sender].team;
        path[1] = pancakeSwapRouter.WETH();
        IBEP20 teamToken = IBEP20(players[msg.sender].team);
        teamToken.approve(address(pancakeSwapRouter), tokenAmount*2);
        
        // make the swap
        pancakeSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
           tokenAmount,
            0, // get anything we can
            path,
            address(this),
            block.timestamp
        );
    }
    
    // @dev Swap tokens for eth
    function swapEthForTokens(uint256 EthAmount ) private {
        // generate the testSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeSwapRouter.WETH();
        path[1] = players[msg.sender].team;

        // make the swap
        pancakeSwapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: EthAmount}(
           0 ,// get anything we can
            path,
             address(this),
            block.timestamp
        );
    }
    // @dev Swap tokens for eth
    function swapEthForExactTokens(uint256 EthAmount, uint256 minTokens) private {
        // generate the testSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeSwapRouter.WETH();
        path[1] = players[msg.sender].team;

        // Make the swap
        pancakeSwapRouter.swapETHForExactTokens{value: EthAmount}(
            minTokens,// get anything we can
            path,
            address(this),
            block.timestamp
        );
    }
    // function mintNFT(address to, uint16 set, uint8 number) external onlyOwner {
    //     rewardNFT.mint(to, set, number);
    //     createdCards[number] += 1;
    // }
}