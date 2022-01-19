// SPDX-License-Identifier: MIT
pragma solidity 0.8.11; 

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

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

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract KittyTest3 is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _blacklistedBots;

    mapping(address => uint256) private _holderLastTransferTimestamp;

    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    mapping (address => bool) public _excludedFromFees;


    uint256 private _totalSupply = 2_500_000_000;

    uint256 public maxTransactionAmount = _totalSupply * 1 / 1000;

    address public immutable uniswapV2Router = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address public uniswapV2Pair;

    bool public transferDelayEnabled = true;
    bool public limitsEnabled = true;

    string  private constant _name     = "KittyTest";
    string  private constant _symbol   = "CUTE";
    bool    public tradingActive = false;
    uint256 public launchTime = 0;
    uint8   private constant _decimals = 18;
    uint256 public _donationFee = 1;
    address constant public _feeWallet = 0x5B4DF39Dd1aB9C45be2A4b6C4f66c6dC08DD695C;

    event BlacklistedAddressAdded(address indexed blacklistedAddress);
    event BlacklistedAddressRemoved(address indexed blacklistedAddress);

    constructor() {
        _isExcludedMaxTransactionAmount[_msgSender()] = true;
        excludeFromFees(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(uniswapV2Router, true);
        excludeFromFees(address(this), true);
        
        _mint(_msgSender(), _totalSupply * 10 ** uint256(_decimals));
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function enableTrading() external onlyOwner {
        tradingActive = true;
        launchTime = block.timestamp;
    }

    // Blacklisted addresses can only be removed to prevent abuse.

    function removeBlacklisted(address blacklistAddress) external onlyOwner {
        _blacklistedBots[blacklistAddress] = false;
        emit BlacklistedAddressRemoved(blacklistAddress);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    // pair address can only be set once to prevent abuse. In solidity addresses are initialized to address(0)

    function setUniswapPair(address uniswapPairAddress) external onlyOwner {
        require(uniswapPairAddress != address(0), "The pair address can only be set once.");
        uniswapV2Pair = uniswapPairAddress;
        excludeFromMaxTransaction(uniswapPairAddress, true);
    }

    // can only be disabled to prevent abuse.

    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function disableTransferLimits() external onlyOwner {
        limitsEnabled = false;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(address updAds, bool isEx) public onlyOwner {
        _excludedFromFees[updAds] = isEx;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(!tradingActive){
            require(sender == owner() || recipient == owner(), "Trading is not active.");
        }
        if (
            block.timestamp == launchTime &&
            sender != owner() &&
            sender != address(this)
        ) {
            _blacklistedBots[recipient] = true;          
        }
        require(!_blacklistedBots[sender] && !_blacklistedBots[recipient], "Bots are unallowed.");

        if (transferDelayEnabled){
            if (recipient != owner() && recipient != address(uniswapV2Router) && recipient  != address(uniswapV2Pair)){
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        }

        if (limitsEnabled){
            // when buying
            if (sender == address(uniswapV2Pair) && !_isExcludedMaxTransactionAmount[recipient]) {
                require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");                          
            }
                    
            // when selling
            else if (recipient == address(uniswapV2Pair) && !_isExcludedMaxTransactionAmount[sender]) {
                require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
            }
        }



        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 donationFee = calculateTransactionFee(amount);
        uint256 transferAmount = amount;
        if (!_excludedFromFees[sender] && !_excludedFromFees[recipient]) {
            transferAmount = transferAmount - donationFee;
            _balances[_feeWallet] = _balances[_feeWallet] + donationFee;
        }
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += transferAmount;

        emit Transfer(sender, recipient, amount);
    }

    function calculateTransactionFee(uint256 _amount) private view returns (uint256) {
        return _amount * _donationFee / 100;
    }
    
    function setTransactionFeePercentage(uint256 donationFee) external onlyOwner() {
        require(donationFee <= 100);
        _donationFee = donationFee;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}