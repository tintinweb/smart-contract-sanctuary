/**
 *Submitted for verification at polygonscan.com on 2021-12-20
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

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
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
    mapping(address => bool) internal _whiteList;
    mapping(address => bool) internal _blackList;
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

    function includeToBlackList(address[] memory _users) external onlyOwner {
        for (uint8 i = 0; i < _users.length; i++) {
            _blackList[_users[i]] = true;
        }
    }

    function setBlackList(address user, bool exempt) public onlyOwner {
        _blackList[user] = exempt;
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

    // Special wallets
    address devAddress = 0x5939202E7d88F3f480c292c0E9051afBb3Ce777f;
    address lpAddress = 0x1c52b31D61859f9d5c610a3ff0227C067241DBcb;
    address autoBuyBackAddress = 0xe146b9641bFB686a920c463a5c6C363bde58A035;
    address manualBuyBackAddress = 0x9C304dE062A0C7bc88822B31b43810027Cab6975;

    IDEXRouter pancakeRouter;
    mapping(address => bool) pairs;

    uint256 public swapbackThreshold = 10;
    uint256 public mainTokenTotalBuy = 0;
    uint256 public mainTokenTotalSell = 0;

    uint256 public undistributedBuyTax = 0;
    uint256 public undistributedSellTax = 0;

    uint8 constant BUY_IN_TAX_PERCENTAGE = 10;
    uint8 constant SELL_OUT_TAX_PERCENTAGE = 25;
    uint8 constant SELL_THRESHOLD = 70;

    uint8 constant TX_NORMAL = 0;
    uint8 constant TX_BUY = 1;
    uint8 constant TX_SELL = 2;

    address public mainSwapPairAddress = DEAD;
    uint256 private maxBnbUserCanBuy = 2000000 * 10**18; // 2 million BNB

    bool inSwap;

    constructor() {
        // Create a DEX pair with the "WETH" token of the blockchain
        // BSC mainnet PancakeSwap pancakeRouter address: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // ETH mainnet Uniswap pancakeRouter address: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        // BSC testnet PancakeSwap pancakeRouter address: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        pancakeRouter = IDEXRouter(0xcEF8ed2ED9FBF122005786321fbba9eDb37b4A55);
        mainSwapPairAddress = IDEXFactory(pancakeRouter.factory()).createPair(
            address(this),
            pancakeRouter.WETH()
        );
        _allowances[address(this)][address(pancakeRouter)] = ~uint256(0);
        pairs[mainSwapPairAddress] = true;

        address contractOwner = owner();
        _balances[contractOwner] = _totalSupply;

        _whiteList[devAddress] = true;
        _whiteList[lpAddress] = true;
        _whiteList[autoBuyBackAddress] = true;
        _whiteList[manualBuyBackAddress] = true;
    }

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

        // TODO NguyenHuynh: need to remove this
    // this used for mainet testing of eth.
    // we'll remove it on beforem merge into develop
    function initLiquidity(uint256 ethAmount, uint256 thisAmount) public onlyOwner {
        approve(address(pancakeRouter),  ethAmount);
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            thisAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }


    /**
     *  Withdraw all bnb accidentally sent to this address
     */
    function withdrawAllBNB() external {
        require(msg.sender == safeManager);
        safeManager.transfer(address(this).balance);
    }

    /**
     * Returns the total sell/total buy ratio of the main token in percentage
     * E.g. 200 = 200%
     */
    function totalMainTokenSellBuyRatio() public view returns (uint256) {
        if (mainTokenTotalBuy == 0) {
            return 0;
        }
        uint256 upper = mainTokenTotalBuy.sub(mainTokenTotalSell);
        uint256 lower = mainTokenTotalBuy.add(mainTokenTotalSell);
        return upper.mul(100).div(lower);
    }

    /**
        Undistributed sell tax in project token
    */
    function getSellTaxBalance() public view returns (uint256) {
        return undistributedSellTax.div(10**_decimals);
    }

    /**
        Undistributed buy tax in project token
    */
    function getBuyTaxBalance() public view returns (uint256) {
        return undistributedBuyTax.div(10**_decimals);
    }

    /**
        Total buy value in main token
     */
    function getTotalBuyValue() public view onlyOwner returns (uint256) {
        return mainTokenTotalBuy.div(10**_decimals);
    }

    /**
        Total sell value in main token
     */
    function getTotalSellValue() public view onlyOwner returns (uint256) {
        return mainTokenTotalSell.div(10**_decimals);
    }

    /**
     * Set swapback threshold.
     * If the total of undistributed buy or sell tax greather than this threshold, we'll do the distribution.
     * Value set in the number of token.
     */
    function setSwapbackThreshold(uint256 threshold) public onlyOwner {
        require(
            threshold < _totalSupply.div(10**_decimals),
            "Invalid threshold value"
        );
        swapbackThreshold = threshold * 10**_decimals;
    }

    /**
        Set address of dev wallet
     */
    function setDevWallet(address dev) public onlyOwner {
        setWhiteList(devAddress, false);
        devAddress = dev;
        setWhiteList(devAddress, true);
    }

    /**
        Set address of liquidity provider wallet
     */
    function setLPWallet(address lp) public onlyOwner {
        setWhiteList(lpAddress, false);
        lpAddress = lp;
        setWhiteList(lpAddress, true);
    }

    /**
        Set address of auto buy back wallet
     */
    function setAutoBuyBackWallet(address add) public onlyOwner {
        setWhiteList(autoBuyBackAddress, false);
        autoBuyBackAddress = add;
        setWhiteList(autoBuyBackAddress, true);
    }

    /**
        Set address of manual buy back wallet
     */
    function setManualBuyBackWallet(address add) public onlyOwner {
        setWhiteList(manualBuyBackAddress, false);
        manualBuyBackAddress = add;
        setWhiteList(manualBuyBackAddress, true);
    }

    /**
        Set max amount of BNB that user can buy in a swap
     */
    function setMaxBnbUserCanBuy(uint256 maxBnb) public onlyOwner {
        require(maxBnb < 2000000 * 10**18, "Max BNB value should < 2 million");

        maxBnbUserCanBuy = maxBnb;
    }

    /**
        Force swapping all undistributed buy tax
        and distribute
     */
    function swapBackAndDistributeBuyTax() private swapping {
        uint256 bnbBefore = address(this).balance;
        swapTokenToBnb(undistributedBuyTax, address(this));
        uint256 bnbAfter = address(this).balance;
        uint256 bnbToDistribute = bnbAfter.sub(bnbBefore);

        distributeBnb(devAddress, bnbToDistribute.mul(50).div(100));
        distributeBnb(lpAddress, bnbToDistribute.mul(50).div(100));

        undistributedBuyTax = 0;
    }

    /**
        Force swapping all undistributed sell tax
        and distribute
     */
    function swapBackAndDistributeSellTax() private swapping {
        // TODO Require undistributedSellTax > 0
        uint256 bnbBefore = address(this).balance;

        swapTokenToBnb(undistributedSellTax, address(this));
        uint256 bnbAfter = address(this).balance;
        uint256 bnbToDistribute = bnbAfter.sub(bnbBefore);

        uint256 manualBuyBackBnb = bnbToDistribute.mul(40).div(100);
        distributeBnb(manualBuyBackAddress, manualBuyBackBnb);
        uint256 devBnb = bnbToDistribute.mul(20).div(100);
        distributeBnb(devAddress, devBnb);
        uint256 autoBuybackBnb = bnbToDistribute.sub(manualBuyBackBnb).sub(
            devBnb
        );

        distributeAutoBuyBack(autoBuybackBnb);

        undistributedSellTax = 0;
    }

    function distributeAutoBuyBack(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, autoBuyBackAddress, block.timestamp.add(300));
    }

    /**
        TODO Review the necessarity of this method
     */
    function canSwapBack() private view returns (bool) {
        return !pairs[msg.sender] && !inSwap;
    }

    /**
        If sender/recipient is blacklisted, they cannot trade
     */
    function isNotBlockedFromTrading(address sender, address recipient)
        private
        view
    {
        require(
            !_blackList[sender] && !_blackList[recipient],
            "Address is blacklisted"
        );
    }

    /**
        Check if the address can sell token
     */
    function canSellToken(
        /*address sender, */
        uint256 amount
    ) private view {
        // require(
        //     /* excludeMaxTxn[sender] || */
        //     sellPressure(amount) < SELL_THRESHOLD,
        //     "Sell Limit Exceeded"
        // );
    }

    /**
        Check if a buyer can buy token:
        * Buying value in BNB < max BNB limit
     */
    function canBuyToken(
        /*address buyer, */
        uint256 amount
    ) private view {
        require(
            getMainTokenEstimatedPrice(amount) < maxBnbUserCanBuy,
            "Buy limit exceeded"
        );
    }

    /**
        Get estimated BNB before swapping
        TODO change to private
     */
    function getMainTokenEstimatedPrice(uint256 tokenAmount)
        public
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();
        uint256[] memory amounts = pancakeRouter.getAmountsOut(
            tokenAmount,
            path
        );
        return amounts[1];
    }

    /**
        Get total sell value / total buy value
        In percentage
     */
    function sellPressure(uint256 amount) private view returns (uint256) {
        // No buy no sell
        if (mainTokenTotalBuy == 0) {
            return 100;
        }

        // Calculate sell value percentage
        uint256 estimatedMainToken = getMainTokenEstimatedPrice(amount);
        return
            mainTokenTotalSell.add(estimatedMainToken).mul(100).div(
                mainTokenTotalBuy
            );
    }

    /**
     * Returns the transfer type.
     * 1 if user is buying (swap main token for sc token)
     * 2 if user is selling (swap sc token for main token)
     * 0 if user do the simple transfer between two wallets.
     */
    function checkTransferType(address sender, address recipient)
        private
        view
        returns (uint8)
    {
        if (sender.code.length > 0) {
            // in case of the wallet, there's no code => length == 0.
            return TX_BUY; // buy
        } else if (recipient.code.length > 0) {
            return TX_SELL; // sell
        }

        return TX_NORMAL; // normal transfer
    }

    function isBuyBackThresholdExceeded(uint256 tokenAmount)
        private
        view
        returns (bool)
    {
        if (tokenAmount == 0) {
            return false;
        }
        return getMainTokenEstimatedPrice(tokenAmount) > swapbackThreshold;
    }

    /**
     * Transfer the token from sender to recipient
     * The logic of tax applied here.
     */
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal override open(sender, recipient) returns (bool) {
        // For the whitelisted wallets, simply do basic transfer
        // TODO: Distribute tax enven in this case
        if (_whiteList[sender] || _whiteList[recipient] || inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint8 transferType = checkTransferType(sender, recipient);
        uint256 fee = 0;
        if (transferType == TX_BUY) {
            // user buy token
            isNotBlockedFromTrading(sender, recipient);
            canBuyToken(
                /*recipient, */
                amount
            );
            fee = amount.mul(BUY_IN_TAX_PERCENTAGE).div(100);
            undistributedBuyTax = undistributedBuyTax.add(fee);

            // totalBuyValue = totalBuyValue.add(amount);
            mainTokenTotalBuy = mainTokenTotalBuy.add(
                getMainTokenEstimatedPrice(amount)
            );
        } else if (transferType == TX_SELL) {
            isNotBlockedFromTrading(sender, recipient);
            canSellToken(
                /*sender, */
                amount
            );
            fee = amount.mul(SELL_OUT_TAX_PERCENTAGE).div(100);
            undistributedSellTax = undistributedSellTax.add(fee);

            // totalSellValue = totalSellValue.add(amount);
            mainTokenTotalSell = mainTokenTotalSell.add(
                getMainTokenEstimatedPrice(amount)
            );
        }

        uint256 amountReceived = amount.sub(fee);
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[address(this)] = _balances[address(this)].add(fee);

        // Swap back and distribute taxes
        if (canSwapBack()) {
            if (undistributedBuyTax >= swapbackThreshold) {
                swapBackAndDistributeBuyTax();
            }

            if (undistributedSellTax >= swapbackThreshold) {
                swapBackAndDistributeSellTax();
            }
        }

        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);

        return true;
    }

    // Swap THIS token into bnb (eth).
    function swapTokenToBnb(uint256 amount, address fromToken) private {
        require(amount > 0);
        IBEP20 tokenContract = IBEP20(fromToken);
        tokenContract.approve(address(pancakeRouter), amount);

        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = pancakeRouter.WETH();
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function distributeBnb(address recipient, uint256 amount) private {
        (bool success, ) = payable(recipient).call{value: amount, gas: 30000}(
            ""
        );
        require(success, "Failed to distribute BNB");
    }
}