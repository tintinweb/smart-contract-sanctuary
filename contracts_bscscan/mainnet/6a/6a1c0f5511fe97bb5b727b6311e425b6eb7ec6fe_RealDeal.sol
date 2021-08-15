pragma solidity 0.8.6;

// SPDX-License-Identifier: MIT

import "./IBEP20.sol";
import "./IPancake.sol";
import "./IRealDealCore.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
─████████████████───██████████████─██████████████─██████─────────████████████───██████████████─██████████████─██████─────────
─██░░░░░░░░░░░░██───██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██─────────██░░░░░░░░████─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██─────────
─██░░████████░░██───██░░██████████─██░░██████░░██─██░░██─────────██░░████░░░░██─██░░██████████─██░░██████░░██─██░░██─────────
─██░░██────██░░██───██░░██─────────██░░██──██░░██─██░░██─────────██░░██──██░░██─██░░██─────────██░░██──██░░██─██░░██─────────
─██░░████████░░██───██░░██████████─██░░██████░░██─██░░██─────────██░░██──██░░██─██░░██████████─██░░██████░░██─██░░██─────────
─██░░░░░░░░░░░░██───██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██─────────██░░██──██░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██─────────
─██░░██████░░████───██░░██████████─██░░██████░░██─██░░██─────────██░░██──██░░██─██░░██████████─██░░██████░░██─██░░██─────────
─██░░██──██░░██─────██░░██─────────██░░██──██░░██─██░░██─────────██░░██──██░░██─██░░██─────────██░░██──██░░██─██░░██─────────
─██░░██──██░░██████─██░░██████████─██░░██──██░░██─██░░██████████─██░░████░░░░██─██░░██████████─██░░██──██░░██─██░░██████████─
─██░░██──██░░░░░░██─██░░░░░░░░░░██─██░░██──██░░██─██░░░░░░░░░░██─██░░░░░░░░████─██░░░░░░░░░░██─██░░██──██░░██─██░░░░░░░░░░██─
─██████──██████████─██████████████─██████──██████─██████████████─████████████───██████████████─██████──██████─██████████████─
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
─██████████████─████████████████───██████████████─██████████████─██████████████─██████████████─██████████████─██████─────────
─██░░░░░░░░░░██─██░░░░░░░░░░░░██───██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██─────────
─██░░██████░░██─██░░████████░░██───██░░██████░░██─██████░░██████─██░░██████░░██─██░░██████████─██░░██████░░██─██░░██─────────
─██░░██──██░░██─██░░██────██░░██───██░░██──██░░██─────██░░██─────██░░██──██░░██─██░░██─────────██░░██──██░░██─██░░██─────────
─██░░██████░░██─██░░████████░░██───██░░██──██░░██─────██░░██─────██░░██──██░░██─██░░██─────────██░░██──██░░██─██░░██─────────
─██░░░░░░░░░░██─██░░░░░░░░░░░░██───██░░██──██░░██─────██░░██─────██░░██──██░░██─██░░██─────────██░░██──██░░██─██░░██─────────
─██░░██████████─██░░██████░░████───██░░██──██░░██─────██░░██─────██░░██──██░░██─██░░██─────────██░░██──██░░██─██░░██─────────
─██░░██─────────██░░██──██░░██─────██░░██──██░░██─────██░░██─────██░░██──██░░██─██░░██─────────██░░██──██░░██─██░░██─────────
─██░░██─────────██░░██──██░░██████─██░░██████░░██─────██░░██─────██░░██████░░██─██░░██████████─██░░██████░░██─██░░██████████─
─██░░██─────────██░░██──██░░░░░░██─██░░░░░░░░░░██─────██░░██─────██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─
─██████─────────██████──██████████─██████████████─────██████─────██████████████─██████████████─██████████████─██████████████─
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
.
. 
. World's first decentralized trading battleground. 
. Trading competitions controlled by smart contracts.
. 
. Website: www.realdealprotocol.com
. Author: www.linkedin.com/in/muhamed-aziz
 */
