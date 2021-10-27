/**
 * Anji is about building an ecosystem of altruistic defi applications to enable a decentralised digital economy that leaves the earth in a better way than we found it.
 *
 * Web: https://anji.eco
 * Telegram: https://t.me/anjieco
 *
 *                 _ _   ______                        _
 *     /\         (_|_) |  ____|                      | |
 *    /  \   _ __  _ _  | |__   ___ ___  ___ _   _ ___| |_ ___ _ __ ___
 *   / /\ \ | '_ \| | | |  __| / __/ _ \/ __| | | / __| __/ _ \ '_ ` _ \
 *  / ____ \| | | | | | | |___| (_| (_) \__ \ |_| \__ \ ||  __/ | | | | |
 * /_/    \_\_| |_| |_| |______\___\___/|___/\__, |___/\__\___|_| |_| |_|
 *               _/ |                         __/ |
 *              |__/                         |___/
 */

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
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

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
    function deposit(uint256 amount) external;
    function claimDividend(address shareholder) external;
}

contract BNBDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;
    address charityReceiver;
    address marketingReceiver;
    address liquidityReceiver;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address WBNB;
    IDEXRouter router;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    
    uint256 public minAmount = 0;
    uint256 public minSwapBalance = 10000 * 10 ** 9;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _wbnb, address _router, address _charityReceiver, address _marketingReceiver, address _liquidityReceiver) {
        WBNB = _wbnb;
        router = IDEXRouter(_router);
        _token = msg.sender;
        charityReceiver = _charityReceiver;
        marketingReceiver = _marketingReceiver;
        liquidityReceiver = _liquidityReceiver;
    }
    
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        // User is selling bag
        if (amount < 1000000000) {
            uint256 unclaimed = getUnpaidEarnings(shareholder);
            if (unclaimed > 0) {
                distributeDividend(shareholder, marketingReceiver);
            }
            // If the amount is less than 1 user does not recieve share
            amount = 0;
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit(uint256 amount) external override onlyToken {
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder, address receiver) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        require(amount > minAmount, "Reward amount has to be more than minimum amount");
        
        payable(receiver).transfer(amount);
        shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    
    function claimDividend(address shareholder) external override onlyToken {
        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount == 0) {
            return;
        }

        distributeDividend(shareholder, shareholder);
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

    function setCharityFeeReceiver(address _receiver) external onlyToken {
        charityReceiver = _receiver;
    }

    function setMarketingFeeReceiver(address _receiver) external onlyToken {
        marketingReceiver = _receiver;
    }
    
    function setLiquidityFeeReceiver(address _receiver) external onlyToken {
        liquidityReceiver = _receiver;
    }

    function donate(address shareholder) onlyToken external {
        distributeDividend(shareholder, charityReceiver);
    }
    
    function buyToken(address shareholder) external onlyToken {
        if(shares[shareholder].amount == 0){ return; }
        
        uint256 amount = getUnpaidEarnings(shareholder);
        uint256 amountToCharity = amount.mul(2).div(100);
        uint256 amountToLiquify = amount.mul(3).div(100).div(2);
        uint256 walletAmount = amount.mul(95).div(100);

        uint256 amountToSwap = amountToLiquify.add(walletAmount);
        
        // Pay charity fee
        payable(charityReceiver).transfer(amountToCharity);

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = _token;

        uint256 balanceBefore = IBEP20(_token).balanceOf(address(this));

        IBEP20(_token).approve(address(router), amountToSwap);
        // Buy more tokens with the BNB of the shareholder and send to them
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountToSwap}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 swapBalance = IBEP20(_token).balanceOf(address(this)).sub(balanceBefore);
        uint256 amountTokensToLiquify = swapBalance.mul(3).div(98);
        uint256 amountTokensToShareholder = swapBalance.sub(amountTokensToLiquify);

        if (amountTokensToShareholder > 0) {
            IBEP20(_token).transfer(shareholder, amountTokensToShareholder);
        }

        if (amountTokensToLiquify > 0 && amountToLiquify > 0){
            IBEP20(_token).approve(address(router), amountTokensToLiquify);
            router.addLiquidityETH{ value: amountToLiquify }(
                _token,
                amountTokensToLiquify,
                0,
                0,
                liquidityReceiver,
                block.timestamp
            );
        }

        shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    
    function depositExternalBNB(uint256 amount) external onlyToken {
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }
    
    receive() external payable { }
}

