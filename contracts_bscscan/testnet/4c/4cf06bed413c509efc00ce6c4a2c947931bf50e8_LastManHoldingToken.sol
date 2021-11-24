/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IPancakePair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IDEXRouter {
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


contract SafeToken is Ownable {
    address payable safeManager;

    constructor() {
        safeManager = payable(msg.sender);
    }

    function getSafeManager() public view returns (address) {
        return safeManager;
    }

    function setSafeManager(address payable _safeManager) public onlyOwner {
        safeManager = _safeManager;
    }

    function withdrawBNB(uint256 _amount) external {
        require(msg.sender == safeManager);
        safeManager.transfer(_amount);
    }
}

contract LockToken is Ownable {
    bool public isOpen = false;
    mapping(address => bool) private _whiteList;
    modifier open(address from, address to) {
        require(isOpen || _whiteList[from] || _whiteList[to], "Not Open");
        _;
    }

    constructor() {
        _whiteList[msg.sender] = true;
        _whiteList[address(this)] = true;
    }

    function openTrade() external onlyOwner {
        isOpen = true;
    }

    function stopTrade() external onlyOwner {
        isOpen = false;
    }

    function includeToWhiteList(address[] memory _users) external onlyOwner {
        for (uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }

    function setWhiteList(address user, bool exempt) public onlyOwner {
        _whiteList[user] = exempt;
    }
}


contract BaseToken is Ownable, IBEP20 {
    using SafeMath for uint256;

    address BNB = 0xB8c77482e45F1F44dE1745F52C74426C631bDD52;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    string _name;
    string _symbol;
    uint8 _decimals;
    uint256 _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _decimals = decimals_;
    }

    receive() external payable {}

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != ~uint256(0)) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        return _basicTransfer(sender, recipient, amount);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }
}

