/**
 *Submitted for verification at Etherscan.io on 2021-02-27
*/

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.5.17;


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IDextokenPool {
    event TokenDeposit(
        address indexed token, 
        address indexed account, 
        uint amount,
        uint spotPrice
    );

    event TokenWithdraw(
        address indexed token, 
        address indexed account, 
        uint amount,
        uint spotPrice
    );

    event SwapExactETHForTokens(
        address indexed poolOut, 
        uint amountOut, 
        uint amountIn,
        uint spotPrice,
        address indexed account
    );

    event SwapExactTokensForETH(
        address indexed poolOut, 
        uint amountOut, 
        uint amountIn, 
        uint spotPrice,
        address indexed account
    );

    /// Speculative AMM
    function initialize(address _token0, address _token1, uint _Ct, uint _Pt) external;
    function updateAMM() external returns (uint, uint);
    function mean() external view returns (uint);
    function getLastUpdateTime() external view returns (uint);
    function getCirculatingSupply() external view returns (uint);
    function getUserbase() external view returns (uint);
    function getPrice() external view returns (uint);
    function getSpotPrice(uint _Ct, uint _Nt) external pure returns (uint);
    function getToken() external view returns (address);

    /// Pool Management
    function getPoolBalance() external view returns (uint);    
    function getTotalLiquidity() external view returns (uint);
    function liquidityOf(address account) external view returns (uint);
    function liquiditySharesOf(address account) external view returns (uint);
    function liquidityTokenToAmount(uint token) external view returns (uint);
    function liquidityFromAmount(uint amount) external view returns (uint);
    function deposit(uint amount) external;
    function withdraw(uint tokens) external;

    /// Trading
    function swapExactETHForTokens(
        uint amountIn,
        uint minAmountOut,
        uint maxPrice,
        uint deadline
    ) external returns (uint);

    function swapExactTokensForETH(
        uint amountIn,
        uint minAmountOut,
        uint minPrice,
        uint deadline
    ) external returns (uint);
}

interface IDextokenExchange {
    event SwapExactAmountOut(
        address indexed poolIn, 
        uint amountSwapIn, 
        address indexed poolOut, 
        uint exactAmountOut,
        address indexed to
    );

    event SwapExactAmountIn(
        address indexed poolIn, 
        uint amountSwapIn, 
        address indexed poolOut, 
        uint exactAmountOut,
        address indexed to
    );
    
    function swapMaxAmountOut(
        address poolIn,
        address poolOut, 
        uint maxAmountOut,
        uint deadline
    ) external;

    function swapExactAmountIn(
        address poolIn,
        address poolOut, 
        uint exactAmountIn,
        uint deadline
    ) external;  
}

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}


library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

contract DextokenExchange is IDextokenExchange, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    uint constant MAX = uint(-1);

    address public owner;
    IERC20 public WETH;

    constructor(address _token0) public {
        owner = msg.sender;
        WETH = IERC20(_token0);        
    }

    function swapMaxAmountOut(
        address poolIn,
        address poolOut, 
        uint maxAmountOut,
        uint deadline
    ) 
        external 
        nonReentrant
    {
        require(poolIn != address(0), "exchange: Invalid token address");
        require(poolOut != address(0), "exchange: Invalid token address");
        require(maxAmountOut > 0, "exchange: Invalid maxAmountOut");

        IERC20 poolInToken = IERC20(IDextokenPool(poolIn).getToken());
        IERC20 poolOutToken = IERC20(IDextokenPool(poolOut).getToken());
        IERC20 _WETH = WETH;

        /// calculate the pair price
        uint closingPrice;
        {
            uint priceIn = IDextokenPool(poolIn).getPrice();
            uint priceOut = IDextokenPool(poolOut).getPrice();
            closingPrice = priceOut.mul(1e18).div(priceIn);
        }

        /// evalucate the swap in amount
        uint amountSwapIn = maxAmountOut.mul(closingPrice).div(1e18);
        require(amountSwapIn >= 1e2, "exchange: invalid amountSwapIn");    

        /// transfer tokens in
        poolInToken.safeTransferFrom(msg.sender, address(this), amountSwapIn);
        require(poolInToken.balanceOf(address(this)) >= amountSwapIn, "exchange: Invalid token balance");

        if (poolInToken.allowance(address(this), poolIn) < amountSwapIn) {       
            poolInToken.approve(poolIn, MAX);
        }

        IDextokenPool(poolIn).swapExactTokensForETH(
            amountSwapIn,
            0,
            0,
            deadline
        );

        uint balanceETH = _WETH.balanceOf(address(this));
        uint spotPriceOut = IDextokenPool(poolOut).getSpotPrice(
            IDextokenPool(poolOut).getCirculatingSupply(),
            IDextokenPool(poolOut).getUserbase().add(balanceETH)
        );
        uint minAmountOut = balanceETH.mul(1e18).div(spotPriceOut);

        /// swap ETH for tokens
        if (_WETH.allowance(address(this), poolOut) < balanceETH) {         
            _WETH.approve(poolOut, MAX);
        }

        IDextokenPool(poolOut).swapExactETHForTokens(
            balanceETH,
            minAmountOut,
            spotPriceOut,
            deadline
        );

        /// transfer all tokens
        uint exactAmountOut = poolOutToken.balanceOf(address(this));
        require(exactAmountOut <= maxAmountOut, "exchange: Exceed maxAmountOut");
        poolOutToken.safeTransfer(msg.sender, exactAmountOut);

        emit SwapExactAmountOut(poolIn, amountSwapIn, poolOut, exactAmountOut, msg.sender);
    }

    function swapExactAmountIn(
        address poolIn,
        address poolOut, 
        uint exactAmountIn,
        uint deadline
    ) 
        external 
        nonReentrant
    {
        require(poolIn != address(0), "exchange: Invalid token address");
        require(poolOut != address(0), "exchange: Invalid token address");
        require(exactAmountIn > 0, "exchange: Invalid exactAmountIn");

        IERC20 poolInToken = IERC20(IDextokenPool(poolIn).getToken());
        IERC20 poolOutToken = IERC20(IDextokenPool(poolOut).getToken());
        IERC20 _WETH = WETH;

        /// transfer tokens in
        poolInToken.safeTransferFrom(msg.sender, address(this), exactAmountIn);
        require(poolInToken.balanceOf(address(this)) >= exactAmountIn, "exchange: Invalid token balance");

        if (poolInToken.allowance(address(this), poolIn) < exactAmountIn) {
            poolInToken.approve(address(poolIn), MAX);
        }

        uint balanceETH = IDextokenPool(poolIn).swapExactTokensForETH(
            exactAmountIn,
            0,
            0,
            deadline
        );

        if (_WETH.allowance(address(this), poolOut) < balanceETH) {       
            _WETH.approve(address(poolOut), MAX);
        }

        uint exactAmountOut = IDextokenPool(poolOut).swapExactETHForTokens(
            balanceETH,
            0,
            MAX,
            deadline
        );

        /// transfer all tokens
        poolOutToken.safeTransfer(msg.sender, exactAmountOut);

        emit SwapExactAmountIn(poolIn, exactAmountIn, poolOut, exactAmountOut, msg.sender);
    }            
}