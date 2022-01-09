// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./Auth.sol";
import "./DividendDistributor.sol";

contract LiquidPrinter is Auth {

  using SafeMath for uint256;

  /** ======= EVENTS ======= */

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event AutoLiquify(uint256 _amountFTMLiquidity, uint256 _amountToLiquify);
  event BuybackMultiplierActive(uint256 _duration);

  /** ======= ERC20 PARAMS ======= */

  string constant _name =  "Liquid Printer";    
  string constant _symbol = "LQP";        
  uint8 constant _decimals = 6;

  uint256 _totalSupply = 1_000_000_000_000_000 * (10 ** _decimals);
  
  mapping (address => uint256) _balances;
  mapping (address => mapping (address => uint256)) _allowances;

  /** ======= GLOBAL PARAMS ======= */

  uint256 public constant MASK = type(uint128).max;

  address DEAD = 0x000000000000000000000000000000000000dEaD;
  address ZERO = address(0);

  address public EP = address(0); 
  address public WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
  
  IUniswapV2Router02 public router;
  address public routerAddress; 
  address public pair;

  DividendDistributor distributor;
  address public distributorAddress;

  uint256 distributorGas = 500000;

  // 23% Fee in total; 
  uint256 totalFee = 2300;
  uint256 feeDenominator = 10000;
  
  // 0% goes to providing liquidity to the pair; 
  uint256 liquidityFee = 0;
  // 14% Goes to the reflections for token holders; 
  uint256 reflectionFee = 1400;
  // 4% Goes to the marketing team;
  uint256 marketingFee = 400;
  // 5% Goes to the dev team; 
  uint256 tresuryFee = 500;

  uint256 buybackFee = 0;

  //liq address
  address public autoLiquidityReceiver= address(0); 

  // Address that gets the marketing fee's; 
  address public marketingFeeReceiver= address(0);

  // Dev address that recives the tresuryFees;
  address public developerFeeReciver = address(0); 


  uint256 targetLiquidity = 5;
  uint256 targetLiquidityDenominator = 100;

  uint256 public _maxTxAmount = _totalSupply.div(100); // 1%
  uint256 public _maxWallet = _totalSupply.div(40); // 2.5%

  mapping (address => bool) isFeeExempt;        
  mapping (address => bool) isTxLimitExempt;    
  mapping (address => bool) isDividendExempt;   
  mapping (address => bool) public isFree;     

  // BlockNumber of launch; 
  uint256 public launchedAt;
  // Timestamp of launch; 
  uint256 public launchedAtTimestamp;

  uint256 buybackMultiplierNumerator = 200;
  uint256 buybackMultiplierDenominator = 100;
  uint256 buybackMultiplierLength = 30 minutes;

  uint256 buybackMultiplierTriggeredAt;

  bool public autoBuybackEnabled = false;

  mapping (address => bool) buyBacker;

  uint256 autoBuybackCap;
  uint256 autoBuybackAccumulator;
  uint256 autoBuybackAmount;
  uint256 autoBuybackBlockPeriod;
  uint256 autoBuybackBlockLast;

  bool public swapEnabled = true;
  uint256 public swapThreshold = _totalSupply / 1000; // 0.1%;

  bool inSwap;

  /** ======= CONSTRUCTOR ======= */

  constructor (
    address _router,
    address _marketer,
    address _ep
  ) {
    EP = _ep;

    autoLiquidityReceiver= msg.sender; 
    marketingFeeReceiver= _marketer;
    developerFeeReciver = msg.sender; 

    routerAddress = _router;
    // Initialize the router; 
    router = IUniswapV2Router02(_router);

    // Make a pair for WFTM/GSCRAB; 
    pair = IUniswapV2Factory(router.factory()).createPair(WFTM, address(this));

    _allowances[address(this)][address(_router)] = type(uint256).max;

    // Create a new Divdistributor contract; 
    distributor = new DividendDistributor(_router);

    // Set the address; 
    distributorAddress = address(distributor);

    isFeeExempt[msg.sender] = true;
    isTxLimitExempt[msg.sender] = true;
    isDividendExempt[pair] = true;
    isDividendExempt[address(this)] = true;
    isDividendExempt[DEAD] = true;
    buyBacker[msg.sender] = true;

    autoLiquidityReceiver = msg.sender;

    // Approve the router with totalSupply; 
    approve(_router, type(uint256).max);

    // Approve the pair with totalSupply; 
    approve(address(pair), type(uint256).max);
    
    // Send totalSupply to msg.sender; 
    _balances[msg.sender] = _totalSupply;

    // Emit transfer event; 
    emit Transfer(address(0), msg.sender, _totalSupply);

  }

  /** ======= PUBLIC VIEW FUNCTIONS ======= */

  function getTotalFee() public view returns (uint256) {
    return totalFee;
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


  /** ======= ERC20 FUNCTIONS ======= */

  function totalSupply() external view returns (uint256) { 
    return _totalSupply; 
  }

  function decimals() external pure returns (uint8) { 
    return _decimals; 
  }

  function symbol() external pure returns (string memory) { 
    return _symbol; 
  }

  function name() external pure  returns (string memory) { 
    return _name; 
  }

  function balanceOf(address account) public view returns (uint256) { 
    return _balances[account]; 
  }

  function allowance(address holder, address spender) public view returns (uint256) { 
    return _allowances[holder][spender]; 
  }

  function approve(address spender, uint256 amount) public returns (bool) {
    _allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function approveMax(address spender) external returns (bool) {
      return approve(spender, _totalSupply);
  }

  function transfer(address recipient, uint256 amount) external returns (bool) {
    return _transferFrom(msg.sender, recipient, amount);
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    if(_allowances[sender][msg.sender] != _totalSupply){
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
    }
    return _transferFrom(sender, recipient, amount);
  }


  function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
    // If in swap just do a basic transfer. Same as normal ERC20 transferFrom function;
    if(inSwap) { 
        return _basicTransfer(sender, recipient, amount); 
    }
      
    bool isSell = recipient == pair || recipient == routerAddress;
    
    checkTxLimit(sender, amount);
    
    // Max wallet check excluding pair and router
    if (!isSell && !isFree[recipient]){
        require((_balances[recipient] + amount) < _maxWallet, "Max wallet has been triggered");
    }
    
    // No swapping on buy and tx
    if (isSell) {
        if(shouldSwapBack()){ 
            swapBack(); 
        }
        if(shouldAutoBuyback()){ 
            triggerAutoBuyback(); 
        }
    }
    

    _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

    uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;

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
    return true;
  }

  /** ======= INTERNAL VIEW FUNCTIONS ======= */

 
  function checkTxLimit(address _sender, uint256 _amount) internal view {
    require(_amount <= _maxTxAmount || isTxLimitExempt[_sender], "TX Limit Exceeded");
  }

  function shouldTakeFee(address _sender) internal view returns (bool) {
    return !isFeeExempt[_sender];
  }

  function shouldSwapBack() internal view returns (bool) {
    return 
      msg.sender != pair
        && 
      !inSwap
        && 
      swapEnabled
        && 
      _balances[address(this)] >= swapThreshold;
  }

  function shouldAutoBuyback() internal view returns (bool) {
    return 
      msg.sender != pair
        && 
      !inSwap
        && 
      autoBuybackEnabled
        && 
      autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number // After N blocks from last buyback
        && 
      address(this).balance >= autoBuybackAmount;
  }

  function launched() internal view returns (bool) {
    return launchedAt != 0;
  }

  /** ======= INTERNAL FUNCTIONS ======= */

  function takeFee(address _sender, uint256 _amount) internal returns (uint256) {
    // Calculate the fee amount; 
    uint256 feeAmount = _amount.mul(totalFee).div(feeDenominator);

    // Add the fee to the contract balance; 
    _balances[address(this)] = _balances[address(this)].add(feeAmount);

    emit Transfer(_sender, address(this), feeAmount);

    return _amount.sub(feeAmount);
  }

  function triggerAutoBuyback() internal {
    // Buy tokens and send them to burn address; 
    buyTokens(autoBuybackAmount, DEAD);
    // Update params: 
    autoBuybackBlockLast = block.number;
    autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
    // Set autoBuybackEnabled if needed;
    if(autoBuybackAccumulator > autoBuybackCap){ 
      autoBuybackEnabled = false; 
    }
  }

  function swapBack() internal swapping {

    uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;

    uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);

    uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

    uint256 balanceBefore = address(this).balance;

    address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = WFTM;

    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        amountToSwap,
        0,
        path,
        address(this),
        block.timestamp
    );
    uint256 amountFTM = address(this).balance.sub(balanceBefore);

    uint256 totalFTMFee = totalFee.sub(dynamicLiquidityFee.div(2));

    uint256 amountFTMLiquidity = amountFTM.mul(dynamicLiquidityFee).div(totalFTMFee).div(2);

    // Calculate the amount used for reflection fee's; 
    uint256 amountFTMReflection = amountFTM.mul(reflectionFee).div(totalFTMFee);
    // Calculate the amount used for marketing fee's: 
    uint256 amountFTMMarketing = amountFTM.mul(marketingFee).div(totalFTMFee);
    // Calculate the amount used for dev fee's: 
    uint256 amountFTMDev = amountFTM.mul(tresuryFee).div(totalFTMFee);

    // Send the dividend fee's to the distributor; 
    distributor.deposit{value: amountFTMReflection}();

    // Send the marketing fee's; 
    payable(marketingFeeReceiver).transfer(amountFTMMarketing);
    // Send the dev fee's; 
    payable(developerFeeReciver).transfer(amountFTMDev);
    
    // Handle the liquidity adding; 
    if(amountToLiquify > 0){
        router.addLiquidityETH{value: amountFTMLiquidity}(
            address(this),
            amountToLiquify,
            0,
            0,
            autoLiquidityReceiver,
            block.timestamp
        );
        emit AutoLiquify(amountFTMLiquidity, amountToLiquify);
    }
  }

  function buyTokens(uint256 _amount, address _to) internal swapping {
    address[] memory path = new address[](2);
    path[0] = WFTM;
    path[1] = address(this);

    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amount}(
        0,
        path,
        _to,
        block.timestamp
    );
  }

  

  /** ======= AUTHORIZED ONLY FUNCTIONS ======= */

  function clearBuybackMultiplier() external authorized {
    buybackMultiplierTriggeredAt = 0;
  }

  function launch() public authorized {
    require(launchedAt == 0, "Already launched");
    launchedAt = block.number;
    launchedAtTimestamp = block.timestamp;
  }
  
  function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
    autoBuybackEnabled = _enabled;
    autoBuybackCap = _cap;
    autoBuybackAccumulator = 0;
    autoBuybackAmount = _amount;
    autoBuybackBlockPeriod = _period;
    autoBuybackBlockLast = block.number;
  }

  function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
    require(numerator / denominator <= 2 && numerator > denominator);
    buybackMultiplierNumerator = numerator;
    buybackMultiplierDenominator = denominator;
    buybackMultiplierLength = length;
  }

  function setMaxWallet(uint256 amount) external authorized {
    require(amount >= _totalSupply / 1000);
    _maxWallet = amount;
  }

  function setTxLimit(uint256 amount) external authorized {
      require(amount >= _totalSupply / 1000);
      _maxTxAmount = amount;
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
  
  function setFees(
    uint256 _liquidityFee, 
    uint256 _buybackFee, 
    uint256 _reflectionFee, 
    uint256 _marketingFee, 
    uint256 _feeDenominator
  ) external authorized {
    liquidityFee = _liquidityFee;
    buybackFee = _buybackFee;
    reflectionFee = _reflectionFee;
    marketingFee = _marketingFee;
    totalFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_marketingFee);
    feeDenominator = _feeDenominator;
    require(totalFee < feeDenominator/4);
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

  /** ======= OWNER ONLY FUNCTION ======= */

  function Collect() external onlyOwner {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
  }

  function setFree(address holder) public onlyOwner {
    isFree[holder] = true;
  }
  
  function unSetFree(address holder) public onlyOwner {
    isFree[holder] = false;
  }
  
  function checkFree(address holder) public view onlyOwner returns(bool){
    return isFree[holder];
  }

  /** ======= MODIFIERS ======= */

  modifier swapping() { 
    inSwap = true; 
    _; 
    inSwap = false; 
  }

  modifier onlyBuybacker() { 
    require(buyBacker[msg.sender] == true, "");
    _; 
  }

  // Make contract able to recive FTM; 
  receive() external payable {}
  
}