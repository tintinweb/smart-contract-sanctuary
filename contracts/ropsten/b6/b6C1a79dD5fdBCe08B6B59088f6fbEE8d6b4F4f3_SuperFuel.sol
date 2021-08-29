// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol';
import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';
import './utils/Ownable.sol';
import './utils/Manageable.sol';
import "./DividendDistributor.sol";
import "./utils/LockableFunction.sol";
import "./utils/LPSwapSupport.sol";
import "./utils/AntiLPSniper.sol";
import "./SmartLottery.sol";

contract SuperFuel is IBEP20, AuthorizedList, AntiLPSniper, LockableFunction, LPSwapSupport {
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;

    event Burn(address indexed from, uint256 tokensBurned);

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event UpdateFee(string indexed feeName, uint256 oldFee, uint256 newFee);

    struct Fees{
        uint256 liquidity;
        uint256 marketing;
        uint256 tokenReflection;
        uint256 buyback;
        uint256 lottery;
        uint256 divisor;
    }

    struct TokenTracker{
        uint256 liquidity;
        uint256 marketingTokens;
        uint256 reward;
        uint256 buyback;
        uint256 lottery;
    }

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private blacklist;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromReward;
    mapping (address => bool) public automatedMarketMakerPairs;

    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private  _totalSupply;

    bool tradingIsEnabled;

    // Trackers for various pending token swaps and fees
    Fees public fees;
    Fees public transferFees;
    TokenTracker public tokenTracker;
    TokenTracker public feeDistributionTracker;

    uint256 public _maxTxAmount;
    uint256 public tokenSwapThreshold;

    uint256 public gasForProcessing = 300000;

    // TODO - Change from test setup
    address payable public marketingWallet;
    address payable public buybackContract;
    ISmartLottery public lotteryContract;
    IDividendDistributor public dividendDistributor;

    constructor (uint256 _supply, address routerAddress, address tokenOwner, address _marketingWallet) public {
        _name = "SuperFuel";
        _symbol = "SFUEL";
        _decimals = 9;
        _totalSupply = _supply * 10 ** _decimals;

        _maxTxAmount = _totalSupply;
        tokenSwapThreshold = _maxTxAmount.div(10000);

        liquidityReceiver = deadAddress;

//        dividendDistributor = new DividendDistributor(routerAddress, rewardsToken);
        marketingWallet = payable(_marketingWallet);
        buybackContract = address(this);
//        lotteryContract = new SuperFuelSmartLottery(routerAddress, rewardsToken);
//        updateRouterAndPair(routerAddress);
        pancakeRouter = IPancakeRouter02(routerAddress);

//        pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());

        fees = Fees({
            liquidity: 2,
            marketing: 3,
            tokenReflection: 7,
            buyback: 2,
            lottery: 5,
            divisor: 100
        });

        transferFees = Fees({
            liquidity: 5,
            marketing: 0,
            tokenReflection: 0,
            buyback: 0,
            lottery: 0,
            divisor: 100
        });

        tokenTracker = TokenTracker({
            liquidity: 0,
            marketingTokens: 0,
            reward: 0,
            buyback: 0,
            lottery: 0
        });

        //exclude owner and this contract from fee
        _isExcludedFromFee[tokenOwner] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[address(dividendDistributor)] = true;
        _isExcludedFromFee[address(lotteryContract)] = true;
        _isExcludedFromFee[buybackContract] = true;
        _isExcludedFromFee[deadAddress] = true;

        _owner = tokenOwner;
        balances[tokenOwner] = _totalSupply;
//        emit Transfer(address(0), address(this), _presaleReserve);
    }

    function init(address payable _dividendContract, address payable _lotteryContract) external authorized {
        setPair();
        dividendDistributor = IDividendDistributor(_dividendContract);
        lotteryContract = ISmartLottery(_lotteryContract);

        _isExcludedFromFee[address(_dividendContract)] = true;
        _isExcludedFromFee[address(_lotteryContract)] = true;

        dividendDistributor.excludeFromReward(pancakePair, true);
        lotteryContract.excludeFromJackpot(pancakePair, true);
    }

    fallback() external payable {}

    //to recieve BNB from pancakeswapV2Router when swaping
    receive() external payable {}

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override view returns (uint8) {
        return uint8(_decimals);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function setMarketingWallet(address _marketingWallet) public onlyOwner {
        marketingWallet = payable(_marketingWallet);
    }

    function getOwner() external override view returns(address){
        return owner();
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 1000000, "Gas requirement is between 200,000 and 1,000,000");
        require(newValue != gasForProcessing, "Gas requirement already set to that value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function withdrawForeignTokens(address receiver, address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Token address is zero");
        require(tokenAddress != address(this), "Cannot force withdraw SuperFuel tokens");
        require(IBEP20(tokenAddress).balanceOf(address(this)) > 0, "No balance to withdraw");

        uint256 balance = IBEP20(tokenAddress).balanceOf(address(this));
        IBEP20(tokenAddress).transfer(receiver, balance);
    }

    function excludeFromFee(address account, bool shouldExclude) public onlyOwner {
        _isExcludedFromFee[account] = shouldExclude;
    }

    function _calculateFees(uint256 amount, bool isTransfer) private returns(uint256 liquidityFee, uint256 marketingFee, uint256 buybackFee, uint256 reflectionFee, uint256 lotteryFee) {
        Fees memory _fees;
        if(isTransfer)
            _fees = transferFees;
        else
            _fees = fees;
        liquidityFee = amount.mul(_fees.liquidity).div(_fees.divisor);
        marketingFee = amount.mul(_fees.marketing).div(_fees.divisor);
        buybackFee = amount.mul(_fees.buyback).div(_fees.divisor);
        reflectionFee = amount.mul(_fees.tokenReflection).div(_fees.divisor);
        lotteryFee = amount.mul(_fees.lottery).div(_fees.divisor);

        feeDistributionTracker.liquidity = feeDistributionTracker.liquidity.add(_fees.liquidity);
        feeDistributionTracker.marketingTokens = feeDistributionTracker.marketingTokens.add(_fees.marketing);
        feeDistributionTracker.buyback = feeDistributionTracker.buyback.add(_fees.buyback);
        feeDistributionTracker.reward = feeDistributionTracker.reward.add(_fees.tokenReflection);
        feeDistributionTracker.lottery = feeDistributionTracker.lottery.add(_fees.lottery);
    }
    ////////////////////////////////////////////////////// - TODO Rewrite
    function _takeFees(address from, uint256 amount, bool isTransfer) private returns(uint256 transferAmount){
        (uint256 liquidityFee, uint256 marketingFee, uint256 buybackFee, uint256 reflectionFee, uint256 lotteryFee) = _calculateFees(amount, isTransfer);
        uint256 totalFees = liquidityFee.add(marketingFee).add(buybackFee).add(reflectionFee).add(lotteryFee);

        tokenTracker.liquidity = tokenTracker.liquidity.add(liquidityFee);
        tokenTracker.marketingTokens = tokenTracker.marketingTokens.add(marketingFee);
        tokenTracker.buyback = tokenTracker.buyback.add(buybackFee);
        tokenTracker.reward = tokenTracker.reward.add(reflectionFee);
        tokenTracker.lottery = tokenTracker.lottery.add(lotteryFee);

        balances[address(this)] = balances[address(this)].add(totalFees);
        emit Transfer(from, address(this), totalFees);
        transferAmount = amount.sub(totalFees);
    }
    ////////////////////////////////////////////////////// - TODO Rewrite

    function updateTransferFees(uint256 _liquidity, uint256 _marketing, uint256 _tokenReflection, uint256 _buyback, uint256 _lottery, uint256 _divisor) external onlyOwner {
        transferFees = Fees({
            liquidity: _liquidity,
            marketing: _marketing,
            tokenReflection: _tokenReflection,
            buyback: _buyback,
            lottery: _lottery,
            divisor: _divisor
        });
    }

    function updateBuySellFees(uint256 _liquidity, uint256 _marketing, uint256 _tokenReflection, uint256 _buyback, uint256 _lottery, uint256 _divisor) external onlyOwner {
        fees = Fees({
            liquidity: _liquidity,
            marketing: _marketing,
            tokenReflection: _tokenReflection,
            buyback: _buyback,
            lottery: _lottery,
            divisor: _divisor
        });
    }

    function setTokenSwapThreshold(uint256 minTokensBeforeTransfer) public onlyOwner {
        tokenSwapThreshold = minTokensBeforeTransfer * 10 ** _decimals;
    }

    function setMaxSellTx(uint256 maxTxTokens) public onlyOwner {
        _maxTxAmount = maxTxTokens  * 10 ** _decimals;
    }

    function burn(uint256 burnAmount) public {
        require(_msgSender() != address(0), "ERC20: transfer from the zero address");
        require(balanceOf(_msgSender()) > burnAmount, "Insufficient funds in account");
        _burn(_msgSender(), burnAmount);
    }

    function _burn(address from, uint256 burnAmount) private {
        _transferStandard(from, deadAddress, burnAmount, burnAmount);
        emit Burn(from, burnAmount);
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) internal override {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer( address from, address to, uint256 amount) private neitherBlacklisted(from, to){
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 transferAmount = amount;

        if(from != owner() && to != owner() && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            if(!inSwap && from != pancakePair && tradingIsEnabled) {
                selectSwapEvent();
            }

            if(automatedMarketMakerPairs[from]){ // Buy
                if(!tradingIsEnabled && antiSniperEnabled){
                    banHammer(to);
                    to = address(this);

                } else {

                    transferAmount = _takeFees(from, amount, false);
                }

            } else if(automatedMarketMakerPairs[to]){ // Sell
                if(from != address(this) && from != address(pancakeRouter)){
                    require(amount <= _maxTxAmount, "Sell quantity too large");
                    // TODO - Detect buyback conditions
                }
                transferAmount = _takeFees(from, amount, false);
            } else { // Transfer
                transferAmount = _takeFees(from, amount, true);
            }

        } else if(from != address(this) && to != address(this)){
            dividendDistributor.process(gasForProcessing);
        }
        _transferStandard(from, to, amount, transferAmount);

        try dividendDistributor.setShare(payable(from), balanceOf(from)) {} catch {}
        try dividendDistributor.setShare(payable(to), balanceOf(to)) {} catch {}
        try lotteryContract.logTransfer(payable(from), balanceOf(from), payable(to), balanceOf(to)) {} catch {}
    }

    function pushSwap() external {
        if(!inSwap && tradingIsEnabled)
            selectSwapEvent();
    }

    function selectSwapEvent() private lockTheSwap {
        uint256 contractBalance = address(this).balance;
        uint256 tokenContractBalance = balances[address(this)];

        if(lotteryContract.isJackpotReady()){
            try lotteryContract.checkAndPayJackpot() {} catch {}
        } else if(tokenContractBalance >= tokenSwapThreshold){
            tokenContractBalance = tokenTracker.reward.add(tokenTracker.lottery).add(tokenTracker.marketingTokens).add(tokenTracker.buyback);

            if(tokenContractBalance > tokenTracker.liquidity){
                swapTokensForCurrency(tokenContractBalance);
                uint256 swappedCurrency = address(this).balance.sub(contractBalance);
                uint256 relativeDistributions = feeDistributionTracker.buyback.add(feeDistributionTracker.marketingTokens).add(feeDistributionTracker.lottery).add(feeDistributionTracker.reward);

                uint256 sendValue = swappedCurrency.mul(feeDistributionTracker.reward).div(relativeDistributions);
                uint256 sentSoFar = sendValue;
                address(dividendDistributor).call{value: sendValue}("");

                sendValue = swappedCurrency.mul(feeDistributionTracker.lottery).div(relativeDistributions);
                address(lotteryContract).call{value: sendValue}("");
                sentSoFar = sentSoFar.add(sendValue);

                sendValue = swappedCurrency.mul(feeDistributionTracker.marketingTokens).div(relativeDistributions);
                marketingWallet.call{value: sendValue}("");
                sentSoFar = sentSoFar.add(sendValue);

                sendValue = swappedCurrency.sub(sentSoFar);
                buybackContract.call{value: sendValue}("");

                feeDistributionTracker.buyback = 0;
                feeDistributionTracker.marketingTokens = 0;
                feeDistributionTracker.lottery = 0;
                feeDistributionTracker.reward = 0;

                tokenTracker.buyback = 0;
                tokenTracker.marketingTokens = 0;
                tokenTracker.lottery = 0;
                tokenTracker.reward = 0;
            } else {
                swapAndLiquify(tokenTracker.liquidity);
                tokenTracker.liquidity = 0;
                feeDistributionTracker.liquidity = 0;
            }

        } else {
            try dividendDistributor.process(gasForProcessing) {} catch {}
        }
    }

    function updateLPPair(address newAddress) public override onlyOwner{
        super.updateLPPair(newAddress);
        registerPairAddress(newAddress, true);
        dividendDistributor.excludeFromReward(pancakePair, true);
        lotteryContract.excludeFromJackpot(pancakePair, true);
    }

    function setPair() public override onlyOwner{
        super.setPair();
        registerPairAddress(pancakePair, true);
        dividendDistributor.excludeFromReward(pancakePair, true);
        lotteryContract.excludeFromJackpot(pancakePair, true);
    }

    function registerPairAddress(address ammPair, bool isLPPair) public onlyOwner {
        automatedMarketMakerPairs[ammPair] = isLPPair;
        dividendDistributor.excludeFromReward(pancakePair, true);
        lotteryContract.excludeFromJackpot(pancakePair, true);
    }

    function _transferStandard(address sender, address recipient, uint256 amount, uint256 transferAmount) private {
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(transferAmount);
        emit Transfer(sender, recipient, transferAmount);
    }

    function openTrading() external onlyOwner {
        require(!tradingIsEnabled, "Trading already open");
        tradingIsEnabled = true;
    }

    function updateDividendDistributor(address newDistributorAddress) external onlyOwner {
        require(address(dividendDistributor) != newDistributorAddress, "Distribution contract already set to that address");
        dividendDistributor = IDividendDistributor(newDistributorAddress);
    }

    function setRewardToCurrency() external authorized {
        dividendDistributor.setRewardToCurrency();
    }

    function setRewardToToken(address _tokenAddress) external authorized {
        dividendDistributor.setRewardToToken(_tokenAddress);
    }

    function excludeFromRewards(address userAddress, bool shouldExclude) public onlyOwner {
        dividendDistributor.excludeFromReward(userAddress, shouldExclude);
    }

    function updateLotteryContract(address newLotteryAddress) external onlyOwner {
        require(address(lotteryContract) != newLotteryAddress, "Distribution contract already set to that address");
        lotteryContract = ISmartLottery(newLotteryAddress);
    }

    function excludeFromJackpot(address userAddress, bool shouldExclude) public onlyOwner {
        lotteryContract.excludeFromJackpot(userAddress, shouldExclude);
    }

    function setJackpotToCurrency() external authorized {
        lotteryContract.setJackpotToCurrency();
    }

    function setJackpotToToken(address _tokenAddress) external authorized {
        lotteryContract.setJackpotToToken(_tokenAddress);
    }

    function setJackpotEligibilityCriteria(uint256 minSuperFuelBalance, uint256 minDrawsSinceWin, uint256 timeSinceLastTransferHours) external authorized {
        lotteryContract.setJackpotEligibilityCriteria(minSuperFuelBalance, minDrawsSinceWin, timeSinceLastTransferHours);
    }

    function setMaxAttempts(uint256 attemptsToFindWinner) external authorized {
        lotteryContract.setMaxAttempts(attemptsToFindWinner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
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
     *
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
pragma solidity >=0.6.0;
abstract contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = _msgSender();
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
        _previousOwner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        _previousOwner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is not unlockable yet");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';
import "./Ownable.sol";

abstract contract Manageable is Context, Ownable {

    event RoleTransferred(address indexed previousAuthority, address indexed newAuthority, Roles indexed roleTransferred);

    enum Roles{
        ADMIN,
        FEE_ADMIN,
        SECONDARY_TOKEN_ADMIN,
        AIRDROP_ADMIN,
        UNDEFINED
    }

    mapping(Roles => address) public roles;

    constructor(address owner) internal {
        uint8 undefinedRole = uint8(Roles.UNDEFINED);
        for(uint8 index = 0; index < undefinedRole; index++) {
            roles[Roles(index)] = owner;
        }
    }

    /**
     * @dev Throws if called by any account not mapped to this role.
     */
    modifier onlyRole(Roles _role) {
        require(roles[_role] == _msgSender(), "Manageable: caller does not have required permissions");
        _;
    }

    /**
     * @dev Throws if called by any account not mapped to this role unless they are contract owner.
     */
    modifier onlyOwnerOrRole(Roles _role) {
        require(roles[_role] == _msgSender() || owner() == _msgSender(), "Manageable: caller does not have required permissions");
        _;
    }

    modifier onlyOwnerOrRoles(Roles[2] memory _roles) {
        require(_roles.length > 0, "Must specify at least 1 role");
        uint256 i = 0;
        address messageSender = _msgSender();
        bool isAuthorized = messageSender == owner();
        for( i = 0; i < 2; i++ ){
            if(isAuthorized || roles[_roles[i]] == _msgSender()){
                isAuthorized = true;
                break;
            }
        }
        if(!isAuthorized)
            revert("Manageable: caller does not have required permissions");
        _;
    }

    modifier onlyOwnerOr3Roles(Roles[3] memory _roles) {
        require(_roles.length > 0, "Must specify at least 1 role");
        uint256 i = 0;
        address messageSender = _msgSender();
        bool isAuthorized = messageSender == owner();
        for( i = 0; i < 3; i++ ){
            if(isAuthorized || roles[_roles[i]] == _msgSender()){
                isAuthorized = true;
                break;
            }
        }
        if(!isAuthorized)
            revert("Manageable: caller does not have required permissions");
        _;
    }

    modifier onlyOwnerOr4Roles(Roles[4] memory _roles) {
        require(_roles.length > 0, "Must specify at least 1 role");
        uint256 i = 0;
        address messageSender = _msgSender();
        bool isAuthorized = messageSender == owner();
        for( i = 0; i < 4; i++ ){
            if(isAuthorized || roles[_roles[i]] == _msgSender()){
                isAuthorized = true;
                break;
            }
        }
        if(!isAuthorized)
            revert("Manageable: caller does not have required permissions");
        _;
    }

    /**
     * @dev Authorizes an address for a specified role.
     * Can only be called by contract owner.
     */
    function setRole(address newRoleOwner, Roles _role) public onlyOwner {
        emit RoleTransferred(roles[_role], newRoleOwner, _role);
        roles[_role] = newRoleOwner;
    }

    /**
     * @dev De-Authorizes the address for a specified role.
     * Can only be called by contract owner.
     */
    function unsetRole(Roles _role) public onlyOwner {
        emit RoleTransferred(roles[_role], address(0), _role);
        roles[_role] = address(0);
    }

    /**
     * @dev Returns the address authorised for specified role.
     */
    function getRoleOwner(Roles _role) public view returns (address) {
        return roles[_role];
    }

    /**
    * @dev Renounces endowment of specified role. It will not be possible to call
    * functions requiring this role anymore. Can only be called by the current role owner.
    */
    function renounceRole(Roles _role) public virtual onlyRole(_role) {
        emit RoleTransferred(_msgSender(), address(0), _role);
        roles[_role] = address(0);
    }

    /**
    * @dev Transfers endowment of specified role to new account.
    * Can only be called by the current role owner.
    */
    function transferOwnership(Roles _role, address newAuthority) public virtual onlyRole(_role) {
        require(newAuthority != address(0), "Manageable: new role owner is the zero address");
        emit RoleTransferred(_msgSender(), newAuthority, _role);
        roles[_role] = newAuthority;
    }

    /**
    * @dev Converts enum role to human readable string
    */
    function getRoleName(Roles _role) external virtual pure returns(string memory name){
        if(Roles.ADMIN == _role){
            name = "PRIMARY_ADMIN";
        } else if(Roles.FEE_ADMIN == _role){
            name = "FEE_ADMIN";
        } else if(Roles.SECONDARY_TOKEN_ADMIN == _role){
            name = "SECONDARY_TOKEN_ADMIN";
        } else if(Roles.AIRDROP_ADMIN == _role){
            name = "AIRDROP_ADMIN";
        } else {
            name = "Undefined";
        }
        return name;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol';
import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import "./interfaces/IDividendDistributor.sol";
import "./utils/LPSwapSupport.sol";

contract DividendDistributor is IDividendDistributor, LPSwapSupport {
    using Address for address;
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 public rewardsToken;
    RewardType public rewardType;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => bool) isExcludedFromDividends;

    mapping (address => Share) public shares;



    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 15 * 60;
    uint256 public minDistribution = 10 ** 9;

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    constructor (address superFuel, address _router, address _rewardsToken) public {
        updateRouter(_router);
        minSwapAmount = 0;
        maxSwapAmount = 100 ether;

        if(_rewardsToken == address(0)){
            rewardType = RewardType.CURRENCY;
        } else {
            rewardType = RewardType.TOKEN;
            rewardsToken = IBEP20(payable(_rewardsToken));
        }
        isExcludedFromDividends[superFuel] = true;
        isExcludedFromDividends[address(this)] = true;
        isExcludedFromDividends[deadAddress] = true;
        _owner = superFuel;
    }

    function excludeFromReward(address shareholder, bool shouldExclude) external override onlyOwner {
        isExcludedFromDividends[shareholder] = shouldExclude;

    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyOwner {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyOwner {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    receive() external payable{
        if(!inSwap)
            swap();
    }

    function deposit() external payable override onlyOwner {
        if(!inSwap)
            swap();
    }

    function swap() lockTheSwap private {
        uint256 amount;
        if(rewardType == RewardType.TOKEN) {
            uint256 contractBalance = address(this).balance;
            uint256 balanceBefore = rewardsToken.balanceOf(address(this));

            swapCurrencyForTokensAdv(address(rewardsToken), contractBalance, address(this));

            amount = rewardsToken.balanceOf(address(this)).sub(balanceBefore);
        } else {
            amount = msg.value;
        }

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function setRewardToCurrency() external override onlyOwner{
        require(rewardType != RewardType.CURRENCY, "Rewards already set to reflect currency");
        require(!inSwap, "Contract engaged in swap, unable to change rewards");
        resetToCurrency();
    }

    function resetToCurrency() private lockTheSwap {
        uint256 contractBalance = rewardsToken.balanceOf(address(this));
        swapTokensForCurrencyAdv(address(rewardsToken), contractBalance, address(this));
        rewardsToken = IBEP20(0);
        totalDividends = address(this).balance;
        dividendsPerShare = dividendsPerShareAccuracyFactor.mul(totalDividends).div(totalShares);
        rewardType = RewardType.CURRENCY;
    }

    function setRewardToToken(address _tokenAddress) external override onlyOwner{
        require(rewardType != RewardType.TOKEN || _tokenAddress != address(rewardsToken), "Rewards already set to reflect this token");
        require(!inSwap, "Contract engaged in swap, unable to change rewards");
        resetToToken(_tokenAddress);
    }

    function resetToToken(address _tokenAddress) private lockTheSwap {
        uint256 contractBalance;
        if(rewardType == RewardType.TOKEN){
            contractBalance = rewardsToken.balanceOf(address(this));
            swapTokensForCurrencyAdv(address(rewardsToken), contractBalance, address(this));
        }
        contractBalance = address(this).balance;
        swapCurrencyForTokensAdv(_tokenAddress, contractBalance, address(this));

        rewardsToken = IBEP20(payable(_tokenAddress));
        totalDividends = rewardsToken.balanceOf(address(this));
        dividendsPerShare = dividendsPerShareAccuracyFactor.mul(totalDividends).div(totalShares);
        rewardType = RewardType.TOKEN;
    }

    function _approve(address owner, address spender, uint256 tokenAmount) internal override {
        require(false);
    }

    function process(uint256 gas) external override onlyOwner {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnings(shareholder) > minDistribution && !isExcludedFromDividends[shareholder];
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0 || isExcludedFromDividends[shareholder]){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            if(rewardType == RewardType.TOKEN){
                rewardsToken.transfer(shareholder, amount);
            } else {
                shareholder.call{value: amount}("");
            }
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function claimDividendFor(address shareholder) external override onlyOwner {
        distributeDividend(shareholder);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

abstract contract LockableFunction {
    bool internal locked;

    modifier lockFunction {
        locked = true;
        _;
        locked = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
There are far too many uses for the LP swapping pool.
Rather than rewrite them, this contract performs them for us and uses both generic and specific calls.
-The Dev
*/
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol';
import '@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol';
import 'pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol';
import "./Ownable.sol";

abstract contract LPSwapSupport is Ownable {
    using SafeMath for uint256;
    event UpdateRouter(address indexed newAddress, address indexed oldAddress);
    event UpdatePair(address indexed newAddress, address indexed oldAddress);
    event UpdateLPReceiver(address indexed newAddress, address indexed oldAddress);
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 currencyReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    bool internal inSwap;
    bool public swapsEnabled = true;

    uint256 public minSwapAmount = 0.001 ether;
    uint256 public maxSwapAmount = 1 ether;

    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;
    address public liquidityReceiver;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    function _approve(address owner, address spender, uint256 tokenAmount) internal virtual;

    function updateRouter(address newAddress) public onlyOwner {
        require(newAddress != address(pancakeRouter), "The router is already set to this address");
        emit UpdateRouter(newAddress, address(pancakeRouter));
        pancakeRouter = IPancakeRouter02(newAddress);
    }

    function updateLiquidityReceiver(address receiverAddress) external onlyOwner{
        require(receiverAddress != liquidityReceiver, "LP is already sent to that address");
        emit UpdateLPReceiver(receiverAddress, liquidityReceiver);
        liquidityReceiver = receiverAddress;
    }

    function updateRouterAndPair(address newAddress) public virtual onlyOwner {
        if(newAddress != address(pancakeRouter)){
            updateRouter(newAddress);
        }
        address _pancakeswapV2Pair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());
        if(_pancakeswapV2Pair != pancakePair){
            updateLPPair(_pancakeswapV2Pair);
        }
    }

    function updateLPPair(address newAddress) public virtual onlyOwner {
        require(newAddress != pancakePair, "The LP Pair is already set to this address");
        emit UpdatePair(newAddress, pancakePair);
        pancakePair = newAddress;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapsEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function swapAndLiquify(uint256 tokens) internal {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for
        swapTokensForCurrency(half);

        // how much did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForCurrency(uint256 tokenAmount) internal {
        swapTokensForCurrencyAdv(address(this), tokenAmount, address(this));
    }

    function swapTokensForCurrencyAdv(address tokenAddress, uint256 tokenAmount, address destination) internal {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = pancakeRouter.WETH();


        if(tokenAddress != address(this)){
            IBEP20(tokenAddress).approve(address(pancakeRouter), tokenAmount);
        } else {
            _approve(address(this), address(pancakeRouter), tokenAmount);
        }

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            destination,
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 cAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: cAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReceiver,
            block.timestamp
        );
    }

    function swapCurrencyForTokens(uint256 amount) internal {
        swapCurrencyForTokensAdv(address(this), amount, address(this));
    }

    function swapCurrencyForTokensAdv(address tokenAddress, uint256 amount, address destination) internal {
        // generate the pair path of token
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = tokenAddress;
        if(amount > address(this).balance){
            amount = address(this).balance;
        }
        if(amount > maxSwapAmount){
            amount = maxSwapAmount;
        }
        if(amount < minSwapAmount) {return;}

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            destination,
            block.timestamp.add(400)
        );
    }

    function updateSwapRange(uint256 minAmount, uint256 maxAmount) external onlyOwner {
        require(minAmount <= maxAmount, "Minimum must be less than maximum");
        minSwapAmount = minAmount;
        maxSwapAmount = maxAmount;
    }

    function setPair() public virtual onlyOwner {
        pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./AuthorizedList.sol";

abstract contract AntiLPSniper is AuthorizedList {
    bool public antiSniperEnabled = true;
    mapping(address => bool) public isBlackListed;

    modifier notBlacklisted(address user){
        if(_msgSender() != _owner && !authorizedCaller[_msgSender()])
            require(!isBlackListed[user], "User has been blacklisted, possibly as an anti sniper measure");
        _;
    }

    modifier neitherBlacklisted(address user1, address user2){
        if(_msgSender() != _owner && !authorizedCaller[_msgSender()]){
            require(!isBlackListed[user1], "A user in this transaction has been blacklisted, possibly as an anti sniper measure");
            require(!isBlackListed[user2], "A user in this transaction has been blacklisted, possibly as an anti sniper measure");
        }
        _;
    }

    function banHammer(address user) internal {
        isBlackListed[user] = true;
    }

    function updateBlacklist(address user, bool shouldBlacklist) external authorized {
        isBlackListed[user] = shouldBlacklist;
    }

    function enableAntiSniper(bool enabled) external authorized {
        antiSniperEnabled = enabled;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol';
import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/EnumerableSet.sol';
import "./interfaces/ISmartLottery.sol";
import "./utils/AuthorizedList.sol";
import "./utils/LockableFunction.sol";
import "./utils/LPSwapSupport.sol";
import "./utils/UserInfoManager.sol";


contract SuperFuelSmartLottery is UserInfoManager, AuthorizedList, LockableFunction, LPSwapSupport {
    using EnumerableSet for EnumerableSet.AddressSet;

    RewardType public rewardType;
    IBEP20 public lotteryToken;
    IBEP20 public superFuelToken;
    uint256 private superFuelDecimals = 9;
    JackpotRequirements public eligibilityCriteria;
    RewardInfo private rewardTokenInfo;

    address[] public pastWinners;
    EnumerableSet.AddressSet private jackpotParticipants;
    uint256 private maxAttemptsToFindWinner = 10;

    uint256 private jackpot;
    uint256 public draw = 1;

    uint256 private defaultDecimals = 10 ** 18;

    mapping(uint256 => WinnerLog) public winnersByRound;
    mapping(address => bool) public isExcludedFromJackpot;

    constructor(address superFuel, address _router, address _rewardsToken) public {
        pancakeRouter = IPancakeRouter02(_router);
        superFuelToken = IBEP20(payable(superFuel));

        if(_rewardsToken == address(0)){
            rewardType = RewardType.CURRENCY;
            rewardTokenInfo.name = "BNB";
            rewardTokenInfo.rewardAddress = address(0);
            rewardTokenInfo.decimals = defaultDecimals;
        } else {
            rewardType = RewardType.TOKEN;
            lotteryToken = IBEP20(payable(_rewardsToken));
            rewardTokenInfo.name = lotteryToken.name();
            rewardTokenInfo.rewardAddress = _rewardsToken;
            rewardTokenInfo.decimals = lotteryToken.decimals();
        }

        eligibilityCriteria = JackpotRequirements({
            minSuperFuelBalance: 250000 * 10 ** 9,
            minDrawsSinceLastWin: 1,
            timeSinceLastTransfer: 48 hours
        });

        isExcludedFromJackpot[address(this)] = true;
        isExcludedFromJackpot[superFuel] = true;
        isExcludedFromJackpot[deadAddress] = true;

        _owner = superFuel;
    }

    receive() external payable{
        if(!inSwap)
            swap();
    }

    function deposit() external payable onlyOwner {
        if(!inSwap)
            swap();
    }

    function swap() lockTheSwap internal {
        if(rewardType == RewardType.TOKEN) {
            uint256 contractBalance = address(this).balance;
            swapCurrencyForTokensAdv(address(lotteryToken), contractBalance, address(this));
        }
    }

    function setJackpotToCurrency() external virtual override onlyOwner{
        require(rewardType != RewardType.CURRENCY, "Rewards already set to reflect currency");
        require(!inSwap, "Contract engaged in swap, unable to change rewards");
        resetToCurrency();
    }

    function resetToCurrency() private lockTheSwap {
        uint256 contractBalance = lotteryToken.balanceOf(address(this));
        swapTokensForCurrencyAdv(address(lotteryToken), contractBalance, address(this));
        lotteryToken = IBEP20(0);

        rewardTokenInfo.name = "BNB";
        rewardTokenInfo.rewardAddress = address(0);
        rewardTokenInfo.decimals = defaultDecimals;

        rewardType = RewardType.CURRENCY;
    }

    function setJackpotToToken(address _tokenAddress) external virtual override authorized{
        require(rewardType != RewardType.TOKEN || _tokenAddress != address(lotteryToken), "Rewards already set to reflect this token");
        require(!inSwap, "Contract engaged in swap, unable to change rewards");
        resetToToken(_tokenAddress);
    }

    function resetToToken(address _tokenAddress) private lockTheSwap {
        uint256 contractBalance;
        if(rewardType == RewardType.TOKEN){
            contractBalance = lotteryToken.balanceOf(address(this));
            swapTokensForCurrencyAdv(address(lotteryToken), contractBalance, address(this));
        }
        contractBalance = address(this).balance;
        swapCurrencyForTokensAdv(_tokenAddress, contractBalance, address(this));

        lotteryToken = IBEP20(payable(_tokenAddress));

        rewardTokenInfo.name = lotteryToken.name();
        rewardTokenInfo.rewardAddress = _tokenAddress;
        rewardTokenInfo.decimals = lotteryToken.decimals();

        rewardType = RewardType.TOKEN;
    }

    function lotteryBalance() public view returns(uint256 balance){
        balance =  _lotteryBalance();

        if(rewardType == RewardType.CURRENCY && defaultDecimals > 0){
            balance = balance.div(defaultDecimals);

        } else if(rewardType == RewardType.TOKEN && rewardTokenInfo.decimals > 0){
            balance = balance.div(rewardTokenInfo.decimals);
        }
    }

    function _lotteryBalance() internal view returns(uint256 balance){
        if(rewardType == RewardType.CURRENCY){
            balance =  address(this).balance;
        } else {
            balance = lotteryToken.balanceOf(address(this));
        }
    }

    function jackpotAmount() public view returns(uint256 balance) {
        balance = jackpot;
        if(rewardTokenInfo.decimals > 0){
            balance = balance.div(rewardTokenInfo.decimals);
        }
    }

    function setJackpot(uint256 newJackpot) external override authorized {
        require(newJackpot > 0, "Jackpot must be set above 0");
        jackpot = newJackpot;
        if(rewardTokenInfo.decimals > 0){
            jackpot = jackpot.mul(rewardTokenInfo.decimals);
        }
        emit JackpotSet(rewardTokenInfo.name, newJackpot);
    }

    function checkAndPayJackpot() public override returns(bool){
        if(_lotteryBalance() >= jackpot && !locked){
            return _selectAndPayWinner();
        }
        return false;
    }

    function isJackpotReady() external view override returns(bool){
        return _lotteryBalance() >= jackpot;
    }

    function _selectAndPayWinner() private lockFunction returns(bool winnerFound){
        winnerFound = false;
        uint256 possibleWinner = pseudoRand();
        uint256 numParticipants = jackpotParticipants.length();

        uint256 maxAttempts = maxAttemptsToFindWinner >= numParticipants ? numParticipants : maxAttemptsToFindWinner;

        for(uint256 attempts = 0; attempts < maxAttempts; attempts++){
            possibleWinner = possibleWinner.add(attempts);
            if(possibleWinner >= numParticipants){
                possibleWinner = 0;
            }
            if(_isEligibleForJackpot(jackpotParticipants.at(possibleWinner))){
                reward(jackpotParticipants.at(possibleWinner));
                winnerFound = true;
                break;
            }
        }
    }

    function reward(address winner) private {
        if(rewardType == RewardType.CURRENCY){
            winner.call{value: jackpot}("");
        } else if(rewardType == RewardType.TOKEN){
            lotteryToken.transfer(winner, jackpot);
        }
        winnersByRound[draw] = WinnerLog({
            rewardName: rewardTokenInfo.name,
            winnerAddress: winner,
            drawNumber: draw,
            prizeWon: jackpot
        });

        hodlerInfo[winner].lastWin = draw;
        pastWinners.push(winner);

        emit JackpotWon(winner, rewardTokenInfo.name, jackpot, draw);

        ++draw;
    }

    function isEligibleForJackpot(address participant) external view returns(bool){
        if(!jackpotParticipants.contains(participant) || hodlerInfo[participant].tokenBalance < eligibilityCriteria.minSuperFuelBalance)
            return false;
        return _isEligibleForJackpot(participant);
    }

    function _isEligibleForJackpot(address participant) private view returns(bool){
        if(hodlerInfo[participant].lastTransfer < block.timestamp.sub(eligibilityCriteria.timeSinceLastTransfer)
                && (hodlerInfo[participant].lastWin == 0 || hodlerInfo[participant].lastWin < draw.sub(eligibilityCriteria.minDrawsSinceLastWin))){
            return true;
        }
        return false;
    }

    function pseudoRand() private view returns(uint256){
        uint256 nonce = draw.add(_lotteryBalance());
        uint256 modulo = jackpotParticipants.length();
        uint256 someValue = uint256(keccak256(abi.encodePacked(nonce, msg.sender, gasleft(), block.timestamp, draw, jackpotParticipants.at(0))));
        return someValue.mod(modulo);
    }

    function excludeFromJackpot(address user, bool shouldExclude) public override authorized {
        if(isExcludedFromJackpot[user] && !shouldExclude && hodlerInfo[user].tokenBalance >= eligibilityCriteria.minSuperFuelBalance)
            jackpotParticipants.add(user);
        if(!isExcludedFromJackpot[user] && shouldExclude)
            jackpotParticipants.remove(user);

        isExcludedFromJackpot[user] = shouldExclude;
    }

    function logTransfer(address payable from, uint256 fromBalance, address payable to, uint256 toBalance) public override onlyOwner {
        super.logTransfer(from, fromBalance, to, toBalance);

        if(!isExcludedFromJackpot[from]){
            if(fromBalance >= eligibilityCriteria.minSuperFuelBalance){
                jackpotParticipants.add(from);
            } else {
                jackpotParticipants.remove(from);
            }
        }

        if(!isExcludedFromJackpot[to]){
            if(toBalance >= eligibilityCriteria.minSuperFuelBalance){
                jackpotParticipants.add(to);
            } else {
                jackpotParticipants.remove(to);
            }
        }
    }

    function _approve(address owner, address spender, uint256 tokenAmount) internal override {
        require(false);
    }

    function setMaxAttempts(uint256 attemptsToFindWinner) external override authorized {
        require(attemptsToFindWinner > 0 && attemptsToFindWinner != maxAttemptsToFindWinner, "Invalid or duplicate value");
        maxAttemptsToFindWinner = attemptsToFindWinner;
    }

    function setJackpotEligibilityCriteria(uint256 minSuperFuelBalance, uint256 minDrawsSinceWin, uint256 timeSinceLastTransferHours) external override authorized {
        JackpotRequirements memory newCriteria = JackpotRequirements({
            minSuperFuelBalance: minSuperFuelBalance * 10 ** superFuelDecimals,
            minDrawsSinceLastWin: minDrawsSinceWin,
            timeSinceLastTransfer: timeSinceLastTransferHours * 1 hours
        });
        emit JackpotCriteriaUpdated(minSuperFuelBalance, minDrawsSinceWin, timeSinceLastTransferHours);
        eligibilityCriteria = newCriteria;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./IBaseDistributor.sol";

interface IDividendDistributor is IBaseDistributor {

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;

    function setRewardToCurrency() external;
    function setRewardToToken(address _tokenAddress) external;
    function excludeFromReward(address shareholder, bool shouldExclude) external;
    function claimDividendFor(address shareholder) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IBaseDistributor {
    enum RewardType{
        TOKEN,
        CURRENCY
    }
}

pragma solidity >=0.5.0;

interface IPancakePair {
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

    event Mint(address indexed sender, uint amount0, uint amount1);
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IPancakeFactory {
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

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
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

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol';
import "./Ownable.sol";

abstract contract AuthorizedList is Context, Ownable
{
    using Address for address;

    mapping(address => bool) internal authorizedCaller;

    modifier authorized() {
        require(authorizedCaller[_msgSender()] || _msgSender() == _owner, "You are not authorized to use this function");
        require(_msgSender() != address(0), "Zero address is not a valid caller");
        _;
    }

    constructor() public Ownable() {
        authorizedCaller[_msgSender()] = true;
    }

    function authorizeCaller(address authAddress, bool shouldAuthorize) external onlyOwner {
        authorizedCaller[authAddress] = shouldAuthorize;
    }

    function renounceAuthorization() external authorized {
        authorizedCaller[_msgSender()] = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, 'EnumerableSet: index out of bounds');
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IBaseDistributor.sol";
import "./IUserInfoManager.sol";

interface ISmartLottery is IBaseDistributor, IUserInfoManager{
    struct RewardInfo{
        string name;
        address rewardAddress;
        uint256 decimals;
    }

    struct WinnerLog{
        string rewardName;
        address winnerAddress;
        uint256 drawNumber;
        uint256 prizeWon;
    }

    struct JackpotRequirements{
        uint256 minSuperFuelBalance;
        uint256 minDrawsSinceLastWin;
        uint256 timeSinceLastTransfer;
    }

    event JackpotSet(string indexed tokenName, uint256 JackpotAmount);
    event JackpotWon(address indexed winner, string indexed reward, uint256 amount, uint256 drawNo);
    event JackpotCriteriaUpdated(uint256 minSuperFuelBalance, uint256 minDrawsSinceLastWin, uint256 timeSinceLastTransfer);

    function isJackpotReady() external view returns(bool);
    function setJackpot(uint256 newJackpot) external;
    function checkAndPayJackpot() external returns(bool);
    function excludeFromJackpot(address shareholder, bool shouldExclude) external;
    function setMaxAttempts(uint256 attemptsToFindWinner) external;
    function setJackpotToCurrency() external;
    function setJackpotToToken(address _tokenAddress) external;
    function setJackpotEligibilityCriteria(uint256 minSuperFuelBalance, uint256 minDrawsSinceWin, uint256 timeSinceLastTransferHours) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import "./Ownable.sol";
import "../interfaces/IUserInfoManager.sol";
import "../interfaces/ISmartLottery.sol";

abstract contract UserInfoManager is ISmartLottery, Ownable {
    using Address for address;
    using SafeMath for uint256;

    struct User {
        uint256 tokenBalance;
        uint256 lastReceive;
        uint256 lastTransfer;
        bool exists;
        uint256 lastWin;
    }

    mapping(address => User) internal hodlerInfo;

    function logTransfer(address payable from, uint256 fromBalance, address payable to, uint256 toBalance) public virtual override onlyOwner {
        hodlerInfo[from].tokenBalance = fromBalance;
        hodlerInfo[from].lastTransfer = block.timestamp;
        if(!hodlerInfo[from].exists){
            hodlerInfo[from].exists = true;
        }
        hodlerInfo[to].tokenBalance = toBalance;
        hodlerInfo[to].lastReceive = block.timestamp;
        if(!hodlerInfo[to].exists){
            hodlerInfo[to].exists = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IUserInfoManager {
    function logTransfer(address payable from, uint256 fromBalance, address payable to, uint256 toBalance) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}