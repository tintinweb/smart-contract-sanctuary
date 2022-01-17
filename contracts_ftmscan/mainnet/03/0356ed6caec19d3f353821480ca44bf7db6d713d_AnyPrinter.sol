/**
 *Submitted for verification at FtmScan.com on 2022-01-17
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);
}

interface IDEXRouter {
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

interface IDividendDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
}

contract DividendDistributor is IDividendDistributor, Auth {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 BASE = IBEP20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    address WETH = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => uint256) public totalRewardsDistributed;
    mapping (address => mapping (address => uint256)) public totalRewardsToUser;

    mapping (address => mapping (address => bool)) public canClaimDividendOfUser;

    mapping (address => bool) public availableRewards;
    mapping (address => address) public pathRewards;

    mapping (address => Share) public shares;

    bool public blacklistMode = true;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed; // to be shown in UI
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router, address _owner) Auth(_owner) {
        router = _router != address(0)
        ? IDEXRouter(_router)
        : IDEXRouter(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        _token = msg.sender;

        IBEP20(BASE).approve(_router, 2**256 - 1);

    }

    receive() external payable { }

    function getTotalRewards(address token) public view returns(uint256){
        return totalRewardsDistributed[token];
    }

    function getTotalRewardsToUser(address token, address user) public view returns(uint256){
        return totalRewardsToUser[token][user];
    }

    function checkCanClaimDividendOfUser(address user, address claimer) public view returns(bool){
        return canClaimDividendOfUser[user][claimer];
    }

    function setReward(address _reward, bool status) public onlyOwner {

        availableRewards[_reward] = status;

    }

    function setPathReward(address _reward, address _path) public onlyOwner {

        pathRewards[_reward] = _path;

    }

    function setBlacklistMode(bool status) public onlyOwner {

        blacklistMode = status;

    }

    function changeRouterVersion(address _router)
        external
        onlyOwner
    {
        IDEXRouter _uniswapV2Router = IDEXRouter(_router);

        router = _uniswapV2Router;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {

        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder, address(BASE));
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder, address rewardAddress) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);

            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);

            //

            if(rewardAddress == address(BASE)) {
                payable(shareholder).transfer(amount);

                totalRewardsDistributed[rewardAddress] = totalRewardsDistributed[rewardAddress].add(amount);  
                totalRewardsToUser[rewardAddress][shareholder] = totalRewardsToUser[rewardAddress][shareholder].add(amount);

            } else {

                IBEP20 rewardToken = IBEP20(rewardAddress);

                uint256 beforeBalance = rewardToken.balanceOf(shareholder);

                if(pathRewards[rewardAddress] == address(0)) {
                    address[] memory path = new address[](2);
                    path[0] = address(BASE);
                    path[1] = rewardAddress;

                    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                        0,
                        path,
                        shareholder,
                        block.timestamp
                    );                 
                } else {
                    address[] memory path = new address[](3);
                    path[0] = address(BASE);
                    path[1] = pathRewards[rewardAddress];
                    path[2] = rewardAddress;

                    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                        0,
                        path,
                        shareholder,
                        block.timestamp
                    );             
  
                }

                uint256 afterBalance = rewardToken.balanceOf(shareholder);
    
                totalRewardsDistributed[rewardAddress] = totalRewardsDistributed[rewardAddress].add(afterBalance.sub(beforeBalance));  
                totalRewardsToUser[rewardAddress][shareholder] = totalRewardsToUser[rewardAddress][shareholder].add(afterBalance.sub(beforeBalance));

            }

            //

        }
    }

    function makeApprove(address token, address spender, uint256 amount) public onlyOwner {

        IBEP20(token).approve(spender, amount);

    }

    function claimDividend(address rewardAddress) external {

        if(blacklistMode) {
            require(!availableRewards[rewardAddress], "This reward is not available");
        } else {
            require(availableRewards[rewardAddress], "This reward is not available");
        }

        distributeDividend(msg.sender, rewardAddress);
    }

    function claimDividendOfUser(address user, address rewardAddress) external {

        require(canClaimDividendOfUser[user][msg.sender], "You can't do that");

        if(blacklistMode) {
            require(!availableRewards[rewardAddress], "This reward is not available");
        } else {
            require(availableRewards[rewardAddress], "This reward is not available");
        }

        distributeDividend(user, rewardAddress);
    }

    function setClaimDividendOfUser(address claimer, bool status) external {
        canClaimDividendOfUser[msg.sender][claimer] = status;
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function transferForeignToken(address token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        require(token != address(this), "Can't withdraw native tokens");
        uint256 _contractBalance = IBEP20(token).balanceOf(address(this));
        _sent = IBEP20(token).transfer(_to, _contractBalance);
    }

}

contract AnyPrinter is IBEP20, Auth {
    using SafeMath for uint256;

    uint256 public constant MASK = type(uint128).max;
    address BASE = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // BASE
    address public WETH = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "AnyPrinter V2";
    string constant _symbol = "ANYP";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1_000_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(50); // 2%
    uint256 public _maxWallet = _totalSupply.div(50); // 2%

    uint256 public minAmountToTriggerSwap = 0; // _totalSupply.div(10000); // 0.01%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public _isFree;

    bool public isFeeOnTransferEnabled = false;

    mapping (address => bool) public automatedMarketMakerPairs;

    uint256 buyLiquidityFee = 0;
    uint256 buyBuybackFee = 0;
    uint256 buyReflectionFee = 1200;
    uint256 buyMarketingFee = 200;
    uint256 buyTotalFee = 1400;

    uint256 sellLiquidityFee = 400;
    uint256 sellBuybackFee = 0;
    uint256 sellReflectionFee = 600;
    uint256 sellMarketingFee = 400;
    uint256 sellTotalFee = 1400;

    uint256 feeDenominator = 10000;

    uint256  _liquidityTokensToSwap;
    uint256  _buybackTokensToSwap;
    uint256  _reflectionTokensToSwap;
    uint256  _marketingTokensToSwap;

    address public autoLiquidityReceiver = msg.sender;
    address public marketingFeeReceiver = 0x3C0870fdF97B123E811964Dee870752d902Ede48;
    address public buybackReceiver = msg.sender;

    IDEXRouter public router;
    address public pair;

    bool public autoBuybackEnabled = false;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    DividendDistributor distributor;
    address public distributorAddress;

    bool public swapEnabled = true;
    uint256 private swapMinimumTokens = _totalSupply / 5000; // 0.0025%

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        address _router = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WETH = router.WETH();
        distributor = new DividendDistributor(_router, msg.sender);
        distributorAddress = address(distributor);

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = msg.sender;

        _setAutomatedMarketMakerPair(pair, true);

        approve(_router, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
         
        // Max  tx check
        address routerAddress = address(router);
        bool isSell = automatedMarketMakerPairs[recipient] || recipient == routerAddress;
        
        checkTxLimit(sender, recipient, amount);
        
        // Max wallet check excluding pair and router
        if (!isSell && !_isFree[recipient]){
            require((_balances[recipient] + amount) < _maxWallet, "Max wallet has been triggered");
        }
        
        // No swapping on buy and tx
        if (isSell && amount >= minAmountToTriggerSwap) {
            if(shouldSwapBack()){ swapBack(); }
            if(shouldAutoBuyback()){ triggerAutoBuyback(); }
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        return true;
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {

        if(isFeeOnTransferEnabled) {
            return !isFeeExempt[sender] && !isFeeExempt[recipient];
        } else {
            address routerAddress = address(router);
            bool isBuy = automatedMarketMakerPairs[sender] || sender == routerAddress;
            bool isSell =  automatedMarketMakerPairs[recipient]|| recipient == routerAddress;

            if(isBuy || isSell) {
                return !isFeeExempt[sender] && !isFeeExempt[recipient];
            } else {
                return false;
            }
        }

    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(selling){ return sellTotalFee; }
        return buyTotalFee;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        address routerAddress = address(router);
        bool isSell = automatedMarketMakerPairs[receiver] || receiver == routerAddress;

        uint256 totalFee = getTotalFee(isSell);
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);

        if(isSell) {
            _liquidityTokensToSwap += feeAmount * sellLiquidityFee / totalFee;
            _marketingTokensToSwap += feeAmount * sellMarketingFee / totalFee;
            _reflectionTokensToSwap += feeAmount * sellReflectionFee / totalFee;
            _buybackTokensToSwap += feeAmount * sellBuybackFee / totalFee;
        } else {
            _liquidityTokensToSwap += feeAmount * buyLiquidityFee / totalFee;
            _marketingTokensToSwap += feeAmount * buyMarketingFee / totalFee;
            _reflectionTokensToSwap += feeAmount * buyReflectionFee / totalFee;
            _buybackTokensToSwap += feeAmount * buyBuybackFee / totalFee;
        }

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return !automatedMarketMakerPairs[msg.sender]
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapMinimumTokens;
    }

    function setAutomatedMarketMakerPair(address _pair, bool value) public onlyOwner {
        _setAutomatedMarketMakerPair(_pair, value);
    }

    function _setAutomatedMarketMakerPair(address _pair, bool value) private {
        automatedMarketMakerPairs[_pair] = value;
        if(value){isDividendExempt[_pair] = true;}
        if(!value){isDividendExempt[_pair] = false;}
    }

    function swapBack() internal swapping {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _liquidityTokensToSwap.add(_buybackTokensToSwap).add(_marketingTokensToSwap).add(_reflectionTokensToSwap);
        
        uint256 tokensForLiquidity = _liquidityTokensToSwap.div(2);
        uint256 amountToSwap = contractBalance.sub(tokensForLiquidity);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 amountETHLiquidity = amountETH.mul(_liquidityTokensToSwap).div(totalTokensToSwap).div(2);
        uint256 amountETHReflection = amountETH.mul(_reflectionTokensToSwap).div(totalTokensToSwap);
        uint256 amountETHMarketing = amountETH.mul(_marketingTokensToSwap).div(totalTokensToSwap);
        
        _liquidityTokensToSwap = 0;
        _marketingTokensToSwap = 0;
        _buybackTokensToSwap = 0;
        _reflectionTokensToSwap = 0;

        try distributor.deposit{value: amountETHReflection}() {} catch {}
        payable(marketingFeeReceiver).transfer(amountETHMarketing);
            
        if(tokensForLiquidity > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                tokensForLiquidity,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, tokensForLiquidity);
        }
    }

    function shouldAutoBuyback() internal view returns (bool) {
        return !automatedMarketMakerPairs[msg.sender]
        && !inSwap
        && autoBuybackEnabled
        && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number // After N blocks from last buyback
        && address(this).balance >= autoBuybackAmount;
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, buybackReceiver);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }
    
    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function transferForeignToken(address _token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        _sent = IBEP20(_token).transfer(_to, _contractBalance);
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }
    
    function setMaxWallet(uint256 amount) external authorized {
        _maxWallet = amount;
    }

    function setTxLimit(uint256 amount) external authorized {
        _maxTxAmount = amount;
    }

    function setMinAmountToTriggerSwap(uint256 amount) external authorized {
        minAmountToTriggerSwap = amount;
    }

    function setIsFeeOnTransferEnabled(bool status) external authorized {
        isFeeOnTransferEnabled = status;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }
    
    function setFree(address holder) public onlyOwner {
        _isFree[holder] = true;
    }
    
    function unSetFree(address holder) public onlyOwner {
        _isFree[holder] = false;
    }
    
    function checkFree(address holder) public view onlyOwner returns(bool){
        return _isFree[holder];
    }

    function setFees(uint256 _buyLiquidityFee, uint256 _buyBuybackFee, uint256 _buyReflectionFee, uint256 _buyMarketingFee, uint256 _sellLiquidityFee, uint256 _sellBuybackFee, uint256 _sellReflectionFee, uint256 _sellMarketingFee, uint256 _feeDenominator) external authorized {
        buyLiquidityFee = _buyLiquidityFee;
        buyBuybackFee = _buyBuybackFee;
        buyReflectionFee = _buyReflectionFee;
        buyMarketingFee = _buyMarketingFee;
        buyTotalFee = _buyLiquidityFee.add(_buyBuybackFee).add(_buyReflectionFee).add(_buyMarketingFee);

        sellLiquidityFee = _sellLiquidityFee;
        sellBuybackFee = _sellBuybackFee;
        sellReflectionFee = _sellReflectionFee;
        sellMarketingFee = _sellMarketingFee;
        sellTotalFee = _sellLiquidityFee.add(_sellBuybackFee).add(_sellReflectionFee).add(_sellMarketingFee);

        feeDenominator = _feeDenominator;
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _buybackReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        buybackReceiver = _buybackReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapMinimumTokens = _amount;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
    
    function changeRouterVersion(address _router)
        external
        onlyOwner
        returns (address _pair)
    {
        IDEXRouter _uniswapV2Router = IDEXRouter(_router);

        _pair = IDEXFactory(_uniswapV2Router.factory()).getPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        if (_pair == address(0)) {
            // Pair doesn't exist
            _pair = IDEXFactory(_uniswapV2Router.factory()).createPair(
                address(this),
                _uniswapV2Router.WETH()
            );
        }
        pair = _pair;

        // Set the router of the contract variables
        router = _uniswapV2Router;
        _allowances[address(this)][address(router)] = _totalSupply;
    }


    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
}