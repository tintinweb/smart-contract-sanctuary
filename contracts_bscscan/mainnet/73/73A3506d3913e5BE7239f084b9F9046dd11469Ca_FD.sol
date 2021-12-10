// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Libraries.sol";

contract FD is Ownable, IBEP20 {
    uint256 private constant _initialSupply = 10000000000 * 10 ** 9; // 10B
    
    /* Trading */
    address private _oneTimeExcluded;
    uint256 private _antiBotTimer;
    bool private _canTrade;

    /* SwapAndLiquify */
    bool private _isWithdrawing;
    uint16 public swapThreshold;
    bool public remove20PercentEnabled;
    bool private _isSwappingContractModifier;
    bool public swapAndLiquifyDisabled;
    bool private _addingLiquidity;
    bool private _removingLiquidity;
    uint256 private _liquidityUnlockTime;
    
    /* Reward Distribution */ 
    uint256 private _profitPerToken;
    uint256 private _totalTokensHeld;
    
    /* Contract BNB Trackers */
    uint256 private _totalLiquidityBNB;
    uint256 private _totalMarketingBNB;
    uint256 private _totalRewardsBNB;
    uint256 private _totalRewardBNBPaid;
    
    /* Sell Delay & Token Vesting (Locking) */
    uint256 private _maxSellDelay = 1 hours;
    uint256 private _sellDelay = 0;
    
    // Primary & Secondary Taxes.  
    uint8 private constant _maxTax = 50;
    uint8 private _buyTax = 15;
    uint8 private _sellTax = 15;
    
    // Applied on sell tx. 
    uint8 private _burnTax = 1;
    uint8 private _marketingTax = 20;
    uint8 private _liquidityTax = 15;
    uint8 private _rewardsTax = 65;
    uint8 private constant _totalTax = 100;
    
    /* Balance & Sell Limits */
    uint256 private _maxWalletSize = _initialSupply; 
    uint256 private _maxSellSize = _initialSupply; 
    
    /* Burn Mechanism */
    uint256 private _totalTokensBurned;
    uint256 private _tokensToBurn;
    
    /* PancakeSwap */
    IPancakeRouter02 private _pancakeRouter;
    address public _pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public _pancakePairAddress;
    
    /* Team Wallet */
    address public teamWallet = 0x1dcE9145721Da58CE01FE14FABcAB2dcE2611375;
    address public burnWallet = 0x000000000000000000000000000000000000dEaD;
    
    /* Promotional Token */
    address public promoToken;
    address public farmToken;
    uint256 private _minHoldForBonus;
    bool private promoTokenEnabled;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _automatedMarketMakers;
    mapping(address => Holder) private _holders;
    
    /* Private Sale */
    mapping(address => bool) private _vestors;
    mapping(address => uint256) private _unvested;
    uint256 private _privateSaleVestTime;
    uint256 private _privateSaleVestRate = 1000000 * 10 ** 9;

    struct Holder {
        // Used for sell delay & token vesting (locking)
        uint256 nextSell;
        uint256 rewardsPaid;
        uint256 rewardsToBePaid;
        bool excludeFromFees;
        bool excludeFromRewards;
    }
    
    event OwnerCreateLP(uint8 teamPercent, uint8 contractPercent);
    event TeamBurnContractTokens(uint256 toBurn);
    event TeamRemoveLiquidity(uint8 percent, bool rewardBoost);
    event TeamChangeTaxes(uint8 buyTax, uint8 sellTax, uint8 burnTax, uint8 marketingTax, uint8 rewardsTax, uint8 liquidityTax);
    event TeamChangeLimits(uint256 maxWalletSize, uint256 maxSellSize);
    event TeamSwapContractTokens(uint16 swapThreshold, bool ignoreLimits);
    event TeamBoostContract(bool rewardBoost, uint256 amountWei);
    event TeamChangeSellDelay(uint256 sellDelay);
    event TeamExtendLPLock(uint256 timeSeconds);
    event TeamUpdateAMM(address indexed AMMAdress, bool enabled);
    event TeamUpdateSwapThreshold(uint16 swapThreshold);
    event TeamSwitchSwapAndLiquify(bool disabled);
    event TeamTriggerBuyBack(uint256 amountWei);
    event TeamSetFarmToken(address indexed farmToken);
    event TeamSetPromoToken(address indexed promoToken, uint256 _minHoldForBonus, bool promoTokenEnabled);
    event ClaimBNBTo(address indexed from, address indexed recipient, uint256 amountWei);
    event Compound(address indexed recipient, uint256 amountTokens);
    event ClaimPromoToken(address indexed recipient, uint256 amountTokens);
    event TeamSwitch20PercentEnabled(bool enabled);
    event LockExternalTeamTokens(address indexed _teamWallet);
    event TeamChangeWallet(address indexed newWallet);
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }
    modifier onlyTeam {
        require(msg.sender == teamWallet);
        _;
    }
    constructor() {
        // Mint initial supply to contract
        _updateBalance(address(this), _initialSupply);
        emit Transfer(address(0), address(this), _initialSupply);
        // Init & approve PCSR
        _pancakeRouter = IPancakeRouter02(_pancakeRouterAddress);
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        _automatedMarketMakers[_pancakePairAddress] = true;
        _approve(address(this), address(_pancakeRouter), type(uint256).max);
        // Exclude from fees & rewards
        _holders[msg.sender].excludeFromFees = true;
        _holders[address(this)].excludeFromFees = true;
        _holders[address(this)].excludeFromRewards = true;
        _holders[_pancakePairAddress].excludeFromRewards = true;
        _privateSaleVestTime = block.timestamp + 9 weeks;
    }
