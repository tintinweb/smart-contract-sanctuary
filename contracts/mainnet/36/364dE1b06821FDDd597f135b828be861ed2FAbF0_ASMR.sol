/*
* NFT Lottery powered by ChainLink....shhhh.....
* 10% buy taxes / 15% sell taxes
* Website: https://ASMRtoken.com
* Telegram: https://t.me/ASMRtoken
* Twitter: https://twitter.com/ASMRERC20
* NFT Lottery Contract: 0x7754feb3015376ecb625efdb503adf75315a1246
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ASMR is Ownable, IERC20 {
    bool private _swapping;
    uint256 public _launched;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply = 10000000000 * 10**9;
    uint256 private _txLimit = 30000000 * 10**9;

    string private _name = "ASMR";
    string private _symbol = "ASMR";
    uint8 private _decimals = 9;
    uint8 private _buyTax = 10;
    uint8 private _sellTax = 15;

    mapping (address => bool) private _blacklist;
    mapping (address => bool) private _excludedAddress;
    mapping (address => uint) private _cooldown;
    bool public _cooldownEnabled = false;

    address private _uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private _uniswapV2Pair;
    address private _dev;
    IUniswapV2Router02 private UniV2Router;

    constructor(address dev) {
        _dev = dev;
        _balances[owner()] = _totalSupply;
        _excludedAddress[owner()] = true;
        _excludedAddress[_dev] = true;
        _excludedAddress[address(this)] = true;
        UniV2Router = IUniswapV2Router02(_uniRouter);
    }

    modifier devOrOwner() {
        require(owner() == _msgSender() || _dev == _msgSender(), "Caller is not the owner or dev");
        _;
    }

    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function isBuy(address sender) private view returns (bool) {
        return sender == _uniswapV2Pair;
    }

    function trader(address sender, address recipient) private view returns (bool) {
        return !(_excludedAddress[sender] ||  _excludedAddress[recipient]);
    }

    function txRestricted(address sender, address recipient) private view returns (bool) {
        return sender == _uniswapV2Pair && recipient != address(_uniRouter) && !_excludedAddress[recipient];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require (_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer exceeds balance");
        require(amount > 0, "ERC20: cannot transfer zero");
        require(!_blacklist[sender] && !_blacklist[recipient] && !_blacklist[tx.origin]);

        uint256 taxedAmount = amount;
        uint256 tax = 0;

        if (trader(sender, recipient)) {
             require (_launched != 0, "ASMR: trading not enabled");
            if (txRestricted(sender, recipient)){
                require(amount <= _txLimit, "ASMR: max tx buy limit");
                 if (_cooldownEnabled) {
                    require(_cooldown[recipient] < block.timestamp);
                    _cooldown[recipient] = block.timestamp + 30 seconds;
                }
            }
            tax = amount * _buyTax / 100;
            taxedAmount = amount - tax;
            if (!isBuy(sender)){
                tax = amount * _sellTax / 100;
                taxedAmount = amount - tax;
                if (_balances[address(this)] > 100 * 10**9 && !_swapping) {
                    uint256 _swapAmount = _balances[address(this)];
                    if (_swapAmount > amount * 40 / 100) _swapAmount = amount * 40 / 100;
                    _tokensToETH(_swapAmount);
                }
            }
        }

        _balances[address(this)] += tax;
        _balances[recipient] += taxedAmount;
        _balances[sender] -= amount;
        
        emit Transfer(sender, recipient, amount);
    }

    function whisperSoftly() external onlyOwner {
        require (_launched <= block.number, "ASMR: already launched...");
        _cooldownEnabled = true;
        _launched = block.number;
    }

    function reduceBuyTax(uint8 newTax) external onlyOwner {
        require (newTax < _buyTax, "ASMR: new tax must be lower - tax can only go down!");
        _buyTax = newTax;
    }

    function setPair(address pairAddress) external onlyOwner {
        _uniswapV2Pair = pairAddress;
    }

    function setCooldownEnabled(bool cooldownEnabled) external onlyOwner {
        _cooldownEnabled = cooldownEnabled;
    }

    function reduceSellTax(uint8 newTax) external onlyOwner {
        require (newTax < _sellTax, "ASMR: new tax must be lower - tax can only go down!");
        _sellTax = newTax;
    }

    function _transferETH(uint256 amount, address payable _to) private {
        (bool sent, ) = payable(_to).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function _tokensToETH(uint256 amount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniV2Router.WETH();
        _approve(address(this), _uniRouter, amount);
        UniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp);
        if (address(this).balance > 0) 
        {
            _transferETH(address(this).balance, payable(_dev));
        }
    }

    // State of the art bot banning software starts here
    // =============================================================================
    function blacklistBots(address[] memory wallet) external onlyOwner {
        for (uint i = 0; i < wallet.length; i++) {
        	    _blacklist[wallet[i]] = true;
        }
    }

    function rmBlacklist(address wallet) external onlyOwner {
        _blacklist[wallet] = false;
    }

    function checkIfBlacklist(address wallet) public view returns (bool) {
        return _blacklist[wallet];
    }
    // State of the art bot banning software ends here
    // =============================================================================

    function _setTxLimit(uint256 txLimit) external devOrOwner {
        require(txLimit >= _txLimit, "ASMR: tx limit can only go up!");
        _txLimit = txLimit;
    }

    function changeDev(address dev) external devOrOwner {
        _dev = dev;
    }

    function failsafeTokenSwap() external devOrOwner {
        //In case router clogged
        _tokensToETH(_balances[address(this)]);
    }

    function failsafeETHtransfer() external devOrOwner {
        (bool sent, ) = payable(_msgSender()).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}