contract LastManHoldingToken is
    BaseToken("Last Man Holding", "LAST", 1000000000000 * (10**18), 18),
    SafeToken,
    LockToken
{
    using SafeMath for uint256;

    mapping(address => bool) public excludeFee;
    mapping(address => bool) public excludeMaxTxn;
    mapping(address => bool) public blackList;

    // Special wallets
    address devAddress = 0x5939202E7d88F3f480c292c0E9051afBb3Ce777f;
    address lpAddress = 0x1c52b31D61859f9d5c610a3ff0227C067241DBcb;
    address autoBuyBackAddress = 0xF44239ea700F72390baac5a4f3bD98D57be7D352;
    address manualBuyBackAddress = 0x8d22708a56D9eBCbDEa0134c74fdB26d7ae9Fe3b;

    // uint256 buyBackUpperLimit = 2 * 10**16;

    IDEXRouter router;
    mapping(address => bool) pairs;
    bool swapEnabled = true;
    bool buyBackEnable = true;

    uint256 swapbackThreshold; // 0.02%
    // TODO private me
    uint256 public totalBuy = 1;
    uint256 public totalSell = 0;
    uint256 public mainTokenTotalBuy = 0; // each increasement is 0.01 of main token.
    uint256 public mainTokenTotalSell = 0;

    // TODO: private me
    uint256 public undistributedSellTax = 0;
    uint256 public undistributedBuyTax = 0;

    uint8 private BUY_IN_TAX = 10;
    uint8 private SELL_OUT_TAX = 25;
    uint8 constant TX_BUY = 1;
    uint8 constant TX_SELL = 2;
    uint8 constant SELL_THRESHOLD = 70;

    // We use 1% percentage.
    // 1 = 0.01 Main token
    uint256 private maxAmountOfMainTokenUserCanBuy = 200000000 * 10**18; // 2 million main token
    address _tokenCreator;

    address public pancakeSwapPair = DEAD;

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        // Mainnet Pancake Swap Router
        // TODO Use this on mainnet release
        // router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // For testnet
        // Uniswap router
        //TODO NguyenHuynh: put back to pancakeSwapPair
        // router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // bnb testnet router v2
        // https://twitter.com/pancakeswap/status/1369547285160370182?lang=en
        router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        pancakeSwapPair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());
        pairs[pancakeSwapPair] = true;
        _allowances[address(this)][address(router)] = ~uint256(0);
        // By default we distribute BNB.

        address owner_ = msg.sender;
        _tokenCreator = msg.sender;

        excludeFee[owner_] = true;
        excludeMaxTxn[owner_] = true;
        excludeFee[address(this)] = true;
        excludeMaxTxn[address(this)] = true;

        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);
    
        //TODO NguyenHuynh: put it back
        swapbackThreshold = 500;

        initWallets();
    }

    /**
     * Set swapback threshold.
     * If the total of undistributed buy or sell tax greather than this threshold, we'll do the distribution.
     * Value set in the number of token.
     */
    function setSwapbackThreshold(uint256 threshold) public onlyOwner {
        require(threshold < 10**18, "Invalid threshold value");
        swapbackThreshold = threshold * 10 ** 18;
    }

    function initWallets() private onlyOwner {
        toggleExcludeAllFeeForWallet(_tokenCreator, true);
        toggleExcludeAllFeeForWallet(devAddress, true);
        toggleExcludeAllFeeForWallet(lpAddress, true);
        toggleExcludeAllFeeForWallet(autoBuyBackAddress, true);
        toggleExcludeAllFeeForWallet(manualBuyBackAddress, true);

        setWhiteList(_tokenCreator, true);
        setWhiteList(devAddress, true);
        setWhiteList(lpAddress, true);
        setWhiteList(autoBuyBackAddress, true);
        setWhiteList(manualBuyBackAddress, true);
    }

    /**
        Set a wallet to be excluded from tax fee
     */
    function toggleExcludeAllFeeForWallet(address wallet, bool isExcludeFee)
        public
        onlyOwner
    {
        excludeFee[wallet] = isExcludeFee;
        excludeMaxTxn[wallet] = isExcludeFee;
    }

    /**
        Set/Unset an address to blacklist
     */
    function setBlacklist(address user, bool exempt) public onlyOwner {
        blackList[user] = exempt;
    }

    /**
        Set address of dev wallet
     */
    function setDevWalletAddress(address dev) public onlyOwner {
        setWhiteList(devAddress, false);
        toggleExcludeAllFeeForWallet(devAddress, false);
        devAddress = dev;
        toggleExcludeAllFeeForWallet(devAddress, true);
        setWhiteList(devAddress, true);
    }

    /**
        Set address of liquidity provider wallet
     */
    function setLPWalletAddress(address lp) public onlyOwner {
        setWhiteList(lpAddress, false);
        toggleExcludeAllFeeForWallet(lpAddress, false);
        lpAddress = lp;
        toggleExcludeAllFeeForWallet(lpAddress, true);
        setWhiteList(lpAddress, true);
    }

    /**
        Set address of auto buy back wallet
     */
    function setAutoBuyBackWalletAddress(address add) public onlyOwner {
        setWhiteList(autoBuyBackAddress, false);
        toggleExcludeAllFeeForWallet(autoBuyBackAddress, false);
        autoBuyBackAddress = add;
        toggleExcludeAllFeeForWallet(autoBuyBackAddress, true);
        setWhiteList(autoBuyBackAddress, true);
    }

    /**
        Set address of manual buy back wallet
     */
    function setManualBuyBackWalletAddress(address add) public onlyOwner {
        setWhiteList(manualBuyBackAddress, false);
        toggleExcludeAllFeeForWallet(manualBuyBackAddress, false);
        manualBuyBackAddress = add;
        toggleExcludeAllFeeForWallet(manualBuyBackAddress, true);
        setWhiteList(manualBuyBackAddress, true);
    }

    function testDistribute() public view returns (bool) {
        return undistributedBuyTax > swapbackThreshold;
    }
    /**
     * Transfer the token from sender to recipient
     * THe logic of tax applied here.
     */
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal override open(sender, recipient) returns (bool) {
        // Buy back we simply do the basic transfer.
        // this won't happen in anyother case.
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        // for the lp, dev, simply do basic transfer
        if (excludeFee[sender] || excludeFee[recipient]) {
            return _basicTransfer(sender, recipient, amount);
        }
        
        if (canSwapBack()) {
            if (undistributedBuyTax > swapbackThreshold) {
                swapBackAndDistributeBuyTaxDividen();
            }
    
            if (undistributedSellTax > swapbackThreshold) {
                swapBackAndDistributeSellTaxDividen();
            }    
        }

        uint8 transferType = _transferType(sender, recipient);
        uint256 fee = 0;
        if (transferType == TX_BUY) {
            // user buy token
            isNotBlockSell(sender, recipient);
            canBuyToken(recipient, amount);
            fee = calculateFee(sender, recipient, amount);
            undistributedBuyTax = undistributedBuyTax.add(fee);

            totalBuy = totalBuy.add(amount);
            mainTokenTotalBuy = mainTokenTotalBuy.add(getPriceOfToken(amount));
        } else if (transferType == TX_SELL) {
            isNotBlockSell(sender, recipient);
            canSellToken(sender, amount);
            fee = calculateFee(sender, recipient, amount);
            undistributedSellTax = undistributedSellTax.add(fee);

            totalSell = totalSell.add(amount);
            mainTokenTotalSell = mainTokenTotalSell.add(getPriceOfToken(amount));
        }

        uint256 amountReceived = amount.sub(fee);
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[address(this)] = _balances[address(this)].add(fee);
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);

        return true;
    }
    
    // //TODO NguyenHuynh remove me
    uint8 public forceSwapback = 0;
    function setForceSwapback(uint8 f) public {
        forceSwapback = f;
    }
    
    function canSwapBack() public view returns (bool) {
        if (forceSwapback != 0) {
            return forceSwapback == 1;
        }
        return !inSwap;
    }

    // TODO NguyenHuynh: need to remove this
    // this used for mainet testing of eth.
    // we'll remove it on beforem merge into develop
    function initLiquidity(uint256 ethAmount, uint256 thisAmount) public onlyOwner {
        approve(address(router),  ethAmount);
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            thisAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }


    function getTaxEarnedBalance() public onlyOwner view returns (uint256) {
        return balanceOf(address(this)).div(10**18);
    }

    /**
        Set max amount of MainToken that user can buy in a swap
     */
    function setMaxMainTokenAmountUserCanBuy(uint256 amountOfMainToken) public onlyOwner {
        require(amountOfMainToken < 10**19, "Invalid amount of the main token..");

        maxAmountOfMainTokenUserCanBuy = amountOfMainToken * 10**16;
    }

    /**
     * Returns sell/buy the ratio of this token (LAST)
     */
    function tokenSellBuyRatio() public view returns (uint256) {
        if (totalBuy == 0) {
            return 100;
        }
        return totalSell.mul(100).div(totalBuy); // percentage
    }

    /**
     * Returns the sell/buy ratio of the main token in percentage
     * E.g. 200 = 200%
     */
    function mainTokenSellBuyRatio() public view returns (uint256) {
        if (mainTokenTotalBuy == 0) {
            return 100;
        }
        return mainTokenTotalSell.mul(100).div(mainTokenTotalBuy);
    }

    /**
        Set an address to be tax-free
     */
    function setExcludeFee(address holder, bool exempt) external onlyOwner {
        excludeFee[holder] = exempt;
    }

    /**
        Set an address to be unlimited buy/sell
     */
    function setExcludeMaxTxn(address holder, bool exempt) external onlyOwner {
        excludeMaxTxn[holder] = exempt;
    }

    /**
     *  Withdraw all bnb accidentally sent to this address
     */
    function withdrawAllBNB() external {
        require(msg.sender == safeManager);
        safeManager.transfer(address(this).balance);
    }

    function isNotBlockSell(address sender, address recipient) private view {
        require(
            !blackList[sender] && !blackList[recipient],
            "Address is blacklisted"
        );
    }

    function canSellToken(address sender, uint256 amount) private view {
        require(
            excludeMaxTxn[sender] || sellPressure(amount) < SELL_THRESHOLD,
            "Sell Limit Exceeded"
        );
    }

    function canBuyToken(address buyer, uint256 amount) private view {
        require(
            excludeMaxTxn[buyer] ||
                _balances[buyer].add(amount) <
                getMaxTokenUserCanSwapFromPool(pancakeSwapPair),
            "Buy Limit Exceeded"
        );
    }

    function getMaxTokenUserCanSwapFromPool(address poolAddress)
        private
        view
        returns (uint256)
    {
        if (poolAddress == DEAD) {
            return _totalSupply;
        }

        IPancakePair swapPair = IPancakePair(poolAddress);

        (uint112 noOfToken0, uint112 noOfToken1, ) = swapPair.getReserves();
        uint112 higher = noOfToken0;
        uint112 lower = noOfToken1;
        if (higher < lower) {
            higher = noOfToken1;
            lower = noOfToken0;
        }
        return (higher * maxAmountOfMainTokenUserCanBuy) / lower;
    }

    function getPriceOfToken(uint256 tokenAmount)
        private
        view
        returns (uint256)
    {
        IPancakePair swapPair = IPancakePair(pancakeSwapPair);

        (uint112 noOfToken0, uint112 noOfToken1, ) = swapPair.getReserves();
        uint112 higher = noOfToken0;
        uint112 lower = noOfToken1;
        if (higher < lower) {
            higher = noOfToken1;
            lower = noOfToken0;
        }

        uint256 amountWithoutDecimal = tokenAmount.div(10**_decimals);
        return (amountWithoutDecimal * lower * 100) / higher;
    }

    function sellPressure(uint256 amount) private view returns (uint256) {
        return totalSell.add(amount).mul(100).div(totalBuy);
    }

    /**
     * Returns the transfer type.
     * 1 if user is buying
     * 2 if user is selling
     * 0 if user do the simple transfer between two wallet.
     */
    function _transferType(address sender, address recipient)
        private
        view
        returns (uint8)
    {
        if (sender.code.length > 0) {
            // in case of the wallet, there's no codee => length = 0.
            return TX_BUY; // buy
        } else if (recipient.code.length > 0) {
            return TX_SELL; // sell
        }

        return 0; // normal transfer
    }

    /**
     * Configure buy/sell tax.
     * In percentage.
     * By default buy/sell tax = 10% and 25%
     */
    function setTax(uint8 buyTax, uint8 sellTax) public onlyOwner {
        BUY_IN_TAX = buyTax;
        SELL_OUT_TAX = sellTax;
    }

    function calculateFee(address sender, address recipient, uint256 amount) private view returns (uint256) {
        uint8 transferType = _transferType(sender, recipient);
        uint8 taxRate = 0;
        if (transferType == TX_BUY) {
            taxRate = BUY_IN_TAX;
        } else if (transferType == TX_SELL) {
            taxRate = SELL_OUT_TAX;
        }
        uint256 fee = amount.mul(taxRate).div(100);
        return fee;
    }

    function takeFee(address sender, uint256 feeAmount) private {
        _balances[sender] -= feeAmount;
        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);
    }

    //TODO NguyenHuynh: remove this
    address public iSwapToBNB;

    // Swap THIS token into bnb (eth).
    function swapTokenToBnb(uint256 amount, address fromToken) private {
        //IBEP20 tokenContract = IBEP20(fromToken);
        // tokenContract.approve(address(router), amount);
        iSwapToBNB = msg.sender;
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp);
    }


    function distributeBnb(address recipient, uint256 amount) private {
        (bool result, ) = payable(recipient).call{value: amount, gas: 30}("");
        if (result) {
            emit SwapbackSuccess("Distributed successfully!");
        }
    }

    uint256 public amountToSwapBack = 0;
    uint256 public amountTokenInContract = 0;
    function swapBackAndDistributeBuyTaxDividen() public swapping {
        uint256 bnbBefore = address(this).balance;
        excludeFee[pancakeSwapPair] = true;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        
        amountToSwapBack = undistributedBuyTax;
        amountTokenInContract = balanceOf(address(this));
        try
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            undistributedBuyTax.div(10),
            0,
            path,
            address(this),
            block.timestamp) {
            uint256 bnbAfter = address(this).balance;
            uint256 bnbToDistribute = bnbAfter.sub(bnbBefore);

            distributeBnb(devAddress, bnbToDistribute.mul(50).div(100));
            distributeBnb(lpAddress, bnbToDistribute.mul(50).div(100));
            
            undistributedBuyTax = 0;
        } catch Error(string memory e) {
            emit SwapBackFailed(
                string(abi.encodePacked("SwapBack failed with error ", e))
            );
        } catch {
            emit SwapBackFailed(
                "SwapBack failed without an error message from pancakeSwap"
            );
        }
        
        emit SwapbackSuccess("Success");
        
        excludeFee[pancakeSwapPair] = false;
    }

    function swapBackAndDistributeSellTaxDividen() public  {
        
    }

    event SwapbackSuccess(string message);
    event SwapBackFailed(string message);
    event SwapBNBForTokens(uint256 amount, address[] path);
}