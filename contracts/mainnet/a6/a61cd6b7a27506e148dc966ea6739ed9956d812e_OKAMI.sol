/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

/*
 * 🔥🔥 Ōkami Inu 🔥🔥
 * Utility driven meme token

 * Telegram :
 * Website : 

 **** Tokenomics ****

 ** Buy Fee/Default Sell Fee : 12% (10% TX 2% Liquidity)
 ** 1 Hour Sell Fee : 24% (12% TX 12% Liquidity)
 ** 24 Hour Sell Fee : 18% (12% TX 6% Liquidity)
 ** Holder Appreciation : After 30 days 0% sell fee
 
 **** Bot and Whale Protection ****

 ** .5% Max tx
 ** 1.5% Max wallet
 ** 30 Second cooldown between buys
 ** 0-2 Block buys automatically blacklisted
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 9;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract OKAMI is ERC20, Ownable {
    using SafeMath for uint256;

    address public constant DEAD_ADDRESS = address(0xdead);
    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public buyLiquidityFee = 2;
    uint256 public sellLiquidityFee = 2;
    uint256 public buyTxFee = 10;
    uint256 public sellTxFee = 10;

    uint256 public defaultSellLiquidityFee = 2;
    uint256 public defaultSellTxFee = 10;

    uint256 public hourSellLiquidityFee = 12;
    uint256 public hourSellTxFee = 12;

    uint256 public daySellLiquidityFee = 6;
    uint256 public daySellTxFee = 12;

    uint256 public tokensForLiquidity;
    uint256 public tokensForTax;

    uint256 public _tTotal = 10**9 * 10**9;                         // 1 billion
    uint256 public swapAtAmount = _tTotal.mul(50).div(10000);       // 0.10% of total supply
    uint256 public maxTxLimit = _tTotal;                            // 0.5% of total supply set in open trading
    uint256 public maxWalletLimit = _tTotal;                        // 1% of total supply set in open trading

    address private dev;
    address private liquidity;

    address public uniswapV2Pair;

    uint256 public launchBlock;

    bool private swapping;
    bool public isLaunched;
    bool private cooldownEnabled = false;
    bool private useBuyMap = true;

    // exclude from fees
    mapping (address => bool) public isExcludedFromFees;

    // exclude from max transaction amount
    mapping (address => bool) public isExcludedFromTxLimit;

    // exclude from max wallet limit
    mapping (address => bool) public isExcludedFromWalletLimit;

    // if the account is blacklisted from transacting
    mapping (address => bool) public isBlacklisted;

    // buy map for timed sell tax
    mapping (address => uint256) public _buyMap;

    // mapping for cooldown
    mapping (address => uint) public cooldown;

    constructor() public ERC20("Ōkami Inu", "Ōkami") {

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _approve(address(this), address(uniswapV2Router), type(uint256).max);


        // exclude from fees, wallet limit and transaction limit
        excludeFromAllLimits(owner(), true);
        excludeFromAllLimits(address(this), true);
        excludeFromWalletLimit(uniswapV2Pair, true);

        dev = payable(0x1f30Eb1644Cb6528d0ab609815EE7930a0F5720c);
        liquidity = payable(0x1f30Eb1644Cb6528d0ab609815EE7930a0F5720c);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), _tTotal);
    }

    function excludeFromFees(address account, bool value) public onlyOwner() {
        require(isExcludedFromFees[account] != value, "Fees: Already set to this value");
        isExcludedFromFees[account] = value;
    }

    function excludeFromTxLimit(address account, bool value) public onlyOwner() {
        require(isExcludedFromTxLimit[account] != value, "TxLimit: Already set to this value");
        isExcludedFromTxLimit[account] = value;
    }

    function excludeFromWalletLimit(address account, bool value) public onlyOwner() {
        require(isExcludedFromWalletLimit[account] != value, "WalletLimit: Already set to this value");
        isExcludedFromWalletLimit[account] = value;
    }

    function excludeFromAllLimits(address account, bool value) public onlyOwner() {
        excludeFromFees(account, value);
        excludeFromTxLimit(account, value);
        excludeFromWalletLimit(account, value);
    }

    function setBuyFee(uint256 liquidityFee, uint256 txFee) external onlyOwner() {
	require(liquidityFee.add(txFee) <= 12, "Total buy fee can not be more than 12");
        buyLiquidityFee = liquidityFee;
        buyTxFee = txFee;
    }

    function setSellFee(uint256 liquidityFee, uint256 txFee) external onlyOwner() {
        require(liquidityFee.add(txFee) <= 12, "Total default fee can not be more than 12");
        sellLiquidityFee = liquidityFee;
        sellTxFee = txFee;

        defaultSellLiquidityFee = liquidityFee;
        defaultSellTxFee = txFee;
    }

    function setHourSellFee(uint256 liquidityFee, uint256 txFee) external onlyOwner() {
        require(liquidityFee.add(txFee) <= 24, "Total default fee can not be more than 25");
        hourSellLiquidityFee = liquidityFee;
        hourSellTxFee = txFee;
    }

    function setDaySellFee(uint256 liquidityFee, uint256 txFee) external onlyOwner() {
        require(liquidityFee.add(txFee) <= 18, "Total default fee can not be more than 18");
        daySellLiquidityFee = liquidityFee;
        daySellTxFee = txFee;
    }

    function setCooldownEnabled(bool _enabled) external onlyOwner() {
        cooldownEnabled = _enabled;
    }

   function setUseBuyMap(bool _enabled) external onlyOwner() {
        useBuyMap = _enabled;
    }

    function setMaxTxLimit(uint256 newLimit) external onlyOwner() {
        require(newLimit > 0, "max tx can not be 0");
        maxTxLimit = newLimit * (10**9);
    }

    function setMaxWalletLimit(uint256 newLimit) external onlyOwner() {
        require(newLimit > 0, "max wallet can not be 0");
        maxWalletLimit = newLimit * (10**9);
    }

    function setSwapAtAmount(uint256 amountToSwap) external onlyOwner() {
        swapAtAmount = amountToSwap * (10**9);
    }

    function updateDevWallet(address newWallet) external onlyOwner() {
        dev = newWallet;
    }

    function updateLiqWallet(address newWallet) external onlyOwner() {
        liquidity = newWallet;
    }

    function addBlacklist(address account) external onlyOwner() {
        require(!isBlacklisted[account], "Blacklist: Already blacklisted");
        require(account != uniswapV2Pair, "Cannot blacklist pair");
        _setBlacklist(account, true);
    }

    function removeBlacklist(address account) external onlyOwner() {
        require(isBlacklisted[account], "Blacklist: Not blacklisted");
        _setBlacklist(account, false);
    }

    function manualswap() external onlyOwner() {
        uint256 totalTokensForFee = tokensForLiquidity + tokensForTax;
        swapBack(totalTokensForFee);
    }
    
    function manualsend() external onlyOwner(){
        uint256 contractETHBalance = address(this).balance;
        payable(address(dev)).transfer(contractETHBalance);
    }
    

    function openTrading() external onlyOwner() {
        require(!isLaunched, "Contract is already launched");
        isLaunched = true;
        launchBlock = block.number;
        cooldownEnabled = true;
        maxTxLimit = _tTotal.mul(50).div(10000);        
        maxWalletLimit = _tTotal.mul(100).div(10000);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(amount <= maxTxLimit || isExcludedFromTxLimit[from] || isExcludedFromTxLimit[to], "Tx Amount too large");
        require(balanceOf(to).add(amount) <= maxWalletLimit || isExcludedFromWalletLimit[to], "Transfer will exceed wallet limit");
        require(isLaunched || isExcludedFromFees[from] || isExcludedFromFees[to], "Waiting to go live");
        require(!isBlacklisted[from], "Sender is blacklisted");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 totalTokensForFee = tokensForLiquidity + tokensForTax;
        bool canSwap = totalTokensForFee >= swapAtAmount;

        if(
            from != uniswapV2Pair &&
            canSwap &&
            !swapping
        ) {
            swapping = true;
            swapBack(totalTokensForFee);
            swapping = false;
        } else if(
            from == uniswapV2Pair &&
            to != uniswapV2Pair &&
            block.number < launchBlock + 1 &&
            !isExcludedFromFees[to]
        ) {
            _setBlacklist(to, true);
        }

        bool takeFee = !swapping;

        if(isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 fees;
            // on sell
            if (to == uniswapV2Pair) {
                if(useBuyMap){
                    if (_buyMap[from] != 0 &&
                        (_buyMap[from] + (1 hours) >= block.timestamp))  {
                        sellLiquidityFee = hourSellLiquidityFee;
                        sellTxFee = hourSellTxFee;
                        _buyMap[from] = block.timestamp;
                    } else if (_buyMap[from] != 0 &&
                        (_buyMap[from] + (24 hours) >= block.timestamp)) {
                        sellLiquidityFee = daySellLiquidityFee;
                        sellTxFee = daySellTxFee;
                        _buyMap[from] = block.timestamp;
                    } else if (_buyMap[from] != 0 &&
                        (_buyMap[from] + (30 days) >= block.timestamp)) {
                        sellLiquidityFee = 0;
                        sellTxFee = 0;
                    } else {
                        sellLiquidityFee = defaultSellLiquidityFee;
                        sellTxFee = defaultSellTxFee;
                    }
                } else {
                    sellLiquidityFee = defaultSellLiquidityFee;
                    sellTxFee = defaultSellTxFee;
                }
              
                uint256 sellTotalFees = sellLiquidityFee.add(sellTxFee);
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity = tokensForLiquidity.add(fees.mul(sellLiquidityFee).div(sellTotalFees));
                tokensForTax = tokensForTax.add(fees.mul(sellTxFee).div(sellTotalFees));
            }
            // on buy & wallet transfers
            else {
                if(cooldownEnabled){
                    require(cooldown[to] < block.timestamp);
                    cooldown[to] = block.timestamp + (30 seconds);
                }
                if (useBuyMap && _buyMap[to] == 0) {
                    _buyMap[to] = block.timestamp;
                }
                uint256 buyTotalFees = buyLiquidityFee.add(buyTxFee);
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity = tokensForLiquidity.add(fees.mul(buyLiquidityFee).div(buyTotalFees));
                tokensForTax = tokensForTax.add(fees.mul(buyTxFee).div(buyTotalFees));
            }

            if(fees > 0){
                super._transfer(from, address(this), fees);
                amount = amount.sub(fees);
            }
        }

        super._transfer(from, to, amount);
    }

    function swapBack(uint256 totalTokensForFee) private {
        uint256 toSwap = swapAtAmount;

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = toSwap.mul(tokensForLiquidity).div(totalTokensForFee).div(2);
        uint256 taxTokens = toSwap.sub(liquidityTokens).sub(liquidityTokens);
        uint256 amountToSwapForETH = toSwap.sub(liquidityTokens);

        _swapTokensForETH(amountToSwapForETH);

        uint256 ethBalance = address(this).balance;
        uint256 ethForTax = ethBalance.mul(taxTokens).div(amountToSwapForETH);
        uint256 ethForLiquidity = ethBalance.sub(ethForTax);

        tokensForLiquidity = tokensForLiquidity.sub(liquidityTokens.mul(2));
        tokensForTax = tokensForTax.sub(toSwap.sub(liquidityTokens.mul(2)));

        payable(address(dev)).transfer(ethForTax);
        _addLiquidity(liquidityTokens, ethForLiquidity);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidity,
            block.timestamp
        );
    }

    function _swapTokensForETH(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _setBlacklist(address account, bool value) internal {
        isBlacklisted[account] = value;
    }

    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent){
        require(_token != address(this), "Can't withdraw native tokens");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }
    

    receive() external payable {}
}