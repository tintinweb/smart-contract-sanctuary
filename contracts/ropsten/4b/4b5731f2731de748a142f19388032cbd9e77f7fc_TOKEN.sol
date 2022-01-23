/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

//SPDX-License-Identifier: MIT
 
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
 
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
 
 
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
contract TOKEN is IERC20, Auth {
    using SafeMath for uint256;
 
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    string constant _name = 'NAME';
    string constant _symbol = 'TICKER';
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 1_000_000_000_000 * (10 ** _decimals);
    uint256 maxTxAmount = _totalSupply / 1000;
    uint256 maxWalletAmount = _totalSupply / 200;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) capturedBotter;
    mapping(address => uint256) _holderLastTransferTimestamp;
 
 
    uint256 liquidityFee = 400;
    uint256 teamFee = 100;
    uint256 totalFee = 500;
    uint256 feeDenominator = 10000;
 
    address public liquidityWallet;
    address private teamFeeReceiver;
 
 
    IDEXRouter public router;
    address public pair;
    uint256 public launchedAt;
    uint256 public launchedTime;
    bool public swapEnabled = true;
    bool public humansOnly = true;
 
    uint256 public swapThreshold = _totalSupply / 2000; // 0.05%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
 
    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = uint256(2**256 - 1);
 
        liquidityWallet = address(msg.sender);
	    teamFeeReceiver = address(msg.sender);
 
 
        isFeeExempt[owner] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[liquidityWallet] = true;
        isTxLimitExempt[owner] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[liquidityWallet] = true;
 
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
        return approve(spender, uint256(2**256 - 1));
    }
 
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(2**256 - 1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }
 
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require (!capturedBotter[sender]);
        if(inSwap){ return _simpleTransfer(sender, recipient, amount);}
 
        if(shouldSwapBack()){ swapBack(); }
 
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
 
        if(!isTxLimitExempt[recipient] && sender == pair){
	    require (_balances[recipient] + amount <= maxWalletAmount);
	    require (amount <= maxTxAmount);
        }
 
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
 
     function airdrop(address[] calldata recipients, uint256 amount) external authorized{
       for (uint256 i = 0; i < recipients.length; i++) {
            _simpleTransfer(msg.sender,recipients[i], amount);
        }
    }
 
 
    function shouldTakeFee(address sender) internal view returns (bool) {
       return !isFeeExempt[sender];
    }
 
    function takeFee(address sender,uint256 amount) internal returns (uint256) {
        if (totalFee !=0){
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
        } else {
        return amount;
        }
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
        uint256 amountETHTeam = amountETH.mul(teamFee).div(totalETHFee);
 
        payable(teamFeeReceiver).transfer(amountETHTeam);
 
 
        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityWallet,
                block.timestamp+360
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }
 
 
 
    function manuallySwap() external authorized{
        swapBack();
    }
 
    function setIsFeeAndTXLimitExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        isTxLimitExempt[holder] = exempt;
    }
 
    function setFeeReceivers(address _liquidityWallet, address _teamFeeReceiver) external onlyOwner {
        liquidityWallet = _liquidityWallet;
        teamFeeReceiver = _teamFeeReceiver;
    }
 
    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
 
    function setFees(uint256 _liquidityFee, uint256 _teamFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        teamFee = _teamFee;
        totalFee = _liquidityFee.add(teamFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/5);
    }
 
    function setxLimit(uint256 _maxTxAmount) external onlyOwner {
        maxTxAmount = _maxTxAmount;
        require(_maxTxAmount > _totalSupply / 1000);
    }
 
    function setMaxWallet(uint256 _maxWalletAmount) external onlyOwner {
         maxWalletAmount = _maxWalletAmount;
        require(_maxWalletAmount > _totalSupply / 200);
    }
 
    function addBot(address _botter) external authorized {
        capturedBotter[_botter] = true;
    }
 
 
    function notABot(address _botter) external authorized {
        capturedBotter[_botter] = false;
    }
 
    function bulkAddBots(address[] calldata _botters) external authorized{
        for (uint256 i = 0; i < _botters.length; i++) {
            capturedBotter[_botters[i]]= true;
        }
    }
 
    function recoverEth() external onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }
 
    function recoverToken(address _token, uint256 amount) external authorized returns (bool _sent){
        _sent = IERC20(_token).transfer(msg.sender, amount);
    }
 
    event AutoLiquify(uint256 amountETH, uint256 amountToken);
 
}