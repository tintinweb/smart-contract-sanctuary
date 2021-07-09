/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-28
*/

// SPDX-License-Identifier: Apache License 2.0
// Written by @zippet

/*

$$\   $$\                                         $$$$$$$\
$$$\  $$ |                                        $$  __$$\
$$$$\ $$ | $$$$$$\ $$\    $$\  $$$$$$\   $$$$$$\  $$ |  $$ | $$$$$$\   $$$$$$\   $$$$$$\
$$ $$\$$ |$$  __$$\\$$\  $$  |$$  __$$\ $$  __$$\ $$ |  $$ |$$  __$$\ $$  __$$\ $$  __$$\
$$ \$$$$ |$$$$$$$$ |\$$\$$  / $$$$$$$$ |$$ |  \__|$$ |  $$ |$$ |  \__|$$ /  $$ |$$ /  $$ |
$$ |\$$$ |$$   ____| \$$$  /  $$   ____|$$ |      $$ |  $$ |$$ |      $$ |  $$ |$$ |  $$ |
$$ | \$$ |\$$$$$$$\   \$  /   \$$$$$$$\ $$ |      $$$$$$$  |$$ |      \$$$$$$  |$$$$$$$  |
\__|  \__| \_______|   \_/     \_______|\__|      \_______/ \__|       \______/ $$  ____/
                                                                                $$ |
                                                                                $$ |
                                                                                \__|

• Automated Price Impact Based Buy-Backs

• Auto LP

• Hyperdeflationary

Tokenomics:

• Total Supply: 1,000,000,000,000,000 ND

• Pancakeswap Liquidity : 250,000,000,000,000 ND

• Presale : 250,000,000,000,000 ND

• Burned: 500,000,000,000,000 ND

• Liquidity Locked

Taxes:

NeverDrop features a 10% buy and sell tax.
• 8% goes towards liquidity (5% to BNB pool to buyback tokens, 3% towards Auto-LP)

• 1% goes towards marketing to ensure continuous advertising

• 1% is redistributed to holders

NeverDrop is the first ever cryptocurrency to feature an automatic price impact trigger that routinely repurchases
tokens to prevent mass sell-offs that cause large price drops. Serving as a hyper-deflationary token on the Binance
Smart Chain, NeverDrop rewards investors for holding tokens while leveraging its proprietary buy-back system.

We identified several major red flags in the code of similar tokens. Most glaringly, they are controlled manually which
leads to the ability of devs to create synthetic price spikes to take advantage of with their large team wallets.
We don’t hold team tokens, and we don’t believe in dishonest control of mechanics. That’s why we’ve automated our
mechanics so that the contract triggers its functions to the benefit of the entire community!

📢 Telegram: https://t.me/neverdrop
🌐 Website: https://www.neverdrop.io/
🐦 Twitter: https://twitter.com/neverdroptoken

*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

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

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

contract NeverDrop is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address payable public marketingAddress; // Marketing Address
    address payable public immutable deadAddress = payable(0x000000000000000000000000000000000000dEaD);

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxTx;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "NeverDrop";
    string private _symbol = "ND";
    uint8 private _decimals = 9;

    // tax = 1%
    // dev = 1%
    // liquidity = 8%

    uint256 public _taxFee = 1;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _marketingFee = 1;
    uint256 private _previousMarketingFee = _taxFee;

    uint256 public _liquidityFee = 8;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public percentOfSwapIsLP = 37;

    uint256 public _maxTxAmount = _tTotal.div(50);
    uint256 private minimumTokensBeforeSwap = _tTotal.div(2000);

    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV2Factory public immutable uniswapV2Factory;
    IUniswapV2Pair public immutable _uniswapV2Pair;
    address public immutable uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    uint256 private buybackTriggerViewerTimer = 0;
    uint256 private buybackTriggerViewerWindow = 1 minutes;
    bool private buyBackTriggered = false;
    uint256 private buybackEndTime;

    int256 private cumulativePriceImpact;

    uint256 private buybackCurrentWindow = 0;
    uint256 private buybackWindow = 30;
    uint256 private minBuybackWindow = 15;
    uint256 private maxBuybackWindow = 50;

    // -8.00% will trigger buyback
    int256 private priceImpactTriggerBuybackThreshold = -800;
    // Multiplier for buyback multiplier
    // Gets divided by 100 so 150/100 = x1.5
    uint256 private buybackImpactMultiplier = 150;
    // Ex: 1010 = 10.10% (last two digits are decimal) = 0.1%
    uint256 private minBuybackImpactPercent = 10;
    // Ex: 2456 = 24.56% (last two digits are decimal) = 5%
    uint256 private maxBuybackImpactPercent = 500;

    uint256 private minBuybackTime = 5 minutes;
    uint256 private maxBuybackTime = 15 minutes;

    uint256 private minBNBBalanceBuyback = 20 ether;

    // 0.1BNB
    uint256 private minBNBAmountBuyback = 0.1 ether;

    event RewardLiquidityProviders(uint256 tokenAmount);

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    // Written by @zippet
    constructor () {
        _rOwned[_msgSender()] = _rTotal;

        // Mainnet
        IUniswapV2Router02 tempRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // Testnet
        //IUniswapV2Router02 tempRouter = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

        uniswapV2Router = tempRouter;

        IUniswapV2Factory tempFactory = IUniswapV2Factory(tempRouter.factory());
        uniswapV2Factory = tempFactory;

        address tempPair = tempFactory.createPair(address(this), tempRouter.WETH());
        uniswapV2Pair = tempPair;

        _uniswapV2Pair = IUniswapV2Pair(tempPair);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;

        marketingAddress = payable(owner());

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(from != owner() && to != owner() && !_isExcludedFromMaxTx[to] && !_isExcludedFromMaxTx[from]) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool shouldSell = contractTokenBalance >= minimumTokensBeforeSwap;

        if (shouldSell && !inSwapAndLiquify && to == uniswapV2Pair && swapAndLiquifyEnabled &&
        !(from == address(this) && to == uniswapV2Pair)) {
            contractTokenBalance = minimumTokensBeforeSwap;

            // swap and liquify
            swapAndLiquify(contractTokenBalance);
        }

        // Makes sure it is not wallet to wallet transfers
        bool buybackReceiverGood = (from == uniswapV2Pair || to == uniswapV2Pair);

        if (!inSwapAndLiquify && swapAndLiquifyEnabled && buybackReceiverGood &&
        !(from == address(this) && to == uniswapV2Pair)) { // Extra recursion protection. Most likely repetitive but tight timeline :(
            buyBackTokens(from, amount);
        }

        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap { // 100
        uint256 autoLpAmount = contractTokenBalance.mul(percentOfSwapIsLP).div(100); // 40

        // Halfs for auto lp
        uint256 half = autoLpAmount.div(2); // 20
        uint256 otherHalf = autoLpAmount.sub(half); // To be converted to BNB 20

        uint256 amountForBuyback = contractTokenBalance.sub(half).sub(otherHalf); // Could also do sub(autoLpAmount) but meh I've tested this already

        uint256 tokenAmountToBeSwapped = amountForBuyback.add(otherHalf); // 20 + 60 = 80

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(tokenAmountToBeSwapped);

        uint256 deltaBalance = address(this).balance.sub(initialBalance);

        uint256 lpBNBRatio = otherHalf.mul(100).div(tokenAmountToBeSwapped); // 20 * 100 / 80 = 25

        uint256 bnbToBeAddedToLiquidity = deltaBalance.mul(lpBNBRatio).div(100);

        // add liquidity to pancake
        addLiquidity(half, bnbToBeAddedToLiquidity);

        emit SwapAndLiquify(half, bnbToBeAddedToLiquidity, otherHalf);
    }

    function randomGenerator(uint256 lower, uint256 upper) private returns(uint256) {
        uint256 randomNumber = (block.timestamp).mod(upper - lower) + lower;

        return randomNumber;
    }

    function resetBuyback() private {
        buyBackTriggered = false;
        buybackCurrentWindow = 0; // Time for buyback window
        cumulativePriceImpact = 0;
        buybackWindow = randomGenerator(minBuybackWindow, maxBuybackWindow);
    }

    function startBuyback() private {
        buyBackTriggered = true;
        cumulativePriceImpact = 0;
        buybackTriggerViewerTimer = block.timestamp + buybackTriggerViewerWindow;
        buybackEndTime = block.timestamp + randomGenerator(minBuybackTime, maxBuybackTime);
    }

    function performBuyback(uint256 priceImpact) private {
        uint256 buybackPercent = priceImpact.mul(buybackImpactMultiplier).div(100);

        if (buybackPercent > maxBuybackImpactPercent) {
            buybackPercent = maxBuybackImpactPercent;
        }

        if (buybackPercent < minBuybackImpactPercent) {
            return;
        }

        // Calculate the amount for buyback (100) = 100 / 10000 = 5
        uint256 amount = address(this).balance.mul(buybackPercent).div(10000);

        // A => B so really dont need to do this. Just being safe lol
        if (amount >= minBNBAmountBuyback && address(this).balance >= minBNBAmountBuyback) {
            swapETHForTokens(amount);
        }
    }

    function calcBuyback(uint256 priceImpact, bool isBuy) private {
        if (isBuy) {
            cumulativePriceImpact += int256(priceImpact);
        } else {
            cumulativePriceImpact -= int256(priceImpact);
        }
    }

    function buyBackTokens(address from, uint256 amount) private lockTheSwap {
        bool isBuy = (from == uniswapV2Pair);
        uint256 priceImpact = getPriceImpact(amount, isBuy);

        if (buyBackTriggered && !isBuy) {
            // Preform buyback
            performBuyback(priceImpact);

            if (block.timestamp >= buybackEndTime) {
                resetBuyback();
            }
        } else if (!buyBackTriggered) {
            buybackCurrentWindow += 1;
            if (buybackCurrentWindow <= buybackWindow) {
                // Add buyback to cumulative number
                calcBuyback(priceImpact, isBuy);
            }

            // Short circuit for if cumulative price impact is dumping faster than the window
            if (buybackCurrentWindow >= buybackWindow || cumulativePriceImpact <= priceImpactTriggerBuybackThreshold) {
                // Needs to be below the threshold since measuring sells and at least min BNB in balance
                if (cumulativePriceImpact <= priceImpactTriggerBuybackThreshold && address(this).balance >= minBNBBalanceBuyback) {
                    // Above threshold! Start the buybackWindow
                    startBuyback();

                    performBuyback(priceImpact);
                } else {
                    // Failed to trigger buyback within window retry
                    resetBuyback();
                }
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(600)
        );

        emit SwapETHForTokens(amount, path);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tMarketing);
        return (tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rMarketing);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function _takeMarketing(uint256 tMarketing) private {
        uint256 currentRate =  _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        _rOwned[marketingAddress] = _rOwned[marketingAddress].add(rMarketing);
        if(_isExcluded[marketingAddress])
            _tOwned[marketingAddress] = _tOwned[marketingAddress].add(tMarketing);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }

    function bnbReadyBuyback() public view returns (uint256) {
        return address(this).balance;
    }

    function getCorrectReserves() private returns (uint256, uint256) {
        (uint256 reserve0, uint256 reserve1,) = _uniswapV2Pair.getReserves();

        uint256 tokenReserve;
        uint256 bnbReserve;

        if (_uniswapV2Pair.token0() == address(this)) {
            tokenReserve = reserve0;
            bnbReserve = reserve1;
        } else {
            tokenReserve = reserve1;
            bnbReserve = reserve0;
        }

        return (tokenReserve, bnbReserve);
    }

    function getPriceImpact(uint256 amount, bool buy) private returns (uint256) {
        (uint256 tokenReserve, uint256 bnbReserve) = getCorrectReserves();

        if (buy) {
            // price impact on buying = (Yamount*0.97) / current Yamount in pool
            // mul by 100 to get percent
            return (amount.mul(10000).mul(97).div(100).div(tokenReserve));
        } else {
            // Let u = Y amount of tokens to be sold
            // Let er = current ETH exchange rate in reference with TokenA
            // price impact on selling = 0.97er / current Xamount in pool
            // mul by 100 for percent
            return (getTokenToBNB(amount).mul(10000).mul(97).div(100).div(bnbReserve));
        }
    }

    function getBuyBackTriggered() public view returns(bool) {
        if (block.timestamp >= buybackTriggerViewerTimer || _msgSender() == owner()) {
            return buyBackTriggered;
        }

        return false;
    }

    function getBuybackEndTime() public view returns(uint256) {
        // Only owner should know the actual status to avoid botting
        if (_msgSender() == owner()) {
            return buybackEndTime;
        }
        return 0;
    }

    function getTokenToBNB(uint256 amount) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint[] memory amounts = uniswapV2Router.getAmountsOut(amount, path);

        return amounts[1];
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _marketingFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _marketingFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _marketingFee = _previousMarketingFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromMaxTx(address account) public view returns(bool) {
        return _isExcludedFromMaxTx[account];
    }

    function setBuybackTime(uint256 _minBuybackTime, uint256 _maxBuybackTime) external onlyOwner {
        minBuybackTime = _minBuybackTime;
        maxBuybackTime = _maxBuybackTime;
    }

    function setBuybackWindowMaxMin(uint256 _minBuybackWindow, uint256 _maxBuybackWindow) external onlyOwner() {
        minBuybackWindow = _minBuybackWindow;
        maxBuybackWindow = _maxBuybackWindow;
    }

    // Need this to change current window before launch incase we get too much traffic
    function setCurrentBuyBackWindow(uint256 _buybackWindow) external onlyOwner() {
        buybackWindow = _buybackWindow;
    }

    function setBuybackTriggerViewerWindow(uint256 _buybackTriggerViewerWindow) external onlyOwner() {
        buybackTriggerViewerWindow = _buybackTriggerViewerWindow;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        _marketingFee = marketingFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }

    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap) external onlyOwner() {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }

    function setPercentOfSwapIsLP(uint256 _percentOfSwapIsLP) external onlyOwner() {
        percentOfSwapIsLP = _percentOfSwapIsLP;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner() {
        // Remove old marketing address
        includeInFee(marketingAddress);
        // Add new marketing address
        excludeFromFee(_marketingAddress);

        marketingAddress = payable(_marketingAddress);
    }

    function setPriceImpactTriggerBuybackThreshold(int256 _priceImpactTriggerBuybackThreshold) external onlyOwner() {
        priceImpactTriggerBuybackThreshold = _priceImpactTriggerBuybackThreshold;
    }

    function setBuybackImpactMultiplier(uint256 _buybackImpactMultiplier) external onlyOwner() {
        buybackImpactMultiplier = _buybackImpactMultiplier;
    }

    function setMinBuybackImpactPercent(uint256 _minBuybackImpactPercent) external onlyOwner() {
        minBuybackImpactPercent = _minBuybackImpactPercent;
    }

    function setMaxBuybackImpactPercent(uint256 _maxBuybackImpactPercent) external onlyOwner() {
        maxBuybackImpactPercent = _maxBuybackImpactPercent;
    }

    function setMinBNBBalanceBuyback(uint256 _minBNBBalanceBuyback) external onlyOwner() {
        minBNBBalanceBuyback = _minBNBBalanceBuyback;
    }

    function setMinBNBAmountBuyback(uint256 _minBNBAmountBuyback) external onlyOwner() {
        minBNBAmountBuyback = _minBNBAmountBuyback;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function backupPrepareForPreSale() external onlyOwner {
        setSwapAndLiquifyEnabled(false);
        _taxFee = 0;
        _marketingFee = 0;
        _liquidityFee = 0;
        _maxTxAmount = _tTotal;
    }

    function backupAfterPreSale() external onlyOwner {
        setSwapAndLiquifyEnabled(true);
        _taxFee = 1;
        _marketingFee = 1;
        _liquidityFee = 8;
        _maxTxAmount = _tTotal.div(50);
    }

    function prepareForPreSale(address _presaleAddress, address _routerAddress) external onlyOwner {
        // Owner contract is exempt
        setSwapAndLiquifyEnabled(true);
        whitelistDxSale(_presaleAddress, _routerAddress);
    }

    function afterPreSale() external onlyOwner {
        setSwapAndLiquifyEnabled(true);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function excludeFromMaxTx(address account) public onlyOwner {
        _isExcludedFromMaxTx[account] = true;
    }

    function includeFromMaxTx(address account) public onlyOwner {
        _isExcludedFromMaxTx[account] = false;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function whitelistDxSale(address _presaleAddress, address _routerAddress) public onlyOwner {
        excludeFromFee(_presaleAddress);
        excludeFromFee(_routerAddress);
        excludeFromMaxTx(_presaleAddress);
        excludeFromMaxTx(_routerAddress);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
}