///////////////////////////////////////////
// Transfer Functions
///////////////////////////////////////////
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0) && recipient != address(0), "Cannot be zero address.");
        bool isBuy = _automatedMarketMakers[sender];
        bool isSell = _automatedMarketMakers[recipient];
        bool isExcluded = _holders[sender].excludeFromFees || _holders[recipient].excludeFromFees || 
            _addingLiquidity || _removingLiquidity||_oneTimeExcluded==sender||_oneTimeExcluded==recipient;
        if (isExcluded) {
            _transferExcluded(sender, recipient, amount);
            _oneTimeExcluded = address(0);
        } else {
            // Trading can only be enabled once
            require(_canTrade, "Trading isn't enabled.");
            if (isBuy) _buyTokens(recipient, amount);
            else if (isSell) _sellTokens(sender, amount);
            else if (sender == recipient) _claimBNBTo(sender, recipient);
            else {
                // Team Wallet cannot transfer tokens until lock has expired
                if (sender == teamWallet) require(block.timestamp >= _holders[teamWallet].nextSell);
                require(_balances[recipient] + amount <= _maxWalletSize);
                _transferExcluded(sender, recipient, amount);
                // Recipient will incurr sell delay to prevent pump & dump
                _holders[recipient].nextSell = block.timestamp + _sellDelay;
            }
        }
    }
    function _buyTokens(address recipient, uint256 amount) private {
        if (block.timestamp < _antiBotTimer) {
            // 5 % of tokens will be stored in burn vault (contract)
            _tokensToBurn += amount * 5 * 100 / 1000;
            // 100 % of tokens sent to contract, 95 % for LP
            _transferExcluded(_pancakePairAddress, address(this), amount);
        } else {
            // Team wallet cannot buy tokens until lock is over.
            if (recipient == teamWallet) require(block.timestamp >= _holders[teamWallet].nextSell);
            // Balance + amount cannot exceed 1 % of circulating supply (_maxWalletSize)
            require(_balances[recipient] + amount <= _maxWalletSize);
            // Amount of tokens to be sent to contract
            uint256 taxedTokens = amount * _buyTax * 100 / 10000;
            _transferIncluded(_pancakePairAddress, recipient, amount, taxedTokens);
            _totalTokensHeld += amount - taxedTokens;
            // Reset sell delay
            _holders[recipient].nextSell = block.timestamp + _sellDelay;
        }
    }
    function _sellTokens(address sender, uint256 amount) private {
        // Cannot sell before nextSell
        require(block.timestamp >= _holders[sender].nextSell);
        require(amount <= _maxSellSize && amount <= _balances[sender]);
        // Private wallets
        if (_vestors[sender])
        {
            uint256 vestDate = _privateSaleVestTime;
            require(block.timestamp > vestDate);
            uint256 timeVested = block.timestamp - vestDate;
            uint256 oneWeek = 1 weeks;
            uint256 vested = (timeVested / oneWeek) * _privateSaleVestRate;
            uint256 unvested = 0;
            if (vested > _unvested[sender])
            {
                _vestors[sender] = false;
            }
            else
            {
                unvested = _unvested[sender] - vested;
            }
            uint256 availableBalance = _balances[sender] - unvested;
            require(amount >= availableBalance);
        }
        // Amount of tokens to be sent to contract
        uint256 taxedTokens = amount * _sellTax * 100 / 10000;
        // Tokens to burn are stored in contract for scheduled burn
        _tokensToBurn += taxedTokens * _burnTax * 100 / 10000;
        _transferIncluded(sender, _pancakePairAddress, amount, taxedTokens);
        _totalTokensHeld -= amount;
        // Reset sell delay
        _holders[sender].nextSell = block.timestamp + _sellDelay;
    }
    function _transferIncluded(address sender, address recipient, uint256 amount, uint256 taxedTokens) private {
        uint256 newAmount = amount - taxedTokens;
        _updateBalance(sender, _balances[sender] - amount);
        // Taxed tokens are sent to contract, including '_toBeBurned'
        _updateBalance(address(this), _balances[address(this)] + taxedTokens);
        _updateBalance(recipient, _balances[recipient] + newAmount);
        emit Transfer(sender, recipient, newAmount);
    }
    function _transferExcluded(address sender, address recipient, uint256 amount) private {
        _updateBalance(sender, _balances[sender] - amount);
        _updateBalance(recipient, _balances[recipient] + amount);
        emit Transfer(sender, recipient, amount);
    }
    function _updateBalance(address account, uint256 newBalance) private {
        // Grab any outstanding rewards before balance change
        uint256 reward = _newRewardsOf(account);
        _balances[account] = newBalance;
        // If account is not exluded from rewards, reset rewards, else return
        if (!_holders[account].excludeFromRewards) _resetRewards(account, reward);
        else return;
    }

