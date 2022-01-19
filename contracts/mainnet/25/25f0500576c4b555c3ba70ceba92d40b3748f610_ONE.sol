/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

/* SPDX-License-Identifier: MIT 

    ______    _____  ___    _______      __   __  ___     ______     _______   ___       ________   
   /    " \  (\"   \|"  \  /"     "|    |"  |/  \|  "|   /    " \   /"      \ |"  |     |"      "\  
  // ____  \ |.\\   \    |(: ______)    |'  /    \:  |  // ____  \ |:        |||  |     (.  ___  :) 
 /  /    ) :)|: \.   \\  | \/    |      |: /'        | /  /    ) :)|_____/   )|:  |     |: \   ) || 
(: (____/ // |.  \    \. | // ___)_      \//  /\'    |(: (____/ //  //      /  \  |___  (| (___\ || 
 \        /  |    \    \ |(:      "|     /   /  \\   | \        /  |:  __   \ ( \_|:  \ |:       :) 
  \"_____/    \___|\____\) \_______)    |___/    \___|  \"_____/   |__|  \___) \_______)(________/  

Twitter: https://twitter.com/oneworlderc20
Telegram: t.me/OneWorld_Quest
Website: https://oneworld.quest/                                                                                                  
*/

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract ONE is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "ONE WORLD";
    string private constant _symbol = "ONEWORLD";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 public _totalSupply = 1000000000 * 10**9;

    //Buy Fee
    uint256 private _taxFeeOnBuy = 12; // 10 after the first 48h

    //Sell Fee
    uint256 private _taxFeeOnSell = 24; // 12 after the first 48h

    //Original Fee
    uint256 private _taxFee = _taxFeeOnSell;

    uint256 private _previoustaxFee = _taxFee;

    mapping(address => bool) public blacklist;

    address payable public marketingAddress = payable(0x2c12Bafb9d1652644Ce052f7E20b6B6428c499E0);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = true;
    
    uint256 public _maxTxAmount = 7500000 * 10**9; // 0.75%
    uint256 public _maxWalletSize = 20000000 * 10**9; // 2%
    uint256 public _tokenSwapThreshold = 1000000 * 10**9; //0.1%

    event MaxTxAmountUpdated(uint256 _maxTxAmount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _balances[_msgSender()] = _totalSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingAddress] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function launch() public onlyOwner {    
        tradingOpen = true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function removeAllFee() private {
        if (_taxFee == 0) return;

        _previoustaxFee = _taxFee;

        _taxFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previoustaxFee;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    // Transfer functions
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            //Trade start check
            require(tradingOpen,"TOKEN: This token isn't tradable yet");
            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
            require(!blacklist[from] && !blacklist[to],"TOKEN: Your account is blacklisted!");
            
            if (to != uniswapV2Pair) {
                require(
                    balanceOf(to) + amount < _maxWalletSize,
                    "TOKEN: Balance exceeds wallet size!"
                );
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool shouldSwap = contractTokenBalance >= _tokenSwapThreshold;

            if (contractTokenBalance >= _maxTxAmount) {
                contractTokenBalance = _maxTxAmount;
            }

            if (shouldSwap && !inSwap && from != uniswapV2Pair && swapEnabled) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHtoMarketing(address(this).balance);
                }
            }
        }

        bool takeFee = true;

        //Transfer Tokens
        if (
            (_isExcludedFromFee[from] || _isExcludedFromFee[to]) ||
            (from != uniswapV2Pair && to != uniswapV2Pair)
        ) {
            takeFee = false;
        } else {
            //Set Fee for Buys
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _taxFee = _taxFeeOnBuy;
            }

            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _taxFee = _taxFeeOnSell;
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 feeAmount = amount.mul(_taxFee).div(100);
        uint256 remainingAmount = amount.sub(feeAmount);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        _balances[recipient] = _balances[recipient].add(remainingAmount);
        emit Transfer(sender, recipient, remainingAmount);
    }

    // Swap and send functions
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHtoMarketing(uint256 amount) private {
        (bool success, ) = marketingAddress.call{value: amount}("");
        require(success, "Tx Failed");
    }

    function manualswap() external {
        require(_msgSender() == marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == marketingAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHtoMarketing(contractETHBalance);
    }

    // Blacklist and whitelist
    function blacklistAddresses(address[] memory _blacklist) public onlyOwner {
        for (uint256 i = 0; i < _blacklist.length; i++) {
            blacklist[_blacklist[i]] = true;
        }
    }

    function whitelistAddress(address whitelist) external onlyOwner {
        blacklist[whitelist] = false;
    }

    // Fee related functions
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    // Setters
    function setExcludeFromFee(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = excluded;
    }

    function setMarketingWalletAddress(address payable _marketingAddress)
        external
        onlyOwner
    {
        marketingAddress = _marketingAddress;
    }

    function setFee(
        uint256 taxFeeOnBuy,
        uint256 taxFeeOnSell
    ) public onlyOwner {
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
    }

    function setMinSwapTokensThreshold(uint256 tokenSwapThreshold)
        public
        onlyOwner
    {
        _tokenSwapThreshold = tokenSwapThreshold;
    }

    function setSwapEnabled(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }

    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }

    // Enable the current contract to receive ETH
    receive() external payable {}
}