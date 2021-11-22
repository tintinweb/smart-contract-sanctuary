/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

/* SPDX-License-Identifier: Unlicensed */
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

contract Megapolis is Context, IERC20, Ownable {
    string private constant _name = unicode"Megapolis";
    string private constant _symbol = "MPC";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant numTokensSellToAddToLiquidity = 500000 * 10**9;
    uint256 private constant _tTotal = 100000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 public _liquiditySellFee = 10;
    uint256 private _previousLiquiditySellFee = _liquiditySellFee;

    uint256 public _liquidityFee = 0;

    uint256 public _liquidityBuyFee = 5;
    uint256 private _previousLiquidityBuyFee = _liquiditySellFee;

    address payable private _devWallet;
    address payable private _marketingWallet;
    address payable private _operationWallet;
    address public _routerAddress;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private inSwap = false;
    uint256 public _maxTxAmount = _tTotal;
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address router) {
        _routerAddress = router;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_routerAddress] = true;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            _routerAddress
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
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
        require(
            _allowances[sender][_msgSender()] >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function setIsExcludedFromFee(address _address, bool _isExcluded)
        external
        onlyOwner
    {
        _isExcludedFromFee[_address] = _isExcluded;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }
    
    function setDevAddress(address payable _address) external onlyOwner {
        _devWallet = _address;
    }

    function setMarketingAddress(address payable _address) external onlyOwner {
        _marketingWallet = _address;
    }

    function setOperationAddress(address payable _address) external onlyOwner {
        _operationWallet = _address;
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
        return rAmount / currentRate;
    }

    function removeAllFee() private {
        if (_liquiditySellFee == 0 && _liquidityBuyFee == 0) return;
        _previousLiquiditySellFee = _liquiditySellFee;
        _previousLiquidityBuyFee = _liquidityBuyFee;
        _liquidityBuyFee = 0;
        _liquiditySellFee = 0;
    }

    function restoreAllFee() private {
        _liquiditySellFee = _previousLiquiditySellFee;
        _liquidityBuyFee = _previousLiquidityBuyFee;
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
        bool takeFee = false;
        _liquidityFee = 0;
        if (from != owner() && to != owner()) {
            // buy handler
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                require(
                    amount <= _maxTxAmount,
                    "Amount larger than max tx amount!"
                );
                takeFee = true;
                _liquidityFee = _liquidityBuyFee;
            }

            // sell handler
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                from != address(uniswapV2Router)
            ) {
                require(
                    amount <= (balanceOf(uniswapV2Pair) * 3) / 100 &&
                        amount <= _maxTxAmount,
                    "Slippage is over MaxTxAmount!"
                );
                takeFee = true;
                _liquidityFee = _liquiditySellFee;
                uint256 contractTokenBalance = balanceOf(address(this));
                bool overMinTokenBalance = contractTokenBalance >=
                    numTokensSellToAddToLiquidity;
                if (overMinTokenBalance) {
                    swapTokensForEth(numTokensSellToAddToLiquidity);
                }
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee();
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = address(this).balance - initialBalance; // 6.0%
        uint256 dev = amount / 4;                                // 1.5%
        uint256 marketing = amount / 4;                          // 1.5%
        uint256 operation = amount - dev - marketing;            // 3.0%
        _devWallet.transfer(dev);
        _marketingWallet.transfer(marketing);
        _operationWallet.transfer(operation);
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
        uint256 tAmount
    ) private {
        // _getTValues
        uint256 tFeePercentage = (_liquidityFee / 10) * 4; //  4.0% to holders
        uint256 tFee = (tAmount * tFeePercentage) / 100;

        uint256 tLiquidityFeePercentage = (_liquidityFee / 10) * 6; // 6.0% to BNB swap
        uint256 tLiquidityFee = (tAmount * tLiquidityFeePercentage) / 100;
        uint256 tTransferAmount = tAmount - tLiquidityFee - tFee;
        // _getRValues
        uint256 currentRate = _getRate();
        uint256 rFee = tFee * currentRate;
        uint256 rAmount = tAmount * currentRate;
        uint256 rLiquidityFee = tLiquidityFee * currentRate;
        uint256 rTransferAmount = rAmount - rLiquidityFee - rFee;

        _calculateReflectTransfer(sender, recipient, rAmount, rTransferAmount);
        _reflectFee(rFee, tFee);
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidityFee;
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _calculateReflectTransfer(
        address sender,
        address recipient,
        uint256 rAmount,
        uint256 rTransferAmount
    ) private {
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
    }

    // allow contract to receive deposits
    receive() external payable {}

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setBuyTax(uint256 buyFee) external onlyOwner {
        require(buyFee < 16, "Amount must be less than 16");
        _liquidityBuyFee = buyFee;
        _previousLiquidityBuyFee = buyFee;
    }

    function setSellTax(uint256 sellFee) external onlyOwner {
        require(sellFee < 16, "Amount must be less than 16");
        _liquiditySellFee = sellFee;
        _previousLiquiditySellFee = sellFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxAmount = (_tTotal * maxTxPercent) / (10**2);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function withdrawResidualBnb(address newAddress) external onlyOwner {
        payable(newAddress).transfer(address(this).balance);
    }

    function transferResidualErc20(IERC20 token, address to)
        external
        onlyOwner
    {
        uint256 erc20balance = token.balanceOf(address(this));
        token.transfer(to, erc20balance);
    }
}