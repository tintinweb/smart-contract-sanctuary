/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

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

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
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

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) =
                getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) =
                getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

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

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

contract SwapBot is Ownable {
    using SafeMath for uint256;

    // States
    address private _dev;
    uint16 private _devFee;

    TokenInterface private _weth;

    address[] public _routers;
    address[] private _runners;

    struct Root {
        uint8[] routerIds;
        address[] inTokens;
        uint256 startAmount;
    }

    modifier onlyRunner() {
        (bool exist, ) = checkRunner(_msgSender());
        require(exist, "caller is not the runner");
        _;
    }

    event BadRoots(uint256 startAmount);
    event BadRoot(
        address indexed startToken,
        address indexed endToken,
        uint256 startAmount
    );
    event GoldRoot(
        address indexed startToken,
        address indexed endToken,
        uint256 startAmount
    );
    event TestRun(
        uint8 routerId,
        address inToken,
        address outToken,
        uint256 expectedOutAmount,
        uint256 realAmountOut
    );

    constructor() {
        _dev = _msgSender();
        _weth = TokenInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        _routers.push(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
        _routers.push(address(0x027Bb5f9205360aC628C33508c3f182320A44525));

        _runners.push(_msgSender());

        _devFee = 4000; // dev fee is 40%, must be divided by 10,000 when calculating
    }

    receive() external payable {}

    function routerLength() public view returns (uint8) {
        return uint8(_routers.length);
    }

    function checkRouter(address routerAddress)
        public
        view
        returns (bool exist, uint8 index)
    {
        uint8 length = routerLength();
        exist = false;
        for (uint8 i = 0; i < length; i++) {
            if (_routers[i] == routerAddress) {
                exist = true;
                index = i;
                break;
            }
        }
    }

    function addRouter(address routerAddress) external onlyDev {
        (bool exist, ) = checkRouter(routerAddress);
        require(!exist, "This router address already exists.");
        require(routerAddress != address(0), "Invalid router address.");

        _routers.push(address(routerAddress));
    }

    function setRouter(uint8 index, address routerAddress) external onlyDev {
        uint8 length = routerLength();
        require(index < length, "Invalid index of router");
        require(routerAddress != address(0), "Invalid router address.");

        _routers[index] = routerAddress;
    }

    function removeRouter(address routerAddress) external onlyDev {
        require(routerAddress != address(0), "Invalid router address.");

        uint8 length = routerLength();
        for (uint8 i = 0; i < length; i++) {
            if (_routers[i] == routerAddress) {
                _routers[i] = address(0);
                break;
            }
        }
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
        (bool exist, ) = checkRunner(runner);
        require(!exist, "This runner address already exists.");
        require(runner != address(0), "Invalid runner address.");

        _runners.push(address(runner));
    }

    function setRunners(uint8 index, address runner) external onlyDev {
        uint8 length = runnerLength();
        require(index < length, "Invalid index of runner");
        require(runner != address(0), "Invalid runner address.");

        _runners[index] = runner;
    }

    function removeRunner(address runner) external onlyDev {
        require(runner != address(0), "Invalid runner address.");

        uint8 length = runnerLength();
        for (uint8 i = 0; i < length; i++) {
            if (_runners[i] == runner) {
                _runners[i] = address(0);
                break;
            }
        }
    }

    function setDevFee(uint16 fee) external onlyOwner {
        _devFee = fee;
    }

    function setDevAddress(address dev) external onlyDev {
        _dev = dev;
    }

    function withdrawProfitOwner(address owner, uint256 amountForOwner)
        external
        onlyOwner
        returns (bool sent)
    {
        if (owner != address(0) && amountForOwner > 0) {
            (sent, ) = owner.call{value: amountForOwner}("");
        }
    }

    function withdrawProfitDev(address dev, uint256 amountForDev)
        external
        onlyDev
        returns (bool sent)
    {
        if (dev != address(0) && amountForDev > 0) {
            (sent, ) = dev.call{value: amountForDev}("");
        }
    }

    function emergencyWithraw() external onlyOwner {
        require(_msgSender() != address(0), "Invalid dev");
        msg.sender.transfer(address(this).balance);
    }

    function removeOddTokens(address[] memory tokens, address to)
        external
        onlyOwner
        returns (bool)
    {
        require(to != address(0), "Invalid address to send odd tokens");
        uint256 len = tokens.length;

        for (uint256 i = 0; i < len; i++) {
            uint256 balance =
                TokenInterface(tokens[i]).balanceOf(address(this));
            if (balance > 0) {
                if (tokens[i] == address(_weth)) {
                    _weth.withdraw(balance);
                    (bool sent, ) = to.call{value: balance}("");
                    require(sent, "Failed to send ether");
                } else {
                    TokenInterface(tokens[i]).transfer(to, balance);
                }
            }
        }

        return true;
    }

    function checkEstimatedProfit(
        uint8[] memory routerIds,
        uint256 startAmount,
        address[] memory inTokens
    ) public view returns (uint256 profit, uint256 endAmount) {
        require(routerIds.length > 1, "Est: Invalid router id array.");
        require(inTokens.length > 1, "Est: Invalid token array.");
        require(
            routerIds.length + 1 == inTokens.length,
            "Est: Rotuers and tokens must have same length."
        );

        uint256 len = inTokens.length;
        uint256 amountIn = startAmount;

        for (uint256 i = 0; i < len - 1; i++) {
            IUniswapV2Router02 router =
                IUniswapV2Router02(_routers[routerIds[i]]);
            IUniswapV2Factory factory = IUniswapV2Factory(router.factory());

            address inToken = inTokens[i];
            address outToken = inTokens[i + 1];

            IUniswapV2Pair pair =
                IUniswapV2Pair(factory.getPair(inToken, outToken));

            (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

            if (pair.token0() == inToken) {
                amountIn = UniswapV2Library.getAmountOut(
                    amountIn,
                    reserve0,
                    reserve1
                );
            } else {
                amountIn = UniswapV2Library.getAmountOut(
                    amountIn,
                    reserve1,
                    reserve0
                );
            }
        }

        profit = amountIn <= startAmount ? 0 : amountIn.sub(startAmount);
        endAmount = amountIn;
    }

    function testCheckEstimatedOutPut(
        uint8 routerId,
        uint256 amountIn,
        address inToken,
        address outToken
    ) public view returns (uint256 outAmount) {
        IUniswapV2Router02 router = IUniswapV2Router02(_routers[routerId]);
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        IUniswapV2Pair pair =
            IUniswapV2Pair(factory.getPair(inToken, outToken));

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        if (pair.token0() == inToken) {
            outAmount = UniswapV2Library.getAmountOut(
                amountIn,
                reserve0,
                reserve1
            );
        } else {
            outAmount = UniswapV2Library.getAmountOut(
                amountIn,
                reserve1,
                reserve0
            );
        }
    }

    function run(
        uint8[] memory routerIds,
        address[] memory inTokens,
        uint256 startAmount,
        bool isSendProfit
    ) public onlyRunner {
        require(routerIds.length > 1, "Run: Invalid router id array.");
        require(inTokens.length > 1, "Run: Invalid token array.");
        require(
            routerIds.length +1 == inTokens.length,
            "Run: Rotuers and tokens must have same length."
        );

        TokenInterface startToken = TokenInterface(inTokens[0]);
        uint256 balanceForStartToken;
        uint256 newBalanceForStartToken;

        if (address(startToken) != address(_weth)) {
            balanceForStartToken = startToken.balanceOf(address(this));
        } else {
            balanceForStartToken = address(this).balance;
        }

        require(
            balanceForStartToken > 0 && balanceForStartToken >= startAmount,
            "run: Invalid swap amount"
        );

        (uint256 profit, ) =
            checkEstimatedProfit(routerIds, startAmount, inTokens);
        require(profit > 0, "run: There is no profit");

        uint256 len = inTokens.length;
        uint256 amountIn = startAmount;

        for (uint256 i = 0; i < len - 1; i++) {
            IUniswapV2Router02 iRouter =
                IUniswapV2Router02(_routers[routerIds[i]]);
            address inToken = inTokens[i];
            address outToken = inTokens[i + 1];

            if (inToken == address(_weth)) {
                amountIn = _swapEthToToken(iRouter, amountIn, outToken);
            } else if (outToken == address(_weth)) {
                amountIn = _swapTokenToEth(iRouter, amountIn, inToken);
            } else {
                amountIn = _swapTokenToToken(
                    iRouter,
                    amountIn,
                    inToken,
                    outToken
                );
            }
        }

        if (address(startToken) != address(_weth)) {
            newBalanceForStartToken = startToken.balanceOf(address(this));
        } else {
            newBalanceForStartToken = address(this).balance;
        }

        profit = newBalanceForStartToken.sub(balanceForStartToken);

        if (isSendProfit) {
            _sendProfit(startToken, profit);
        }
    }

    function bulkRun(Root[] memory roots, bool isSendProfit)
        external
        onlyRunner
        returns (bool)
    {
        uint256 length = roots.length;
        require(length > 0, "Invalid root data");

        uint256 maxProfit = 0;
        uint256 goalRoot = 0;
        for (uint256 i = 0; i < length; i++) {
            Root memory root = roots[i];

            (uint256 profit, ) =
                checkEstimatedProfit(
                    root.routerIds,
                    root.startAmount,
                    root.inTokens
                );

            uint256 len = root.inTokens.length;

            if (profit > 0) {
                emit GoldRoot(
                    root.inTokens[0],
                    root.inTokens[len - 1],
                    root.startAmount
                );
            } else {
                emit BadRoot(
                    root.inTokens[0],
                    root.inTokens[len - 1],
                    root.startAmount
                );
            }

            if (profit > maxProfit) {
                maxProfit = profit;
                goalRoot = i;
            }
        }

        if (maxProfit > 0) {
            Root memory root = roots[goalRoot];
            uint256 len = root.inTokens.length;
            run(root.routerIds, root.inTokens, root.startAmount, isSendProfit);
            emit GoldRoot(
                root.inTokens[0],
                root.inTokens[len - 1],
                root.startAmount
            );
        } else {
            emit BadRoots(roots[0].startAmount);
        }

        return true;
    }

    function testRun(
        uint8[] memory routerIds,
        address[] memory inTokens,
        uint8[] memory percents,
        uint256 startAmount
    ) public onlyRunner {
        require(routerIds.length > 1, "Run: Invalid router id array.");
        require(inTokens.length > 1, "Run: Invalid token array.");
        require(
            routerIds.length +1 == inTokens.length,
            "Run: Rotuers and tokens must have same length."
        );

        TokenInterface startToken = TokenInterface(inTokens[0]);
        uint256 balanceForStartToken;

        if (address(startToken) != address(_weth)) {
            balanceForStartToken = startToken.balanceOf(address(this));
        } else {
            balanceForStartToken = address(this).balance;
        }

        require(
            balanceForStartToken > 0 && balanceForStartToken >= startAmount,
            "run: Invalid swap amount"
        );

        uint256 len = inTokens.length;
        uint256 amountIn = startAmount;

        for (uint256 i = 0; i < len - 1; i++) {
            IUniswapV2Router02 iRouter =
                IUniswapV2Router02(_routers[routerIds[i]]);
            address inToken = inTokens[i];
            address outToken = inTokens[i + 1];

            uint256 expectedOutAmount =
                testCheckEstimatedOutPut(
                    routerIds[i],
                    amountIn,
                    inToken,
                    outToken
                );

            if (inToken == address(_weth)) {
                amountIn = _swapEthToToken(iRouter, amountIn, outToken);
            } else if (outToken == address(_weth)) {
                amountIn = _swapTokenToEth(iRouter, amountIn, inToken);
            } else {
                amountIn = _swapTokenToToken(
                    iRouter,
                    amountIn,
                    inToken,
                    outToken
                );
            }

            // check percentage
            uint8 percent = uint8(amountIn.mul(100).div(expectedOutAmount));

            if (percent < percents[i]) {
                emit TestRun(
                    routerIds[i],
                    inToken,
                    outToken,
                    expectedOutAmount,
                    amountIn
                );
            }
        }

        revert();
    }

    function _swapEthToToken(
        IUniswapV2Router02 router,
        uint256 ethAmount,
        address token
    ) private returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = token;

        uint256 oldBalance = TokenInterface(token).balanceOf(address(this));

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: ethAmount
        }(0, path, address(this), block.timestamp);

        amountOut = TokenInterface(token).balanceOf(address(this)).sub(
            oldBalance
        );
    }

    function _swapTokenToEth(
        IUniswapV2Router02 router,
        uint256 tokenAmount,
        address token
    ) private returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();

        TokenInterface(token).approve(address(router), tokenAmount);
        uint256 oldEthAmount = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 newEthAmount = address(this).balance;
        amountOut = newEthAmount.sub(oldEthAmount);
    }

    function _swapTokenToToken(
        IUniswapV2Router02 router,
        uint256 tokenInAmount,
        address tokenIn,
        address tokenOut
    ) private returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256 oldTokenOutAmount =
            TokenInterface(tokenOut).balanceOf(address(this));

        TokenInterface(tokenIn).approve(address(router), tokenInAmount);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenInAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 newTokenOutAmount =
            TokenInterface(tokenOut).balanceOf(address(this));
        amountOut = newTokenOutAmount.sub(oldTokenOutAmount);
    }

    function _sendProfit(TokenInterface token, uint256 amount)
        private
        returns (bool sent)
    {
        uint256 devAmount = amount.mul(_devFee).div(10000);

        if (address(token) == address(_weth)) {
            (sent, ) = _dev.call{value: devAmount}("");
            require(sent, "Failed to send Ether");
            (sent, ) = owner().call{value: amount.sub(devAmount)}("");
            require(sent, "Failed to send Ether");
        } else {
            token.transfer(_dev, devAmount);
            token.transfer(owner(), amount.sub(devAmount));
        }
    }
}