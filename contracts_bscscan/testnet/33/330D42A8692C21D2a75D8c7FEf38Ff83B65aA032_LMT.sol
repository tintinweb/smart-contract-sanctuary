// Protocol by team BloctechSolutions.com

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier:MIT

// BEP20 token standard interface
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `_account`.
     */
    function balanceOf(address _account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's _account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Emitted when `value` tokens are moved from one _account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IdexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IdexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the _account sending and
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an _account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner _account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
     * @dev Throws if called by any _account other than the owner.
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
     * @dev Transfers ownership of the contract to a new _account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    /**
     * @dev set the owner for the first time.
     * Can only be called by the contract or deployer.
     */
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Main token Contract

contract LMT is Context, IBEP20, Ownable {
    // all private variables and functions are only for contract use

    string private _name = "Looney Moons Token"; // token name

    string private _symbol = "LMT"; // token ticker

    uint8 private _decimals = 9; // token decimals

    uint256 private _tTotal = 1 * 1e9 * 10**_decimals; // total supply

    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _totalDistributed;
    uint256 public marketFee = 500; // 5% will go to the marketAddress pool
    uint256 public lotteryFee = 100; // 1% will go to the lotteryAddress address
    uint256 public initialRewardFee = 100; // 1% will go to the rewardAddress address
    uint256 public rewardFee = initialRewardFee; // 1% will go to the rewardAddress address
    uint256 public incFeePercent = 5; // will be 0.05% percent per buy transaction
    uint256 public maxIncFeePercent = 1400; // max reward fee will be 14%
    uint256 public divider = 10000; // percent divider

    address[] public holders;
    address[] public winners;
    address public marketWallet; // marketing and development wallet address
    address public dexPair; // LP pair address

    bool public feeStatus = true; // should be false to charge fee
    bool public isLotteryEnable = true; // distribute lottery if true
    bool public tradingOpen; //once switched on, can never be switched off.

    // for smart contract use
    uint256 private _currentRewardFee;
    uint256 private _currentLotteryFee;
    uint256 private _currentMarketFee;
    uint256 private _excludedTSupply;
    uint256 private _excludedRSupply;
    uint256 private _lotteryFeeCount;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReward;
    mapping(address => bool) private _isExcludedFromLottery;

    // constructor for initializing the contract
    constructor(address payable _marketWallet) {
        _rOwned[owner()] = _rTotal;
        marketWallet = _marketWallet;

        IdexRouter _dexRouter = IdexRouter(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
        // Create a dex pair for this new token
        dexPair = IdexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        //exclude owner and this contract from Lottery
        _isExcludedFromLottery[owner()] = true;
        _isExcludedFromLottery[address(this)] = true;
        _isExcludedFromLottery[dexPair] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    // token standards by Blockchain

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

    function balanceOf(address _account)
        public
        view
        override
        returns (uint256)
    {
        if (_isExcludedFromReward[_account]) return _tOwned[_account];
        return tokenFromReflection(_rOwned[_account]);
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
            _allowances[sender][_msgSender()] - (amount)
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
            _allowances[_msgSender()][spender] + (addedValue)
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
            _allowances[_msgSender()][spender] - (subtractedValue)
        );
        return true;
    }

    // public view able functions

    // to check wether the address is excluded from reward or not
    function isExcludedFromReward(address _account) public view returns (bool) {
        return _isExcludedFromReward[_account];
    }

    // to check wether the address is excluded from Lottery or not
    function isExcludedFromLottery(address _account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromLottery[_account];
    }

    // to check wether the address is excluded from fee or not
    function isExcludedFromFee(address _account) public view returns (bool) {
        return _isExcludedFromFee[_account];
    }

    // to check how much tokens get redistributed among holders till now
    function totalHolderDistribution() public view returns (uint256) {
        return _totalDistributed;
    }

    // For manual distribution to the holders
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcludedFromReward[sender],
            "BEP20: Excluded addresses cannot call this function"
        );
        uint256 rAmount = tAmount * (_getRate());
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rTotal = _rTotal - (rAmount);
        _totalDistributed = _totalDistributed + (tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "BEP20: Amount must be less than supply");
        if (!deductTransferFee) {
            uint256 rAmount = tAmount * (_getRate());
            return rAmount;
        } else {
            uint256 rAmount = tAmount * (_getRate());
            uint256 rTransferAmount = rAmount -
                (totalFeePerTx(tAmount) * (_getRate()));
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
            "BEP20: Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / (currentRate);
    }

    // setter functions for owner

    // to include any address in reward
    function includeInReward(address _account) external onlyOwner {
        require(
            _isExcludedFromReward[_account],
            "BEP20: _Account is already excluded"
        );
        _excludedTSupply = _excludedTSupply - (_tOwned[_account]);
        _excludedRSupply = _excludedRSupply - (_rOwned[_account]);
        _rOwned[_account] = _tOwned[_account] * (_getRate());
        _tOwned[_account] = 0;
        _isExcludedFromReward[_account] = false;
    }

    //to include any address in reward
    function excludeFromReward(address _account) public onlyOwner {
        require(
            !_isExcludedFromReward[_account],
            "BEP20: _Account is already excluded"
        );
        if (_rOwned[_account] > 0) {
            _tOwned[_account] = tokenFromReflection(_rOwned[_account]);
        }
        _isExcludedFromReward[_account] = true;
        _excludedTSupply = _excludedTSupply + (_tOwned[_account]);
        _excludedRSupply = _excludedRSupply + (_rOwned[_account]);
    }

    //to include or exludde  any address from fee
    function includeOrExcludeFromFee(address _account, bool _value)
        public
        onlyOwner
    {
        _isExcludedFromFee[_account] = _value;
    }

    //to include or exludde  any address from Lottery
    function includeOrExcludeFromLottery(address _account, bool _value)
        public
        onlyOwner
    {
        _isExcludedFromLottery[_account] = _value;
    }

    //only owner can change TaxFeePercent any time after deployment
    function setTaxFeePercent(
        uint256 _rewardFee,
        uint256 _lotteryFee,
        uint256 _marketFee,
        uint256 _divider
    ) external onlyOwner {
        rewardFee = _rewardFee;
        lotteryFee = _lotteryFee;
        marketFee = _marketFee;
        divider = _divider;
    }

    //only owner can change Percent any time after deployment
    function setTaxFeePercent(
        uint256 _incFee,
        uint256 _maxIncFee
    ) external onlyOwner {
        incFeePercent = _incFee;
        maxIncFeePercent = _maxIncFee;
    }

    //To enable or disable Tax fees
    function enableOrDisableFees(bool _state) external onlyOwner {
        feeStatus = _state;
    }

    //To enable or disable lottery
    function enableOrDisableLottery(bool _state) external onlyOwner {
        isLotteryEnable = _state;
    }

    // owner can change marketing and development address
    function setMarketWalletAddress(address payable _newAddress)
        external
        onlyOwner
    {
        marketWallet = _newAddress;
    }

    // owner can change LP token address
    function setLPAddres(address _dexPair) external onlyOwner {
        dexPair = _dexPair;
    }

    // owner can only enable the trading after launch
    function startTrading() external onlyOwner {
        tradingOpen = true;
    }

    // owner can remove stuck tokens in case of any issue
    function removeStuckToken(address _token, uint256 _amount)
        external
        onlyOwner
    {
        IBEP20(_token).transfer(owner(), _amount);
    }

    // internal functions for contract use

    function totalFeePerTx(uint256 tAmount) internal view returns (uint256) {
        uint256 percentage = (tAmount *
            (_currentRewardFee + (_currentLotteryFee) + (_currentMarketFee))) /
            (divider);
        return percentage;
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / (tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        rSupply = rSupply - (_excludedRSupply);
        tSupply = tSupply - (_excludedTSupply);
        if (rSupply < _rTotal / (_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function removeAllFee() private {
        _currentRewardFee = 0;
        _currentLotteryFee = 0;
        _currentMarketFee = 0;
    }

    function setTaxFee() private {
        _currentRewardFee = rewardFee;
        _currentLotteryFee = lotteryFee;
        _currentMarketFee = marketFee;
    }

    function luckyDraw(
        uint256 from,
        uint256 to,
        uint256 amount
    ) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number +
                        amount
                )
            )
        );
        return mod(seed, to - from) + from;
    }

    function mod(uint256 a, uint256 b) private pure returns (uint256) {
        require(b != 0, "BEP20: modulo by zero");
        return a % b;
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

    // base function to transafer tokens
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "BEP20: transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            if (!tradingOpen) {
                require(
                    from != dexPair && to != dexPair,
                    "Trading is not enabled"
                );
            }
        }

        if (balanceOf(to) == 0 && !_isExcludedFromLottery[to]) {
            holders.push(to);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any _account belongs to _isExcludedFromFee _account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || !feeStatus) {
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
        // transaction handler

        if (!takeFee) {
            removeAllFee();
        } else {
            if (sender == dexPair) {
                // reward fee increment handler
                if (rewardFee < maxIncFeePercent) {
                    rewardFee += incFeePercent;
                } else {
                    rewardFee = initialRewardFee;
                    // lottery handler
                    if (isLotteryEnable) {
                        address winner;
                        bool winnerFound = true;
                        while (winnerFound) {
                            uint256 winnerIndex = luckyDraw(
                                0,
                                holders.length,
                                amount
                            );
                            winner = holders[winnerIndex];
                            if (
                                balanceOf(winner) > 0 &&
                                !_isExcludedFromLottery[winner]
                            ) {
                                winnerFound = false;
                            }
                        }
                        winners.push(winner);
                        if (_lotteryFeeCount > 0) {
                            giveLottery(winner);
                        }
                    }
                }
            }
            setTaxFee();
        }

        // check if sender or reciver excluded from reward then do transfer accordingly
        if (
            _isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]
        ) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (
            !_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]
        ) {
            _transferToExcluded(sender, recipient, amount);
        } else if (
            _isExcludedFromReward[sender] && _isExcludedFromReward[recipient]
        ) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    // if both sender and receiver are not excluded from reward
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 currentFeeAmount = totalFeePerTx(tAmount);
        uint256 tTransferAmount = tAmount - (currentFeeAmount);
        uint256 rAmount = tAmount * (currentRate);
        uint256 rTransferAmount = rAmount - (currentFeeAmount * (currentRate));
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLotteryFee(sender, tAmount, currentRate);
        _takeMarketFee(sender, tAmount, currentRate);
        _reflectFee(tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // if receiver is excluded from reward
    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 currentFeeAmount = totalFeePerTx(tAmount);
        uint256 tTransferAmount = tAmount - (currentFeeAmount);
        uint256 rAmount = tAmount * (currentRate);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _excludedTSupply = _excludedTSupply + (tAmount);
        _takeLotteryFee(sender, tAmount, currentRate);
        _takeMarketFee(sender, tAmount, currentRate);
        _reflectFee(tAmount);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    // if sender is excluded from reward
    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 currentFeeAmount = totalFeePerTx(tAmount);
        uint256 tTransferAmount = tAmount - (currentFeeAmount);
        uint256 rAmount = tAmount * (currentRate);
        uint256 rTransferAmount = rAmount - (currentFeeAmount * (currentRate));
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _excludedTSupply = _excludedTSupply - (tAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLotteryFee(sender, tAmount, currentRate);
        _takeMarketFee(sender, tAmount, currentRate);
        _reflectFee(tAmount);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    // if both sender and receiver are excluded from reward
    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 currentFeeAmount = totalFeePerTx(tAmount);
        uint256 tTransferAmount = tAmount - (currentFeeAmount);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _excludedTSupply = _excludedTSupply - (tAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _excludedTSupply = _excludedTSupply + (tAmount);
        _takeLotteryFee(sender, tAmount, currentRate);
        _takeMarketFee(sender, tAmount, currentRate);
        _reflectFee(tAmount);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    // take fees for lottery
    function _takeLotteryFee(
        address sender,
        uint256 tAmount,
        uint256 currentRate
    ) internal {
        uint256 tFee = (tAmount * (_currentLotteryFee)) / (divider);
        uint256 rFee = tFee * (currentRate);
        if (_isExcludedFromReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + (tFee);
        else _rOwned[address(this)] = _rOwned[address(this)] + (rFee);
        _lotteryFeeCount += tFee;

        emit Transfer(sender, address(this), tFee);
    }

    // take fees for marketing and development
    function _takeMarketFee(
        address sender,
        uint256 tAmount,
        uint256 currentRate
    ) internal {
        uint256 tFee = (tAmount * (_currentMarketFee)) / (divider);
        uint256 rFee = tFee * (currentRate);
        if (_isExcludedFromReward[marketWallet])
            _tOwned[marketWallet] = _tOwned[marketWallet] + (tFee);
        else _rOwned[marketWallet] = _rOwned[marketWallet] + (rFee);

        emit Transfer(sender, marketWallet, tFee);
    }

    // for automatic redistribution among all holders on each tx
    function _reflectFee(uint256 tAmount) private {
        uint256 tFee = (tAmount * (_currentRewardFee)) / (divider);
        uint256 rFee = tFee * (_getRate());
        _rTotal = _rTotal - (rFee);
        _totalDistributed = _totalDistributed + (tFee);
    }

    // lottery distributor
    function giveLottery(address winner) internal {
        uint256 winningAmount = _lotteryFeeCount;
        uint256 rWinningAmount = winningAmount * _getRate();
        if (_isExcludedFromReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] - (winningAmount);
        else _rOwned[address(this)] = _rOwned[address(this)] - (rWinningAmount);
        if (_isExcludedFromReward[winner])
            _tOwned[winner] = _tOwned[winner] + (winningAmount);
        else _rOwned[winner] = _rOwned[winner] + (rWinningAmount);
        _lotteryFeeCount = 0;

        emit Transfer(address(this), winner, winningAmount);
    }
}