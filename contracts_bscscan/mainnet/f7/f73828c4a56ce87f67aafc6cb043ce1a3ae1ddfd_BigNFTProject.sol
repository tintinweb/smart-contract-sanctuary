/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

pragma solidity ^0.7.4;

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
 * Standard SafeMath
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
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

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

contract BigNFTProject is IBEP20, Auth {
    using SafeMath for uint256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Paperfly"; 
    string constant _symbol = "Pfly";
    uint8  constant _decimals = 18;

    uint256 _totalSupply = 12000000 * (10**_decimals);
    uint256 public _maxTxAmount = 120000 * (10**_decimals); 
    uint256 public _maxHoldAmount = 120000 * (10**_decimals); 
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;


    mapping (address => bool) isMaxHoldLimitExempt;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    /*
    * Note: We have no tax on buy! Although it could be turned on by me.
    */
 
    uint256 public totalFee = 15;
    uint256 feeDenominator  = 100;
    

    address public marketingFeeReceiver;

    IDEXRouter public router;
    address public pair;
    
    uint256 taxBuys = 0;
    uint256 taxWalletToWallet = 1;
    mapping (address => uint) private cooldownTimer;

    bool public swapEnabled = true;
    
    uint256 public swapAfterCountTransactions = 2;
    uint256 private _transactionCounter = 0;

    bool inSwap;
    

    constructor () Auth(msg.sender) {
        //router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //real
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //pcs testnet
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        
        isTxLimitExempt[msg.sender] = true;
        //isTxLimitExempt[address(this)] = true;
        
        isMaxHoldLimitExempt[msg.sender] = true;
        isMaxHoldLimitExempt[pair] = true;

        marketingFeeReceiver = msg.sender;
        
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
        //checkTxDeadAddress(msg.sender, spender);
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
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        checkTxLimit(sender, recipient,amount);

        checkMaxWalletLimit(recipient, amount);
        
        if(shouldSwapBack()){ swapAndLiquify(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
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

    function checkTxLimit(address sender, address to, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[to], "tx limit reached");
    }
    
    function checkMaxWalletLimit(address to, uint256 amount) internal view {
        uint256 userBalance = balanceOf(to);
        
        require((userBalance + amount) <= _maxHoldAmount || isMaxHoldLimitExempt[to] || (to == address(DEAD)), "Max wallet Exceeded");
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {

        if(sender != pair && recipient != pair && taxWalletToWallet ==0){
                return false;
        }

        if(isFeeExempt[sender] || isFeeExempt[recipient] || (taxBuys ==0 && sender == pair)){
            return false;
        }
        return true;
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {

        _transactionCounter++;

        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair && !inSwap && swapEnabled && _transactionCounter >= swapAfterCountTransactions;
    }

    
    modifier lockTheSwap() { 
        inSwap = true; 
        
        _; inSwap = false; 
        
    }


    function swapAndLiquify() internal lockTheSwap {
        
        _transactionCounter = 0;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 amountToSwap =  balanceOf(address(this));

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 contractSwapBNB = address(this).balance;
         (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: contractSwapBNB, gas: 30000}("");
         tmpSuccess = false;
    }

    function setMaxTx(uint256 _maxTransaction, uint256 maxHold) external onlyOwner {
        _maxTxAmount = _maxTransaction * (10**_decimals);
        _maxHoldAmount = maxHold * (10**_decimals);
    } 
    
    function setExemptions(address holder, bool exemptMaxSell, bool exemptMaxHold, bool exmeptFee) external onlyOwner {
        isTxLimitExempt[holder] = exemptMaxSell;
        isMaxHoldLimitExempt[holder] = exemptMaxHold;
        isFeeExempt[holder] = exmeptFee;
    }
    
    function setTaxing(uint256 _contractFee, uint256 _taxBuyers, uint256 _taxWalletToWallet ) external onlyOwner {
        require(_contractFee <= 15, "Max tax is 15%."); 
        require(_taxWalletToWallet <= 1, "Error"); 
        require(_taxBuyers <=1, "Error"); 
        totalFee = _contractFee;
        taxBuys = _taxBuyers;
        taxWalletToWallet = _taxWalletToWallet;
    }

    function setMarketingReceiver(address _feeReceiver) external onlyOwner {
        marketingFeeReceiver = _feeReceiver;
    }

    function canSwap(bool _enabled, uint256 _swapAt) external onlyOwner {
        swapEnabled   = _enabled;
        swapAfterCountTransactions = _swapAt;
    }

     function checkFeeExempt(address _address) external view onlyOwner returns (bool){
       return isFeeExempt[_address];  
     }
     
     function checkNoMaxWallet(address _address) external view onlyOwner returns (bool){
       return isMaxHoldLimitExempt[_address];  
     }
     
     function checkTx(address _address) external view onlyOwner returns (bool){
       return isTxLimitExempt[_address];  
     }
     }