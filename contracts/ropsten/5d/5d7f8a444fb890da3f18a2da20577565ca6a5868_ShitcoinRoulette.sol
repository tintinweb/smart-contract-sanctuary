/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

/*

    
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

    constructor () {
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

contract ShitcoinRoulette is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = 'ShitcoinRoulette';
    string private constant _symbol = 'SCR';
    uint8 private constant _decimals = 18;
    uint private constant _totalSupply = 1_000_000_000e18; // 1 billion SCR

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping(address => uint256) private _cooldown;
    mapping(address => bool) private _isExcludedFromFee;

    uint8 private constant _fee = 10; //percentage

    address payable private _FeeAddress;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;


    bool private inSwap = false;
    bool private tradingOpen = false;
    bool private cooldownEnabled = false;


    modifier lockTheSwap {
    inSwap = true;
    _;
    inSwap = false;
    }


    constructor (address payable FeeAddress) {
        _FeeAddress = FeeAddress;
        _balances[_msgSender()] = _totalSupply;

        //while testing everyone pays fees
        //_isExcludedFromFee[_msgSender()] = true;
        //_isExcludedFromFee[address(this)] = true;
        //_isExcludedFromFee[FeeAddress] = true;

        emit Transfer(address(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B), _msgSender(), _totalSupply);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }

    function excludeFromFees(address addressToExclude) external onlyOwner() {
        _isExcludedFromFee[addressToExclude] = true;
    }

    function includeInFees(address addressToInclude) external onlyOwner() {
        _isExcludedFromFee[addressToInclude] = false;
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _isUniswapBuy(address from, address to) private view returns(bool){
        return (from == uniswapV2Pair && to != address(uniswapV2Router));
    }

    function _isWinner() private view returns(bool){
        return block.timestamp % 10 > 5;
    }

    function _payoutWinner(address payable winner, uint256 amount) private {
        winner.transfer(amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            if (cooldownEnabled) {
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
            }

            if (_isUniswapBuy(from, to) && cooldownEnabled) {
                require(_cooldown[to] < block.timestamp);
                _cooldown[to] = block.timestamp + (30 seconds);
                if (_isWinner()) {
                    uint256 contractETHBalance = address(this).balance;
                    if (contractETHBalance > 0) {
                        _payoutWinner(payable(to), amount.div(2));
                    }
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && tradingOpen) {
                swapTokensForEth(contractTokenBalance.div(2), address(this));
                swapTokensForEth(contractTokenBalance.div(2), _FeeAddress);
            }
        }
		
        _tokenTransfer(from,to,amount);
    }

    function swapTokensForEth(uint256 tokenAmount, address destinationAddress) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            destinationAddress,
            block.timestamp + 600
        );
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen, "trading is already open");
        IUniswapV2Router02 _uniswapV2Router =
            IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp + 100
        );
        cooldownEnabled = true;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }
    
        
    function _tokenTransfer(address sender, address recipient, uint256 amount) private returns(bool){

        uint256 feeAmount = amount.mul(_fee).div(100);

        if (_isExcludedFromFee[sender]) {
            feeAmount = 0;
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        if (feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            _balances[recipient] = _balances[recipient].sub(feeAmount);
        }

        emit Transfer(sender, recipient, amount);

        return true;

    }

    receive() external payable {}
    
    //function manualswap() external {
      //  require(_msgSender() == _FeeAddress);
        //uint256 contractBalance = balanceOf(address(this));
        //swapTokensForEth(contractBalance);
   // }
    
   // function manualsend() external {
     //   require(_msgSender() == _FeeAddress);
       // uint256 contractETHBalance = address(this).balance;
        //sendETHToFee(contractETHBalance);
    //}

    //function sendETHToFee(uint256 amount) private {
    //_FeeAddress.transfer(amount);
    //}
}