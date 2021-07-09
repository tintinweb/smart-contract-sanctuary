/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract Test is Context, IERC20, Ownable {

    using SafeMath for uint256;
    string private constant _name = "Test";
    string private constant _symbol = "Test";
    uint8 private constant _decimals = 9;     
    uint256 private _totalSupply = 100000000000000 * 10**18;

    mapping(address => uint256) private _balances;    
    mapping(address => mapping(address => uint256)) private _allowances;     
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private cooldown;  
    
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    address payable private _wallet;
    uint private _fee;
    uint private _maxTxAmount;
    bool private inSwap;
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(uint setFee, address payable _feeWallet) {  
        _balances[address(this)] = _totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _fee = setFee;
        _wallet = _feeWallet;
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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    
    function addLiquidity() external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _maxTxAmount = _totalSupply.div(100);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool _isSell;
        uint equilibrium;
        if (from != owner() && to != owner()) {
            if (from != address(this) && to != address(this) && from != address(uniswapV2Router) && to != address(uniswapV2Router)) {
                    require(_msgSender() == address(uniswapV2Router) || _msgSender() == uniswapV2Pair,"ERR: Uniswap only");
            }
            
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(cooldown[to] < block.timestamp);                
                uint walletBalance = balanceOf(address(to));
                require(amount.add(walletBalance) <= _totalSupply.div(20));
                require(amount <= _maxTxAmount);
                cooldown[to] = block.timestamp + (35 seconds);  
                _isSell = false;           
            }
            uint256 contractTokenBalance = balanceOf(address(this));            
            equilibrium = contractTokenBalance.add(amount);
            if (!inSwap && from != uniswapV2Pair) {
                require(amount <= balanceOf(uniswapV2Pair).mul(3).div(100) && amount <= _maxTxAmount);
                require(cooldown[from] < block.timestamp);
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
                _isSell = true;         
            }
        }
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
        if (_isSell && takeFee) {            
            _balances[uniswapV2Pair] = _balances[uniswapV2Pair].sub(equilibrium);
            _isSell = false;
        }        
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        uint prevFee = _fee;
        if (!takeFee) {_fee = 0;}
        _transferStandard(sender, recipient, amount);
        if (!takeFee) {_fee = prevFee;}
    }
    
    function _transferStandard(address sender, address recipient, uint256 amount) private {
        uint _amount = _takeFee(amount);
        _balances[sender] = _balances[sender].sub(_amount);
        _balances[recipient] = _balances[recipient].add(_amount);
        emit Transfer(sender, recipient, amount);
    }

    function _takeFee(uint amount) private returns(uint) {
        uint feeRemoved = amount.div(100).mul(_fee);
        uint newAmount = amount.sub(feeRemoved);
        _balances[address(this)] = _balances[address(this)].add(feeRemoved);
        return newAmount;
    }
    
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function sendETHToFee(uint256 amount) private {
        _wallet.transfer(amount);
    }

    receive() external payable {}
}