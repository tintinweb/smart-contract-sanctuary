/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// File: localhost/base/InitializableOwnable.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier notInitialized() {
        require(!_INITIALIZED_, "INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: localhost/base/Governance.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

contract Governance {
    address internal _governance;

    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);

    /**
     * @dev Initializes the contract setting the deployer as the initial governance.
     */
    constructor () internal {
        _governance = msg.sender;
        emit GovernanceTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current governance.
     */
    function governance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the governance.
     */
    modifier onlyGovernance() {
        require(_governance == msg.sender, "NOT_Governance");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newGovernance`).
     * Can only be called by the current governance.
     */
    function transferGovernance(address newGovernance) public onlyGovernance {
        require(newGovernance != address(0), "ZERO_ADDRESS");
        emit GovernanceTransferred(_governance, newGovernance);
        _governance = newGovernance;
    }
}

// File: localhost/base/Operation.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;


contract Operation is Governance{
    mapping(address => uint8) private _operators;

    modifier isOperator{
        require(_operators[msg.sender] == 1,"NOT_AN_OPERATOR");
        _;
    }

    constructor() public {
        _operators[msg.sender] = 1;
    }

    function addOperator(address account) external onlyGovernance {
        _operators[account] = 1;
    }

    function removeOperator(address account) external onlyGovernance {
        _operators[account] = 0;
    }

    function canOperate(address account) external view returns (bool) {
        return _operators[account] == 1;
    }
}

// File: localhost/lib/Counters.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }

    function moveTo(Counter storage counter,uint256 target) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value = target;
    }
}
// File: localhost/lib/SafeERC20.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;




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
// File: localhost/interface/IYouSwapFactory.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

interface IYouSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setFeeToRate(uint256) external;

    function feeToRate() external view returns (uint256);
}
// File: localhost/token/createToken/MoonProxyTemplate.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;






contract MoonProxyTemplate is InitializableOwnable {
    using SafeMath for uint256;

    IERC20 public TOKENMOON;
    IERC20 public TOKENB;
    bool private _pairCreated;
    IYouSwapRouter public youSwapRouter;
    address private _youSwapPair;

    bool inSwapAndLiquify;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event SwapAndLiquify(
        uint256 moonTokensSwapped,
        uint256 tokenBReceived,
        uint256 moonTokensIntoLiqudity
    );

    event LiquifySkipped(
        uint256 tokenMoonAmount,
        uint256 tokenBAmount
    );

    function youSwapPair() external view returns (address){
        return _youSwapPair;
    }

    modifier onlyMoon() {
        require(msg.sender == address(TOKENMOON), "ONLY_CALLABLE_FOR_MOON_CONTRACT");
        _;
    }

    function createPairs(address creator, address router, address tokenMoon, address tokenB) external returns (address, address){
        require(!_pairCreated, "PAIR_CREATED");
        require(msg.sender == tokenMoon, "ONLY_CALLABLE_FOR_MOON_CONTRACT");

        TOKENMOON = IERC20(tokenMoon);
        TOKENB = IERC20(tokenB);
        initOwner(creator);

        youSwapRouter = IYouSwapRouter(router);
        IYouSwapFactory factory = IYouSwapFactory(youSwapRouter.factory());
        // Create YouSwap pairs for this new token
        _youSwapPair = factory.createPair(tokenMoon, tokenB);
        address ethPair = factory.createPair(tokenMoon, youSwapRouter.WETH());

        _pairCreated = true;
        return (_youSwapPair, ethPair);
    }

    function swapAndLiquify(uint256 contractTokenBalance) onlyMoon lockTheSwap external returns (bool)  {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current TOKENB balance.
        // this is so that we can capture exactly the amount of TOKENB that the
        // swap creates, and not make the liquidity event include any TOKENB that
        // has been manually sent to the contract
        uint256 initialBalance = TOKENB.balanceOf(address(this));

        // swap tokens for TOKENB
        _swapTokensForTOKENB(half);

        // how much TOKENB did we just swap into?
        uint256 newBalance = TOKENB.balanceOf(address(this)).sub(initialBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
        if (otherHalf == 0 || newBalance == 0) {
            LiquifySkipped(otherHalf, newBalance);
        }
        else {
            // add liquidity to YouSwap
            _addLiquidity(otherHalf, newBalance);
        }
    }

    function _swapTokensForTOKENB(uint256 tokenMoonAmount) private {
        // generate the YouSwap pair path of TOKENMOON -> TOKENB
        address[] memory path = new address[](2);
        path[0] = address(TOKENMOON);
        path[1] = address(TOKENB);

        TOKENMOON.approve(address(youSwapRouter), tokenMoonAmount);

        // make the swap
        youSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenMoonAmount,
            0, // accept any amount of TOKENB
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenMoonAmount, uint256 tokenBAmount) private {
        // approve token transfer to cover all possible scenarios
        TOKENMOON.approve(address(youSwapRouter), tokenMoonAmount);
        TOKENB.approve(address(youSwapRouter), tokenBAmount);

        // add the liquidity
        youSwapRouter.addLiquidity(
            address(TOKENMOON),
            address(TOKENB),
            tokenMoonAmount,
            tokenBAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _OWNER_,
            block.timestamp
        );
    }
}
// File: localhost/token/createToken/templates/MoonERC20Template.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;






contract MoonERC20Template is InitializableOwnable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint8 public _taxFee;
    uint8 private _previousTaxFee = _taxFee;

    uint8 public _liquidityFee;
    uint8 private _previousLiquidityFee = _liquidityFee;

    bool public swapAndLiquifyEnabled;

    uint256 public _maxTxAmount;
    uint256 private _numTokensSellToAddToLiquidity;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Mint(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);

    bool public initialized;
    MoonProxyTemplate public moonProxy;
    IERC20 public YOU;

    bool inSwapAndLiquify;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function init(
        address creator,
        address tokenYou,
        address router,
        uint256 initSupply,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint8 taxFee,
        uint8 liquidityFee,
        address cloneFactory,
        address moonProxyTemplate
    ) public {
        require(!initialized, "TOKEN_INITIALIZED");
        require((taxFee + liquidityFee) < 100, "INVALID_FEE_RATE");

        initOwner(creator);
        YOU = IERC20(tokenYou);

        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _taxFee = taxFee;
        _liquidityFee = liquidityFee;

        _tTotal = initSupply * 10 ** uint256(decimals);
        _rTotal = (MAX - (MAX % _tTotal));

        _maxTxAmount = _tTotal.div(200);
        _numTokensSellToAddToLiquidity = _maxTxAmount.div(10);

        _rOwned[creator] = _rTotal;
        emit Transfer(address(0), creator, _tTotal);

        moonProxy = MoonProxyTemplate(ICloneFactory(cloneFactory).clone(moonProxyTemplate));
        (address youPair,address ethPair) = moonProxy.createPairs(creator, router, address(this), address(YOU));
        _isExcludedFromFee[youPair] = true;
        _isExcludedFromFee[ethPair] = true;

        //exclude owner and the proxy contract from fee
        _isExcludedFromFee[creator] = true;
        _isExcludedFromFee[address(moonProxy)] = true;
        swapAndLiquifyEnabled = true;
        initialized = true;
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

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = msg.sender;
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
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

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint8 taxFee) external onlyOwner {
        require((_liquidityFee + taxFee) < 100, "INVALID_FEE_RATE");
        _taxFee = taxFee;
    }

    function setNumTokensSellToAddToLiquidity(uint256 numTokensSellToAddToLiquidity) external onlyOwner {
        _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity;
    }

    function getNumTokensSellToAddToLiquidity() external view returns (uint256) {
        return _numTokensSellToAddToLiquidity;
    }

    function setLiquidityFeePercent(uint8 liquidityFee) external onlyOwner() {
        require((_taxFee + liquidityFee) < 100, "INVALID_FEE_RATE");
        _liquidityFee = liquidityFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10 ** 2
        );
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
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
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(moonProxy)] = _rOwned[address(moonProxy)].add(rLiquidity);
        if (_isExcluded[address(moonProxy)])
            _tOwned[address(moonProxy)] = _tOwned[address(moonProxy)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10 ** 2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10 ** 2
        );
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != _OWNER_ && to != _OWNER_)
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is YouSwap pair.
        uint256 contractTokenBalance = balanceOf(address(moonProxy));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != moonProxy.youSwapPair() &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        moonProxy.swapAndLiquify(contractTokenBalance);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee)
            removeAllFee();

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

        if (!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}
// File: localhost/lib/Address.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {

    function isNotZero(address account) internal pure returns (bool) {
        return account != address(0);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
        (bool success,) = recipient.call{value : amount}("");
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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

// File: localhost/token/createToken/templates/MintableERC20Template.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

contract MintableERC20Template is InitializableOwnable {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint8) private _minters;

    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    bool public initialized;

    function init(
        address creator,
        uint256 initSupply,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
        require(!initialized, "TOKEN_INITIALIZED");
        initialized = true;

        initOwner(creator);
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = initSupply * 10 ** uint256(decimals);
        _balanceOf[creator] = _totalSupply;
        _minters[creator] = 1;
        emit Transfer(address(0), creator, _totalSupply);
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balanceOf[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "DECREASED_ALLOWANCE_BELOW_ZERO"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "TRANSFER_FROM_THE_ZERO_ADDRESS");
        require(recipient != address(0), "TRANSFER_TO_THE_ZERO_ADDRESS");
        require(amount > 0, "TRANSFER_ZERO_AMOUNT");

        _balanceOf[sender] = _balanceOf[sender].sub(amount, "TRANSFER_AMOUNT_EXCEEDS_BALANCE");
        _balanceOf[recipient] = _balanceOf[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BURN_FROM_THE_ZERO_ADDRESS");
        require(_balanceOf[account] > 0, "INSUFFICIENT_FUNDS");

        _balanceOf[account] = _balanceOf[account].sub(amount, "BURN_AMOUNT_EXCEEDS_BALANCE");
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "APPROVE_FROM_THE_ZERO_ADDRESS");
        require(spender != address(0), "APPROVE_TO_THE_ZERO_ADDRESS");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        uint256 newAllowance = allowance(account, msg.sender).sub(amount, "BURN_AMOUNT_EXCEEDS_ALLOWANCE");

        _approve(account, msg.sender, newAllowance);
        _burn(account, amount);
    }

    modifier isMinter() {
        require(_minters[msg.sender] == 1, "IS_NOT_A_MINTER");
        _;
    }

    function mint(address recipient, uint256 amount) external isMinter {
        _totalSupply = _totalSupply.add(amount);
        _balanceOf[recipient] = _balanceOf[recipient].add(amount);

        emit Transfer(address(0), recipient, amount);
    }

    function addMinter(address account) external onlyOwner {
        require(Address.isNotZero(account), "ZERO_ADDRESS");
        _minters[account] = 1;
    }

    function removeMinter(address account) external onlyOwner {
        _minters[account] = 0;
    }
}
// File: localhost/lib/SafeMath.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

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

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
// File: localhost/token/createToken/templates/ERC20Template.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;


contract ERC20Template {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    bool public initialized;

    function init(
        address creator,
        uint256 initSupply,
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external {
        require(!initialized, "TOKEN_INITIALIZED");

        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = initSupply * 10 ** uint256(decimals);
        _balanceOf[creator] = _totalSupply;
        initialized = true;

        emit Transfer(address(0), creator, _totalSupply);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balanceOf[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE"));
        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "DECREASED_ALLOWANCE_BELOW_ZERO"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "TRANSFER_FROM_THE_ZERO_ADDRESS");
        require(recipient != address(0), "TRANSFER_TO_THE_ZERO_ADDRESS");
        require(amount > 0, "TRANSFER_ZERO_AMOUNT");

        _balanceOf[sender] = _balanceOf[sender].sub(amount, "TRANSFER_AMOUNT_EXCEEDS_BALANCE");
        _balanceOf[recipient] = _balanceOf[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "APPROVE_FROM_THE_ZERO_ADDRESS");
        require(spender != address(0), "APPROVE_TO_THE_ZERO_ADDRESS");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
// File: localhost/interface/ICloneFactory.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}
// File: localhost/interface/IERC20.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
     * @dev Emitted when `amount` tokens are moved from one account (`sender`) to
     * another (`recipient`).
     *
     * Note that `amount` may be zero.
     */
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `amount` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}
// File: localhost/interface/IYouSwapRouter.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

interface IYouSwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapMining() external pure returns (address);

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
// File: localhost/token/createToken/ERC20FactoryV3.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

abstract contract ERC20FactoryV2 {
    function getTokenByUser(address user) virtual external view returns (address[] memory tokens, uint8[] memory tokenTypes);
}

contract ERC20FactoryV3 is Operation {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    address public _CLONE_FACTORY_;
    address public _ERC20_TEMPLATE_;
    address public _MINTABLE_ERC20_TEMPLATE_;
    address public _MOON_ERC20_TEMPLATE_;
    address public _MOON_PROXY_TEMPLATE_;

    uint256 public usdtFeeForStd;
    uint256 public youFeeForStd;

    uint256 public usdtFeeForMintable;
    uint256 public youFeeForMintable;

    uint256 public usdtFeeForMoon;
    uint256 public youFeeForMoon;

    mapping(address => bool) private _isExcludedFromFee;
    Counters.Counter private _issues;

    event NewERC20(address tokenAddress, address creator, bool isMintable, uint8 tokenType);
    event Refund(address recipient, uint256 amount);

    IYouSwapRouter public youSwapRouter;

    IERC20 public YOU;
    IERC20 public USDT;

    // ============ Registry ============
    // creator -> token address list
    mapping(address => address[]) public _USER_REGISTRY_;
    // creator -> token type list
    mapping(address => uint8[]) public _USER_REGISTRY_TYPE_;

    // creator -> amount of YOU used to be refund
    mapping(address => uint256) public _REFUNDS_;
    uint256 private _refundRate = 50;

    ERC20FactoryV2 public factoryV2;
    constructor(
        address cloneFactory,
        address erc20Template,
        address mintableErc20Template,
        address moonErc20Template,
        address moonProxyTemplate
    ) public {
        _CLONE_FACTORY_ = cloneFactory;
        _ERC20_TEMPLATE_ = erc20Template;
        _MINTABLE_ERC20_TEMPLATE_ = mintableErc20Template;
        _MOON_ERC20_TEMPLATE_ = moonErc20Template;
        _MOON_PROXY_TEMPLATE_ = moonProxyTemplate;

        youSwapRouter = IYouSwapRouter(0xA4CE57F063A610290EEEF0564B034278438D06CF);
        YOU = IERC20(0x181801F00df1BD997D38Dd579dBd44bf9b5a6d2D);
        USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);

        factoryV2 = ERC20FactoryV2(0x0f0478CcB18aFCbC738381619f78D80C30c45244);
        
        //100USDT as default
        usdtFeeForStd = 100 * 10 ** uint256(USDT.decimals());
        //100YOU as default
        youFeeForStd = 100 * 10 ** uint256(YOU.decimals());

        //400USDT as default
        usdtFeeForMintable = 400 * 10 ** uint256(USDT.decimals());
        //400YOU as default
        youFeeForMintable = 400 * 10 ** uint256(YOU.decimals());

        //1000USDT as default
        usdtFeeForMoon = 1000 * 10 ** uint256(USDT.decimals());
        //1000YOU as default
        youFeeForMoon = 1000 * 10 ** uint256(YOU.decimals());

        //include issues from V1 and V2
        _issues.moveTo(76);
    }

    function createStdERC20(
        uint256 totalSupply,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint8 feeTokenType //YOU:1 USDT:2
    ) external returns (address newERC20) {
        _takeFeeForStd(feeTokenType);
        newERC20 = ICloneFactory(_CLONE_FACTORY_).clone(_ERC20_TEMPLATE_);
        ERC20Template(newERC20).init(msg.sender, totalSupply, name, symbol, decimals);
        _USER_REGISTRY_[msg.sender].push(newERC20);
        _USER_REGISTRY_TYPE_[msg.sender].push(1);
        _issues.increment();
        emit NewERC20(newERC20, msg.sender, false, 1);
    }

    function createMintableERC20(
        uint256 initSupply,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint8 feeTokenType //YOU:1 USDT:2
    ) external returns (address newMintableERC20) {
        _takeFeeForMintable(feeTokenType);
        newMintableERC20 = ICloneFactory(_CLONE_FACTORY_).clone(_MINTABLE_ERC20_TEMPLATE_);
        MintableERC20Template(newMintableERC20).init(
            msg.sender,
            initSupply,
            name,
            symbol,
            decimals
        );
        _USER_REGISTRY_[msg.sender].push(newMintableERC20);
        _USER_REGISTRY_TYPE_[msg.sender].push(2);
        _issues.increment();
        emit NewERC20(newMintableERC20, msg.sender, true, 2);
    }

    function createMoonERC20(
        uint256 initSupply,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint8 taxFee,
        uint8 liquidityFee,
        uint8 feeTokenType //YOU:1 USDT:2
    ) external returns (address newMoonERC20) {
        _takeFeeForMoon(feeTokenType);
        newMoonERC20 = ICloneFactory(_CLONE_FACTORY_).clone(_MOON_ERC20_TEMPLATE_);
        MoonERC20Template(newMoonERC20).init(
            msg.sender,
            address(YOU),
            address(youSwapRouter),
            initSupply,
            name,
            symbol,
            decimals,
            taxFee,
            liquidityFee,
            _CLONE_FACTORY_,
            _MOON_PROXY_TEMPLATE_
        );
        _USER_REGISTRY_[msg.sender].push(newMoonERC20);
        _USER_REGISTRY_TYPE_[msg.sender].push(3);
        _issues.increment();
        emit NewERC20(newMoonERC20, msg.sender, false, 3);
    }

    function getTokenByUser(address user) external view returns (address[] memory tokens, uint8[] memory tokenTypes){
        (address[] memory tokensV2,uint8[] memory tokenTypesV2) = factoryV2.getTokenByUser(user);
        if (tokensV2.length > 0 && tokensV2.length == tokenTypesV2.length) {
            uint256 lenV2 = tokensV2.length;
            uint256 lenV3 = _USER_REGISTRY_[user].length;

            uint256 len = lenV2 + lenV3;

            address[] memory tokensAll = new address[](len);
            uint8[] memory tokenTypesAll = new uint8[](len);

            for (uint256 i = 0; i < lenV2; i++) {
                tokensAll[i] = tokensV2[i];
                tokenTypesAll[i] = tokenTypesV2[i];
            }

            for (uint256 j = 0; j < lenV3; j++) {
                tokensAll[lenV2 + j] = _USER_REGISTRY_[user][j];
                tokenTypesAll[lenV2 + j] = _USER_REGISTRY_TYPE_[user][j];
            }

            return (tokensAll, tokenTypesAll);
        }
        else {
            return (_USER_REGISTRY_[user], _USER_REGISTRY_TYPE_[user]);
        }
    }

    function excludeFromFee(address account) public onlyGovernance {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public isOperator {
        _isExcludedFromFee[account] = false;
    }

    function _takeFeeForStd(uint8 feeTokenType) private {
        if (_isExcludedFromFee[msg.sender]) return;

        if (feeTokenType == 1) {//YOU
            YOU.safeTransferFrom(msg.sender, address(this), youFeeForStd);
        }
        else {//USDT
            _takeUsdtFee(usdtFeeForStd);
        }

        _REFUNDS_[msg.sender] = _calculateRefund(youFeeForStd);
    }

    function _takeFeeForMintable(uint8 feeTokenType) private {
        if (_isExcludedFromFee[msg.sender]) return;

        if (feeTokenType == 1) {//YOU
            YOU.safeTransferFrom(msg.sender, address(this), youFeeForMintable);
        }
        else {//USDT
            _takeUsdtFee(usdtFeeForMintable);
        }

        _REFUNDS_[msg.sender] = _calculateRefund(youFeeForMintable);
    }

    function _takeFeeForMoon(uint8 feeTokenType) private {
        if (_isExcludedFromFee[msg.sender]) return;

        if (feeTokenType == 1) {//YOU
            YOU.safeTransferFrom(msg.sender, address(this), youFeeForMoon);
        }
        else {//USDT
            _takeUsdtFee(usdtFeeForMoon);
        }

        _REFUNDS_[msg.sender] = _calculateRefund(youFeeForMoon);
    }

    function _calculateRefund(uint256 amount) private view returns (uint256) {
        if (_isExcludedFromFee[msg.sender]) return 0;
        return amount.mul(_refundRate).div(
            10 ** 2
        );
    }

    function _takeUsdtFee(uint256 feeAmount) private {
        USDT.safeTransferFrom(msg.sender, address(this), feeAmount);
        uint256 balanceOfU = USDT.balanceOf(address(this));
        if (balanceOfU >= feeAmount) {
            _swapUSDTForYOU(balanceOfU);
        }
    }

    function _swapUSDTForYOU(uint256 usdtAmount) private {
        // generate the youswap pair path of USDT -> YOU
        address[] memory path = new address[](2);
        path[0] = address(USDT);
        path[1] = address(YOU);

        USDT.safeApprove(address(youSwapRouter), usdtAmount);

        youSwapRouter.swapExactTokensForTokens(
            usdtAmount,
            0, // accept any amount of YOU
            path,
            address(this),
            block.timestamp
        );
    }

    function setUsdtFeeForStd(uint256 newFee) external isOperator {
        usdtFeeForStd = newFee;
    }

    function setYouFeeForStd(uint256 newFee) external isOperator {
        youFeeForStd = newFee;
    }

    function setUsdtFeeForMintable(uint256 newFee) external isOperator {
        usdtFeeForMintable = newFee;
    }

    function setYouFeeForMintable(uint256 newFee) external isOperator {
        youFeeForMintable = newFee;
    }

    function setUsdtFeeForMoon(uint256 newFee) external isOperator {
        usdtFeeForMoon = newFee;
    }

    function setYouFeeForMoon(uint256 newFee) external isOperator {
        youFeeForMoon = newFee;
    }

    function setRefundRate(uint256 newRate) external isOperator {
        require(newRate <= 100, "INVALID_RATE");
        _refundRate = newRate;
    }

    function refundRate() external view returns (uint256) {
        return _refundRate;
    }

    function refund(address user) external isOperator {
        require(_REFUNDS_[user] > 0, "INSUFFICIENT_BALANCE");

        YOU.safeTransfer(user, _REFUNDS_[user]);
        emit Refund(user, _REFUNDS_[user]);
        _REFUNDS_[user] = 0;
    }

    function totalIssues() external view returns (uint256) {
        return _issues.current();
    }

    function withdraw(address token, address recipient, uint256 amount) onlyGovernance external {
        IERC20(token).safeTransfer(recipient, amount);
    }
}