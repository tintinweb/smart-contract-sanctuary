/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

//SPDX-License-Identifier: Mines™®©
pragma solidity ^0.8.4;

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

contract ShibaGalaxy is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Shiba Galaxy";
    string private constant _symbol = "SGX";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _sgxBal;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant _vTotal = 100000000000000 * 10**9;
    uint256 private _devFee = 3;
    uint256 private _burnFee = 7;
    uint256 private _maxFeeSwap;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    address private _feeCollector;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private _initialized = false;


    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _feeCollector = owner();
        _sgxBal[address(this)] = _vTotal;
        emit Transfer(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B, address(this), _vTotal);

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
        return _vTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _sgxBal[account];
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

    function removeAllFee() private {
        _burnFee = 0;
        _devFee = 0;
    }

    function restoreAllFee() private {
        _burnFee = 7;
        _devFee = 3;
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
            if (
                from != address(this) &&
                to != address(this) &&
                from != address(uniswapV2Router) &&
                to != address(uniswapV2Router)
            ) {
                require(
                    _msgSender() == address(uniswapV2Router) ||
                        _msgSender() == uniswapV2Pair,
                    "ERR: Uniswap only"
                );
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            
            _maxFeeSwap = balanceOf(uniswapV2Pair).div(100);
            
            if (contractTokenBalance > _maxFeeSwap) contractTokenBalance = _maxFeeSwap;

            if (!inSwap && from != uniswapV2Pair && swapEnabled && contractTokenBalance > 0) swapTokensForEth(contractTokenBalance);
             
        }

        bool takeFee;
        
        if (from != uniswapV2Pair) takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) takeFee = false;

        _tokenTransfer(from, to, amount, takeFee);
        
        restoreAllFee();
    }

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


    function addLiquidity() external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router =
            IUniswapV2Router02(0x03f7724180AA6b939894B5Ca4314783B0b36b329);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _vTotal);
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
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }

    function manualswap() external onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
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
        uint256 sendAmount
    ) private {
        uint256 totalFee = _devFee + _burnFee;
        uint256 recAmount = sendAmount - sendAmount.div(100).mul(totalFee);
        uint256 devFee = sendAmount.div(100).mul(_devFee);
        uint256 burnFee = sendAmount.div(100).mul(_burnFee);
        _sgxBal[sender] = _sgxBal[sender].sub(sendAmount);
        _sgxBal[recipient] = _sgxBal[recipient].add(recAmount);
        _sgxBal[address(this)] = _sgxBal[address(this)].add(devFee);
        _sgxBal[address(0)] = _sgxBal[address(0)].add(burnFee);
        emit Transfer(sender, recipient, recAmount);
    }

    receive() external payable {}

    modifier feeCollector() {
        require(_feeCollector == _msgSender(), "Caller is not the fee collector");
        _;
    }
    
    function withdrawBalance() external feeCollector() {
        payable(msg.sender).transfer(address(this).balance);
    }
    
}