///////////////////////////////////////////
// Rewards Functions
///////////////////////////////////////////
    function _distributeBNB(uint256 amountWei) private {
        uint256 marketing = amountWei * _marketingTax / 100;
        uint256 rewards = amountWei - marketing;
        // If no tokens are held, all distributed BNB will go to marketing wallet
        if (_totalTokensHeld == 0) _totalMarketingBNB += (marketing + rewards);
        else {
            _totalMarketingBNB += marketing;
            _totalRewardsBNB += rewards;
            _profitPerToken += (rewards * (2 ** 64)) / _totalTokensHeld;
        }
    }
    function _setIncludedToRewards(address account) private {
        require(_holders[account].excludeFromRewards);
        _holders[account].excludeFromRewards = false;
        _totalTokensHeld += _balances[account];
        _resetRewards(account, 0);
    }
    function _deductRewards(address account, uint256 amountWei) private {
        require(amountWei > 0 && amountWei <= _rewardsOf(account));
        if (!_holders[account].excludeFromRewards) _resetRewards(account, _newRewardsOf(account));
        _holders[account].rewardsToBePaid -= amountWei;
    }   
    function _resetRewards(address account, uint256 reward) private {
        // Reset rewardsPaid offset.
        _holders[account].rewardsPaid = _profitPerToken * _balances[account]; 
        // Add outstanding rewards to rewardsToBePaid.
        _holders[account].rewardsToBePaid += reward;
    }
    function _rewardsOf(address account) private view returns (uint256) {
        return _holders[account].excludeFromRewards ? 0 : _holders[account].rewardsToBePaid + _newRewardsOf(account);
    }
    function _newRewardsOf(address account) private view returns (uint256) {
        uint256 rewards = _profitPerToken * _balances[account];
        // If rewards are greater than rewards paid, return the difference
        return rewards <= _holders[account].rewardsPaid ? 0 : (rewards - _holders[account].rewardsPaid) / (2 ** 64);
    }
    function _claimBNBTo(address from, address recipient) private {
        uint256 totalRewards = _rewardsOf(from); 
        require(!_isWithdrawing);
        require(totalRewards > 0);   
        _isWithdrawing = true;
        _deductRewards(from, totalRewards);
        _totalRewardBNBPaid += totalRewards;
        (bool sent,) = recipient.call{value: (totalRewards)}("");
        require(sent);
        _isWithdrawing = false;
        emit ClaimBNBTo(from, recipient, totalRewards);
    }
