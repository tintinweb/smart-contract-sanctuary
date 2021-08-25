// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol';
import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';
import '@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol';
import '@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol';
import 'pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol';
import './utils/Ownable.sol';
import './utils/Manageable.sol';
import "./utils/Presale.sol";
import "./utils/DividendDistributor.sol";
import "./utils/LockableFunction.sol";
import "./utils/LPSwapSupport.sol";
import "./utils/AntiLPSniper.sol";

contract SuperFuel is IBEP20, Manageable, AntiLPSniper, LockableFunction, LPSwapSupport {
    using SafeMath for uint256;
    using Address for address;

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

    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private  _totalSupply;

    bool tradingIsEnabled;

    // Trackers for various pending token swaps and fees
    Fees public fees;
    Fees public transferFees;
    TokenTracker public tokenTracker;

    uint256 public _maxTxAmount;
    uint256 public tokenSwapThreshold;

    uint256 public gasForProcessing = 300000;

    address payable private marketingWallet;
    IDividendDistributor public dividendDistributor;

    constructor (uint256 _supply, address routerAddress, address tokenOwner, address _marketingWallet, address rewardsToken) Manageable(tokenOwner) public {
        _name = "SuperFuel";
        _symbol = "SFUEL";
        _decimals = 9;
        _totalSupply = _supply * 10 ** _decimals;

        _maxTxAmount = _totalSupply.div(200);
        tokenSwapThreshold = _maxTxAmount.div(10000);

        liquidityReceiver = deadAddress;

        dividendDistributor = new DividendDistributor(routerAddress, rewardsToken);


//        updateRouterAndPair(routerAddress);
        pancakeRouter = IPancakeRouter02(routerAddress);
//        setPair();
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

        marketingWallet = payable(_marketingWallet);

        //exclude owner and this contract from fee
        _isExcludedFromFee[tokenOwner] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;

        _owner = tokenOwner;
        balances[tokenOwner] = _totalSupply;
//        emit Transfer(address(0), address(this), _presaleReserve);
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

    // TODO - Turn off individually?
    function _calculateFees(uint256 amount) private returns(uint256 liquidityFee, uint256 marketingFee, uint256 buybackFee, uint256 reflectionFee, uint256 lotteryFee) {
        liquidityFee = amount.mul(fees.liquidity).div(fees.divisor);
        marketingFee = amount.mul(fees.marketing).div(fees.divisor);
        buybackFee = amount.mul(fees.buyback).div(fees.divisor);
        reflectionFee = amount.mul(fees.tokenReflection).div(fees.divisor);
        lotteryFee = amount.mul(fees.lottery).div(fees.divisor);
    }
    ////////////////////////////////////////////////////// - TODO Rewrite
    function _takeFees(uint256 amount) private returns(uint256 transferAmount){
        (uint256 liquidityFee, uint256 marketingFee, uint256 buybackFee, uint256 reflectionFee, uint256 lotteryFee) = _calculateFees(amount);
        uint256 totalFees = liquidityFee.add(marketingFee).add(buybackFee).add(reflectionFee).sub(lotteryFee);

        tokenTracker.liquidity = tokenTracker.liquidity.add(liquidityFee);
        tokenTracker.marketingTokens = tokenTracker.marketingTokens.add(marketingFee);
        tokenTracker.buyback = tokenTracker.buyback.add(buybackFee);
        tokenTracker.reward = tokenTracker.reward.add(reflectionFee);
        tokenTracker.lottery = tokenTracker.lottery.add(lotteryFee);

        balances[address(this)] = balances[address(this)].add(totalFees);
        transferAmount = amount.sub(totalFees);
    }
    ////////////////////////////////////////////////////// - TODO Rewrite
    function setLiquidityFee(uint256 _liquidityFee) external onlyOwner() {
        emit UpdateFee("LiquidityFee", fees.liquidity, _liquidityFee);
        fees.liquidity = _liquidityFee;
    }

    function setMarketingFee(uint256 _marketingFee) external onlyOwner() {
        emit UpdateFee("ProjectWalletFee", fees.marketing, _marketingFee);
        fees.marketing = _marketingFee;
    }

    function setRewardTokenFee(uint256 _rewardTokenFee) external onlyOwner() {
        emit UpdateFee("RewardTokenFee", fees.tokenReflection, _rewardTokenFee);
        fees.tokenReflection = _rewardTokenFee;
    }

    function setBuybackFee(uint256 _buybackFee) external onlyOwner() {
        emit UpdateFee("BuybackFee", fees.buyback, _buybackFee);
        fees.buyback = _buybackFee;
    }

    function setLotteryFee(uint256 _lotteryFee) external onlyOwner() {
        emit UpdateFee("BuybackFee", fees.lottery, _lotteryFee);
        fees.lottery = _lotteryFee;
    }

    function setFeeDivisor(uint256 _divisor) external onlyOwner() {
        emit UpdateFee("Divisor", fees.divisor, _divisor);
        fees.divisor = _divisor;
    }

    function settokenSwapThreshold(uint256 swapNumber) public onlyOwner {
        tokenSwapThreshold = swapNumber * 10 ** _decimals;
    }

    function setMaxTx(uint256 maxTxPercent) public onlyOwner {
        _maxTxAmount = maxTxPercent  * 10 ** _decimals;
    }

    function burn(uint256 burnAmount) public {
        require(balanceOf(_msgSender()) > burnAmount, "Insufficient funds in account");
        _burn(_msgSender(), burnAmount);
    }


    function _burn(address from, uint256 burnAmount) private returns(uint256) {
        require(from != address(0), "ERC20: transfer from the zero address");
        // TODO - Discuss type of burn
        return 0;
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
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // is the token balance of this contract address counter for one
        // of the possible token swap events is over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeswap pair.

        if(from != owner() && to != owner() && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            if(!inSwap && from != pancakePair && tradingIsEnabled) {
                selectSwapEvent();
            }
            transferAmount = _takeFees(amount);
        } else {
            dividendDistributor.process(gasForProcessing);
        }
        try dividendDistributor.setShare(payable(from), balanceOf(from)) {} catch {}
        try dividendDistributor.setShare(payable(to), balanceOf(to)) {} catch {}
        _transferStandard(from, to, amount, transferAmount);
    }

    function pushSwap() external {
        if(!inSwap && tradingIsEnabled)
            selectSwapEvent();
    }

    function selectSwapEvent() private lockTheSwap {
        uint256 tokenContractBalance = balances[address(this)];
        if(tokenTracker.reward >= tokenSwapThreshold){
            tokenContractBalance = tokenTracker.reward;

            if(tokenContractBalance >= _maxTxAmount)
            {
                tokenContractBalance = _maxTxAmount;
            }

            swapTokensForCurrencyAdv(address(this), tokenContractBalance, address(dividendDistributor));

            tokenTracker.reward = tokenTracker.reward.sub(tokenContractBalance);
//
////        } else if(tokenTracker.lottery >= tokenSwapThreshold){
//            tokenContractBalance = tokenTracker.lottery;
//
//            if(tokenContractBalance >= _maxTxAmount)
//            {
//                tokenContractBalance = _maxTxAmount;
//            }
//
//            swapTokensForCurrency(tokenContractBalance);
//            //            sendBNBTo(projectWallet, address(this).balance);
//            tokenTracker.lottery = tokenTracker.lottery.sub(tokenContractBalance);
//
////        } else if(tokenTracker.buyback >= tokenSwapThreshold){
//            tokenContractBalance = tokenTracker.buyback;
//
//            if(tokenContractBalance >= _maxTxAmount)
//            {
//                tokenContractBalance = _maxTxAmount;
//            }
//
//            swapTokensForCurrency(tokenContractBalance);
//            //            sendBNBTo(projectWallet, address(this).balance);
//            tokenTracker.buyback = tokenTracker.buyback.sub(tokenContractBalance);
//
////        }else if(tokenTracker.liquidity >= tokenSwapThreshold){
//            tokenContractBalance = tokenTracker.liquidity;
//
//            if(tokenContractBalance >= _maxTxAmount)
//            {
//                tokenContractBalance = _maxTxAmount;
//            }
//            // Add liquidity
//            swapAndLiquify(tokenContractBalance);
//            tokenTracker.liquidity = tokenTracker.liquidity.sub(tokenContractBalance);
//
////        }else if(tokenTracker.marketingTokens >= tokenSwapThreshold){
//            tokenContractBalance = tokenTracker.marketingTokens;
//
//            if(tokenContractBalance >= _maxTxAmount)
//            {
//                tokenContractBalance = _maxTxAmount;
//            }
//            // Swap for rewards contract
//            swapTokensForCurrency(tokenContractBalance);
//            tokenTracker.marketingTokens = tokenTracker.marketingTokens.sub(tokenContractBalance);


        } else {
            try dividendDistributor.process(gasForProcessing) {} catch {}
        }
    }

    function sendBNBTo(address payable to, uint256 amount) private {
        require(address(this).balance >= amount);
        to.transfer(amount);
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

    function setRewardToCurrency() external onlyOwner {
        dividendDistributor.setRewardToCurrency();
    }
    function setRewardToToken(address _tokenAddress) external onlyOwner{
        dividendDistributor.setRewardToToken(_tokenAddress);
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
pragma solidity ^0.6.0;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';
import "./Manageable.sol";

abstract contract Presale is Context, Manageable {
//    using Address for address;
//    using SafeMath for uint256;
//
//    event PresalePurchase(address indexed buyer, uint256 tokenAmount);
//
//    address payable private presaleBeneficiary;
//
//    mapping(address => bool) public presaleWhitelist;
//
//    uint256 public presaleStartDate;
//    uint256 public presaleEndDate;
//    uint256 public tokensPerBNB;
//    uint256 public presaleTotalAllocation;
//    uint256 public presaleQuantityRemaining;
//
//    bool public presaleEnabled;
//    bool public presaleFinalized;
//
//    // Separate function for presales incase transfers are disabled for duration
//    function _presaleTransfer(address to, uint256 amount) internal virtual;
//
//    constructor(uint256 _presaleAmount) public {
//        presaleBeneficiary = payable(owner());
//        presaleTotalAllocation = _presaleAmount;
//        presaleQuantityRemaining = _presaleAmount;
//        presaleStartDate = 0;
//        presaleEndDate = 0;
//        tokensPerBNB = 0;
//        presaleTotalAllocation = 0;
//        presaleQuantityRemaining = 0;
//        presaleEnabled = false;
//        presaleFinalized = false;
//    }
//
//    modifier disableDuringPresale(){
//        require(block.timestamp >= presaleEndDate || _msgSender() == owner(), "This function is disabled until presale has finished");
//        _;
//    }
//
//    modifier afterPresale(){
//        require(block.timestamp >= presaleEndDate, "This function is disabled until presale has finished");
//        _;
//    }
//
//    modifier duringPresale(){
//        require(presaleEnabled, "Presale feature has not been enabled");
//        require(block.timestamp < presaleEndDate, "Presale has finished");
//        require(block.timestamp >= presaleStartDate, "Presale has not started yet");
//        _;
//    }
//
//    function setPresaleStartDateInHours(uint256 _presaleStart) public onlyOwnerOrRole(Roles.ADMIN){
//        require(!presaleFinalized, "Presale values have been locked");
//        presaleStartDate = block.timestamp + (_presaleStart) * 1 hours;
//    }
//
//    function setPresaleEndDateInHours(uint256 _presaleEnd) public onlyOwnerOrRole(Roles.ADMIN){
//        require(!presaleFinalized, "Presale values have been locked");
//        presaleEndDate = block.timestamp + (_presaleEnd) * 1 hours;
//    }
//
//    function setPresaleTokenPrice(uint256 _tokensPerBNB) public onlyOwnerOrRole(Roles.ADMIN){
//        require(!presaleFinalized, "Presale values have been locked");
//        tokensPerBNB = _tokensPerBNB;
//    }
//
//    function setPresaleParamsAndEnable(uint256 _presaleStart, uint256 _presaleEnd, uint256 _tokensPerBNB) public onlyOwnerOrRole(Roles.ADMIN){
//        require(!presaleFinalized, "Presale values have been locked");
//        presaleStartDate = block.timestamp + (_presaleStart) * 1 hours;
//        presaleEndDate = block.timestamp + (_presaleEnd) * 1 hours;
//        tokensPerBNB = _tokensPerBNB;
//        enablePresale();
//    }
//
//    function enablePresale() public onlyOwnerOrRole(Roles.ADMIN){
//        require(presaleStartDate > 0);
//        require(presaleEndDate > presaleStartDate);
//        require(tokensPerBNB > 0);
//        presaleEnabled = true;
//    }
//
//    function stopPresale() public onlyOwnerOrRole(Roles.ADMIN){
//        presaleEnabled = false;
//    }
//
//    function lockPresaleValues() public onlyOwnerOrRole(Roles.ADMIN){
//        require(!presaleFinalized, "Presale values are already locked");
//        presaleFinalized = true;
//    }
//
//    function isPresale() public view returns (bool) {
//        return (block.timestamp >= presaleStartDate && block.timestamp < presaleEndDate);
//    }
//
//    function setPresaleDuration(uint256 presaleDurationInHours) internal {
//        presaleEndDate = block.timestamp + (presaleDurationInHours * 1 hours);
//    }
//
//    function presaleCostForTokens(uint256 tokenAmount) external view duringPresale() returns(uint256) {
//        return tokenAmount.div(tokensPerBNB);
//    }
//
//    function presaleBuy() external virtual payable duringPresale() {
//        require(presaleEnabled, "Presale is not enabled");
//        require(block.timestamp > presaleStartDate && block.timestamp < presaleEndDate, "Presale not active at this time");
//        require(presaleWhitelist[_msgSender()], "Address not on whitelist for sale");
//        require(msg.value > 0, "You must send BNB to complete a buy");
//        require(presaleQuantityRemaining > 0);
//
//        address payable buyer = payable(_msgSender());
//        uint256 sentBNB = msg.value;
//        uint256 tokensToBuy = (msg.value).mul(tokensPerBNB);
//        uint256 unusedBNB = 0;
//
//        if (tokensToBuy > presaleQuantityRemaining){
//            tokensToBuy = presaleQuantityRemaining;
//            unusedBNB = sentBNB.sub(tokensToBuy.div(tokensPerBNB));
//        }
//        presaleQuantityRemaining = presaleQuantityRemaining.sub(tokensToBuy);
//
//        _presaleTransfer(buyer, tokensToBuy);
//
//        if(unusedBNB > 0){
//            buyer.transfer(unusedBNB);
//        }
//        emit PresalePurchase(buyer, tokensToBuy);
//        presaleBeneficiary.transfer(sentBNB.sub(unusedBNB));
//    }
//
//    function setPresaleBeneficiary(address _beneficiary) public onlyOwnerOrRole(Roles.ADMIN){
//        presaleBeneficiary = payable(_beneficiary);
//    }
//
//    function recoverLeftoverPresaleTokens() public afterPresale() onlyOwnerOrRole(Roles.ADMIN){
//        require(presaleQuantityRemaining > 0);
//        uint256 tokensToSend = presaleQuantityRemaining;
//        presaleQuantityRemaining = 0;
//
//        _presaleTransfer(presaleBeneficiary, tokensToSend);
//    }
//
//    function addAddressToPresaleWhitelist(address _presaleAddress) public onlyOwnerOrRole(Roles.ADMIN){
//        require(!presaleWhitelist[_presaleAddress], "Address is already enrolled in whitelist");
//        presaleWhitelist[_presaleAddress] = true;
//    }
//
//    function removeAddressToPresaleWhitelist(address _presaleAddress) public onlyOwnerOrRole(Roles.ADMIN){
//        require(presaleWhitelist[_presaleAddress], "Address is not currently enrolled in whitelist");
//        presaleWhitelist[_presaleAddress] = false;
//    }
//
//    function addAddressesToPresaleWhitelist(address[] memory _presaleAddresses) public onlyOwnerOrRole(Roles.ADMIN){
//        for(uint256 i = 0; i < _presaleAddresses.length; i++){
//            presaleWhitelist[_presaleAddresses[i]] = true;
//        }
//    }
//
//    function removeAddressesToPresaleWhitelist(address[] memory _presaleAddresses) public onlyOwnerOrRole(Roles.ADMIN){
//        for(uint256 i = 0; i < _presaleAddresses.length; i++){
//            presaleWhitelist[_presaleAddresses[i]] = false;
//        }
//    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol';
import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import "../interfaces/IDividendDistributor.sol";
import "./LPSwapSupport.sol";

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

    constructor (address _router, address _rewardsToken) public {
        updateRouter(_router);
        if(_rewardsToken == address(0)){
            rewardType = RewardType.CURRENCY;
        } else {
            rewardType = RewardType.TOKEN;
            rewardsToken = IBEP20(payable(_rewardsToken));
        }
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
        if(rewardType == RewardType.CURRENCY) { return; }
        uint256 contractBalance = address(this).balance;
        uint256 balanceBefore = rewardsToken.balanceOf(address(this));

        swapCurrencyForTokensAdv(address(rewardsToken), contractBalance, address(this));

        uint256 amount = rewardsToken.balanceOf(address(this)).sub(balanceBefore);
        // reset to switch
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
        swapTokensForCurrencyAdv(_tokenAddress, contractBalance, address(this));

        rewardsToken = IBEP20(payable(_tokenAddress));
        totalDividends = rewardsToken.balanceOf(address(this));
        dividendsPerShare = dividendsPerShareAccuracyFactor.mul(totalDividends).div(totalShares);
        rewardType = RewardType.TOKEN;
    }

    function _approve(address owner, address spender, uint256 tokenAmount) internal override {
        return;
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
        && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            rewardsToken.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
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

    uint256 public minSwapAmount = 0.00001 ether;
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

    function setPair() public onlyOwner {
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
        require(!isBlackListed[user], "User has been blacklisted, possibly as an anti sniper measure");
        _;
    }

    modifier neitherBlacklisted(address user1, address user2){
        require(!isBlackListed[user1], "A user in this transaction has been blacklisted, possibly as an anti sniper measure");
        require(!isBlackListed[user2], "A user in this transaction has been blacklisted, possibly as an anti sniper measure");
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

interface IDividendDistributor {
    enum RewardType{
        TOKEN,
        CURRENCY
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;

    function setRewardToCurrency() external;
    function setRewardToToken(address _tokenAddress) external;
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

    function authorizeCaller(address authAddress, bool shouldAuthorize) external authorized {
        authorizedCaller[authAddress] = shouldAuthorize;
    }
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