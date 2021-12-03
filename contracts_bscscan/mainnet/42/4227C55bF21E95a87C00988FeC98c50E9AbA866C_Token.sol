/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    function _msgData() internal view virtual returns (bytes memory) {
        this;  return msg.data;
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

contract Token is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping (uint256 => address payable) private classifiedAddress;
    mapping (uint256 => uint256) private classifiedAddressFee;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 300 * 10**9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public _feeAutoFarming = 2;
    uint256 public _feeClassified = classifiedAddressFee[1].add(classifiedAddressFee[2]);
    
    string private constant _name = "Fluffy Corgi Inu";
    string private constant _symbol = "FluffyCorgi";
    uint8 private constant _decimals = 9;
    
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool public _isFeeToEth = true;
    uint256 public _isFeeToEthMin = _tTotal.div(10000);
    uint256 public _maxTxAmount = _tTotal.div(100);
    uint256 public _antiBotFee = 90;
    
    constructor () {
        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        emit Transfer(address(0),address(this),_tTotal);
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
        
        uint256 tempFee1 = _feeAutoFarming;
        uint256 tempFee2 = classifiedAddressFee[1]+classifiedAddressFee[2];
        _feeAutoFarming = 0;
        _feeClassified = 0;

        if(!_isExcludedFromFee[from]) { 
            require(amount <= _maxTxAmount);
            _feeAutoFarming = tempFee1;
            _feeClassified = tempFee2;
            if(bots[from] || bots[to]) {
                _feeAutoFarming = _antiBotFee.div(2);
                _feeClassified = _antiBotFee.div(2);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance >= _isFeeToEthMin && from != uniswapV2Pair && _isFeeToEth) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        _tokenTransfer(from,to,amount);

        _feeAutoFarming = tempFee1;
        _feeClassified = tempFee2;
    }

    function swapTokensForEth(uint256 tokenAmount) private  {
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
        for(uint256 i=1; i <= type(uint256).max; i++){
            if(classifiedAddress[i] != address(0)){
                classifiedAddress[i].transfer(amount.mul(classifiedAddressFee[i]).div(100));
            }
            else{
                break;
            }
        }
    } 
    
    function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }
    function setAutoFarmingFee(uint256 _value) public onlyOwner {
        _feeAutoFarming = _value;
    }
    function setclassifiedAddressess(uint256 _slot, address payable _value) public onlyOwner {
        classifiedAddress[_slot] = payable(_value);
    }
    function setClassifiedAddressFee(uint256 _slot, uint256 _value) public onlyOwner {
        classifiedAddressFee[_slot] = _value;
        _feeClassified = classifiedAddressFee[1].add(classifiedAddressFee[2]);
    }
    function setAntiBotFee(uint256 _value) public onlyOwner {
        _antiBotFee = _value;
    }
    function setMaxTxAmount(uint256 _value) public onlyOwner {
        _maxTxAmount = _value;
    }
    
    function setIsFeeToEth(bool _value) public onlyOwner {
        _isFeeToEth = _value;
    }
    function setIsFeeToEthMin(uint256 _value) public onlyOwner {
        _isFeeToEthMin = _value;
    }
    function popERC20(address _token, uint256 _value) public onlyOwner {
        IERC20(_token).transfer(msg.sender, _value);
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        _transferStandard(sender, recipient, amount);
    }
    function _excludedFromFee(address _value) public onlyOwner{
        _isExcludedFromFee[_value] = true;
    }
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tGrowth) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        _acquireGrowth(tGrowth);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _acquireGrowth(uint256 tGrowth) private {
        uint256 currentRate =  _getRate();
        uint256 rGrowth = tGrowth.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rGrowth);
    }
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function manualswap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    function manualsend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tGrowth) = _getTValues(tAmount, _feeAutoFarming, _feeClassified);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tGrowth, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tGrowth);
    }
    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 GrowthFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tGrowth = tAmount.mul(GrowthFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tGrowth);
        return (tTransferAmount, tFee, tGrowth);
    }
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tGrowth, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rGrowth = tGrowth.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rGrowth);
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