// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/* ========== Internal Inheritance ========== */
import "./DToken.sol";
import "./BMath.sol";

/* ========== Internal Interfaces ========== */
import "./interfaces/IDynaset.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/OneInchAgregator.sol";


/************************************************************************************************
Originally from https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license 
*************************************************************************************************/


contract Dynaset is DToken, BMath, IDynaset {

/* ==========  EVENTS  ========== */

  /** @dev Emitted when tokens are swapped. */
  event LOG_SWAP(
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 Amount
  );

  /** @dev Emitted when underlying tokens are deposited for dynaset tokens. */
  event LOG_JOIN(
    address indexed caller,
    address indexed tokenIn,
    uint256 tokenAmountIn
  );

  /** @dev Emitted when dynaset tokens are burned for underlying. */
  event LOG_EXIT(
    address indexed caller,
    address indexed tokenOut,
    uint256 tokenAmountOut
  );

  event LOG_CALL(
        bytes4  indexed sig,
        address indexed caller,
        bytes           data
  ) anonymous;

  /** @dev Emitted when a token's weight updates. */
  event LOG_DENORM_UPDATED(address indexed token, uint256 newDenorm);

/* ==========  Modifiers  ========== */
  
  modifier _logs_() {
      emit LOG_CALL(msg.sig, msg.sender, msg.data);
      _;
  }

  modifier _lock_ {
    require(!_mutex, "ERR_REENTRY");
    _mutex = true;
    _;
    _mutex = false;
  }

  modifier _viewlock_() {
    require(!_mutex, "ERR_REENTRY");
    _;
  }

  modifier _control_ {
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    _;
  }

  modifier _digital_asset_managers_ {
    require(msg.sender == _digital_asset_manager, "ERR_NOT_DAM");
    _;
  }

  modifier _mint_forge_ {
    require(_mint_forges[msg.sender], "ERR_NOT_FORGE");
    _;
  }

  modifier _burn_forge_ {
     require(_burn_forges[msg.sender], "ERR_NOT_FORGE");
    _;
  }

  /* uniswap addresses*/

  //address of the uniswap v2 router
  address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  //address of the oneInch v3 aggregation router
  address private constant ONEINCH_V4_AGREGATION_ROUTER = 0x1111111254fb6c44bAC0beD2854e76F90643097d;
    //address of WETH token.  This is needed because some times it is better to trade through WETH.
    //you might get a better price using WETH.
    //example trading from token A to WETH then WETH to token B might result in a better price
  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

/* ==========  Storage  ========== */
  
  bool internal _mutex;
  // Account with CONTROL role. Able to modify the swap fee,
  // adjust token weights, bind and unbind tokens and lock
  // public swaps & joins.
  address internal _controller;

  address internal _digital_asset_manager;

  mapping(address =>bool) internal _mint_forges;
  mapping(address =>bool) internal _burn_forges;


  // Array of underlying tokens in the dynaset.
  address[] internal _tokens;

  // Internal records of the dynaset's underlying tokens
  mapping(address => Record) internal _records;

  // Total denormalized weight of the dynaset.
  uint256 internal _totalWeight;


  constructor() public {
      _controller = msg.sender;
  }

/* ==========  Controls  ========== */

  /**
   * @dev Sets the controller address and the token name & symbol.
   *
   * Note: This saves on storage costs for multi-step dynaset deployment.
   *
   * @param controller Controller of the dynaset
   * @param name Name of the dynaset token
   * @param symbol Symbol of the dynaset token
   */
  function configure(
    address controller,//admin
    address dam,//digital asset manager
    string calldata name,
    string calldata symbol
  ) external override  _control_{
    _controller = controller;
    _digital_asset_manager = dam;
    _initializeToken(name, symbol);
  }

    /**
   * @dev Sets up the initial assets for the pool.
   *
   * Note: `tokenProvider` must have approved the pool to transfer the
   * corresponding `balances` of `tokens`.
   *
   * @param tokens Underlying tokens to initialize the pool with
   * @param balances Initial balances to transfer
   * @param denorms Initial denormalized weights for the tokens
   * @param tokenProvider Address to transfer the balances from
   */
  function initialize(
    address[] calldata tokens,
    uint256[] calldata balances,
    uint96[] calldata denorms,
    address tokenProvider
  )
    external
    override
    _control_
  {
    require(_tokens.length == 0, "ERR_INITIALIZED");
    uint256 len = tokens.length;
    require(len > 1, "ERR_MIN_TOKENS");
    require(len <= MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");
    require(balances.length == len && denorms.length == len, "ERR_ARR_LEN");
    uint256 totalWeight = 0;
    for (uint256 i = 0; i < len; i++) {
      address token = tokens[i];
      uint96 denorm = denorms[i];
      uint256 balance = balances[i];
      require(denorm >= MIN_WEIGHT, "ERR_MIN_WEIGHT");
      require(denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
      require(balance >= MIN_BALANCE, "ERR_MIN_BALANCE");

      _records[token] = Record({
        bound: true,
        ready: true,
        index: uint8(i),
        denorm: denorm,
        balance: balance
      });

      _tokens.push(token);
      
      totalWeight = badd(totalWeight, denorm);
      _pullUnderlying(token, tokenProvider, balance);
    }
    require(totalWeight <= MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
    _totalWeight = totalWeight;
    _mintdynasetShare(INIT_POOL_SUPPLY);
    _pushdynasetShare(tokenProvider, INIT_POOL_SUPPLY);
  }

    /**
   * @dev Get all bound tokens.
   */
  function getCurrentTokens()
    public
    view
    override
    returns (address[] memory tokens)
  {
    tokens = _tokens;
  }

  /**
   * @dev Returns the list of tokens which have a desired weight above 0.
   * Tokens with a desired weight of 0 are set to be phased out of the dynaset.
   */
  function getCurrentDesiredTokens()
    external
    view
    override
    returns (address[] memory tokens)
  {
    address[] memory tempTokens = _tokens;
    tokens = new address[](tempTokens.length);
    uint256 usedIndex = 0;
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tempTokens[i];
      if (_records[token].denorm > 0) {
        tokens[usedIndex++] = token;
      }
    }
    assembly { mstore(tokens, usedIndex) }
  }

   /**
   * @dev Returns the denormalized weight of a bound token.
   */
  function getDenormalizedWeight(address token)
    external
    view
    override
    returns (uint256/* denorm */)
  {
    require(_records[token].bound, "ERR_NOT_BOUND");
    return _records[token].denorm;
  }

  function getNormalizedWeight(address token)
        external 
        view
        _viewlock_
        returns (uint)
  {
    require(_records[token].bound, "ERR_NOT_BOUND");
    uint denorm = _records[token].denorm;
    return bdiv(denorm, _totalWeight);
  }

    /**
   * @dev Get the total denormalized weight of the dynaset.
   */
  function getTotalDenormalizedWeight()
    external
    view
    override
    returns (uint256)
  {
    return _totalWeight;
  }

  /**
   * @dev Returns the stored balance of a bound token.
   */
    function getBalance(address token) external view override returns (uint256) {
      Record storage record = _records[token];
      require(record.bound, "ERR_NOT_BOUND");
      return record.balance;
    }

      /**
     * @dev Sets the desired weights for the pool tokens, which
     * will be adjusted over time as they are swapped.
     *
     * Note: This does not check for duplicate tokens or that the total
     * of the desired weights is equal to the target total weight (25).
     * Those assumptions should be met in the controller. Further, the
     * provided tokens should only include the tokens which are not set
     * for removal.
     */
    function reweighTokens(
      address[] calldata tokens,
      uint96[] calldata Denorms
    )
      external
      override
      _lock_
      _control_
    {
      for (uint256 i = 0; i < tokens.length; i++){
        require(_records[tokens[i]].bound, "ERR_NOT_BOUND");
        _setDesiredDenorm(tokens[i], Denorms[i]);
      }
    }

    // Absorb any tokens that have been sent to this contract into the dynaset
  function updateAfterSwap(address _tokenIn,address _tokenOut) external _digital_asset_managers_{ //external for test

     uint256 balance_in = IERC20(_tokenIn).balanceOf(address(this)); 
     uint256 balance_out = IERC20(_tokenOut).balanceOf(address(this));
     
     _records[_tokenIn].balance = balance_in;
     _records[_tokenOut].balance = balance_out;
  
  }


/* ==========  Liquidity Provider Actions  ========== */

  /*
   * @dev Mint new dynaset tokens by providing the proportional amount of each
   * underlying token's balance relative to the proportion of dynaset tokens minted.
   *
   *
   * @param dynasetAmountOut Amount of dynaset tokens to mint
   * @param maxAmountsIn Maximum amount of each token to pay in the same
   * order as the dynaset's _tokens list.
   */

  function joinDynaset(uint256 _amount) external override _mint_forge_{

    uint256[] memory maxAmountsIn = new uint256[](getCurrentTokens().length);
    for (uint256 i = 0; i < maxAmountsIn.length; i++) {
      maxAmountsIn[i] = uint256(-1);
    }
    _joinDynaset(_amount, maxAmountsIn);
  }

  function _joinDynaset(uint256 dynasetAmountOut, uint256[] memory maxAmountsIn)
   internal 
   //external
   //override
  {
    uint256 dynasetTotal = totalSupply();
    uint256 ratio = bdiv(dynasetAmountOut, dynasetTotal); 
    require(ratio != 0, "ERR_MATH_APPROX");
    require(maxAmountsIn.length == _tokens.length, "ERR_ARR_LEN");

    for (uint256 i = 0; i < maxAmountsIn.length; i++) {
      address t = _tokens[i];
      (, uint256 realBalance) = _getInputToken(t);
      //uint256 bal = getBalance(t);
      uint256 tokenAmountIn = bmul(ratio, realBalance);
      require(tokenAmountIn != 0, "ERR_MATH_APPROX");
      require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
     
      _updateInputToken(t, badd(realBalance, tokenAmountIn));
      emit LOG_JOIN(msg.sender, t, tokenAmountIn);
      _pullUnderlying(t, msg.sender, tokenAmountIn);
    }

    _mintdynasetShare(dynasetAmountOut);
    _pushdynasetShare(msg.sender, dynasetAmountOut);
  }


  /*
   * @dev Burns `dynasetAmountIn` dynaset tokens in exchange for the amounts of each
   * underlying token's balance proportional to the ratio of tokens burned to
   * total dynaset supply. The amount of each token transferred to the caller must
   * be greater than or equal to the associated minimum output amount from the
   * `minAmountsOut` array.
   *
   * @param dynasetAmountIn Exact amount of dynaset tokens to burn
   * @param minAmountsOut Minimum amount of each token to receive, in the same
   * order as the dynaset's _tokens list.
   */
  
  function exitDynaset(uint256 _amount) external override _burn_forge_ {
    uint256[] memory minAmountsOut = new uint256[](getCurrentTokens().length);
    for (uint256 i = 0; i < minAmountsOut.length; i++) {
      minAmountsOut[i] = 0;
    }
    _exitDynaset(_amount, minAmountsOut);
  }

  function _exitDynaset(uint256 dynasetAmountIn, uint256[] memory minAmountsOut)
   internal
  {
    require(minAmountsOut.length == _tokens.length, "ERR_ARR_LEN");
    uint256 dynasetTotal = totalSupply();
    uint256 ratio = bdiv(dynasetAmountIn, dynasetTotal);
    require(ratio != 0, "ERR_MATH_APPROX");

    _pulldynasetShare(msg.sender, dynasetAmountIn);
    _burndynasetShare(dynasetAmountIn);
    
    for (uint256 i = 0; i < minAmountsOut.length; i++) {
      address t = _tokens[i];
      Record memory record = _records[t];
       if (record.ready) {
        uint256 tokenAmountOut = bmul(ratio, record.balance);
        require(tokenAmountOut != 0, "ERR_MATH_APPROX");
        require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
   
        _records[t].balance = bsub(record.balance, tokenAmountOut);
        emit LOG_EXIT(msg.sender, t, tokenAmountOut);
        _pushUnderlying(t, msg.sender, tokenAmountOut);
       
        }else{
           require(minAmountsOut[i] == 0, "ERR_OUT_NOT_READY");
        }
      
      } 
    
  }



/* ==========  Other  ========== */

  /**
   * @dev Absorb any tokens that have been sent to the dynaset.
   * If the token is not bound, it will be sent to the unbound
   * token handler.
   */

/* ==========  Token Swaps  ========== */
  
  function ApproveOneInch(address token,uint256 amount) external _digital_asset_managers_ {
      
      require(_records[token].bound, "ERR_NOT_BOUND");
      IERC20(token).approve(ONEINCH_V4_AGREGATION_ROUTER, amount);
  }
  

  function swapUniswap(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _amountOutMin) 
  external
  _digital_asset_managers_
  {
        
    require(_records[_tokenIn].bound, "ERR_NOT_BOUND");
    require(_records[_tokenOut].bound, "ERR_NOT_BOUND");
        //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract
    IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
    address[] memory path;
    if (_tokenIn == WETH || _tokenOut == WETH) {
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
    } else {
        path = new address[](3);
        path[0] = _tokenIn;
        path[1] = WETH;
        path[2] = _tokenOut;
    }
        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
    IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
      _amountIn,
      _amountOutMin,
      path,
      address(this),
      block.timestamp
      );

      uint256 balance_in = IERC20(_tokenIn).balanceOf(address(this));
     
      uint256 balance_out = IERC20(_tokenOut).balanceOf(address(this));
   
     _records[_tokenIn].balance = balance_in;
     _records[_tokenOut].balance = balance_out;
  }

  //swap using oneinch api
  
  function swapOneInch(
    address _tokenIn,
    address _tokenOut,
    uint256 amount,
    uint256 minReturn,
    bytes32[] calldata _data) 
  external 
  _digital_asset_managers_ 
  {
      
  require(_records[_tokenIn].bound, "ERR_NOT_BOUND");
  require(_records[_tokenOut].bound, "ERR_NOT_BOUND");
     
  OneInchAgregator(ONEINCH_V4_AGREGATION_ROUTER).unoswap(_tokenIn,amount,minReturn,_data);
    
  uint256 balance_in = IERC20(_tokenIn).balanceOf(address(this));
  uint256 balance_out = IERC20(_tokenOut).balanceOf(address(this));
     
  _records[_tokenIn].balance = balance_in;
  _records[_tokenOut].balance = balance_out;

  emit LOG_SWAP(_tokenIn,_tokenOut,amount);

  }

  function swapOneInchUniV3(
    address _tokenIn,
    address _tokenOut,
    uint256 amount,
    uint256 minReturn,
    uint256[] calldata _pools) 
  external 
  _digital_asset_managers_ 
  {
      
  require(_records[_tokenIn].bound, "ERR_NOT_BOUND");
  require(_records[_tokenOut].bound, "ERR_NOT_BOUND");
   
  OneInchAgregator(ONEINCH_V4_AGREGATION_ROUTER).uniswapV3Swap(amount,minReturn,_pools);
    
  uint256 balance_in = IERC20(_tokenIn).balanceOf(address(this));
  uint256 balance_out = IERC20(_tokenOut).balanceOf(address(this));
     
  _records[_tokenIn].balance = balance_in;
  _records[_tokenOut].balance = balance_out;

  emit LOG_SWAP(_tokenIn,_tokenOut,amount);

  }

/* ==========  Config Queries  ========== */
  
  function setMintForge(address _mintForge) external  _control_ returns(address) {
    require (!_mint_forges[_mintForge],"forge already added");
    _mint_forges[_mintForge] = true;
  }

  function setBurnForge(address _burnForge) external _control_ returns(address) {
    require (!_burn_forges[_burnForge],"forge already added");
    _burn_forges[_burnForge] = true;
  }

   function removeMintForge(address _mintForge) external  _control_ returns(address) {
    require (_mint_forges[_mintForge],"not forge ");
    delete _mint_forges[_mintForge];
  }

  function removeBurnForge(address _burnForge) external _control_ returns(address) {
    require (_burn_forges[_burnForge],"not forge ");
    delete _burn_forges[_burnForge];
  }

  

  /**
   * @dev Returns the controller address.
   */
  function getController() external view override returns (address) {
    return _controller;
  }

/* ==========  Token Queries  ========== */

  /**
   * @dev Check if a token is bound to the dynaset.
   */
  function isBound(address t) external view override returns (bool) {
    return _records[t].bound;
  }

  /**
   * @dev Get the number of tokens bound to the dynaset.
   */
  function getNumTokens() external view override returns (uint256) {
    return _tokens.length;
  }

  /**
   * @dev Returns the record for a token bound to the dynaset.
   */
  function getTokenRecord(address token)
    external
    view
    override
    returns (Record memory record)
  {
    record = _records[token];
    require(record.bound, "ERR_NOT_BOUND");
  }


/* ==========  Price Queries  ========== */


  function _setDesiredDenorm(address token, uint96 Denorm) internal {
    Record storage record = _records[token];
    require(record.bound, "ERR_NOT_BOUND");
    // If the desired weight is 0, this will trigger a gradual unbinding of the token.
    // Therefore the weight only needs to be above the minimum weight if it isn't 0.
    require(
      Denorm >= MIN_WEIGHT || Denorm == 0,
      "ERR_MIN_WEIGHT"
    );
    require(Denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
    record.denorm = Denorm;
    emit LOG_DENORM_UPDATED(token,Denorm);

  }


/* ==========  dynaset Share Internal Functions  ========== */

  function _pulldynasetShare(address from, uint256 amount) internal {
    _pull(from, amount);
  }

  function _pushdynasetShare(address to, uint256 amount) internal {
    _push(to, amount);
  }

  function _mintdynasetShare(uint256 amount) internal {
    _mint(amount);
  }

  function _burndynasetShare(uint256 amount) internal {
    _burn(amount);
  }

/* ==========  Underlying Token Internal Functions  ========== */
  // 'Underlying' token-manipulation functions make external calls but are NOT locked
  // You must `_lock_` or otherwise ensure reentry-safety

  function _pullUnderlying(
    address erc20,
    address from,
    uint256 amount
  ) internal {

    IERC20(erc20).transferFrom(from,address(this),amount);
  }


  function _pushUnderlying(
    address erc20,
    address to,
    uint256 amount
  ) internal {

    IERC20(erc20).transfer(to ,amount);

  }


  function withdrawAnyTokens(address token,uint256 amount) 
  external 
  _control_ {
    IERC20 Token = IERC20(token);
   // uint256 currentTokenBalance = Token.balanceOf(address(this));
    Token.transfer(msg.sender, amount); 
  }


/* ==========  Token Management Internal Functions  ========== */

  /** 
   * @dev Handles weight changes and initialization of an
   * input token.
   *
   * If the token is not initialized and the new balance is
   * still below the minimum, this will not do anything.
   *
   * If the token is not initialized but the new balance will
   * bring the token above the minimum balance, this will
   * mark the token as initialized, remove the minimum
   * balance and set the weight to the minimum weight plus
   * 1%.
   *
   *
   * @param token Address of the input token
   * and weight if the token was uninitialized.
   */
  function _updateInputToken(
    address token,
    uint256 realBalance
  )
    internal
  {
      // If the token is still not ready, do not adjust the weight.
    _records[token].balance = realBalance;

  }


/* ==========  Token Query Internal Functions  ========== */

  /**
   * @dev Get the record for a token which is being swapped in.
   * The token must be bound to the dynaset. If the token is not
   * initialized (meaning it does not have the minimum balance)
   * this function will return the actual balance of the token
   * which the dynaset holds, but set the record's balance and weight
   * to the token's minimum balance and the dynaset's minimum weight.
   * This allows the token swap to be priced correctly even if the
   * dynaset does not own any of the tokens.
   */
   function _getInputToken(address token)
    internal
    view
    returns (Record memory record, uint256 realBalance)
  {
    record = _records[token];
    require(record.bound, "ERR_NOT_BOUND");

    realBalance = record.balance;

  }



  function calcTokensForAmount(uint256 _amount)
    external
    view
    returns (address[] memory tokens, uint256[] memory amounts)
  {

    uint256 dynasetTotal = totalSupply();
    uint256 ratio = bdiv(_amount, dynasetTotal);
    require(ratio != 0, "ERR_MATH_APPROX");
    // Underlying_token_amount = Ratio * token_balance_in_dynaset
    //   Ratio  = User_amount / Dynaset_token_supply 
    tokens = _tokens;
    amounts = new uint256[](_tokens.length);

    for (uint256 i = 0; i < _tokens.length; i++) {
      address t = tokens[i];
      (Record memory record, ) = _getInputToken(t);
      uint256 tokenAmountIn = bmul(ratio, record.balance);
      amounts[i] = tokenAmountIn;
    }
  }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


interface OneInchAgregator {
    function unoswap(address srcToken,uint256 amount,uint256 minReturn,bytes32[] calldata _pools) external payable returns(uint256 returnAmount);
    function uniswapV3Swap(uint256 amount,uint256 minReturn,uint256[] calldata pools) external payable returns(uint256 returnAmount); 
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IUniswapV2Router {

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function swapExactTokensForTokens(

    //amount of tokens we are sending in
        uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
        uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address[] calldata path,
    //this is the address we are going to send the output tokens to
        address to,
    //the last time that the trade is valid for
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


interface IDynaset {
  /**
   * @dev Token record data structure
   * @param bound is token bound to pool
   * @param ready has token been initialized
   * @param lastDenormUpdate timestamp of last denorm change
   * @param denorm denormalized weight
   * @param desiredDenorm desired denormalized weight (used for incremental changes)
   * @param index of address in tokens array
   * @param balance token balance
   */
  struct Record {
      bool bound;   // is token bound to dynaset
      bool ready;
      uint index;   // private
      uint96 denorm;  // denormalized weight
      uint256 balance;
  }

  event LOG_SWAP(
    address indexed caller,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 tokenAmountIn,
    uint256 tokenAmountOut
  );

  event LOG_JOIN(
    address indexed caller,
    address indexed tokenIn,
    uint256 tokenAmountIn
  );

  event LOG_EXIT(
    address indexed caller,
    address indexed tokenOut,
    uint256 tokenAmountOut
  );

  event LOG_DENORM_UPDATED(address indexed token, uint256 newDenorm);

  event LOG_DESIRED_DENORM_SET(address indexed token, uint256 desiredDenorm);

  event LOG_MINIMUM_BALANCE_UPDATED(address token, uint256 minimumBalance);

  event LOG_TOKEN_READY(address indexed token);

  event LOG_PUBLIC_SWAP_TOGGLED(bool enabled);

  function configure(
    address controller,
    address dam,
    string calldata name,
    string calldata symbol
  ) external;

  function initialize(
    address[] calldata tokens,
    uint256[] calldata balances,
    uint96[] calldata denorms,
    address tokenProvider
  ) external;
  

  function reweighTokens(
    address[] calldata tokens,
    uint96[] calldata Denorms
  ) external;

  function joinDynaset(uint256 _amount) external;

  function exitDynaset(uint256 _amount) external;

  //function updateAfterSwap(address token) external;

  function getController() external view returns (address);

  function isBound(address t) external view returns (bool);

  function getNumTokens() external view returns (uint256);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function getCurrentDesiredTokens() external view returns (address[] memory tokens);

  function getDenormalizedWeight(address token) external view returns (uint256/* denorm */);

  function getTokenRecord(address token) external view returns (Record memory record);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getBalance(address token) external view returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import "./BNum.sol";


/************************************************************************************************
Originally from https://github.com/balancer-labs/balancer-core/blob/master/contracts/BToken.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license
*************************************************************************************************/


// Highly opinionated token implementation
interface IERC20 {
  event Approval(address indexed src, address indexed dst, uint256 amt);
  event Transfer(address indexed src, address indexed dst, uint256 amt);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address whom) external view returns (uint256);

  function allowance(address src, address dst) external view returns (uint256);

  function approve(address dst, uint256 amt) external returns (bool);

  function transfer(address dst, uint256 amt) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 amt
  ) external returns (bool);
}


contract DTokenBase is BNum {
  mapping(address => uint256) internal _balance;
  mapping(address => mapping(address => uint256)) internal _allowance;
  uint256 internal _totalSupply;

  event Approval(address indexed src, address indexed dst, uint256 amt);
  event Transfer(address indexed src, address indexed dst, uint256 amt);

  function _mint(uint256 amt) internal {
    _balance[address(this)] = badd(_balance[address(this)], amt);
    _totalSupply = badd(_totalSupply, amt);
    emit Transfer(address(0), address(this), amt);
  }

  function _burn(uint256 amt) internal {
    require(_balance[address(this)] >= amt, "ERR_INSUFFICIENT_BAL");
    _balance[address(this)] = bsub(_balance[address(this)], amt);
    _totalSupply = bsub(_totalSupply, amt);
    emit Transfer(address(this), address(0), amt);
  }

  function _move(
    address src,
    address dst,
    uint256 amt
  ) internal {
    require(_balance[src] >= amt, "ERR_INSUFFICIENT_BAL");
    _balance[src] = bsub(_balance[src], amt);
    _balance[dst] = badd(_balance[dst], amt);
    emit Transfer(src, dst, amt);
  }

  function _push(address to, uint256 amt) internal {
    _move(address(this), to, amt);
  }

  function _pull(address from, uint256 amt) internal {
    _move(from, address(this), amt);
  }
}


contract DToken is DTokenBase, IERC20 {
  uint8 private constant DECIMALS = 18;
  string private _name;
  string private _symbol;

  function _initializeToken(string memory name, string memory symbol) internal {
    require(
      bytes(_name).length == 0 &&
      bytes(name).length != 0 &&
      bytes(symbol).length != 0,
      "ERR_BTOKEN_INITIALIZED"
    );
    _name = name;
    _symbol = symbol;
  }

  function name()
    external
    override
    view
    returns (string memory)
  {
    return _name;
  }

  function symbol()
    external
    override
    view
    returns (string memory)
  {
    return _symbol;
  }

  function decimals()
    external
    override
    view
    returns (uint8)
  {
    return DECIMALS;
  }

  function allowance(address src, address dst)
    external
    override
    view
    returns (uint256)
  {
    return _allowance[src][dst];
  }

  function balanceOf(address whom) external override view returns (uint256) {
    return _balance[whom];
  }

  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  function approve(address dst, uint256 amt) external override returns (bool) {
    _allowance[msg.sender][dst] = amt;
    emit Approval(msg.sender, dst, amt);
    return true;
  }

  function increaseApproval(address dst, uint256 amt) external returns (bool) {
    _allowance[msg.sender][dst] = badd(_allowance[msg.sender][dst], amt);
    emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
    return true;
  }

  function decreaseApproval(address dst, uint256 amt) external returns (bool) {
    uint256 oldValue = _allowance[msg.sender][dst];
    if (amt > oldValue) {
      _allowance[msg.sender][dst] = 0;
    } else {
      _allowance[msg.sender][dst] = bsub(oldValue, amt);
    }
    emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
    return true;
  }

  function transfer(address dst, uint256 amt) external override returns (bool) {
    _move(msg.sender, dst, amt);
    return true;
  }

  function transferFrom(
    address src,
    address dst,
    uint256 amt
  ) external override returns (bool) {
    require(
      msg.sender == src || amt <= _allowance[src][msg.sender],
      "ERR_BTOKEN_BAD_CALLER"
    );
    _move(src, dst, amt);
    if (msg.sender != src && _allowance[src][msg.sender] != uint256(-1)) {
      _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
      emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
    }
    return true;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import "./BConst.sol";


/************************************************************************************************
Originally from https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license
*************************************************************************************************/


contract BNum is BConst {
  function btoi(uint256 a) internal pure returns (uint256) {
    return a / BONE;
  }

  function bfloor(uint256 a) internal pure returns (uint256) {
    return btoi(a) * BONE;
  }

  function badd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "ERR_ADD_OVERFLOW");
    return c;
  }

  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, "ERR_SUB_UNDERFLOW");
    return c;
  }

  function bsubSign(uint256 a, uint256 b)
    internal
    pure
    returns (uint256, bool)
  {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "ERR_MUL_OVERFLOW");
    uint256 c2 = c1 / BONE;
    return c2;
  }

  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "ERR_DIV_ZERO");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
    uint256 c2 = c1 / b;
    return c2;
  }

  // DSMath.wpow
  function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
    uint256 z = n % 2 != 0 ? a : BONE;

    for (n /= 2; n != 0; n /= 2) {
      a = bmul(a, a);

      if (n % 2 != 0) {
        z = bmul(z, a);
      }
    }
    return z;
  }

  // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
  // Use `bpowi` for `b^e` and `bpowK` for k iterations
  // of approximation of b^0.w
  function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
    require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
    require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

    uint256 whole = bfloor(exp);
    uint256 remain = bsub(exp, whole);

    uint256 wholePow = bpowi(base, btoi(whole));

    if (remain == 0) {
      return wholePow;
    }

    uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
    return bmul(wholePow, partialResult);
  }

  function bpowApprox(
    uint256 base,
    uint256 exp,
    uint256 precision
  ) internal pure returns (uint256) {
    // term 0:
    uint256 a = exp;
    (uint256 x, bool xneg) = bsubSign(base, BONE);
    uint256 term = BONE;
    uint256 sum = term;
    bool negative = false;

    // term(k) = numer / denom
    //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
    // each iteration, multiply previous term by (a-(k-1)) * x / k
    // continue until term is less than precision
    for (uint256 i = 1; term >= precision; i++) {
      uint256 bigK = i * BONE;
      (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
      term = bmul(term, bmul(c, x));
      term = bdiv(term, bigK);
      if (term == 0) break;

      if (xneg) negative = !negative;
      if (cneg) negative = !negative;
      if (negative) {
        sum = bsub(sum, term);
      } else {
        sum = badd(sum, term);
      }
    }

    return sum;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import "./BNum.sol";


/************************************************************************************************
Originally from https://github.com/balancer-labs/balancer-core/blob/master/contracts/BMath.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license
*************************************************************************************************/


contract BMath is BConst, BNum {
  /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                ( bI / wI )         1                                  //
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
  function calcSpotPrice(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 swapFee
  ) internal pure returns (uint256 spotPrice) {
    uint256 numer = bdiv(tokenBalanceIn, tokenWeightIn);
    uint256 denom = bdiv(tokenBalanceOut, tokenWeightOut);
    uint256 ratio = bdiv(numer, denom);
    uint256 scale = bdiv(BONE, bsub(BONE, swapFee));
    return (spotPrice = bmul(ratio, scale));
  }

  /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
  function calcOutGivenIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountOut) {
    uint256 weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
    uint256 adjustedIn = bsub(BONE, swapFee);
    adjustedIn = bmul(tokenAmountIn, adjustedIn);
    uint256 y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
    uint256 foo = bpow(y, weightRatio);
    uint256 bar = bsub(BONE, foo);
    tokenAmountOut = bmul(tokenBalanceOut, bar);
    return tokenAmountOut;
  }

  /**********************************************************************************************
    // calcInGivenOut                                                                            //
    // aI = tokenAmountIn                                                                        //
    // bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \                 //
    // bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |                //
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /                 //
    // wI = tokenWeightIn           --------------------------------------------                 //
    // wO = tokenWeightOut                          ( 1 - sF )                                   //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
  function calcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountIn) {
    uint256 weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
    uint256 diff = bsub(tokenBalanceOut, tokenAmountOut);
    uint256 y = bdiv(tokenBalanceOut, diff);
    uint256 foo = bpow(y, weightRatio);
    foo = bsub(foo, BONE);
    tokenAmountIn = bsub(BONE, swapFee);
    tokenAmountIn = bdiv(bmul(tokenBalanceIn, foo), tokenAmountIn);
    return tokenAmountIn;
  }

  /**********************************************************************************************
    // calcPoolOutGivenSingleIn                                                                  //
    // pAo = poolAmountOut         /                                              \              //
    // tAi = tokenAmountIn        ///      /     //    wI \      \\       \     wI \             //
    // wI = tokenWeightIn        //| tAi *| 1 - || 1 - --  | * sF || + tBi \    --  \            //
    // tW = totalWeight     pAo=||  \      \     \\    tW /      //         | ^ tW   | * pS - pS //
    // tBi = tokenBalanceIn      \\  ------------------------------------- /        /            //
    // pS = poolSupply            \\                    tBi               /        /             //
    // sF = swapFee                \                                              /              //
    **********************************************************************************************/
  function calcPoolOutGivenSingleIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 poolAmountOut) {
    // Charge the trading fee for the proportion of tokenAi
    ///  which is implicitly traded to the other pool tokens.
    // That proportion is (1- weightTokenIn)
    // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);
    uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
    uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
    uint256 tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BONE, zaz));

    uint256 newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
    uint256 tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);

    // uint newPoolSupply = (ratioTi ^ weightTi) * poolSupply;
    uint256 poolRatio = bpow(tokenInRatio, normalizedWeight);
    uint256 newPoolSupply = bmul(poolRatio, poolSupply);
    poolAmountOut = bsub(newPoolSupply, poolSupply);
    return poolAmountOut;
  }

  /**********************************************************************************************
    // calcSingleInGivenPoolOut                                                                  //
    // tAi = tokenAmountIn              //(pS + pAo)\     /    1    \\                           //
    // pS = poolSupply                 || ---------  | ^ | --------- || * bI - bI                //
    // pAo = poolAmountOut              \\    pS    /     \(wI / tW)//                           //
    // bI = balanceIn          tAi =  --------------------------------------------               //
    // wI = weightIn                              /      wI  \                                   //
    // tW = totalWeight                          |  1 - ----  |  * sF                            //
    // sF = swapFee                               \      tW  /                                   //
    **********************************************************************************************/
  function calcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountIn) {
    uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
    uint256 newPoolSupply = badd(poolSupply, poolAmountOut);
    uint256 poolRatio = bdiv(newPoolSupply, poolSupply);

    //uint newBalTi = poolRatio^(1/weightTi) * balTi;
    uint256 boo = bdiv(BONE, normalizedWeight);
    uint256 tokenInRatio = bpow(poolRatio, boo);
    uint256 newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
    uint256 tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
    // Do reverse order of fees charged in joinswap_ExternAmountIn, this way
    //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
    //uint tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
    uint256 zar = bmul(bsub(BONE, normalizedWeight), swapFee);
    tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BONE, zar));
    return tokenAmountIn;
  }

  /**********************************************************************************************
    // calcSingleOutGivenPoolIn                                                                  //
    // tAo = tokenAmountOut            /      /                                             \\   //
    // bO = tokenBalanceOut           /      // pS - (pAi * (1 - eF)) \     /    1    \      \\  //
    // pAi = poolAmountIn            | bO - || ----------------------- | ^ | --------- | * b0 || //
    // ps = poolSupply                \      \\          pS           /     \(wO / tW)/      //  //
    // wI = tokenWeightIn      tAo =   \      \                                             //   //
    // tW = totalWeight                    /     /      wO \       \                             //
    // sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |                            //
    // eF = exitFee                        \     \      tW /       /                             //
    **********************************************************************************************/
  function calcSingleOutGivenPoolIn(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountOut) {
    uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
    // charge exit fee on the pool token side
    // pAiAfterExitFee = pAi*(1-exitFee)
    uint256 poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BONE, EXIT_FEE));
    uint256 newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
    uint256 poolRatio = bdiv(newPoolSupply, poolSupply);

    // newBalTo = poolRatio^(1/weightTo) * balTo;
    uint256 tokenOutRatio = bpow(poolRatio, bdiv(BONE, normalizedWeight));
    uint256 newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

    uint256 tokenAmountOutBeforeSwapFee = bsub(
      tokenBalanceOut,
      newTokenBalanceOut
    );

    // charge swap fee on the output token side
    //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
    uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
    tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BONE, zaz));
    return tokenAmountOut;
  }

  /**********************************************************************************************
    // calcPoolInGivenSingleOut                                                                  //
    // pAi = poolAmountIn               // /               tAo             \\     / wO \     \   //
    // bO = tokenBalanceOut            // | bO - -------------------------- |\   | ---- |     \  //
    // tAo = tokenAmountOut      pS - ||   \     1 - ((1 - (tO / tW)) * sF)/  | ^ \ tW /  * pS | //
    // ps = poolSupply                 \\ -----------------------------------/                /  //
    // wO = tokenWeightOut  pAi =       \\               bO                 /                /   //
    // tW = totalWeight           -------------------------------------------------------------  //
    // sF = swapFee                                        ( 1 - eF )                            //
    // eF = exitFee                                                                              //
    **********************************************************************************************/
  function calcPoolInGivenSingleOut(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 poolAmountIn) {
    // charge swap fee on the output token side
    uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
    //uint tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
    uint256 zoo = bsub(BONE, normalizedWeight);
    uint256 zar = bmul(zoo, swapFee);
    uint256 tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BONE, zar));

    uint256 newTokenBalanceOut = bsub(
      tokenBalanceOut,
      tokenAmountOutBeforeSwapFee
    );
    uint256 tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);

    //uint newPoolSupply = (ratioTo ^ weightTo) * poolSupply;
    uint256 poolRatio = bpow(tokenOutRatio, normalizedWeight);
    uint256 newPoolSupply = bmul(poolRatio, poolSupply);
    uint256 poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);

    // charge exit fee on the pool token side
    // pAi = pAiAfterExitFee/(1-exitFee)
    poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BONE, EXIT_FEE));
    return poolAmountIn;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


