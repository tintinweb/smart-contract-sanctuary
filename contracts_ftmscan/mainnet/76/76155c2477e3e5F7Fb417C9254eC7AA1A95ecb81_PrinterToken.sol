// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";

import "./DividendDistributor.sol";

contract PrinterToken is Ownable {

  using SafeMath for uint256;

  /** ======= EVENTS ======= */

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event AutoSwapBack(uint256 indexed amountIn, uint256 indexed amountOut);
    event AutoLiquify(uint256 indexed amountWFTMLiquidity, uint256 indexed amountTokenToLiquify);
    
    event Initialized(address indexed initializer, uint256 indexed initalLiquidity, address indexed dividendDistributor);

  /** ======= GLOBAL PARAMS ======= */

    bool public isInitialized = false;

    // Paircontract deployed in contructor; 
    address public pair;

    // Global param to check if contract is swapping; 
    bool inSwap;

    address public dev; 
    address public marketing; 
    
    // Burn address to send tokens to; 
    address public BURN = 0x000000000000000000000000000000000000dEaD;
    address public WFTM;

    address public ROUTER;

    address public SCARAB;
    address public DISTRIBUTOR; 

    IERC20 internal wftm = IERC20(WFTM);
    IUniswapV2Router02 internal router; 
    DividendDistributor internal dividendDistributor;

    bool internal swapEnabled = true;

    uint256 internal swapThreshold;
    uint256 internal maxTxThreshold;
    uint256 internal maxWalletThreshold;
  
    uint256 internal targetLiquidity = 20;
    uint256 internal targetLiquidityDenominator = 100;

    uint256 internal feeDenominator = 10000;
    
    uint256 internal liquidityFee = 400;
    uint256 internal reflectionFee = 800;
    uint256 internal marketingFee = 150;
    uint256 internal devFee = 150;

    mapping (address => bool) internal isFeeExempt;     
    mapping (address => bool) internal isTxLimitExempt;   
    mapping (address => bool) internal isDividendExempt;   

  /** ======= ERC20 PARAMS ======= */

    string private _name;    
    string private _symbol;       
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

  /** ======= CONSTRUCTOR ======= */

    constructor(
      string memory name_, 
      string memory symbol_,
      uint8 decimals_,
      uint256 totalSupply_,
      address marketing_,
      address scarab_,
      address router_
    ) {
    
      SCARAB = scarab_;

      ROUTER = router_;
      router = IUniswapV2Router02(ROUTER); 

      WFTM = router.WETH();
      wftm = IERC20(WFTM);

      pair = IUniswapV2Factory(router.factory()).createPair(WFTM, address(this));

      isDividendExempt[pair] = true;

      dev = msg.sender;
      marketing = marketing_;
      
      _name = name_;
      _symbol = symbol_;
      _decimals = decimals_;
      _totalSupply = totalSupply_.mul(10 ** _decimals);

      swapThreshold = _totalSupply.div(1000);     // 0.1 %
      maxTxThreshold = _totalSupply.div(100);     // 1.0 %
      maxWalletThreshold = _totalSupply.div(40);  // 2.5 %

      isFeeExempt[msg.sender] = true; 
      isTxLimitExempt[msg.sender] = true;

      isDividendExempt[address(this)] = true;
      isDividendExempt[pair] = true;
      isDividendExempt[BURN] = true;

       _allowances[address(this)][address(router)] = type(uint256).max;

    }

  /** ======= INITIALIZER ======= */

    function initialize(address _dividendDistributor) external payable Swapping onlyOwner  {
      require(!isInitialized, 'Can only initialzed once');
      
      DISTRIBUTOR = _dividendDistributor; 
      dividendDistributor = DividendDistributor(payable(DISTRIBUTOR));

      require(dividendDistributor.isDividendDistributor() == true, 'isDividendDistributor');

      _balances[address(this)] = _totalSupply;
      emit Transfer(address(0), address(this), _totalSupply);

      _allowances[address(this)][address(router)] = type(uint256).max;

      (, , uint256 liquidity) = router.addLiquidityETH{value: msg.value}(
        address(this), 
        _totalSupply, 
        0, 
        0, 
        msg.sender, 
        block.timestamp
      );

      wftm.approve(DISTRIBUTOR, type(uint256).max);

      emit Initialized(msg.sender, liquidity, DISTRIBUTOR);
      isInitialized = true;
    }

  /** ======= OWNER ONLY FUNCTIONS ======= */

    function setFees(uint256 _devFee, uint256 _marketingFee, uint256 _reflectionFee, uint256 _liquidityFee) external onlyOwner {
        devFee = _devFee;
        marketingFee = _marketingFee;
        reflectionFee = _reflectionFee;
        liquidityFee = _liquidityFee;
    }

    function setMaxWallet(uint256 _amount) external onlyOwner {
      require(_amount >= _totalSupply / 1000);
      maxWalletThreshold = _amount;
    }

    function setTxLimit(uint256 _amount) external onlyOwner {
      require(_amount >= _totalSupply / 1000);
      maxTxThreshold = _amount;
    }

    function setFeeReceiver(address _marketingFeeReceiver) external onlyOwner {
        marketing = _marketingFeeReceiver;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
      swapEnabled = _enabled;
      swapThreshold = _amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
      require(holder != address(this) && holder != pair);
      isDividendExempt[holder] = exempt;
      if(exempt){
          dividendDistributor.setShare(holder, 0);
      }else{
          dividendDistributor.setShare(holder, _balances[holder]);
      }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
      isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
      isTxLimitExempt[holder] = exempt;
    }

  /** ======= PUBLIC VIEW FUNCTIONS ======= */

    function getTotalFee() public view returns (uint256) {
        return liquidityFee.add(reflectionFee).add(marketingFee).add(devFee);
    }

    function getSwapThreshold() public view returns (uint256) {
        return swapThreshold;
    }

    function getMaxTxThreshold() public view returns (uint256) {
      return maxTxThreshold; 
    }

    function getMaxWalletThreshold() public view returns (uint256) {
      return maxWalletThreshold; 
    }

    function getRouter() public view returns (address) {
      return address(router); 
    }

    function getDividendDistributor() public view returns (address) {
      return address(dividendDistributor);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(BURN));
    }

    function getLiquidityBacking(address _pair, uint256 _accuracy) public view returns (uint256) {
        return _accuracy.mul(balanceOf(_pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(address _pair, uint256 _targetLiquidity, uint256 _accuracy) public view returns (bool) {
        return getLiquidityBacking(_pair, _accuracy) > _targetLiquidity;
    }

    /** ======= ERC20 VIEW FUNCTIONS ======= */

    function name() public view returns (string memory) { 
      return _name; 
    }

    function symbol() public view returns (string memory) { 
      return _symbol; 
    }

    function decimals() public view returns (uint8) { 
      return _decimals; 
    }

    function totalSupply() public view returns (uint256) { 
      return _totalSupply; 
    }

    function balanceOf(address _account) public view returns (uint256) { 
      return _balances[_account]; 
    }

    function allowance(address _owner, address _spender) public view returns (uint256) { 
      return _allowances[_owner][_spender]; 
    }

  /** ======= ERC20 EXTERNAL FUNCTIONS ======= */

    function approve(address spender, uint256 amount) public returns (bool) {
      _allowances[msg.sender][spender] = amount;
      emit Approval(msg.sender, spender, amount);
      return true;
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

  /** ======= ERC20 INTERNAL FUNCTIONS ======= */

    function _transferFrom(address _sender, address _recipient, uint256 _amount) internal returns (bool) {
      
      if(inSwap) { 
          return _basicTransfer(_sender, _recipient, _amount); 
      } 
      require(isWithinTxLimits(_sender, _amount), 'Err - Max Tx limit triggerd');

      bool isSell = _recipient == pair || _recipient == address(router);
      if (!isSell){
        require((_balances[_recipient] + _amount) < maxWalletThreshold, "Err - Max Wallet limit been triggered");
      } 

      if (isSell) {
        if(shouldSwapBack()){ 
          handleSwapBack();
        }
      }
      
      _balances[_sender] = _balances[_sender].sub(_amount, "ERC20:  Insufficient Balance");

      uint256 amountAfterFee = handleTxFee(_sender, _amount);
      _balances[_recipient] = _balances[_recipient].add(amountAfterFee);

      if(!isDividendExempt[_sender]){ try dividendDistributor.setShare(_sender, _balances[_sender]) {} catch {} }
      if(!isDividendExempt[_recipient]){ try dividendDistributor.setShare(_recipient, _balances[_recipient]) {} catch {} }

      emit Transfer(_sender, _recipient, amountAfterFee);
      return true;    
    }

    function _basicTransfer(address _sender, address _recipient, uint256 _amount) internal returns (bool) {
      _balances[_sender] = _balances[_sender].sub(_amount, "Insufficient Balance");
      _balances[_recipient] = _balances[_recipient].add(_amount);
      return true;
    }

  /** ======= INTERNAL FUNCTIONS ======= */

    function handleTxFee(address _sender, uint256 _amount) internal returns (uint256) {
      uint256 amountAfterFee = _amount; 
      if(shouldTakeFee(_sender)) {
        amountAfterFee = TakeTxFee(_sender, _amount);
      }
      return amountAfterFee;
    }

    function handleShares(address _sender, address _recipient) internal {
      if(!isDividendExempt[_sender]){ 
        dividendDistributor.setShare(_sender, _balances[_sender]);
      }
      if(!isDividendExempt[_sender]){ 
        dividendDistributor.setShare(_recipient, _balances[_recipient]);
      }
    }

    function handleSwapBack() internal Swapping {

        (uint256 swapBackAmountIn, uint256 amountToLiquify, uint256 dynamicLiquidityFee) = getSwapBackAmountsIn();

        uint256 balanceBefore = address(this).balance;

        address[] memory path = new address[](2);
          path[0] = address(this);
          path[1] = WFTM;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapBackAmountIn,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountOut = address(this).balance.sub(balanceBefore);

        uint256 totalFTMFee = getTotalFee().sub(dynamicLiquidityFee.div(2));
        uint256 liquidityFTMFeeAmount = amountOut.mul(dynamicLiquidityFee).div(totalFTMFee).div(2);

        if(amountToLiquify > 0){
            handleAutoLiquidity(liquidityFTMFeeAmount, amountToLiquify);
        }

        handleDistribution(amountOut, dynamicLiquidityFee);

    }

    function handleAutoLiquidity(uint256 _amountFTMLiquidity, uint256 _amountToLiquify ) internal Swapping returns (uint256) {

      (, , uint256 liquidity) = router.addLiquidityETH{value: _amountFTMLiquidity}(
          address(this),
          _amountToLiquify,
          0,
          0,
          dev,
          block.timestamp
      );
      emit AutoLiquify(_amountFTMLiquidity, _amountToLiquify);
      return liquidity;
      
    }

    function handleDistribution(uint256 _totalFTMAmount, uint256 _dynamicLiquidityFee) internal {

        uint256 totalFTMFee = getTotalFee().sub(_dynamicLiquidityFee.div(2));
      
        uint256 reflectionFeeAmount = _totalFTMAmount.mul(reflectionFee).div(totalFTMFee);
        uint256 marketingFeeAmount = _totalFTMAmount.mul(marketingFee).div(totalFTMFee);
        uint256 devFeeAmount = _totalFTMAmount.mul(devFee).div(totalFTMFee);

        dividendDistributor.deposit{value: reflectionFeeAmount}();

        payable(marketing).transfer(marketingFeeAmount);
        payable(dev).transfer(devFeeAmount);

    }

    function TakeTxFee(address _sender, uint256 _amount) internal returns (uint256) {
      uint256 feeAmount = _amount.mul(getTotalFee()).div(feeDenominator);

      _balances[address(this)] = _balances[address(this)].add(feeAmount);

      emit Transfer(_sender, address(this), feeAmount);
      
      return _amount.sub(feeAmount);
    }

  /** ======= INTERNAL VIEW FUNCTIONS ======= */

    function shouldSwapBack() internal view returns (bool) {
      return 
        msg.sender != pair
          && 
        !inSwap
          && 
        swapEnabled
          && 
        balanceOf(address(this)) >= swapThreshold;
    }

    function getSwapBackAmountsIn() internal view returns(uint256, uint256, uint256) {
      uint256 dynamicLiquidityFee = isOverLiquified(pair, targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee; 
      uint256 amountToLiquify = dynamicLiquidityFee == 0 ? 0 :  swapThreshold.mul(dynamicLiquidityFee).div(getTotalFee()).div(2);
      uint256 swapBackAmountIn = swapThreshold.sub(amountToLiquify);      
      return (swapBackAmountIn, amountToLiquify, dynamicLiquidityFee);
    }

    function shouldTakeFee(address _sender) internal view returns (bool) {
      return !isFeeExempt[_sender];
    }

    function isWithinTxLimits(address _sender, uint256 _amount) internal view returns (bool) {
      if(isTxLimitExempt[_sender]) {
        return true;
      } else {
        return _amount <= maxTxThreshold;
      }
    }


  /** ======= MODIFIERS ======= */

    modifier Swapping() { 
      inSwap = true; 
      _; 
      inSwap = false; 
    }

    modifier onlyDistributor() {
        require(msg.sender == DISTRIBUTOR);
        _;
    }

    
    // Make contract able to recive FTM; 
    receive() external payable {}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUniswapV2Router01 {
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
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITresuary {
    function tbond() external view returns (address);
    function tomb() external view returns (address);
    function tombOracle() external view returns (address);
    function tshare() external view returns (address);

    function nextEpochPoint() external view returns (uint256);

    function tombPriceCeiling() external view returns (uint256);
    function tombPriceOne() external view returns (uint256);
    function maxDebtRatioPercent() external view returns (uint256);

    function buyBonds(uint256 _tombAmount, uint256 targetPrice) external;
    function redeemBonds(uint256 _bondAmount, uint256 targetPrice) external;
    
    function getBondDiscountRate() external view returns (uint256);
    function getBondPremiumRate() external view returns (uint256);

    function getTombPrice() external view returns (uint256);
    function getTombUpdatedPrice() external view returns (uint256);
    function getBurnableTombLeft() external view returns (uint256);
    function getRedeemableBonds() external view returns (uint256);
    function epochSupplyContractionLeft() external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRewardPool {
    function userInfo(uint256 poolId, address user) external view returns(uint256, uint256);
    
    function tshare() external pure returns (address);
    function poolEndTime() external pure returns (uint256);
    // View function to see pending tSHAREs on frontend.
    function pendingShare(uint256 _pid, address _user) external view returns (uint256);
    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) external view returns (uint256);
    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) external;
    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOracle {
    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IGscarabSwapper {
    function swapTBondToTShare(uint256 _tbondAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IRewardPool.sol";
import "./interfaces/ITresuary.sol";
import "./interfaces/IGscarabSwapper.sol";

contract Strategy is Ownable {

    using SafeMath for uint256;

  /** ======= GLOBAL PARAMS ======= */

    address public DISTRIBUTOR; 

    IERC20 public wftm; 
    IERC20 public sbond;
    IERC20 public scarab;
    IERC20 public gscarab;
    IERC20 public poolToken;

    IOracle public oracle;
    ITresuary public treasury;
    IRewardPool public gscarabRewardPool;
    IUniswapV2Router02 public router;

    IGscarabSwapper public gscarabSwapper; 

    uint256 public totalEarnings; 

    uint256 internal minScarabThreshold = 1e18; 
    uint256 internal minGscarabThreshold = 1e16;

    uint256 internal minBondThreshold = 1e18;

    uint256 internal bondsRedeemPercentage = 10;
    uint256 internal bondsRedeemNominator = 100;

    bool internal shouldHandleBonds = false;

  /** ======= CONSTRUCTOR ======= */

    constructor(
      address _router,
      address _treasury,
      address _rewardPool,
      address _poolToken,
      address _gscarabSwapper
    ) {
        wftm = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

        router = IUniswapV2Router02(_router);

        treasury = ITresuary(_treasury);
        sbond = IERC20(treasury.tbond());
        scarab = IERC20(treasury.tomb());
        gscarab = IERC20(treasury.tshare());
        oracle = IOracle(treasury.tombOracle());

        gscarabRewardPool = IRewardPool(_rewardPool);
        poolToken = IERC20(_poolToken);

        gscarabSwapper = IGscarabSwapper(_gscarabSwapper);

        sbond.approve(address(gscarabSwapper), type(uint256).max);
        wftm.approve(address(router), type(uint256).max);
        scarab.approve(address(router), type(uint256).max);
        gscarab.approve(address(router), type(uint256).max);
        poolToken.approve(address(router), type(uint256).max);
        poolToken.approve(address(gscarabRewardPool),type(uint256).max);
      
    }

  /** ======= PUBLIC VIEW FUNCTIONS ======= */

    function isStrategy() public pure returns(bool) {
        return true; 
    }    

  /** ======= EXTERNAL ONLY OWNER ======= */

    function setDistributor(address _distributor) external onlyOwner {
      DISTRIBUTOR = _distributor;
      scarab.approve(DISTRIBUTOR, type(uint256).max);
    }

    function setMinScarabThreshold(uint256 _newScarabThreshold) external onlyOwner{
      minScarabThreshold = _newScarabThreshold;
    }

    function setMinGscarabThreshold(uint256 _newGscarabThreshold) external onlyOwner{
      minGscarabThreshold = _newGscarabThreshold;
    }

    function setShouldHandleBonds(bool _newvalue) external onlyOwner{
      shouldHandleBonds = _newvalue;
    }

  /** ======= EXTERNAL ONLY DISTRIBUTOR ======= */

    function process() external payable onlyDistributor  {
        
        if(isAbovePeg()) {
        
          handleDepositRewardPool(msg.value);

          if(shouldRedeemBonds()) {
            uint256 balance = sbond.balanceOf(address(this)); 
            if(balance > minBondThreshold) {
              handleRedeemBonds(sbond.balanceOf(address(this)));
            } else {
              handleRedeemBonds(balance.div(bondsRedeemNominator).mul(bondsRedeemPercentage));
            }
          }

        } else {
          
          handleExitRewardPool();

          address[] memory path = new address[](2);
            path[0] = address(wftm);
            path[1] = address(scarab);

          uint256 amountOutSCARAB = handleFTMSwap(msg.value, path);
        
          if(shouldBuyBonds()) {
            handleBuyBonds(amountOutSCARAB);
          } 
        }
    }

    function exit() external onlyDistributor returns(uint256) {

      // Check bondBalance and send them to distributor;
      uint256 bondBalance = sbond.balanceOf(address(this)); 
      if(bondBalance > 0) {
        sbond.transfer(owner(), bondBalance);
      }

      uint256 ftmBalance = address(this).balance; 
      if(ftmBalance > 0) {
        address[] memory path = new address[](2);
            path[0] = address(wftm);
            path[1] = address(scarab);

        handleFTMSwap(ftmBalance, path);
      }

      // Exit pool position if we have any; 
      handleExitRewardPool();
      
      uint256 amountToSend = scarab.balanceOf(address(this)); 
      scarab.transfer(msg.sender, amountToSend);
      return amountToSend; 
    }

    function pullEarnings() external onlyDistributor returns(uint256) {
      if(shouldPullEarnings()) {
        uint256 balance = scarab.balanceOf(address(this)); 
        totalEarnings = totalEarnings.add(balance);
        scarab.transfer(msg.sender, balance);
        return balance; 
      } else {
        return 0;
      }
    }

    function forcePullEarnings() external onlyDistributor returns(uint256) {
      uint256 balance = scarab.balanceOf(address(this)); 
      totalEarnings = totalEarnings.add(balance);
      scarab.transfer(msg.sender, balance);
      return balance; 
    }

  /** ======= PUBLIC VIEW FUNCTIONS ======= */

    function shouldPullEarnings() public view returns(bool){
      return scarab.balanceOf(address(this)) > minScarabThreshold; 
    }

    function shouldRedeemBonds() public view returns(bool) {
      return 
        sbond.balanceOf(address(this)) > 0 
          && 
        getMaxRedeemableBonds() > 0
          &&
        shouldHandleBonds;
    }

    function shouldSwapBonds() public view returns(bool) {
      return 
        sbond.balanceOf(address(this)) > 0 ;
    }

    function shouldBuyBonds() public view returns(bool) {
      return 
        getMaxBurnableScarab() > 0
          &&
        shouldHandleBonds;
    }

    function getScarabPrice() public view returns(uint256) {
        return treasury.getTombPrice();
    }

    function getBondDiscountRate() public view returns(uint256) {
        return treasury.getBondDiscountRate();
    }

    function getBondPremiumRate() public view returns(uint256) {
        return treasury.getBondPremiumRate();
    }

    function getMaxRedeemableBonds() public view returns(uint256) {
        return treasury.getRedeemableBonds();
    }

    function getMaxBurnableScarab() public view returns(uint256) {
        return treasury.getBurnableTombLeft();
    }

    function getPendingGscarabRewards() public view returns(uint256) {
        (, uint256 pending) = gscarabRewardPool.userInfo(0, address(this));
        return pending;
    }

    function getGscarabRewardPoolBalance() public view returns(uint256) {
        (uint256 amount, ) = gscarabRewardPool.userInfo(0, address(this));
        return amount;
    }

    function isAbovePeg() public view returns(bool) {
        // First get the current twap; 
        uint256 scarabPrice = treasury.getTombPrice();
        uint256 priceCeiling = treasury.tombPriceCeiling();
        return scarabPrice > priceCeiling;
    }

    /** ======= INTERNAL FUNCTIONS ======= */

    function handleBuyBonds(uint256 _amountIn) internal {
       
        // Grab the targetPrice before buying; 
        uint256 price = treasury.getTombPrice();

        // Approve amountToBuy; 
        scarab.approve(address(treasury), _amountIn);

        // Buy BONDS with amountOut; 
        treasury.buyBonds(_amountIn, price);
    }

    function handleRedeemBonds(uint256 _amount) internal {
        uint256 price = treasury.getTombPrice();
        sbond.approve(address(treasury), _amount);
        treasury.redeemBonds(_amount, price);
    }

    function handleSwapBonds(uint256 _amount) internal {
      gscarabSwapper.swapTBondToTShare(_amount);
      uint256 gscarabBalance = gscarab.balanceOf(address(this));
        if(gscarabBalance > minGscarabThreshold) {
            address[] memory path = new address[](3);
              path[0] = address(gscarab);
              path[1] = address(wftm);
              path[2] = address(scarab);
            handleTokenSwap(gscarabBalance, path);
        }
    }

    function handleDepositRewardPool(uint256 _amount) internal returns(uint256) {

        address[] memory liquidityPath = new address[](2);
            liquidityPath[0] = address(wftm);
            liquidityPath[1] = address(scarab);
        uint256 amountOutSCARAB = handleFTMSwap(_amount.div(2), liquidityPath);
        
        (, , uint liquidity) = router.addLiquidityETH{value: _amount.div(2)}(
            address(scarab), 
            amountOutSCARAB,
            0, 
            0, 
            address(this), 
            block.timestamp
        );
    
        gscarabRewardPool.deposit(0, liquidity);

        uint256 gscarabBalance = gscarab.balanceOf(address(this));
        if(gscarabBalance > minGscarabThreshold) {
            address[] memory path = new address[](3);
              path[0] = address(gscarab);
              path[1] = address(wftm);
              path[2] = address(scarab);
            handleTokenSwap(gscarabBalance, path);
        }

        if(address(this).balance > 0) {
          handleFTMSwap(address(this).balance, liquidityPath);
        }
        return scarab.balanceOf(address(this));        
    }

    function handleExitRewardPool() internal returns (uint256) {
        uint256 lpBalanceInFarm = getGscarabRewardPoolBalance();
        if(lpBalanceInFarm > 0) {
            
            gscarabRewardPool.withdraw(0, lpBalanceInFarm);
           
            (uint256 amountOutWFTM, ) = router.removeLiquidity(
                address(wftm), 
                address(scarab), 
                poolToken.balanceOf(address(this)),
                0,
                0,
                address(this),
                block.timestamp
            );
            
            address[] memory path = new address[](2);
              path[0] = address(wftm);
              path[1] = address(scarab);

            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountOutWFTM,
                0,
                path,
                address(this),
                block.timestamp
            );
        } 

        uint256 gscarabBalance = gscarab.balanceOf(address(this));
        if(gscarabBalance > 0) {
            address[] memory path = new address[](3);
              path[0] = address(gscarab);
              path[1] = address(wftm);
              path[2] = address(scarab);
            handleTokenSwap(gscarabBalance, path);
        }

        return scarab.balanceOf(address(this));
    }

    function handleTokenSwap(uint256 _amountIn, address[] memory _path) internal returns (uint256) {
        uint256 balanceBefore = IERC20(_path[_path.length - 1]).balanceOf(address(this));

        IERC20(_path[0]).approve(address(router), _amountIn);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            0,
            _path,
            address(this),
            block.timestamp
        );

        return IERC20(_path[_path.length - 1]).balanceOf(address(this)).sub(balanceBefore);
    }

    function handleFTMSwap(uint256 _amountIn, address[] memory _path) internal returns (uint256) {
        uint256 balanceBefore = IERC20(_path[_path.length - 1]).balanceOf(address(this));

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amountIn}(
            0,
            _path,
            address(this),
            block.timestamp
          );

        return IERC20(_path[_path.length - 1]).balanceOf(address(this)).sub(balanceBefore);
    }



  /** ======= MODIFIERS ======= */

    /**
     *  Modifier to make shure the function is only called by the divToken; 
     */
    modifier onlyDistributor() {
        require(msg.sender == DISTRIBUTOR); _;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "./Strategy.sol";

contract DividendDistributor is Ownable {
    using SafeMath for uint256;

    /** ======= GLOBAL PARAMS ======= */

    IERC20 public wftm; 
    IERC20 public scarab;
    IERC20 public scarabp;

    Strategy public strategy;
    IUniswapV2Router02 public router;
    
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] internal shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 internal totalShares;
    uint256 internal totalDividends;
    uint256 internal totalDistributed;
    uint256 internal dividendsPerShare;
    uint256 internal dividendsPerShareAccuracyFactor = 10e36;

    uint256 internal lastDepositTimestamp; 
    uint256 internal currentIndex; 

    uint256 internal minDistribution = 1e18; 
    uint256 internal minPeriod = 1 minutes;

    uint256 internal strategyPercentage = 50;
    uint256 internal strategyNominator = 100;

    /** ======= CONSTRUCTOR ======= */

    constructor (
        address _router,
        address _scarab,
        address _scarabp
    ) {

        wftm = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

        router = IUniswapV2Router02(_router);
        scarab = IERC20(_scarab);
        scarabp = IERC20(_scarabp);

        strategy = Strategy(payable(address(0)));
       
        lastDepositTimestamp = block.timestamp;
    }

    /** ======= PUBLIC VIEW FUNCTIONS ======= */

    function isDividendDistributor() public pure returns(bool) {
        return true; 
    }

    function getUnpaidEarnings(address _shareholder) public view returns (uint256) {
        if(shares[_shareholder].amount == 0){ 
            return 0; 
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[_shareholder].amount);
        uint256 shareholderTotalExcluded = shares[_shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ 
            return 0; 
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    /** ======= EXTERNAL ONLY OWNER ======= */

    function setStrategy(address _strategy) external onlyOwner {
        if(address(strategy) != address(0)) {
            uint256 earnings = strategy.exit();
            totalDividends = totalDividends.add(earnings);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(earnings).div(totalShares));
        }
        strategy = Strategy(payable(_strategy));
        require(strategy.isStrategy(), 'Contract is not Strategy');
        scarab.approve(address(strategy), type(uint256).max);
    }

    function setMinDistribution(uint256 _newValue) external onlyOwner {
        minPeriod = _newValue;
    }

    function setMinPeriod(uint256 _newValue) external onlyOwner {
        minPeriod = _newValue;
    }

    function setStrategyPercentage(uint256 _strategyPercentage, uint256 _strategyNominator) external onlyOwner {
        strategyPercentage = _strategyPercentage;
        strategyNominator = _strategyNominator;
    }

    function forceExit() external onlyOwner {
        uint256 earnings = strategy.exit();
        totalDividends = totalDividends.add(earnings);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(earnings).div(totalShares));
    }

    function forcePull() external onlyOwner {
        uint256 earnings = strategy.forcePullEarnings();
        totalDividends = totalDividends.add(earnings);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(earnings).div(totalShares));
    }

    /** ======= EXTERNAL FUNCTIONS ======= */

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    /** ======= GLOBAL GETTERS ======= */

    function getTotalShares() public view returns (uint256) {
        return totalShares;
    }

    function getTotalDividends() public view returns (uint256) {
        return totalDividends;
    }

    function getTotalDistributed() public view returns (uint256) {
        return totalDistributed;
    }

    function getDividendsPerShare() public view returns (uint256) {
        return dividendsPerShare;
    }
    
    function getMinPeriod() public view returns (uint256) {
        return minPeriod;
    }

    function getStrategyPercentage() public view returns (uint256) {
        return strategyPercentage;
    }

    function getShareHolderShares(address _shareHolder) public view returns(Share memory){
        return shares[_shareHolder];
    }
    
    /** ======= SCARABp ONLY FUNCTIONS ======= */

    function setShare(address shareholder, uint256 amount) external onlyToken {
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

    function deposit() external payable onlyToken {
        if( (block.timestamp - lastDepositTimestamp) > minPeriod) {
            
            uint256 ftmBalance = address(this).balance; 

            uint256 amountToStrategy = ftmBalance.div(strategyNominator).mul(strategyPercentage);
            uint256 amountToDistribution = ftmBalance.sub(amountToStrategy); 
            uint256 earnings = strategy.shouldPullEarnings() ? strategy.pullEarnings() : 0;

            uint256 amountOut = handleSwapFTMtoSCARAB(amountToDistribution); 
            uint256 totalDistribution = amountOut.add(earnings);
            totalDividends = totalDividends.add(totalDistribution);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(totalDistribution).div(totalShares));
            
            handleStrategyAmount(amountToStrategy);

            lastDepositTimestamp = block.timestamp; 
        } 
    }

    /** ======= INTERNAL FUNCTIONS ======= */

    function handleStrategyAmount(uint256 _amount) internal {
        try strategy.process{value: _amount}() {} catch {} 
    }

    /** ======= SWAPPER FUNCTIONS ======= */

    function handleSwapFTMtoSCARAB(uint256 _amount) internal returns (uint256) {
        uint256 balanceBefore = scarab.balanceOf(address(this));

        address[] memory path = new address[](2);
            path[0] = address(wftm);
            path[1] = address(scarab);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amount}(
            0,
            path,
            address(this),
            block.timestamp
        );
        return scarab.balanceOf(address(this)).sub(balanceBefore);

    }
    
    /** ======= INTERNAL HELPER VIEW FUNCTIONS ======= */

    function shouldDistribute(address _shareholder) internal view returns (bool) {
        // Check 
        // Check unpaid earnings are higher than minDistribution 
        return 
            shareholderClaims[_shareholder] + minPeriod < block.timestamp
        && 
            getUnpaidEarnings(_shareholder) > minDistribution;
    }

   
    function getCumulativeDividends(uint256 _share) internal view returns (uint256) {
        return _share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    /** ======= INTERNAL SHARE FUNCTIONS ======= */

    function distributeDividend(address _shareholder) internal {

        // Make shure the shareholder has shares; 
        if(shares[_shareholder].amount == 0){ 
            return; 
        }

        // Get the shareholder earnings; 
        uint256 amount = getUnpaidEarnings(_shareholder);

        // If shareholder has earnings distribute; 
        if(amount > 0){
            // Update totals; 
            totalDistributed = totalDistributed.add(amount);
            // Transfer the shares to holder; 
            scarab.transfer(_shareholder, amount);
            // Update holderClaims; 
            shareholderClaims[_shareholder] = block.timestamp;
            // Update holder totals; 
            shares[_shareholder].totalRealised = shares[_shareholder].totalRealised.add(amount);
            shares[_shareholder].totalExcluded = getCumulativeDividends(shares[_shareholder].amount);
        }
    }

    function addShareholder(address _shareholder) internal {
        shareholderIndexes[_shareholder] = shareholders.length;
        shareholders.push(_shareholder);
    }

    function removeShareholder(address _shareholder) internal {
        shareholders[shareholderIndexes[_shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[_shareholder];
        shareholders.pop();
    }

    /** ======= MODIFIERS ======= */

    modifier onlyToken() {
        require(msg.sender == address(scarabp)); _;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}