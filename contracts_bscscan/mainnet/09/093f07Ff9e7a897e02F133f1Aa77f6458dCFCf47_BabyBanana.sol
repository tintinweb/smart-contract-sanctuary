// SPDX-License-Identifier: MIT

/**
 *    ___       __        ___                          
 *   / _ )___ _/ /  __ __/ _ )___ ____  ___ ____  ___ _
 *  / _  / _ `/ _ \/ // / _  / _ `/ _ \/ _ `/ _ \/ _ `/
 * /____/\_,_/_.__/\_, /____/\_,_/_//_/\_,_/_//_/\_,_/ 
 *                /___/                                
 *
 * Pioneers on the jungle ecosystem!
 *
 * Website     https://babybanana.finance
 * Twitter     https://twitter.com/BabyBananaToken
 * Telegram    https://t.me/BabyBananaOfficial
 * Discord     https://discord.gg/ukuy4TBMJw
 * Reddit      https://www.reddit.com/r/BabyBananaOfficial
 * Instagram   https://www.instagram.com/babybananatoken
 *
 * In memory of Selma
 */

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./DividendDistributor.sol";

contract BabyBanana is IBEP20 {
    struct TokenLock {
        uint256 amount;
        uint256 releaseTime;
    }

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address constant MULTI_SIG_TEAM_WALLET = 0x48e065F5a65C3Ba5470f75B65a386A2ad6d5ba6b;
    address constant MARKETING_WALLET = 0x0426760C100E3be682ce36C01D825c2477C47292;
    address constant PRESALE_CONTRACT = 0xa5707412E6F3e06e932b139C3BCAD26a0734Ab91;

    IBabyBananaNFT public constant BABYBANANA_NFT = IBabyBananaNFT(0x986462937DE0B064364631c9b72A15ac8cc76678);
    ISelmaNFT public constant SELMA_NFT = ISelmaNFT(0x824Db8c2Cf7eC655De2A7825f8E9311c8e526523);

    bool public autoBuybackEnabled = false;
    bool public swapEnabled = true;
    bool _inSwap;

    uint8 constant DECIMALS = 18;
    uint256 constant TOTAL_SUPPLY = 1 * 10**9 * 10**DECIMALS;
    uint256 public swapThreshold = 300000 * 10**DECIMALS;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => TokenLock) _lockedTokens;

    uint256 public buybackFee = 300;
    uint256 public rewardFee = 100;
    uint256 public marketingFee = 100;
    uint256 _totalFee = 500;
    uint256 constant FEE_DENOMINATOR = 10000;

    IApeRouter public constant ROUTER = IApeRouter(0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7);
    address public immutable pair;
    uint256 _launchedAt;

    uint256 public lastNftBuyback;
    uint256 public nftBuybackCooldown = 3 days;
    uint256 public lastMarketingBuyback;
    uint256 constant public marketingBuybackCooldown = 1 days;

    uint256 public autoBuybackCap;
    uint256 public autoBuybackAccumulator;
    uint256 public autoBuybackAmount;
    uint256 public autoBuybackBlockPeriod;
    uint256 public autoBuybackBlockLast;

    DividendDistributor public immutable distributor;
    uint256 _marketingTransferGas = 30000;

    event NFTBuyback(address indexed account, uint256 indexed tokenId, uint256 amount);
    event Launch(uint256 timestamp);
    event SetMarketingTransferGas(uint256 gas);
    event SetDividendExempt(address indexed account, bool indexed exempt);
    event SetFeeExempt(address indexed account, bool indexed exempt);
    event SetFees(uint256 buyback, uint256 reward, uint256 marketing);
    event SetSwapBackSettings(bool indexed enabled, uint256 amount);
    event SetAutoBuybackSettings(bool indexed enabled, uint256 cap, uint256 amount, uint256 period);
    event SetNFTBuybackCooldown(uint256 cooldown);
    event TriggerBuyback(uint256 amount);
    event TriggerSwapBack();
    event SendLockedTokens(address indexed recipient, uint256 amount, uint256 releaseTime);
    event UnlockTokens(address indexed account);

    modifier swapping() { 
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier onlyTeam() {
        require(msg.sender == MULTI_SIG_TEAM_WALLET);
        _;
    }

    modifier onlyMarketing() {
        require(msg.sender == MARKETING_WALLET);
        _;
    }

    constructor () {
        pair = IApeFactory(ROUTER.factory()).createPair(ROUTER.WETH(), address(this));
        _allowances[address(this)][address(ROUTER)] = type(uint256).max;

        distributor = new DividendDistributor();
        excludeAccounts();

        _balances[MULTI_SIG_TEAM_WALLET] = TOTAL_SUPPLY;
        emit Transfer(address(0), MULTI_SIG_TEAM_WALLET, TOTAL_SUPPLY);
    }

    // IBEP20

    function totalSupply() external pure override returns (uint256) { return TOTAL_SUPPLY; }
    function decimals() external pure override returns (uint8) { return DECIMALS; }
    function symbol() external pure override returns (string memory) { return "BBNANA"; }
    function name() external pure override returns (string memory) { return "BabyBanana"; }
    function getOwner() external pure override returns (address) { return MULTI_SIG_TEAM_WALLET; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address _owner, address spender) external view override returns (uint256) { return _allowances[_owner][spender]; }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transferFrom(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    // IBEP20 Helpers

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    // Public

    receive() external payable {}

    function lockedAccountInfo(address account) external view returns (TokenLock memory) {
        return _lockedTokens[account];
    }

    function getTotalFee() public view returns (uint256) {
        if(_launchedAt + 1 >= block.number){ return FEE_DENOMINATOR - 100; }
        return _totalFee;
    }

    function getCirculatingSupply() external view returns (uint256) {
        return TOTAL_SUPPLY - _balances[DEAD] - _balances[ZERO];
    }

    function nftBuyback(uint256 tokenId) external {
        uint256 buybackAmount = BABYBANANA_NFT.featureValueOf(0, msg.sender);
        require(buybackAmount > 0 && buybackAmount <= 15 ether, "Invalid amount");
        require(address(this).balance >= buybackAmount, "Insufficient balance");
        require(lastNftBuyback + nftBuybackCooldown <= block.timestamp, "Buyback is cooling down");

        BABYBANANA_NFT.consume(tokenId, msg.sender);
        buyTokens(buybackAmount, DEAD);
        lastNftBuyback = block.timestamp;

        emit NFTBuyback(msg.sender, tokenId, buybackAmount);
    }

    // Private

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        if(_inSwap){ return _basicTransfer(sender, recipient, amount); }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        if (_lockedTokens[sender].releaseTime > block.timestamp) {
            require(senderBalance - amount >= _lockedTokens[sender].amount, "Tokens are locked");
        }

        if(shouldSwapBack(recipient)){ swapBack(); }
        if(shouldAutoBuyback(recipient)){ triggerAutoBuyback(); }
        if(!launched() && recipient == pair && senderBalance > 0 && amount > 0){ launch(); }

        _balances[sender] = senderBalance - amount;

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] += amountReceived;

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process() {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) private returns (bool) {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender, address recipient) private view returns (bool) {
        if (isFeeExempt[sender]) { return false; }
        bool isSell = recipient == pair;
        bool isBuy = sender == pair;
        return isBuy || isSell;
    }

    function takeFee(address sender, address recipient, uint256 amount) private returns (uint256) {
        bool isBuy = sender == pair;
        address initiator = isBuy ? recipient : sender;
        uint256 discountMultiplier;

        uint256 nftDiscountMultiplier = nftTaxDiscount(initiator);
        uint256 selmaDiscountMultiplier = selmaTaxDiscount(initiator);

        if (nftDiscountMultiplier >= selmaDiscountMultiplier) {
            discountMultiplier = nftDiscountMultiplier;
        } else {
            discountMultiplier = selmaDiscountMultiplier;
        }

        uint256 discountedFee = getTotalFee() - getTotalFee() * discountMultiplier / FEE_DENOMINATOR;
        uint256 feeAmount = amount * discountedFee / FEE_DENOMINATOR;

        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function nftTaxDiscount(address account) private view returns (uint256) {
        try BABYBANANA_NFT.featureValueOf(3, account) returns (uint256 discountMultiplier) {
            return discountMultiplier > FEE_DENOMINATOR ? FEE_DENOMINATOR : discountMultiplier;
        } catch {
            return 0;
        }
    }

    function selmaTaxDiscount(address account) private view returns (uint256) {
        uint256 discountMultiplier;

        try SELMA_NFT.balanceOf(account, 1) returns (uint256 platinumBalance) {
            if (platinumBalance > 0) { discountMultiplier = 2500; }
        } catch {}

        try SELMA_NFT.balanceOf(account, 2) returns (uint256 diamondBalance) {
            if (diamondBalance > 0) { discountMultiplier = 5000; }
        } catch {}

        return discountMultiplier;
    }

    function shouldSwapBack(address recipient) private view returns (bool) {
        return recipient == pair
        && !_inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() private swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = ROUTER.WETH();

        uint256 balanceBefore = address(this).balance;

        ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance - balanceBefore;
        uint256 amountBNBRewards = amountBNB * rewardFee / _totalFee;
        uint256 amountBNBMarketing = amountBNB * marketingFee / _totalFee;

        try distributor.deposit{value: amountBNBRewards}() {} catch {}
        payable(MARKETING_WALLET).call{value: amountBNBMarketing, gas: _marketingTransferGas}("");
    }

    function shouldAutoBuyback(address recipient) private view returns (bool) {
        return recipient == pair
            && !_inSwap
            && autoBuybackEnabled
            && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
            && address(this).balance >= autoBuybackAmount;
    }

    function triggerAutoBuyback() private {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator += autoBuybackAmount;
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    function buyTokens(uint256 amount, address to) private swapping {
        address[] memory path = new address[](2);
        path[0] = ROUTER.WETH();
        path[1] = address(this);

        ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function launched() private view returns (bool) {
        return _launchedAt != 0;
    }

    function launch() private {
        _launchedAt = block.number;
        emit Launch(_launchedAt);
    }

    function excludeAccounts() private {
        isFeeExempt[MARKETING_WALLET] = true;
        isDividendExempt[MARKETING_WALLET] = true;

        isFeeExempt[MULTI_SIG_TEAM_WALLET] = true;
        isDividendExempt[MULTI_SIG_TEAM_WALLET] = true;

        isDividendExempt[PRESALE_CONTRACT] = true;

        isFeeExempt[address(this)] = true;
        isDividendExempt[address(this)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
    }

    // Maintenance

    function setMarketingTransferGas(uint256 gas) external onlyTeam {
        require(gas >= 21000 && gas <= 100000);
        _marketingTransferGas = gas;
        emit SetMarketingTransferGas(gas);
    }

    function setIsDividendExempt(address account, bool exempt) external onlyTeam {
        require(account != address(this) && account != pair && account != MARKETING_WALLET);

        isDividendExempt[account] = exempt;
        if (exempt) {
            distributor.setShare(account, 0);
        } else {
            distributor.setShare(account, _balances[account]);
        }

        emit SetDividendExempt(account, exempt);
    }

    function setIsFeeExempt(address account, bool exempt) external onlyTeam {
        require(account != MARKETING_WALLET && account != MULTI_SIG_TEAM_WALLET && account != address(this));
        isFeeExempt[account] = exempt;
        emit SetFeeExempt(account, exempt);
    }

    function setFees(uint256 _buybackFee, uint256 _rewardFee, uint256 _marketingFee) external onlyTeam {
        buybackFee = _buybackFee;
        rewardFee = _rewardFee;
        marketingFee = _marketingFee;
        _totalFee = buybackFee + rewardFee + marketingFee;
        require(_totalFee <= 1500);

        emit SetFees(buybackFee, rewardFee, marketingFee);
    }

    function setSwapBackSettings(bool enabled, uint256 amount) external onlyTeam {
        uint256 tokenAmount = amount * 10**DECIMALS;
        swapEnabled = enabled;
        swapThreshold = tokenAmount;
        emit SetSwapBackSettings(enabled, amount);
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external onlyTeam {
        require(_amount <= 10 ether, "Buyback is capped to 10 BNB");
        require(_period >= 100, "Minimum interval is 5 minutes with average 3s block time");
        
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;

        emit SetAutoBuybackSettings(_enabled, _cap, _amount, _period);
    }

    function setNftBuybackCooldown(uint256 cooldown) external onlyTeam {
        require(cooldown <= 1 weeks);
        nftBuybackCooldown = cooldown;
        emit SetNFTBuybackCooldown(cooldown);
    }

    function triggerBuyback(uint256 amount) external onlyMarketing {
        require(amount <= 30 ether, "Buyback is capped to 30 BNB");
        require(lastMarketingBuyback + marketingBuybackCooldown <= block.timestamp, "Buyback is cooling down");
        
        buyTokens(amount, DEAD);
        lastMarketingBuyback = block.timestamp;

        emit TriggerBuyback(amount);
    }

    function triggerSwapBack() external onlyMarketing {
        swapBack();
        emit TriggerSwapBack();
    }

    function sendLockedTokens(address recipient, uint256 amount, uint256 releaseTime) external onlyMarketing {
        _lockedTokens[recipient].amount += amount;
        _lockedTokens[recipient].releaseTime = releaseTime;
        _transferFrom(msg.sender, recipient, amount);

        emit SendLockedTokens(recipient, amount, releaseTime);
    }

    function unlockTokens(address account) external onlyTeam {
        _lockedTokens[account].releaseTime = 0;
        _lockedTokens[account].amount = 0;
        emit UnlockTokens(account);
    }
}