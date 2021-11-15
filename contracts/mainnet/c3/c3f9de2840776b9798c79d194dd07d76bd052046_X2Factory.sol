// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/SafeERC20.sol";

import "./interfaces/IX2Factory.sol";
import "./X2Market.sol";
import "./X2Token.sol";

contract X2Factory is IX2Factory {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_FEE_BASIS_POINTS = 40; // max 0.4% fee
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    address public gov;
    address public override feeReceiver;
    address public override feeToken;
    address public weth;

    address[] public markets;
    bool public freeMarketCreation = false;

    mapping (address => uint256) public feeBasisPoints;

    event CreateMarket(
        string bullToken,
        string bearToken,
        address collateralToken,
        address priceFeed,
        uint256 multiplierBasisPoints,
        uint256 maxProfitBasisPoints,
        uint256 index
    );

    event GovChange(address gov);
    event FeeChange(address market, uint256 fee);
    event FeeReceiverChange(address feeReceiver);

    modifier onlyGov() {
        require(msg.sender == gov, "X2Factory: forbidden");
        _;
    }

    constructor(address _feeToken, address _weth) public {
        feeToken = _feeToken;
        weth = _weth;
        gov = msg.sender;
    }

    function marketsLength() external view returns (uint256) {
        return markets.length;
    }

    function enableFreeMarketCreation() external onlyGov {
        freeMarketCreation = true;
    }

    function createMarket(
        string memory _bullTokenSymbol,
        string memory _bearTokenSymbol,
        address _collateralToken,
        address _priceFeed,
        uint256 _multiplierBasisPoints,
        uint256 _maxProfitBasisPoints,
        uint256 _minDeltaBasisPoints
    ) external returns (address, address, address) {
        if (!freeMarketCreation) {
            require(msg.sender == gov, "X2Factory: forbidden");
        }

        X2Market market = new X2Market();
        market.initialize(
            address(this),
            weth,
            _collateralToken,
            feeToken,
            _priceFeed,
            _multiplierBasisPoints,
            _maxProfitBasisPoints,
            _minDeltaBasisPoints
        );

        X2Token bullToken = new X2Token();
        bullToken.initialize(address(market), _bullTokenSymbol);

        X2Token bearToken = new X2Token();
        bearToken.initialize(address(market), _bearTokenSymbol);

        market.setBullToken(address(bullToken));
        market.setBearToken(address(bearToken));

        markets.push(address(market));

        emit CreateMarket(
            _bullTokenSymbol,
            _bearTokenSymbol,
            _collateralToken,
            _priceFeed,
            _multiplierBasisPoints,
            _maxProfitBasisPoints,
            markets.length - 1
        );

        return (address(market), address(bullToken), address(bearToken));
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
        emit GovChange(gov);
    }

    function setFee(address _market, uint256 _feeBasisPoints) external onlyGov {
        require(_feeBasisPoints <= MAX_FEE_BASIS_POINTS, "X2Factory: fee exceeds allowed limit");
        feeBasisPoints[_market] = _feeBasisPoints;
        emit FeeChange(_market, _feeBasisPoints);
    }

    function setFeeReceiver(address _feeReceiver) external onlyGov {
        feeReceiver = _feeReceiver;
        emit FeeReceiverChange(feeReceiver);
    }

    function getFee(address _market, uint256 _amount) external override view returns (uint256) {
        if (feeReceiver == address(0)) {
            return 0;
        }
        return _amount.mul(feeBasisPoints[_market]).div(BASIS_POINTS_DIVISOR);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
        require(c >= a, "SafeMath: addition overflow");

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
        return div(a, b, "SafeMath: division by zero");
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return mod(a, b, "SafeMath: modulo by zero");
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "../math/SafeMath.sol";
import "../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2Factory {
    function feeToken() external view returns (address);
    function feeReceiver() external view returns (address);
    function getFee(address market, uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/token/IERC20.sol";
import "./libraries/token/SafeERC20.sol";
import "./libraries/math/SafeMath.sol";
import "./libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IX2Market.sol";
import "./interfaces/IX2Factory.sol";
import "./interfaces/IX2FeeReceiver.sol";
import "./interfaces/IX2PriceFeed.sol";
import "./interfaces/IX2Token.sol";

contract X2Market is IX2Market, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    // max uint256 has 77 digits, with an initial rebase divisor of 10^20
    // and assuming 18 decimals for tokens, collateral tokens with a supply
    // of up to 39 digits can be supported
    uint256 public constant INITIAL_REBASE_DIVISOR = 10**20;

    address public factory;

    address public weth;
    address public override collateralToken;
    address public feeToken;
    address public override bullToken;
    address public override bearToken;
    address public priceFeed;
    uint256 public multiplierBasisPoints;
    uint256 public maxProfitBasisPoints;
    uint256 public minDeltaBasisPoints;
    uint256 public lastPrice;

    uint256 public feeReserve;

    uint256 public collateralTokenBalance;
    uint256 public feeTokenBalance;

    bool public isInitialized;

    mapping (address => uint256) public previousDivisors;
    mapping (address => uint256) public override cachedDivisors;

    event Fee(uint256 fee, uint256 subsidy);
    event PriceChange(uint256 price, uint256 bullDivisor, uint256 bearDivisor);
    event DistributeFees(uint256 fees);
    event DistributeInterest(uint256 interest);
    event Deposit(address account, uint256 amount, uint256 fee, uint256 balance);
    event Withdraw(address account, uint256 amount, uint256 fee, uint256 balance);

    modifier onlyFactory() {
        require(msg.sender == factory, "X2Market: forbidden");
        _;
    }

    function initialize(
        address _factory,
        address _weth,
        address _collateralToken,
        address _feeToken,
        address _priceFeed,
        uint256 _multiplierBasisPoints,
        uint256 _maxProfitBasisPoints,
        uint256 _minDeltaBasisPoints
    ) public {
        require(!isInitialized, "X2Market: already initialized");
        isInitialized = true;

        factory = _factory;
        weth = _weth;
        collateralToken = _collateralToken;
        feeToken = _feeToken;
        priceFeed = _priceFeed;
        multiplierBasisPoints = _multiplierBasisPoints;
        maxProfitBasisPoints = _maxProfitBasisPoints;
        minDeltaBasisPoints = _minDeltaBasisPoints;

        lastPrice = latestPrice();
        require(lastPrice != 0, "X2Market: unsupported price feed");
    }

    function setBullToken(address _bullToken) public onlyFactory {
        require(bullToken == address(0), "X2Market: bullToken already set");
        bullToken = _bullToken;
        previousDivisors[bullToken] = INITIAL_REBASE_DIVISOR;
        cachedDivisors[bullToken] = INITIAL_REBASE_DIVISOR;
    }

    function setBearToken(address _bearToken) public onlyFactory {
        require(bearToken == address(0), "X2Market: bearToken already set");
        bearToken = _bearToken;
        previousDivisors[bearToken] = INITIAL_REBASE_DIVISOR;
        cachedDivisors[bearToken] = INITIAL_REBASE_DIVISOR;
    }

    function deposit(address _token, address _receiver, bool _withFeeSubsidy) public override nonReentrant returns (uint256) {
        require(_token == bullToken || _token == bearToken, "X2Market: unsupported token");
        uint256 amount = _getCollateralTokenBalance().sub(collateralTokenBalance);
        require(amount > 0, "X2Market: insufficient collateral sent");

        rebase();

        uint256 feeSubsidy = 0;
        if (_withFeeSubsidy && collateralToken == weth) {
            feeSubsidy = _getFeeTokenBalance().sub(feeTokenBalance);
        }

        uint256 fee = _collectFees(amount, feeSubsidy);
        uint256 depositAmount = amount.sub(fee);
        IX2Token(_token).mint(_receiver, depositAmount, cachedDivisors[_token]);

        _updateCollateralTokenBalance();
        _updateFeeTokenBalance();

        emit Deposit(_receiver, depositAmount, fee, IERC20(_token).balanceOf(_receiver));
        return depositAmount;
    }

    function withdraw(address _token, uint256 _amount, address _receiver, bool _withFeeSubsidy) public override nonReentrant returns (uint256) {
        require(_token == bullToken || _token == bearToken, "X2Market: unsupported token");
        rebase();

        IX2Token(_token).burn(msg.sender, _amount);

        uint256 feeSubsidy = 0;
        if (_withFeeSubsidy && collateralToken == weth) {
            feeSubsidy = _getFeeTokenBalance().sub(feeTokenBalance);
        }

        uint256 fee = _collectFees(_amount, feeSubsidy);
        uint256 withdrawAmount = _amount.sub(fee);
        IERC20(collateralToken).safeTransfer(_receiver, withdrawAmount);

        _updateCollateralTokenBalance();

        emit Withdraw(_receiver, withdrawAmount, fee, IERC20(_token).balanceOf(_receiver));
        return withdrawAmount;
    }

    function distributeFees() public nonReentrant {
        address feeReceiver = IX2Factory(factory).feeReceiver();
        require(feeReceiver != address(0), "X2Market: empty feeReceiver");

        uint256 fees = feeReserve;
        feeReserve = 0;

        IERC20(collateralToken).safeTransfer(feeReceiver, fees);
        IX2FeeReceiver(feeReceiver).notifyFees(collateralToken, fees);

        _updateCollateralTokenBalance();
        emit DistributeFees(fees);
    }

    function distributeInterest() public nonReentrant {
        address feeReceiver = IX2Factory(factory).feeReceiver();
        require(feeReceiver != address(0), "X2Market: empty feeReceiver");

        uint256 interest = interestReserve();
        IERC20(collateralToken).safeTransfer(feeReceiver, interest);
        IX2FeeReceiver(feeReceiver).notifyInterest(collateralToken, interest);

        _updateCollateralTokenBalance();
        emit DistributeInterest(interest);
    }

    function interestReserve() public view returns (uint256) {
        uint256 totalBulls = cachedTotalSupply(bullToken);
        uint256 totalBears = cachedTotalSupply(bearToken);
        return collateralTokenBalance.sub(totalBulls).sub(totalBears).sub(feeReserve);
    }

    function rebase() public override returns (bool) {
        uint256 nextPrice = latestPrice();
        if (nextPrice == lastPrice) { return false; }

        // store the divisor values as updating cachedDivisors will change the
        // value returned from getRebaseDivisor
        uint256 bullDivisor = getRebaseDivisor(bullToken);
        uint256 bearDivisor = getRebaseDivisor(bearToken);

        previousDivisors[bullToken] = cachedDivisors[bullToken];
        previousDivisors[bearToken] = cachedDivisors[bearToken];

        cachedDivisors[bullToken] = bullDivisor;
        cachedDivisors[bearToken] = bearDivisor;

        lastPrice = nextPrice;
        emit PriceChange(nextPrice, bullDivisor, bearDivisor);

        return true;
    }

    function latestPrice() public view override returns (uint256) {
        uint256 answer = IX2PriceFeed(priceFeed).latestAnswer();
        // prevent zero from being returned
        if (answer == 0) { return lastPrice; }

        // prevent price from moving too often
        uint256 _lastPrice = lastPrice;
        uint256 minDelta = _lastPrice.mul(minDeltaBasisPoints).div(BASIS_POINTS_DIVISOR);
        uint256 delta = answer > _lastPrice ? answer.sub(_lastPrice) : _lastPrice.sub(answer);
        if (delta <= minDelta) { return _lastPrice; }

        return answer;
    }

    function getDivisor(address _token) public override view returns (uint256) {
        uint256 nextPrice = latestPrice();

        // if the price has moved then on rebase the previousDivisor
        // will have the current cachedDivisor's value
        // and the cachedDivisor will have the rebaseDivisor's value
        // so we should only compare these two values for this case
        if (nextPrice != lastPrice) {
            uint256 cachedDivisor = cachedDivisors[_token];
            uint256 rebaseDivisor = getRebaseDivisor(_token);
            // return the largest divisor to prevent manipulation
            return cachedDivisor > rebaseDivisor ? cachedDivisor : rebaseDivisor;
        }

        uint256 previousDivisor = previousDivisors[_token];
        uint256 cachedDivisor = cachedDivisors[_token];
        uint256 rebaseDivisor = getRebaseDivisor(_token);
        // return the largest divisor to prevent manipulation
        if (previousDivisor > cachedDivisor && previousDivisor > rebaseDivisor) {
            return previousDivisor;
        }
        return cachedDivisor > rebaseDivisor ? cachedDivisor : rebaseDivisor;
    }

    function getRebaseDivisor(address _token) public view returns (uint256) {
        address _bullToken = bullToken;
        address _bearToken = bearToken;

        uint256 _lastPrice = lastPrice;
        uint256 nextPrice = latestPrice();

        if (nextPrice == _lastPrice) {
            return cachedDivisors[_token];
        }

        uint256 totalBulls = cachedTotalSupply(_bullToken);
        uint256 totalBears = cachedTotalSupply(_bearToken);

        // refSupply is the smaller of the two supplies
        uint256 refSupply = totalBulls < totalBears ? totalBulls : totalBears;
        uint256 delta = nextPrice > _lastPrice ? nextPrice.sub(_lastPrice) : _lastPrice.sub(nextPrice);
        // profit is [(smaller supply) * (change in price) / (last price)] * multiplierBasisPoints
        uint256 profit = refSupply.mul(delta).div(_lastPrice).mul(multiplierBasisPoints).div(BASIS_POINTS_DIVISOR);

        // cap the profit to the (max profit percentage) of the smaller supply
        uint256 maxProfit = refSupply.mul(maxProfitBasisPoints).div(BASIS_POINTS_DIVISOR);
        if (profit > maxProfit) { profit = maxProfit; }

        if (_token == _bullToken) {
            uint256 nextSupply = nextPrice > _lastPrice ? totalBulls.add(profit) : totalBulls.sub(profit);
            return _getNextDivisor(_token, nextSupply);
        }

        uint256 nextSupply = nextPrice > _lastPrice ? totalBears.sub(profit) : totalBears.add(profit);
        return _getNextDivisor(_token, nextSupply);
    }

    function cachedTotalSupply(address _token) public view returns (uint256) {
        return IX2Token(_token)._totalSupply().div(cachedDivisors[_token]);
    }

    function _getNextDivisor(address _token, uint256 _nextSupply) private view returns (uint256) {
        if (_nextSupply == 0) {
            return INITIAL_REBASE_DIVISOR;
        }

        uint256 divisor = IX2Token(_token)._totalSupply().div(_nextSupply);
        // prevent the cachedDivisor from being set to 0
        if (divisor == 0) { return cachedDivisors[_token]; }

        return divisor;
    }

    function _collectFees(uint256 _amount, uint256 _feeSubsidy) private returns (uint256) {
        uint256 fee = IX2Factory(factory).getFee(address(this), _amount);
        if (fee == 0) { return 0; }
        if (_feeSubsidy >= fee) { return 0; }

        fee = fee.sub(_feeSubsidy);
        feeReserve = feeReserve.add(fee);

        emit Fee(fee, _feeSubsidy);
        return fee;
    }

    function _updateFeeTokenBalance() private {
        feeTokenBalance = _getFeeTokenBalance();
    }

    function _updateCollateralTokenBalance() private {
        collateralTokenBalance = _getCollateralTokenBalance();
    }

    function _getCollateralTokenBalance() private view returns (uint256) {
        return IERC20(collateralToken).balanceOf(address(this));
    }

    function _getFeeTokenBalance() private view returns (uint256) {
        return IERC20(feeToken).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/token/IERC20.sol";
import "./libraries/token/SafeERC20.sol";
import "./libraries/math/SafeMath.sol";
import "./libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IX2Factory.sol";
import "./interfaces/IX2Market.sol";
import "./interfaces/IX2Token.sol";

contract X2Token is IERC20, IX2Token, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 public override _totalSupply;

    address public override market;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    bool public isInitialized;

    modifier onlyMarket() {
        require(msg.sender == market, "X2Token: forbidden");
        _;
    }

    function initialize(address _market, string memory _symbol) public {
        require(!isInitialized, "X2Token: already initialized");
        isInitialized = true;
        market = _market;
        name = _symbol;
        symbol = _symbol;
    }

    function mint(address _account, uint256 _amount, uint256 _divisor) public override onlyMarket {
        _mint(_account, _amount, _divisor);
    }

    function burn(address _account, uint256 _amount) public override onlyMarket {
        _burn(_account, _amount);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply.div(getDivisor());
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return balances[_account].div(getDivisor());
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "X2Token: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function getDivisor() public view returns (uint256) {
        return IX2Market(market).getDivisor(address(this));
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        IX2Market(market).rebase();

        require(_sender != address(0), "X2Token: transfer from the zero address");
        require(_recipient != address(0), "X2Token: transfer to the zero address");

        uint256 divisor = getDivisor();
        _decreaseBalance(_sender, _amount, divisor);
        _increaseBalance(_recipient, _amount, divisor);

        emit Transfer(_sender, _recipient, _amount);
    }

    function _mint(address _account, uint256 _amount, uint256 _divisor) private {
        require(_account != address(0), "X2Token: mint to the zero address");

        _increaseBalance(_account, _amount, _divisor);

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) private {
        require(_account != address(0), "X2Token: burn from the zero address");

        uint256 divisor = getDivisor();
        _decreaseBalance(_account, _amount, divisor);

        emit Transfer(_account, address(0), _amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "X2Token: approve from the zero address");
        require(_spender != address(0), "X2Token: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _increaseBalance(address _account, uint256 _amount, uint256 _divisor) private {
        if (_amount == 0) { return; }

        uint256 scaledAmount = _amount.mul(_divisor);
        balances[_account] = balances[_account].add(scaledAmount);
        _totalSupply = _totalSupply.add(scaledAmount);
    }

    function _decreaseBalance(address _account, uint256 _amount, uint256 _divisor) private {
        if (_amount == 0) { return; }

        uint256 scaledAmount = _amount.mul(_divisor);
        balances[_account] = balances[_account].sub(scaledAmount);
        _totalSupply = _totalSupply.sub(scaledAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

pragma solidity 0.6.12;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2Market {
    function bullToken() external view returns (address);
    function bearToken() external view returns (address);
    function latestPrice() external view returns (uint256);
    function getDivisor(address token) external view returns (uint256);
    function cachedDivisors(address token) external view returns (uint256);
    function collateralToken() external view returns (address);
    function deposit(address token, address receiver, bool withFeeSubsidy) external returns (uint256);
    function withdraw(address token, uint256 amount, address receiver, bool withFeeSubsidy) external returns (uint256);
    function rebase() external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2FeeReceiver {
    function notifyFees(address token, uint256 amount) external;
    function notifyInterest(address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2PriceFeed {
    function latestAnswer() external view returns (uint256);
    function latestTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2Token {
    function _totalSupply() external view returns (uint256);
    function market() external view returns (address);
    function mint(address account, uint256 amount, uint256 divisor) external;
    function burn(address account, uint256 amount) external;
}

