pragma solidity ^0.8.0;

// SPDX-License-Identifier: Unlicensed

import './interfaces/swap/IUniswapV2Router02.sol';
import './interfaces/swap/IUniswapV2Pair.sol';
import './interfaces/swap/IUniswapV2Factory.sol';
import './interfaces/IERC20.sol';
import './abstracts/Ownable.sol';

contract Arbitrage is Ownable {
  address public factory;
  uint256 public deadline = 300;
  IUniswapV2Router02 public sushiRouter;

  
  IUniswapV2Router02 public pancakeRouter;
  IUniswapV2Router02 public apeRouter;

  address public pancakeWETH;
  address public WETH;

  address public pancakeFactory;
  address public apeFactory;

  address public profitReceiver;


  constructor(address _pancakeRouter, address _apeRouter, address _profitReceiver, bool pancakeToApe) public {
    pancakeRouter = IUniswapV2Router02(_pancakeRouter);
    pancakeFactory = pancakeRouter.factory();

    WETH = pancakeRouter.WETH();

    
    apeRouter = IUniswapV2Router02(_apeRouter);
    apeFactory = apeRouter.factory();

    profitReceiver = _profitReceiver;

    factory = pancakeToApe? pancakeFactory : apeFactory;
    sushiRouter = pancakeToApe? apeRouter : pancakeRouter;

  }

  receive() external payable {

  }

  function ethBalance() external view returns(uint256) {
    return address(this).balance;
  }

  function tokenBalance(address token) external view returns(uint256) {
    return IERC20(token).balanceOf(address(this));
  }

  function getAmountIn(address tokenIn, address tokenOut, uint amountOut) external view returns(uint) {
    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = tokenOut;

    IUniswapV2Router02 router = factory == pancakeFactory? pancakeRouter : apeRouter;
    return router.getAmountsIn(amountOut, path)[0];
  }
  

  function getPairAddress(address token0, address token1) external view returns(address) {
    return IUniswapV2Factory(factory).getPair(token0, token1);
  }

  function claimETH() external onlyOwner {
    sendCoin(owner(), address(this).balance);
  }

  function claimToken(address token) external onlyOwner {
    IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
  }

  function setProfitReceiver(address _profitReceiver) external onlyOwner {
    profitReceiver = _profitReceiver;
  }

  function setPancakeToApe(bool yes) external onlyOwner {
    factory = yes? pancakeFactory : apeFactory;
    sushiRouter = yes? apeRouter : pancakeRouter;
  }

  function setDealine(uint256 _deadline) external onlyOwner {
    deadline = _deadline;
  }

  function arbWETH(
    address token, 
    uint amountToken, 
    uint amountWETH) external {
      
    _startArbitrage(token, WETH, amountToken, amountWETH);
  }

  function arb( 
    address token0, 
    address token1, 
    uint amount0, 
    uint amount1) external {
    
    _startArbitrage(token0, token1, amount0, amount1);
  }

  function _startArbitrage(
    address token0, 
    address token1, 
    uint amount0, 
    uint amount1
  ) private {
    address pairAddress = IUniswapV2Factory(factory).getPair(token0, token1);
    require(pairAddress != address(0), 'This pool does not exist');
    //On a cheap Xchange, borrow loan by swapping 0 tokenA to (x > 0) token B directly from the token pair contract
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    if(pair.token0() == token0) {
      pair.swap(
        amount0, 
        amount1, 
        address(this), 
        bytes('not empty')
      );
    } else {
      pair.swap(
        amount1, 
        amount0, 
        address(this), 
        bytes('not empty')
      );
    }
  }


  function pancakeCall(
    address _sender, 
    uint _amount0, 
    uint _amount1, 
    bytes calldata _data
  ) external {
    //require(!onLend, append(append(uintToString(_amount0), " ::: "), uintToString(_amount1)));
    uint borrowedToken = _amount0 > 0 ? _amount0 : _amount1;
    
    address token0 = IUniswapV2Pair(msg.sender).token0();
    address token1 = IUniswapV2Pair(msg.sender).token1();

    require(
      msg.sender == IUniswapV2Factory(factory).getPair(token0, token1), 
      'Unauthorized'
    );

    require(_amount0 == 0 || _amount1 == 0);

    address[] memory path = new address[](2);
    address[] memory loanPath = new address[](2);

    path[0] = _amount0 > 0 ? token0 : token1;
    path[1] = _amount0 > 0 ? token1 : token0;

    loanPath[0] = path[1];
    loanPath[1] = path[0];

    IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
    
    token.approve(address(sushiRouter), borrowedToken);

    /**
    If 0 SKILL, 1000 WETH was borrowed,
    then:
    1. We must return SKILL worth of 1000 WETH to the loan pair(SKILL to return is calculated with the loan pair factory)
    2. path will be [WETH(borrowed token), SKILL(equivalence of borrowed token to return)]
    3. loanPath will be [SKILL(equivalence of borrowed token to return), WETH(borrowed token)]
     */

    IUniswapV2Router02 router = factory == pancakeFactory? pancakeRouter : apeRouter;
    uint otherTokenNotSentToLoaner = router.getAmountsIn(borrowedToken, loanPath)[0];
    /*
    uint totalBorrowedToTokenNotSentFromProfitableDex = sushiRouter.swapExactTokensForTokens(
      borrowedToken, 
      otherTokenNotSentToLoaner, 
      path, 
      address(this), 
      block.timestamp + deadline
    )[1];*/

    IERC20 otherToken = IERC20(_amount0 == 0 ? token0 : token1);
    otherToken.transfer(msg.sender, otherTokenNotSentToLoaner);


    //otherToken.transfer(profitReceiver, totalBorrowedToTokenNotSentFromProfitableDex - otherTokenNotSentToLoaner);
  }

  function sendCoin(address recipient, uint256 amount) private {
      (bool success, ) = recipient.call{value: amount}(new bytes(0));
      require(success, 'Arbitrage::sendCoin: BNB transfer failed');
  }
}
/**
Hi Julien, I don't think this code works properly. Below is an example where we borrow WETH on Uni to sell for DAI on Sushi and return DAI to Uni (you are doing a multi-asset flash swap, returning a different one than borrowed)
You specify the path to be borrowed asset =>  non-borrowed (WETH => DAI) on lines 53-54. 
token is WETH on line 56.
on line 60-64 you get "the input amount of WETH you need given the output amount of WETH you borrowed". 
the path should be reversed here, you really want to get "the input amount of DAI given you need given the output amount of WETH you borrowed" (borrowedToken).

as a result line 74 is also broken because you are specifying for it to transfer otherTokenNotSentToLoaner amount of DAI, but otherTokenNotSentToLoaner does not represent this. 
Am I tripping here?
**/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
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
    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: Unlicensed
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: Unlicensed

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: Unlicensed

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: Unlicensed

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

