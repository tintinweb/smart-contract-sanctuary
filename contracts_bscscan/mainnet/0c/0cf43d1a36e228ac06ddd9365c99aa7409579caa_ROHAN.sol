/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

/**
* Hold Popcorn, and you pay less fees.
* Get ISENGARD relfections for holding ANGRENOST.
* Get MITHRIL relfections for Holding ISENGARD.
* Burn Dolan trading ANGRENOST.
* It's a win, win, win.
* 
* ANGRENOST - TICKER: ROHAN
* Dolan Telegram - https://t.me/dolandukbsc
* Isnegard Telegram - https://t.me/ISENGARDBSC
* Mithril Telegram - https://t.me/bscmithriil
* PopCorn Tools Telegram - https://t.me/popcorntools
* Supply - 1,000,000
* Max Wallet - 10,000
* Max Buy - 10,000
* Max Sell - 5,000
*
     *  Variable Buy Fees:
        * If your wallet has a PopCorn balance, your fee is 5%
        * Otherwise 10% buy fee

     *  Variable Sell Fees:
        * If your wallet has a PopCorn balance, your fee is 2.5%
        * Otherwise 10% sell fee
     *
     *swapback() [Threshold = 1,000]
     * 
     *80% LP generated and burned
     *20% Dev, Burn and Relfections
       * BREAKDOWN:
        * 12.5% to dev
        * 43.75% Isengard Reflections
        * 43.75% to Burn Dolan
     *
     *burnDolan() [Threshold = 0.025 BNB]
     *
*
*/
pragma solidity ^0.8.11;
// SPDX-License-Identifier: MIT
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
interface PancakeSwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface PancakeSwapRouter {
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
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}
contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    address _token;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // MAINNET
    IBEP20 RewardToken = IBEP20(0x728711dB663Ec37340aaBcECFA7ef7Bf2F8116D2); // MAINNET - Isengard - https://bscscan.com/address/0x728711db663ec37340aabcecfa7ef7bf2f8116d2#code
    PancakeSwapRouter router;
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public minPeriod = 1 minutes;
    uint256 public minDistribution = 1 * (10 ** 1);
    uint256 currentIndex;
    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }
    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
    constructor (address _router) {
        router = _router != address(0)
            ? PancakeSwapRouter(_router)
            : PancakeSwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // MAINNET
        _token = msg.sender;
    }
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
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
        uint256 balanceBefore = RewardToken.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(RewardToken);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amount = RewardToken.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }
    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0) { return; }
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }
    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            RewardToken.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    function claimDividend() external {
        distributeDividend(msg.sender);
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
abstract contract Ownership {
    address internal owner;
    mapping(address => bool) internal authorizations;
    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "You're not an owner!");
        _;
    }
    modifier authorized() {
        require(isAuthorized(msg.sender), "You're not authorized");
        _;
    }
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }
   function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }
    event OwnershipTransferred(address owner);
}
abstract contract PopCornInterface {
    function balanceOf(address whom) view public virtual returns (uint);
}
contract ROHAN is IBEP20 {
    using SafeMath for uint256;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address devWallet = 0xaC5A11eA4f1e69209187dC9e623a8f5d77AcB43f;
    address dolanAddress = 0x066719da06d3927E9c7858f4002249A47A4C8b0C; // MAINNET - dolan - https://bscscan.com/address/0x066719da06d3927e9c7858f4002249a47a4c8b0c#code
    address popCornAddress = 0xf70a11EF1f69758E7D6ed64d22Be2Ae462F29EA1; // MAINNET - PopCorn Tools - https://bscscan.com/address/0xf70a11ef1f69758e7d6ed64d22be2ae462f29ea1#code
    address pancakeAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // MAINNET
    string constant _name = "ANGRENOST";
    string constant _symbol = "ROHAN";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 1000000 * 1**18 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply;
    uint256 public _maxWalletAmount = _totalSupply / 100;
    uint256 private _maxTxAmountBuy = _maxWalletAmount;
    uint256 private _maxTxAmountSell = _maxWalletAmount / 2;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    uint256 liquidityFee = 8;
    uint256 devBurnReflectionFee = 2;
    uint256 zeroFee = 0;
    DividendDistributor public dividendDistributor;
    uint256 distributorGas = 750000;
    address public owner;
    address public autoLiquidityReceiver;
    address public devFeeReceiver;
    PancakeSwapRouter public router;
    address public pair;
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000;
    uint256 public dolanThreshold = _totalSupply * 25 / 1000000000;
    bool public inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        router = PancakeSwapRouter(pancakeAddress);
        pair = PancakeSwapFactory(router.factory()).createPair(router.WETH(), address(this));
        dividendDistributor = new DividendDistributor(address(router));
        _allowances[address(this)][address(router)] = _totalSupply;
        owner = msg.sender;
        isFeeExempt[owner] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[pair] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[ZERO] = true;
        isTxLimitExempt[owner] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;
        isDividendExempt[owner] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
        autoLiquidityReceiver = DEAD;
        devFeeReceiver = devWallet;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    receive() external payable {}
    function name() external pure override returns (string memory) {return _name;}
    function symbol() external pure override returns (string memory) {return _symbol;}
    function decimals() external pure override returns (uint8) {return _decimals;}
    function totalSupply() external view override returns (uint256) {return _totalSupply;}
    function getOwner() external view override returns (address) {return owner;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}
    function popCornBalance(address _addressToQuery) view public returns (uint256) {
        return PopCornInterface(popCornAddress).balanceOf(_addressToQuery);
    }
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transferTo(msg.sender, recipient, amount);
    }
    function _basicTransfer(address sender, address recipient, uint256 amount) private returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }
    function _transferTo(address sender, address recipient, uint256 amount) private returns (bool) {
        if (inSwap) {return _basicTransfer(sender, recipient, amount);}
        checkTxLimitTo(recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = takeFeeTo(sender, recipient, amount);
        _balances[recipient] = _balances[recipient].add(amountReceived);
        if(!isDividendExempt[recipient]) {
            try dividendDistributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }
        try dividendDistributor.process(distributorGas) {} catch {}
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    function _transferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        if (inSwap) {return _basicTransfer(sender, recipient, amount);}
        checkTxLimitFrom(sender, recipient, amount);
        if(shouldSwapBack()){ swapBack(); }
        if(shouldBurnDolan()){ burnDolan(); }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = takeFeeFrom(sender, amount);
        _balances[recipient] = _balances[recipient].add(amountReceived);
        if(!isDividendExempt[sender]) {
            try dividendDistributor.setShare(sender, _balances[sender]) {} catch {}
        }
        try dividendDistributor.process(distributorGas) {} catch {}
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    function shouldSwapBack() private view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }
    function shouldBurnDolan() private view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && address(this).balance >= dolanThreshold;
    }
    function swapBack() private swapping() {
        uint256 tokensToLiquify = _balances[address(this)];
        uint256 amountToLiquify = tokensToLiquify.mul(8).div(10);
        uint256 amountToSwap = tokensToLiquify.sub(amountToLiquify);
        approve(address(this), amountToSwap);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountBNB = address(this).balance;
        uint256 amountBNBLiquidity = amountBNB.mul(8).div(10); // 80%
        // 20% REMAINING
        uint256 amountBNBdev = amountBNB.mul(5).div(10000); // 12.5%
        uint256 amountBNBReflection = amountBNB.mul(35).div(100).div(4); // 43.75%
        try dividendDistributor.deposit{value: amountBNBReflection}() {} catch {}
        (bool tmpSuccess,) = payable(devFeeReceiver).call{value : amountBNBdev, gas : 30000}("");
        tmpSuccess = false;
        if (amountToLiquify > 0) {
            router.addLiquidityETH{value : amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }
    function burnDolan() private swapping() {
        uint256 amountBNBdolan = address(this).balance.div(2);
        approve(address(this), amountBNBdolan);
        address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = dolanAddress;
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountBNBdolan}(
                0,
                path,
                DEAD,
                block.timestamp
            );
    }
    function checkTxLimitTo(address recipient, uint256 amount) private view {
        if (isTxLimitExempt[recipient]) {
            require(amount <= _maxTxAmount);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _totalSupply);
        } else if (!isTxLimitExempt[recipient]) {
            require(amount <= _maxTxAmountBuy);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _maxWalletAmount);
        }
    }
    function checkTxLimitFrom(address sender, address recipient, uint256 amount) private view {
        if (isTxLimitExempt[sender]) {
            require(amount <= _maxTxAmount);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _totalSupply);
        } else if (!isTxLimitExempt[sender] && isTxLimitExempt[recipient]) {
            require(amount <= _maxTxAmountSell);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _totalSupply);
        } else if (!isTxLimitExempt[sender]) {
            require(amount <= _maxTxAmountSell);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _maxWalletAmount);
        }
    }
    function takeFeeTo(address sender, address recipient, uint256 amount) private returns (uint256) {
        uint256 fivePercent = amount.mul(10).div(100).div(2);
        uint256 tenPercent = amount.mul(10).div(100);
        if (isFeeExempt[recipient]) {
            _balances[address(this)] = _balances[address(this)].add(zeroFee);
            emit Transfer(sender, address(this), zeroFee);
            return amount.sub(zeroFee);
        } else if (popCornBalance(recipient) > 0) {
            _balances[address(this)] = _balances[address(this)].add(fivePercent);
            emit Transfer(sender, address(this), fivePercent);
            return amount.sub(fivePercent);
        } else
            _balances[address(this)] = _balances[address(this)].add(tenPercent);
            emit Transfer(sender, address(this), tenPercent);
            return amount.sub(tenPercent);
    }
    function takeFeeFrom(address sender, uint256 amount) private returns (uint256) {
        uint256 twoPointFivePercent = amount.mul(10).div(100).div(4);
        uint256 tenPercent = amount.mul(10).div(100);
        if (isFeeExempt[sender]) {
            _balances[address(this)] = _balances[address(this)].add(zeroFee);
            emit Transfer(sender, address(this), zeroFee);
            return amount.sub(zeroFee);
        } else if (popCornBalance(sender) > 0) {
            _balances[address(this)] = _balances[address(this)].add(twoPointFivePercent);
            emit Transfer(sender, address(this), twoPointFivePercent);
            return amount.sub(twoPointFivePercent);
        } else
            _balances[address(this)] = _balances[address(this)].add(tenPercent);
            emit Transfer(sender, address(this), tenPercent);
            return amount.sub(tenPercent);
    }
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}