/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

// SPDX-License-Identifier: UNLICENSED

/*

Elon Tweet: https://twitter.com/twitter/statuses/1478419298032836610'

TG: https://t.me/FarmerSponge

*/

pragma solidity ^0.8.9;

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
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

//Stripped down to the bare bone

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract FarmerSponge is IBEP20, Ownable {

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "FarmerSponge";
    string constant _symbol = "$FarmerSponge";
    uint8 constant _decimals = 4;

    uint256 _totalSupply = 1 * 10**9 * 10**_decimals;

    uint256 public _maxTxAmount = _totalSupply/100;
    uint256 public _maxWalletToken = _totalSupply/100;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) public _botList;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isMaxWalletExempt;
    mapping (address => bool) public isTxLimitExempt;

    uint256 public marketingFee    = 5;
    uint256 public buyBackFee = 5;
    uint256 public autoBuyBack = 0;
    uint256 public burner = 3;
    uint256 public sellFee = 7;
    uint256 public totalFee        = marketingFee + buyBackFee;
    uint256 public feeDenominator  = 100;
    
    address public buyBackReceiver = 0x391A47497Ce19ED43C015f3bf1d69985FBc24690;
    address public marketingFeeReceiver;

    address public pair;
    IDEXRouter public router;

    bool public dropIt = true;
    bool public _botMode = true;
    bool public tradingStarted = false; 
  
    uint256 public launchedAt = 0;
    uint256 public botBlocks = 2;

    uint256 public sellThreshold = _totalSupply / 1000;
    uint256 public swapThreshold = _totalSupply / 400;
    
    bool public swapEnabled = true;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = 2**256 - 1;
        _allowances[msg.sender][address(router)] = 2**256 - 1;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isMaxWalletExempt[pair] = true;
        isMaxWalletExempt[address(this)] = true;
        isMaxWalletExempt[DEAD] = true;
        isMaxWalletExempt[msg.sender] = true;

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
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, 2**256 - 1);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != 2**256 - 1){
            _allowances[sender][msg.sender] -=  amount; 
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        checkValidity(sender,recipient,amount);

        if(shouldSwapBack(amount)){ swapBack(); }

        //Exchange tokens
        _balances[sender] -= amount;
        uint256 amountReceived = (!shouldTakeFee(sender) || !shouldTakeFee(recipient)) ? amount : takeFee(sender, amount,(recipient == pair));
        _balances[recipient] += amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -=amount; 
        _balances[recipient] +=amount; 
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount, bool isSell) internal returns (uint256) {
        
        uint256 fee = isSell ? sellFee : totalFee;
        uint256 feeAmount = (amount * fee) /feeDenominator;
        uint256 toTheFire = 0; 

        if(isSell && (burner >0)){
            toTheFire = (amount * burner)/feeDenominator;
            _balances[DEAD] +=toTheFire;
            emit Transfer(sender, DEAD, toTheFire);
        }

        if(dropIt && !isSell && ((launchedAt + botBlocks) > block.number)){
             feeAmount = (amount * 99) /100;
        }

        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        feeAmount+=toTheFire;
        
        return amount-= feeAmount;
    }

    function shouldSwapBack(uint256 amount) internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && amount > sellThreshold
        && _balances[address(this)] >= swapThreshold;
    }

    function startTrading(uint256 _botBlocks) public onlyOwner {
        launchedAt = block.number;
        botBlocks = _botBlocks;
        tradingStarted = true;
    }

    function setDropIt(bool _dropIt) external onlyOwner{
        dropIt = _dropIt;        
    }

    function swapBack() internal swapping {
        uint256 amountToSwap = swapThreshold;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance - (balanceBefore);
        uint256 amountBNBBuyback = (amountBNB * buyBackFee)/(totalFee);
        uint256 amountBNBMarketing = (amountBNB * marketingFee)/(totalFee);
        
        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        (tmpSuccess,) = payable(buyBackReceiver).call{value: amountBNBBuyback, gas: 30000}("");
        
        // only to supress warning msg
        tmpSuccess = false;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsMaxWalletExempt(address holder, bool exempt) external onlyOwner{
         isMaxWalletExempt[holder] = exempt;
    }

    function setFees(uint256 _marketingFee, uint256 _buyBackFee, uint256 _burner, uint256 _sellFee, uint256 _feeDenominator) external onlyOwner {
        marketingFee = _marketingFee;
        buyBackFee = _buyBackFee;
        burner = _burner;
        sellFee = _sellFee;
        totalFee =  _marketingFee +_buyBackFee;
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/3, "Fees cannot be more than 33%");
        require(sellFee < feeDenominator/3, "Fees cannot be more than 33%");
    }

    function setFeeReceivers(address _buyBackReceiver, address _marketingFeeReceiver) external onlyOwner {
        buyBackReceiver = _buyBackReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
     
    function checkValidity(address sender, address recipient, uint256 _amount) internal view {
        require(_amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient] , "TX Limit Exceeded");
        require((balanceOf(recipient) + _amount) <= _maxWalletToken || isMaxWalletExempt[recipient],"Total Holding is currently limited, you can not buy that much.");
        require(tradingStarted || isTxLimitExempt[sender], "Trading hasn't started yet, seer");
        if (_botMode && sender != pair){
            require(!_botList[sender] || sender == address(this) || sender == pair, "Botsi Botsi, Boom Boom");
            require(!_botList[msg.sender], "Botsi Botsi, Boom Boom");
        }
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD)) - (balanceOf(ZERO));
    }

    function manageBots(address _bot, bool status) external onlyOwner{
        _botList[_bot]=status;
    }

     function botMode(bool enabled) external onlyOwner{
        _botMode = enabled;
    }

    // In case BNBs get stuck in contract
    function rescueBNB() external {
        require(msg.sender == buyBackReceiver);
        uint256 amountBNB = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountBNB);
    }
    
    // In case someone mistakenly send tokens to the contract, we
    function rescueToken(address tokenAddress, uint256 tokens) external returns (bool success) {
        require(msg.sender == buyBackReceiver);
        return IBEP20(tokenAddress).transfer(msg.sender, tokens);
    }
}