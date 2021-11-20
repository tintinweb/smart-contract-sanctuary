/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

//MetaDoge is the next BSC community driven meme/utility token which has the goal to be the next big moonshot.

//SPDX-License-Identifier: None

pragma solidity ^0.8.5;

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

contract TestContract is IBEP20, Auth {
    using SafeMath for uint256;

    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; //Mainnet:0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Test";
    string constant _symbol = "Test";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100000000000 * (10 ** _decimals);
    uint256 _burntSupply = (_totalSupply * 38) /100;
    uint256 _liqSupply = (_totalSupply * 50) /100;
    uint256 _ethBridgeAndExchangeSupply = (_totalSupply * 10) /100;
    uint256 _stakingSupply = (_totalSupply * 2) /100;
   
    uint256 public _maxTxAmount = (_totalSupply * 5) / 1000;
    uint256 public _maxWalletSize = (_totalSupply * 10) / 1000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isMaxWalletExempt; //Noch unten in die exclude methode einfügen

    //Buyfees
    uint256 liquidityFee = 5;
    uint256 marketingFee = 3;
    uint256 devFee = 2;
    uint256 stakingFee = 2;
    uint256 totalFee = 12;
    
    //Sellfees
    uint256 sellLiquidityFee = 5;
    uint256 sellMarketingFee = 3;
    uint256 sellDevFee = 2; 
    uint256 sellStakingFee = 4;
    uint256 totalSellFee = 14;
    
    //AvFees
    uint256 tempLiquidityFee;
    uint256 tempMarketingFee;
    uint256 tempDevFee;
    uint256 tempTotalFee;
    
    uint256 feeDenominator = 100;
    uint256 public launchTimestamp = 0;
    uint256 timeF = 0; 
    
    
    address private marketingFeeReceiver = 0x3F602089d2fD51D73EBfFCEBaD154A898B235A16;
    address private devFeeReceiver = 0x973BD2F207F317753ADE00B56D4Bb6f0a0BC4ABb;
    address private ethBridgeAndExchange = 0x16A1c14661e3d9B674251cCD345C5180A37ecc26;
    address private stakingWallet = 0xBd18C1F64212c4c89D830D5564b648c527Bd40F3;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;
    
    bool public tradingEnabled;
    bool public swapEnabled;
    uint256 public swapThreshold = _totalSupply / 1000 * 1; // 0.1%
    
    bool inSwap;
    
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        //Mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        address _DEAD = DEAD;
        isFeeExempt[_owner] = true;
        isTxLimitExempt[_owner] = true;
        isFeeExempt[ethBridgeAndExchange] = true;
        isTxLimitExempt[ethBridgeAndExchange] = true;
        isFeeExempt[stakingWallet] = true; 
        isTxLimitExempt[stakingWallet] = true; 
        
        _balances[_owner] = _liqSupply;
        _balances[_DEAD] = _burntSupply;
        _balances[ethBridgeAndExchange] = _ethBridgeAndExchangeSupply;
        _balances[stakingWallet] = _stakingSupply;
        emit Transfer(address(0), _owner, _liqSupply);
        emit Transfer(address(0), _DEAD, _burntSupply);
        emit Transfer(address(0), ethBridgeAndExchange, _ethBridgeAndExchangeSupply);
        emit Transfer(address(0), stakingWallet, _stakingSupply);
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
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(sender != pair && recipient != pair){ return _basicTransfer(sender, recipient, amount); } //transfer between wallets
        
        if(!isFeeExempt[sender]){
            require(tradingEnabled, "Trading is not enabled yet");
        }
        
        checkTxLimit(sender, amount);


        if (recipient != pair && recipient != DEAD && recipient != ethBridgeAndExchange && sender != ethBridgeAndExchange) {
            require(isTxLimitExempt[recipient] || isMaxWalletExempt[sender] || _balances[recipient] + amount <= _maxWalletSize, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack()){ swapBack(); }
        

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
    
        if(shouldTakeFee(sender) != true){
             uint256 amountReceived = amount; 
             _balances[recipient] = _balances[recipient].add(amountReceived);

            emit Transfer(sender, recipient, amountReceived);
        }
        else {
            uint256 amountReceived = takeFee(sender, recipient, amount);
            _balances[recipient] = _balances[recipient].add(amountReceived);

            emit Transfer(sender, recipient, amountReceived);
        }
        
        
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(isMaxWalletExempt[recipient] || _balances[recipient] + amount <= _maxWalletSize, "Transfer amount exceeds the bag size.");
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        uint256 multiplier = AntiDumpMultiplier();
        bool firstFewBlocks = AntSni();
        if(selling) {   return totalSellFee.mul(multiplier); }
        if (firstFewBlocks) {return feeDenominator.sub(1); }
        return totalFee;
    }

    function AntiDumpMultiplier() private view returns (uint256) {
        uint256 time_since_start = block.timestamp - launchTimestamp;
        uint256 hour = 3600;
        if (time_since_start > 1 * hour) { return (1);}
        else { return (2);}
    }
    
    function AntSni() private view returns (bool) {
        uint256 time_since_start = block.timestamp - launchTimestamp;
        if (time_since_start < timeF) { return true;}
        else { return false;}
    }
    
    function updateTimeF(uint256 _int) public onlyOwner {
        require(_int < 1536, "Time too long");
        timeF = _int; 
    }


    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);
        if(receiver == pair) {
            uint256 stakingFeeAmount = amount.mul(sellStakingFee).div(feeDenominator).mul(AntiDumpMultiplier());
            uint256 newFeeAmount = feeAmount.sub(stakingFeeAmount);
            
            _balances[stakingWallet] = _balances[stakingWallet].add(stakingFeeAmount);
            emit Transfer(sender, stakingWallet, stakingFeeAmount);
            
            _balances[address(this)] = _balances[address(this)].add(newFeeAmount); 
            emit Transfer(sender, address(this), newFeeAmount); //send 22k
            return amount.sub(feeAmount); 
        }
        else {
            uint256 stakingFeeAmount = amount.mul(stakingFee).div(feeDenominator);
            uint256 newFeeAmount = feeAmount.sub(stakingFeeAmount);
            
            
            _balances[stakingWallet] = _balances[stakingWallet].add(stakingFeeAmount);
            emit Transfer(sender, stakingWallet, stakingFeeAmount);
            
            _balances[address(this)] = _balances[address(this)].add(newFeeAmount);
            emit Transfer(sender, address(this), newFeeAmount);
            return amount.sub(feeAmount);
       }
    
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function getSwapFees() internal {
        tempLiquidityFee = liquidityFee.mul(sellLiquidityFee).div(2);
        tempMarketingFee = marketingFee.mul(sellMarketingFee).div(2);
        tempDevFee = devFee.mul(sellDevFee).div(2);
        tempTotalFee = totalFee.mul(totalSellFee).div(2);
    }

    function swapBack() internal swapping {
        //average the fees
        getSwapFees();
        
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractTokenBalance.mul(tempLiquidityFee).div(tempTotalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

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
        uint256 totalBNBFee = tempTotalFee.sub(tempLiquidityFee.div(2));
        uint256 amountBNBLiquidity = amountBNB.mul(tempLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBMarketing = amountBNB.mul(tempMarketingFee).div(totalBNBFee);
        uint256 amountBNBDev = amountBNB.mul(tempDevFee).div(totalBNBFee);
        //payable(devFeeReceiver).transfer(amountBNBDev);
        //payable(marketingFeeReceiver).transfer(amountBNBMarketing);

        (bool MarketingSuccess, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        (bool DevSuccess, /* bytes memory data */) = payable(devFeeReceiver).call{value: amountBNBDev, gas: 30000}("");
        require(MarketingSuccess && DevSuccess,"receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                marketingFeeReceiver,
                block.timestamp
            );
        }
    }
    
    
    function startTrading() external onlyOwner{
        tradingEnabled = true;
        swapEnabled = true;
        launchTimestamp = block.timestamp;
        emit TradingEnabled(block.timestamp);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }
    
    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }
    
    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

   function setMaxWallet(uint256 amount) external onlyOwner() {
        require(amount >= _totalSupply / 1000 );
        _maxWalletSize = amount;
    }    

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }
    
    function excludeFromMaxWallet(address _wallet, bool _excludeFromMaxWallet) external onlyOwner{
        isMaxWalletExempt[_wallet] = _excludeFromMaxWallet; 
    }
    
    function excludeFromMaxTX(address _wallet, bool _excludeFromMaxTx) external onlyOwner{
        isTxLimitExempt[_wallet]= _excludeFromMaxTx;
    }

    function setBuyFees(uint256 _liquidityFee,  uint256 _marketingFee,uint256 _devFee, uint256 _stakingFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        stakingFee = _stakingFee;
        devFee = _devFee;
        totalFee = _liquidityFee.add(_marketingFee).add(_stakingFee).add(_devFee);
        feeDenominator = _feeDenominator;
    }
    
    function setSellFees(uint256 _liquidityFee,  uint256 _marketingFee,uint256 _devFee, uint256 _stakingFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        sellStakingFee = _stakingFee;
        sellDevFee = _devFee;
        totalSellFee = _liquidityFee.add(_marketingFee).add(_stakingFee).add(_devFee);
        feeDenominator = _feeDenominator;
    }

    function setMarketingFeeReceiver(address _marketingFeeReceiver) external authorized {
        marketingFeeReceiver = _marketingFeeReceiver;
    }
    
    function setDevFeeReceiver(address _devFeeReceiver) external authorized {
        devFeeReceiver = _devFeeReceiver; 
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function manualSend() external authorized {
        uint256 contractETHBalance = address(this).balance;
        payable(marketingFeeReceiver).transfer(contractETHBalance);
    }

    function transferForeignToken(address _token) public authorized {
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        payable(marketingFeeReceiver).transfer(_contractBalance);
    }
        
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    event TradingEnabled(uint256 startDate);
}