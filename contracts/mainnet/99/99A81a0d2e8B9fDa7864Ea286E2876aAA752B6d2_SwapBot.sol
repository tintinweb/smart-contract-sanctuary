/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _dev;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _dev = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function dev() public view returns (address) {
        return _dev;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyDev() {
        require(_dev == _msgSender(), "Ownable: caller is not the dev");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferDevship(address newDev) public virtual onlyDev {
        require(newDev != address(0), "Ownable: new dev is the zero address");
        _dev = newDev;
    }
}

library SafeMathUniswap {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

library UniswapV2Library {
    using SafeMathUniswap for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) =
            IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);
}

interface IUniswapV2Pair {
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

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
}

interface TokenInterface is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract SwapBot is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for TokenInterface;

    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    TokenInterface private _weth;

    IUniswapV2Router02[] public _routers;
    IUniswapV2Factory[] public _factories;
    address[] private _runners;

    struct Root {
        uint8[] routerIds;
        address[] inTokens;
        uint256 startAmount;
        uint256 estimateProfit;
        uint256 chiAmount;
    }

    struct PairInfo {
        IUniswapV2Pair pair;
        uint256 outputAmount;
        bool isReserveIn;
    }

    modifier onlyRunner() {
        (bool exist, ) = checkRunner(_msgSender());
        require(exist, "caller is not the runner");
        _;
    }

    modifier discountCHI(uint256 chiAmount) {
        if (chiAmount > 0) {
            uint256 gasStart = gasleft();
            _;
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            chi.freeFromUpTo(_msgSender(), Math.min((gasSpent + 14154) / 41947, chiAmount));
        } else {
            _;
        }
    }

    constructor() {
        _weth = TokenInterface(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
        IUniswapV2Router02 sushiswapV2Router = IUniswapV2Router02(address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F));

        _routers.push(uniswapV2Router);
        _routers.push(sushiswapV2Router);

        _factories.push(IUniswapV2Factory(uniswapV2Router.factory()));
        _factories.push(IUniswapV2Factory(sushiswapV2Router.factory()));

        _runners.push(_msgSender());
    }

    receive() external payable {
    }

    function deposit(uint256 depositAmount) public onlyDev {
        _weth.deposit{value: depositAmount}();
    }

    function runnerLength() public view returns (uint8) {
        return uint8(_runners.length);
    }
    
    function checkRunner(address runner)
        public
        view
        returns (bool exist, uint8 index)
    {
        uint8 length = runnerLength();
        exist = false;
        for (uint8 i = 0; i < length; i++) {
            if (_runners[i] == runner) {
                exist = true;
                index = i;
                break;
            }
        }
    }

    function addRunner(address runner) external onlyDev {
        require(runner != address(0), "Invalid runner address.");

        _runners.push(address(runner));
    }

    function withdrawProfit(address withdrawAddress, uint256 withdrawAmount)
        public
        onlyOwner
        returns (bool sent)
    {
        uint256 balance = _weth.balanceOf(address(this));
        require(balance > withdrawAmount, "Invalid Withdraw Amount");

        _weth.withdraw(withdrawAmount);
        (sent, ) = withdrawAddress.call{value: withdrawAmount}("");
        require(sent, "Invalid withdraw ETH");
    }

    function emergencyWithdraw(address withdrawAddress) 
        public
        onlyDev
        returns (bool sent)
    {
        uint256 withdrawAmount = _weth.balanceOf(address(this));
        _weth.withdraw(withdrawAmount);
        uint256 ethAmount = address(this).balance;
        (sent, ) = withdrawAddress.call{value: ethAmount}("");
        require(sent, "Invalid withdraw ETH");
    }

    function checkEstimatedProfit(
        uint8[] memory routerIds,
        uint256 startAmount,
        address[] memory inTokens
    ) 
        public 
        view 
        returns (
            uint256,
            PairInfo[] memory
        )
    {
        uint256 len = inTokens.length;
        uint256 amountIn = startAmount;
        bool isReserveIn;
        PairInfo[] memory pairList = new PairInfo[](len - 1);


        for (uint256 i = 0; i < len - 1; i++) {
            IUniswapV2Factory factory = _factories[routerIds[i]];

            IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(inTokens[i], inTokens[i + 1]));

            (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

            isReserveIn = pair.token0() == inTokens[i] ? true : false;

            amountIn = UniswapV2Library.getAmountOut(
                amountIn,
                isReserveIn ? reserve0 : reserve1,
                !isReserveIn ? reserve0 : reserve1
            );

            pairList[i] = PairInfo(
                pair,
                amountIn,
                isReserveIn
            );
        }

        uint256 profit = amountIn <= startAmount ? 0 : amountIn.sub(startAmount);
        return (profit, pairList);
    }

    function run(
        Root memory router
    ) public onlyRunner discountCHI(router.chiAmount) {
        (uint256 estimateProfit, PairInfo[] memory pairList)
            = checkEstimatedProfit(router.routerIds, router.startAmount, router.inTokens);

        if (estimateProfit < router.estimateProfit) {
            return;
        }

        uint256 len = router.inTokens.length;
        uint256 amountIn = router.startAmount;

        for (uint256 i = 0; i < len - 1; i++) {
            amountIn = _swapTokenToToken(
                amountIn,
                router.inTokens[i],
                router.inTokens[i + 1],
                pairList[i]
            );
        }
        return;
    }

    function bulkRun(Root[] memory roots)
        external
        onlyRunner
        returns (bool)
    {
        uint256 length = roots.length;

        uint256 maxProfit = 0;
        uint256 goalRoot = 0;
        for (uint256 i = 0; i < length; i++) {
            Root memory root = roots[i];

            (uint256 profit, ) = checkEstimatedProfit(
                root.routerIds,
                root.startAmount,
                root.inTokens
            );

            if (profit > maxProfit) {
                maxProfit = profit;
                goalRoot = i;
            }
        }

        if (maxProfit > 0) {
            Root memory root = roots[goalRoot];
            run(root);
        }

        return true;
    }

    function _swapTokenToToken(
        uint256 tokenInAmount,
        address inToken,
        address outToken,
        PairInfo memory pairInfo
    ) private returns (uint256 amountOut) {
        uint256 oldTokenOutAmount = TokenInterface(outToken).balanceOf(address(this));

        TokenInterface(inToken).safeTransfer(address(pairInfo.pair), tokenInAmount);
        _swapSupportingFeeOnTransferTokens(
            pairInfo
        );
        
        uint256 newTokenOutAmount = TokenInterface(outToken).balanceOf(address(this));
        amountOut = newTokenOutAmount.sub(oldTokenOutAmount);
    }

    function _swapSupportingFeeOnTransferTokens(
        PairInfo memory pairInfo
    ) internal virtual {
        (uint256 amount0Out, uint256 amount1Out) =
            pairInfo.isReserveIn
                ? (uint256(0), pairInfo.outputAmount)
                : (pairInfo.outputAmount, uint256(0));

        pairInfo.pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
    }
}