contract RealDeal is IBEP20, Context, Ownable {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _isSystemAddress;

    string private constant _SYMBOL = "REALDEAL";
    string private constant _NAME = "RealDeal Protocol";
    uint8 private constant _DECIMALS = 18;
    uint256 private constant _DECIMALFACTOR = 10**uint256(_DECIMALS);
    uint256 private constant _FEE_GRANULARITY = 100;
    uint256 private constant _MAX_FEE_LIMIT = 3 * _FEE_GRANULARITY;
    
    uint256 private _totalSupply = 1000000 * _DECIMALFACTOR;
    uint256 private _minTokensForFeeConversion = 200 * _DECIMALFACTOR;
    uint256 private _presaleTokenPool = 369360000000000000000000;
    uint256 private _presaleBNBPool = 369360000000000000000;
    
    uint256 public rewardFeePercentage = 7 * _FEE_GRANULARITY;
    uint256 public burnPercentage = 1 * _FEE_GRANULARITY;
    uint256 public marketingFeePercentage = 1 * _FEE_GRANULARITY;
    uint256 public developmentFeePercentage = 1 * _FEE_GRANULARITY;
    
    address payable private _marketingAddress;
    address payable private _developmentAddress;
    address private _pancakePairAddress;
    address private _presaleAddress;
    
    bool public excludeFee;
    
    uint256 public maxTokensPerAccount = 8000 * _DECIMALFACTOR;
    uint256 public minTokensToPurchase = 80 * _DECIMALFACTOR;

    IRealDealCore private _core;
    IPancakeRouter02 private _pancakeRouter;
    IBEP20 private _busd;

    bool private _isFeeConversionInProgress;

    event BurnPercentageChanged(uint256 newValue);
    event RewardPoolFeeChanged(uint256 newValue);
    event MarketingPoolFeeChanged(uint256 newValue);
    event DevelopmentFeeChanged(uint256 newValue);
    event MaxTokensPerAccountChanged(uint256 newValue);
    event MinTokensToPurchaseChanged(uint256 newValue);
    event MinTokensForFeeConversionChanged(uint256 newValue);
    event FeeConversionTriggered(uint256 amount1, uint256 amount2, uint256 amount3);

    modifier lockFeeConversion {
        _isFeeConversionInProgress = true;
        _;
        _isFeeConversionInProgress = false;
    }

    constructor(address coreAddress, address marketingWalletAddress, address developmentWalletAddress) {
        _marketingAddress = payable(marketingWalletAddress);
        _developmentAddress = payable(developmentWalletAddress);

        _balances[_msgSender()] = _totalSupply;

        _core = IRealDealCore(coreAddress);
        _busd = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());

        _isSystemAddress[owner()] = true;
        _isSystemAddress[coreAddress] = true;
        _isSystemAddress[address(this)] = true;
        _isSystemAddress[address(_pancakeRouter)] = true;
        _isSystemAddress[_pancakePairAddress] = true;
        _isSystemAddress[marketingWalletAddress] = true;
        _isSystemAddress[developmentWalletAddress] = true;
        
        _approve(address(this), address(_pancakeRouter), 2 ** 256 - 1);
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view virtual override returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view virtual override returns (uint8) {
        return _DECIMALS;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view virtual override returns (string memory) {
        return _SYMBOL;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external view virtual override returns (string memory) {
        return _NAME;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "REALDEAL: AMOUNT_EXCEEDS_ALLOWANCE"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "REALDEAL: ALLOWANCE_BELOW_ZERO"
            )
        );
        return true;
    }
    
    /**
     * @dev Returns if the specified address is a system address.
     * System addresses do not pay tax.
     * Niether their performance is tracked, nor they receive the rewards. 
     * Only addresses that are necessary to maintain the protocol are in this list.
     */
    function isSystemAddress(address account) external view returns(bool) {
        return _isSystemAddress[account];
    }

    /**
     * @dev Returns the protocol core address
     */
    function getProtocolCoreAddress() external view returns(address) {
        return address(_core);
    }

    /**
     * @dev Returns the current price of the token in BNB value when selling.
     * Used by RealDeal apps.
     */
    function getTokenSellPriceInBNB(uint256 amount) public view returns (uint256) {
        (uint256 res0, uint256 res1, ) = IPancakePair(_pancakePairAddress).getReserves();
        
        if (res0 == 0 || res1 == 0) {
            return 0;
        }
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();
        
        return _pancakeRouter.getAmountsOut(amount, path)[1];
    }
    
    /**
     * @dev Returns the current price of the token in BNB value when buying.
     * Used by RealDeal apps.
     */
    function getTokenPurchasePriceInBNB(uint256 amount) public view returns (uint256) {
        (uint256 res0, uint256 res1, ) = IPancakePair(_pancakePairAddress).getReserves();
        
        if (res0 == 0 || res1 == 0) {
            return 0;
        }
        
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = address(this);
        
        return _pancakeRouter.getAmountsIn(amount, path)[0];
    }

    /**
     * @dev Returns the presale price of the token in BNB value.
     */
    function getTokenPresalePriceInBNB(uint256 amount) public view returns (uint256) {
        return amount.mul(_presaleBNBPool).div(_presaleTokenPool);
    }
    
    /**
     * @dev Returns the trader at the specified rank of the specified competition.
     */
    function getCurrentRewardPoolBUSD() external view returns(uint256) {
        return _core.currentRewardPoolSize();
    }
    
    /**
     * @dev Returns the net profit of the trader at the specified competition.
     */
    function getNetProfitOfTrader(address trader) external view returns(address) {
        return _core.getPerformanceOfTrader(trader, _core.getCompetitionIndex());
    }
    
    /**
     * @dev Returns the trader at the specified rank of the specified competition.
     */
    function getTraderAtRank(uint256 rank) external view returns(address) {
        return _core.getTraderAtRank(rank, _core.getCompetitionIndex());
    }

    /**
     * @dev Returns the rank of the specified trader at the specified competition.
     */
    function getRankOfTrader(address trader) external view returns(uint256) {
        return _core.getRankOfTrader(trader, _core.getCompetitionIndex());
    }

    /**
    * @dev Returns the last rank.
    */
    function getNumberOfProfitingTraders() external view returns(uint256) {
        return _core.getNumberOfProfitingTraders(_core.getCompetitionIndex());
    }
    
    /**
     * @dev Excludes fee from net profit calculation.
     */
    function excludeFeeFromNetProfit(bool exclude) external onlyOwner {
        excludeFee = exclude;
    }
    
    /**
     * @dev Sets the contract address for reward pool currency.
     * Used only if BUSD contract address changes.
     */
    function setRewardCurrencyContractAddress(address newAddress) external onlyOwner {
        _busd = IBEP20(newAddress);
    }

    /**
     * @dev Sets new marketing wallet address in case the original is not accessible or compromised.
     */
    function setMarketingAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "REALDEAL: NULL_ADDRESS");
        _marketingAddress = payable(newAddress);
    }

    /**
     * @dev Sets new development wallet address in case the original is not accessible or compromised.
     */
    function setDevelopmentAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "REALDEAL: NULL_ADDRESS");
        _developmentAddress = payable(newAddress);
    }
    
    /**
     * @dev Sets the presale address.
     */
    function setPresaleAddress(address newAddress) external onlyOwner {
        _presaleAddress = newAddress;
    }

    /**
     * @dev Sets the presale token pool.
     */
    function setPresaleTokenPool(uint256 amount) external onlyOwner {
        require(amount > 0, "REALDEAL: INVALID_INPUT");
        _presaleTokenPool = amount;
    }

    /**
     * @dev Sets the presale BNB pool.
     */
    function setPresaleBNBPool(uint256 amount) external onlyOwner {
        require(amount > 0, "REALDEAL: INVALID_INPUT");
        _presaleBNBPool = amount;
    }

    /**
     * @dev Sets the core protocol contract that is responsible for TPTS and ARAM.
     * Only used in case the default core contract fails for some reason and needs to be replaced.
     */
    function setProtocolCore(address newAddress) external onlyOwner {
        require(newAddress != address(0), "REALDEAL: NULL_ADDRESS");
        _core = IRealDealCore(newAddress);
    }

    /**
     * @dev Sets the burn percentage.
     * Only used in case the current burn percentage is not sustainable and needs to be tuned.
     */
    function setBurnPercentage(uint256 newBurn) external onlyOwner {
        burnPercentage = newBurn;
        emit BurnPercentageChanged(newBurn);
    }

    /**
     * @dev Sets the reward pool fee percentage.
     * Only used in case the current fee percentages are not sustainable and needs to be tuned.
     */
    function setRewardPoolFeePercentage(uint256 newFee) external onlyOwner {
        rewardFeePercentage = newFee;
        emit RewardPoolFeeChanged(newFee);
    }

    /**
     * @dev Sets the marketing pool fee percentage.
     * Only used in case the current fee percentages are not sustainable and needs to be tuned.
     */
    function setMarketingPoolFeePercentage(uint256 newFee) external onlyOwner {
        require(newFee <= _MAX_FEE_LIMIT, "REALDEAL: EXCEEDS_LIMIT");
        marketingFeePercentage = newFee;
        emit MarketingPoolFeeChanged(newFee);
    }

    /**
     * @dev Sets the development fee percentage.
     * Only used in case the current fee percentages are not sustainable and needs to be tuned.
     */
    function setDevelopmentFeePercentage(uint256 newFee) external onlyOwner {
        require(newFee <= _MAX_FEE_LIMIT, "REALDEAL: EXCEEDS_LIMIT");
        developmentFeePercentage = newFee;
        emit DevelopmentFeeChanged(newFee);
    }
    
    /**
     * @dev Sets the LP pair address.
     * Only used in case LP needs to be replaced.
     */
    function setPairAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "REALDEAL: NULL_ADDRESS");
        _pancakePairAddress = newAddress;
    }
    
    /**
     * @dev Sets the router address.
     * Only used in case the migration to a new router version.
     */
    function setRouterAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "REALDEAL: NULL_ADDRESS");
        _pancakeRouter = IPancakeRouter02(newAddress);
    }

    /**
     * @dev Sets the max amount of tokens one account can have. 
     * This is to prevent price manipulation of big whales.
     */
    function setMaxTokensPerAccount(uint256 amount) external onlyOwner {
        maxTokensPerAccount = amount.mul(_DECIMALFACTOR);
        emit MaxTokensPerAccountChanged(amount);
    }

    /**
     * @dev Sets the min amount of tokens allowed to purchase. 
     * This is to prevent bots unnecessarily overloading the TPTS.
     */
    function setMinTokensToPurchase(uint256 amount) external onlyOwner {
        minTokensToPurchase = amount.mul(_DECIMALFACTOR);
        emit MinTokensToPurchaseChanged(amount);
    }
    
    /**
     * @dev Sets the min amount of tokens allowed to purchase. 
     * This is to prevent bots unnecessarily overloading the TPTS.
     */
    function setMinTokensForFeeConversion(uint256 amount) external onlyOwner {
        _minTokensForFeeConversion = amount.mul(_DECIMALFACTOR);
        emit MinTokensForFeeConversionChanged(amount);
    }
    
    /**
     * @dev Adds or removes the system address. 
     */
    function changeSystemAddress(address account, bool shouldAdd) public onlyOwner {
        require(account != address(0), "REALDEAL: NULL_ADDRESS");
        _isSystemAddress[account] = shouldAdd;
    }
    
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "REALDEAL: NULL_ADDRESS");
        require(spender != address(0), "REALDEAL: NULL_ADDRESS");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and is used to
     * implement token fees and trade tracking mechanism.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(
            sender != address(0),
            "REALDEAL: NULL_ADDRESS"
        );
        require(
            recipient != address(0),
            "REALDEAL: NULL_ADDRESS"
        );
        require(amount > 0, "REALDEAL: AMOUNT_ZERO");
        
        _core.competitionUpdateCallback();

        if (sender == _pancakePairAddress) {
            _handlePurchaseTransfer(recipient, amount);
        } else if (recipient == _pancakePairAddress) {
            if (sender != address(this) && 
                !_isFeeConversionInProgress &&
                _balances[address(this)] >= _minTokensForFeeConversion) {
                _tryFeeConversion();
            }
            
            _handleSellTransfer(sender, amount);
        } else {
            if (!_isFeeConversionInProgress &&
                _balances[address(this)] >= _minTokensForFeeConversion) {
                _tryFeeConversion();
            }
            _handleTokenTransfer(sender, recipient, amount);
        }
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is private function is equivalent to {transfer} but only for token purchases, and is used to
     * initiate trade tracking mechanism and trigger ARAM.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `buyer` cannot be the zero address.
     * - `pancakePairAddress` must have a balance of at least `amount`.
     */
    function _handlePurchaseTransfer(address buyer, uint256 amount) private {
        uint256 amountAfterTax;

        if (_isSystemAddress[buyer]) {
            amountAfterTax = amount;
        } else {
            require(
                amount >= minTokensToPurchase,
                "REALDEAL: AMOUNT_BELOW_MIN_LIMIT"
            );

            _core.competitionEndCallback();
        
            (uint256 burnAmount, uint256 feeAmount) = _applyTax(amount);
            amountAfterTax = amount.sub(feeAmount).sub(burnAmount);

            uint256 valueIn = getTokenPurchasePriceInBNB(excludeFee ? amountAfterTax : amount);

            require(
                _balances[buyer].add(amountAfterTax) <= maxTokensPerAccount,
                "REALDEAL: AMOUNT_EXCEEDS_MAX_LIMIT"
            );
            
            _core.tradeEntryCallback(buyer, valueIn, amount, amountAfterTax);
            
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            _totalSupply = _totalSupply.sub(burnAmount);
        }

        _balances[_pancakePairAddress] = _balances[_pancakePairAddress].sub(
            amount,
            "REALDEAL: NOT_ENOUGH_BALANCE"
        );
        _balances[buyer] = _balances[buyer].add(amountAfterTax);

        emit Transfer(_pancakePairAddress, buyer, amount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is private function is equivalent to {transfer} but only for token sells, and is used to
     * implement token fees and trigger TPTS.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `seller` cannot be the zero address.
     * - `seller` must have a balance of at least `amount`.
     */
    function _handleSellTransfer(address seller, uint256 amount) private {
        uint256 amountAfterTax;

        if (_isSystemAddress[seller]) {
            amountAfterTax = amount;
        } else {
            (uint256 burnAmount, uint256 feeAmount) = _applyTax(amount);
            amountAfterTax = amount.sub(feeAmount).sub(burnAmount);
            
            _core.tradeExitCallback(seller, getTokenSellPriceInBNB(excludeFee ? amount : amountAfterTax), amount, amountAfterTax, _balances[seller]);
            
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            _totalSupply = _totalSupply.sub(burnAmount);
        }

        _balances[seller] = _balances[seller].sub(amount, "REALDEAL: NOT_ENOUGH_BALANCE");
        _balances[_pancakePairAddress] = _balances[_pancakePairAddress].add(amountAfterTax);

        emit Transfer(seller, _pancakePairAddress, amountAfterTax);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is private function is equivalent to {transfer} and only for standart token transfers. For example, between wallets.
     * Trade data also transfered with the tokens.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _handleTokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (!_isSystemAddress[recipient]) {
            uint256 valueIn = getTokenPurchasePriceInBNB(amount);
            uint256 valueOut = getTokenSellPriceInBNB(amount);
                
            if (_isSystemAddress[sender]) {
                if (sender == _presaleAddress) {
                    _core.tradeTransferCallback(recipient, getTokenPresalePriceInBNB(amount), valueOut, amount);
                }
                else {
                    _core.tradeTransferCallback(recipient, valueIn, valueOut, amount);
                }
            } 
            else {
                require(
                    _balances[recipient].add(amount) <= maxTokensPerAccount,
                    "REALDEAL: AMOUNT_EXCEEDS_MAX_LIMIT"
                );

                _core.tradeTransferCallback(sender, recipient, valueIn, valueOut, amount, _balances[sender]);
            }   
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "REALDEAL: NOT_ENOUGH_BALANCE"
        );
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }
    
    /**
     * @dev Tries to start fee conversion.
     * Converts REALDEAL tokens collected in contract address as a fee to BUSD, fills reward pool 
     * and sends marketing and team fees to appropriate addresses.
     */
    function _tryFeeConversion() private lockFeeConversion {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();
        path[2] = address(_busd);

        _pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _balances[address(this)],
            0, 
            path,
            address(this),
            block.timestamp
        );
        
        uint256 transferredBalance = _busd.balanceOf(address(this));
        uint256 totalFeePercentage = rewardFeePercentage.add(marketingFeePercentage).add(developmentFeePercentage);
        uint256 marketingSlice;
        uint256 developmentSlice;
        uint256 rewardSlice;

        if (transferredBalance > 0) {
            if (marketingFeePercentage > 0) {
                marketingSlice = transferredBalance.mul(marketingFeePercentage).div(totalFeePercentage);
                require(_busd.transfer(_marketingAddress, marketingSlice), "REALDEAL: BUSD_TX_FAILED");
            }
                
            if (developmentFeePercentage > 0) {
                developmentSlice = transferredBalance.mul(developmentFeePercentage).div(totalFeePercentage);
                require(_busd.transfer(_developmentAddress, developmentSlice), "REALDEAL: BUSD_TX_FAILED");
            }
            
            rewardSlice = transferredBalance.sub(marketingSlice).sub(developmentSlice);
            require(_busd.transfer(address(_core), rewardSlice), "REALDEAL: BUSD_TX_FAILED");
        }
        
        emit FeeConversionTriggered(rewardSlice, marketingSlice, developmentSlice);
    }
    
    /**
     * @dev Applies fees for `amount`.
     *
     * This is private function which applies fee for the given amount and returns the amount of fees.
     */
    function _applyTax(uint256 amount) private view returns (uint256 burnAmount, uint256 feeAmount)
    {
        uint256 rewardFeeAmount = amount.mul(rewardFeePercentage).div(100 * _FEE_GRANULARITY);
        uint256 marketingFeeAmount = amount.mul(marketingFeePercentage).div(100 * _FEE_GRANULARITY);
        uint256 developmentFeeAmount = amount.mul(developmentFeePercentage).div(100 * _FEE_GRANULARITY);

        burnAmount = amount.mul(burnPercentage).div(100 * _FEE_GRANULARITY);
        feeAmount = rewardFeeAmount.add(marketingFeeAmount).add(developmentFeeAmount);
    }
}