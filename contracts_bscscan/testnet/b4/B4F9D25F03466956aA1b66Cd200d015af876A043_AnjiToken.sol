/**
 *Submitted for verification at BscScan.com on 2021-10-19
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

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;
    
    mapping (address => uint256) public externalBNBs;

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

    constructor (address _router, address _charityReceiver) {
        router = IDEXRouter(_router);
        _token = msg.sender;
        charityReceiver = _charityReceiver;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        } else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit(uint256 amount) external override onlyToken {
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }
    
    function deposited() external onlyToken {
        uint256 balanceBefore = address(this).balance;
        uint256 balance = IBEP20(_token).balanceOf(address(this));
        if (balance >= minSwapBalance) {
            IBEP20(_token).approve(address(router), balance);

            address[] memory path = new address[](2);
            path[0] = _token;
            path[1] = WBNB;
            
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                balance,
                0,
                path,
                address(this),
                block.timestamp
            );
            
            uint256 amount = address(this).balance - balanceBefore;
            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        }
    }


    function distributeDividend(address shareholder, address receiver) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        require(amount > minAmount, "Reward amount has to be more than minimum amount");
        
        payable(receiver).call{value: amount, gas: 30000}("");
        shareholderClaims[shareholder] = block.timestamp;
        shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    
    function claimDividend(address shareholder) external override onlyToken {
        distributeDividend(shareholder, shareholder);
    }
    
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded).add(externalBNBs[shareholder]);
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
    
    function setCharityFeeReceiver(address _receiver) external onlyToken {
        charityReceiver = _receiver;
    }
    
    
    function donate(address shareholder) onlyToken external {
        distributeDividend(shareholder, charityReceiver);
    }
    
    function buyToken(address shareholder) external onlyToken {
        if(shares[shareholder].amount == 0){ return; }
        
        uint256 amount = getUnpaidEarnings(shareholder);
        uint256 amountToCharity = amount.mul(2).div(100);
        uint256 amountToLiquify = amount.mul(3).div(100).div(2);
        uint256 amountToSend = amount.mul(95).div(100);
        
        payable(charityReceiver).call{value: amountToCharity, gas: 30000}("");
        payable(shareholder).call{value: amountToSend, gas: 30000}("");
    

        if (amountToLiquify > 0){
            uint256 balanceBefore = IBEP20(_token).balanceOf(address(this));
            
            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = _token;
            
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountToLiquify}(
                0,
                path,
                address(this),
                block.timestamp
            );
            
            uint256 amountToAdd = IBEP20(_token).balanceOf(address(this)) - balanceBefore;
        
            IBEP20(_token).approve(address(router), amountToAdd);
            router.addLiquidityETH{ value: amountToLiquify }(
                _token,
                amountToAdd,
                0,
                0,
                charityReceiver,
                block.timestamp
            );
        }
    }
    
    function depositExternalBNB(address shareholder) external payable {
        externalBNBs[shareholder] = msg.value;
    }
    
    receive() external payable { }
}

contract StaticDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor () {
        _token = msg.sender;
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit(uint256 amount) external onlyToken {
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
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
}

contract AnjiToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    //address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    //address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    address BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
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
    mapping (address => bool) isBlacklisted;

    uint256 liquidityFee = 300;
    uint256 charityFee = 200;
    uint256 marketingFee = 200;
    uint256 bnbReflectionFee = 200;
    uint256 staticReflectionFee = 100;
    
    uint256 feeDenominator = 10000;

    address public charityFeeReceiver;
    address public marketingFeeReceiver;
    address public autoLiquidityReceiver;

    IDEXRouter public router;
    address pancakeV2BNBPair;
    address[] public pairs;

    bool public liquidityEnabled = true;
    bool public swapEnabled = false;

    bool public feesOnNormalTransfers = false;
    
    mapping (address => bool) exists;
    address[] shareholders;

    BNBDistributor public bnbDistributor;
    StaticDistributor public staticDistributor;
    
    bool inSwap;
    modifier swapping { inSwap = true; _; inSwap = false; }
    uint256 public swapThreshold = 1000000 * 10 ** _decimals;
    
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
        bnbDistributor = new BNBDistributor(address(router), _owner);
        staticDistributor = new StaticDistributor();

        isFeeExempt[_owner] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(bnbDistributor)] = true;
        isFeeExempt[address(staticDistributor)] = true;
        isDividendExempt[pancakeV2BNBPair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[address(bnbDistributor)] = true;
        isDividendExempt[address(staticDistributor)] = true;
        isDividendExempt[_owner] = true;

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
    function balanceOf(address account) public view override returns (uint256) { return _balances[account].add(staticDistributor.getUnpaidEarnings(account)); }
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
        require(!isBlacklisted[sender], "Address is blacklisted");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(recipient == pancakeV2BNBPair){ require(_balances[sender] > 0); }
        
        if(shouldSwapBack()) { swapBack(); } 
        
        require(balanceOf(sender).sub(amount) > 0, "Insufficient Balance");
        _balances[sender] = _balances[sender].sub(amount);
        
        if (!exists[sender]) {
            exists[sender] = true;
            shareholders.push(sender);
        }
        if (!exists[recipient]) {
            exists[recipient] = true;
            shareholders.push(recipient);
        }
        
        if (shouldTakeFee(sender, recipient)) {
            uint256 _marketingFee = amount.mul(marketingFee).div(feeDenominator);
            uint256 _charityFee = amount.mul(charityFee).div(feeDenominator);
            uint256 _staticFee = amount.mul(staticReflectionFee).div(feeDenominator);
            uint256 _bnbFee = amount.mul(bnbReflectionFee).div(feeDenominator);
            uint256 _liquidityFee = amount.mul(liquidityFee).div(feeDenominator);
            
            _balances[marketingFeeReceiver] = _balances[marketingFeeReceiver] + _marketingFee;
            // emit Transfer(sender, marketingFeeReceiver, _marketingFee);
            
            _balances[charityFeeReceiver] = _balances[charityFeeReceiver] + _charityFee;
            // emit Transfer(sender, charityFeeReceiver, _charityFee);
            
            _balances[address(this)] = _balances[address(staticDistributor)] + _staticFee;
            // emit Transfer(sender, address(staticDistributor), _staticFee);
            
            _balances[address(bnbDistributor)] = _balances[address(bnbDistributor)] + _bnbFee;
            // emit Transfer(sender, address(bnbDistributor), _bnbFee);
            
            _balances[address(this)] = _balances[address(this)] + _liquidityFee;
            // emit Transfer(sender, address(this), _liquidityFee);
            
            uint256 amountReceived = amount - _marketingFee - _charityFee - _staticFee - _bnbFee - _liquidityFee;
            _balances[recipient] = _balances[recipient].add(amountReceived);
            emit Transfer(sender, recipient, amountReceived);
            
            if (!isDividendExempt[sender]) {
                try bnbDistributor.setShare(sender, balanceOf(sender)) {} catch {}
                try staticDistributor.setShare(sender, balanceOf(sender)) {} catch {}
            }
            if(!isDividendExempt[recipient]) {
                try bnbDistributor.setShare(recipient, balanceOf(recipient)) {} catch {}
                try staticDistributor.setShare(recipient, balanceOf(recipient)) {} catch {}
            }
            
            bnbDistributor.deposited();
            staticDistributor.deposit(_staticFee);
            
        } else {
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }


        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(balanceOf(sender).sub(amount) > 0, "Insufficient Balance");
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
        
        uint256 amount = _balances[address(this)];
        uint256 amountToLiquify = amount.div(2);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        
        _approve(address(this), address(router), amount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToLiquify,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNBLiquidity = address(this).balance.sub(balanceBefore);
        
        if (amountToLiquify > 0){
            router.addLiquidityETH{ value: amountBNBLiquidity }(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
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
        uint256 _bnbReflectionFee,
        uint256 _staticReflectionFee
    ) external onlyOwner {
        liquidityFee = _liquidityFee;
        charityFee = _charityFee;
        marketingFee = _marketingFee;
        bnbReflectionFee = _bnbReflectionFee;
        staticReflectionFee = _staticReflectionFee;
    }
    
    function setSwapThreshold(uint256 threshold) external onlyOwner {
        swapThreshold = threshold;
    }
    
    function setCharityFeeReceiver(address _receiver) external onlyOwner {
        charityFeeReceiver = _receiver;
        bnbDistributor.setCharityFeeReceiver(_receiver);
    }
    
    function setMarketingFeeReceiver(address _receiver) external onlyOwner {
        marketingFeeReceiver = _receiver;
    }


    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }
    
    function setLiqudityEnabled(bool _enabled) external onlyOwner {
        liquidityEnabled = _enabled;
    }


    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
    
    function getClaimableBNB() external view returns (uint256) {
        return bnbDistributor.getUnpaidEarnings(msg.sender);
    }

    function claim() external {
        bnbDistributor.claimDividend(msg.sender);
    }
    
    function donate() external {
        bnbDistributor.donate(msg.sender);
    }
    
    function depositExternalBNB() external payable {
        bnbDistributor.depositExternalBNB(msg.sender);
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
        
    function setIsBlacklisted(address adr, bool blacklisted) external onlyOwner {
        isBlacklisted[adr] = blacklisted;
    }
    
    receive() external payable { }
}