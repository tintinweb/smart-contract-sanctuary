// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol';
import "./interfaces/ISuperFuelReflector.sol";
import "./interfaces/ISmartLottery.sol";
import "./utils/LockableFunction.sol";
import "./utils/AntiLPSniper.sol";
import "./SmartBuyback.sol";
import "./interfaces/ISupportingTokenInjection.sol";

contract SuperFuel is IBEP20, ISupportingTokenInjection, AntiLPSniper, LockableFunction, SmartBuyback {
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;

    event Burn(address indexed from, uint256 tokensBurned);

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

    uint8 private initSteps = 2;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) private automatedMarketMakerPairs;

    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private  _totalSupply;

    bool tradingIsEnabled;

    // Trackers for various pending token swaps and fees
    Fees public buySellFees;
    Fees public transferFees;
    TokenTracker public tokenTracker;

    uint256 public _maxTxAmount;
    uint256 public tokenSwapThreshold;

    uint256 public gasForProcessing = 400000;

    address payable public marketingWallet;
    ISmartLottery public lotteryContract;
    ISuperFuelReflector public reflectorContract;

    constructor (uint256 _supply, address routerAddress, address tokenOwner, address _marketingWallet) AuthorizedList() public {
        _name = "SuperFuel";
        _symbol = "SFUEL";
        _decimals = 9;
        _totalSupply = _supply * 10 ** _decimals;

        swapsEnabled = false;

        _maxTxAmount = _totalSupply.mul(3).div(100);
        tokenSwapThreshold = _maxTxAmount.div(400);

        liquidityReceiver = deadAddress;

        marketingWallet = payable(_marketingWallet);
        pancakeRouter = IPancakeRouter02(routerAddress);

        buySellFees = Fees({
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

        address owner1 = address(0x8427F4702831667Fd58Fb5a652F1c795e2B8E942);
        address owner2 = address(0xa4a91638919a45A0B485DBb57D6BFdeA9051B129);
        //exclude owner and this contract from fee
        _isExcludedFromFee[tokenOwner] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[deadAddress] = true;
        _isExcludedFromFee[owner1] = true;
        _isExcludedFromFee[owner2] = true;
        authorizedCaller[owner1] = true;
        authorizedCaller[owner2] = true;

        uint256 twoPointFivePercent = _totalSupply.mul(25).div(1000);
        balances[owner1] = twoPointFivePercent;
        emit Transfer(address(this), owner1, twoPointFivePercent);
        balances[owner2] = twoPointFivePercent;
        emit Transfer(address(this), owner2, twoPointFivePercent);
        balances[marketingWallet] = twoPointFivePercent.mul(2);
        emit Transfer(address(this), marketingWallet, balances[marketingWallet]);
        _owner = tokenOwner;
        balances[tokenOwner] = _totalSupply.sub(balances[owner1]).sub(balances[owner2]).sub(balances[marketingWallet]);
        emit Transfer(address(this), _owner, balances[_owner]);
    }

    function init(address payable _dividendContract, address payable _lotteryContract, address payable _injectorAddress) external authorized {
        require(initSteps > 0, "Contract already initialized");

        if(initSteps == 2) {
            pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());
            automatedMarketMakerPairs[pancakePair] = true;
        } else if(initSteps == 1){
            reflectorContract = ISuperFuelReflector(_dividendContract);
            lotteryContract = ISmartLottery(_lotteryContract);

            _isExcludedFromFee[address(_dividendContract)] = true;
            _isExcludedFromFee[address(_lotteryContract)] = true;
            _isExcludedFromFee[address(_injectorAddress)] = true;

            reflectorContract.excludeFromReward(pancakePair, true);
            reflectorContract.excludeFromReward(_lotteryContract, true);
            reflectorContract.excludeFromReward(_injectorAddress, true);

            lotteryContract.excludeFromJackpot(pancakePair, true);
            lotteryContract.excludeFromJackpot(_dividendContract, true);
            lotteryContract.excludeFromJackpot(marketingWallet, true);
            lotteryContract.excludeFromJackpot(_injectorAddress, true);

            emit Transfer(address(this), address(_injectorAddress), balances[address(_injectorAddress)]);
            authorizedCaller[_msgSender()] = false;
        }
        --initSteps;
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

    function setMarketingWallet(address _marketingWallet) public onlyOwner {
        marketingWallet = payable(_marketingWallet);
    }

    function getOwner() external override view returns(address){
        return owner();
    }

    function updateGasForProcessing(uint256 newValue) public authorized {
        require(newValue >= 200000 && newValue <= 1000000, "Gas requirement is between 200,000 and 1,000,000");
        require(newValue != gasForProcessing, "Gas requirement already set to that value");
        gasForProcessing = newValue;
    }

    function excludeFromFee(address account, bool shouldExclude) public onlyOwner {
        _isExcludedFromFee[account] = shouldExclude;
    }

    function _calculateFees(uint256 amount, bool isTransfer) private view returns(uint256 liquidityFee, uint256 marketingFee, uint256 buybackFee, uint256 reflectionFee, uint256 lotteryFee) {
        Fees memory _fees;
        if(isTransfer)
            _fees = transferFees;
        else
            _fees = buySellFees;
        liquidityFee = amount.mul(_fees.liquidity).div(_fees.divisor);
        marketingFee = amount.mul(_fees.marketing).div(_fees.divisor);
        buybackFee = amount.mul(_fees.buyback).div(_fees.divisor);
        reflectionFee = amount.mul(_fees.tokenReflection).div(_fees.divisor);
        lotteryFee = amount.mul(_fees.lottery).div(_fees.divisor);
    }

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
        buySellFees = Fees({
            liquidity: _liquidity,
            marketing: _marketing,
            tokenReflection: _tokenReflection,
            buyback: _buyback,
            lottery: _lottery,
            divisor: _divisor
        });
    }

    function setTokenSwapThreshold(uint256 minTokensBeforeTransfer) public authorized {
        tokenSwapThreshold = minTokensBeforeTransfer * 10 ** _decimals;
    }

    function setMaxSellTx(uint256 maxTxTokens) public authorized {
        _maxTxAmount = maxTxTokens  * 10 ** _decimals;
    }

    function burn(uint256 burnAmount) public override {
        require(_msgSender() != address(0), "BEP20: transfer from the zero address");
        require(balanceOf(_msgSender()) > burnAmount, "Insufficient funds in account");
        _burn(_msgSender(), burnAmount);
    }

    function _burn(address from, uint256 burnAmount) private {
        _transferStandard(from, deadAddress, burnAmount, burnAmount);
        emit Burn(from, burnAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal override {
        require(owner != address(0) && spender != address(0), "BEP20: Approve involves the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0) && to != address(0), "BEP20: Transfer involves the zero address");
        require(!isBlackListed[to] && !isBlackListed[from], "Address blacklisted and cannot trade");
        require(initSteps == 0, "Contract is not fully initialized");
        if(amount == 0){
            _transferStandard(from, to, 0, 0);
        }
        uint256 transferAmount = amount;
        bool tryBuyback;

        if(from != owner() && to != owner() && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            if(automatedMarketMakerPairs[from]){ // Buy
                if(!tradingIsEnabled && antiSniperEnabled){
                    banHammer(to);
                    to = address(this);
                } else {
                    transferAmount = _takeFees(from, amount, false);
                }

            } else if(automatedMarketMakerPairs[to]){ // Sell
                require(tradingIsEnabled, "Trading is not enabled");
                if(from != address(this) && from != address(pancakeRouter)){
                    require(amount <= _maxTxAmount, "Sell quantity too large");
                    tryBuyback = shouldBuyback(balanceOf(pancakePair), amount);
                    transferAmount = _takeFees(from, amount, false);
                }
            } else { // Transfer
                transferAmount = _takeFees(from, amount, true);
            }

        } else if(from != address(this) && to != address(this) && tradingIsEnabled){
            reflectorContract.process(gasForProcessing);
        }

        try reflectorContract.setShare(payable(from), balanceOf(from)) {} catch {}
        try reflectorContract.setShare(payable(to), balanceOf(to)) {} catch {}
        try lotteryContract.logTransfer(payable(from), balanceOf(from), payable(to), balanceOf(to)) {} catch {}
        if(tryBuyback){
            doBuyback(balanceOf(pancakePair), amount);
        } else if(!inSwap && from != pancakePair && from != address(pancakeRouter) && tradingIsEnabled) {
            selectSwapEvent();
            try reflectorContract.claimDividendFor(from) {} catch {}
        }

        _transferStandard(from, to, amount, transferAmount);
    }

    function pushSwap() external {
        if(!inSwap && tradingIsEnabled)
            selectSwapEvent();
    }

    function selectSwapEvent() private lockTheSwap {
        if(!swapsEnabled){return;}
        uint256 contractBalance = address(this).balance;

        if(tokenTracker.reward >= tokenSwapThreshold){

            uint256 toSwap = tokenTracker.reward > _maxTxAmount ? _maxTxAmount : tokenTracker.reward;
            swapTokensForCurrency(toSwap);
            uint256 swappedCurrency = address(this).balance.sub(contractBalance);
            reflectorContract.deposit{value: swappedCurrency}();
            tokenTracker.reward = tokenTracker.reward.sub(toSwap);

        } else if(tokenTracker.buyback >= tokenSwapThreshold){

            uint256 toSwap = tokenTracker.buyback > _maxTxAmount ? _maxTxAmount : tokenTracker.buyback;
            swapTokensForCurrency(toSwap);
            tokenTracker.buyback = tokenTracker.buyback.sub(toSwap);

        } else if(tokenTracker.lottery >= tokenSwapThreshold){

            uint256 toSwap = tokenTracker.lottery > _maxTxAmount ? _maxTxAmount : tokenTracker.lottery;
            swapTokensForCurrency(toSwap);
            uint256 swappedCurrency = address(this).balance.sub(contractBalance);
            lotteryContract.deposit{value: swappedCurrency}();
            tokenTracker.lottery = tokenTracker.lottery.sub(toSwap);

        } else if(tokenTracker.liquidity >= tokenSwapThreshold){

            uint256 toSwap = tokenTracker.liquidity > _maxTxAmount ? _maxTxAmount : tokenTracker.liquidity;
            swapAndLiquify(tokenTracker.liquidity);
            tokenTracker.liquidity = tokenTracker.liquidity.sub(toSwap);

        } else if(tokenTracker.marketingTokens >= tokenSwapThreshold){

            uint256 toSwap = tokenTracker.marketingTokens > _maxTxAmount ? _maxTxAmount : tokenTracker.marketingTokens;
            swapTokensForCurrency(toSwap);
            uint256 swappedCurrency = address(this).balance.sub(contractBalance);
            address(marketingWallet).call{value: swappedCurrency}("");
            tokenTracker.marketingTokens = tokenTracker.marketingTokens.sub(toSwap);

        }
        try lotteryContract.checkAndPayJackpot() {} catch {}
        try reflectorContract.process(gasForProcessing) {} catch {}
    }

    function authorizeCaller(address authAddress, bool shouldAuthorize) external override onlyOwner {
        authorizedCaller[authAddress] = shouldAuthorize;

        lotteryContract.authorizeCaller(authAddress, shouldAuthorize);
        reflectorContract.authorizeCaller(authAddress, shouldAuthorize);

        emit AuthorizationUpdated(authAddress, shouldAuthorize);
    }

    function updateLPPair(address newAddress) public override onlyOwner {
        super.updateLPPair(newAddress);
        registerPairAddress(newAddress, true);
        reflectorContract.excludeFromReward(pancakePair, true);
        lotteryContract.excludeFromJackpot(pancakePair, true);
    }

    function registerPairAddress(address ammPair, bool isLPPair) public authorized {
        automatedMarketMakerPairs[ammPair] = isLPPair;
        reflectorContract.excludeFromReward(pancakePair, true);
        lotteryContract.excludeFromJackpot(pancakePair, true);
    }

    function _transferStandard(address sender, address recipient, uint256 amount, uint256 transferAmount) private {
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(transferAmount);
        emit Transfer(sender, recipient, transferAmount);
    }

    function openTrading() external authorized {
        require(!tradingIsEnabled, "Trading already open");
        tradingIsEnabled = true;
        swapsEnabled = true;
        autoBuybackEnabled = true;
        autoBuybackAtCap = true;
    }

    function updateReflectionContract(address newReflectorAddress) external onlyOwner {
        reflectorContract = ISuperFuelReflector(newReflectorAddress);
    }

    function updateLotteryContract(address newLotteryAddress) external onlyOwner {
        lotteryContract = ISmartLottery(newLotteryAddress);
    }

    function excludeFromJackpot(address userAddress, bool shouldExclude) external onlyOwner {
        lotteryContract.excludeFromJackpot(userAddress, shouldExclude);
    }

    function excludeFromRewards(address userAddress, bool shouldExclude) external onlyOwner {
        reflectorContract.excludeFromReward(userAddress, shouldExclude);
    }

    function reflections() external view returns(string memory){
        return reflectorContract.rewardCurrency();
    }
    function jackpot() external view returns(string memory){
        return lotteryContract.rewardCurrency();
    }

    function depositTokens(uint256 liquidityDeposit, uint256 rewardsDeposit, uint256 jackpotDeposit, uint256 buybackDeposit) external override {
        require(balanceOf(_msgSender()) >= (liquidityDeposit.add(rewardsDeposit).add(jackpotDeposit).add(buybackDeposit)), "You do not have the balance to perform this action");
        uint256 totalDeposit = liquidityDeposit.add(rewardsDeposit).add(jackpotDeposit).add(buybackDeposit);
        _transferStandard(_msgSender(), address(this), totalDeposit, totalDeposit);
        tokenTracker.liquidity = tokenTracker.liquidity.add(liquidityDeposit);
        tokenTracker.reward = tokenTracker.reward.add(rewardsDeposit);
        tokenTracker.lottery = tokenTracker.lottery.add(jackpotDeposit);
        tokenTracker.buyback = tokenTracker.buyback.add(buybackDeposit);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./IBaseDistributor.sol";
import "../utils/AuthorizedList.sol";

interface ISuperFuelReflector is IBaseDistributor, IAuthorizedListExt, IAuthorizedList {

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function process(uint256 gas) external;

    function setRewardToCurrency(bool andSwap) external;
    function setRewardToToken(address _tokenAddress, bool andSwap) external;
    function excludeFromReward(address shareholder, bool shouldExclude) external;
    function claimDividendFor(address shareholder) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IBaseDistributor.sol";
import "./IUserInfoManager.sol";
import "./IAuthorizedList.sol";

interface ISmartLottery is IBaseDistributor, IAuthorizedListExt, IAuthorizedList {
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

    function draw() external pure returns(uint256);
    function jackpotAmount() external view returns(uint256);
    function isJackpotReady() external view returns(bool);
    function setJackpot(uint256 newJackpot) external;
    function checkAndPayJackpot() external returns(bool);
    function excludeFromJackpot(address shareholder, bool shouldExclude) external;
    function setMaxAttempts(uint256 attemptsToFindWinner) external;

    function setJackpotToCurrency(bool andSwap) external;
    function setJackpotToToken(address _tokenAddress, bool andSwap) external;
    function setJackpotEligibilityCriteria(uint256 minSuperFuelBalance, uint256 minDrawsSinceWin, uint256 timeSinceLastTransferHours) external;
    function logTransfer(address payable from, uint256 fromBalance, address payable to, uint256 toBalance) external;
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
pragma solidity ^0.6.0;

import "./AuthorizedList.sol";

contract AntiLPSniper is AuthorizedList {
    bool public antiSniperEnabled = true;
    mapping(address => bool) public isBlackListed;

    function banHammer(address user) internal {
        isBlackListed[user] = true;
    }

    function updateBlacklist(address user, bool shouldBlacklist) external onlyOwner {
        isBlackListed[user] = shouldBlacklist;
    }

    function enableAntiSniper(bool enabled) external authorized {
        antiSniperEnabled = enabled;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./utils/AuthorizedList.sol";
import "./utils/LPSwapSupport.sol";

abstract contract SmartBuyback is AuthorizedList, LPSwapSupport{
    event BuybackTriggered(uint256 amountSpent);
    event BuybackReceiverUpdated(address indexed oldReceiver, address indexed newReceiver);

    uint256 public minAutoBuyback = 0.05 ether;
    uint256 public maxAutoBuyback = 10 ether;
    uint256 private significantLPBuyPct = 1;
    uint256 private significantLPBuyPctDivisor = 100;
    bool public autoBuybackEnabled;
    bool public autoBuybackAtCap = true;
    bool public doSimpleBuyback;
    address public buybackReceiver = deadAddress;
    uint256 private lastBuybackAmount;
    uint256 private lastBuybackTime;
    uint256 private lastBuyPoolSize;

    function shouldBuyback(uint256 poolTokens, uint256 sellAmount) public view returns(bool){
        return (poolTokens.mul(significantLPBuyPct).div(significantLPBuyPctDivisor) >= sellAmount && autoBuybackEnabled
            && address(this).balance >= minAutoBuyback) || (autoBuybackAtCap && address(this).balance >= maxAutoBuyback);
    }

    function doBuyback(uint256 poolTokens, uint256 sellAmount) internal {
        if(autoBuybackEnabled && !inSwap && address(this).balance >= minAutoBuyback)
            _doBuyback(poolTokens, sellAmount);
    }

    function _doBuyback(uint256 poolTokens, uint256 sellAmount) private lockTheSwap {
        uint256 lpMin = minSpendAmount;
        uint256 lpMax = maxSpendAmount;
        minSpendAmount = minAutoBuyback;
        maxSpendAmount = maxAutoBuyback;
        if(autoBuybackAtCap && address(this).balance >= maxAutoBuyback){
            simpleBuyback(poolTokens, 0);
        } else if(doSimpleBuyback){
            simpleBuyback(poolTokens, sellAmount);
        } else {
            dynamicBuyback(poolTokens, sellAmount);
        }
        minSpendAmount = lpMin;
        maxSpendAmount = lpMax;
    }

    function _doBuybackNoLimits(uint256 amount) private lockTheSwap {
        uint256 lpMin = minSpendAmount;
        uint256 lpMax = maxSpendAmount;
        minSpendAmount = 0;
        maxSpendAmount = amount;
        swapCurrencyForTokensAdv(address(this), amount, buybackReceiver);
        emit BuybackTriggered(amount);
        minSpendAmount = lpMin;
        maxSpendAmount = lpMax;
    }

    function simpleBuyback(uint256 poolTokens, uint256 sellAmount) private {
        uint256 amount = address(this).balance > maxAutoBuyback ? maxAutoBuyback : address(this).balance;
        if(amount >= minAutoBuyback){
            if(sellAmount == 0){
                amount = minAutoBuyback;
            }
            swapCurrencyForTokensAdv(address(this), amount, buybackReceiver);
            emit BuybackTriggered(amount);
            lastBuybackAmount = amount;
            lastBuybackTime = block.timestamp;
            lastBuyPoolSize = poolTokens;
        }
    }

    function dynamicBuyback(uint256 poolTokens, uint256 sellAmount) private {
        if(lastBuybackTime == 0){
            simpleBuyback(poolTokens, sellAmount);
        }
        uint256 amount = sellAmount.mul(address(pancakePair).balance).div(poolTokens);
        if(lastBuyPoolSize < poolTokens){
            amount = amount.add(amount.mul(poolTokens).div(poolTokens.add(lastBuyPoolSize)));
        }

        swapCurrencyForTokensAdv(address(this), amount, buybackReceiver);
        emit BuybackTriggered(amount);
        lastBuybackAmount = amount;
        lastBuybackTime = block.timestamp;
        lastBuyPoolSize = poolTokens;
    }

    function enableAutoBuybacks(bool enable, bool autoBuybackAtCapEnabled) external authorized {
        autoBuybackEnabled = enable;
        autoBuybackAtCap = autoBuybackAtCapEnabled;
    }

    function updateBuybackSettings(uint256 lpSizePct, uint256 pctDivisor, bool simpleBuybacksOnly) external authorized{
        significantLPBuyPct = lpSizePct;
        significantLPBuyPctDivisor = pctDivisor;
        doSimpleBuyback = simpleBuybacksOnly;
    }

    function updateBuybackLimits(uint256 minBuyAmount, uint256 maxBuyAmount) external authorized {
        minAutoBuyback = minBuyAmount;
        maxAutoBuyback = maxBuyAmount;
    }

    function forceBuyback(uint256 amount) external authorized {
        require(address(this).balance >= amount);
        if(!inSwap){
            _doBuybackNoLimits(amount);
        }
    }

    function updateBuybackReceiver(address newReceiver) external onlyOwner {
        emit BuybackReceiverUpdated(buybackReceiver, newReceiver);
        buybackReceiver = newReceiver;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface ISupportingTokenInjection {
    function depositTokens(uint256 liquidityDeposit, uint256 rewardsDeposit, uint256 jackpotDeposit, uint256 buybackDeposit) external;
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IBaseDistributor {
    enum RewardType{
        TOKEN,
        CURRENCY
    }

    struct RewardInfo{
        string name;
        address rewardAddress;
        uint256 decimals;
    }

    function deposit() external payable;
    function rewardCurrency() external view returns(string memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol';
import "./Ownable.sol";
import "../interfaces/IAuthorizedList.sol";

contract AuthorizedList is IAuthorizedList, Context, Ownable
{
    using Address for address;

    event AuthorizationUpdated(address indexed user, bool authorized);
    event AuthorizationRenounced(address indexed user);

    mapping(address => bool) internal authorizedCaller;

    modifier authorized() {
        require(authorizedCaller[_msgSender()] || _msgSender() == _owner, "You are not authorized to use this function");
        require(_msgSender() != address(0), "Zero address is not a valid caller");
        _;
    }

    constructor() public Ownable() {
        authorizedCaller[_msgSender()] = true;
    }

    function authorizeCaller(address authAddress, bool shouldAuthorize) external virtual override onlyOwner {
        authorizedCaller[authAddress] = shouldAuthorize;
        emit AuthorizationUpdated(authAddress, shouldAuthorize);
    }

    function renounceAuthorization() external authorized {
        authorizedCaller[_msgSender()] = false;
        emit AuthorizationRenounced(_msgSender());
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
pragma solidity ^0.6.0;

interface IAuthorizedList {
    function authorizeCaller(address authAddress, bool shouldAuthorize) external;
}

interface IAuthorizedListExt {
    function authorizeByAuthorized(address authAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IUserInfoManager {
//    function logTransfer(address payable from, uint256 fromBalance, address payable to, uint256 toBalance) external;
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
import "./AuthorizedList.sol";

abstract contract LPSwapSupport is AuthorizedList {
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

    uint256 public minSpendAmount = 0.001 ether;
    uint256 public maxSpendAmount = 1 ether;

    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;
    address public liquidityReceiver = deadAddress;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    function _approve(address owner, address spender, uint256 tokenAmount) internal virtual;

    function updateRouter(address newAddress) public authorized {
        require(newAddress != address(pancakeRouter), "The router is already set to this address");
        emit UpdateRouter(newAddress, address(pancakeRouter));
        pancakeRouter = IPancakeRouter02(newAddress);
    }

    function updateLiquidityReceiver(address receiverAddress) external onlyOwner{
        require(receiverAddress != liquidityReceiver, "LP is already sent to that address");
        emit UpdateLPReceiver(receiverAddress, liquidityReceiver);
        liquidityReceiver = receiverAddress;
    }

    function updateRouterAndPair(address newAddress) public virtual authorized {
        if(newAddress != address(pancakeRouter)){
            updateRouter(newAddress);
        }
        address _pancakeswapV2Pair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());
        if(_pancakeswapV2Pair != pancakePair){
            updateLPPair(_pancakeswapV2Pair);
        }
    }

    function updateLPPair(address newAddress) public virtual authorized {
        require(newAddress != pancakePair, "The LP Pair is already set to this address");
        emit UpdatePair(newAddress, pancakePair);
        pancakePair = newAddress;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public authorized {
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
        if(amount > maxSpendAmount){
            amount = maxSpendAmount;
        }
        if(amount < minSpendAmount) {return;}

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            destination,
            block.timestamp.add(400)
        );
    }

    function updateSwapRange(uint256 minAmount, uint256 maxAmount) external authorized {
        require(minAmount <= maxAmount, "Minimum must be less than maximum");
        minSpendAmount = minAmount;
        maxSpendAmount = maxAmount;
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

