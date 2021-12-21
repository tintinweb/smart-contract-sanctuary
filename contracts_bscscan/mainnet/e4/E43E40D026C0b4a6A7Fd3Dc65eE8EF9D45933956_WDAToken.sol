/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier:MIT

// BEP20 token standard interface
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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

// Dex Factory contract interface
interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// Dex Router02 contract interface
interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract WDAToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    // all private variables and functions are only for contract use
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReward;
    mapping(address => bool) private _isExcludedFromMaxHoldLimit;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1 * 1e12 * 1e18; // 1 trillion total supply
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "WAVE DATING"; // token name
    string private _symbol = "WDA"; // token ticker
    uint8 private _decimals = 18; // token decimals

    IDexRouter public dexRouter; // Dex router address
    address public dexPair; // LP token address
    address payable public marketWallet; // market Wallet address
    address public burnAddress = 0x000000000000000000000000000000000000dEaD; // dead address

    uint256 private maxHoldingAmount = _tTotal.mul(41).div(100); // maximum Holding limit is 4% percent of total supply
    uint256 public minTokenToSwap = 1 * 1e6 * 1e18; // 1M amount will trigger the swap and add liquidity
    uint256 public launchTime; // will be set only once at the time of launch
    uint256 private excludedTSupply; // for contract use
    uint256 private excludedRSupply; // for contract use

    bool public swapAndLiquifyEnabled; // should be true to turn on to liquidate the pool
    bool public reflectionFees = true; // should be false to charge fee
    bool public tradingOpen; //once switched on, can never be switched off.
    bool public isMaxHoldLimitValid = true; // max Holding Limit is valid if it's true

    //  tax fee
    uint256 public redistributionFee = 50; // 5% will be distributed among holder as token divideneds
    uint256 public liquidityFee = 20; // 2% will be added to the liquidity pool
    uint256 public marketWalletFee = 30; // 3% will go to the award pool address

    // for smart contract use
    uint256 private _currentRedistributionFee;
    uint256 private _currentliquidityFee;
    uint256 private _currentmarketWalletFee;

    //Events for blockchain
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );

    // constructor for initializing the contract
    constructor(address payable _marketWallet) {
        _rOwned[owner()] = _rTotal;
        marketWallet = _marketWallet;

        IDexRouter _dexRouter = IDexRouter(
           // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
             0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        // Create a Dex pair for this new token
        dexPair = IDexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );

        // set the rest of the contract variables
        dexRouter = _dexRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude addresses from max tx
        _isExcludedFromMaxHoldLimit[owner()] = true;
        _isExcludedFromMaxHoldLimit[address(this)] = true;
        _isExcludedFromMaxHoldLimit[dexPair] = true;
        _isExcludedFromMaxHoldLimit[burnAddress] = true;
        _isExcludedFromMaxHoldLimit[marketWallet] = true;

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
            _allowances[sender][_msgSender()].sub(
                amount,
                "WDA: transfer amount exceeds allowance"
            )
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
            _allowances[_msgSender()][spender].add(addedValue)
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
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "WDA: decreased allowance below zero"
            )
        );
        return true;
    }

    // public view able functions

    // to check wether the address is excluded from reward or not
    function isExcludedFromReward(address _account) public view returns (bool) {
        return _isExcludedFromReward[_account];
    }

    // to check wether the address is excluded from fee or not
    function isExcludedFromFee(address _account) public view returns (bool) {
        return _isExcludedFromFee[_account];
    }

    // to check wether the address is excluded from max Holding or not
    function isExcludedFromMaxHoldLimit(address _account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromMaxHoldLimit[_account];
    }

    // to check how much tokens get redistributed among holders till now
    function totalHolderDistribution() public view returns (uint256) {
        return _tFeeTotal;
    }

    // For manual distribution to the holders
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcludedFromReward[sender],
            "WDA: Excluded addresses cannot call this function"
        );
        uint256 rAmount = tAmount.mul(_getRate());
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "WDA: Amount must be less than supply");
        if (!deductTransferFee) {
            uint256 rAmount = tAmount.mul(_getRate());
            return rAmount;
        } else {
            uint256 rAmount = tAmount.mul(_getRate());
            uint256 rTransferAmount = rAmount.sub(
                totalFeePerTx(tAmount).mul(_getRate())
            );
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
            "WDA: Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    // setter functions for owner

    // to include any address in reward
    function includeInReward(address _account) external onlyOwner {
        require(
            _isExcludedFromReward[_account],
            "WDA: _Account is already excluded"
        );
        excludedTSupply = excludedTSupply.sub(_tOwned[_account]);
        excludedRSupply = excludedRSupply.sub(_rOwned[_account]);
        _rOwned[_account] = _tOwned[_account].mul(_getRate());
        _tOwned[_account] = 0;
        _isExcludedFromReward[_account] = false;
    }

    //to include any address in reward
    function excludeFromReward(address _account) public onlyOwner {
        require(
            !_isExcludedFromReward[_account],
            "WDA: _Account is already excluded"
        );
        if (_rOwned[_account] > 0) {
            _tOwned[_account] = tokenFromReflection(_rOwned[_account]);
        }
        _isExcludedFromReward[_account] = true;
        excludedTSupply = excludedTSupply.add(_tOwned[_account]);
        excludedRSupply = excludedRSupply.add(_rOwned[_account]);
    }

    //to include or exludde  any address from fee
    function includeOrExcludeFromFee(address _account, bool _value)
        public
        onlyOwner
    {
        _isExcludedFromFee[_account] = _value;
    }

    //to include or exludde  any address from max hold limit
    function includeOrExcludeFromMaxHoldLimit(address _address, bool value)
        public
        onlyOwner
    {
        _isExcludedFromMaxHoldLimit[_address] = value;
    }

    //only owner can change MaxHoldingAmount
    function setMaxHoldingAmount(uint256 _amount) public onlyOwner {
        maxHoldingAmount = _amount;
    }

    //only owner can change MinTokenToSwap
    function setMinTokenToSwap(uint256 _amount) public onlyOwner {
        minTokenToSwap = _amount;
    }

    //only owner can change BuyFeePercentages any time after deployment
    function setFeePercent(
        uint256 _redistributionFee,
        uint256 _liquidityFee,
        uint256 _marketWalletFee
    ) external onlyOwner {
        redistributionFee = _redistributionFee;
        liquidityFee = _liquidityFee;
        marketWalletFee = _marketWalletFee;
    }

    //only owner can change state of swapping, he can turn it in to true or false any time after deployment
    function enableOrDisableSwapAndLiquify(bool _state) public onlyOwner {
        swapAndLiquifyEnabled = _state;
        emit SwapAndLiquifyEnabledUpdated(_state);
    }

    //To enable or disable all fees when set it to true fees will be disabled
    function enableOrDisableFees(bool _state) external onlyOwner {
        reflectionFees = _state;
    }

    //by default maxholding is true to disable set it to false address can hold more than limit
    function enableOrDisableMaxHoldLimit(bool _state) external onlyOwner {
        isMaxHoldLimitValid = _state;
    }

    // owner can change award pool address
    function setmarketWalletAddress(address payable _newAddress)
        external
        onlyOwner
    {
        marketWallet = _newAddress;
    }

    // owner can change router and pair address
    function setRoute(IDexRouter _router, address _pair) external onlyOwner {
        dexRouter = _router;
        dexPair = _pair;
    }

    // no one can buy or sell when trading is off except owner
    // but once switched on every one can buy / sell tokens
    // once switched on can never be switched off
    function startTrading() external onlyOwner {
        require(!tradingOpen, "WDA: Already enabled");
        tradingOpen = true;
        launchTime = block.timestamp;
        swapAndLiquifyEnabled = true;
    }

    //to receive BNB from dexRouter when swapping
    receive() external payable {}

    // internal functions for contract use

    function totalFeePerTx(uint256 tAmount) internal view returns (uint256) {
        uint256 percentage = tAmount
            .mul(_currentRedistributionFee.add(_currentliquidityFee).add(_currentmarketWalletFee))
            .div(1e3);
        return percentage;
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        rSupply = rSupply.sub(excludedRSupply);
        tSupply = tSupply.sub(excludedTSupply);
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function removeAllFee() private {
        _currentRedistributionFee = 0;
        _currentliquidityFee = 0;
        _currentmarketWalletFee = 0;
    }

    function setTaxFee() private {
        _currentRedistributionFee = redistributionFee;
        _currentliquidityFee = liquidityFee;
        _currentmarketWalletFee = marketWalletFee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "WDA: approve from the zero address");
        require(spender != address(0), "WDA: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // base function to transafer tokens
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "WDA: transfer from the zero address");
        require(to != address(0), "WDA: transfer to the zero address");
        require(amount > 0, "WDA: transfer amount must be greater than zero");

        if (!tradingOpen && from != owner()) {
            require(to != dexPair, "WDA: trading is not enabled yet");
        }

        if (!tradingOpen && to != owner()) {
            require(from != dexPair, "WDA: trading is not enabled yet");
        }

        // swap and liquify
        swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any _account belongs to _isExcludedFromFee _account then remove the fee
        if (
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to] ||
            !reflectionFees
        ) {
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
        if (!takeFee || (sender != dexPair && recipient != dexPair)) {
            removeAllFee();
        }
        // buying and selling handler
        else {
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

    function _checkMaxWalletAmount(address to, uint256 amount) private view {
        if (
            !_isExcludedFromMaxHoldLimit[to] // by default false
        ) {
            if (isMaxHoldLimitValid) {
                require(
                    balanceOf(to).add(amount) <= maxHoldingAmount,
                    "WDA: amount exceed max holding limit"
                );
            }
        }
    }

    // take market fees
    function _takeMarketaFee(
        address sender,
        uint256 tAmount,
        uint256 currentRate
    ) internal {
        uint256 tFee = tAmount.mul(_currentmarketWalletFee).div(1e3);
        uint256 rFee = tFee.mul(currentRate);
        if (_isExcludedFromReward[marketWallet])
            _tOwned[marketWallet] = _tOwned[marketWallet].add(tFee);
        else _rOwned[marketWallet] = _rOwned[marketWallet].add(rFee);

        emit Transfer(sender, marketWallet, tFee);
    }

    // take  lp fees
    function _takeLiquidityFee(
        address sender,
        uint256 tAmount,
        uint256 currentRate
    ) internal {
        uint256 tPoolFee = tAmount.mul(_currentliquidityFee).div(1e3);
        uint256 rPoolFee = tPoolFee.mul(currentRate);
        if (_isExcludedFromReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tPoolFee);
        else _rOwned[address(this)] = _rOwned[address(this)].add(rPoolFee);
        emit Transfer(sender, address(this), tPoolFee);
    }

    // if both sender and receiver are not excluded from reward
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(
            totalFeePerTx(tAmount).mul(currentRate)
        );
        _checkMaxWalletAmount(recipient, tTransferAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidityFee(sender, tAmount, currentRate);
        _takeMarketaFee(sender, tAmount, currentRate);
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
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        _checkMaxWalletAmount(recipient, tTransferAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        excludedTSupply = excludedTSupply.add(tAmount);
        _takeLiquidityFee(sender, tAmount, currentRate);
        _takeMarketaFee(sender, tAmount, currentRate);
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
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(
            totalFeePerTx(tAmount).mul(currentRate)
        );
        _checkMaxWalletAmount(recipient, tTransferAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        excludedTSupply = excludedTSupply.sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidityFee(sender, tAmount, currentRate);
        _takeMarketaFee(sender, tAmount, currentRate);
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
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        _checkMaxWalletAmount(recipient, tTransferAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        excludedTSupply = excludedTSupply.sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        excludedTSupply = excludedTSupply.add(tAmount);
        _takeLiquidityFee(sender, tAmount, currentRate);
        _takeMarketaFee(sender, tAmount, currentRate);
        _reflectFee(tAmount);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    // for automatic redistribution among all holders on each tx
    function _reflectFee(uint256 tAmount) private {
        uint256 tFee = tAmount.mul(_currentRedistributionFee).div(1e3);
        uint256 rFee = tFee.mul(_getRate());
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function swapAndLiquify(address from, address to) private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancake pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        bool shouldSell = contractTokenBalance >= minTokenToSwap;

        if (
            shouldSell &&
            from != dexPair &&
            swapAndLiquifyEnabled &&
            !(from == address(this) && to == address(dexPair)) // swap 1 time
        )  {
            // approve contract
            _approve(address(this), address(dexRouter), contractTokenBalance);

            // add liquidity
            // split the contract balance into 2 pieces
            uint256 otherPiece = contractTokenBalance.div(2);
            uint256 tokenAmountToBeSwapped = contractTokenBalance.sub(
                otherPiece
            );

            uint256 initialBalance = address(this).balance;

            // now is to lock into staking pool
            Utils.swapTokensForEth(address(dexRouter), tokenAmountToBeSwapped);

            // how much BNB did we just swap into?

            // capture the contract's current BNB balance.
            // this is so that we can capture exactly the amount of BNB that the
            // swap creates, and not make the liquidity event include any BNB that
            // has been manually sent to the contract
            uint256 bnbToBeAddedToLiquidity = address(this).balance.sub(
                initialBalance
            );

            // add liquidity to dex
            Utils.addLiquidity(
                address(dexRouter),
                owner(),
                otherPiece,
                bnbToBeAddedToLiquidity
            );

            emit SwapAndLiquify(
                tokenAmountToBeSwapped,
                bnbToBeAddedToLiquidity,
                otherPiece
            );
        }
    }
}

// Library for doing a swap on Dex
library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(address routerAddress, uint256 tokenAmount)
        internal
    {
        IDexRouter dexRouter = IDexRouter(routerAddress);

        // generate the Dex pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp + 300
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {
        IDexRouter dexRouter = IDexRouter(routerAddress);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 300
        );
    }
}

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}