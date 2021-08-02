/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;


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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

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
    function selectToken(address, address) external;
    function shares(address) external view returns (uint256, uint256, uint256);
    function getUnpaidEarnings(address) external view returns (uint256);
    function claimDividend(address) external;
    function getSelectedToken(address) external view returns (address, string memory);
}

contract babysquirrelcake is IBEP20, Auth {
    using SafeMath for uint256;


    address CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address LINK = 0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD;
    address XRP = 0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE;
    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address ADA = 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47;
    address ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address BTC = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address BAKE = 0xE02dF9e3e622DeBdD69fb838bB799E3F168902c5;
    address DOGE = 0xbA2aE424d960c26247Dd6c32edC70B295c744C43;
    address TRX = 0x85EAC5Ac2F758618dFa09bDbe0cf174e7d574D5B;
    address XTZ = 0x16939ef78684453bfDFb47825F8a5F714f12623a;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "babysquirrelcake";
    string constant _symbol = "BBSQUI";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = 0; 
    uint256 public _maxSellTxAmount = _totalSupply / 1000; // 0.1%
    uint256 public _maxWalletAmount = _totalSupply / 20; // 0.1%

    bool public transferDelayEnabled;
    bool public sellDelayEnabled;
    uint256 public transferDelay = 30 seconds;  // at launch, users may only buy every 30 seconds.
    uint256 public SellDelay = 5 minutes; // 5 minutes between sells
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => uint256) private _holderLastSellTimestamp;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isBlacklisted;

    uint256 liquidityFee = 4;
    uint256 buybackFee = 2;
    uint256 reflectionFee = 10;
    uint256 marketingFee = 2;
    uint256 totalFee = 18;
    uint256 feeDenominator = 100;
    uint256 antiSnipeBlock;
    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;
    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;
    uint256 public launchTimestamp;
    uint256 buybackMultiplierNumerator = 2;
    uint256 buybackMultiplierDenominator = 1;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    bool public autoBuybackEnabled = false;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    IDividendDistributor distributor;
    uint256 distributorGas = 800000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 20000; // 0.005%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (address _distributor, uint256 _antiSnipeBlock) Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        distributor = IDividendDistributor(_distributor);
	    antiSnipeBlock = _antiSnipeBlock;
        isFeeExempt[owner] = true;
        isTxLimitExempt[owner] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;

        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
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
        return approve(spender, uint256(-1));
    }

    function transferMultiple(address[] calldata recipients, uint256 amount) public returns (bool) {
       for (uint256 i = 0; i < recipients.length; i++) {
            require(_transferFrom(msg.sender,recipients[i], amount));
        }
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!isBlacklisted[sender]);
	    if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        if(recipient != pair && !isTxLimitExempt[sender] && !isTxLimitExempt[recipient])
            require(_balances[address(recipient)] + amount <= _maxWalletAmount, "Transfer amount exceeds the maxWalletAmount.");

       if(block.number > launchedAt + antiSnipeBlock && transferDelayEnabled){
            if (!isTxLimitExempt[sender] && recipient != pair && !isTxLimitExempt[recipient]){
                require(_holderLastTransferTimestamp[recipient].add(transferDelay) <= block.timestamp, "BABYJEJUDOGE: Transfer Delay enabled.  Please try again in 30 seconds.");
            }
        }

       if(block.number > launchedAt + antiSnipeBlock && sellDelayEnabled){
            if (!isTxLimitExempt[sender] && recipient == pair && !isTxLimitExempt[recipient]){     
                require(_holderLastSellTimestamp[sender].add(SellDelay) <= block.timestamp, "BABYJEJUDOGE: There must be at least 5 minutes gap between your last sell");
            }
        }       	    
	    
	   if(launched() && recipient != pair && !isTxLimitExempt[sender] && !isTxLimitExempt[recipient]){ _holderLastTransferTimestamp[recipient] = block.timestamp;
	    } else if(launched() && recipient == pair){
	    _holderLastSellTimestamp[sender] = block.timestamp;}

         
        checkTxLimit(sender, amount, recipient == pair);

        if(shouldSwapBack()){ swapBack(); }
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }

        if(!launched() && recipient == pair){ require(_balances[sender] > 0); launch(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount, bool selling) internal view {
        if(block.number > launchedAt + antiSnipeBlock && !selling ){require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");}
        if(block.number > launchedAt + antiSnipeBlock && selling ){require(amount <= _maxSellTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");}
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + antiSnipeBlock >= block.number){ return feeDenominator.sub((buybackMultiplierDenominator.div(_totalSupply)).div(_totalSupply)); }
        if(selling && block.timestamp <= launchTimestamp + 3 hours){ return 30; }
	    if(selling && buybackMultiplierTriggeredAt.add(buybackMultiplierLength) > block.timestamp){ return getMultipliedFee(); }
        return totalFee;
    }

    function getMultipliedFee() public view returns (uint256) {
        uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
        return totalFee.add(feeIncrease);
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
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

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");

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

    function setIsBlacklisted(address[] calldata accounts, bool flag) external authorized {
         for(uint256 i = 0; i < accounts.length; i++) {
            isBlacklisted[accounts[i]] = flag;
        }
    }

    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair
            && !inSwap
            && autoBuybackEnabled
            && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
            && address(this).balance >= autoBuybackAmount;
    }

    function BuyBack(uint256 amount, bool triggerBuybackMultiplier) external authorized {
        buyTokens(amount, DEAD);
        if(triggerBuybackMultiplier){
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }

    function SendToDivs(uint256 amount) external authorized {
        try distributor.deposit{value: amount}() {} catch {}
    }
    
    function clearBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = 0;
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }
    function accountbalance(address account) public view returns (uint256 BABYJEJUHeld,uint256,uint256 dividendsPaidinBNB) {
		return distributor.shares(account);
	}

    function unpaidDividends(address account) public view returns (uint256) {
	return distributor.getUnpaidEarnings(account);
	}

    function ConfigureDelaySettings(bool TDEnable, uint256 TDTime, bool SDEnable, uint256 SDTime) external authorized {
     transferDelayEnabled = TDEnable;
     transferDelay = TDTime;
     sellDelayEnabled = SDEnable;
     SellDelay = SDTime;
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount * (10**_decimals) ;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
        require(numerator / denominator <= 2 && numerator > denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
	launchTimestamp = block.timestamp;
        transferDelayEnabled = true;
        sellDelayEnabled = true;
        _maxTxAmount = _totalSupply / 1000; //0.1%
    }


    function setMaxBuyTxLimit(uint256 amount) external authorized {
        _maxTxAmount = amount * (10**_decimals) ;
    }


    function setMaxSellTxLimit(uint256 amount) external authorized {
        _maxSellTxAmount = amount * (10**_decimals) ;
    }

    function setMaxWalletLimit(uint256 amount) external authorized {
        _maxWalletAmount = amount * (10**_decimals) ;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
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


    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized{
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount * (10**_decimals);
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        distributorGas = gas;
    }

    function ManuallyTriggerSwap() external authorized {
        swapBack();
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

    function selectedToken(address account) public view returns (address, string memory) {
	return (distributor.getSelectedToken(account));
	}

    function ClaimAndProcessDivs() external {
	distributor.claimDividend(msg.sender);
	try distributor.process(distributorGas) {} catch {}
	}

    function ProcessDivs() external {
	try distributor.process(distributorGas) {} catch {}
	}

   function SelectCAKE() external {
	distributor.selectToken(msg.sender, CAKE);
	}

   function SelectLINK() external {
	distributor.selectToken(msg.sender, LINK);
	}

   function SelectXRP() external {
	distributor.selectToken(msg.sender, XRP);
	}

   function SelectBUSD() external {
	distributor.selectToken(msg.sender, BUSD);
	}

   function SelectADA() external {
	distributor.selectToken(msg.sender, ADA);
	}

   function SelectETH() external {
	distributor.selectToken(msg.sender, ETH);
	}

   function SelectDOGE() external {
	distributor.selectToken(msg.sender, DOGE);
	}
	
   function SelectBTC() external {
	distributor.selectToken(msg.sender, CAKE);
	}

   function SelectBAKE() external {
	distributor.selectToken(msg.sender, BAKE);
	}

   function SelectTRX() external {
	distributor.selectToken(msg.sender, TRX);
	}

   function SelectXTZ() external {
	distributor.selectToken(msg.sender, XTZ);
	}

   function SelectBNB() external {
	distributor.selectToken(msg.sender, WBNB);
	}	

    event AutoLiquify(uint256 amountBNB, uint256 amountBABYJEJU);
    event BuybackMultiplierActive(uint256 duration);
}