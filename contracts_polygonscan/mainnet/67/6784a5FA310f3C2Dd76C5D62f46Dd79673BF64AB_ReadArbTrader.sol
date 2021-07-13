/**
 *Submitted for verification at polygonscan.com on 2021-07-13
*/

pragma solidity >=0.6.12;

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

library SafeMath {
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
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeRate() external view returns (uint);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeRate(uint) external;
    function setFeeToSetter(address) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract ReadArbTrader {

    address payable                 Na_owner;
    
    address[]                       Routerpath;   
    
    address[][]                     Startpath;
    address[][]                     Endpath;

    using SafeMath for uint256;
    
    constructor() public {
        Na_owner = msg.sender;
        Startpath = new address[][](100);
        Endpath = new address[][](100);
    }

    function setRouter(address[] memory _Routerpath) external {
        
        Routerpath = new address[](_Routerpath.length);

        for(uint256 i = 0; i < _Routerpath.length; i++) {
            Routerpath[i] = _Routerpath[i];
        }

    }    
    
    function setPair(uint256 _CoinNo, address[] memory _Startpath, address[] memory _Endpath) external {
        
        Startpath[_CoinNo] = new address[](_Startpath.length);
        Endpath[_CoinNo] = new address[](_Endpath.length);
  
        for(uint256 i = 0; i < _Startpath.length; i++) {
            Startpath[_CoinNo][i] = _Startpath[i];
        }
        
        for(uint256 i = 0; i < _Endpath.length; i++) {
            Endpath[_CoinNo][i] = _Endpath[i];
        }
        
        
    }
    
    function WithdrawToken(address _token) external {
        IERC20 token = IERC20(_token);
        token.transfer(Na_owner, token.balanceOf(address(this)));
    }
    
    function Approve(address _owner, address _token) public {
        IERC20 token = IERC20(_token);
        token.approve(_owner, uint256(-1));
    }
  
    function GetSwapAmounts(uint256 _CoinNo, uint256 StartIndex, uint256 EndIndex, uint256 _AmountIn, uint256 _AmountOut)
        public 
        view
        virtual
        returns (uint256 amounts)
    {
        uint256 amountToken = 0;
        uint256 amountToken2 = 0;
        uint256[] memory amountsToken = new uint256[](4);
       
        amountsToken[0] = IERC20(Startpath[_CoinNo][0]).balanceOf(getUniParAdd(StartIndex, Startpath[_CoinNo][0], Startpath[_CoinNo][1]));
       
        
        if (Startpath[_CoinNo].length > 2) { 
            amountToken2 = getUniParAmount(StartIndex, _AmountIn, Startpath[_CoinNo][0], Startpath[_CoinNo][1]);
            amountsToken[2] = IERC20(Startpath[_CoinNo][1]).balanceOf(getUniParAdd(StartIndex, Startpath[_CoinNo][1], Startpath[_CoinNo][2])) / amountToken2;
            amountsToken[2] = amountsToken[2] * _AmountIn;
        } 
        
        if (Endpath[_CoinNo].length > 2) { 
            amountsToken[1] = IERC20(Startpath[_CoinNo][0]).balanceOf(getUniParAdd(EndIndex, Endpath[_CoinNo][1], Endpath[_CoinNo][2]));
            amountToken2 = getUniParAmount(EndIndex, _AmountIn, Endpath[_CoinNo][2], Endpath[_CoinNo][1]);
            amountsToken[3] = IERC20(Endpath[_CoinNo][1]).balanceOf(getUniParAdd(EndIndex, Endpath[_CoinNo][0], Endpath[_CoinNo][1])) / amountToken2;
            amountsToken[3] = amountsToken[3] * _AmountIn;
            
        } else {
            amountsToken[1] = IERC20(Startpath[_CoinNo][0]).balanceOf(getUniParAdd(EndIndex, Endpath[_CoinNo][0], Endpath[_CoinNo][1]));
        }
        
        amountToken = ((((_AmountOut - _AmountIn) * _AmountIn) / _AmountOut) * amountsToken[0]) / _AmountIn;
        
        for(uint256 i = 1; i < amountsToken.length; i++) {
            if (amountsToken[i] != 0) {
                if (amountToken > (((((_AmountOut - _AmountIn) * _AmountIn) / _AmountOut) * amountsToken[i]) / _AmountIn)) {
                    amountToken = ((((_AmountOut - _AmountIn) * _AmountIn) / _AmountOut) * amountsToken[i]) / _AmountIn;
                }
            }
        }
        
        //if (amountsToken[1] > amountsToken[0]) {
        //    amountToken = ((((_AmountOut - _AmountIn) * _AmountIn) / _AmountOut) * amountsToken[0]) / _AmountIn;
        //} else {
        //    amountToken = ((((_AmountOut - _AmountIn) * _AmountIn) / _AmountOut) * amountsToken[1]) / _AmountIn;
        //} 
        
        amountToken = amountToken.div(2);

        amounts = amountToken;
    }
    
    function GetAmounts(uint256 _CoinNo, uint _AmountIn)
        public 
        view
        virtual
        returns (uint256 amounts)
    {
        uint256 amounts0 = 0;
        uint256 amounts1 = 0;
        uint256 amounts2 = 0;
        
        for(uint256 i = 0; i < Routerpath.length; i++) {
            try IUniswapV2Router01(Routerpath[i]).getAmountsOut(_AmountIn, Startpath[_CoinNo]) returns (uint256[] memory amountsS) {
                if (amounts0 <= amountsS[amountsS.length-1]) {
                    amounts0 = amountsS[amountsS.length-1];
                }
            } catch {
                continue;
            }
        }
     
        for(uint256 i = 0; i < Routerpath.length; i++) {
            try IUniswapV2Router01(Routerpath[i]).getAmountsOut(amounts0, Endpath[_CoinNo]) returns (uint256[] memory amountsS) {
                if (amounts2 <= amountsS[amountsS.length-1]) {
                    amounts2 = amountsS[amountsS.length-1];
                }
            } catch {
                continue;
            }
        }
        
        amounts = amounts2;
    }
    
    function getAmountsPer(uint256 _CoinNo, uint _AmountIn)
        public
        view
        virtual
        returns (uint256 amounts, uint256 StartIndex, uint256 EndIndex )
    {
        
        uint256 amounts0 = 0;
        uint256 amounts1 = 0;
        uint256 amounts2 = 0;
        
        for(uint256 i = 0; i < Routerpath.length; i++) {
            try IUniswapV2Router01(Routerpath[i]).getAmountsOut(_AmountIn, Startpath[_CoinNo]) returns (uint256[] memory amountsS) {
                if (amounts0 <= amountsS[amountsS.length-1]) {
                    amounts0 = amountsS[amountsS.length-1];
                    StartIndex = i;
                }
            } catch {
                continue;
            }
        }
     
        for(uint256 i = 0; i < Routerpath.length; i++) {
            
            try IUniswapV2Router01(Routerpath[i]).getAmountsOut(amounts0, Endpath[_CoinNo]) returns (uint256[] memory amountsS) {
                if (amounts2 <= amountsS[amountsS.length-1]) {
                    amounts2 = amountsS[amountsS.length-1];
                    EndIndex = i;
                }
            } catch {
                continue;
            }
           
        }
        
        amounts = amounts2;
    }
    
    function getUniParAmount(uint256 _CoinNo, uint _AmountIn, address _asset0, address _asset1)
        public
        view
        virtual
        returns (uint256 _Amount)
    {  
        address[] memory amountspath = new address[](2);
        uint256[] memory amountsToken = new uint256[](2);
        amountspath[0] = _asset0;
        amountspath[1] = _asset1;
        
        amountsToken = IUniswapV2Router01(Routerpath[_CoinNo]).getAmountsOut(_AmountIn, amountspath);
        
        _Amount = amountsToken[amountsToken.length-1];
    }

    function getUniParAdd(uint256 _CoinNo, address _asset0, address _asset1)
        public
        view
        virtual
        returns (address factoryAdd)
    {  
        IUniswapV2Router01 routerS = IUniswapV2Router01(Routerpath[_CoinNo]);
        IUniswapV2Factory factoryS = IUniswapV2Factory(routerS.factory());
        factoryAdd = factoryS.getPair(_asset0, _asset1);
    }
   
    function getStartPath(uint256 _CoinNo)
        public
        view
        virtual
        returns (address[] memory _Startpath)
    {  
        _Startpath = Startpath[_CoinNo];
    }
   
    function getEndPath(uint256 _CoinNo)
        public
        view
        virtual
        returns (address[] memory _Endpath)
    {  
         _Endpath = Endpath[_CoinNo];
    }
    
    function getStartAdd(uint256 _CoinNo, uint256 _PathIdx)
        public
        view
        virtual
        returns (address _Startpath)
    {  
        _Startpath = Startpath[_CoinNo][_PathIdx];
    }
   
    function getEndAdd(uint256 _CoinNo, uint256 _PathIdx)
        public
        view
        virtual
        returns (address _Endpath)
    {  
         _Endpath = Endpath[_CoinNo][_PathIdx];
    }
    
    function getRouterAdd(uint256 _CoinNo)
        public
        view
        virtual
        returns (address _Routerpath)
    {  
         _Routerpath = Routerpath[_CoinNo];
    }
    
    function GroupReadSwap(uint256 _AmountIn, uint256[] memory _CoinNo) 
        public 
        view
        virtual
        returns (uint256[] memory amounts) {
            
        amounts = new uint256[](_CoinNo.length);

        for (uint i = 0; i < _CoinNo.length; i++) {
            amounts[i] = GetAmounts(_CoinNo[i], _AmountIn);
        }

    }
}