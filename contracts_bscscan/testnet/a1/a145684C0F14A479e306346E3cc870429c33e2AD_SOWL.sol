/**
 *Submitted for verification at BscScan.com on 2021-10-07
*/

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier:MIT

interface IBEP20 {
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address payable private _owner;
    address payable private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = payable(_msgSender());
        emit OwnershipTransferred(address(0), _owner);
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
        _owner = payable(address(0));
    }

    function transferOwnership(address payable newOwner)
        public
        virtual
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = payable(address(0));
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(
            block.timestamp > _lockTime,
            "Contract is locked until defined days"
        );
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = payable(address(0));
    }
}

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IPancakePair {
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

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

interface IPancakeRouter01 {
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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
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

library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(address routerAddress, uint256 tokenAmount)
        internal
    {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function swapETHForTokens(
        address routerAddress,
        address recipient,
        uint256 ethAmount
    ) internal {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: ethAmount
        }(
            0, // accept any amount of BNB
            path,
            address(recipient),
            block.timestamp + 360
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
        );
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}

// Protocol by team BloctechSolutions.com

contract SOWL is Context, IBEP20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) public _isSniper;
    mapping(address => bool) public _isRetailer;

    address[] private _excluded;
    address[] private _confirmedSnipers;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100 * 1e9 * 1e12;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "SOWL Token";
    string private _symbol = "SOWL";
    uint8 private _decimals = 12;

    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;
    address payable public charityAddress;
    address payable public marketWallet;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool public swapAndLiquifyEnabled; // should be true to turn on to liquidate the pool
    bool public reflectionFeesdiabled; // fee is enabled by default
    bool public buyBackEnabled; // should be true to turn on to buy back from pool
    bool inSwapAndLiquify;
    bool public _tradingOpen; //once switched on, can never be switched off.

    uint256 public _liquidityFee = 40; // 4% will be added to the liquidity pool

    uint256 public _holderFee = 40; // 4% will be distributed to holders

    uint256 public _charityFee = 10; // 1% will go to the charity address

    uint256 public _marketFee = 10; // 1% will go to the market address

    uint256 totalFee = 100; // for internal use

    uint256 public _totalFeePerTx = 100; // 10% by default
    uint256 private _previoustotalFeePerTx = _totalFeePerTx;

    uint256 public _maxTxAmount = _tTotal.div(1000); // should be 0.1% percent per transaction
    uint256 public _maxSellAmount = 1 * 1e6 * 1e12; // should be 1M per sell transaction
    uint256 public minTokenNumberToSell = _tTotal.div(1000000); // 0.0001% max tx amount will trigger swap and add liquidity
    uint256 public sellFeeMultiplierNumerator = 200;
    uint256 public sellFeeMultiplierDenominator = 100;
    mapping(address => uint256) public sellFeeMultiplierTriggeredAt;
    uint256 public sellFeeMultiplierLength = 24 hours;
    uint256 public buyBackLowerLimit = 0.1 ether;
    uint256 public buyBackUpperLimit = 1 ether;
    uint256 public buyBackBurnLimit = 20 * 1e6 * 1e12;
    uint256 public currentBuyBackBurn;
    uint256 public _launchTime; // can be set only once
    uint256 public antiSnipingTime = 60 seconds; // can be set only once
    uint256 public retailerPercent = 20; // 2% by default
    uint256 public bonusPercent = 250; // 25% by default

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event BuyBack(address indexed receiver, uint256 indexed bnbAmount);

    event RetailerAddded(address indexed account);

    event RetailerRemoved(address indexed account);

    event SniperBotAddded(address indexed account);

    event SniperBotRemoved(address indexed account);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address payable _charity, address payable _market) {
        _rOwned[owner()] = _rTotal;
        charityAddress = _charity;
        marketWallet = _market;

        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(
             0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
        // Create a pancake pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(
            address(this),
            _pancakeRouter.WETH()
        );

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[address(deadAddress)] = true;

        //exclude from reward
        _isExcluded[deadAddress] = true;

        emit Transfer(address(0), owner(), _tTotal);
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

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        _transfer(_msgSender(), deadAddress, amount);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public nonReentrant isHuman {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        uint256 rAmount = tAmount.mul(_getRate());
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            uint256 rAmount = tAmount.mul(_getRate());
            return rAmount;
        } else {
            uint256 rAmount = tAmount.mul(_getRate());
            uint256 rTransferAmount = rAmount.sub(
                getTotalFeePerTx(tAmount).mul(_getRate())
            );
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _rOwned[account] = _tOwned[account].mul(_getRate());
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    // for 1% input 100
    function setMaxTxLimits(uint256 maxTxAmount, uint256 maxSellAmount)
        public
        onlyOwner
    {
        _maxTxAmount = maxTxAmount;
        _maxSellAmount = maxSellAmount;
    }

    function setMinTokenNumberToSell(uint256 _amount) public onlyOwner {
        minTokenNumberToSell = _amount;
    }

    function setExcludeFromMaxTx(address _address, bool value)
        public
        onlyOwner
    {
        _isExcludedFromMaxTx[_address] = value;
    }

    function setFeePercent(
        uint256 liquidityFee,
        uint256 holderFee,
        uint256 charityFee,
        uint256 marketFee
    ) external onlyOwner {
        _liquidityFee = liquidityFee;
        _holderFee = holderFee;
        _charityFee = charityFee;
        _marketFee = marketFee;
        totalFee = _liquidityFee.add(_holderFee).add(_charityFee).add(
            _marketFee
        );
        _totalFeePerTx = totalFee;
    }

    // numerator must be a multiple of 100
    function setSellFeeMultiplierNumerator(
        uint256 _duration,
        uint256 _numerator
    ) external onlyOwner {
        sellFeeMultiplierLength = _duration;
        sellFeeMultiplierNumerator = _numerator;
    }

    function setSwapAndLiquifyEnabled(bool _state) public onlyOwner {
        swapAndLiquifyEnabled = _state;
        emit SwapAndLiquifyEnabledUpdated(_state);
    }

    function setRetailerProfit(uint256 _percent) external onlyOwner {
        retailerPercent = _percent;
    }

    function setLiquidityMiningBonus(uint256 _percent) external onlyOwner {
        bonusPercent = _percent;
    }

    function setBuyback(
        bool _state,
        uint256 _upperAmount,
        uint256 _lowerAmount,
        uint256 _burnLimit
    ) public onlyOwner {
        buyBackEnabled = _state;
        buyBackUpperLimit = _upperAmount;
        buyBackLowerLimit = _lowerAmount;
        buyBackBurnLimit = _burnLimit;
    }

    function startTrading() external onlyOwner {
        require(!_tradingOpen, "Trading aready enabled");
        _tradingOpen = true;
        _launchTime = block.timestamp;
        swapAndLiquifyEnabled = true;
        buyBackEnabled = true;
    }

    function setReflectionFees(bool _state) external onlyOwner {
        reflectionFeesdiabled = _state;
    }

    function changeRouter(IPancakeRouter02 _pancakeRouter, address _pancakePair)
        external
        onlyOwner
    {
        pancakeRouter = _pancakeRouter;
        pancakePair = _pancakePair;
    }

    //to receive BNB from pancakeRouter when swapping
    receive() external payable {}

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function getSellFee() public view returns (uint256) {
        uint256 remainingTime = sellFeeMultiplierTriggeredAt[_msgSender()]
            .add(sellFeeMultiplierLength)
            .sub(block.timestamp);
        uint256 feeIncrease = _totalFeePerTx
            .mul(sellFeeMultiplierNumerator)
            .div(sellFeeMultiplierDenominator)
            .sub(_totalFeePerTx);
        return
            _totalFeePerTx.add(
                feeIncrease.mul(remainingTime).div(sellFeeMultiplierLength)
            );
    }

    function getTotalFeePerTx(uint256 tAmount) public view returns (uint256) {
        uint256 percentage = tAmount.mul(_totalFeePerTx).div(1e3);
        return percentage;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function addSniperInList(address account) external onlyOwner {
        require(
            account != address(pancakeRouter),
            "We can not blacklist pancakeRouter"
        );
        require(!_isSniper[account], "Account is already blacklisted");
        _isSniper[account] = true;
        _confirmedSnipers.push(account);

        emit SniperBotAddded(account);
    }

    function removeSniperFromList(address account) external onlyOwner {
        require(_isSniper[account], "Account is not blacklisted");
        for (uint256 i = 0; i < _confirmedSnipers.length; i++) {
            if (_confirmedSnipers[i] == account) {
                _confirmedSnipers[i] = _confirmedSnipers[
                    _confirmedSnipers.length - 1
                ];
                _isSniper[account] = false;
                _confirmedSnipers.pop();
                break;
            }
        }

        emit SniperBotRemoved(account);
    }

    function addRetailerInList(address account) external onlyOwner {
        require(!_isRetailer[account], "Account is already added");
        _isRetailer[account] = true;

        emit RetailerAddded(account);
    }

    function removeRetailerFromList(address account) external onlyOwner {
        require(_isRetailer[account], "Account is already removed");
        _isRetailer[account] = false;

        emit RetailerRemoved(account);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // liquidity fee transfer
    function _takeLiquidityFee(uint256 tAmount, uint256 currentRate) internal {
        uint256 feeAmount = getTotalFeePerTx(tAmount);
        uint256 tFee = feeAmount.mul(_liquidityFee.mul(100).div(totalFee)).div(
            100
        );
        uint256 rFee = tFee.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rFee);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tFee);
        emit Transfer(_msgSender(), address(this), tFee);
    }

    // Charity fee transfer
    function _takeCharityFee(uint256 tAmount, uint256 currentRate) internal {
        uint256 feeAmount = getTotalFeePerTx(tAmount);
        uint256 tFee = feeAmount.mul(_charityFee.mul(100).div(totalFee)).div(
            100
        );
        uint256 rFee = tFee.mul(currentRate);
        _rOwned[charityAddress] = _rOwned[charityAddress].add(rFee);
        if (_isExcluded[charityAddress])
            _tOwned[charityAddress] = _tOwned[charityAddress].add(tFee);
        emit Transfer(_msgSender(), charityAddress, tFee);
    }

    // Market fee transfer
    function _takeMarketFee(uint256 tAmount, uint256 currentRate) internal {
        uint256 feeAmount = getTotalFeePerTx(tAmount);
        uint256 tFee = feeAmount.mul(_marketFee.mul(100).div(totalFee)).div(
            100
        );
        uint256 rFee = tFee.mul(currentRate);
        _rOwned[marketWallet] = _rOwned[marketWallet].add(rFee);
        if (_isExcluded[marketWallet])
            _tOwned[marketWallet] = _tOwned[marketWallet].add(tFee);
        emit Transfer(_msgSender(), marketWallet, tFee);
    }

    // distribution to holders
    function _reflectFee(uint256 tAmount, uint256 currentRate) private {
        uint256 feeAmount = getTotalFeePerTx(tAmount);
        uint256 tFee = feeAmount.mul(_holderFee.mul(100).div(totalFee)).div(
            100
        );
        uint256 rFee = tFee.mul(currentRate);
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function setAllFee(uint256 _currentFee) private {
        _previoustotalFeePerTx = _totalFeePerTx;

        _totalFeePerTx = _currentFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "SOWL: transfer from the zero address");
        require(to != address(0), "SOWL: transfer to the zero address");
        require(amount > 0, "SOWL: Transfer amount must be greater than zero");
        require(balanceOf(from) >= amount, "SOWL: Insufficient user balance");
        require(!_isSniper[to], "SOWL: Can not send to bot");
        require(!_isSniper[from], "SOWL: Bots can not send");

        if (
            _isExcludedFromMaxTx[from] == false &&
            _isExcludedFromMaxTx[to] == false // by default false
        ) {
            require(amount <= _maxTxAmount, "SOWL: amount exceeded max limit");

            if (!_tradingOpen) {
                require(
                    from != pancakePair && to != pancakePair,
                    "SOWL: Trading is not enabled"
                );
            }

            if (
                block.timestamp < _launchTime + antiSnipingTime &&
                from != address(pancakeRouter)
            ) {
                if (from == pancakePair) {
                    _isSniper[to] = true;
                    _confirmedSnipers.push(to);

                    emit SniperBotAddded(to);
                }
            }
        }

        bool shouldSell = balanceOf(address(this)) >= minTokenNumberToSell;

        // can not trigger on buy transactions
        if (
            !inSwapAndLiquify &&
            shouldSell &&
            from != pancakePair &&
            swapAndLiquifyEnabled &&
            !(from == address(this) && to == pancakePair) // swap 1 time
        ) {
            swapAndLiquify();
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to] ||
            reflectionFeesdiabled
        ) {
            takeFee = false;
        }

        if (_isRetailer[to]) {
            amount = amount.add(amount.mul(retailerPercent).div(1e3));
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) setAllFee(0);
        else if (recipient == pancakePair) {
            require(
                amount <= _maxSellAmount,
                "SOWL: amount exceeded max limit"
            );
            if (
                sellFeeMultiplierTriggeredAt[_msgSender()].add(
                    sellFeeMultiplierLength
                ) > block.timestamp
            ) {
                setAllFee(getSellFee());
            }
            takeFee = false;
            sellFeeMultiplierTriggeredAt[_msgSender()] = block.timestamp;
        } else {
            setAllFee(0);
            takeFee = false;
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) {
            _totalFeePerTx = _previoustotalFeePerTx;
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(getTotalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(
            getTotalFeePerTx(tAmount).mul(currentRate)
        );
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidityFee(tAmount, currentRate);
        _takeCharityFee(tAmount, currentRate);
        _takeMarketFee(tAmount, currentRate);
        _reflectFee(tAmount, currentRate);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(getTotalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(
            getTotalFeePerTx(tAmount).mul(currentRate)
        );
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidityFee(tAmount, currentRate);
        _takeCharityFee(tAmount, currentRate);
        _takeMarketFee(tAmount, currentRate);
        _reflectFee(tAmount, currentRate);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(getTotalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(
            getTotalFeePerTx(tAmount).mul(currentRate)
        );
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidityFee(tAmount, currentRate);
        _takeCharityFee(tAmount, currentRate);
        _takeMarketFee(tAmount, currentRate);
        _reflectFee(tAmount, currentRate);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(getTotalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(
            getTotalFeePerTx(tAmount).mul(currentRate)
        );
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidityFee(tAmount, currentRate);
        _takeCharityFee(tAmount, currentRate);
        _takeMarketFee(tAmount, currentRate);
        _reflectFee(tAmount, currentRate);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function swapAndLiquify() private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancake pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        // only sell for minTokenNumberToSell, decouple from _maxTxAmount
        // split the contract balance into 2 pieces

        contractTokenBalance = minTokenNumberToSell;
        _approve(address(this), address(pancakeRouter), contractTokenBalance);

        // add liquidity
        // split the contract balance into 2 pieces

        uint256 otherPiece = contractTokenBalance.div(2);
        uint256 tokenAmountToBeSwapped = contractTokenBalance.sub(otherPiece);

        uint256 initialBalance = address(this).balance;

        // now is to lock into liquidity pool
        Utils.swapTokensForEth(address(pancakeRouter), tokenAmountToBeSwapped);

        // how much BNB did we just swap into?

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract

        uint256 bnbToBeAddedToLiquidity = address(this).balance.sub(
            initialBalance
        );

        // buy back if balance bnb is exceed lower limit
        if (buyBackEnabled && initialBalance > uint256(buyBackLowerLimit)) {
            if (initialBalance > buyBackUpperLimit)
                initialBalance = buyBackUpperLimit;
            if (currentBuyBackBurn <= buyBackBurnLimit) {
                uint256 beforeBalance = balanceOf(deadAddress);
                Utils.swapETHForTokens(
                    address(pancakeRouter),
                    deadAddress,
                    initialBalance.div(10)
                );
                uint256 afterBalance = balanceOf(deadAddress);
                currentBuyBackBurn = currentBuyBackBurn.add(
                    afterBalance.sub(beforeBalance)
                );

                emit BuyBack(deadAddress, initialBalance.div(10));
            } else {
                Utils.swapETHForTokens(
                    address(pancakeRouter),
                    address(this),
                    initialBalance.div(10)
                );

                emit BuyBack(address(this), initialBalance.div(10));
            }
        }

        // add liquidity to pancake
        Utils.addLiquidity(
            address(pancakeRouter),
            owner(),
            otherPiece,
            bnbToBeAddedToLiquidity
        );

        emit SwapAndLiquify(
            tokenAmountToBeSwapped,
            bnbToBeAddedToLiquidity,
            otherPiece
        );
    }
}