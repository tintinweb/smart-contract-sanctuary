/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IBEP20Metadata is IBEP20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
interface IPancakeRouter01 {
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
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}
}
contract BEP20 is Context, IBEP20, IBEP20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {return _name;}
    function symbol() public view virtual override returns (string memory) {return _symbol;}
    function decimals() public view virtual override returns (uint8) { return 18; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue); return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
abstract contract BEP20Burnable is Context, BEP20 {
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "BEP20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() { _setOwner(_msgSender()); }
    function owner() public view virtual returns (address) { return _owner; }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner { _setOwner(address(0)); }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub( uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b <= a, errorMessage); return a - b; }
    }
    function div( uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b > 0, errorMessage); return a / b; }
    }
    function mod( uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b > 0, errorMessage); return a % b; }
    }
}
contract TKNSOFT is BEP20, BEP20Burnable, Ownable {
    mapping(address => bool) public whitelister; 
    uint256 public whitelistersLength;
    uint256 public totalTokenSupply;
    uint256 public tokenRate;
    uint256 public preIcoStart;
    uint256 public preIcoStageOneEnd;
    uint256 public preIcoStageTwoEnd;
    uint256 public stageOneSupply;
    uint256 public stageTwoSupply;
    uint256 public weiRaised;
    bool public preIcoStageOneEnded;
    bool public preIcoStageTwoEnded;
    // for pancake swap add liquidity function
    uint public liquidityLimitA;
    uint public liquidityLimitB;
    address public routerAddress;
    address public tokenAAddress;
    address public tokenBAddress;
    address public toAddress;
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
    constructor( uint _liquidityLimitA, uint _liquidityLimitB, address _routerAddress, address _tokenAAddress, address _tokenBAddress, address _toAddress) BEP20("TKNSOFT", "TKN") {
        preIcoStart = block.timestamp;
        preIcoStageOneEnd = preIcoStart + 1 weeks;
        preIcoStageTwoEnd = preIcoStageOneEnd + 1 weeks;
        weiRaised = 0;
        tokenRate = 25;
        totalTokenSupply = 1000 ether;
        stageOneSupply = SafeMath.mul(SafeMath.div(totalTokenSupply,100),25);
        stageTwoSupply = SafeMath.mul(SafeMath.div(totalTokenSupply,100),25);
        // Set values while deploying smart contract
        liquidityLimitA = _liquidityLimitA;
        liquidityLimitB = _liquidityLimitB;
        routerAddress = _routerAddress;
        tokenAAddress = _tokenAAddress;
        tokenBAddress = _tokenBAddress;
        toAddress = _toAddress;
    }
    modifier icoIsEnded(){
        require(preIcoStageOneEnded == false && preIcoStageTwoEnded == false);
        _;
    }
    receive () external payable {
     purchaseTokens(msg.sender);
    }
    function purchaseTokens(address _beneficiary) public payable icoIsEnded {
        uint256 weiAmount = msg.value;
        uint256 tokens = 0;
        require(_beneficiary != address(0x0));
        if(block.timestamp >= preIcoStart && block.timestamp < preIcoStageOneEnd && stageOneSupply > 0 && preIcoStageOneEnded == false){
            require(whitelister[_beneficiary],"You are not whitelisted by the owner.");
            tokens = SafeMath.add(tokens, SafeMath.mul(weiAmount,tokenRate));
            stageOneSupply = SafeMath.sub(stageOneSupply,tokens);
        }else if(block.timestamp >= preIcoStageOneEnd && block.timestamp < preIcoStageTwoEnd && stageTwoSupply > 0 && preIcoStageTwoEnded == false){
            tokens = SafeMath.add(tokens, SafeMath.mul(weiAmount,tokenRate));
            stageTwoSupply = SafeMath.sub(stageTwoSupply,tokens);
        }else{
            revert("ICO Sale ended.");
        }
        weiRaised = SafeMath.add(weiRaised,weiAmount);
        _mint(_beneficiary, tokens);
        emit TokenPurchase(_beneficiary, weiAmount, tokens);
    }
    function endPreIcoStageOne() external onlyOwner { preIcoStageOneEnded = true; }
    function endPreIcoStageTwo() external onlyOwner { preIcoStageTwoEnded = true; }
    function isWhiteLister(address _beneficiary) public view returns (bool) { return whitelister[_beneficiary]; }
    function addWhitelisters(address[] memory _whitelister) external onlyOwner {
        for(uint8 i=0; i<_whitelister.length;i++){
            if(!isWhiteLister(_whitelister[i])){
                whitelister[_whitelister[i]] = true;
                whitelistersLength++;
            }
        }
    }
    function removeWhitelisters(address[] memory _whitelister) external onlyOwner {
        for(uint8 i=0; i<_whitelister.length;i++) {
            if(isWhiteLister(_whitelister[i])){
                whitelister[_whitelister[i]] = false;
                whitelistersLength++;
            }
        }
    }
    function setRouterAddress(address _router) public onlyOwner{ routerAddress = _router; }
    function setLiquidtyA(uint _liquidityLimitA) public onlyOwner{ liquidityLimitA = _liquidityLimitA; }
    function setLiquidtyB(uint _liquidityLimitB) public onlyOwner{ liquidityLimitB = _liquidityLimitB; }
    function setTokenA(address _tokenAAddress) public onlyOwner{ tokenAAddress = _tokenAAddress; }
    function setTokenB(address _tokenBAddress) public onlyOwner{ tokenBAddress = _tokenBAddress; }
    function setToAddress(address _toAddress) public onlyOwner{ toAddress = _toAddress; }
    function addLiquidityToPancakeSwap() public returns (uint liquidityLimitA_, uint liquidityLimitB_, uint deadline_) {
       address pancakeRouter = routerAddress != address(0) ? routerAddress : 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
       uint deadline = block.timestamp + 1 days;
       IBEP20(tokenAAddress).approve(pancakeRouter, liquidityLimitA);
       IBEP20(tokenBAddress).approve(pancakeRouter, liquidityLimitB);
       IPancakeRouter01 router = IPancakeRouter01(pancakeRouter);
       return router.addLiquidity(tokenAAddress, tokenBAddress, liquidityLimitA, liquidityLimitB, liquidityLimitA, liquidityLimitB, toAddress, deadline);
    }
}