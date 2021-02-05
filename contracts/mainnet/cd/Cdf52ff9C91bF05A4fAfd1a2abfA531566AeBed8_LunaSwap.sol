/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// Uniswap V2

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

library UniswapV2Library {
    using SafeMathUniswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

interface IUniswapV2Pair {
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

interface IUniswapV2Router01 {
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
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// Token interface

interface TokenInterface is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

// Balancer library

contract BNum {
    uint public constant BONE = 10**18;

    function btoi(uint a)
        internal pure 
        returns (uint)
    {
        return a / BONE;
    }

    function bfloor(uint a)
        internal pure
        returns (uint)
    {
        return btoi(a) * BONE;
    }

    function badd(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint a, uint b)
        internal pure
        returns (uint)
    {
        (uint c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint a, uint b)
        internal pure
        returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        require(b != 0, "ERR_DIV_ZERO");
        uint c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint c2 = c1 / b;
        return c2;
    }
}

// Balancer pool interface

interface BPoolInterface is IERC20 {
    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;
    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;
    function getNormalizedWeight(address token) external view returns (uint256);
    function getBalance(address) external view returns (uint256);
    function getCurrentTokens() external view returns (address[] memory tokens);
    function getNumTokens() external view returns (uint256);
}

// Swap contract

contract LunaSwap is Ownable, BNum {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for TokenInterface;
    using SafeERC20 for BPoolInterface;

    // States
    TokenInterface public weth;
    TokenInterface public univ2;
    TokenInterface public twa;
    BPoolInterface public lunaBP;
    IUniswapV2Router02 public uniswapV2Router;

    mapping(address => address) public uniswapEthPairByTokenAddress;
    mapping(address => address) public uniswapEthPairToken0;
    mapping(address => bool) public reApproveTokens;
    uint256 public defaultSlippage;

    struct CalculationStruct {
        uint256 tokenAmount;
        uint256 ethAmount;
        uint256 tokenReserve;
        uint256 ethReserve;
    }

    // Events
    event SetTokenSetting(
        address indexed token,
        bool indexed reApprove,
        address indexed uniswapPair
    );
    event SetDefaultSlippage(uint256 newDefaultSlippage);
    event EthToLunaSwap(
        address indexed user,
        uint256 ethInAmount,
        uint256 poolOutAmount
    );
    event OddEth(address indexed user, uint256 amount);
    event OddToken(address indexed user, address indexed token, uint256 amount);
    event LunaToEthSwap(
        address indexed user,
        uint256 poolInAmount,
        uint256 ethOutAmount
    );
    event BuyTwaAndAddLiquidityToUniswapV2(
        address indexed msgSender,
        uint256 totalAmount,
        uint256 ethAmount,
        uint256 twaAmount
    );
    event Erc20ToLunaSwap(
        address indexed user,
        address indexed swapToken,
        uint256 erc20InAmount,
        uint256 ethInAmount,
        uint256 poolOutAmount
    );
    event LunaToErc20Swap(
        address indexed user,
        address indexed swapToken,
        uint256 poolInAmount,
        uint256 ethOutAmount,
        uint256 erc20OutAmount
    );

    constructor() public {
        // Just for test
        weth = TokenInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        univ2 = TokenInterface(0x748a9631baD6AF6D048aE66e2e6E3F44213Fb1E0);
        twa = TokenInterface(0xa2EF2757D2eD560c9e3758D1946d7bcccBD5A7fe);
        lunaBP = BPoolInterface(0x3B260CF977DF1ff8d87960064DaeE2cE491a1B91);
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        defaultSlippage = 0.04 ether;
    }

    receive() external payable {
        if (msg.sender != tx.origin) {
            return;
        }
        swapEthToLuna(defaultSlippage);
    }

    function setTokensSettings(
        address[] memory _tokens,
        address[] memory _pairs,
        bool[] memory _reapprove
    ) external onlyOwner {
        uint256 len = _tokens.length;
        require(len == _pairs.length && len == _reapprove.length, "LENGTHS_NOT_EQUAL");
        for (uint256 i = 0; i < len; i++) {
            _setUniswapSettingAndPrepareToken(_tokens[i], _pairs[i]);
            reApproveTokens[_tokens[i]] = _reapprove[i];
            emit SetTokenSetting(_tokens[i], _reapprove[i], _pairs[i]);
        }
    }

    function fetchUnswapPairsFromFactory(address _factory, address[] calldata _tokens) external onlyOwner {
        uint256 len = _tokens.length;
        for (uint256 i = 0; i < len; i++) {
            _setUniswapSettingAndPrepareToken(_tokens[i], IUniswapV2Factory(_factory).getPair(_tokens[i], address(weth)));
        }
    }
    
    function setDefaultSlippage(uint256 _defaultSlippage) external onlyOwner {
        defaultSlippage = _defaultSlippage;
        emit SetDefaultSlippage(_defaultSlippage);
    }

    // swap eth to luna fund tokens contain eth-twa lp, weth, uni, link, renBTC
    function swapEthToLuna(uint256 _slippage) public payable returns (uint256 poolAmountOut) {
        address[] memory tokens = lunaBP.getCurrentTokens();
        (, uint256[] memory ethInUniswap, ) = calcSwapEthToLunaInputs(msg.value, tokens, _slippage);
        weth.deposit{ value: msg.value }();
        poolAmountOut = _swapWethToLunaByEthIn(ethInUniswap);
        uint256 oddEth = _checkAndSendOddToken();

        emit EthToLunaSwap(msg.sender, bsub(msg.value, oddEth), poolAmountOut);
    }

    function swapErc20ToLuna(
        address _swapToken,
        uint256 _swapAmount,
        uint256 _slippage
    ) external returns (uint256 poolAmountOut) {
        TokenInterface(_swapToken).safeTransferFrom(msg.sender, address(this), _swapAmount);
        
        if (_swapToken == address(twa)) {
            address[] memory path = new address[](2);
            path[0] = address(twa);
            path[1] = address(weth);
            
            // try to get real twa amount becasue twa burned 1% every transfer
            uint256 twaAmount = twa.balanceOf(address(this));
            twa.approve(address(uniswapV2Router), twaAmount);
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                twaAmount,
                0, // accept any amount of pair token
                path,
                address(this),
                block.timestamp
            );
        } else {
            _swapTokenForWethOut(_swapToken, _swapAmount);
        }

        uint256 wethAmount = weth.balanceOf(address(this));
        uint256 ethAmount = address(this).balance;
        if (ethAmount > 0) {
            weth.deposit{ value: ethAmount }();
            wethAmount = badd(wethAmount, ethAmount);
        }
        address[] memory tokens = lunaBP.getCurrentTokens();
        uint256[] memory ethInUniswap;

        (, ethInUniswap, ) = calcSwapEthToLunaInputs(wethAmount, tokens, _slippage);
        poolAmountOut = _swapWethToLunaByEthIn(ethInUniswap);
        uint256 oddEth = _checkAndSendOddToken();

        emit Erc20ToLunaSwap(msg.sender, _swapToken, _swapAmount, bsub(wethAmount, oddEth), poolAmountOut);
    }

    function swapLunaToEth(uint256 _poolAmountIn) external returns (uint256 ethOutAmount) {
        _swapLunaToWeth(_poolAmountIn);
        uint256 wethAmount = weth.balanceOf(address(this));
        if (wethAmount > 0) {
            weth.withdraw(wethAmount);
        }
        ethOutAmount = address(this).balance;
        msg.sender.transfer(ethOutAmount);

        emit LunaToEthSwap(msg.sender, _poolAmountIn, ethOutAmount);
    }

    function swapLunaToErc20(
        address _swapToken,
        uint256 _poolAmountIn
    ) external returns (uint256 erc20Out) {
        _swapLunaToWeth(_poolAmountIn);
        uint256 ethAmount = address(this).balance;
        if (ethAmount > 0) {
            weth.deposit{ value: ethAmount }();
        }
        uint256 ethOut = weth.balanceOf(address(this));
        _swapWethForTokenOut(_swapToken, ethOut);
        erc20Out = TokenInterface(_swapToken).balanceOf(address(this));
        IERC20(_swapToken).safeTransfer(msg.sender, erc20Out);

        emit LunaToErc20Swap(msg.sender, _swapToken, _poolAmountIn, ethOut, erc20Out);
    }

    function calcNeedEthToPoolOut(uint256 _poolAmountOut, uint256 _slippage) public view returns (uint256 ethAmountIn) {
        uint256 ratio = bdiv(_poolAmountOut, lunaBP.totalSupply());

        address[] memory tokens = lunaBP.getCurrentTokens();
        uint256 len = tokens.length;
        uint256[] memory tokensInLuna = new uint256[](len);

        uint256 totalEthSwap = 0;
        for (uint256 i = 0; i < len; i++) {
            tokensInLuna[i] = bmul(ratio, lunaBP.getBalance(tokens[i]));
            if (tokens[i] == address(weth)) {
                totalEthSwap = badd(totalEthSwap, tokensInLuna[i]);
            } else {
                if (tokens[i] == address(univ2)) {
                    totalEthSwap = badd(totalEthSwap, calcEthReserveOutByLPIn(address(twa), tokensInLuna[i]));
                } else {
                    totalEthSwap = badd(totalEthSwap, getAmountInForUniswapValue(uniswapPairFor(tokens[i]), tokensInLuna[i], true));
                }
            }
        }
        uint256 slippageAmount = bmul(_slippage, totalEthSwap);
        ethAmountIn = badd(totalEthSwap, slippageAmount);
    }

    function calcNeedErc20ToPoolOut(
        address _swapToken,
        uint256 _poolAmountOut,
        uint256 _slippage
    ) external view returns (uint256) {
        uint256 resultEth = calcNeedEthToPoolOut(_poolAmountOut, _slippage);
        IUniswapV2Pair tokenPair = uniswapPairFor(_swapToken);
        (uint256 token1Reserve, uint256 token2Reserve, ) = tokenPair.getReserves();
        if (tokenPair.token0() == address(weth)) {
            return UniswapV2Library.getAmountIn(resultEth.mul(1003).div(1000), token2Reserve, token1Reserve);
        } else {
            return UniswapV2Library.getAmountIn(resultEth.mul(1003).div(1000), token1Reserve, token2Reserve);
        }
    }
    
    // swap eth to eth-twa lp, weth, uni, link, renBTC
    function calcSwapEthToLunaInputs(
        uint256 _ethValue,
        address[] memory _tokens,
        uint256 _slippage
    ) public view returns (uint256[] memory tokensInLuna, uint256[] memory ethInUniswap, uint256 poolOut) {
        uint256 slippageEth = bmul(_ethValue, _slippage);
        uint256 ethValue = bsub(_ethValue, slippageEth);

        uint256 totalNormalizedWeight = 0;
        for (uint256 i = 0; i < _tokens.length; i++) {
            totalNormalizedWeight = badd(totalNormalizedWeight, lunaBP.getNormalizedWeight(_tokens[i]));
        }
        
        tokensInLuna = new uint256[](_tokens.length);
        ethInUniswap = new uint256[](_tokens.length);

        uint256 baseTokenWeight = lunaBP.getNormalizedWeight(address(weth));
        uint256 baseTokenBalance = lunaBP.getBalance(address(weth));
        uint256 baseTokenAmount = bmul(ethValue, bdiv(baseTokenWeight, totalNormalizedWeight));
        uint256 poolRatio = bdiv(baseTokenAmount, baseTokenBalance);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address ithToken = _tokens[i];
            uint256 tokenWeight = lunaBP.getNormalizedWeight(ithToken);
            uint256 tokenBalance = lunaBP.getBalance(ithToken);

            tokensInLuna[i] = bmul(poolRatio, tokenBalance);
            ethInUniswap[i] = bmul(ethValue, bdiv(tokenWeight, totalNormalizedWeight));
        }

        poolOut = bmul(poolRatio, lunaBP.totalSupply());
    }

    function calcSwapErc20ToLunaInputs(
        address _swapToken,
        uint256 _swapAmount,
        address[] memory _tokens,
        uint256 _slippage
    ) external view returns (uint256[] memory tokensInLuna, uint256[] memory ethInUniswap, uint256 poolOut) {
        uint256 ethAmount = getAmountOutForUniswapValue(uniswapPairFor(_swapToken), _swapAmount, true);
        return calcSwapEthToLunaInputs(ethAmount, _tokens, _slippage);
    }

    function calcSwapLunaToEthInputs(
        uint256 _poolAmountIn,
        address[] memory _tokens
    ) public view returns (uint256[] memory tokensOutLuna, uint256[] memory ethOutUniswap, uint256 totalEthOut) {
        tokensOutLuna = new uint256[](_tokens.length);
        ethOutUniswap = new uint256[](_tokens.length);

        uint256 poolRatio = bdiv(_poolAmountIn, lunaBP.totalSupply());

        totalEthOut = 0;
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokensOutLuna[i] = bmul(poolRatio, lunaBP.getBalance(_tokens[i]));
            if (_tokens[i] == address(weth)) {
                ethOutUniswap[i] = tokensOutLuna[i];
            } else {
                if (_tokens[i] == address(univ2)) {
                   ethOutUniswap[i] = calcEthReserveOutByLPIn(address(twa), tokensOutLuna[i]);
                } else {
                    ethOutUniswap[i] = getAmountOutForUniswapValue(uniswapPairFor(_tokens[i]), tokensOutLuna[i], true);
                }
            }
            totalEthOut = badd(totalEthOut, ethOutUniswap[i]);
        }
    }

    function calcSwapLunaToErc20Inputs(
        address _swapToken,
        uint256 _poolAmountIn,
        address[] memory _tokens
    ) external view returns (uint256[] memory tokensOutLuna, uint256[] memory ethOutUniswap, uint256 totalErc20Out) {
        uint256 totalEthOut;

        (tokensOutLuna, ethOutUniswap, totalEthOut) = calcSwapLunaToEthInputs(_poolAmountIn, _tokens);
        (uint256 tokenReserve, uint256 ethReserve, ) = uniswapPairFor(_swapToken).getReserves();
        totalErc20Out = UniswapV2Library.getAmountOut(totalEthOut, ethReserve, tokenReserve);
    }

    function calcEthReserveOutByLPIn(address _token, uint256 lpAmountIn) public view returns(uint256) {
        uint256 lpTotalSupply = uniswapPairFor(_token).totalSupply();
        (, uint256 ethReserve, ) = uniswapPairFor(_token).getReserves();

        return ethReserve.mul(lpAmountIn).div(lpTotalSupply);
    }

    // swap weth to Luna tokens
    // Odd ether will return back to sender
    function _swapWethToLunaByEthIn(uint256[] memory _ethInUniswap) internal returns (uint256 poolAmountOut) {
        uint256[] memory tokensInLuna;
        (tokensInLuna, poolAmountOut) = _swapAndApproveTokensForJoin(_ethInUniswap);

        lunaBP.joinPool(poolAmountOut, tokensInLuna);
        lunaBP.safeTransfer(msg.sender, poolAmountOut);
    }

    function _checkAndSendOddToken() internal returns (uint256 oddEth) {
        address[] memory tokens = lunaBP.getCurrentTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] != address(weth)) {
                uint256 oddToken = TokenInterface(tokens[i]).balanceOf(address(this));
                if (oddToken > 0) {
                    TokenInterface(tokens[i]).transfer(msg.sender, oddToken);
                    emit OddToken(msg.sender, tokens[i], oddToken);
                }
            }
        }
        uint256 oddWeth = weth.balanceOf(address(this));
        if (oddWeth > 0) {
            weth.withdraw(oddWeth);
        }

        oddEth = address(this).balance;
        if (oddEth > 0) {
            msg.sender.transfer(oddEth);
            emit OddEth(msg.sender, oddEth);
        }
    }

    // prepare the joining to balancer pool
    function _swapAndApproveTokensForJoin(uint256[] memory ethInUniswap)
        internal
        returns (uint256[] memory tokensInLuna, uint256 poolAmountOut)
    {
        uint256 poolRatio = 0;
        address[] memory tokens = lunaBP.getCurrentTokens();
        tokensInLuna = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == address(weth)) {
                tokensInLuna[i] = ethInUniswap[i];
            } else if (tokens[i] == address(univ2)) {
                tokensInLuna[i] = buyTwaAndAddLiquidityToUniswapV2(ethInUniswap[i]);
            } else {
                _swapWethForTokenOut(tokens[i], ethInUniswap[i]);
                tokensInLuna[i] = TokenInterface(tokens[i]).balanceOf(address(this));
            }
            
            uint256 tokenBalance = lunaBP.getBalance(tokens[i]);
            uint256 minRatio = bdiv(tokensInLuna[i], tokenBalance);

            if (poolRatio == 0 || poolRatio > minRatio) {
                poolRatio = minRatio;
            }
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            tokensInLuna[i] = bmul(poolRatio, lunaBP.getBalance(tokens[i]));

            if (reApproveTokens[tokens[i]]) {
                TokenInterface(tokens[i]).approve(address(lunaBP), 0);
            }
            TokenInterface(tokens[i]).approve(address(lunaBP), tokensInLuna[i]);
        }

        poolAmountOut = bmul(bsub(poolRatio, 1e3), lunaBP.totalSupply());
    }

    function buyTwaAndAddLiquidityToUniswapV2(uint256 _ethAmountIn) public returns (uint256 liquidity) {
        uint256 ethAmountForSwap = bdiv(_ethAmountIn, 2 ether);

        _swapWethForTokenOut(address(twa), ethAmountForSwap);
        uint256 twaTokenAmount = twa.balanceOf(address(this));

        uint256 ethAmountForAddLiquidity = getAmountInForUniswapValue(uniswapPairFor(address(twa)), twaTokenAmount, true);
        weth.withdraw(ethAmountForAddLiquidity);

        // add liquidity to uniswap
        twa.approve(address(uniswapV2Router), twaTokenAmount);
        uint256 ethAmountOut = 0;
        uint256 tokenAmountOut = 0;
        (tokenAmountOut, ethAmountOut, liquidity) = uniswapV2Router.addLiquidityETH{ value: ethAmountForAddLiquidity } (
            address(twa),
            twaTokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
        if (ethAmountForAddLiquidity > ethAmountOut) {
            weth.deposit{ value: bsub(ethAmountForAddLiquidity, ethAmountOut) }();
        }

        emit BuyTwaAndAddLiquidityToUniswapV2(_msgSender(), _ethAmountIn, ethAmountOut, tokenAmountOut);
    }
    
    function _swapLunaToWeth(uint256 _poolAmountIn) internal {
        address[] memory tokens = lunaBP.getCurrentTokens();
        uint256 len = tokens.length;

        (uint256[] memory tokensOutLuna, ,) = calcSwapLunaToEthInputs(_poolAmountIn, tokens);

        lunaBP.safeTransferFrom(msg.sender, address(this), _poolAmountIn);
        lunaBP.approve(address(lunaBP), _poolAmountIn);
        lunaBP.exitPool(_poolAmountIn, tokensOutLuna);

        for (uint256 i = 0; i < len; i++) {
            if (tokens[i] == address(univ2)) {
                tokensOutLuna[i] = univ2.balanceOf(address(this));
                univ2.approve(address(uniswapV2Router), tokensOutLuna[i]);
                uniswapV2Router.removeLiquidityETHSupportingFeeOnTransferTokens(
                    address(twa),
                    tokensOutLuna[i],
                    0,
                    0,
                    address(this),
                    block.timestamp
                );

                uint256 twaBalance = twa.balanceOf(address(this));
                if (twaBalance > 0) {
                    address[] memory path = new address[](2);
                    path[0] = address(twa);
                    path[1] = address(weth);

                    twa.approve(address(uniswapV2Router), twaBalance);
                    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                        twaBalance,
                        0, // accept any amount of pair token
                        path,
                        msg.sender,
                        block.timestamp
                    );
                }
            } else {
                if (tokens[i] != address(weth)) {
                    tokensOutLuna[i] = TokenInterface(tokens[i]).balanceOf(address(this));
                    _swapTokenForWethOut(tokens[i], tokensOutLuna[i]);
                }
            }
        }
    }

    function getAmountInForUniswap(
        IUniswapV2Pair _tokenPair,
        uint256 _swapAmount,
        bool _isEthIn
    ) public view returns (uint256 amountIn, bool isInverse) {
        isInverse = uniswapEthPairToken0[address(_tokenPair)] == address(weth);
        if (_isEthIn ? !isInverse : isInverse) {
            (uint256 ethReserve, uint256 tokenReserve, ) = _tokenPair.getReserves();
            amountIn = UniswapV2Library.getAmountIn(_swapAmount, tokenReserve, ethReserve);
        } else {
            (uint256 tokenReserve, uint256 ethReserve, ) = _tokenPair.getReserves();
            amountIn = UniswapV2Library.getAmountIn(_swapAmount, tokenReserve, ethReserve);
        }
    }

    function getAmountInForUniswapValue(
        IUniswapV2Pair _tokenPair,
        uint256 _swapAmount,
        bool _isEthIn
    ) public view returns (uint256 amountIn) {
        (amountIn, ) = getAmountInForUniswap(_tokenPair, _swapAmount, _isEthIn);
    }

    function getAmountOutForUniswap(
        IUniswapV2Pair _tokenPair,
        uint256 _swapAmount,
        bool _isEthOut
    ) public view returns (uint256 amountOut, bool isInverse) {
        isInverse = uniswapEthPairToken0[address(_tokenPair)] == address(weth);
        if (_isEthOut ? isInverse : !isInverse) {
            (uint256 ethReserve, uint256 tokenReserve, ) = _tokenPair.getReserves();
            amountOut = UniswapV2Library.getAmountOut(_swapAmount, tokenReserve, ethReserve);
        } else {
            (uint256 tokenReserve, uint256 ethReserve, ) = _tokenPair.getReserves();
            amountOut = UniswapV2Library.getAmountOut(_swapAmount, tokenReserve, ethReserve);
        }
    }

    function getAmountOutForUniswapValue(
        IUniswapV2Pair _tokenPair,
        uint256 _swapAmount,
        bool _isEthOut
    ) public view returns (uint256 ethAmount) {
        (ethAmount, ) = getAmountOutForUniswap(_tokenPair, _swapAmount, _isEthOut);
    }

    function _setUniswapSettingAndPrepareToken(address _token, address _pair) internal {
        uniswapEthPairByTokenAddress[_token] = _pair;
        uniswapEthPairToken0[_pair] = IUniswapV2Pair(_pair).token0();
    }

    function uniswapPairFor(address token) public view returns (IUniswapV2Pair) {
        return IUniswapV2Pair(uniswapEthPairByTokenAddress[token]);
    }

    function _swapWethForTokenIn(address _erc20, uint256 _erc20Out) internal returns (uint256 ethIn) {
        IUniswapV2Pair tokenPair = uniswapPairFor(_erc20);
        bool isInverse;
        (ethIn, isInverse) = getAmountInForUniswap(tokenPair, _erc20Out, true);
        weth.safeTransfer(address(tokenPair), ethIn);
        tokenPair.swap(isInverse ? uint256(0) : _erc20Out, isInverse ? _erc20Out : uint256(0), address(this), new bytes(0));
    }

    function _swapWethForTokenOut(address _erc20, uint256 _ethIn) internal returns (uint256 erc20Out) {
        IUniswapV2Pair tokenPair = uniswapPairFor(_erc20);
        bool isInverse;
        (erc20Out, isInverse) = getAmountOutForUniswap(tokenPair, _ethIn, false);
        weth.safeTransfer(address(tokenPair), _ethIn);
        tokenPair.swap(isInverse ? uint256(0) : erc20Out, isInverse ? erc20Out : uint256(0), address(this), new bytes(0));
    }

    function _swapTokenForWethOut(address _erc20, uint256 _erc20In) public returns (uint256 ethOut) {
        IUniswapV2Pair tokenPair = uniswapPairFor(_erc20);
        bool isInverse;
        (ethOut, isInverse) = getAmountOutForUniswap(tokenPair, _erc20In, true);
        IERC20(_erc20).safeTransfer(address(tokenPair), _erc20In);
        tokenPair.swap(isInverse ? ethOut : uint256(0), isInverse ? uint256(0) : ethOut, address(this), new bytes(0));
    }
}