///////////////////////////////////////////
// Liquidity Functions
///////////////////////////////////////////
    function _swapContractTokens(uint16 _swapThreshold, bool ignoreLimits) private lockTheSwap {
        uint256 contractBalance = _balances[address(this)] - _tokensToBurn;
        uint256 toSwap = _swapThreshold * _balances[_pancakePairAddress] / 1000;
        toSwap = toSwap > _maxSellSize ? _maxSellSize : toSwap;
        if (contractBalance < toSwap) {
            if (ignoreLimits)
                toSwap = contractBalance;
            else return;
        }
        // Calculate the total tokens for LP
        uint256 totalLiquidityTokens = toSwap * _liquidityTax / 100;
        uint256 tokensLeft = toSwap - totalLiquidityTokens;
        uint256 liquidityTokens = totalLiquidityTokens / 2;
        uint256 liquidityBNBTokens = totalLiquidityTokens - liquidityTokens;
        uint256 totalSwap = liquidityBNBTokens + tokensLeft;
        uint256 oldBNB = address(this).balance;
        _swapTokensForBNB(totalSwap);
        uint256 newBNB = address(this).balance - oldBNB;
        uint256 LPBNB = (newBNB * liquidityBNBTokens) / totalSwap;
        _addLiquidity(liquidityTokens, LPBNB);
        uint256 remainingBNB = address(this).balance - oldBNB;
        _distributeBNB(remainingBNB);
    }
    function _addLiquidity(uint256 amountTokens, uint256 amountBNB) private {
        _totalLiquidityBNB += amountBNB;
        _addingLiquidity = true;
        _pancakeRouter.addLiquidityETH{value: amountBNB}(
            // Liquidity Tokens are sent from contract, NOT OWNER!
            address(this),
            amountTokens,
            0,
            0,
            // contract receives CAKE-LP, NOT OWNER!
            address(this),
            block.timestamp
        );
        _addingLiquidity = false;
    }
    function _removeLiquidityPercent(uint8 percent) private {
        IPancakeERC20 lpToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = lpToken.balanceOf(address(this)) * percent / 100;
        lpToken.approve(address(_pancakeRouter), amount);
        _removingLiquidity = true;
        _pancakeRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            0,
            0,
            // Receiver address
            address(this),
            block.timestamp
        );
        _removingLiquidity = false;
    }
    function _swapTokensForBNB(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        // WBNB
        path[1] = _pancakeRouter.WETH();
        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            // Receiver address
            address(this),
            block.timestamp
        );
    }
    function _swapBNBForTokens(address recipient, address token, uint256 amountWei) private {
        _isWithdrawing = true;
        address[] memory path = new address[](2);
        // WBNB
        path[0] = _pancakeRouter.WETH();
        path[1] = token;  
        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountWei}(
            0,
            path,
            recipient,
            block.timestamp);
        _isWithdrawing = false;
    }
///////////////////////////////////////////
// Buy-Back Functions
///////////////////////////////////////////
    function _buyBack(uint256 amountWei) private {
        require(!_isWithdrawing);
        require(amountWei > 0 && amountWei <= _totalMarketingBNB);
        uint256 oldBalance = _balances[address(this)]; 
        _swapBNBForTokens(address(this), address(this), amountWei);
        // Check if tokens were actually bought
        require(_balances[address(this)] > oldBalance);
        // Add tokens in contract, toBeBurn
        _tokensToBurn += _balances[address(this)] - oldBalance;
        // Decreaste the marketing BNB
        _totalMarketingBNB -= amountWei;
    }
