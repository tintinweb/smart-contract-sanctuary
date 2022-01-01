/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


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


interface IUniswapV2Router {
  function getAmountsOut(uint amountIn, address[] memory path)
    external
    view
    returns (uint[] memory amounts);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  )
    external
    returns (
      uint amountA,
      uint amountB,
      uint liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external view returns (address);
}


interface IDMMExchangeRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata poolsPath,
        IERC20[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata poolsPath,
        IERC20[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IDMMLiquidityRouter {
    /**
     * @param tokenA address of token in the pool
     * @param tokenB address of token in the pool
     * @param pool the address of the pool
     * @param amountADesired the amount of tokenA users want to add to the pool
     * @param amountBDesired the amount of tokenB users want to add to the pool
     * @param amountAMin bounds to the extents to which amountB/amountA can go up
     * @param amountBMin bounds to the extents to which amountB/amountA can go down
     * @param vReserveRatioBounds bounds to the extents to which vReserveB/vReserveA can go (precision: 2 ** 112)
     * @param to Recipient of the liquidity tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function addLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256[2] calldata vReserveRatioBounds,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityNewPool(
        IERC20 tokenA,
        IERC20 tokenB,
        uint32 ampBps,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityNewPoolETH(
        IERC20 token,
        uint32 ampBps,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    /**
     * @param token address of token in the pool
     * @param pool the address of the pool
     * @param amountTokenDesired the amount of token users want to add to the pool
     * @dev   msg.value equals to amountEthDesired
     * @param amountTokenMin bounds to the extents to which WETH/token can go up
     * @param amountETHMin bounds to the extents to which WETH/token can go down
     * @param vReserveRatioBounds bounds to the extents to which vReserveB/vReserveA can go (precision: 2 ** 112)
     * @param to Recipient of the liquidity tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function addLiquidityETH(
        IERC20 token,
        address pool,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256[2] calldata vReserveRatioBounds,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    /**
     * @param tokenA address of token in the pool
     * @param tokenB address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountAMin the minimum token retuned after burning
     * @param amountBMin the minimum token retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function removeLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @param tokenA address of token in the pool
     * @param tokenB address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountAMin the minimum token retuned after burning
     * @param amountBMin the minimum token retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param approveMax whether users permit the router spending max lp token or not.
     * @param r s v Signature of user to permit the router spending lp token
     */
    function removeLiquidityWithPermit(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @param token address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountTokenMin the minimum token retuned after burning
     * @param amountETHMin the minimum eth in wei retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert
     */
    function removeLiquidityETH(
        IERC20 token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @param token address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountTokenMin the minimum token retuned after burning
     * @param amountETHMin the minimum eth in wei retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert
     * @param approveMax whether users permit the router spending max lp token
     * @param r s v signatures of user to permit the router spending lp token.
     */
    function removeLiquidityETHWithPermit(
        IERC20 token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @param amountA amount of 1 side token added to the pool
     * @param reserveA current reserve of the pool
     * @param reserveB current reserve of the pool
     * @return amountB amount of the other token added to the pool
     */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
}

interface IDMMRouter01 is IDMMExchangeRouter, IDMMLiquidityRouter {
    function factory() external pure returns (address);

    function weth() external pure returns (IWETH);
}


interface IDMMRouter02 is IDMMRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        IERC20 token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        IERC20 token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external;
}



interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}




interface IDMMFactory {
    function createPool(
        IERC20 tokenA,
        IERC20 tokenB,
        uint32 ampBps
    ) external returns (address pool);

    function setFeeConfiguration(address feeTo, uint16 governmentFeeBps) external;

    function setFeeToSetter(address) external;

    function getFeeConfiguration() external view returns (address feeTo, uint16 governmentFeeBps);

    function feeToSetter() external view returns (address);

    function allPools(uint256) external view returns (address pool);

    function allPoolsLength() external view returns (uint256);

    function getUnamplifiedPool(IERC20 token0, IERC20 token1) external view returns (address);

    function getPools(IERC20 token0, IERC20 token1)
        external
        view
        returns (address[] memory _tokenPools);

    function isPool(
        IERC20 token0,
        IERC20 token1,
        address pool
    ) external view returns (bool);
}

interface IDMMPool {
    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function sync() external;

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    function getTradeInfo()
        external
        view
        returns (
            uint112 _vReserve0,
            uint112 _vReserve1,
            uint112 reserve0,
            uint112 reserve1,
            uint256 feeInPrecision
        );

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function ampBps() external view returns (uint32);

    function factory() external view returns (IDMMFactory);

    function kLast() external view returns (uint256);
}






/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * For IERC20, copy from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol to contract if necessary
 */






interface IUniswapV2Callee {
  function uniswapV2Call(
    address sender,
    uint amount0,
    uint amount1,
    bytes calldata data
  ) external;
}

contract TestUniswapFlashSwap is IUniswapV2Callee {




  address public owner;

  address public bridging_token;
  uint public bridging_amount;
  uint public expected_ori_token_amount;
  address[] public poolsPath_kyber;
  IERC20[] public tokensPath_kyber;
  uint public exchangeOrder;    // 1: uniswap > kyber  or  2: kyber > uniswap

  uint public gussedGasFeeInToken;



  // modified from an example in https://docs.kyberswap.com/developer-guides/smart-contract-integration/fetching-pool-addresses/index.html  
  IDMMRouter02 public dmmRouter; // for Kyber
  IDMMFactory public dmmFactory; // for Kyber



  /* 
  * Uniswap V2 router
  */
  address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  // address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //mainnet (MAINNET USE)
  address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab; //Ropsten  https://docs.kyberswap.com/reference/smart-contract/dmmRouter02
  
  // address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet (MAINNET USE)
  address private constant DAI = 0xaD6D458402F60fD3Bd25163575031ACDce07538D; //Ropsten
  
  /* 
  * Uniswap V2 factory
  */
  address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; //miannet & Ropsten








  address private constant FALSE_ADDRESS = 0x0000000000000000000000000000000000000000;



  



  // Keyber's Router
  address kyber_Router = 0x96E8B9E051c81661C36a18dF64ba45F86AC80Aae;   // for Kyber on Ropsten
  // address kyber_Router = 0x1c87257f5e8609940bc751a07bb085bb7f8cdbe6;  // for Kyber on mainnet (MAINNET USE)








  event Log(string message, uint val);


  event Txs(string message, address _address, uint val);
  event ERC20Txs(string message, address _token, address _address, uint val);

  event KyberswapProcess(address _token0, address _token1, uint val0, uint val1);

  event Repayment(string message0, uint val0, string message1, uint val1, string message2, uint val2);






  modifier onlyOwner(){
    require(msg.sender==owner, 'Not owner');
    _;
  }

  constructor() public payable{
    owner = msg.sender;
  }














  /*
  * Borrow money from Uniswap
  */
  function testFlashSwap(address _tokenBorrow, uint _amount, address _bridging_token, uint _bridging_amount, uint _expected_ori_token_amount, address[] memory _poolsPath_kyber, uint _exchangeOrder, uint _gussedGasFeeInToken) external {
    address pair = IUniswapV2Factory(FACTORY).getPair(_tokenBorrow, WETH);
    require(pair != address(0), "!pair");

    address token0 = IUniswapV2Pair(pair).token0();
    address token1 = IUniswapV2Pair(pair).token1();
    uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
    uint amount1Out = _tokenBorrow == token1 ? _amount : 0;

    // need to pass some data to trigger uniswapV2Call
    bytes memory data = abi.encode(_tokenBorrow, _amount);


    // Pass bridging token
    bridging_token = _bridging_token;
    bridging_amount = _bridging_amount;
    expected_ori_token_amount = _expected_ori_token_amount;
    poolsPath_kyber = _poolsPath_kyber;
    exchangeOrder = _exchangeOrder;
    gussedGasFeeInToken = _gussedGasFeeInToken;


    IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
  }

  // called by pair contract
  function uniswapV2Call(
    address _sender,
    uint _amount0,
    uint _amount1,
    bytes calldata _data
  ) external override {
    address token0 = IUniswapV2Pair(msg.sender).token0();
    address token1 = IUniswapV2Pair(msg.sender).token1();
    address pair = IUniswapV2Factory(FACTORY).getPair(token0, token1);
    require(msg.sender == pair, "!pair");
    require(_sender == address(this), "!sender");

    (address tokenBorrow, uint amount) = abi.decode(_data, (address, uint));

    // about 0.3%
    uint fee = ((amount * 3) / 997) + 1;
    uint amountToRepay = amount + fee;

    // do stuff here
    emit Log("amount", amount);
    emit Log("amount0", _amount0);
    emit Log("amount1", _amount1);
    emit Log("fee", fee);
    emit Log("amount to repay", amountToRepay);



    /*
    USE THE TOKENS BORROWED   START =======================
    */
    if (exchangeOrder == 1){  // 1: uniswap > kyber
      emit Log("Money borrowed, going from Uniswap to Kyber, expecting to get bridging token at amount ", bridging_amount);
      swapWithUniswap(tokenBorrow, bridging_token, amount, bridging_amount);
      tokensPath_kyber = [IERC20(bridging_token), IERC20(tokenBorrow)];
      emit KyberswapProcess(bridging_token, tokenBorrow, bridging_amount, expected_ori_token_amount);
      swapWithKyber(bridging_amount, expected_ori_token_amount, poolsPath_kyber, tokensPath_kyber);
    } else {   // 2: kyber > uniswap
      emit Log("Money borrowed, going from Kyber to Uniswap, expecting to get bridging token at amount ", bridging_amount);
      tokensPath_kyber = [IERC20(tokenBorrow), IERC20(bridging_token)];
      emit KyberswapProcess(tokenBorrow, bridging_token, amount, bridging_amount);
      swapWithKyber(amount, bridging_amount, poolsPath_kyber, tokensPath_kyber);
      swapWithUniswap(bridging_token, tokenBorrow, bridging_amount, expected_ori_token_amount);
    }
    emit Repayment("Resulting amount is ", expected_ori_token_amount, "expected repayment is ", amountToRepay, "guessed gas fee is ", gussedGasFeeInToken);
    assert(expected_ori_token_amount > amountToRepay + gussedGasFeeInToken);  // cancel the tx if not profitable by failing it
    /*
    USE THE TOKENS BORROWED   FINISH ======================
    */



    // repay
    IERC20(tokenBorrow).transfer(pair, amountToRepay);
  }



  

  




  /*
  * Uniswap's swap and query
  */
  function getAmountOutMin(
    address _tokenIn,
    address _tokenOut,
    uint _amountIn,
    address _router
  ) external view returns (uint) {

    address UNISWAP_V2_ROUTER_OR_CLONE = _router;
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

    // same length as path
    uint[] memory amountOutMins =
      IUniswapV2Router(UNISWAP_V2_ROUTER_OR_CLONE).getAmountsOut(_amountIn, path);

    return amountOutMins[path.length - 1];
  }

  function getTokensOfPair(address _address) external view returns(address, address){
    // Gets a pair address from Python and returns the two tokens of the pair
    return ( IUniswapV2Pair(_address).token0(), IUniswapV2Pair(_address).token1() );
  }

  // Uniswap swap function
  function swapWithUniswap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin) public {
    //path is an array of addresses.
    //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
    //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
    address[] memory path;
    if (_tokenIn == WETH || _tokenOut == WETH) {
      emit Log("Swapping for WETH ", _amountOutMin);
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      emit Txs("Swapping for token ", _tokenOut, _amountOutMin);
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = WETH;
      path[2] = _tokenOut;
    }
    //then we will call swapExactTokensForTokens
    //for the deadline we will pass in block.timestamp
    //the deadline is the latest time the trade is valid for
    IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, address(this), block.timestamp);
  }










  /*
  * Kyber's query and swap
  */
  function getPairBestPool(address _token0, address _token1) external returns(address){   // Pool with best liquidity
    dmmRouter = IDMMRouter02(kyber_Router);  // for Kyber
    dmmFactory = IDMMFactory(dmmRouter.factory());  // for Kyber
    address[] memory poolAddresses = dmmFactory.getPools( IERC20(_token0), IERC20(_token1) );
    address bestPool;
    uint256 highestKLast = 0;
    uint256 bestIndex = 0;
    for (uint i = 0; i < poolAddresses.length; i++) {
        uint256 currentKLast = IDMMPool(poolAddresses[i]).kLast();
        if (currentKLast > highestKLast) {
            highestKLast = currentKLast;
            bestIndex = i;
        }
    }
    // handle case if highestKLast is 0 (no liquidity)
    if (highestKLast == 0) {
        bestPool = FALSE_ADDRESS;
    } else {
        bestPool = poolAddresses[bestIndex];
    }
    return bestPool;
    // use bestPool for rate queries, liquidity provision or swaps 
  }

  function getRate(uint _amountIn, address[] memory poolsPath, IERC20[] memory tokensPath) external returns (uint256[] memory amounts) {
    // return amounts
    // poolsPath example: [pool 1 address, pool 2 address, ...]
    // tokensPath example: [usdt, dai]
    dmmRouter = IDMMRouter02(kyber_Router);
    return dmmRouter.getAmountsOut(_amountIn, poolsPath, tokensPath);
  }

  function swapWithKyber(uint _amountIn, uint _amountOutMin, address[] memory poolsPath, IERC20[] memory path) public{
    dmmRouter = IDMMRouter02(kyber_Router);  // for Kyber
    // poolsPath example: [pool 1 address, pool 2 address, ...]
    // tokensPath example: [usdt, dai]
    dmmRouter.swapExactTokensForTokens(_amountIn, _amountOutMin, poolsPath, path, address(this), block.timestamp);
  }














  /*
  * Wallet function
  */
  function deposit() public payable {
    // source: https://ftsrg.mit.bme.hu/blockchain-ethereumlab/guide.
    // requires wallet connected to etherscan and use the input box under deposit to enter X ether to work
    emit Txs("Received from ", msg.sender, msg.value);
  }

  function getBalance() public view returns(uint){
    return address(this).balance;
  }

  function getERC20ToeknBalance(address _address) external view returns(uint){
    return ( IERC20(_address).balanceOf(address(this)) );
  }

  function getWETHDAIToeknBalance() external view returns(uint, uint){
    return ( IERC20(WETH).balanceOf(address(this)), IERC20(DAI).balanceOf(address(this)) );
  }

  function transferAllBackToWallet(address _yourWallet, uint _leaveForGas) public payable onlyOwner{
    uint balance = address(this).balance;
    require(balance - _leaveForGas > 0);
    payable(_yourWallet).transfer(balance - _leaveForGas);
    emit Txs("Transferred from contract to address ", _yourWallet, balance - _leaveForGas);
  }

  function transferTokensBackToWalletInTotal(address _yourWallet, address _token) public payable onlyOwner{
    require(IERC20(_token).balanceOf(address(this)) > 0, "The balance of this token is 0");
    uint erc20_balance = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer( _yourWallet, erc20_balance );
    emit ERC20Txs("Transferred from contract to address ", _token, _yourWallet, erc20_balance);
  }

  








}