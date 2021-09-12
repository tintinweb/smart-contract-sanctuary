/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

/**
 remove txlimit and max wallet to remove lp
 swapThreshold determines auto lp and conversion to dividend
 feeMultipliersDuration - 180 min
 anti bot - unable to buy at 2 block after launch
 to add LP exclude pcs router and lp pair for maxwallet
 to send token to other wallet exempt max wallet for new wallet to receive token if over limit. 
 to exempt from fee both sender and receiver must be exempted
 
 WIP
dividend is verified by deploying and verify the dividenddistributor.sol separately. bscscan will find a match auto. but need to test it works properly
add show maxwallet 

to set receiver wallet exempt then everyone also can exempt

buy reduction not working. it is increasing instead
sell reduces buy instead
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
    function createPair(address tokenA, address tokenB) external returns (address pair); // is this correct? pair or pcspair?
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

    IBEP20 BTCB = IBEP20(0x8BaBbB98678facC7342735486C851ABD7A0d17Ca);
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 15);

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
            ? IDEXRouter(_router)
            : IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
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
        uint256 balanceBefore = BTCB.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BTCB);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BTCB.balanceOf(address(this)).sub(balanceBefore);

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
            BTCB.transfer(shareholder, amount);
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

contract OLY11 is IBEP20, Auth {
    using SafeMath for uint256;

    address BTCB = 0x8BaBbB98678facC7342735486C851ABD7A0d17Ca;
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "OLY11";
    string constant _symbol = "OLY11";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 200; // 0.5%
    uint256 public maxWallet = _totalSupply / 50; // 2%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isMaxWalletExempt;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isWhitelistedForLimitedTrading;
    mapping (address => bool) isDividendExempt;
    mapping (address => uint256) public lastBuy; //greenwall2

    uint256 public liquidityFee = 200; //added public
    uint256 public buybackFee = 200;//added public
    uint256 public reflectionFee = 300;//added public
    uint256 public marketingFee = 300;//added public
    uint256 public totalBuyFee = 1000;
    uint256 public totalSellFee = 2200;
   // uint256 totalFee = 1400; 
    uint256 feeDenominator = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public PCSpair;
    address[] public pairs;

    uint256 public launchedAt;

   // uint256 buybackMultiplierNumerator = 200;
   // uint256 buybackMultiplierDenominator = 100;
   // uint256 buybackMultiplierTriggeredAt;
  //  uint256 buybackMultiplierLength = 30 minutes;
    
    uint256 public floppaNumerator = 150;
    uint256 public bingusNumerator = 50;
    uint256 public feeMultipliersDenominator = 100;
    uint256 public feeMultipliersTriggeredAt;
    uint256 public feeMultipliersDuration = 180 minutes;
    
  
    bool public greenwallEnabled = true; //greenwall
    uint256 public greenwallTriggeredAt = 0;//greenwall
    uint256 public greenwallNumerator = 975; //greenwall
    uint256 public greenwallDenominator = 1000; //greenwall
    uint256 public greenwallDuration = 10 minutes; //greenwall
    bool public tradingLimited = true;

   
    bool public autoBuybackEnabled = false;
    uint256 public autoBuybackCap; //added public
    uint256 public autoBuybackAccumulator;//added public
    uint256 public autoBuybackAmount;//added public
    uint256 public autoBuybackBlockPeriod;//added public
    uint256 public autoBuybackBlockLast;//added public

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 2000; // 0.05%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (
     // address _presaler,
    //  address _presaleContract
    ) Auth(msg.sender) {
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        PCSpair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);
        
        pairs.push(PCSpair);
        
        distributor = new DividendDistributor(address(router));
        
        address owner_ = msg.sender;
        
        isMaxWalletExempt[owner_] = true;
        isMaxWalletExempt[address(this)] = true;
        isFeeExempt[owner_] = true;
        isTxLimitExempt[owner_] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;
        isDividendExempt[address(this)] = true;
        isWhitelistedForLimitedTrading[owner_] = true;
        isWhitelistedForLimitedTrading[address(this)] = true;
        isDividendExempt[PCSpair] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;

        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);
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
        if (tradingLimited) {
            checkAllowedToTrade(sender, recipient);
        }
        if (!isSell(recipient)) {
            lastBuy[PCSpair] = block.timestamp; //last out from pcspair
        }

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender,recipient, amount); //add recipient
        checkMaxWallet(recipient, amount); //added for maxWallet
        
        if(shouldSwapBack()){ swapBack(); }
   //     if(shouldgreenwall(recipient)){triggergreenwall();} //greenwall
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }

      //  if(!launched() && recipient == PCSpair){ require(_balances[sender] > 0); launch(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        address _address = isSell(recipient) ? sender : recipient; //did this to try reduce shouldtakefee to 1 address
    
        uint256 amountReceived = shouldTakeFee(_address) ? takeFee(sender, recipient, amount) : amount; //changed to _address
        
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

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view { //added recipient
        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded"); //added txlimitexempt[recipient]
    }
    
    function checkMaxWallet(address recipient, uint256 amount) internal view { 
        require(balanceOf(recipient)+amount <= maxWallet || isMaxWalletExempt[recipient], "Max Wallet Exceeded 2%"); //added for maxWallet
    }

    function checkAllowedToTrade(address sender, address recipient) public view returns (bool){ //added returns (bool)
        require(isWhitelistedForLimitedTrading[sender] || isWhitelistedForLimitedTrading[recipient], "Not whitelisted while trading is limited.");
        return isWhitelistedForLimitedTrading[sender]; //added to return the address
    }

    function shouldTakeFee(address _address) public view returns (bool) { // original internal //added recipient
          return !isFeeExempt[_address];
       // return !isFeeExempt[sender]; // replaced with top line
    }
        
   // function getTotalFee(bool selling) public view returns (uint256) {
//        if(launchedAt + 1 >= block.number){ return feeDenominator.sub(1); }
 //       if(selling && buybackMultiplierTriggeredAt.add(buybackMultiplierLength) > block.timestamp){ return getMultipliedFee(); }
  //      return totalFee;
//    }
    
    function getTotalFee(bool selling) public view returns (uint256) {
        if (launchedAt + 2 >= block.number){ return feeDenominator.sub(1); }
        if (selling && feeMultipliersTriggeredAt.add(feeMultipliersDuration) > block.timestamp) {return getFloppaFee();}
        if (!selling && feeMultipliersTriggeredAt.add(feeMultipliersDuration) > block.timestamp) {return getBingusFee();}
        if (!selling && block.timestamp < greenwallTriggeredAt.add(greenwallDuration)) {return greenwallbuyFee();}  
      //  if (selling && feeMultipliersTriggeredAt.add(feeMultipliersDuration) > block.timestamp) { return getFloppaFee(); }
     //   if (!selling && feeMultipliersTriggeredAt.add(feeMultipliersDuration) > block.timestamp) { return getBingusFee(); }
      //  if (greenwallEnabled && !selling && feeMultipliersTriggeredAt.add(feeMultipliersDuration) < block.timestamp) { return getbuyfee();} // greenwall
     //   if (greenwallEnabled && selling && feeMultipliersTriggeredAt.add(feeMultipliersDuration) < block.timestamp) { return getsellfee();} // greenwall
        return selling ? totalSellFee : totalBuyFee;
    }
    
    function greenwallbuyFee() public view returns (uint256) {
        uint256 totalFee = totalBuyFee;
        uint256 remainingTime = greenwallTriggeredAt.add(greenwallDuration).sub(block.timestamp);
        uint256 feeDecrease = totalFee.sub(totalFee.mul(greenwallNumerator).div(greenwallDenominator));
        return totalFee.sub(feeDecrease.mul(remainingTime).div(greenwallDuration)); 
    }
/**
    //greenwall
    function getsellfee() public view returns (uint256) {
        uint256 totalFee = totalSellFee;
        uint256 remainingTime = buyMultipliersTriggeredAt.add(buyMultipliersDuration).sub(block.timestamp);
        uint256 feeIncrease = totalFee.mul(sellNumerator).div(buyMultipliersDenominator).sub(totalFee);
        return totalFee.add(sellNumerator.mul(remainingTime).div(buyMultipliersDuration)); // replace feeincrease with sellNumerator
    }
    */
    function getFloppaFee() public view returns (uint256) {
        uint256 totalFee = totalSellFee;
        uint256 remainingTime = feeMultipliersTriggeredAt.add(feeMultipliersDuration).sub(block.timestamp);
        uint256 feeIncrease = totalFee.mul(floppaNumerator).div(feeMultipliersDenominator).sub(totalFee);
     //   uint256 remainingTime2 = buyMultipliersTriggeredAt.add(buyMultipliersDuration).sub(block.timestamp);
        return totalFee.add(feeIncrease.mul(remainingTime).div(feeMultipliersDuration));
     //   totalFee.add(sellNumerator).mul(remainingTime2).div(buyMultipliersDuration);
         
   //     if(feeMultipliersTriggeredAt.add(feeMultipliersDuration) > block.timestamp) { 
    //    return totalFee.add(feeIncrease.mul(remainingTime).div(feeMultipliersDuration));}
    }

    function getBingusFee() public view returns (uint256) {
        uint256 totalFee = totalBuyFee;
        uint256 remainingTime = feeMultipliersTriggeredAt.add(feeMultipliersDuration).sub(block.timestamp);
        uint256 feeDecrease = totalFee.sub(totalFee.mul(bingusNumerator).div(feeMultipliersDenominator));
    //    uint256 remainingTime2 = buyMultipliersTriggeredAt.add(buyMultipliersDuration).sub(block.timestamp);
        return totalFee.sub(feeDecrease.mul(remainingTime).div(feeMultipliersDuration));
      //  totalFee.sub(buyNumerator).mul(remainingTime2).div(buyMultipliersDuration);
        
    //    if (feeMultipliersTriggeredAt.add(feeMultipliersDuration) > block.timestamp) {
    //    return totalFee.sub(feeDecrease.mul(remainingTime).div(feeMultipliersDuration)); }
    }
