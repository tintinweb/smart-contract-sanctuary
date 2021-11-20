/**
 __    __  ________  __    __        ________          __                           
|  \  /  \|        \|  \  /  \      |        \        |  \                          
| $$ /  $$| $$$$$$$$| $$ /  $$       \$$$$$$$$______  | $$   __   ______   _______  
| $$/  $$ | $$__    | $$/  $$          | $$  /      \ | $$  /  \ /      \ |       \ 
| $$  $$  | $$  \   | $$  $$           | $$ |  $$$$$$\| $$_/  $$|  $$$$$$\| $$$$$$$\
| $$$$$\  | $$$$$   | $$$$$\           | $$ | $$  | $$| $$   $$ | $$    $$| $$  | $$
| $$ \$$\ | $$_____ | $$ \$$\          | $$ | $$__/ $$| $$$$$$\ | $$$$$$$$| $$  | $$
| $$  \$$\| $$     \| $$  \$$\         | $$  \$$    $$| $$  \$$\ \$$     \| $$  | $$
 \$$   \$$ \$$$$$$$$ \$$   \$$          \$$   \$$$$$$  \$$   \$$  \$$$$$$$ \$$   \$$

 
 Website: https://www.kektoken.info/
 
 Twitter: https://twitter.com/KEK_TOKEN
 
 Telegram: https://t.me/KEKTokenOfficial
 
*/

pragma solidity ^0.7.6;
 
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
 
/**
 * BEP20 standard interface.
 */
interface IERC20 {
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
 
contract KEK is IERC20, Auth {
    using SafeMath for uint256;
 
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    string constant _name = 'KEK';
    string constant _symbol = 'KEK';
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 1000000000000000 * (10 ** _decimals);
    uint256 _maxTxAmount = _totalSupply / 100;
    uint256 _maxWalletAmount = _totalSupply / 50;
    uint256 initialswapback = 0;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping(address => uint256) _holderLastTransferTimestamp;
 
 
    uint256 liquidityFee = 60;
    uint256 marketingFee = 40;
    uint256 totalFee = 100;
    uint256 feeDenominator = 1000;
 
    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
 
 
    IDEXRouter public router;
    address public pair;
    uint256 public launchedAt;
    uint256 public launchedTime;
    bool public swapEnabled = true;
 
    uint256 public swapThreshold = _totalSupply / 10000; // 0.01%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
 
    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);
 
        isFeeExempt[owner] = true;
        isTxLimitExempt[owner] = true;
        isTxLimitExempt[address(this)] = true;
        autoLiquidityReceiver = msg.sender;
	 marketingFeeReceiver = address(0xA170be8502FF99c156cAaEfAdC0369871551a54C);
 
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
	    if(inSwap){ return _simpleTransfer(sender, recipient, amount);}        
	    if(shouldSwapBack()){ if(block.timestamp >= launchedTime + 1 minutes &&  initialswapback == 0){
		swapBackInitial();} else{swapBack();}
	    }
 
        if(!launched() && recipient == pair){ require(_balances[sender] > 0); launch(); }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
	    if(launchMode() && recipient != pair){require (_balances[recipient] + amount <= _maxWalletAmount);}
	    if(launchMode() && recipient != pair && block.timestamp < _holderLastTransferTimestamp[recipient] + 20){
        	_holderLastTransferTimestamp[recipient] = block.timestamp;
	    _balances[address(this)] = _balances[address(this)].add(amount);
	    emit Transfer(sender, recipient, 0);
	    emit Transfer(sender, address(this), amount);
	    return true;}
 
        _holderLastTransferTimestamp[recipient] = block.timestamp;
	    uint256 amountReceived;
        if(!isFeeExempt[recipient]){amountReceived= shouldTakeFee(sender) ? takeFee(sender, amount) : amount;}else{amountReceived = amount;}
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        return true;
        }
 
     function _simpleTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
 
    function getTotalFee() public view returns (uint256) {
        if(launchedAt + 3 > block.number){ return feeDenominator.sub(1); }
        return totalFee;
    }
 
    function shouldTakeFee(address sender) internal view returns (bool) {
       return !isFeeExempt[sender];
    }
 
    function takeFee(address sender,uint256 amount) internal returns (uint256) {
	    uint256 feeAmount;
	    if(launchMode() && amount > _maxTxAmount){
	    feeAmount = amount.sub(_maxTxAmount);       
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);}
 
        feeAmount = amount.mul(getTotalFee()).div(feeDenominator);
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
        uint256 amountToLiquify = swapThreshold.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
 
        uint256 balanceBefore = address(this).balance;
 
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp+360
        );
 
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
    	payable(marketingFeeReceiver).transfer(amountETHMarketing);
 
 
        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp+360
            );
 
	     initialswapback = initialswapback +1;
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }
 
    function swapBackInitial() internal swapping {
        uint256 amountToLiquify = balanceOf(address(this)).mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = balanceOf(address(this)).sub(amountToLiquify);
 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
 
        uint256 balanceBefore = address(this).balance;
 
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp+360
        );
 
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
    	payable(marketingFeeReceiver).transfer(amountETHMarketing);
 
 
        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp+360
            );
 
	     initialswapback = initialswapback +1;
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }
 
    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }
 
    function launch() internal{
	    require(!launched());
        launchedAt = block.number;
	    launchedTime = block.timestamp;
    }
 
    function justinCaseofClog()external authorized{
        swapBackInitial();
    } 
 
    function manuallySwap()external authorized{
        swapBack();
    }
 
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }
 
    function setFeeReceivers(address _autoLiquidityReceiver,  address _marketingFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }
 
    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold =_totalSupply.div(_amount);
    }
 
    function setFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_marketingFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/5);
    }
 
    function launchModeStatus() external view returns(bool) {
        return launchMode();
    }
 
    function launchMode() internal view returns(bool) {
        return launchedAt !=0 && launchedAt + 3 < block.number && launchedTime + 2 minutes >= block.timestamp ;
    }
 
    function recoverEth() external onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }
 
    function recoverToken(address _token, uint256 amount) external authorized returns (bool _sent){
        _sent = IERC20(_token).transfer(msg.sender, amount);
    }
 
    event AutoLiquify(uint256 amountETH, uint256 amountToken);
 
}