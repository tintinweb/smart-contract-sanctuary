// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import './IBEP20.sol';
import './SafeMath.sol';
import './Auth.sol';
import './Math.sol';
import './Ownable.sol';
import './IUniswapV2Router01.sol';
import './IUniswapV2Router02.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Pair.sol';


contract Katoh is Ownable, IBEP20 {
	using SafeMath for uint256;
	using Math for uint256;

	struct PastTx {
		uint256 cumTransfer;
		uint256 cumTax;
		uint256 lastTimestamp;
	}

	mapping (address => uint256) private _balances;
	mapping (address => PastTx) public lastTx;
	mapping (address => mapping(address => uint256)) private _allowances;
	mapping (address => bool) private excluded;
	mapping (address => bool) private _isBlacklisted;

	string private constant _name = "Katoh";
	string private constant _symbol = "KTOH";
	uint8 private constant _decimals = 8;

	uint256 private constant _totalSupply = 10000000 * (10 ** _decimals);
    uint256 public _maxWallet = 1100000 * (10 ** _decimals); // Max wallet 11%
	uint256 public swapForLiquidityThreshold = 100000 * (10 ** _decimals);

	uint32 public constant RESTORE_RATE = 1 days;
	uint8 public constant MAX_SELL = 1; // Maximum sell in the last 24 hours
	uint8 public constant GLOBAL_FEE = 50; // 5%

	bool public circuitBreaker;
	bool public isFunctionRenounced = false;
	bool private _liqSwapReentrancyGuard;

	address public constant SAFE_WALLET = address(0x84B05882Fb5150E63Abb4B77e2D51BF1D81725bD);
	address public constant ROUTER = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);

	IUniswapV2Pair public pair;
	IUniswapV2Router02 public router;

	event AddToLiquidity(string);

	modifier isNotRenounced() {
		require(isFunctionRenounced == false, "The function has been renounced");
		_;
	}

	constructor() {
		excluded[_msgSender()] = true;
		excluded[address(this)] = true;
		excluded[SAFE_WALLET] = true;

		circuitBreaker = true; //ERC20 behavior by default/presale

		_balances[_msgSender()] = _totalSupply;

		//create pair to get the pair address
		router = IUniswapV2Router02(ROUTER);
		IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
		pair = IUniswapV2Pair(factory.createPair(address(this), router.WETH()));

		emit Transfer(address(0), _msgSender(), _totalSupply);
	}

	function decimals() external pure override returns (uint8) {
		return _decimals;
	}

	function name() external pure override returns (string memory) {
		return _name;
	}

	function symbol() external pure override returns (string memory) {
		return _symbol;
	}

	function totalSupply() public pure override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) external view override returns (uint256) {
		return _balances[account];
	}

	function getOwner() external view override returns (address) {
		return owner();
	}

	function transfer(address recipient, uint256 amount) external override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address _owner, address spender) public view override returns (uint256) {
		return _allowances[_owner][spender];
	}

	function approve(address spender, uint256 amount) external override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
		_transfer(sender, recipient, amount);

		uint256 currentAllowance = _allowances[sender][_msgSender()];
		require(currentAllowance >= amount, "KTOH: transfer amount exceeds allowance");
		_approve(sender, _msgSender(), currentAllowance - amount);

		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
		uint256 currentAllowance = _allowances[_msgSender()][spender];
		require(currentAllowance >= subtractedValue, "KTOH: decreased allowance below zero");
		_approve(_msgSender(), spender, currentAllowance - subtractedValue);

		return true;
	}

	function _approve(address _owner, address spender, uint256 amount) private {
		require(_owner != address(0), "KTOH: approve from the zero address");
		require(spender != address(0), "KTOH: approve to the zero address");

		_allowances[_owner][spender] = amount;
		emit Approval(_owner, spender, amount);
	}

	function _transfer(address sender, address recipient, uint256 amount) private {
		require(sender != address(0), "KTOH: transfer from the zero address");

		uint256 senderBalance = _balances[sender];
		require(senderBalance >= amount, "KTOH: transfer amount exceeds balance");

		require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "You are a bot");

        bool isSell=recipient == address(pair) || recipient == address(router);

		// Max wallet check excluding pair and router
		if (!isSell && !excluded[recipient]){
			require((_balances[recipient] + amount) < _maxWallet, "Max wallet has been triggered");
		}

		// >1 day since last tx
		if (block.timestamp > lastTx[sender].lastTimestamp + RESTORE_RATE) {
			lastTx[sender].cumTransfer = 0;
			lastTx[sender].cumTax = 0;
		}

		uint256 sellTax = 0;
		uint256 balancerTax = 0;

		if (!excluded[sender] && !excluded[recipient] && !circuitBreaker) {
			if (recipient == address(pair)) {
				sellTax = sellingTax(sender, amount);
			}

			balancerTax = amount.mul(GLOBAL_FEE).ceilDiv(10**3).add(sellTax);

			balancer(balancerTax);
		}

		lastTx[sender].lastTimestamp = block.timestamp;

		_balances[sender] = senderBalance.sub(amount);
		_balances[recipient] += amount.sub(balancerTax);

		emit Transfer(sender, recipient, amount.sub(balancerTax));
	}

	// @dev take a selling tax based on amount of token dumped
	function sellingTax(address sender, uint256 amount) private returns (uint256) {
		uint256 newCumSum = amount.add(lastTx[sender].cumTransfer);

		if (newCumSum > totalSupply().mul(MAX_SELL).div(10**3)) {
			revert("KTOH: selling amount is above max allowed");
		}

		uint256 taxAmount = newCumSum.mul(newCumSum).mul(100).ceilDiv(totalSupply());
		uint256 sellTax = taxAmount - lastTx[sender].cumTax;

		lastTx[sender].cumTransfer = newCumSum;
		lastTx[sender].cumTax += sellTax;

		return sellTax;
	}

	// @dev take the fixed tax as input, split it between resources and liq pool
	// according to pool condition
	function balancer(uint256 amount) private {
		//divide in 50/50 tokens
		uint256 half = amount.div(2);
		uint256 half_2 = amount.sub(half);

		//send half tokens to resources
		_balances[SAFE_WALLET] += half;
		emit Transfer(_msgSender(), SAFE_WALLET, half);

		//send half tokens to contract wallet
		_balances[address(this)] += half_2;
		emit Transfer(_msgSender(), address(this), half_2);

		//swap if limit is reached
		uint256 _liquidityPool = _balances[address(this)];
		if (_liquidityPool >= swapForLiquidityThreshold && !_liqSwapReentrancyGuard) {
			_liqSwapReentrancyGuard = true;
			addLiquidity(_liquidityPool);
			_liqSwapReentrancyGuard = false;
		}
	}

	//@dev when triggered, will swap and provide liquidity
	function addLiquidity(uint256 tokenAmount) private returns (uint256) {
		uint256 BNBBeforeSwap = address(this).balance;

		if (allowance(address(this), address(router)) < tokenAmount) {
			_allowances[address(this)][address(router)] = type(uint256).max;
			emit Approval(address(this), address(router), type(uint256).max);
		}

		//odd numbers management
		uint256 half = tokenAmount.div(2);
		uint256 half_2 = tokenAmount.sub(half);

		address[] memory route = new address[](2);
		route[0] = address(this);
		route[1] = router.WETH();

		router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			half,
			0, // accept any amount of ETH
			route,
			address(this),
			block.timestamp
		);

		uint256 BNBfromSwap = address(this).balance.sub(BNBBeforeSwap);
		router.addLiquidityETH{value: BNBfromSwap}(
			address(this),
			half_2,
			0, // slippage is unavoidable
			0, // slippage is unavoidable
			SAFE_WALLET,
			block.timestamp
		);
		emit AddToLiquidity("Liquidity increased");
		return tokenAmount;
	}

	function excludeFromTaxes(address adr) external onlyOwner {
		require(!excluded[adr], "already excluded");
		excluded[adr] = true;
	}

	function includeInTaxes(address adr) external onlyOwner {
		require(excluded[adr], "already taxed");
		excluded[adr] = false;
	}

	function isExcluded(address adr) external view returns (bool) {
		return excluded[adr];
	}

	function setMaxWallet(uint256 amount) external onlyOwner {
		require(amount >= _totalSupply / 1000);
		_maxWallet = amount;
	}

	function updateIsBlacklisted(address account, bool state) external onlyOwner {
		_isBlacklisted[account] = state;
	}

	function bulkIsBlacklisted(address[] memory accounts, bool state) external onlyOwner {
		for(uint256 i =0; i < accounts.length; i++){
			_isBlacklisted[accounts[i]] = state;

		}
	}

	//@dev frontend integration
	function endOfPenaltyPeriod() external view returns (uint256) {
		return lastTx[_msgSender()].lastTimestamp + RESTORE_RATE;
	}

	//@dev will bypass all the taxes and act as erc20.
	//pools & balancer balances will remain untouched
	function setCircuitBreaker(bool status) external onlyOwner {
		circuitBreaker = status;
	}

	function changeLiquidityThreshold(uint256 newThreshold) external onlyOwner {
		swapForLiquidityThreshold = newThreshold;
	}

	function retrieveStuckBNB() external onlyOwner isNotRenounced {
		address payable contractOwner = payable(_msgSender());
		uint256 stuckBNB = address(this).balance;
		contractOwner.transfer(stuckBNB);
	}

	function renounceStuckBNBFunction() external onlyOwner {
		isFunctionRenounced = true;
	}

	//Use this in case BNB are sent to the contract by mistake
	function rescueBNB(uint256 weiAmount) external onlyOwner {
		require(address(this).balance >= weiAmount, "insufficient BNB balance");
		payable(msg.sender).transfer(weiAmount);
	}

	function rescueAnyBEP20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
		IBEP20(_tokenAddr).transfer(_to, _amount);
	}

	//@dev fallback in order to receive BNB
	receive() external payable {}
}