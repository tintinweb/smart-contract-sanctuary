/**
 *Submitted for verification at cronoscan.com on 2022-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        if (b > a) {return 0;} else {return a - b;}
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library Babylonian {
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;

        uint256 r1 = x / r;

        return (r < r1 ? r : r1);
    }
}

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISwapPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

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

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface ISwapRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
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

    function addLiquidityETH(
        address token,
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
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

    function removeLiquidityETHWithPermit(
        address token,
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

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface ISwapRouter02 is ISwapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
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
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract StrongZaps is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IWETH public WCRO;
    ISwapRouter02 public swapRouter;

    // Maximum integer (used for managing allowance)
    uint256 public constant MAX_INT = 2**256 - 1;

    // Minimum amount for a swap (derived from swap)
    uint256 public constant MINIMUM_AMOUNT = 1000;

    // Maximum reverse zap ratio (100 --> 1%, 1000 --> 0.1%)
    uint256 public maxZapReverseRatio;

    address private swapRouterAddress;
    address private WCROAddress;

    event AdminTokenRecovery(address indexed tokenAddress, uint256 amountTokens);
    event NewMaxZapReverseRatio(uint256 maxZapReverseRatio);

    event ZapIn(address indexed tokenToZap, address indexed lpToken, uint256 tokenAmountIn, uint256 lpTokenAmountReceived, address indexed user);
    event ZapInRebalancing(address indexed token0ToZap, address indexed token1ToZap, address lpToken, uint256 token0AmountIn, uint256 token1AmountIn, uint256 lpTokenAmountReceived, address indexed user);
    event ZapOut(address indexed lpToken, address indexed tokenToReceive, uint256 lpTokenAmount, uint256 tokenAmountReceived, address indexed user);

    receive() external payable {
        assert(msg.sender == WCROAddress);
    }

    constructor(address _swapRouter, uint256 _maxZapReverseRatio) public {

        swapRouterAddress = _swapRouter;
        swapRouter = ISwapRouter02(_swapRouter);
        
        WCROAddress = swapRouter.WETH();
        WCRO = IWETH(WCROAddress);

        maxZapReverseRatio = _maxZapReverseRatio;
    }

    /////////////////////
    // WRITE FUNCTIONS //
    /////////////////////

    function zapInCRO(address _lpToken, uint256 _tokenAmountOutMin) external payable nonReentrant {
        WCRO.deposit{value: msg.value}();

        // Call zap function
        uint256 lpTokenAmountTransferred = _zapIn(WCROAddress, msg.value, _lpToken, _tokenAmountOutMin);

        // Emit event
        emit ZapIn(address(0), _lpToken, msg.value, lpTokenAmountTransferred, address(msg.sender));
    }

    function zapInToken(address _tokenToZap, uint256 _tokenAmountIn, address _lpToken, uint256 _tokenAmountOutMin) external nonReentrant {
        // Transfer tokens to this contract
        IERC20(_tokenToZap).safeTransferFrom(address(msg.sender), address(this), _tokenAmountIn);

        // Call zap function
        uint256 lpTokenAmountTransferred = _zapIn(_tokenToZap, _tokenAmountIn, _lpToken, _tokenAmountOutMin);

        // Emit event
        emit ZapIn(_tokenToZap, _lpToken, _tokenAmountIn, lpTokenAmountTransferred, address(msg.sender));
    }

    function zapInTokenRebalancing(address _token0ToZap, address _token1ToZap, uint256 _token0AmountIn, uint256 _token1AmountIn, address _lpToken, uint256 _tokenAmountInMax, uint256 _tokenAmountOutMin, bool _isToken0Sold) external nonReentrant {
        IERC20(_token0ToZap).safeTransferFrom(address(msg.sender), address(this), _token0AmountIn);
        IERC20(_token1ToZap).safeTransferFrom(address(msg.sender), address(this), _token1AmountIn);

        uint256 lpTokenAmountTransferred = _zapInRebalancing(_token0ToZap, _token1ToZap, _token0AmountIn, _token1AmountIn, _lpToken, _tokenAmountInMax, _tokenAmountOutMin, _isToken0Sold);

        emit ZapInRebalancing(_token0ToZap, _token1ToZap, _lpToken, _token0AmountIn, _token1AmountIn, lpTokenAmountTransferred, address(msg.sender));
    }

    function zapInCRORebalancing(address _token1ToZap, uint256 _token1AmountIn, address _lpToken, uint256 _tokenAmountInMax, uint256 _tokenAmountOutMin, bool _isToken0Sold) external payable nonReentrant {
        WCRO.deposit{value: msg.value}();

        IERC20(_token1ToZap).safeTransferFrom(address(msg.sender), address(this), _token1AmountIn);

        // Call zapIn function
        uint256 lpTokenAmountTransferred = _zapInRebalancing(WCROAddress, _token1ToZap, msg.value, _token1AmountIn, _lpToken, _tokenAmountInMax, _tokenAmountOutMin, _isToken0Sold);

        // Emit event
        emit ZapInRebalancing(address(0), _token1ToZap, _lpToken, msg.value, _token1AmountIn, lpTokenAmountTransferred, address(msg.sender));
    }

    function zapOutCRO(address _lpToken, uint256 _lpTokenAmount, uint256 _tokenAmountOutMin) external nonReentrant {
        
        // Transfer LP token to this address
        IERC20(_lpToken).safeTransferFrom(address(msg.sender), address(_lpToken), _lpTokenAmount);

        // Call zapOut
        uint256 tokenAmountToTransfer = _zapOut(_lpToken, WCROAddress, _tokenAmountOutMin);

        // Unwrap CRO
        WCRO.withdraw(tokenAmountToTransfer);

        // Transfer CRO to the msg.sender
        (bool success, ) = msg.sender.call{value: tokenAmountToTransfer}(new bytes(0));
        require(success, "CRO: transfer fail");

        // Emit event
        emit ZapOut(_lpToken, address(0), _lpTokenAmount, tokenAmountToTransfer, address(msg.sender));
    }

    function zapOutToken(address _lpToken, address _tokenToReceive, uint256 _lpTokenAmount, uint256 _tokenAmountOutMin) external nonReentrant {
        
        // Transfer LP token to this address
        IERC20(_lpToken).safeTransferFrom(address(msg.sender), address(_lpToken), _lpTokenAmount);

        uint256 tokenAmountToTransfer = _zapOut(_lpToken, _tokenToReceive, _tokenAmountOutMin);

        IERC20(_tokenToReceive).safeTransfer(address(msg.sender), tokenAmountToTransfer);

        emit ZapOut(_lpToken, _tokenToReceive, _lpTokenAmount, tokenAmountToTransfer, msg.sender);
    }

    //////////////////////////
    // OWNER-ONLY FUNCTIONS //
    //////////////////////////

    function updateMaxZapInverseRatio(uint256 _maxZapInverseRatio) external onlyOwner {
        maxZapReverseRatio = _maxZapInverseRatio;
        emit NewMaxZapReverseRatio(_maxZapInverseRatio);
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////

    function estimateZapInSwap(address _tokenToZap, uint256 _tokenAmountIn, address _lpToken) external view returns (uint256 swapAmountIn, uint256 swapAmountOut, address swapTokenOut) {
        address token0 = ISwapPair(_lpToken).token0();
        address token1 = ISwapPair(_lpToken).token1();

        require(_tokenToZap == token0 || _tokenToZap == token1, "Zap: Wrong tokens");

        // Convert to uint256 (from uint112)
        (uint256 reserveA, uint256 reserveB, ) = ISwapPair(_lpToken).getReserves();

        if (token0 == _tokenToZap) {
            swapTokenOut = token1;
            swapAmountIn = _calculateAmountToSwap(_tokenAmountIn, reserveA, reserveB);
            swapAmountOut = swapRouter.getAmountOut(swapAmountIn, reserveA, reserveB);
        } else {
            swapTokenOut = token0;
            swapAmountIn = _calculateAmountToSwap(_tokenAmountIn, reserveB, reserveA);
            swapAmountOut = swapRouter.getAmountOut(swapAmountIn, reserveB, reserveA);
        }

        return (swapAmountIn, swapAmountOut, swapTokenOut);
    }

    function estimateZapInRebalancingSwap(address _token0ToZap, address _token1ToZap, uint256 _token0AmountIn, uint256 _token1AmountIn, address _lpToken) external view returns (uint256 swapAmountIn, uint256 swapAmountOut, bool sellToken0) {
        require(_token0ToZap == ISwapPair(_lpToken).token0() || _token0ToZap == ISwapPair(_lpToken).token1(), "Zap: Wrong token0");
        require(_token1ToZap == ISwapPair(_lpToken).token0() || _token1ToZap == ISwapPair(_lpToken).token1(), "Zap: Wrong token1");

        require(_token0ToZap != _token1ToZap, "Zap: Same tokens");

        // Convert to uint256 (from uint112)
        (uint256 reserveA, uint256 reserveB, ) = ISwapPair(_lpToken).getReserves();

        if (_token0ToZap == ISwapPair(_lpToken).token0()) {
            sellToken0 = (_token0AmountIn * reserveB > _token1AmountIn * reserveA) ? true : false;

            // Calculate the amount that is expected to be swapped
            swapAmountIn = _calculateAmountToSwapForRebalancing(
                _token0AmountIn,
                _token1AmountIn,
                reserveA,
                reserveB,
                sellToken0
            );

            // Calculate the amount expected to be received in the intermediary swap
            if (sellToken0) {
                swapAmountOut = swapRouter.getAmountOut(swapAmountIn, reserveA, reserveB);
            } else {
                swapAmountOut = swapRouter.getAmountOut(swapAmountIn, reserveB, reserveA);
            }
        } else {
            sellToken0 = (_token0AmountIn * reserveA > _token1AmountIn * reserveB) ? true : false;
            // Calculate the amount that is expected to be swapped
            swapAmountIn = _calculateAmountToSwapForRebalancing(
                _token0AmountIn,
                _token1AmountIn,
                reserveB,
                reserveA,
                sellToken0
            );

            // Calculate the amount expected to be received in the intermediary swap
            if (sellToken0) {
                swapAmountOut = swapRouter.getAmountOut(swapAmountIn, reserveB, reserveA);
            } else {
                swapAmountOut = swapRouter.getAmountOut(swapAmountIn, reserveA, reserveB);
            }
        }

        return (swapAmountIn, swapAmountOut, sellToken0);
    }

    function estimateZapOutSwap(address _lpToken, uint256 _lpTokenAmount, address _tokenToReceive) external view returns (uint256 swapAmountIn, uint256 swapAmountOut, address swapTokenOut) {
        address token0 = ISwapPair(_lpToken).token0();
        address token1 = ISwapPair(_lpToken).token1();

        require(_tokenToReceive == token0 || _tokenToReceive == token1, "Zap: Token not in LP");

        // Convert to uint256 (from uint112)
        (uint256 reserveA, uint256 reserveB, ) = ISwapPair(_lpToken).getReserves();

        if (token1 == _tokenToReceive) {
            // sell token0
            uint256 tokenAmountIn = (_lpTokenAmount * reserveA) / ISwapPair(_lpToken).totalSupply();

            swapAmountIn = _calculateAmountToSwap(tokenAmountIn, reserveA, reserveB);
            swapAmountOut = swapRouter.getAmountOut(swapAmountIn, reserveA, reserveB);

            swapTokenOut = token0;
        } else {
            // sell token1
            uint256 tokenAmountIn = (_lpTokenAmount * reserveB) / ISwapPair(_lpToken).totalSupply();

            swapAmountIn = _calculateAmountToSwap(tokenAmountIn, reserveB, reserveA);
            swapAmountOut = swapRouter.getAmountOut(swapAmountIn, reserveB, reserveA);

            swapTokenOut = token1;
        }

        return (swapAmountIn, swapAmountOut, swapTokenOut);
    }

    ////////////////////////
    // INTERNAL FUNCTIONS //
    ////////////////////////

    function _zapIn(address _tokenToZap, uint256 _tokenAmountIn, address _lpToken, uint256 _tokenAmountOutMin) internal returns (uint256 lpTokenReceived) {
        require(_tokenAmountIn >= MINIMUM_AMOUNT, "Zap: Amount too low");

        address token0 = ISwapPair(_lpToken).token0();
        address token1 = ISwapPair(_lpToken).token1();

        require(_tokenToZap == token0 || _tokenToZap == token1, "Zap: Wrong tokens");

        // Retrieve the path
        address[] memory path = new address[](2);
        path[0] = _tokenToZap;

        // Initiates an estimation to swap
        uint256 swapAmountIn;

        {
            // Convert to uint256 (from uint112)
            (uint256 reserveA, uint256 reserveB, ) = ISwapPair(_lpToken).getReserves();

            require((reserveA >= MINIMUM_AMOUNT) && (reserveB >= MINIMUM_AMOUNT), "Zap: Reserves too low");

            if (token0 == _tokenToZap) {
                swapAmountIn = _calculateAmountToSwap(_tokenAmountIn, reserveA, reserveB);
                path[1] = token1;
                require(reserveA / swapAmountIn >= maxZapReverseRatio, "Zap: Quantity higher than limit");
            } else {
                swapAmountIn = _calculateAmountToSwap(_tokenAmountIn, reserveB, reserveA);
                path[1] = token0;
                require(reserveB / swapAmountIn >= maxZapReverseRatio, "Zap: Quantity higher than limit");
            }
        }

        // Approve token to zap if necessary
        _approveTokenIfNeeded(_tokenToZap);

        uint256[] memory swapedAmounts = swapRouter.swapExactTokensForTokens(
            swapAmountIn,
            _tokenAmountOutMin,
            path,
            address(this),
            block.timestamp
        );

        // Approve other token if necessary
        if (token0 == _tokenToZap) {
            _approveTokenIfNeeded(token1);
        } else {
            _approveTokenIfNeeded(token0);
        }

        // Add liquidity and retrieve the amount of LP received by the sender
        (, , lpTokenReceived) = swapRouter.addLiquidity(
            path[0],
            path[1],
            _tokenAmountIn - swapedAmounts[0],
            swapedAmounts[1],
            1,
            1,
            address(msg.sender),
            block.timestamp
        );

        return lpTokenReceived;
    }

    function _zapInRebalancing(address _token0ToZap, address _token1ToZap, uint256 _token0AmountIn, uint256 _token1AmountIn, address _lpToken, uint256 _tokenAmountInMax, uint256 _tokenAmountOutMin, bool _isToken0Sold) internal returns (uint256 lpTokenReceived) {
        require(
            _token0ToZap == ISwapPair(_lpToken).token0() || _token0ToZap == ISwapPair(_lpToken).token1(),
            "Zap: Wrong token0"
        );
        require(
            _token1ToZap == ISwapPair(_lpToken).token0() || _token1ToZap == ISwapPair(_lpToken).token1(),
            "Zap: Wrong token1"
        );

        require(_token0ToZap != _token1ToZap, "Zap: Same tokens");

        // Initiates an estimation to swap
        uint256 swapAmountIn;

        {
            // Convert to uint256 (from uint112)
            (uint256 reserveA, uint256 reserveB, ) = ISwapPair(_lpToken).getReserves();

            require((reserveA >= MINIMUM_AMOUNT) && (reserveB >= MINIMUM_AMOUNT), "Zap: Reserves too low");

            if (_token0ToZap == ISwapPair(_lpToken).token0()) {
                swapAmountIn = _calculateAmountToSwapForRebalancing(
                    _token0AmountIn,
                    _token1AmountIn,
                    reserveA,
                    reserveB,
                    _isToken0Sold
                );
                require(reserveA / swapAmountIn >= maxZapReverseRatio, "Zap: Quantity higher than limit");
            } else {
                swapAmountIn = _calculateAmountToSwapForRebalancing(
                    _token0AmountIn,
                    _token1AmountIn,
                    reserveB,
                    reserveA,
                    _isToken0Sold
                );

                require(reserveB / swapAmountIn >= maxZapReverseRatio, "Zap: Quantity higher than limit");
            }
        }

        require(swapAmountIn <= _tokenAmountInMax, "Zap: Amount to swap too high");

        address[] memory path = new address[](2);

        // Define path for swapping and check whether to approve token to sell in intermediary swap
        if (_isToken0Sold) {
            path[0] = _token0ToZap;
            path[1] = _token1ToZap;
            _approveTokenIfNeeded(_token0ToZap);
        } else {
            path[0] = _token1ToZap;
            path[1] = _token0ToZap;
            _approveTokenIfNeeded(_token1ToZap);
        }

        // Execute the swap and retrieve quantity received
        uint256[] memory swapedAmounts = swapRouter.swapExactTokensForTokens(
            swapAmountIn,
            _tokenAmountOutMin,
            path,
            address(this),
            block.timestamp
        );

        // Check whether to approve other token and add liquidity to LP
        if (_isToken0Sold) {
            _approveTokenIfNeeded(_token1ToZap);

            (, , lpTokenReceived) = swapRouter.addLiquidity(
                path[0],
                path[1],
                (_token0AmountIn - swapedAmounts[0]),
                (_token1AmountIn + swapedAmounts[1]),
                1,
                1,
                address(msg.sender),
                block.timestamp
            );
        } else {
            _approveTokenIfNeeded(_token0ToZap);
            (, , lpTokenReceived) = swapRouter.addLiquidity(
                path[0],
                path[1],
                (_token1AmountIn - swapedAmounts[0]),
                (_token0AmountIn + swapedAmounts[1]),
                1,
                1,
                address(msg.sender),
                block.timestamp
            );
        }

        return lpTokenReceived;
    }

    function _zapOut(address _lpToken, address _tokenToReceive, uint256 _tokenAmountOutMin) internal returns (uint256) {
        address token0 = ISwapPair(_lpToken).token0();
        address token1 = ISwapPair(_lpToken).token1();

        require(_tokenToReceive == token0 || _tokenToReceive == token1, "Zap: Token not in LP");

        // Burn all LP tokens to receive the two tokens to this address
        (uint256 amount0, uint256 amount1) = ISwapPair(_lpToken).burn(address(this));

        require(amount0 >= MINIMUM_AMOUNT, "SwapRouter: INSUFFICIENT_A_AMOUNT");
        require(amount1 >= MINIMUM_AMOUNT, "SwapRouter: INSUFFICIENT_B_AMOUNT");

        address[] memory path = new address[](2);
        path[1] = _tokenToReceive;

        uint256 swapAmountIn;

        if (token0 == _tokenToReceive) {
            path[0] = token1;
            swapAmountIn = IERC20(token1).balanceOf(address(this));

            // Approve token to sell if necessary
            _approveTokenIfNeeded(token1);
        } else {
            path[0] = token0;
            swapAmountIn = IERC20(token0).balanceOf(address(this));

            // Approve token to sell if necessary
            _approveTokenIfNeeded(token0);
        }

        // Swap tokens
        swapRouter.swapExactTokensForTokens(swapAmountIn, _tokenAmountOutMin, path, address(this), block.timestamp);

        // Return full balance for the token to receive by the sender
        return IERC20(_tokenToReceive).balanceOf(address(this));
    }

    function _approveTokenIfNeeded(address _token) private {
        if (IERC20(_token).allowance(address(this), swapRouterAddress) < 1e24) {
            IERC20(_token).safeApprove(swapRouterAddress, MAX_INT);
        }
    }

    function _calculateAmountToSwap(uint256 _token0AmountIn, uint256 _reserve0, uint256 _reserve1) private view returns (uint256 amountToSwap) {
        uint256 halfToken0Amount = _token0AmountIn / 2;
        uint256 nominator = swapRouter.getAmountOut(halfToken0Amount, _reserve0, _reserve1);
        uint256 denominator = swapRouter.quote(halfToken0Amount, _reserve0 + halfToken0Amount, _reserve1 - nominator);

        // Adjustment for price impact
        amountToSwap = _token0AmountIn - Babylonian.sqrt((halfToken0Amount * halfToken0Amount * nominator) / denominator);

        return amountToSwap;
    }

    function _calculateAmountToSwapForRebalancing(uint256 _token0AmountIn, uint256 _token1AmountIn, uint256 _reserve0, uint256 _reserve1, bool _isToken0Sold) private view returns (uint256 amountToSwap) {
        bool sellToken0 = (_token0AmountIn * _reserve1 > _token1AmountIn * _reserve0) ? true : false;

        require(sellToken0 == _isToken0Sold, "Zap: Wrong trade direction");

        if (sellToken0) {
            uint256 token0AmountToSell = (_token0AmountIn - (_token1AmountIn * _reserve0) / _reserve1) / 2;
            uint256 nominator = swapRouter.getAmountOut(token0AmountToSell, _reserve0, _reserve1);
            uint256 denominator = swapRouter.quote(
                token0AmountToSell,
                _reserve0 + token0AmountToSell,
                _reserve1 - nominator
            );

            // Calculate the amount to sell (in token0)
            token0AmountToSell =
                (_token0AmountIn - (_token1AmountIn * (_reserve0 + token0AmountToSell)) / (_reserve1 - nominator)) /
                2;

            // Adjustment for price impact
            amountToSwap =
                2 *
                token0AmountToSell -
                Babylonian.sqrt((token0AmountToSell * token0AmountToSell * nominator) / denominator);
        } else {
            uint256 token1AmountToSell = (_token1AmountIn - (_token0AmountIn * _reserve1) / _reserve0) / 2;
            uint256 nominator = swapRouter.getAmountOut(token1AmountToSell, _reserve1, _reserve0);

            uint256 denominator = swapRouter.quote(
                token1AmountToSell,
                _reserve1 + token1AmountToSell,
                _reserve0 - nominator
            );

            // Calculate the amount to sell (in token1)
            token1AmountToSell =
                (_token1AmountIn - ((_token0AmountIn * (_reserve1 + token1AmountToSell)) / (_reserve0 - nominator))) /
                2;

            // Adjustment for price impact
            amountToSwap =
                2 *
                token1AmountToSell -
                Babylonian.sqrt((token1AmountToSell * token1AmountToSell * nominator) / denominator);
        }

        return amountToSwap;
    }
}