pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

import "./IBEP20.sol";
import "./IPancake.sol";
import "./IRealDealCore.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @dev Sample description.
 */
contract RealDeal is IBEP20, Context, Ownable {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _purchasePrices;
    mapping(address => bool) private _isSystemAddress;
    mapping(uint256 => uint256) private _competitionDurations;

    string private constant _SYMBOL = "REALDEAL";
    string private constant _NAME = "RealDeal Protocol";
    uint8 private constant _DECIMALS = 18;
    uint256 private constant _DECIMALFACTOR = 10**uint256(_DECIMALS);
    uint256 private constant _PRICE_GRANULARITY = _DECIMALFACTOR;
    uint256 private constant _MAX_TAX_LIMIT = 10;
    
    uint256 private _totalSupply = 10000000 * _DECIMALFACTOR;
    
    uint256 public burnPercentage = 4;
    uint256 public rewardPoolPercentage = 10;
    uint256 public marketingPoolPercentage = 2;
    uint256 public teamFeePercentage = 4;
    
    uint256 public maxTokensPerAccount = 50000 * _DECIMALFACTOR;
    uint256 public minTokensToPurchase = 50 * _DECIMALFACTOR;
    uint256 public currentCompetitionDuration = 1 weeks;
    uint256 public competitionIndex;

    uint256 public lastCompetitionEndDate;

    address payable private _marketingAddress;
    address payable private _teamAddress;
    address private _presaleAddress;

    IRealDealCore private _core;
    IPancakeRouter02 private _pancakeRouter;
    address private _pancakePairAddress;

    uint256 private _minTokensForFeeConversion = 2000 * _DECIMALFACTOR;
    uint256 private _presaleRate;
    bool private _automaticAirdropInProgress;
    bool private _isFeeConversionInProgress;

    event BurnFeeChanged(uint256 newValue);
    event RewardPoolFeeChanged(uint256 newValue);
    event MarketingPoolFeeChanged(uint256 newValue);
    event TeamFeeChanged(uint256 newValue);
    event MaxTokensPerAccountChanged(uint256 newValue);
    event MinTokensToPurchaseChanged(uint256 newValue);
    event CompetitionDurationChanged(uint256 newValue);
    event CompetitionIndexChanged(uint256 newValue);
    event FeeConversionTriggered(uint256 amount1, uint256 amount2, uint256 amount3);
    event AramDistributionCompleted(bool success);

    modifier lockFeeConversion {
        _isFeeConversionInProgress = true;
        _;
        _isFeeConversionInProgress = false;
    }

    constructor(address coreAddress, address marketingAddress, address teamAddress) {
        lastCompetitionEndDate = block.timestamp;
        
        _marketingAddress = payable(marketingAddress);
        _teamAddress = payable(teamAddress);

        _balances[_msgSender()] = _totalSupply;

        _core = IRealDealCore(coreAddress);

        IPancakeRouter02 pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        _pancakePairAddress = IPancakeFactory(pancakeRouter.factory())
        .createPair(address(this), pancakeRouter.WETH());

        _pancakeRouter = pancakeRouter;

        _isSystemAddress[owner()] = true;
        _isSystemAddress[coreAddress] = true;
        _isSystemAddress[address(this)] = true;
        _isSystemAddress[address(_pancakeRouter)] = true;
        _isSystemAddress[_pancakePairAddress] = true;
        _isSystemAddress[marketingAddress] = true;
        _isSystemAddress[teamAddress] = true;
        
        _approve(address(this), address(_pancakeRouter), 2 ** 256 - 1);
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    /**
     * @dev To receive ETH from PancakeSwapRouter when swaping.
     */
    receive() external payable {}

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
     * @dev Returns the size of the current competition reward pool.
     * Used by RealDeal apps.
     */
    function currentRewardPoolSize() external view returns(uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Returns the rank of the trader in current competition.
     * Used by traders temporarily untill RealDeal app release.
     */
    function getMyRankInCompetition(address myWalletAddress) external view returns(uint256) {
        return _core.getRankOfTrader(myWalletAddress, competitionIndex);
    }
    
    /**
     * @dev Returns the net profit of the trader in current competition.
     * Used by traders temporarily untill RealDeal app release.
     */
    function getMyNetProfitInCompetition(address myWalletAddress) external view returns(int256) {
        return _core.getPerformanceOfTrader(myWalletAddress, competitionIndex);
    }
    
    /**
     * @dev Returns the trader at the specified rank in current competition.
     * Used by traders temporarily untill RealDeal app release.
     */
    function getTraderAtRank(uint256 rank) external view returns(address) {
        return _core.getTraderAtRank(rank, competitionIndex);
    }
    
    /**
     * @dev Returns the net profit of the last trader in TOP list in current competition.
     * Used by traders temporarily untill RealDeal app release.
     */
    function lastWinnerNetProfit() external view returns(int256) {
        return _core.getLastWinnerPerformance(competitionIndex);
    }
    
    /**
     * @dev Returns whether automatic airdrop is currently distributing the rewards.
     * Used by RealDeal apps.
     */
    function isAutomaticAirdropInProgress() external view returns(bool) {
        return _automaticAirdropInProgress;
    }

    /**
     * @dev Returns the entry price of the specified trader.
     * Used by RealDeal apps.
     */
    function getPurchasePrice(address account) external view returns(uint256) {
        return _purchasePrices[account];
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
     * @dev Returns the duration of the specified competition.
     * Used by RealDeal apps.
     */
    function getCompetitionDuration(uint256 targetCompetitionIndex) external view returns(uint256) {
        return _competitionDurations[targetCompetitionIndex];
    }

    /**
     * @dev Returns current price of the token in BUSD value.
     * Used by RealDeal apps.
     */
    function price() public view returns (uint256) {
        (uint256 res0, uint256 res1, ) = IPancakePair(_pancakePairAddress).getReserves();
        
        if (res0 == 0 || res1 == 0) {
            return 0;
        }
        
        address[] memory path1 = new address[](2);
        path1[0] = address(this);
        path1[1] = _pancakeRouter.WETH();
        
        address[] memory path2 = new address[](2);
        path2[0] = _pancakeRouter.WETH();
        path2[1] = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        
        return _pancakeRouter.getAmountsOut(_PRICE_GRANULARITY, path2)[1].mul(_pancakeRouter.getAmountsOut(_PRICE_GRANULARITY, path1)[1]);
    }

    /**
     * @dev Sets the last competition end date.
     * Used only to calibrate and match the competition start date to the week start date.
     */
    function setLastCompetitionEndDate(uint256 date) external onlyOwner {
        lastCompetitionEndDate = date;
    }

    /**
     * @dev Sets new marketing wallet address in case the original is not accessible or compromised.
     */
    function setMarketingWalletAddress(address newAddress) external onlyOwner {
        _marketingAddress = payable(newAddress);
    }

    /**
     * @dev Sets new team wallet address in case the original is not accessible or compromised.
     */
    function setTeamWalletAddress(address newAddress) external onlyOwner {
        _teamAddress = payable(newAddress);
    }
    
    /**
     * @dev Sets the presale address.
     */
    function setPresaleAddress(address newAddress) external onlyOwner {
        _presaleAddress = newAddress;
    }

    /**
     * @dev Sets the core protocol contract that is responsible for TPTS and ARAM.
     * Only used in case the default core contract fails for some reason and needs to be replaced.
     */
    function setProtocolCore(address newCoreAddress) external onlyOwner {
        _core = IRealDealCore(newCoreAddress);
    }

    /**
     * @dev Sets the burn tax percentage.
     * Only used in case the current fee percentages are not sustainable and needs to be tuned.
     */
    function setBurnTaxPercentage(uint256 newBurnPercentage) external onlyOwner {
        burnPercentage = newBurnPercentage;
        emit BurnFeeChanged(newBurnPercentage);
    }

    /**
     * @dev Sets the reward pool tax percentage.
     * Only used in case the current fee percentages are not sustainable and needs to be tuned.
     */
    function setRewardPoolTaxPercentage(uint256 newRewardPoolPercentage) external onlyOwner {
        rewardPoolPercentage = newRewardPoolPercentage;
        emit RewardPoolFeeChanged(newRewardPoolPercentage);
    }

    /**
     * @dev Sets the marketing pool tax percentage.
     * Only used in case the current fee percentages are not sustainable and needs to be tuned.
     */
    function setMarketingPoolTaxPercentage(uint256 newMarketingPoolPercentage) external onlyOwner {
        require(newMarketingPoolPercentage <= _MAX_TAX_LIMIT, "REALDEAL: EXCEEDS_LIMIT");
        marketingPoolPercentage = newMarketingPoolPercentage;
        emit MarketingPoolFeeChanged(newMarketingPoolPercentage);
    }

    /**
     * @dev Sets the team tax percentage.
     * Only used in case the current fee percentages are not sustainable and needs to be tuned.
     */
    function setTeamTaxPercentage(uint256 newTeamFeePercentage) external onlyOwner {
        require(newTeamFeePercentage <= _MAX_TAX_LIMIT, "REALDEAL: EXCEEDS_LIMIT");
        teamFeePercentage = newTeamFeePercentage;
        emit TeamFeeChanged(newTeamFeePercentage);
    }
    
    /**
     * @dev Sets the LP pair address.
     * Only used in case LP needs to be replaced.
     */
    function setPairAddress(address pairAddress) external onlyOwner {
        _pancakePairAddress = pairAddress;
    }
    
    /**
     * @dev Sets the router address.
     * Only used in case the migration to a new router version.
     */
    function setRouterAddress(address rounterAddress) external onlyOwner {
        _pancakeRouter = IPancakeRouter02(rounterAddress);
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
     * @dev Sets min amount of fee tokens need to be collected in the contract before converting to BNB.
     * Only used in case the current value needs to be tuned. 
     * It's purpose is to prevent small unnecessary fee conversions 
     * which will reduce the transaction gas cost.
     */
    function setMinTokensForFeeConversion(uint256 amount) external onlyOwner {
        _minTokensForFeeConversion = amount.mul(_DECIMALFACTOR);
    }
    
    /**
     * @dev Adds or removes the system address. 
     */
    function changeSystemAddress(address account, bool shouldAdd) public onlyOwner {
        _isSystemAddress[account] = shouldAdd;
    }
    
    /**
     * @dev Sets current competition duration. 
     * Used only in case the community requests to prolong the competition duration.
     */
    function setCurrentCompetitionDuration(uint256 duration) external onlyOwner {
        currentCompetitionDuration = duration;
        emit CompetitionDurationChanged(duration);
    }
    
    /**
     * @dev Used only in case Trader Performance Tracking System (TPTS) fails to work or
     * reaches it's technical limitation. Recovers current invalid state of the protocol
     * by starting new competition with valid state.
     * Failed competition's reward pool is assigned to the new competition.
     */
    function tptsEmergencyRecovery(bool cancelAram) external onlyOwner {
        if (cancelAram) {
            _automaticAirdropInProgress = false;
            _core.aramForceCancel();
        }
        
        _competitionDurations[competitionIndex] = currentCompetitionDuration;
        competitionIndex++;
    }
    
    /**
     * @dev Used only in case Automatic Reward Airdrop Mechanism (ARAM) fails to distribute rewards from reward pool
     * and if funds get stuck and locked in the contract.
     * Recovers funds stuck in the contract to the marketing address for manual reward distribution using external tools. 
     */
    function aramEmergencyRecovery(bool onlyCore) external onlyOwner {
        _automaticAirdropInProgress = false;
        
        if (!onlyCore) {
            payable(_marketingAddress).transfer(address(this).balance);
        }
        
        _core.aramEmergencyRecovery(_marketingAddress);
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
        
        // block.timestamp can be manipulated by miners for certain degree but this should not affect much the protocol logic.
        if (
            lastCompetitionEndDate + currentCompetitionDuration <
            block.timestamp
        ) {
            uint256 rewardPoolSize = address(this).balance;
            
            if (rewardPoolSize > 0) {
                _core.setRewardPoolSize(competitionIndex, rewardPoolSize);
                _automaticAirdropInProgress = true;
            }

            lastCompetitionEndDate = lastCompetitionEndDate.add(currentCompetitionDuration);

            _competitionDurations[competitionIndex] = currentCompetitionDuration;
            competitionIndex++;
        }

        if (sender == _pancakePairAddress) {
            _handlePurchaseTransfer(recipient, amount);
        } else if (recipient == _pancakePairAddress) {
            if (sender != address(this)) {
                _tryFeeConversion();
            }
            
            _handleSellTransfer(sender, amount);
        } else {
            _tryFeeConversion();
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
     * - `_pancakePairAddress` must have a balance of at least `amount`.
     */
    function _handlePurchaseTransfer(address buyer, uint256 amount) private {
        if (_automaticAirdropInProgress) {
            if (_core.getRewardCount(competitionIndex - 1) == 0) {
                uint256 rewardPoolSize = _core.getRewardPoolSize(competitionIndex - 1);
                if (!payable(address(_core)).send(rewardPoolSize) || !_core.aramStart(competitionIndex - 1)) {
                    _automaticAirdropInProgress = false;
                    emit AramDistributionCompleted(false);
                }
            } else {
                if (_core.isAramInProgress()) {
                    _core.aramTrigger(competitionIndex - 1);
                }
                else {
                    _automaticAirdropInProgress = false;
                    emit AramDistributionCompleted(true);
                }
            }
        }

        if (!_isSystemAddress[buyer]) {
            require(
                _balances[buyer] == 0,
                "REALDEAL: ALREADY_HAVE_TOKENS"
            );

            require(
                amount >= minTokensToPurchase,
                "REALDEAL: AMOUNT_BELOW_MIN_LIMIT"
            );

            require(
                amount <= maxTokensPerAccount,
                "REALDEAL: AMOUNT_EXCEEDS_MAX_LIMIT"
            );

            uint256 currentPrice = price();
            if (_presaleRate == 0) {
                _presaleRate = currentPrice;
            }
                
            _purchasePrices[buyer] = currentPrice;
        }

        _balances[_pancakePairAddress] = _balances[_pancakePairAddress].sub(
            amount,
            "REALDEAL: NOT_ENOUGH_BALANCE"
        );
        _balances[buyer] = _balances[buyer].add(amount);

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
        uint256 transferAmount;
        uint256 currentPrice = price();
        bool shouldTax = !_isSystemAddress[seller] &&
            _purchasePrices[seller] < currentPrice;

        if (shouldTax) {
            uint256 burnAmount = amount.mul(burnPercentage).div(100);
            uint256 rewardPoolAmount = amount.mul(rewardPoolPercentage).div(100);
            uint256 marketingAmount = amount.mul(marketingPoolPercentage).div(100);
            uint256 teamAmount = amount.mul(teamFeePercentage).div(100);

            uint256 feeAmount = rewardPoolAmount.add(marketingAmount).add(teamAmount);

            transferAmount = amount.sub(burnAmount).sub(feeAmount);
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            _totalSupply = _totalSupply.sub(burnAmount);
        } else {
            transferAmount = amount;
        }

        if (!_isSystemAddress[seller]) {
            int256 netTradeProfit = int256(currentPrice.mul(transferAmount)) -
                int256(_purchasePrices[seller].mul(amount));
            if (netTradeProfit != 0) {
                _core.tptsUpdateTraderPerformance(seller, netTradeProfit, competitionIndex);
            }
        }

        _balances[seller] = _balances[seller].sub(
            amount,
            "REALDEAL: NOT_ENOUGH_BALANCE"
        );
        _balances[_pancakePairAddress] = _balances[_pancakePairAddress].add(
            transferAmount
        );

        if (_balances[seller] == 0 && !_isSystemAddress[seller]) {
            delete _purchasePrices[seller];
        }

        emit Transfer(seller, _pancakePairAddress, transferAmount);
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
        if (!_isSystemAddress[sender] && !_isSystemAddress[recipient]) {
            require(
                _balances[recipient] == 0,
                "REALDEAL: ALREADY_HAVE_TOKENS"
            );

            require(
                amount <= maxTokensPerAccount,
                "REALDEAL: AMOUNT_EXCEEDS_MAX_LIMIT"
            );

            _purchasePrices[recipient] = _purchasePrices[sender];
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "REALDEAL: NOT_ENOUGH_BALANCE"
        );
        _balances[recipient] = _balances[recipient].add(amount);

        if (_isSystemAddress[sender] && !_isSystemAddress[recipient]) {
            if (sender == _presaleAddress && _presaleRate > 0) {
                _purchasePrices[recipient] = _presaleRate;
            }
            else {
                uint256 currentPrice = price();
                if (_presaleRate == 0) {
                    _presaleRate = currentPrice;
                }
                
                _purchasePrices[recipient] = currentPrice;
            }
        }

        if (!_isSystemAddress[sender] && _balances[sender] == 0) {
            delete _purchasePrices[sender];
        }

        emit Transfer(sender, recipient, amount);
    }
    
    /**
     * @dev Tries to start fee conversion.
     * Converts REALDEAL tokens collected in contract address as a fee to BNB, fills reward pool 
     * and sends marketing and team fees to appropriate addresses.
     */
    function _tryFeeConversion() private {
        if (!_isFeeConversionInProgress &&
            _balances[address(this)] >= _minTokensForFeeConversion) {
                
            uint256 initialBalance = address(this).balance;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _pancakeRouter.WETH();

            _pancakeRouter.swapExactTokensForETH(
                _balances[address(this)],
                0, 
                path,
                address(this),
                block.timestamp
            );
        
            uint256 transferredBalance = address(this).balance.sub(initialBalance);
            uint256 totalFeePercentage = rewardPoolPercentage.add(marketingPoolPercentage).add(teamFeePercentage);
            uint256 marketingSlice;
            uint256 teamSlice;

            if (transferredBalance > 0) {
                if (marketingPoolPercentage > 0) {
                    marketingSlice = transferredBalance.mul(marketingPoolPercentage).div(totalFeePercentage);
                    _marketingAddress.transfer(marketingSlice);
                }
                
                if (teamFeePercentage > 0) {
                    teamSlice = transferredBalance.mul(teamFeePercentage).div(totalFeePercentage);
                    _teamAddress.transfer(teamSlice);
                }
            }
        
            emit FeeConversionTriggered(transferredBalance.sub(marketingSlice).sub(teamSlice), marketingSlice, teamSlice);
        }
    }
}