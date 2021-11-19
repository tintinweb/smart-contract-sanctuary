/**
 //SPDX-License-Identifier: UNLICENSED
 
Check us out on Telegram! TG: t.me/
*/

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

contract Meditoken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10**18 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    uint256 private _feeCharity;
    uint256 private _feeReflection;
    uint256 private _feeDevMarketing;
    uint256 private _feeBurn;
    
    uint256 public _maxWalletSize = 35 * 10**15 * 10**9; //3.5
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    address payable private charityWallet = payable(0x6c79496140848FaCa2721139bD7C7A4eBD9B2e4C);
    address payable private devMarketingWallet = payable(0x6c3116da9054aE64E89284aaC5248415E2f55ee4);
    
    string private constant _name = "Medi Token";
    string private constant _symbol = "Medi";
    uint8 private constant _decimals = 9;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    uint256 private _maxTxAmount = _tTotal;
    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[devMarketingWallet] = true;
        _isExcludedFromFee[charityWallet] = true;

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

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
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

        _feeReflection = 1;
        _feeBurn = 1;
        _feeCharity = 2;
        _feeDevMarketing = 6;

        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] && cooldownEnabled) {
                // Cooldown
                require(amount <= _maxTxAmount);
                require(cooldown[to] < block.timestamp);
                cooldown[to] = block.timestamp + (30 seconds);
            }
            
            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }

            if (to == uniswapV2Pair && from != address(uniswapV2Router) && ! _isExcludedFromFee[from]) {
                _feeReflection = 1;
                _feeBurn = 1;
                _feeCharity = 2;
                _feeDevMarketing = 6;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
		
        _tokenTransfer(from,to,amount);
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
        
    function sendETHToFee(uint256 amount) private {
        charityWallet.transfer(amount.mul(_feeCharity).div(_feeCharity + _feeDevMarketing));
        devMarketingWallet.transfer(amount.mul(_feeDevMarketing).div(_feeCharity + _feeDevMarketing));
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        _maxTxAmount = _tTotal;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
    
    function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        _takeTeam(tTeam);
        _takeBurn(sender, tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeBurn(address sender, uint tBurn) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[burnAddress] = _rOwned[burnAddress].add(rBurn);

        emit Transfer(sender, burnAddress, tBurn);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 amount = tAmount;
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam, uint256 tBurn) = _getTValues(amount, _feeReflection, _feeCharity + _feeDevMarketing, _feeBurn);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(amount, tFee, tTeam, tBurn, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam, tBurn);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 TeamFee, uint256 burnFee) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 amount = tAmount;
        uint256 tFee = amount.mul(taxFee).div(100);
        uint256 tTeam = amount.mul(TeamFee).div(100);
        uint256 tBurn = amount.mul(burnFee).div(100);
        uint256 tTransferAmount = amount.sub(tFee).sub(tTeam).sub(tBurn);
        return (tTransferAmount, tFee, tTeam, tBurn);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 tBurn, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam).sub(rBurn);
        return (rAmount, rTransferAmount, rFee);
    }

	function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}