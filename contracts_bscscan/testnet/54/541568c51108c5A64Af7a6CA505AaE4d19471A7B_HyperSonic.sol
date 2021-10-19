/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface ITokenConverter {
    function convertViaWETH(
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) external view returns (uint256);

    function DEFAULT_FACTORY() external view returns (IDEXFactory);
}

abstract contract Auth {
    address public owner;
    mapping(address => bool) public isAuthorized;

    constructor() {
        owner = msg.sender;
        isAuthorized[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!OWNER");
        _;
    }
    modifier authorized() {
        require(isAuthorized[msg.sender], "!AUTHORIZED");
        _;
    }

    function authorize(address adr) external onlyOwner {
        isAuthorized[adr] = true;
    }

    function unauthorize(address adr) external onlyOwner {
        isAuthorized[adr] = false;
    }

    function setAuthorizationMultiple(address[] memory adr, bool value) external onlyOwner {
        for (uint256 i = 0; i < adr.length; i++) {
            isAuthorized[adr[i]] = value;
        }
    }

    function transferOwnership(address payable adr) external onlyOwner {
        isAuthorized[owner] = false;
        owner = adr;
        isAuthorized[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract DividendDistributor {
    address public _token;
    IBEP20 public SSN = IBEP20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    IDEXRouter public router;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
        uint256 index;
        uint256 lastClaimed;
    }
    mapping(address => Share) public shares;
    address[] shareholders;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public _ACCURACY_ = 1e36;
    uint256 public minPeriod = 30 minutes;
    uint256 public minDistribution = 1e18;
    uint256 public shareThreshold = 0;

    uint256 public currentIndex;
    uint256 public maxGas = 500000;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _router) {
        router = _router != address(0) ? IDEXRouter(_router) : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
    }

    function setRouter(IDEXRouter _router) external onlyToken {
        router = _router;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _shareThreshold) external onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        shareThreshold = _shareThreshold;
    }

    function setMaxGas(uint256 gas) external onlyToken {
        maxGas = gas;
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
        Share storage _S = shares[shareholder];
        if (_S.amount > 0) {
            _sendDividend(shareholder);
            if (amount < shareThreshold) _removeShareholder(shareholder);
        } else if (amount >= shareThreshold) _addShareholder(shareholder);
        totalShares -= _S.amount;
        totalShares += amount;
        _S.amount = amount;
        _S.totalExcluded = _getCumulativeDividends(shareholder);
    }

    function deposit() external payable onlyToken {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(SSN);
        uint256 gotSSN = SSN.balanceOf(address(this));
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(0, path, address(this), block.timestamp);
        gotSSN = SSN.balanceOf(address(this)) - gotSSN;

        totalDividends += gotSSN;
        dividendsPerShare += (_ACCURACY_ * gotSSN) / totalShares;
    }

    function sendDividends(uint256 gas) external onlyToken {
        uint256 shareholderCount = shareholders.length;
        if (shareholderCount == 0) return;

        uint256 gasUsed;
        uint256 gasLeft = gasleft();

        uint256 _currentIndex = currentIndex;
        for (uint256 i = 0; i < shareholderCount && gasUsed < gas; i++) {
            if (_currentIndex >= shareholderCount) _currentIndex = 0;
            address _shareholder = shareholders[_currentIndex];
            if (block.timestamp > shares[_shareholder].lastClaimed + minPeriod && getUnpaidEarnings(_shareholder) > minDistribution) {
                _sendDividend(_shareholder);
            }
            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
            _currentIndex++;
        }
        currentIndex = _currentIndex;
    }

    function _getCumulativeDividends(address shareholder) internal view returns (uint256) {
        return (shares[shareholder].amount * dividendsPerShare) / _ACCURACY_;
    }

    function _sendDividend(address shareholder) internal {
        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount == 0) return;

        SSN.transfer(shareholder, amount);
        totalDistributed += amount;
        shares[shareholder].totalRealised += amount;
        shares[shareholder].totalExcluded = _getCumulativeDividends(shareholder);
        shares[shareholder].lastClaimed = block.timestamp;
    }

    function _addShareholder(address shareholder) internal {
        shares[shareholder].index = shareholders.length;
        shareholders.push(shareholder);
    }

    function _removeShareholder(address shareholder) internal {
        _sendDividend(shareholder);
        shareholders[shares[shareholder].index] = shareholders[shareholders.length - 1];
        shares[shareholders[shareholders.length - 1]].index = shares[shareholder].index;
        delete shares[shareholder];
        shareholders.pop();
    }

    function claimDividend() external {
        _sendDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        uint256 _dividends = _getCumulativeDividends(shareholder);
        uint256 _excluded = shares[shareholder].totalExcluded;
        return _dividends > _excluded ? _dividends - _excluded : 0;
    }
}

