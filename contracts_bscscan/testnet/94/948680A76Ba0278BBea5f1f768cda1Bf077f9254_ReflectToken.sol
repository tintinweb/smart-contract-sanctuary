/*

        ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗███████╗██╗░░██╗
        ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝
        ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░█████╗░░░╚███╔╝░
        ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██╔══╝░░░██╔██╗░
        ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░███████╗██╔╝╚██╗
        ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝

 Token is created with CryptEx token constructor, uses Reflect.finance model.

 • website:                           https://cryptexlock.me
 • medium:                            https://medium.com/cryptex-locker
 • Telegram Announcements Channel:    https://t.me/CryptExAnnouncements
 • Telegram Main Channel:             https://t.me/cryptexlocker
 • Twitter Page:                      https://twitter.com/ExLocker
 • Reddit:                            https://www.reddit.com/r/CryptExLocker/

 SPDX-License-Identifier: UNLICENSED

*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract ReflectToken is IERC20, Ownable {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => uint256) private _reflections;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public excludedFromFee;
    mapping(address => bool) public excludedFromReward;
    uint256 private _totalRatedBalance;
    uint256 private _totalRatedReflection;

    uint256 public totalFees;
    uint256 private _totalSupply;
    uint256 private _totalReflection;

    bool public immutable BRN_ENABLED;
    bool public immutable MRK_ENABLED;
    bool public immutable REF_ENABLED;

    uint256 public taxFee;
    uint256 public liqFee;
    uint256 public brnFee;
    uint256 public mrkFee;
    uint256 public refFee;
    uint256 private immutable feeLimit; // up to FLOAT_FACTOR / 2
    uint256 private constant TX_FACTOR = 1e3; // txLimit <= totalSupply / TX_FACTOR
    uint256 private constant FLOAT_FACTOR = 1e4;
    uint256 private constant MAX = type(uint256).max;

    IUniswapV2Router02 public swapRouter;
    mapping(address => bool) public swapPairs;
    address private swapWETH;

    bool private _liqInProgress;
    bool public liqStatus;
    uint256 private liqThreshold;
    uint256 public txLimit;
    address public liquidityAddress;
    address public marketingAddress;
    mapping(address => address) private referrals;

    event UpdateFees(
        uint256 newTaxFee,
        uint256 newLiqFee,
        uint256 newBrnFee,
        uint256 newMrkFee,
        uint256 newRefFee
    );
    event UpdateTxLimit(uint256 newTxLimit);
    event UpdateLiqThreshold(uint256 newLiqThreshold);
    event UpdateLiqStatus(bool newLiqStatus);
    event UpdateLiquidityAddress(address newLiquidityAddress);
    event UpdateMarketingAddress(address newMarketingkAddress);
    event UpdateSwapRouter(address newRouter, address newPair);
    event LiquidityAdded(
        uint256 indexed tokensToLiqudity,
        uint256 indexed bnbToLiquidity
    );
    event ReferralSet(address indexed referrer, address referee);
    event SwapPairUpdated(address indexed pair, bool isMarketPair);

    modifier lockTheSwap() {
        _liqInProgress = true;
        _;
        _liqInProgress = false;
    }

    /**
    * @param flags_ boolean parameters:
                    [0] burning fee on transfers, cannot be updated after creation
                    [1] marketing fee on transfers, cannot be updated after creation
                    [2] referrals fee on transfers, cannot be updated after creation
                    [3] autoLiquify flag, updatable by the owner after creation
    * @param feesAndLimits_ uint256 parameters:
                    [0] totalSupply, initial token amount in wei
                    [1] taxFee on transfers, updatable within limits after creation
                    [2] liquidityFee on transfers, updatable within limits after creation
                    [3] burnFee on transfers, only if _flags[0] is set
                    [4] marketingFee on transfers, only if _flags[1] is set
                    [5] referralFee on transfers, only if _flags[2] is set
                    [6] feeLimit of total fees, cannot be updated after creation
                    [7] liquidityThreshold, min amount of tokens to be swapped on transfers
                    [8] txLimit, max amount of transfer for non-privileged users
    * @param addresses_ address parameters:
                    [0] owner, receives totalSupply and controls the parameters
                    [1] Uniswap-like router for autoLiquify on transfers, must have WETH() function
                    [2] liquidityAddress to accumulate LP tokens from autoLiquify process
                    [3] marketingAddress, only if _flags[1] is set
    */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        bool[4] memory flags_,
        uint256[9] memory feesAndLimits_,
        address[4] memory addresses_
    ) {
        require(bytes(name_).length != 0, "Empty name");
        require(bytes(symbol_).length != 0, "Empty symbol");
        require(feesAndLimits_[0] != 0, "Zero total supply");
        require(addresses_[1] != address(0), "Zero Router address");

        require(feesAndLimits_[6] <= FLOAT_FACTOR / 2, "Wrong limit");
        require(
            feesAndLimits_[1] +
                feesAndLimits_[2] +
                feesAndLimits_[3] +
                feesAndLimits_[4] +
                feesAndLimits_[5] <=
                feesAndLimits_[6],
            "Fee's too high"
        );

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        _totalSupply = feesAndLimits_[0];
        _totalReflection = MAX - (MAX % feesAndLimits_[0]);
        _totalRatedBalance = feesAndLimits_[0];
        _totalRatedReflection = MAX - (MAX % feesAndLimits_[0]);
        _reflections[addresses_[0]] = _totalReflection;

        BRN_ENABLED = flags_[0];
        MRK_ENABLED = flags_[1];
        REF_ENABLED = flags_[2];

        taxFee = feesAndLimits_[1];
        liqFee = feesAndLimits_[2];
        liquidityAddress = addresses_[2];
        liqStatus = flags_[3];
        feeLimit = feesAndLimits_[6];

        if (flags_[0]) {
            brnFee = feesAndLimits_[3];
        }
        if (flags_[1]) {
            mrkFee = feesAndLimits_[4];
            marketingAddress = addresses_[3];
        }
        if (flags_[2]) {
            refFee = feesAndLimits_[5];
            if (!flags_[1]) marketingAddress = addresses_[3];
        }

        require(
            feesAndLimits_[8] <= feesAndLimits_[0] / TX_FACTOR,
            "txLimit is too high"
        );
        require(
            feesAndLimits_[7] <= feesAndLimits_[8],
            "liqThreshold is too high"
        );
        txLimit = feesAndLimits_[8];
        liqThreshold = feesAndLimits_[7];

        swapWETH = IUniswapV2Router02(addresses_[1]).WETH();
        require(swapWETH != address(0), "Wrong router");
        address _swapPair = IUniswapV2Factory(
            IUniswapV2Router02(addresses_[1]).factory()
        ).createPair(address(this), swapWETH);
        _updateSwapPair(_swapPair, true);
        swapRouter = IUniswapV2Router02(addresses_[1]);
        excludeFromReward(_swapPair);
        excludeFromFee(addresses_[0]);

        transferOwnership(addresses_[0]);
        emit Transfer(address(0), addresses_[0], feesAndLimits_[0]);
        emit UpdateFees(
            feesAndLimits_[1],
            feesAndLimits_[2],
            feesAndLimits_[3],
            feesAndLimits_[4],
            feesAndLimits_[5]
        );
        emit UpdateTxLimit(feesAndLimits_[8]);
        emit UpdateLiqThreshold(feesAndLimits_[7]);
        emit UpdateLiqStatus(flags_[3]);
        emit UpdateLiquidityAddress(addresses_[2]);
        emit UpdateMarketingAddress(addresses_[3]);
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

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner_, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner_,
        address spender,
        uint256 amount
    ) private {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
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
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        if (currentReflection > 0) {
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
        if (currentBalance > 0) {
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

    function setFee(
        uint256 newTaxFee,
        uint256 newLiqFee,
        uint256 newBrnFee,
        uint256 newMrkFee,
        uint256 newRefFee
    ) external onlyOwner {
        require(
            newTaxFee + newLiqFee + newBrnFee + newMrkFee + newRefFee <=
                feeLimit,
            "Fee's too high"
        );
        taxFee = newTaxFee;
        liqFee = newLiqFee;

        if (BRN_ENABLED) {
            brnFee = newBrnFee;
        }
        if (MRK_ENABLED) {
            mrkFee = newMrkFee;
        }
        if (REF_ENABLED) {
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

    function setMarketingAddress(address newMarketingAddress)
        external
        onlyOwner
    {
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
        address newPair = IUniswapV2Factory(newRouter.factory()).getPair(
            address(this),
            newRouter.WETH()
        );
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

    function _getRate() public view returns (uint256) {
        uint256 totalRatedBalance_ = _totalRatedBalance;

        if (totalRatedBalance_ == 0) return (_totalReflection / _totalSupply);
        return (_totalRatedReflection / totalRatedBalance_);
    }

    function _takeLiquidity(uint256 amount, uint256 rate) private {
        uint256 rAmount = amount * rate;

        if (excludedFromReward[address(this)]) {
            _balances[address(this)] += amount;
            _totalRatedBalance -= amount;
            _totalRatedReflection -= rAmount;
            return;
        }
        _reflections[address(this)] += rAmount;
    }

    function _getFeeValues(uint256 amount, bool takeFee)
        private
        view
        returns (
            uint256 _tax,
            uint256 _liq,
            uint256 _brn,
            uint256 _mrk,
            uint256 _ref
        )
    {
        if (takeFee) {
            _tax = (amount * taxFee) / FLOAT_FACTOR;
            _liq = (amount * liqFee) / FLOAT_FACTOR;
            if (BRN_ENABLED) _brn = (amount * brnFee) / FLOAT_FACTOR;
            if (MRK_ENABLED) _mrk = (amount * mrkFee) / FLOAT_FACTOR;
            if (REF_ENABLED) _ref = (amount * refFee) / FLOAT_FACTOR;
        }
    }

    function _reflectFee(
        uint256 amount,
        uint256 rate,
        bool takeFee
    ) private returns (uint256, uint256) {
        (
            uint256 tax,
            uint256 liq,
            uint256 brn,
            uint256 mrk,
            uint256 ref
        ) = _getFeeValues(amount, takeFee);
        _totalReflection -= tax * rate;
        totalFees += tax;

        if (BRN_ENABLED) {
            _totalSupply -= brn;
            _totalReflection -= brn * rate;
        }
        if (REF_ENABLED) {
            uint256 mrk_;
            if (MRK_ENABLED) mrk_ = mrk;
            address referralAddress = referrals[msg.sender];
            if (referralAddress == address(0)) {
                _takeFee(marketingAddress, mrk_ + ref, rate);
            } else {
                _takeFee(marketingAddress, mrk_, rate);
                _takeFee(msg.sender, ref / 2, rate);
                _takeFee(referralAddress, ref - ref / 2, rate);
            }
        } else if (MRK_ENABLED) {
            _takeFee(marketingAddress, mrk, rate);
        }

        return ((tax + liq + brn + mrk + ref), liq);
    }

    function _takeFee(
        address recipient,
        uint256 amount,
        uint256 rate
    ) private {
        if (amount == 0) return;
        uint256 rAmount = amount * rate;

        if (excludedFromReward[recipient]) {
            _balances[recipient] += amount;
            _totalRatedBalance -= amount;
            _totalRatedReflection -= rAmount;
            return;
        }
        _reflections[recipient] += rAmount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(to != address(0), "ERC20: transfer to the zero address");
        address owner_ = owner();
        if (from != owner_ && to != owner_)
            require(amount <= txLimit, "txLimit exceeded");

        uint256 _liqThreshold = liqThreshold;
        bool liquifyReady = (balanceOf(address(this)) >= _liqThreshold &&
            !_liqInProgress &&
            liqStatus &&
            !swapPairs[from]);
        if (liquifyReady) _swapAndLiquify(_liqThreshold);

        uint256 rate = _getRate();
        bool takeFee = !(excludedFromFee[from] || excludedFromFee[to]);
        (uint256 feesAmount, uint256 liqAmount) = _reflectFee(
            amount,
            rate,
            takeFee
        );
        _takeLiquidity(liqAmount, rate);
        _updateBalances(from, to, amount, rate, feesAmount);
    }

    function _updateBalances(
        address from,
        address to,
        uint256 amount,
        uint256 rate,
        uint256 fees
    ) private {
        uint256 rAmount = amount * rate;
        uint256 transferAmount = amount - fees;
        uint256 rTransferAmount = rAmount - fees * rate;

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

    function _swapAndLiquify(uint256 amount) internal lockTheSwap {
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
        require(_liqInProgress, "Only for swaps");
    }

    function recoverLockedTokens(address receiver, address token)
        external
        onlyOwner
        returns (uint256 balance)
    {
        require(token != address(this), "Only 3rd party");
        if (token == address(0)) {
            balance = address(this).balance;
            payable(receiver).transfer(balance);
            return balance;
        }
        balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(receiver, balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

