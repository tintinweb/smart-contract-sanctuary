/**
 *Submitted for verification at Etherscan.io on 2021-09-22
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

contract FkEverGrande is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "FkEverGrande";
    string private constant _symbol = "FKE";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _fkeBal;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant _vTotal = 100000000000000 * 10**9;
    uint256 private _devFee = 5;
    uint256 private _burnFee = 5;
    uint256 private _maxFeeSwap = 1000000000000 * 10**9;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    address private _teamAddress;
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
        _teamAddress = owner();
        _fkeBal[address(this)] = _vTotal;
        emit Transfer(address(0), address(this), _vTotal);

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
        return _fkeBal[account];
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
        _burnFee = 5;
        _devFee = 5;
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
            _teamAddress,
            block.timestamp
        );
    }


    function addLiquidity() external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router =
            IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
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
        _fkeBal[sender] = _fkeBal[sender].sub(sendAmount);
        _fkeBal[recipient] = _fkeBal[recipient].add(recAmount);
        _fkeBal[address(this)] = _fkeBal[address(this)].add(devFee);
        _fkeBal[address(0)] = _fkeBal[address(0)].add(burnFee);
        emit Transfer(sender, recipient, recAmount);
    }

    receive() external payable {}
    
    function setTeamAddress(address payable _address) external onlyOwner() {
        _teamAddress = _address;
        _isExcludedFromFee[_teamAddress] = true;
    }
    
}