contract HyperSonic is Auth {
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    ITokenConverter public constant TOKEN_CONVERTER = ITokenConverter(0x45A69C32F6A7C2bd67F949AA8FA7d69f9FE1d3Ce);

    string public constant name = "Hypersonic";
    string public constant symbol = "HSN";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 1e6 * 1e18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isBuyLimitExempt;
    mapping(address => bool) public isWalletLimitExempt;
    mapping(address => bool) public isDividendExempt;

    bool public buyLimitEnabled = true;
    uint256 public buyLimitBUSD = 5000e18;

    uint256 public walletLimit = 5000e18;

    IDEXRouter public router;
    address public pair;
    DividendDistributor public distributor;
    uint256 public distributorGas = 500000;

    uint256 public launchedAt;
    bool public tradingOpen;

    struct FeeSettings {
        uint256 liquidity;
        uint256 dividends;
        uint256 total;
        uint256 _burn;
        uint256 _denominator;
    }
    struct SwapbackSettings {
        bool enabled;
        bool forbidDuringBuy;
        bool forbidDuringSell;
        uint256 amount;
    }

    FeeSettings public fees = FeeSettings({liquidity: 100, dividends: 300, total: 400, _burn: 100, _denominator: 10000});
    SwapbackSettings public swapback = SwapbackSettings({enabled: true, forbidDuringBuy: true, forbidDuringSell: false, amount: totalSupply / 1000});

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTKN);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        // PANCAKE V1 ROUTER 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
        // PANCAKE V2 ROUTER 0x10ED43C718714eb63d5aA57B78B54704E256024E
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        allowance[address(this)][address(router)] = ~uint256(0);

        distributor = new DividendDistributor(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

        isFeeExempt[DEAD] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

        isBuyLimitExempt[DEAD] = true;
        isBuyLimitExempt[msg.sender] = true;
        isBuyLimitExempt[address(this)] = true;

        isWalletLimitExempt[DEAD] = true;
        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(this)] = true;

        isDividendExempt[DEAD] = true;
        isDividendExempt[msg.sender] = true;
        isDividendExempt[address(this)] = true;

        isDividendExempt[pair] = true;

        // Owner must manually whitelist DXSale presale contract
        // isFeeExempt[_presaleContract] = true;
        // isBuyLimitExempt[_presaleContract] = true;
        // isDividendExempt[_presaleContract] = true;

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable {}

    function getOwner() external view returns (address) {
        return owner;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, ~uint256(0));
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        if (allowance[sender][msg.sender] != ~uint256(0)) allowance[sender][msg.sender] -= amount;
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) return _basicTransfer(sender, recipient, amount);
        if (tradingOpen) require(isAuthorized[sender] || isAuthorized[recipient], "Trading not open yet");

        bool _isBuy = sender == pair;
        bool _isSell = recipient == pair;
        bool _isJustTransfer = !_isBuy && _isSell;
        bool _isFirst24Hours = block.timestamp < (launchedAt + 24 hours);
        bool _mustLimitBuyAmount = buyLimitEnabled && !isBuyLimitExempt[recipient];

        // Limit wallet balance during first 24h
        if (_isFirst24Hours && !isWalletLimitExempt[recipient]) require(balanceOf[recipient] + amount <= walletLimit, "Recipient balance limit exceeded");

        // Limit BUY during first 24h
        if (_isBuy && _mustLimitBuyAmount) {
            uint256 _BUSDEquivalent = TOKEN_CONVERTER.convertViaWETH(address(this), BUSD, amount);
            if (_BUSDEquivalent > 0) require(_BUSDEquivalent <= buyLimitBUSD, "BUY limit exceeded");
        }

        // Sells accumulated fee for BNB and distribute
        if (
            swapback.enabled &&
            (balanceOf[address(this)] >= swapback.amount) &&
            !(_isBuy && swapback.forbidDuringBuy) &&
            !(_isSell && swapback.forbidDuringSell)
        ) {
            // (?swapback enabled?) Sells accumulated TKN fees for BNB
            _sellAndDistributeAccumulatedTKNFee();
        }

        // Launch at first liquidity
        if (launchedAt == 0 && recipient == pair) {
            require(balanceOf[sender] > 0);
            launchedAt = block.timestamp;
        }

        // Take fee; burn;
        // Exchange balances
        balanceOf[sender] -= amount;
        uint256 amountReceived = amount;
        if (!isFeeExempt[sender] && !_isJustTransfer) {
            if (fees.total > 0) {
                uint256 feeAmount = (amount * fees.total) / fees._denominator;
                balanceOf[address(this)] += feeAmount;
                emit Transfer(sender, address(this), feeAmount);
                amountReceived -= feeAmount;
            }
            if (fees._burn > 0) {
                uint256 burnAmount = (amount * fees._burn) / fees._denominator;
                balanceOf[DEAD] += burnAmount;
                emit Transfer(sender, DEAD, burnAmount);
                amountReceived -= burnAmount;
            }
        }
        balanceOf[recipient] += amountReceived;
        emit Transfer(sender, recipient, amountReceived);

        // Dividend tracker
        if (!isDividendExempt[sender]) try distributor.setShare(sender, balanceOf[sender]) {} catch {}
        if (!isDividendExempt[recipient]) try distributor.setShare(recipient, balanceOf[recipient]) {} catch {}
        try distributor.sendDividends(distributorGas) {} catch {}

        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _sellAndDistributeAccumulatedTKNFee() internal swapping {
        // Swap the fee taken above to BNB and distribute to liquidity and dividends;
        // Add some liquidity
        uint256 halfLiquidityFee = fees.liquidity / 2;
        uint256 TKNtoLiquidity = (swapback.amount * halfLiquidityFee) / fees.total;
        uint256 amountToSwap = swapback.amount - TKNtoLiquidity;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 gotBNB = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, address(this), block.timestamp);
        gotBNB = address(this).balance - gotBNB;

        uint256 totalBNBFee = fees.total - halfLiquidityFee;
        uint256 BNBtoLiquidity = (gotBNB * halfLiquidityFee) / totalBNBFee;
        uint256 BNBtoDividends = (gotBNB * fees.dividends) / totalBNBFee;

        try distributor.deposit{value: BNBtoDividends}() {} catch {}

        if (TKNtoLiquidity > 0) {
            router.addLiquidityETH{value: BNBtoLiquidity}(address(this), TKNtoLiquidity, 0, 0, owner, block.timestamp);
            emit AutoLiquify(BNBtoLiquidity, TKNtoLiquidity);
        }
    }

    function _sellBNB(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, to, block.timestamp);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return totalSupply - balanceOf[DEAD] - balanceOf[ZERO];
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return (accuracy * (balanceOf[pair] * 2)) / getCirculatingSupply();
    }

    // SET EXEMPTS

    function setIsFeeExempt(address[] memory holders, bool exempt) public onlyOwner {
        for (uint256 i = 0; i < holders.length; i++) {
            isFeeExempt[holders[i]] = exempt;
        }
    }

    function setIsBuyLimitExempt(address[] memory holders, bool exempt) public onlyOwner {
        for (uint256 i = 0; i < holders.length; i++) {
            isBuyLimitExempt[holders[i]] = exempt;
        }
    }

    function setIsWalletLimitExempt(address[] memory holders, bool exempt) public onlyOwner {
        for (uint256 i = 0; i < holders.length; i++) {
            isWalletLimitExempt[holders[i]] = exempt;
        }
    }

    function setIsDividendExempt(address[] memory holders, bool exempt) public onlyOwner {
        for (uint256 i = 0; i < holders.length; i++) {
            require(holders[i] != address(this) && holders[i] != pair);
            isDividendExempt[holders[i]] = exempt;
            distributor.setShare(holders[i], exempt ? 0 : balanceOf[holders[i]]);
        }
    }

    function setFullExempt(address[] memory holders, bool exempt) external onlyOwner {
        setIsFeeExempt(holders, exempt);
        setIsBuyLimitExempt(holders, exempt);
        setIsWalletLimitExempt(holders, exempt);
        setIsDividendExempt(holders, exempt);
    }

    // TOKEN SETTINGS

    function setBuyLimitSettings(uint256 amount, bool enabled) external onlyOwner {
        buyLimitBUSD = amount;
        buyLimitEnabled = enabled;
    }

    function setWalletLimitSettings(uint256 amount) external onlyOwner {
        walletLimit = amount;
    }

    function setFees(
        uint256 _liquidity,
        uint256 _dividends,
        uint256 _burn,
        uint256 _denominator
    ) external onlyOwner {
        fees = FeeSettings({liquidity: _liquidity, dividends: _dividends, total: _liquidity + _dividends, _burn: _burn, _denominator: _denominator});
        require(fees.total + _burn < fees._denominator / 4);
    }

    function setSwapBackSettings(
        bool _enabled,
        bool _forbidDuringBuy,
        bool _forbidDuringSell,
        uint256 _amount
    ) external onlyOwner {
        swapback.enabled = _enabled;
        swapback.forbidDuringBuy = _forbidDuringBuy;
        swapback.forbidDuringSell = _forbidDuringSell;
        swapback.amount = _amount;
    }

    function setTradingStatus(bool _status) external onlyOwner {
        tradingOpen = _status;
    }

    // DISTRIBUTOR SETTINGS

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _shareThreshold) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution, _shareThreshold);
    }

    function setDistributorGas(uint256 gas) external onlyOwner {
        require(gas <= 750000, "Max 750000 gas allowed");
        distributor.setMaxGas(gas);
    }

    function setDistributorRouter(IDEXRouter _router) external onlyOwner {
        distributor.setRouter(_router);
    }

    /* Airdrop Begins */
    function makeItRain(address[] memory addresses, uint256[] memory tokens) external onlyOwner {
        uint256 showerCapacity = 0;
        require(addresses.length == tokens.length, "Mismatch between Address and token count");
        for (uint256 i = 0; i < addresses.length; i++) showerCapacity += tokens[i];
        require(balanceOf[msg.sender] >= showerCapacity, "Not enough tokens to airdrop");
        for (uint256 i = 0; i < addresses.length; i++) _basicTransfer(msg.sender, addresses[i], tokens[i]);
    }
}