///////////////////////////////////////////
// Team/Owner Public Functions
///////////////////////////////////////////
    function ownerCreateLP(uint8 teamPercent, uint8 contractPercent) public onlyOwner {
        require(IBEP20(_pancakePairAddress).totalSupply() == 0);
        uint256 contractBalance = _balances[address(this)];
        // Tokens to be reserved for the team
        uint256 teamTokens = contractBalance * teamPercent / 100;
        // Tokens to remain in contract
        uint256 contractTokens = contractBalance * contractPercent / 100;
        // Tokens to be added to the LP
        uint256 LPTokens = contractBalance - (teamTokens + contractTokens);
        // Team tokens sent to owner
        _transferExcluded(address(this), msg.sender, teamTokens);
        _addLiquidity(LPTokens, address(this).balance);
        require(IBEP20(_pancakePairAddress).totalSupply() > 0);
        emit OwnerCreateLP(teamPercent, contractPercent);
    }
    function teamEnableTrading() public onlyOwner {
        // This function can only be called once
        require(!_canTrade);
        _canTrade = true; // true
        // Liquidity is locked for 7 days
        _liquidityUnlockTime = block.timestamp + 7 days;
        // Team tokens are vested (locked) for 60 days
        _holders[teamWallet].nextSell = block.timestamp + 60 days;
        // All buys in the next 5 minutes are burned and added to LP
        _antiBotTimer = 0;//block.timestamp;
    }
    // Calling this function breaks the rewards
    function withdrawBNB() public onlyOwner {
        // Transfers BNB in contract to owner.
        (bool success,) = teamWallet.call{value: (address(this).balance)}("");
        require(success);
    }
    function lockExternalTeamTokens(address _teamWallet) public onlyOwner {
        // Tokens cannot be locked after trading has been enabled, only before.
        require(!_canTrade);
        _holders[_teamWallet].nextSell = block.timestamp + 60 days;
        _setIncludedToRewards(_teamWallet);
        emit LockExternalTeamTokens(_teamWallet);
    }
    function teamBurnContractTokens(uint8 burnPercent) public onlyTeam {
        require(_tokensToBurn > 0);
        uint256 toBurn = _tokensToBurn * burnPercent / 100;
        // Send _tokensToBurn to burn wallet
        _transferExcluded(address(this), burnWallet, toBurn);
        _totalTokensBurned += toBurn;
        _tokensToBurn -= toBurn;
        emit TeamBurnContractTokens(toBurn);
    }
    function teamRemoveLiquidityPercent(uint8 percent, bool rewardBoost) public onlyTeam {
        // Cannot remove liquidity unless timer is over
        require(block.timestamp >= _liquidityUnlockTime);
        // If remove20Percent is enabled, can remove upto 20 % of LP, otherwise the lock is auto-reset
        percent=remove20PercentEnabled?percent>20?20:percent:0;
        _liquidityUnlockTime=block.timestamp+7 days;
        if(percent==0)return;
        uint256 oldBNB = address(this).balance;
        _removeLiquidityPercent(percent);
        uint256 newBNB = address(this).balance - oldBNB;
        // Boost marketing, rewards
        if (rewardBoost) _distributeBNB(newBNB);
        // Boost only marketing BNB
        else _totalMarketingBNB += newBNB;
        emit TeamRemoveLiquidity(percent, rewardBoost);
    }
    // Incase token dies, LP can be removed.
    function teamReleaseLiquidity() public onlyTeam {
        // If the LP lock has not been reset for 30 days, team can remove ALL LP.
        require(block.timestamp>=_liquidityUnlockTime+30 days);
        uint256 oldBNB = address(this).balance;
        // Remove 100 % of LP
        _removeLiquidityPercent(100);
        uint256 newBNB = address(this).balance - oldBNB;
        _totalMarketingBNB+=newBNB;
    }
    function teamSwitch20PercentEnabled(bool enabled) public onlyTeam {
        remove20PercentEnabled = enabled;
        emit TeamSwitch20PercentEnabled(remove20PercentEnabled);
    }
    function teamSetPromoToken(address _promoToken, uint256 minHoldForBonus, bool enabled) public onlyTeam {
        require(_promoToken != address(this) && _promoToken != _pancakePairAddress);
        promoToken = _promoToken;
        _minHoldForBonus = minHoldForBonus;
        promoTokenEnabled = enabled;
        emit TeamSetPromoToken(promoToken, _minHoldForBonus, promoTokenEnabled);
    }
    function teamSetFarmToken(address _farmToken) public onlyTeam {
        require(_farmToken != address(this) && _farmToken != _pancakePairAddress);
        farmToken = _farmToken;
        emit TeamSetFarmToken(farmToken);
    }
    function teamTriggerBuyBack(uint256 amountWei) public onlyTeam {
        require(!_isWithdrawing);
        _buyBack(amountWei);
        emit TeamTriggerBuyBack(amountWei);
    }
    function teamExtendLPLock(uint256 timeSeconds) public onlyTeam {
        require(timeSeconds<=7 days);
        _liquidityUnlockTime += timeSeconds;
        emit TeamExtendLPLock(_liquidityUnlockTime);
    }
    function teamChangeTaxes(
        uint8 buyTax,
        uint8 sellTax,
        uint8 burnTax,
        uint8 marketingTax,
        uint8 rewardsTax,
        uint8 liquidityTax) public onlyTeam {
            require(buyTax <= _maxTax && sellTax <= _maxTax && burnTax <= 1);
            require((marketingTax + rewardsTax + liquidityTax) <= _totalTax);
            _buyTax = buyTax;
            _sellTax = sellTax;
            _burnTax = burnTax;
            _marketingTax = marketingTax;
            _rewardsTax = rewardsTax;
            _liquidityTax = liquidityTax;
            emit TeamChangeTaxes(_buyTax, _sellTax, _burnTax, _marketingTax, _rewardsTax, _liquidityTax);
        }
    function teamUpdateLimits() public onlyTeam {
        // Update to 1 % of circulating supply.
        _maxWalletSize = _maxSellSize = (_initialSupply - _totalTokensBurned) / 100;
        emit TeamChangeLimits(_maxWalletSize, _maxSellSize);
    }
    function teamTriggerSwapContractTokens(uint16 _swapThreshold, bool ignoreLimits) public onlyTeam {
        _swapContractTokens(_swapThreshold, ignoreLimits);
        emit TeamSwapContractTokens(swapThreshold, ignoreLimits);
    }
    // 0 disables sellDelay.
    function teamChangeSellDelay(uint256 sellDelay) public onlyTeam {
        // Cannot exceed 1 hour.
        require(sellDelay <= _maxSellDelay);
        _sellDelay = sellDelay;
        emit TeamChangeSellDelay(sellDelay);
    }
    function teamFixStuckBNB() public onlyTeam {
        uint256 stuckBNB = address(this).balance - (_totalMarketingBNB + _totalRewardsBNB);
        _totalMarketingBNB += stuckBNB>0?stuckBNB:0;
    }
    function teamBoostContract(bool rewardBoost) public payable {
        if (rewardBoost) _distributeBNB(msg.value);
        else _totalMarketingBNB += msg.value;
        emit TeamBoostContract(rewardBoost, msg.value);
    }
    function teamUpdateAMM(address AMMAddress, bool enabled) public onlyTeam {
        _automatedMarketMakers[AMMAddress] = enabled;
        _holders[AMMAddress].excludeFromRewards = true;
        emit TeamUpdateAMM(AMMAddress, enabled);
    }
    function teamUpdateSwapThreshold(uint16 _swapThreshold) public onlyTeam {
        swapThreshold=_swapThreshold>50?50:_swapThreshold;
        emit TeamUpdateSwapThreshold(swapThreshold);
    }
    function teamSetExcludedFromRewards(address account, bool exclude) public onlyTeam {
        if (exclude) {
            require(!_holders[account].excludeFromRewards);
            uint256 reward = _newRewardsOf(account);
            _resetRewards(account, reward);
            _holders[account].excludeFromRewards = true;
        } else _setIncludedToRewards(account);
    }
    function teamSwitchSwapAndLiquify() public onlyOwner {
        swapAndLiquifyDisabled = !swapAndLiquifyDisabled;
        emit TeamSwitchSwapAndLiquify(swapAndLiquifyDisabled);
    }
    function TeamWithdrawStrandedToken(address strandedToken) public onlyTeam {
        require((strandedToken!=_pancakePairAddress)&&strandedToken!=address(this)&&strandedToken!=address(promoToken));
        IBEP20 token=IBEP20(strandedToken);
        token.transfer(teamWallet, token.balanceOf(address(this)));
    }
    function teamWithdrawMarketingBNB(uint256 amountWei) public onlyTeam {
        require(amountWei <= _totalMarketingBNB);
        (bool success,) = teamWallet.call{value: (amountWei)}("");
        require(success);
        _totalMarketingBNB -= amountWei;
    }
    function teamChangeWallet(address newWallet) public onlyTeam {
        require(block.timestamp >= _holders[teamWallet].nextSell);
        teamWallet = newWallet;
        emit TeamChangeWallet(newWallet);
    }
    // Disable anti-snipe manually, if needed
    function teamDisableAntiSnipe() public onlyTeam {
        _antiBotTimer = 0;
    }
    function teamResetOneTimeExcluded() public onlyTeam {
        _oneTimeExcluded = address(0);
    }
    function resetFlags() public onlyTeam {
        _removingLiquidity = _addingLiquidity = _isWithdrawing = false;
    }