contract AnjiToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    //address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Anji";
    string constant _symbol = "ANJI";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10 * 10 ** (9 + _decimals); // 10 Billion

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isRestricted;

    uint256 liquidityFee = 300;
    uint256 charityFee = 200;
    uint256 marketingFee = 200;
    uint256 bnbReflectionFee = 300;
    
    uint256 feeDenominator = 10000;

    address public charityFeeReceiver;
    address public marketingFeeReceiver;
    address public autoLiquidityReceiver;

    IDEXRouter public router;
    address pancakeV2BNBPair;
    address[] public pairs;

    bool public swapEnabled = false;
    bool public feesOnNormalTransfers = true;
    
    BNBDistributor public bnbDistributor;
    
    bool inSwap;
    modifier swapping { inSwap = true; _; inSwap = false; }
    uint256 public swapThreshold = 100 * 10 ** _decimals;

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
    event BoughtBack(uint256 amount, address to);
    event Launched(uint256 blockNumber, uint256 timestamp);
    event SwapBackSuccess(uint256 amount);
    event SwapBackFailed(string message);

    constructor() {
        address _owner = msg.sender;
        
        //0x10ED43C718714eb63d5aA57B78B54704E256024E
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pancakeV2BNBPair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);

        pairs.push(pancakeV2BNBPair);
        bnbDistributor = new BNBDistributor(WBNB, address(router), _owner, _owner, _owner);

        isFeeExempt[_owner] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(bnbDistributor)] = true;
        isDividendExempt[pancakeV2BNBPair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
        isDividendExempt[address(bnbDistributor)] = true;
        isDividendExempt[_owner] = true;

        // address upgradeContract = 0x5Ba41eAE2AE8a103B19ffE23384310B065bAF7f3;
        // isFeeExempt[upgradeContract] = true;
        // isDividendExempt[upgradeContract] = true;

        charityFeeReceiver = _owner;
        marketingFeeReceiver = _owner;
        autoLiquidityReceiver = _owner;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, ~uint256(0));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != ~uint256(0)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!isRestricted[recipient], "Address is restricted");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(shouldSwapBack()) { swapBack(); }

        require(_balances[sender].sub(amount) >= 0, "Insufficient Balance");
        _balances[sender] = _balances[sender].sub(amount);
        
        if (shouldTakeFee(sender, recipient)) {
            uint256 _marketingFee = amount.mul(marketingFee).div(feeDenominator);
            uint256 _charityFee = amount.mul(charityFee).div(feeDenominator);
            uint256 _bnbFee = amount.mul(bnbReflectionFee).div(feeDenominator);
            uint256 _liquidityFee = amount.mul(liquidityFee).div(feeDenominator);

            uint256 _totalFee = _marketingFee + _charityFee + _bnbFee + _liquidityFee; // Total token fee

            _balances[address(this)] = _balances[address(this)] + _totalFee; // New Balance

            uint256 amountReceived = amount - _totalFee;
            _balances[recipient] = _balances[recipient].add(amountReceived);
            emit Transfer(sender, recipient, amountReceived);
            
        } else {
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }

        if (!isDividendExempt[sender]) {
            try bnbDistributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try bnbDistributor.setShare(recipient, _balances[recipient]) {} catch {}
        }

        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(balanceOf(sender).sub(amount) >= 0, "Insufficient Balance");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient]) return false;

        address[] memory liqPairs = pairs;

        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] || recipient == liqPairs[i]) return true;
        }

        return feesOnNormalTransfers;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pancakeV2BNBPair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapAndLiquidify() public {
        swapBack();
    }
    
    function swapBack() internal swapping {
        uint256 balanceBefore = address(this).balance;
        
        uint256 totalAmount = _balances[address(this)];
        uint256 denom = liquidityFee + charityFee + marketingFee + bnbReflectionFee;

        uint256 marketingSwap = totalAmount.mul(marketingFee).div(denom);
        uint256 charitySwap = totalAmount.mul(charityFee).div(denom);
        uint256 bnbSwap = totalAmount.mul(bnbReflectionFee).div(denom);
        uint256 liquiditySwap = totalAmount.mul(liquidityFee).div(denom);

        uint256 amountToLiquify = liquiditySwap.div(2);

        uint256 amountToSwap = marketingSwap + charitySwap + bnbSwap + amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        
        _approve(address(this), address(router), amountToSwap);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 swapedBNBAmount = address(this).balance.sub(balanceBefore);

        if (swapedBNBAmount > 0) {
            uint256 bnbDenom = liquidityFee.div(2) + charityFee + marketingFee + bnbReflectionFee;
            uint256 bnbSwapMarketingAmount = swapedBNBAmount.mul(marketingFee).div(bnbDenom); // BNB for Marketing
            uint256 bnbSwapCharityAmount = swapedBNBAmount.mul(charityFee).div(bnbDenom); // BNB for Charity
            uint256 bnbSwapBnbAmount = swapedBNBAmount.mul(bnbReflectionFee).div(bnbDenom); // BNB for BNB Rewards
            uint256 bnbLiquidify = swapedBNBAmount.mul(liquidityFee.div(2)).div(bnbDenom); // BNB for Liqudity
        
            if (bnbSwapMarketingAmount > 0) {
                // Send BNB for Marketing
                payable(marketingFeeReceiver).transfer(bnbSwapMarketingAmount);
            }

            if (bnbSwapCharityAmount > 0) {
                // Send BNB for Charity
                payable(charityFeeReceiver).transfer(bnbSwapCharityAmount);
            }

            if (bnbSwapBnbAmount > 0) {
                // Send BNB for Rewards
                payable(bnbDistributor).transfer(bnbSwapBnbAmount);
                bnbDistributor.depositExternalBNB(bnbSwapBnbAmount);
            }
            
            if (bnbLiquidify > 0){
                _approve(address(this), address(router), amountToLiquify);
                router.addLiquidityETH{ value: bnbLiquidify }(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    autoLiquidityReceiver,
                    block.timestamp
                );
            }
        }
    }

    function BNBbalance() external view returns (uint256) {
        return address(this).balance;
    }


    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pancakeV2BNBPair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            bnbDistributor.setShare(holder, 0);
        } else{
            bnbDistributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _charityFee,
        uint256 _marketingFee,
        uint256 _bnbReflectionFee
    ) external onlyOwner {
        liquidityFee = _liquidityFee;
        charityFee = _charityFee;
        marketingFee = _marketingFee;
        bnbReflectionFee = _bnbReflectionFee;
    }

    function setSwapThreshold(uint256 threshold) external onlyOwner {
        swapThreshold = threshold;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }
    
    function setCharityFeeReceiver(address _receiver) external onlyOwner {
        charityFeeReceiver = _receiver;
        bnbDistributor.setCharityFeeReceiver(_receiver);

        isDividendExempt[_receiver] = true;
        isFeeExempt[_receiver] = true;
    }
    
    function setMarketingFeeReceiver(address _receiver) external onlyOwner {
        marketingFeeReceiver = _receiver;
        bnbDistributor.setMarketingFeeReceiver(_receiver);

        isDividendExempt[_receiver] = true;
        isFeeExempt[_receiver] = true;
    }

    function setLiquidityFeeReceiver(address _receiver) external onlyOwner {
        autoLiquidityReceiver = _receiver;
        bnbDistributor.setLiquidityFeeReceiver(_receiver);

        isDividendExempt[_receiver] = true;
        isFeeExempt[_receiver] = true;
    }


    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
    
    function getClaimableBNB() external view returns (uint256) {
        return bnbDistributor.getUnpaidEarnings(msg.sender);
    }
    
    function getWalletClaimableBNB(address _addr) external view returns (uint256) {
        return bnbDistributor.getUnpaidEarnings(_addr);
    }

    function claim() external {
        bnbDistributor.claimDividend(msg.sender);
    }
    
    function donate() external {
        bnbDistributor.donate(msg.sender);
    }
    
    function depositExternalBNB() external payable {
        payable(bnbDistributor).transfer(msg.value);
        bnbDistributor.depositExternalBNB(msg.value);
    }
    
    function buyAnjiWithReward() external {
        bnbDistributor.buyToken(msg.sender);
    }
    
    function addPair(address pair) external onlyOwner {
        pairs.push(pair);
    }
    
    function removeLastPair() external onlyOwner {
        pairs.pop();
    }
    
    function setFeesOnNormalTransfers(bool _enabled) external onlyOwner {
        feesOnNormalTransfers = _enabled;
    }
        
    function setisRestricted(address adr, bool restricted) external onlyOwner {
        isRestricted[adr] = restricted;
    }

    function walletIsDividendExempt(address adr) external view returns (bool) {
        return isDividendExempt[adr];
    }

    function walletIsTaxExempt(address adr) external view returns (bool) {
        return isFeeExempt[adr];
    }

    function walletisRestricted(address adr) external view returns (bool) {
        return isRestricted[adr];
    }

    // only for recovering excess BNB in the contract, in times of miscalculation. Can only be sent to marketing wallet - ALWAYS CONFIRM BEFORE USE
    function recoverExcess(uint256 amount) external onlyOwner {
        require(amount < address(this).balance, "ANJI: Can not send more than contract balance");
        payable(marketingFeeReceiver).transfer(amount);
    }

    // only for recovering tokens that are NOT ANJI tokens sent in error by wallets
    function withdrawTokens(address tokenaddr) external onlyOwner {
        require(tokenaddr != address(this), 'This is for tokens sent to the contract by mistake');
        uint256 tokenBal = IBEP20(tokenaddr).balanceOf(address(this));
        if (tokenBal > 0) {
            IBEP20(tokenaddr).transfer(marketingFeeReceiver, tokenBal);
        }
    }
    
    receive() external payable { }
}