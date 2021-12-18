/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// File: contracts\Context.sol

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
// File: contracts\Ownable.sol

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
// File: contracts\IERC20.sol

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
// File: contracts\SafeMath.sol

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
// File: contracts\IUniswapV2Factory.sol

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
// File: contracts\IUniswapV2Router02.sol

interface IUniswapV2Router02 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
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
// File: contracts\ShieldNetETH.sol

contract ShieldNetworkToken is IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;
    mapping(address => uint256) private cooldown;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _feeReflection = 1;
    uint256 private _feeTeam = 8;
    uint256 private _feeLiquidity = 3;
    address payable private _marketingWallet;
    address payable private _devFundWallet;
    // ETH balance required to execute swapAndLiquify
    uint256 _swapThreshold = 500_000 * 10**9; // 500k
    string private constant _name = "Shield Network Token";
    string private constant _symbol = "SHIELDNET";
    uint8 private constant _decimals = 9;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    uint256 private _maxTxAmount = _tTotal;
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event SwapAndLiquify(uint256 amountETH, uint256 amountToken);
    event SwapTokensForEth(uint256 tokenAmount, uint256 amountETH);
    event FeeSettingsModified();
    event ReflectionFeeModified(uint256 oldValue, uint256 newValue);
    event ExcludeFromFee(address account, bool exclude);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        _marketingWallet = payable(owner());
        _devFundWallet = payable(owner());
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        _isExcludedFromFee[_devFundWallet] = true;
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
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
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
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
    function setCooldownEnabled(bool onoff) external onlyOwner {
        cooldownEnabled = onoff;
    }
    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to] &&
                cooldownEnabled
            ) {
                // Cooldown
                require(amount <= _maxTxAmount);
                require(cooldown[to] < block.timestamp);
                cooldown[to] = block.timestamp + (30 seconds);
            }
            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                swapBack();
            }
        }
        uint256 tmpFeeReflect = _feeReflection;
        uint256 tmpFeeTeam = _feeTeam;
        uint256 tmpFeeLiquidity = _feeLiquidity;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            _feeReflection = 0;
            _feeTeam = 0;
            _feeLiquidity = 0;
        }
        _tokenTransfer(from, to, amount);
        // set back fee settings
        _feeReflection = tmpFeeReflect;
        _feeTeam = tmpFeeTeam;
        _feeLiquidity = tmpFeeLiquidity;
    }
    function swapBack() private lockTheSwap {
        uint256 tokenBalance = balanceOf(address(this));
        uint256 totalFees = _feeTeam.add(_feeLiquidity);
        uint256 amountToLiquify = tokenBalance
            .mul(_feeLiquidity)
            .div(totalFees)
            .div(2);
        uint256 amountToSwap = tokenBalance.sub(amountToLiquify);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        uint256 balanceBefore = address(this).balance;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 totalETHFee = totalFees.sub(_feeLiquidity.div(2));
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 teamETH = amountETH.mul(_feeTeam).div(totalETHFee);
        uint256 liquidityETH = amountETH.sub(teamETH);
        sendETHToTeam(teamETH);
        if (liquidityETH > 0 && amountToLiquify > 0) {
            uniswapV2Router.addLiquidityETH{value: liquidityETH}(
                address(this),
                amountToLiquify,
                0,
                0,
                owner(),
                block.timestamp
            );
        }
        if (address(this).balance > 0) {
            (bool success, ) = _marketingWallet.call{
                value: address(this).balance
            }("");
            require(success || !success);
        }
        emit SwapAndLiquify(amountETH, amountToLiquify);
    }
    function sendETHToTeam(uint256 amount) private {
        (bool successTx1, ) = _marketingWallet.call{
            value: amount.div(2),
            gas: 30000
        }("");
        (bool successTx2, ) = _devFundWallet.call{
            value: amount.div(2),
            gas: 30000
        }("");
        require(successTx1 || !successTx1 || successTx2 || !successTx2); // supress warnings
    }
    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 // bsc testnet pancakeswap v2 router
            // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D // eth mainnet uniswap v2 router
        );
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        swapEnabled = true;
        cooldownEnabled = true;
        _maxTxAmount = 50000000000000000 * 10**9;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }
    function setBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _transferStandard(sender, recipient, amount);
    }
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTaxes(tTeam + tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _takeTaxes(uint256 tTaxes) private {
        uint256 currentRate = _getRate();
        uint256 rTaxes = tTaxes.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTaxes);
        emit Transfer(_msgSender(), address(this), tTaxes);
    }
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    receive() external payable {}
    // function manualswap() external {
    //     require(_msgSender() == _marketingWallet);
    //     uint256 contractBalance = balanceOf(address(this));
    //     swapTokensForEth(contractBalance);
    // }
    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam,
            uint256 tLiquidity
        )
    {
        (tTransferAmount, tFee, tTeam, tLiquidity) = _getTValues(
            tAmount,
            _feeReflection,
            _feeTeam,
            _feeLiquidity
        );
        uint256 currentRate = _getRate();
        (rAmount, rTransferAmount, rFee) = _getRValues(
            tAmount,
            tFee,
            tTeam,
            tLiquidity,
            currentRate
        );
    }
    function _getTValues(
        uint256 tAmount,
        uint256 taxFee,
        uint256 teamFee,
        uint256 liquidityFee
    )
        private
        pure
        returns (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam,
            uint256 tLiquidity
        )
    {
        tFee = tAmount.mul(taxFee).div(100);
        tTeam = tAmount.mul(teamFee).div(100);
        tLiquidity = tAmount.mul(liquidityFee).div(100);
        tTransferAmount = tAmount.sub(tFee).sub(tTeam).sub(tLiquidity);
    }
    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee
        )
    {
        rAmount = tAmount.mul(currentRate);
        rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        rTransferAmount = rAmount.sub(rFee).sub(rTeam).sub(rLiquidity);
    }
    function _getRate() private view returns (uint256 rate) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        rate = rSupply.div(tSupply);
    }
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    function excludeFromFee(address account, bool exclude) external onlyOwner {
        _isExcludedFromFee[account] = exclude;
        emit ExcludeFromFee(account, exclude);
    }
    function setReflectionFee(uint256 feeReflection) external onlyOwner {
        emit ReflectionFeeModified(_feeReflection, feeReflection);
        _feeReflection = feeReflection;
    }
    function setFeeSettings(uint256 feeTeam, uint256 feeLiquidity) external onlyOwner {
        _feeTeam = feeTeam;
        _feeLiquidity = feeLiquidity;
        emit FeeSettingsModified();
    }
    function setWalletSettings(address marketingWallet, address devFundWallet) external onlyOwner {
        require(marketingWallet != address(0), "marketingWallet: zero address");
        require(devFundWallet != address(0), "devFundWallet: zero address");
        _marketingWallet = payable(marketingWallet);
        _devFundWallet = payable(devFundWallet);
    }
    function manualSwap() external onlyOwner {
        swapBack();
    }
}