///////////////////////////////////////////
// Public Rewards Functions
///////////////////////////////////////////
    function claimToken() public {
        uint256 amountWei = _rewardsOf(msg.sender);
        require(!_automatedMarketMakers[farmToken] && !_isWithdrawing && amountWei > 0);
        uint256 oldBalance = IBEP20(farmToken).balanceOf(msg.sender);
        _swapBNBForTokens(msg.sender, farmToken, amountWei);
        uint256 newBalance = IBEP20(farmToken).balanceOf(msg.sender) - oldBalance;
        require(newBalance > 0);
        _deductRewards(msg.sender, amountWei);
        _totalRewardBNBPaid += amountWei;
        //
    }
    function includeMeToRewards() public {
        _setIncludedToRewards(msg.sender);
    }
///////////////////////////////////////////
// BEP-2O Functions
///////////////////////////////////////////
    function airdrop(address[] memory addresses, uint256[] memory amounts, bool fromContract) external onlyOwner {
        require(addresses.length > 0 && amounts.length > 0 && addresses.length == amounts.length);
        address from = fromContract ? address(this) : msg.sender;
        for (uint i = 0; i < addresses.length; i++) {
            uint256 amount = amounts[i] * 10 ** 9; 
            _vestors[addresses[i]] = true;
            _unvested[addresses[i]] = amount;
            _transferExcluded(from, addresses[i], amount);
        }
        
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require((owner != address(0) && spender != address(0)), "Owner/Spender address cannot be 0.");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        uint256 allowance_ = _allowances[sender][msg.sender];
        _transfer(sender, recipient, amount);
        require(allowance_ >= amount);
        _approve(sender, msg.sender, allowance_ - amount);
            emit Transfer(sender, recipient, amount);
        return true;
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    receive() external payable {
        require(msg.sender == _pancakeRouterAddress || msg.sender == owner() || msg.sender == teamWallet);
    }
    function allTaxes() external view returns (
        uint8 buyTax, 
        uint8 sellTax, 
        uint8 burnTax, 
        uint8 marketingTax, 
        uint8 liquidityTax, 
        uint8 rewardsTax) {
            buyTax = _buyTax;
            sellTax = _sellTax;
            burnTax = _burnTax;
            marketingTax = _marketingTax;
            liquidityTax = _liquidityTax;
            rewardsTax = _rewardsTax;
    }
    function trackContractBNB() external view returns (
        uint256 marketingBNB,
        uint256 liquidityBNB,
        uint256 rewardBNB) {
            marketingBNB = _totalMarketingBNB;
            liquidityBNB = _totalLiquidityBNB;
            rewardBNB = _totalRewardsBNB;
    }
    function antiBotTimeLeft() external view returns (uint256) {
        return _antiBotTimer>block.timestamp?_antiBotTimer-block.timestamp:0;
    }
    function rewardsOf(address account) external view returns (uint256) {
        return _rewardsOf(account);
    }
    function nextSellOf(address account) external view returns(uint256) {
        return _holders[account].nextSell > block.timestamp ? _holders[account].nextSell - block.timestamp : 0;
    }
    function totalRewardBNBPaid() external view returns (uint256) {
        return _totalRewardBNBPaid;
    }
    function totalTokensHeld() external view returns(uint256){
        return _totalTokensHeld;
    }
    function totalTokensBurned() external view returns(uint256){
        return _totalTokensBurned;
    }
    function tokensToBurn() external view returns(uint256){
        return _tokensToBurn;
    }
    function liquidityUnlockTimeLeft() external view returns (uint256) {
        return _liquidityUnlockTime>block.timestamp?_liquidityUnlockTime-block.timestamp:0;
    }
    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowances[owner_][spender];
    }
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    function name() external pure override returns (string memory) {
        return "FarmerDoge2";
    }
    function symbol() external pure override returns (string memory) {
        return "CROP";
    }
    function totalSupply() external view override returns (uint256) {
        return _initialSupply - _totalTokensBurned;
    }
    function decimals() external pure override returns (uint8) {
        return 9;
    }
    function getOwner() external view override returns (address) {
        return owner();
    }
}