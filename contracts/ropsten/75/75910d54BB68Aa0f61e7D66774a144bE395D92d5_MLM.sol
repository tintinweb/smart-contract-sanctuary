/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// https://MagicLambo.Money - The first DeFi MLM
// Main token contract

// SPDX-License-Identifier: MIT
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
}

contract MLM is Context, IERC20, Ownable {
    //========================= Variables =========================
    using SafeMath for uint256;

    string private constant _name = "Magic Lambo Money";
    string private constant _symbol = "MLM";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) public _blacklist;

    uint256 private constant MAX = ~uint256(0);
    uint256 public _totalSupply = 10000000 * 10**9;
    uint256 public _devTokenAllocation;
    uint256 public _treasuryTokenAllocation;

    uint16 private _devFeeOnBuy = 1000;
    uint16 private _treasuryFeeOnBuy = 0;
    uint16 private _devFeeOnSell = 200;
    uint16 private _treasuryFeeOnSell = 800;

    uint16 private _devFee = _devFeeOnSell;
    uint16 private _treasuryFee = _treasuryFeeOnSell;

    uint16 private _taxFee = _devFeeOnSell + _treasuryFeeOnSell;

    address payable public _devAddress =
        payable(0xd18DE0C4598d3b8B029C30192fC1e1a65898D532);
    address payable public _treasuryAddress =
        payable(0xD16ffd969712129C4fff570aCa83EaE906Ff19A6);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint32 private _tradingOpenDate;
    bool private _inSwap = false;
    bool private _swapEnabled = true;

    uint256 public _maxTxAmount = 30000 * 10**9; // 0.3%
    uint256 public _maxWalletSize = 100000 * 10**9; // 1%
    uint256 public _tokenSwapThreshold = 10000 * 10**9; //0.1%

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    //========================= Events =========================
    // TODO: We should probably add more events
    event MaxTxAmountUpdated(uint256 _maxTxAmount);

    //========================= Constructor =========================
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
        _isExcludedFromFee[_devAddress] = true;
        _isExcludedFromFee[_treasuryAddress] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    //========================= Views =========================
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

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    //========================= Public and owner only functions =========================
    function setLaunchDate(uint32 delay) public onlyOwner {
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        _tradingOpenDate = delay + blockTimestamp + blockTimestamp % 60;
    }

    //======================== Transfer functions (public)
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
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

    function manualswap() external {
        require(_msgSender() == _devAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _devAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETH(contractETHBalance);
    }

    //======================== Swap and send functions (public)
    function enableAddressToTrade(address account, bool enable)
        public
        onlyOwner
    {
        _blacklist[account] = !enable;
    }

    function enableAddressesToTrade(address[] memory addressList, bool enable)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addressList.length; i++) {
            _blacklist[addressList[i]] = !enable;
        }
    }

    //======================== Token management functions
    function setExcludedFromFee(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = excluded;
    }

    function setDevAddress(address payable account) external onlyOwner {
        _devAddress = account;
    }

    function setTreasuryAddress(address payable account) external onlyOwner {
        _treasuryAddress = account;
    }

    function setFee(
        uint16 devFeeBuy,
        uint16 treasuryFeeBuy,
        uint16 devFeeSell,
        uint16 treasuryFeeSell
    ) public onlyOwner {
        _devFeeOnBuy = devFeeBuy;
        _treasuryFeeOnBuy = treasuryFeeBuy;
        _devFeeOnSell = devFeeSell;
        _treasuryFeeOnSell = treasuryFeeSell;
    }

    function setMinSwapTokensThreshold(uint256 tokenSwapThreshold)
        public
        onlyOwner
    {
        _tokenSwapThreshold = tokenSwapThreshold;
    }

    function setSwapEnabled(bool swapEnabled) public onlyOwner {
        _swapEnabled = swapEnabled;
    }

    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }

    //========================= Private functions =========================
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

    //======================== Transfer functions (private)
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (
            (from != owner() && to != owner()) ||
            (from != _treasuryAddress && to != _treasuryAddress)
        ) {
            require(
                block.timestamp > _tradingOpenDate,
                "TOKEN: Trading this token is not allowed yet"
            );
            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
            require(
                !_blacklist[from] && !_blacklist[to],
                "TOKEN: Your account is blacklisted!"
            );

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

            if (
                shouldSwap && !_inSwap && from != uniswapV2Pair && _swapEnabled
            ) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETH(address(this).balance);
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
                _devFee = _devFeeOnBuy;
                _treasuryFee = _treasuryFeeOnBuy;
                _taxFee = _devFee + _treasuryFee;
            }

            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _devFee = _devFeeOnSell;
                _treasuryFee = _treasuryFeeOnSell;
                _taxFee = _devFee + _treasuryFee;
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
        uint256 transferAmount = amount;
        if (takeFee) {
            uint256 feeAmount = amount.mul(_taxFee).div(10000);
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            transferAmount = transferAmount.sub(feeAmount);
            _setTokenAllocation(feeAmount);
        }
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(transferAmount);

        emit Transfer(sender, recipient, transferAmount);
    }

    function _setTokenAllocation(uint256 amount) private {
        uint256 devPercentage = _devFee * 100 / _taxFee;

        uint256 devAmount = amount.mul(devPercentage).div(100);
        uint256 treasuryAmount = amount.sub(devAmount);

        _devTokenAllocation = _devTokenAllocation.add(devAmount);
        _treasuryTokenAllocation = _treasuryTokenAllocation.add(treasuryAmount);
    }

    //======================== Swap and send functions (private)
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

    function sendETH(uint256 amount) private {
        require(address(this).balance >= amount, "Contract does not have enough ETH to send");
        uint256 _totalTokenAllocation = _devTokenAllocation.add(
            _treasuryTokenAllocation
        );

        uint256 devPercentage = _devTokenAllocation.mul(100).div(
            _totalTokenAllocation
        );

        uint256 devETHAmount = amount.mul(devPercentage).div(100);
        uint256 treasuryETHAmount = amount.sub(devETHAmount);

        (bool successDev, ) = _devAddress.call{value: devETHAmount}("");
        (bool successTreasury, ) = _treasuryAddress.call{
            value: treasuryETHAmount
        }("");

        require(successDev, "Tx Failed");
        require(successTreasury, "Tx Failed");

        uint256 contractCurrentBalance = balanceOf(address(this));
        if (contractCurrentBalance > 0) {
            // Swapped less tokens than contract balance due to maximum transaction limits
            uint256 remainingDevTokens = contractCurrentBalance
                .mul(devPercentage)
                .div(100);
            uint256 remainingTreasuryTokens = contractCurrentBalance
                .sub(remainingDevTokens);
            _devTokenAllocation = remainingDevTokens;
            _treasuryTokenAllocation = remainingTreasuryTokens;
        } else {
            // Reset token allocation
            _devTokenAllocation = 0;
            _treasuryTokenAllocation = 0;
        }
    }

    //======================== Enable contract to receive ETH
    receive() external payable {}
}