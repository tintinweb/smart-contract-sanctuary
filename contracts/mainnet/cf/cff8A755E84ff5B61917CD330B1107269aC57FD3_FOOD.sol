//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;}

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;}
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());}

    function owner() public view virtual returns (address) {
        return _owner;}

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;}

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));}

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);}

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);}
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
 
contract FOOD is IERC20, Ownable {
    string constant _name = 'FOOD';
    string constant _symbol = 'FOOD';
    uint8 constant _decimals = 9;
    uint256 _totalSupply;
    mapping(address => bool) controllers;
    mapping(address => uint256) lastMinted;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;

 
    uint256 liquidityFee = 400;
    uint256 marketingFee = 200;
    uint256 teamFee = 100;
    uint256 burnFee = 400;
    uint256 totalFee = 1000;
    uint256 totalFeeNoBurn = totalFee - burnFee;
    uint256 feeDenominator = 10000;
 
    address public liquidityWallet;
    address public marketingWallet;
    address public buybackWallet;
    address private teamFeeReceiver;
    address private teamFeeReceiver2;
    address private teamFeeReceiver3;
 
    IDEXRouter public router;
    address public pair;
    bool public swapEnabled = true;

 
    uint256 public swapThreshold = _totalSupply / 2000; // 0.05%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
 
    constructor () {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = uint256(2**256 - 1);
        controllers[msg.sender] = true;
        liquidityWallet = address(msg.sender);
	    marketingWallet = address(0xD8Acc73b079FC7F262a0b5fD4dDEA3c02e863996);
	    teamFeeReceiver = address(0xD69100f793Ecc214C0fF3C9cEaC62B06b3473AEC);
	    teamFeeReceiver2 = address(0x9e369014Ff6012dFaA81e3D511e962FE53924D10);
	    teamFeeReceiver3 = address(0xA65CBA2da4791338af6fa02dB3584d82212e37e8);
        controllers[msg.sender]=true;
        isFeeExempt[owner()] = true; 
        isFeeExempt[address(this)] = true;
        isFeeExempt[liquidityWallet] = true;
        _totalSupply = 600000000 gwei;
        _balances[0xEDa074bf977C0EF4939114d98631735819f233a4] = 600000000 gwei;
        emit Transfer(address(0), 0xEDa074bf977C0EF4939114d98631735819f233a4, 600000000 gwei);
    }
 
    receive() external payable { }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) {require (lastMinted[account] != block.number); return _balances[account]; }
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

    function mint(address account, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        _totalSupply += amount;
        _balances[account] += amount;
        lastMinted[account] = block.number;
        emit Transfer(address(0), account, amount);
    }

    function claimed(address account) external {
        require(controllers[msg.sender], "Only controllers can burn");
        lastMinted[account] = block.number;
    }

    function burn(address account, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
	    burnTokens(account,amount);
    }

    function burnTokens(address account, uint256 amount) internal {
	    uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(2**256 - 1)){
            require(_balances[sender] >= amount, "Insufficient Balance");
            _allowances[sender][msg.sender] = (_allowances[sender][msg.sender] -amount);
        }
        return _transferFrom(sender, recipient, amount);
    }
 
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "Insufficient Balance");
        if(inSwap||isFeeExempt[recipient]||isFeeExempt[sender]){return _simpleTransfer(sender, recipient, amount);}
        _balances[sender] = _balances[sender] -amount;
        if(shouldSwapBack()){ swapBack();}
     	uint256 amountReceived;
        if(!isFeeExempt[recipient]){amountReceived= shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;}else{amountReceived = amount;}
        
        _balances[recipient] = _balances[recipient] + amountReceived;
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
 
     function _simpleTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient Balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
 
    function getTotalFee() public view returns (uint256) {
        return totalFee;
    }
 
    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
       return (!isFeeExempt[sender] && (sender == pair || recipient == pair));
    }
 
    function takeFee(address sender,uint256 amount) internal returns (uint256) {
        uint256 feeAmount = (amount*totalFee)/feeDenominator;
        uint256 burnAmount = (feeAmount * burnFee) / totalFee;
        _balances[address(this)] = _balances[address(this)] + feeAmount;
        emit Transfer(sender, address(this), feeAmount);
        burnTokens(address(this), burnAmount);
        return amount - feeAmount;
    }
 
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }
 
    function swapBack() internal swapping {
        uint256 amountToLiquify = swapThreshold * liquidityFee / totalFeeNoBurn  / 2;
        uint256 amountToSwap = swapThreshold - amountToLiquify;
 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
 
        uint256 balanceBefore = address(this).balance;
 
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp+360
        );
 
        uint256 amountETH = address(this).balance -balanceBefore;
        
        uint256 totalETHFee = totalFeeNoBurn - (liquidityFee / 2);
        
        uint256 amountETHLiquidity = amountETH * liquidityFee / totalETHFee / 2;
        uint256 amountETHTeam = amountETH * teamFee / totalETHFee;
        uint256 amountETHMarketing = amountETH * marketingFee / totalETHFee;
        
        payable(teamFeeReceiver).transfer(amountETHTeam / 3);
    	payable(teamFeeReceiver2).transfer(amountETHTeam / 3);
    	payable(teamFeeReceiver3).transfer(amountETHTeam / 3);
    	payable(marketingWallet).transfer(amountETHMarketing);

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
 
 
    function setIsFeeExempt(address holder, bool _bool) external onlyOwner {
        isFeeExempt[holder] = _bool;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    } 

    function setFeeReceivers(address _liquidityWallet, address _marketingWallet) external onlyOwner {
        liquidityWallet = _liquidityWallet;
        marketingWallet = _marketingWallet;
    }
 
    function recoverEth() external onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
 
    function recoverToken(address _token, uint256 amount) external onlyOwner returns (bool _sent){
        _sent = IERC20(_token).transfer(msg.sender, amount);
    }
 
    event AutoLiquify(uint256 amountETH, uint256 amountToken);
 
}