/**greenwall
    function isbuybackmuliplier () public view returns (bool) {
        return feeMultipliersTriggeredAt.add(feeMultipliersDuration) > block.timestamp; 
    }
   */
  //  function getMultipliedFee() public view returns (uint256) {
//        uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
 //       uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
  //      return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
//    }

  //  function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
//        uint256 feeAmount = amount.mul(getTotalFee(receiver == PCSpair)).div(feeDenominator);

 //       _balances[address(this)] = _balances[address(this)].add(feeAmount);
  //      emit Transfer(sender, address(this), feeAmount);

//        return amount.sub(feeAmount);
 //   }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(isSell(recipient) == false)   
        {return greenwallTriggeredAt = block.timestamp;} //greenwall2
        uint256 feeAmount = amount.mul(getTotalFee(isSell(recipient))).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function isSell(address recipient) internal view returns (bool) {
        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (recipient == liqPairs[i]) return true;
        }
        return false;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != PCSpair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalBuyFee).div(2);
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
        uint256 totalBNBFee = totalBuyFee.sub(dynamicLiquidityFee.div(2));
        
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

    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != PCSpair
            && !inSwap
            && autoBuybackEnabled
            && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
            && address(this).balance >= autoBuybackAmount;
    }
/**greenwall
    function shouldgreenwall(address recipient) internal view returns (bool) {
        return msg.sender != PCSpair
            && !inSwap
            && greenwallEnabled
            && !isSell(recipient);
    }
    
    function triggergreenwall() internal {
        buyMultipliersTriggeredAt = block.timestamp;
        emit BuyMultiplierActive(buyMultipliersDuration);
    }

*/
    function triggerZeusBuyback(uint256 amount, bool triggerBuybackMultiplier) external authorized {
        buyTokens(amount, DEAD);
        if(triggerBuybackMultiplier){
            feeMultipliersTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(feeMultipliersDuration);
        }
    }
    
    function clearBuybackMultiplier() external authorized {
        feeMultipliersTriggeredAt = 0;
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

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

   function setgreenwall(bool _greenwallenabled, uint256 _greenwallperiod, uint256 _greenwallnumerator, uint _greenwalldenominator) external authorized {
        greenwallEnabled = _greenwallenabled;
        greenwallDuration = _greenwallperiod;
        greenwallNumerator = _greenwallnumerator;
        greenwallDenominator = _greenwalldenominator;
    }
    
   function setMultiplierSettings(uint256 floppaNum, uint256 bingusNum, uint256 denominator, uint256 length) external authorized{
        require(floppaNum / denominator <= 2 && floppaNum >= denominator);
        require(bingusNum <= denominator);

        floppaNumerator = floppaNum;
        bingusNumerator = bingusNum;
        feeMultipliersDenominator = denominator;
        feeMultipliersDuration = length;
    }


   // function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
    //    require(numerator / denominator <= 2 && numerator > denominator);
    //    buybackMultiplierNumerator = numerator;
     //   buybackMultiplierDenominator = denominator;
    //    buybackMultiplierLength = length;
//    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() external authorized {
        launchedAt = block.number;
        tradingLimited = false;
        emit Launched(block.number, block.timestamp);
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 200);
        _maxTxAmount = amount;
    }

    function setMaxWallet(uint256 newmaxWallet) public authorized { 
        maxWallet = newmaxWallet;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != PCSpair);
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
        isTxLimitExempt[holder] = exempt; // true
    }
    
    function setIsMaxWalletExempt(address holder, bool exempt) external authorized {
        isMaxWalletExempt[holder] = exempt; // true
    }
    
    function setIsWhitelistedForLimitedTrading(address holder, bool whitelisted) external authorized{
        isWhitelistedForLimitedTrading[holder] = whitelisted; // true
    }

    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator, uint256 _totalSellFee) external authorized {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalBuyFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_marketingFee);
        totalSellFee = _totalSellFee;
        feeDenominator = _feeDenominator;
        require(totalBuyFee <= feeDenominator * 15 / 100, "Buy fee too high");
        require(totalSellFee <= feeDenominator * 30 / 100, "Sell fee too high");
        
        require(_liquidityFee <= feeDenominator * 10 / 100, "Liq fee too high");
        require(_buybackFee <= feeDenominator * 10 / 100, "Utility fee too high");
        require(_reflectionFee <= feeDenominator * 10 / 100, "Utility fee too high");
        require(_marketingFee <= feeDenominator * 10 / 100, "Utility fee too high");
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

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(PCSpair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
    
    //additional 
    function getisFeeExempt(address holder) public view returns (bool) {
        return isFeeExempt[holder];
    }
    function getIsDividendExempt(address holder) public view returns (bool) {
        return isDividendExempt[holder];
    }
    function getisTxLimitExempt(address holder) public view returns (bool) {
        return isTxLimitExempt[holder];
    }
    function getisMaxWalletExempt(address holder) public view returns (bool) {
        return isMaxWalletExempt[holder];
    }
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
    event BuyMultiplierActive(uint256 duration);
    event Launched(uint256 blockNumber, uint256 timestamp);
}