/************************************************************************************************
Originally from https://github.com/balancer-labs/balancer-core/blob/master/contracts/BConst.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license
*************************************************************************************************/


contract BConst {


  uint256 public constant VERSION_NUMBER = 1;

/* ---  Weight Updates  --- */

  // Minimum time passed between each weight update for a token.
  uint256 internal constant WEIGHT_UPDATE_DELAY = 1 hours;

  // Maximum percent by which a weight can adjust at a time
  // relative to the current weight.
  // The number of iterations needed to move from weight A to weight B is the floor of:
  // (A > B): (ln(A) - ln(B)) / ln(1.01)
  // (B > A): (ln(A) - ln(B)) / ln(0.99)
  uint256 internal constant WEIGHT_CHANGE_PCT = BONE/100;

  uint256 internal constant BONE = 10**18;

  uint256 internal constant MIN_BOUND_TOKENS = 2;
  uint256 internal constant MAX_BOUND_TOKENS = 10;
  // Minimum swap fee.
  uint256 internal constant MIN_FEE = BONE / 10**6;
  // Maximum swap or exit fee.
  uint256 internal constant MAX_FEE = BONE / 10;
  // Actual exit fee.
  uint256 internal constant EXIT_FEE = 5e15;
  
  // Minimum weight for any token (1/100).
  uint256 internal constant MIN_WEIGHT = BONE;
  uint256 internal constant MAX_WEIGHT = BONE * 50;
  // Maximum total weight.
  uint256 internal constant MAX_TOTAL_WEIGHT = BONE * 50;
  // Minimum balance for a token (only applied at initialization)
  uint256 internal constant MIN_BALANCE = BONE / 10**12;
  // Initial pool tokens
  uint256 internal constant INIT_POOL_SUPPLY = BONE * 100;

  uint256 internal constant MIN_BPOW_BASE = 1 wei;
  uint256 internal constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint256 internal constant BPOW_PRECISION = BONE / 10**10;

  // Maximum ratio of input tokens to balance for swaps.
  uint256 internal constant MAX_IN_RATIO = BONE / 2;
  // Maximum ratio of output tokens to balance for swaps.
  uint256 internal constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}