pragma solidity ^0.8.6;

// SPDX-License-Identifier: UNLICENSED

import "./IERC20.sol";
import "./IPancakeFactory.sol";
import "./IPancakeRouter.sol";
import "./IAuntieWhaleSniperOracle.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./AuntieWhaleAutomaticBuybackAgent.sol";
import "./AuntieWhaleManualBuybackAgent.sol";

contract AuntieWhale is Context, IERC20, Ownable {
	using SafeMath for uint256;

	address private constant ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
	address private constant LAUNCHPAD_ADDRESS = 0xDc0a7fE55670dE0EaD8777432701Fc2815EB6b1e;

	uint256 private constant MAX = 2 ** 256 - 1;
	address constant ZERO_ADDRESS = address(0);
	address constant DEAD_ADDRESS = address(57005);
	uint256 private constant RATELIMIT_DELAY = 3;
	uint256 private constant FEE_PROCESSING_DELAY = 3;

	string constant _name = "Auntie Whale";
	string constant _symbol = "AUNTIE";
	uint8 constant _decimals = 9;

	uint256 private _tTotal = 1000000000000 * (10 ** _decimals);
	uint256 private _rTotal = (MAX - (MAX % _tTotal));
	uint256 private _tFeeTotal = 0;

	mapping(address => uint256) private _rOwned;
	mapping(address => uint256) private _tOwned;
	mapping(address => mapping(address => uint256)) private _allowances;

	mapping(address => uint256) private _ratelimit;
	mapping(address => bool) private _canTradeBeforeLaunch;
	mapping(address => bool) private _isAllowedToLaunch;
	mapping(address => bool) private _isExcludedFromFee;
	mapping(address => bool) private _isExcluded;
	address[] private _excluded;

	uint256 private _whaleTaxThreshold = _tTotal / 100;

	uint256 private _whaleTaxFee = 15;
	uint256 private _automaticBuybackFee = 7;
	uint256 private _manualBuybackFee = 3;
	uint256 private _marketingFee = 3;
	uint256 private _holderReflectFee = 1;
	uint256 private _liquidityFee = 1;

	AuntieWhaleAutomaticBuybackAgent private _automaticBuybackAgent;
	AuntieWhaleManualBuybackAgent private _manualBuybackAgent;
	IAuntieWhaleSniperOracle private _sniperOracle;
	address payable private _marketingWallet;

	bool private _areFeesActive = true;

	IPancakeRouter private _router;
	address private _pairAddress;

	bool private _areFeesBeingProcessed = false;
	bool private _isFeeProcessingEnabled = true;
	uint256 private _feeProcessingThreshold = _tTotal / 1000;
	uint256 private _feesLastProcessedAt;

	bool private _hasLaunched = false;

	event AutomaticBuybackAgentCreated(address contractAddress);
	event ManualBuybackAgentCreated(address contractAddress);
	event FeeProcessingThresholdUpdated(uint256 feeProcessingThreshold);
	event FeeProcessingEnabledUpdated(bool enabled);
	event FeesProcessed(uint256 amount);

	modifier lockTheSwap {
		_areFeesBeingProcessed = true;
		_;
		_areFeesBeingProcessed = false;
	}

	constructor() {
		address self = address(this);

		_rOwned[_msgSender()] = _rTotal;

		//Set router and pair variables
		_router = IPancakeRouter(ROUTER_ADDRESS);
		_pairAddress = IPancakeFactory(_router.factory()).createPair(self, _router.WETH());

		//Initialize buyback agents
		_automaticBuybackAgent = new AuntieWhaleAutomaticBuybackAgent(self);
		_automaticBuybackAgent.transferOwnership(owner());

		_manualBuybackAgent = new AuntieWhaleManualBuybackAgent(self);
		_manualBuybackAgent.transferOwnership(owner());

		//Exclude necessary addresses from fees
		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[self] = true;
		_isExcludedFromFee[ZERO_ADDRESS] = true;
		_isExcludedFromFee[DEAD_ADDRESS] = true;
		_isExcludedFromFee[address(_automaticBuybackAgent)] = true;
		_isExcludedFromFee[address(_manualBuybackAgent)] = true;

		_canTradeBeforeLaunch[owner()] = true;

		_isAllowedToLaunch[owner()] = true;
		_isAllowedToLaunch[LAUNCHPAD_ADDRESS] = true;

		_marketingWallet = payable(owner());

		emit AutomaticBuybackAgentCreated(address(_automaticBuybackAgent));
		emit ManualBuybackAgentCreated(address(_manualBuybackAgent));
		emit Transfer(DEAD_ADDRESS, _msgSender(), _tTotal);
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
		if (_isExcluded[account]) return _tOwned[account];
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

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}

	function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
		require(rAmount <= _rTotal, "Amount must be less than total reflections");
		uint256 currentRate = _getRate();
		return rAmount.div(currentRate);
	}

	function isExcludedFromReward(address account) public view returns (bool) {
		return _isExcluded[account];
	}

	function excludeFromFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = true;
	}

	function includeInFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = false;
	}

	function isExcludedFromFee(address account) public view returns (bool) {
		return _isExcludedFromFee[account];
	}

	function excludeFromReward(address account) public onlyOwner() {
		require(!_isExcluded[account], "Account is already excluded");

		if (_rOwned[account] > 0) {
			_tOwned[account] = tokenFromReflection(_rOwned[account]);
		}

		_isExcluded[account] = true;
		_excluded.push(account);
	}

	function includeInReward(address account) external onlyOwner() {
		require(_isExcluded[account], "Account is not excluded");

		for (uint256 i = 0; i < _excluded.length; i++) {
			if (_excluded[i] == account) {
				_excluded[i] = _excluded[_excluded.length - 1];
				_tOwned[account] = 0;
				_isExcluded[account] = false;
				_excluded.pop();
				break;
			}
		}
	}

	function setCanTradeBeforeLaunch(address account, bool isAllowed) public onlyOwner {
		_canTradeBeforeLaunch[account] = isAllowed;
	}

	function setFees(uint256 whaleTaxFee, uint256 automaticBuybackFee, uint256 manualBuybackFee, uint256 marketingFee, uint256 holderReflectFee, uint256 liquidityFee) public onlyOwner {
		//No honeypots here
		uint256 feeSum = whaleTaxFee + automaticBuybackFee + manualBuybackFee + marketingFee + holderReflectFee + liquidityFee;
		require(feeSum <= 45, "Cannot set fees higher than 45%.");

		//Update fee variables
		_whaleTaxFee = whaleTaxFee;
		_automaticBuybackFee = automaticBuybackFee;
		_manualBuybackFee = manualBuybackFee;
		_marketingFee = marketingFee;
		_holderReflectFee = holderReflectFee;
		_liquidityFee = liquidityFee;
	}

	function calculateWhaleTaxFee(uint256 _amount, address _recipient) private view returns (uint256) {
		if (_areFeesActive && balanceOf(_recipient).add(_amount) > _whaleTaxThreshold && _recipient != _pairAddress && _recipient != address(_router)) {
			return _amount.mul(_whaleTaxFee).div(100);
		} else return 0;
	}

	function calculateAutomaticBuybackFee(uint256 _amount) private view returns (uint256) {
		if (!_areFeesActive) return 0;
		return _amount.mul(_automaticBuybackFee).div(100);
	}

	function calculateManualBuybackFee(uint256 _amount) private view returns (uint256) {
		if (!_areFeesActive) return 0;
		return _amount.mul(_manualBuybackFee).div(100);
	}

	function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
		if (!_areFeesActive) return 0;
		return _amount.mul(_marketingFee).div(100);
	}

	function calculateHolderReflectFee(uint256 _amount) private view returns (uint256) {
		if (!_areFeesActive) return 0;
		return _amount.mul(_holderReflectFee).div(100);
	}

	function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
		if (!_areFeesActive) return 0;
		return _amount.mul(_liquidityFee).div(100);
	}

	function setFeeProcessingEnabled(bool enabled) public onlyOwner {
		_isFeeProcessingEnabled = enabled;
		emit FeeProcessingEnabledUpdated(enabled);
	}

	function setFeeProcessingThreshold(uint256 threshold) public onlyOwner {
		require(threshold > 0, "Fee processsing threshold must be greater than zero.");
		_feeProcessingThreshold = threshold;
		emit FeeProcessingThresholdUpdated(threshold);
	}

	function setAutomaticBuybackAgent(AuntieWhaleAutomaticBuybackAgent automaticBuybackAgent) public onlyOwner {
		_automaticBuybackAgent = automaticBuybackAgent;
		_isExcludedFromFee[address(_automaticBuybackAgent)] = true;
	}

	function setManualBuybackAgent(AuntieWhaleManualBuybackAgent manualBuybackAgent) public onlyOwner {
		_manualBuybackAgent = manualBuybackAgent;
		_isExcludedFromFee[address(_manualBuybackAgent)] = true;
	}

	function setSniperOracle(IAuntieWhaleSniperOracle sniperOracle) public onlyOwner {
		_sniperOracle = sniperOracle;
	}

	function getAutomaticBuybackAgent() public view returns (address) {
		return address(_automaticBuybackAgent);
	}

	function getManualBuybackAgent() public view returns (address) {
		return address(_manualBuybackAgent);
	}

	function getMarketingWallet() public view returns (address) {
		return _marketingWallet;
	}

	function setMarketingWallet(address payable wallet) public onlyOwner {
		require(wallet != ZERO_ADDRESS, "The marketing wallet cannot be the zero address.");
		_marketingWallet = wallet;
		_isExcludedFromFee[_marketingWallet] = true;
	}

	function launch() public {
		require(_isAllowedToLaunch[_msgSender()], "Forbidden.");
		require(!_hasLaunched, "Already launched.");
		_sniperOracle.launch();
		_hasLaunched = true;
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != ZERO_ADDRESS, "ERC20: approve from the zero address");
		require(spender != ZERO_ADDRESS, "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _transfer(address _from, address _to, uint256 _amount) private {
		require(_from != ZERO_ADDRESS, "ERC20: transfer from the zero address");
		require(_to != ZERO_ADDRESS, "ERC20: transfer to the zero address");
		require(_amount > 0, "Transfer amount must be greater than zero");

		//Ensure trading is disabled before launch
		require(_hasLaunched || _canTradeBeforeLaunch[_from], "Cannot trade before launch.");

		//Making the bots and snipers say uncle.
		_sniperOracle.processTransfer(_from, _to, _amount);

		bool canProcess = _isFeeProcessingEnabled && !_areFeesBeingProcessed;
		bool hasProcessedFees = false;

		if (canProcess) {
			//Transaction ratelimit
			if (_from != address(_router) && _from != _pairAddress && !_isExcludedFromFee[_from]) {
				require(block.number >= _ratelimit[_from], "Too many transactions, try again in a couple of blocks.");
				_ratelimit[_from] = block.number + RATELIMIT_DELAY;
			}

			//Fee processing logic
			if (block.number >= (_feesLastProcessedAt + FEE_PROCESSING_DELAY) && balanceOf(address(this)) >= _feeProcessingThreshold && _from != _pairAddress) {
				processFees(_feeProcessingThreshold);
				hasProcessedFees = true;
			}
		}

		//Automatic buyback
		if (canProcess && !hasProcessedFees && _automaticBuybackAgent.getIsBuybackEnabled()) {
			if (_from != address(_router) && _to == _pairAddress) {
				processAutomaticBuyback();
			}
		}

		//Process the transfer itself
		_tokenTransfer(_from, _to, _amount);
	}

	function processFees(uint256 amount) private lockTheSwap {
		uint256 buybackFeeSum = _automaticBuybackFee.add(_manualBuybackFee);
		uint256 feeSum = buybackFeeSum.add(_marketingFee).add(_liquidityFee);

		//Don't bother processing if fees are zero
		if (buybackFeeSum == 0 || feeSum == 0) return;

		//Calculate all necessary amounts
		uint256 tokensForAutomaticBuyback = amount.mul(_automaticBuybackFee).div(feeSum);
		uint256 tokensForManualBuyback = amount.mul(_manualBuybackFee).div(feeSum);
		uint256 tokensForBuyback = tokensForAutomaticBuyback.add(tokensForManualBuyback);
		uint256 tokensForMarketing = amount.mul(_marketingFee).div(feeSum);
		uint256 tokensForLiquidity = amount.sub(tokensForBuyback).sub(tokensForMarketing);

		//Sell tokens to fuel the buyback (we swap them both in one transaction to optimize gas)
		uint256 ethReceivedForBuyback = swapExactTokensForETH(tokensForBuyback);
		uint256 ethReceivedForAutomaticBuyback = ethReceivedForBuyback.mul(_automaticBuybackFee).div(buybackFeeSum);
		uint256 ethReceivedForManualBuyback = ethReceivedForBuyback.sub(ethReceivedForAutomaticBuyback);

		//Send the newly swapped ETH to the buyback agents for later
		payable(_automaticBuybackAgent).transfer(ethReceivedForAutomaticBuyback);
		payable(_manualBuybackAgent).transfer(ethReceivedForManualBuyback);

		//Sell tokens and send to the the marketing wallet
		uint256 ethReceivedForMarketing = swapExactTokensForETH(tokensForMarketing);
		_marketingWallet.transfer(ethReceivedForMarketing);

		//The rest goes right into liquidity
		addLiquidity(tokensForLiquidity);

		//Ensure this cannot be called again for the next few blocks
		_feesLastProcessedAt = block.number;

		emit FeesProcessed(amount);
	}

	function swapExactTokensForETH(uint256 amountIn) private returns (uint256) {
		address self = address(this);

		address[] memory path = new address[](2);
		path[0] = self;
		path[1] = _router.WETH();

		_approve(self, address(_router), amountIn);

		uint256 initialBalance = self.balance;
		_router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, 0, path, self, block.timestamp);

		return self.balance.sub(initialBalance);
	}

	function addLiquidity(uint256 amountIn) private {
		address self = address(this);

		//Split the amount to liquify into halves
		uint256 tokensToSell = amountIn.div(2);
		uint256 tokensForLiquidity = amountIn.sub(tokensToSell);

		//Sell one half so that we can add to liquidity
		uint256 ethForLiquidity = swapExactTokensForETH(tokensToSell);

		//Add the liquidity
		_approve(self, address(_router), tokensForLiquidity);
		_router.addLiquidityETH{value : ethForLiquidity}(self, tokensForLiquidity, 0, 0, owner(), block.timestamp);
	}

	function processAutomaticBuyback() private lockTheSwap {
		_automaticBuybackAgent.buyback();
	}

	function _tokenTransfer(address sender, address recipient, uint256 amount) private {
		bool shouldTakeFee = !_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient];

		if (!shouldTakeFee) {
			_areFeesActive = false;
		}

		if (_isExcluded[sender] && !_isExcluded[recipient]) {
			_transferFromExcluded(sender, recipient, amount);
		} else if (!_isExcluded[sender] && _isExcluded[recipient]) {
			_transferToExcluded(sender, recipient, amount);
		} else if (_isExcluded[sender] && _isExcluded[recipient]) {
			_transferBothExcluded(sender, recipient, amount);
		} else {
			_transferStandard(sender, recipient, amount);
		}

		if (!shouldTakeFee) {
			_areFeesActive = true;
		}
	}

	function _reflectFee(uint256 rFee, uint256 tFee) private {
		_rTotal = _rTotal.sub(rFee);
		_tFeeTotal = _tFeeTotal.add(tFee);
	}

	function _getValues(uint256 tAmount, address recipient) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
		(uint256 tTransferAmount, uint256 tHolderReflectFee, uint256 tOtherFee) = _getTValues(tAmount, recipient);
		(uint256 rAmount, uint256 rTransferAmount, uint256 rHolderReflectFee) = _getRValues(tAmount, tHolderReflectFee, tOtherFee, _getRate());
		return (rAmount, rTransferAmount, rHolderReflectFee, tTransferAmount, tHolderReflectFee, tOtherFee);
	}

	function _getTValues(uint256 tAmount, address recipient) private view returns (uint256, uint256, uint256) {
		//Calculate value of fees taken for this transaction
		uint256 tWhaleTaxFee = calculateWhaleTaxFee(tAmount, recipient);
		uint256 tAutomaticBuybackFee = calculateAutomaticBuybackFee(tAmount);
		uint256 tManualBuybackFee = calculateManualBuybackFee(tAmount);
		uint256 tMarketingFee = calculateMarketingFee(tAmount);
		uint256 tHolderReflectFee = calculateHolderReflectFee(tAmount);
		uint256 tLiquidityFee = calculateLiquidityFee(tAmount);

		//Add up all fees besides the basic holder reflect fee
		uint256 tOtherFee = tWhaleTaxFee.add(tAutomaticBuybackFee).add(tManualBuybackFee).add(tMarketingFee).add(tLiquidityFee);

		return (tAmount.sub(tHolderReflectFee).sub(tOtherFee), tHolderReflectFee, tOtherFee);
	}

	function _getRValues(uint256 tAmount, uint256 tHolderReflectFee, uint256 tOtherFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
		uint256 rAmount = tAmount.mul(currentRate);
		uint256 rHolderReflectFee = tHolderReflectFee.mul(currentRate);
		uint256 rOtherFee = tOtherFee.mul(currentRate);
		uint256 rTransferAmount = rAmount.sub(rHolderReflectFee).sub(rOtherFee);
		return (rAmount, rTransferAmount, rHolderReflectFee);
	}

	function _getRate() private view returns (uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply.div(tSupply);
	}

	function _getCurrentSupply() private view returns (uint256, uint256) {
		uint256 rSupply = _rTotal;
		uint256 tSupply = _tTotal;

		for (uint256 i = 0; i < _excluded.length; i++) {
			if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
			rSupply = rSupply.sub(_rOwned[_excluded[i]]);
			tSupply = tSupply.sub(_tOwned[_excluded[i]]);
		}

		if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
		return (rSupply, tSupply);
	}

	function _takeFees(uint256 tOtherFee) private {
		address self = address(this);

		uint256 currentRate = _getRate();
		uint256 rOtherFee = tOtherFee.mul(currentRate);

		_rOwned[self] = _rOwned[self].add(rOtherFee);

		if (_isExcluded[self]) {
			_tOwned[self] = _tOwned[self].add(tOtherFee);
		}
	}

	function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rHolderReflectFee, uint256 tTransferAmount, uint256 tHolderReflectFee, uint256 tOtherFee) = _getValues(tAmount, recipient);
		_tOwned[sender] = _tOwned[sender].sub(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeFees(tOtherFee);
		_reflectFee(rHolderReflectFee, tHolderReflectFee);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rHolderReflectFee, uint256 tTransferAmount, uint256 tHolderReflectFee, uint256 tOtherFee) = _getValues(tAmount, recipient);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeFees(tOtherFee);
		_reflectFee(rHolderReflectFee, tHolderReflectFee);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rHolderReflectFee, uint256 tTransferAmount, uint256 tHolderReflectFee, uint256 tOtherFee) = _getValues(tAmount, recipient);
		_tOwned[sender] = _tOwned[sender].sub(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeFees(tOtherFee);
		_reflectFee(rHolderReflectFee, tHolderReflectFee);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferStandard(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rHolderReflectFee, uint256 tTransferAmount, uint256 tHolderReflectFee, uint256 tOtherFee) = _getValues(tAmount, recipient);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeFees(tOtherFee);
		_reflectFee(rHolderReflectFee, tHolderReflectFee);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function withdraw(uint256 amount) public onlyOwner {
		payable(owner()).transfer(amount == 0 ? address(this).balance : amount);
	}

	function forceProcessFees(uint256 amount) public onlyOwner {
		require(_isFeeProcessingEnabled, "Fee processing must be enabled to manually process fees.");
		require(!_areFeesBeingProcessed, "Contract cannot already be processing fees.");
		processFees(amount == 0 ? balanceOf(address(this)) : amount);
	}

	receive() external payable {}
}