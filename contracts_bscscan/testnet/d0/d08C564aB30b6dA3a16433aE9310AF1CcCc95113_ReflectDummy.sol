// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract ReflectDummy is IERC20, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping (address => uint256) private _reflections;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public excludedFromFee;
    mapping (address => bool) public excludedFromReward;
    uint256 private _totalRatedBalance;
    uint256 private _totalRatedReflection;

    uint256 public totalFees;
    uint256 private _totalSupply;
    uint256 private _totalReflection;

    bool public BRN_ENABLED;
    bool public MRK_ENABLED;
    bool public REF_ENABLED;

    uint256 public taxFee;
    uint256 public liqFee;
    uint256 public brnFee;
    uint256 public mrkFee;
    uint256 public refFee;
    uint256 public feeLimit;                        // up to FLOAT_FACTOR / 2
    uint256 private constant TX_FACTOR = 1e3;       // txLimit <= totalSupply / TX_FACTOR
    uint256 private constant FLOAT_FACTOR = 1e4;

	IUniswapV2Router02 public swapRouter;
	mapping (address => bool) public swapPairs;
    address public swapWETH;

	bool private liqInProgress;
    bool public liqStatus;
	uint256 public liqThreshold;
    uint256 public txLimit;
    address public liquidityAddress;
    address public marketingAddress;
    mapping (address => address) private referrals;

    event UpdateFees(
		uint256 newTaxFee,
		uint256 newLiqFee,
		uint256 newBrnFee,
        uint256 newMrkFee,
        uint256 newRefFee
	);
    event UpdateTxLimit( uint256 newTxLimit );
	event UpdateLiqThreshold( uint256 newLiqThreshold );
	event UpdateLiqStatus( bool newLiqStatus );
    event UpdateLiquidityAddress( address newLiquidityAddress );
    event UpdateMarketingAddress( address newMarketingkAddress );
	event UpdateSwapRouter( address newRouter, address newPair );
	event LiquidityAdded( uint256 indexed tokensToLiqudity, uint256 indexed bnbToLiquidity );
    event ReferralSet(address indexed referrer, address referee);
    event SwapPairUpdated(address indexed pair, bool isMarketPair);

    modifier lockTheSwap {
        liqInProgress = true;
        _;
        liqInProgress = false;
    }

    bool private parametersInitialized;
    address private factory;

    function initToken (
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        bool burn_,
        bool marketing_,
        bool referrals_,
        address router_,
        address owner_
    ) external returns (bool) {
        require(bytes(name_).length != 0, "Empty name");
        require(bytes(symbol_).length != 0, "Empty symbol");
        require(totalSupply_ != 0, "Zero total supply");
        require(router_ != address(0), "Zero Router address");

        __Ownable_init();

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        _totalSupply = totalSupply_ * 10**decimals_;
		_totalReflection = ~uint256(0) - (~uint256(0) % totalSupply_);
        _totalRatedBalance = totalSupply_ * 10**decimals_;
        _totalRatedReflection = ~uint256(0) - (~uint256(0) % totalSupply_);
        _reflections[owner_] = _totalReflection;

        BRN_ENABLED = burn_;
        MRK_ENABLED = marketing_;
        REF_ENABLED = referrals_;

        swapWETH = IUniswapV2Router02(router_).WETH();
        require(swapWETH != address(0), "Wrong router");
        address _swapPair = IUniswapV2Factory(IUniswapV2Router02(router_).factory()).createPair(address(this), swapWETH);
        _updateSwapPair(_swapPair, true);
		swapRouter = IUniswapV2Router02(router_);
        excludeFromReward(_swapPair);
        excludeFromFee(owner_);

        factory = msg.sender;
        transferOwnership(owner_);

        emit Transfer(address(0), owner_, _totalSupply);
        return true;
    }

    function initParameters(
        uint256 taxFee_,
        uint256 liqFee_,
        uint256 brnFee_,
        uint256 mrkFee_,
        uint256 refFee_,
        bool liqStatus_,
        uint256 liqThreshold_,
        uint256 txLimit_,
        address marketingAddress_,
        address liquidityAddress_,
        uint256 feeLimit_
    ) external {
        require(!parametersInitialized, "Token initialized");
        require(msg.sender == factory, "Only factory");
        require(feeLimit_ <= FLOAT_FACTOR/2, "Wrong limit");
        require(taxFee_ <= feeLimit_, "Fee's too high");
        require(liqFee_ <= feeLimit_, "Fee's too high");

        taxFee = taxFee_;
        liqFee = liqFee_;
        liquidityAddress = liquidityAddress_;
        liqStatus = liqStatus_;
        feeLimit = feeLimit_;

        if (BRN_ENABLED) {
            require(brnFee_ <= feeLimit, "Fee's too high");
            brnFee = brnFee_;
        }
        if (MRK_ENABLED) {
            require(mrkFee_ <= feeLimit, "Fee's too high");
            mrkFee = mrkFee_;
            marketingAddress = marketingAddress_;
        }
        if (REF_ENABLED) {
            require(refFee_ <= feeLimit, "Fee's too high");
            refFee = refFee_;
            if (!MRK_ENABLED)
                marketingAddress = marketingAddress_;
        }

        require(txLimit_ <= _totalSupply / TX_FACTOR, "txLimit is too high");
        require(liqThreshold_ <= txLimit_, "liqThreshold is too high");
        txLimit = txLimit_;
        liqThreshold = liqThreshold_;

        parametersInitialized = true;

        emit UpdateFees(taxFee, liqFee, brnFee, mrkFee, refFee);
        emit UpdateTxLimit(txLimit_);
	    emit UpdateLiqThreshold(liqThreshold_);
	    emit UpdateLiqStatus( true );
        emit UpdateLiquidityAddress(liquidityAddress_);
        emit UpdateMarketingAddress(marketingAddress_);
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
        return _totalSupply;
    }

    function getOwner() public view returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (excludedFromReward[account]) return _balances[account];
        return _reflections[account] / _getRate();
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner_, address spender, uint256 amount) private {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function distribute(uint256 amount) external {
        require(!excludedFromReward[msg.sender], "Not for excluded");
        uint256 rAmount = amount * _getRate();
        _reflections[msg.sender] -= amount;
        _totalReflection -= rAmount;
        totalFees += amount;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!excludedFromReward[account], "Already excluded");

        uint256 currentReflection = _reflections[account];
        if(currentReflection > 0) {
            uint256 currentBalance = currentReflection / _getRate();
            _balances[account] = currentBalance;
            _totalRatedBalance -= currentBalance;
            _totalRatedReflection -= currentReflection;

            _reflections[account] = 0;
        }

        excludedFromReward[account] = true;
    }

    function includeInReward(address account) external onlyOwner {
        require(excludedFromReward[account], "Not excluded");

        uint256 currentBalance = _balances[account];
        if(currentBalance > 0) {
            uint256 currentReflection = currentBalance * _getRate();

            _totalRatedBalance += currentBalance;
            _totalRatedReflection += currentReflection;
            _reflections[account] = currentReflection;

            _balances[account] = 0;
        }

        excludedFromReward[account] = false;
    }

    function excludeFromFee(address account) public onlyOwner {
        require(!swapPairs[account], "Not for Pair address");
        excludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        delete excludedFromFee[account];
    }

    function setFee(uint256 newTaxFee, uint256 newLiqFee, uint256 newBrnFee, uint256 newMrkFee, uint256 newRefFee) external onlyOwner {
        require(newTaxFee <= feeLimit, "Fee's too high");
        require(newLiqFee <= feeLimit, "Fee's too high");
        taxFee = newTaxFee;
        liqFee = newLiqFee;

        if (BRN_ENABLED) {
            require(newBrnFee <= feeLimit, "Fee's too high");
            brnFee = newBrnFee;
        }
        if (MRK_ENABLED) {
            require(newMrkFee <= feeLimit, "Fee's too high");
            mrkFee = newMrkFee;
        }
        if (REF_ENABLED) {
            require(newRefFee <= feeLimit, "Fee's too high");
            refFee = newRefFee;
        }

        emit UpdateFees(taxFee, liqFee, brnFee, mrkFee, refFee);
    }

	function setLiquifyStatus(bool newStatus) external onlyOwner {
	    liqStatus = newStatus;

		emit UpdateLiqStatus(newStatus);
    }

	function setLiquifyThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold <= txLimit, "Threshold exceeds txLimit");
	    liqThreshold = newThreshold;

		emit UpdateLiqThreshold(newThreshold);
    }

    function setLiquidyAddress(address newLiquidityAddress) external onlyOwner {
	    liquidityAddress = newLiquidityAddress;

		emit UpdateLiquidityAddress(newLiquidityAddress);
    }

    function setMarketingAddress(address newMarketingAddress) external onlyOwner {
        require(MRK_ENABLED, "Denied");
		require(newMarketingAddress != address(0), "Zero address");
		marketingAddress = newMarketingAddress;

        emit UpdateMarketingAddress(newMarketingAddress);
    }

    function setReferral(address referralAddress) external {
        require(REF_ENABLED, "Denied");
        referrals[msg.sender] = referralAddress;

        emit ReferralSet(referralAddress, msg.sender);
    }

    function setTxLimit(uint256 newTxLimit) external onlyOwner {
        require(newTxLimit >= liqThreshold, "txLimit is below liqThreshold");
        require(newTxLimit <= _totalSupply / TX_FACTOR, "txLimit is too high");
	    txLimit = newTxLimit;

		emit UpdateTxLimit(newTxLimit);
    }

    function setSwapRouter(IUniswapV2Router02 newRouter) external onlyOwner {
		address newPair = IUniswapV2Factory(newRouter.factory()).getPair(address(this), newRouter.WETH());
		require(newPair != address(0), "Pair doesn't exist");
        swapRouter = newRouter;
		_updateSwapPair(newPair, true);
        swapWETH = newRouter.WETH();
        require(swapWETH != address(0), "Wrong router");
		excludeFromReward(newPair);

		emit UpdateSwapRouter(address(newRouter), newPair);
    }

    function updateSwapPair(address pair, bool isPair) external onlyOwner {
        _updateSwapPair(pair, isPair);
    }

    function _updateSwapPair(address pair, bool isPair) internal {
        require(swapPairs[pair] != isPair, "Pair already set");
        swapPairs[pair] = isPair;

        emit SwapPairUpdated(pair, isPair);
    }

    function _getRate() public view returns(uint256) {
        uint256 totalSupply_ = _totalSupply;
        uint256 totalReflection_ = _totalReflection;
        uint256 totalRatedBalance_ = _totalRatedBalance;

        if (totalRatedBalance_ == 0) return (_totalReflection / _totalSupply);
        return ( _totalRatedReflection / totalRatedBalance_ );
    }

    function _takeLiquidity(uint256 amount, uint256 rate) private {
        uint256 rAmount = amount * rate;

        if( excludedFromReward[address(this)] ) {
            _balances[address(this)] += amount;
            _totalRatedBalance -= amount;
            _totalRatedReflection -= rAmount;
            return;
        }
        _reflections[address(this)] += rAmount;
    }

    function _getFeeValues(uint256 amount, bool takeFee) private view returns (uint256 _tax, uint256 _liq, uint256 _brn, uint256 _mrk, uint256 _ref) {
        if (takeFee) {
            _tax = amount * taxFee / FLOAT_FACTOR;
            _liq = amount * liqFee / FLOAT_FACTOR;
            if (BRN_ENABLED)
                _brn = amount * brnFee / FLOAT_FACTOR;
            if (MRK_ENABLED)
                _mrk = amount * mrkFee / FLOAT_FACTOR;
            if (REF_ENABLED)
                _ref = amount * refFee / FLOAT_FACTOR;
        }
    }

    function _reflectFee(uint256 amount, uint256 rate, bool takeFee) private returns (uint256, uint256){
        (uint256 tax, uint256 liq, uint256 brn, uint256 mrk, uint256 ref) = _getFeeValues(amount, takeFee);
        _totalReflection -= tax * rate;
        totalFees += tax;

        if (BRN_ENABLED) {
            _totalSupply -= brn;
            _totalReflection -= brn * rate;
        }
        if (REF_ENABLED) {
            uint256 mrk_;
            if (MRK_ENABLED)
                mrk_ = mrk;
            address referralAddress = referrals[msg.sender];
            if(referralAddress == address(0)) {
                _takeFee(marketingAddress, mrk_ + ref, rate);
            } else {
                _takeFee(marketingAddress, mrk_, rate);
                _takeFee(msg.sender, ref/2, rate);
                _takeFee(referralAddress, ref - ref/2, rate);
            }
        } else if (MRK_ENABLED) {
            _takeFee(marketingAddress, mrk, rate);
        }

        return ((tax + liq + brn + mrk + ref), liq);
    }

    function _takeFee(address recipient, uint256 amount, uint256 rate) private {
        if (amount == 0 ) return;
        uint256 rAmount = amount * rate;

        if ( excludedFromReward[recipient] ) {
            _balances[recipient] += amount;
            _totalRatedBalance -= amount;
            _totalRatedReflection -= rAmount;
            return;
        }
        _reflections[recipient] += rAmount;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        address owner_ = owner();
        if(from != owner_ && to != owner_) require(amount <= txLimit, "txLimit exceeded");

        bool liquifyReady = (   balanceOf(address(this)) >= liqThreshold &&
                                !liqInProgress &&
                                liqStatus &&
                                !swapPairs[from]   );
        if (liquifyReady)
            _swapAndLiquify(liqThreshold);

        uint256 rate = _getRate();
        bool takeFee = !(excludedFromFee[from] || excludedFromFee[to]);
        (uint256 feesAmount, uint256 liqAmount) = _reflectFee(amount, rate, takeFee);
        _takeLiquidity(liqAmount, rate);
        _updateBalances(from, to, amount, rate, feesAmount);
    }

    function _updateBalances(address from, address to, uint256 amount, uint256 rate, uint256 fees) private {
        uint256 rAmount = amount * rate;
        uint256 transferAmount = amount - fees;
        uint256 rTransferAmount = rAmount - fees*rate;

        if (excludedFromReward[from]) {
            _balances[from] -= amount;
            _totalRatedBalance += amount;
            _totalRatedReflection += rAmount;
        } else {
            _reflections[from] -= rAmount;
        }
        if (excludedFromReward[to]) {
            _balances[to] += transferAmount;
            _totalRatedBalance -= transferAmount;
            _totalRatedReflection -= rTransferAmount;
        } else {
            _reflections[to] += rTransferAmount;
        }
    }

    function _swapAndLiquify(uint256 amount) private lockTheSwap {
        uint256 half = amount / 2;
        amount -= half;

        uint256 balance = address(this).balance;
        _swapTokensForBNB(half);

        emit LiquidityAdded(amount, balance);
    }

    function _swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapWETH;

        _approve(address(this), address(swapRouter), tokenAmount);
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

	function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(swapRouter), tokenAmount);
        swapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityAddress,
            block.timestamp
        );
    }

    receive() external payable {
        require(liqInProgress, "Only for swaps");
    }

	function recoverLockedTokens(address receiver, address token) external onlyOwner returns(uint256 balance){
        require(token != address(this), "Only 3rd party");
        if( token == address(0)) {
			balance = address(this).balance;
			payable(receiver).transfer(balance);
            return balance;
		}
        balance = IERC20(token).balanceOf(address(this));
		IERC20(token).safeTransfer(receiver, balance);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity >=0.6.2;

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

