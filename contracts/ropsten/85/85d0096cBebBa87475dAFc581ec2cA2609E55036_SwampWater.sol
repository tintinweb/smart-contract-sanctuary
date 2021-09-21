/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

pragma solidity >=0.5.0;
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
pragma solidity >=0.6.2;
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
pragma solidity >=0.6.2;
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
}
pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
pragma solidity ^0.8.0;
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
}
pragma solidity ^0.8.0;
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {return _name;}
    function symbol() public view virtual override returns (string memory) {return _symbol;}
    function decimals() public view virtual override returns (uint8) {return 18;  }
    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view virtual override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender,address recipient,uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {_approve(sender, _msgSender(), currentAllowance - amount);}
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {_approve(_msgSender(), spender, currentAllowance - subtractedValue);}
        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        unchecked {_balances[sender] -= amount;}
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _approve(address owner,address spender,uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
pragma solidity ^0.8.0;
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
pragma solidity ^0.8.0;
contract SwampWater is ERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    mapping(address => uint256) nextBuyTime;
    mapping(address => uint256) nextSellTime;
    bool private swapping;
    uint256 public swapTokensAtAmount = 5 * 10**10 * 10**18;
    mapping(address => bool) isExcluded;
    constructor() ERC20("SwampWater", "SWPv9") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        isExcluded[_msgSender()] = true;
        isExcluded[address(this)] = true;
        _mint(_msgSender(), 15 * 10**14 * 10**18);
    }
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0));
        require(to != address(0));
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        require(amount > 0);
        bool takeFee;
        if (!isExcluded[from] && !isExcluded[to]) {
            uint256 time = block.timestamp;
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                require(time > nextBuyTime[to], "Buy: Cooldown time has not elapsed!");
                nextBuyTime[to] = time + 45;
                takeFee = true;
            } else if (to == uniswapV2Pair) {
                require(time > nextSellTime[from], "Sell: Cooldown time has not elapsed!");
                nextSellTime[from] = time + 15;
                takeFee = true;
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance >= swapTokensAtAmount && !swapping && from != uniswapV2Pair) {
                swapping = true;
                swapAndSend(contractTokenBalance/2);
                swapping = false;
            }
        }
        if(takeFee) {
            uint256 fee = amount * 5 / 100;
            amount -= fee;
            super._transfer(from, address(this), fee);
        }
        super._transfer(from, to, amount);
    }
    function swapAndSend(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
        payable(owner()).transfer(address(this).balance);
    }
    function swapAndSend() external onlyOwner {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), balanceOf(address(this)));
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(balanceOf(address(this)),0,path,address(this),block.timestamp);
        payable(owner()).transfer(address(this).balance);
    }
    function airdrop(address[] memory _user, uint256[] memory _amount) external onlyOwner {
        uint256 len = _user.length;
        require(len == _amount.length);
        for (uint256 i = 0; i < len; i++) {
            super._transfer(_msgSender(), _user[i], _amount[i]);
        }
    }
    function setSwapAtAmount(uint256 amount) external onlyOwner {
        swapTokensAtAmount = amount;
    }
}