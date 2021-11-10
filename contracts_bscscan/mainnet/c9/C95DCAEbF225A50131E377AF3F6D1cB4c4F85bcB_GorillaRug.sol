/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

// SPDX-License-Identifier: MIT
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


contract GorillaRug is Context, IERC20, VRFConsumerBase {

    // Variables for contract lifecycle and transaction fees
    mapping (uint256 => uint) private _epochTimestamp;
    mapping (uint16 => uint16) private _epochTax;
    mapping (uint16 => uint16) private _epochBurn;
    uint16 private _epoch;
    uint16 private _flatBuyFee = 5;
    bool private _liquifying;
    
    uint256 private _start = 1636646400; // Contract starts

    // Variables for selecting winners
    address[] private winnersPool;
    address[] private winners;
    bool private winnersSelected = false;
    
    // Variables required for Chainlink to work
    bytes32 private _keyHash;
    uint256 private _fee;
    
    // Variables for tokens to work
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => uint256) private _lastBuyTransactionBlock;
    mapping (address => uint256) private _lastSellTransactionBlock;

    uint256 private constant _totalSupply = 10 * 10**6 * 10**18; // Ten million total supply

    // Token info
    string private _name = "GorillaRug";
    string private _symbol = "GRX";
    uint8 private _decimals = 18;

    // Wallet addresses
    address payable private _devWallet = payable(0xfAa1ec28383cDBcA23B127e71e244553ce752f4E);
    address private _lpWallet = 0x9Eb0273aECa8bD62fBB75853EBD6Ed2dBB29B5Aa;
    address payable private _buyBackWallet = payable(0x79AE32EbB1d5654be9c18F5a3C672641930dBC96);
    address private _pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // Address for Pancake Router v2
    address private _pairAd = address(0); // Pair address

    IPancakeRouter02 private PancakeRouter;

    constructor(address vrfCoordinator, address link, bytes32 keyHash, uint256 fee) VRFConsumerBase(vrfCoordinator, link) {
        _epoch = 0;
        // Contract lifecicle timestamps
        _epochTimestamp[0] = _start;
        _epochTimestamp[1] = _start + 2 hours;
        _epochTimestamp[2] = _start + 4 hours;
        _epochTimestamp[3] = _start + 6 hours;
        _epochTimestamp[4] = _start + 8 hours;
        _epochTimestamp[5] = _start + 10 hours;
        // Taxation values
        _epochTax[0] = 5;
        _epochTax[1] = 4;
        _epochTax[2] = 3;
        _epochTax[3] = 2;
        _epochTax[4] = 0;
        // Buyback values
        _epochBurn[0] = 20;
        _epochBurn[1] = 16;
        _epochBurn[2] = 12;
        _epochBurn[3] = 8;
        _epochBurn[4] = 20;
        // Requred data to create a pool
        _balances[_lpWallet] = _totalSupply;
        PancakeRouter = IPancakeRouter02(_pancakeRouter);
        // Required data to use Chainlink
        _keyHash = keyHash;
        _fee = fee;
    }

    modifier noRecursion {
        _liquifying = true;
        _;
        _liquifying = false;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require (_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    // Prevent transaction from being sandwiched
    // Does not allow both buy and sell from one address during the same block
    function isSandwich(address sender, address recipient, address pair) private returns (bool) {
        // Buy logic
        if (sender == pair) {
            if (block.number == _lastSellTransactionBlock[recipient])
                return true;
            _lastBuyTransactionBlock[recipient] = block.number;
        // Sell logic
        } else if (recipient == pair) {
            if (block.number == _lastBuyTransactionBlock[sender])
                return true;
            _lastSellTransactionBlock[sender] = block.number;
        }
        return false;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        // Check to be sure epoch is set correctly
        _checkEpoch();

        // One-time set pair address during addLiquidity, since that should be the first use of this function
        if (_pairAd == address(0) && sender != address(0)) {
            _pairAd = recipient;
        }
        
        // Ensure we're within the contract lifecycle limits and the transaction is not a sandwich pair,
        // unless it's the LP or the Uni router (for add/removeLiquidity)
        if (sender != _lpWallet && recipient != _lpWallet && recipient != _pancakeRouter && sender != address(this))
        {
            require(!isSandwich(sender, recipient, _pairAd));
            require (block.timestamp >= _epochTimestamp[0] && block.timestamp <= _epochTimestamp[5], "No trades at this time");
            // Token limit of 500000 for the first 15 minutes
            require (amount <= (_totalSupply * 50 / 1000) || block.timestamp >= _epochTimestamp[0] + 15 minutes);
        }
        

        // The usual ERC20 checks
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer exceeds balance");
        require(amount > 0, "Transfer = 0");
        
        // Set defaults for fallback
        uint256 amountRemaining = amount;
        uint256 taxes = 0;
        uint256 buyBack = 0;

        // Logic for buys
        if (sender == _pairAd && recipient != _lpWallet && recipient != _pancakeRouter && recipient != _buyBackWallet)
        {
            taxes = amount * _flatBuyFee / 100;
            amountRemaining = amount - taxes;
            
            // If it is the last epoch and the amount bought is more than 10000, the buyer is added to pottential winners' list
            if (block.timestamp > _epochTimestamp[4] && block.timestamp <= _epochTimestamp[5] && amount >= 10**4 * 10**18) {
                winnersPool.push(recipient);
            }
        }
        
        // Logic for sells
        if (recipient == _pairAd && sender != _lpWallet && sender != address(this))
        {
            taxes = amount * _epochTax[_epoch] / 100;
            amountRemaining = amount - taxes;

            buyBack = amount * _epochBurn[_epoch] / 100;
            amountRemaining = amountRemaining - buyBack;
        }
        
        _balances[address(this)] += buyBack;        
        if (_balances[address(this)] > 100 * 10**18 && !_liquifying && recipient == _pairAd){
            if (_balances[address(this)] >= buyBack && buyBack > 100 * 10**18) {
                liquidateTokens(buyBack, _buyBackWallet);
            }
        }
        
        _balances[address(this)] += taxes;
        if (_balances[address(this)] > 100 * 10**18 && !_liquifying && recipient == _pairAd){
            uint256 _liqAmount = _balances[address(this)];
            if (_liqAmount > amount * 10 / 100) _liqAmount = amount * 10 / 100;
            liquidateTokens(_liqAmount, _devWallet);
        }

        _balances[recipient] += amountRemaining;
        _balances[sender] -= amount;

        emit Transfer(sender, recipient, amount);
    }
    
    function _checkEpoch() private {
        if (_epoch == 0 && block.timestamp >= _epochTimestamp[1]) _epoch = 1;
        if (_epoch == 1 && block.timestamp >= _epochTimestamp[2]) _epoch = 2;
        if (_epoch == 2 && block.timestamp >= _epochTimestamp[3]) _epoch = 3;
        if (_epoch == 3 && block.timestamp >= _epochTimestamp[4]) _epoch = 4;
        if (_epoch == 4 && block.timestamp >= _epochTimestamp[5]) _epoch = 5;
    }

    function currentEpoch() public view returns (uint16){
        return _epoch;
    }

    function pairAddr() public view returns (address){
        return _pairAd;
    }

    function sendETH(uint256 amount, address payable _to) private {
        (bool sent,) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    // Liqudate for a single address
    function liquidateTokens(uint256 amount, address payable recipient) private noRecursion {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = PancakeRouter.WETH();

        _approve(address(this), _pancakeRouter, amount);
        PancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp);

        if (address(this).balance > 0) sendETH(address(this).balance, recipient);
    }

    function emergencyWithdrawETH() external {
        require (_msgSender() == _buyBackWallet || _msgSender() == _devWallet, "Unauthorized");
        (bool sent,) = _msgSender().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
    
    // Withdraw the remaining taxes left in the contract
    function withdrawRemaining() external {
        require (block.timestamp > _epochTimestamp[5], "The game is still in progress"); // Prevent from being called until the game is finished
        require (_msgSender() == _devWallet, "Unauthorized");
        liquidateTokens(_balances[address(this)], _devWallet);
    }
    
    // Generate a list of winners. Can be called only once
    function getWinners() external {
        require (block.timestamp > _epochTimestamp[5], "The game is still in progress"); // Prevent from being called until the game is finished
        require (_msgSender() == _buyBackWallet || _msgSender() == _devWallet, "Unauthorized");
        require (!winnersSelected, "Already selected"); // Prevent a second call of the function
        if (winnersPool.length <= 10) {
            winners = winnersPool; // If less than 10 winners in winnersPool - all are winners
        } else {
            require(LINK.balanceOf(address(this)) >= _fee, "Not enough LINK - fill contract with faucet");
            requestRandomness(_keyHash, _fee); // Generate a random number
        }
        winnersSelected = true;
    }
    
    // Generate a list of winners. Can be called only if getWinners was not successful
    // The purpose of this function is to retry the randomness request, if the original
    // one failed due to wrong amount of LINK
    function emergencyGetWinners(uint256 overrideFee) external {
        require (block.timestamp > _epochTimestamp[5], "The game is still in progress"); // Prevent from being called until the game is finished
        require (_msgSender() == _buyBackWallet || _msgSender() == _devWallet, "Unauthorized");
        require (winners.length == 0, "Already selected"); // Don't allow to call if the original succeeded
        if (winnersPool.length <= 10) {
            winners = winnersPool; // If less than 10 winners in winnersPool - all are winners
        } else {
            require(LINK.balanceOf(address(this)) >= overrideFee, "Not enough LINK - fill contract with faucet");
            requestRandomness(_keyHash, overrideFee); // Generate a random number
        }
        winnersSelected = true;
    }
    
    function showWinners() view public returns(address[] memory) {
        return winners;
    }
    
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        uint256 randomNumber = randomness;
        for (uint8 i = 0; i < 10; i++) {
            if (i != 0) {
                // Generate a random number based on the previous winner's address
                // Divide by 2 to prevent possible overflow and add more randomness
                randomNumber = randomNumber / 2 + uint256(uint160(winners[i - 1])) / 2;
            }
            uint16 randomIndex = uint16(randomNumber % winnersPool.length);
            rememberWinner(randomIndex);
        }
    }
    
    function rememberWinner(uint256 index) private {
        // Add the winner
        address winner = winnersPool[index];
        winners.push(winner);
        // Remove from winnersPool to ensure that this enrty won't be selected twice
        winnersPool[index] = winnersPool[winnersPool.length - 1];
        winnersPool.pop();
    }

    receive() external payable {}

    fallback() external payable {}
}