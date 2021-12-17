/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

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

/**
 * BEP20 standard interface.
 */
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

/**
 * Allows for contract ownership along with multi-address authorization
 */
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




contract YogiInu is IBEP20, Auth {
    using SafeMath for uint256;

    //address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd ;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address _marketingAdr = 0x362f08Fc2bde3328221AfaF642e78f6ED6A734CD;

    //address routerv2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address routerv2 = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    string constant _name = "test12";
    string constant _symbol = "test12";
    uint8 constant _decimals = 4;

    uint256 _totalSupply = 1 * 10**16 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply * 1 / 100;

    uint256 public _maxWalletToken = ( _totalSupply * 2 ) / 100;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isTimelockExempt;

    mapping (address => bool) WL;

    uint256 liquidityFee = 200;
    uint WLLiquidityFee = 1000;

    uint256 burnFee = 100;
    uint WLBurnFee = 1000;

    uint256 marketingFee = 200;
    uint256 WLMarketingFee = 1000;

    uint256 public totalFee = 500;
    uint256 public WLTotalFee = 3000;

    uint256 feeDenominator  = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint256 targetLiquidity = 50;
    uint256 targetLiquidityDenominator = 100;

    uint256 start = 1639690547;
    uint256 WLTime = 15 minutes;
    uint256 WLHighTaxTime = 30 minutes;

    IDEXRouter public router;
    address public pair;

    // Cooldown & timer functionality
    bool public buyCooldownEnabled = false;
    uint8 public cooldownTimerInterval = 10; //this is in seconds.
    mapping (address => uint) private cooldownTimer;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 10 / 1000000; // will start swapping once 0.01% of supply is in the swap wallet
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    bool maxTxActive = true;
    function setMaxTxActive(bool v) external {
        maxTxActive = v;
    }
    bool maxWalletActive = true;
    function setMaxWalletActive(bool v) external {
        maxWalletActive = v;
    }
    bool swapActive = true;
    function setSwapActive(bool v) external {
        swapActive = v;
    }

    event Log(string log, uint256 value);
    event LogAddress(string log, address adr);

    constructor () Auth(msg.sender) {
        router = IDEXRouter(routerv2);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        // No timelock for these people
        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;

        autoLiquidityReceiver = DEAD;
        marketingFeeReceiver = _marketingAdr;

        approve(routerv2, _totalSupply);
        approve(address(pair), _totalSupply);

        _balances[msg.sender] = _totalSupply * 95 / 100;
        emit Transfer(address(0), msg.sender, _totalSupply * 95 / 100);

        //dev
        _balances[0x362f08Fc2bde3328221AfaF642e78f6ED6A734CD] = _totalSupply * 5 / 100;
        emit Transfer(address(0), 0x362f08Fc2bde3328221AfaF642e78f6ED6A734CD, _totalSupply * 5 / 100);

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

    //settting the maximum permitted wallet holding (percent of total supply)
    function setMaxWalletPercent(uint256 maxWallPercent, uint denominator) external authorized() {
        _maxWalletToken = (_totalSupply * maxWallPercent ) / denominator;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        emit Log("heldTokens", balanceOf(recipient));
        emit Log("amount", amount);
        emit Log("maxwallet", _maxWalletToken);
        emit LogAddress("recipient", recipient);
        emit LogAddress("sender", sender);

        require((block.timestamp - start > WLTime) || WL[sender] || WL[recipient] || authorizations[sender] || authorizations[recipient]);

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        bool selling = recipient == pair;


        if (maxWalletActive) {
        // max wallet code
        if (!authorizations[sender] && !authorizations[recipient] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != marketingFeeReceiver && recipient != autoLiquidityReceiver){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
        }
        }

        // cooldown timer, so a bot doesnt do quick trades!
        if (sender == pair &&
        buyCooldownEnabled &&
            !isTimelockExempt[recipient]) {
            require(cooldownTimer[recipient] < block.timestamp,"Please wait for cooldown between buys!");
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }

        if (maxTxActive) {
        // Checks max transaction limit
        checkTxLimit(sender, recipient, amount);
        }

        if (swapActive) {
        // Liquidity, Maintained at 25%
        if(shouldSwapBack()){ swapBack(selling, sender); }
        }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount, selling) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || authorizations[sender] || authorizations[recipient], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender] && !authorizations[sender];
    }

    function takeFee(address sender, uint256 amount, bool selling) internal returns (uint256) {
        uint256 burnAmount = getBurnFeeAmount(selling, sender, amount);

        uint256 feeAmount = getTotalFeeAmount(selling, sender, amount);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        _totalSupply = _totalSupply.sub(burnAmount);
        emit Transfer(address(this), DEAD, burnAmount);

        return amount.sub(feeAmount);
    }

    function getBurnFeeAmount(bool selling, address sender, uint256 amount) internal view returns (uint256) {
        if (isWLHighTax(selling, sender)) {
            return amount.mul(WLBurnFee).div(feeDenominator);
        }
        return amount.mul(burnFee).div(feeDenominator);
    }

    function getMarketingFee(bool selling, address sender) internal view returns (uint256) {
        return isWLHighTax(selling, sender) ? marketingFee : WLMarketingFee;
    }

    function getTotalFee(bool selling, address sender) internal view returns (uint256) {
        return isWLHighTax(selling, sender) ? WLTotalFee : totalFee;
    }

    function getTotalFeeAmount(bool selling, address sender, uint256 amount) internal view returns (uint256) {
        return amount.mul(getTotalFee(selling, sender)).div(feeDenominator);
    }

    function isWLHighTax(bool selling, address sender) internal view returns (bool) {
        return selling && WL[sender] && block.timestamp - start <= WLHighTaxTime;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountBNB * amountPercentage / 100);
    }

    function cooldownEnabled(bool _status, uint8 _interval) public onlyOwner {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    function swapBack(bool selling, address sender) internal swapping {
        uint256 dynamicLiquidityFee = 0;
        if (!isOverLiquified(targetLiquidity, targetLiquidityDenominator)) {
            dynamicLiquidityFee = isWLHighTax(selling, sender) ? WLLiquidityFee : liquidityFee;
        }

        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(getTotalFee(selling, sender)).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = getTotalFee(selling, sender).sub(dynamicLiquidityFee.div(2));

        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBMarketing = amountBNB.mul(getMarketingFee(selling, sender)).div(totalBNBFee);

        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");

        // only to supress warning msg
        tmpSuccess = false;

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
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


    function setTxLimit(uint256 amount) external authorized {
        _maxTxAmount = amount;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsTimelockExempt(address holder, bool exempt) external authorized {
        isTimelockExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee,
        uint256 _burnFee,
        uint256 _marketingFee,
        uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        burnFee = _burnFee;
        totalFee = _liquidityFee.add(_burnFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
        require(totalFee / feeDenominator * 100 < 20); //max fees less than 20%
        }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }


    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function addToWL(address[] calldata list) external authorized {
        for (uint i = 0; i < list.length; i++) {
            WL[list[i]] = true;
        }
    }

    function checkWL(address adr) public view returns (bool){
        return WL[adr];
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}