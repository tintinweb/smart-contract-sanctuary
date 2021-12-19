/**
 *
 * Effortless Finance (EFFIN)
 *
 * BSD 3-Clause License (https://github.com/EffortlessFinance/Licenses/blob/main/LICENSE)
 *
 * Copyright (c) 2021, Effortless Finance Developments (https://www.effin.dev/) All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.2;

import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";
import "./IEFFINvaultV1.sol";

/**
 *
 * @title Effortless Finance (EFFIN)
 * @author Effortless Finance Developments (https://www.effin.dev/)
 * @notice This contract is licensed under BSD 3-Clause License (https://github.com/EffortlessFinance/Licenses/blob/main/LICENSE)
 *
 */

contract EFFIN_V2_3_6 is Initializable, IERC20Upgradeable {
	uint256 private _totalSupply;
	uint256 private _capitalGains;
	uint256 private _sgLiquidity;
	uint256 private _transactionTax;
	uint256 private _transactionLimit;
	uint256 private _transactionTimeLimit;
	uint256 private _maxAllowedBalance;	
	uint256 private _maxGainReference;	
	uint256 private _totalGainReference;	
	uint256 private _pendingTotalGains;
	uint256 private _pendingTotalLiquidity;
	uint256 private _pendingTotalPDF;
	uint256 private _internalTransferTrigger;
	uint256 private _overflow;
	uint256 private _reentrant;
	uint256 private _tokenomics;
	uint256 private _tokenomicsActive;
	uint256 private _debug;
	uint256 private _disablePDF;
	uint256 private _disableLiq;
	uint256 private _disableTax;
	uint256 private _disableGns;
	uint256 private _reportsToggle;
	uint256 private constant _FALSE_INT = 1;
	uint256 private constant _TRUE_INT = 2;

	uint8 private _decimals;

	IUniswapV2Router02 private swapRouter;
	IUniswapV2Pair private swapPair;
	IEFFINvaultV1 private effinVault;

	address private _projectDevelopmentAdmin;
	address private _projectDevelopmentFunds;
	address private _projectDevelopmentSafe;
	address private _routerAddress;
	address private _pairAddress;
	address private _pendingAdmin;
	address private _pendingPDF;

	mapping (address => uint256) private _balances;
	mapping (address => uint256) private _gainReference;
	mapping (address => uint256) private _overflowReference;
	mapping (address => uint256) private _transactionTime;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => bool) private _nogains;
	mapping (address => bool) private _notaxes;

	string private _name;
	string private _symbol;

	/**
	 *
	 * Effortless Finance (EFFIN)
	 * Tokenomics Details
	 *
	 * Capital Gains + Self Generated Liquidity = Transaction Tax
	 * Self Generated Liquidity Trigger {Contract Token Balance Tolerance Before WETH/WBNB Is Swapped}
	 * Capital Gains * {capitalGains + sgLiquidity}% = Project Development Funds
	 *
	 * DEPLOYED INITIAL VALUES
	 * | Token Name: Effortless Finance
	 * | Symbol: EFFIN
	 * | Decimals: 18
	 * | Total Supply: 1,000,000,000,000
	 * | Capital Gains: 5%
	 * | Self Generated Liquidity: 5%
	 * | Transaction Limit: 20,000,000,000 (2% of Total Supply)
	 * | Maximum Account Balance Limit: 100,000,000,000 (10% of Total Supply) <<
	 * | >> The limit does not apply to an account's gains and only limits
	 * | >> an account from receiving more from transfers and buys.
	 *
	 */

	receive() external payable { require(_msgData().length == 0); emit ReceivedContribution(msg.value); }

	/** @dev EFFIN Events */

	event ReceivedContribution(uint256 value);
	event AddedLiquidity(address indexed pairAddress, uint256 effinTokens, uint256 wrappedPair);
	event FundedProject(address indexed projectDevelopmentFunds, string developerMessge);
	event AdminNotice(address indexed adminAddress, string messgeString);
	event DappTransaction(address indexed senderAddress, uint256 senderAmount, uint256 senderEth);

	/** @dev EFFIN Context */

	function _msgSender() private view returns (address) {
		return msg.sender;
	}

	function _msgData() private view returns (bytes calldata) {
		this;
		return msg.data;
	}

	/** @dev EFFIN Modifiers */

	modifier onlyAdmin() {
		require(_projectDevelopmentAdmin == _msgSender(), "EFFIN: Not an administrator");
		_;
	}

	modifier nonReentrant() {
		require(_reentrant != _TRUE_INT, "EFFIN: Reentrant error");
		_reentrant = _TRUE_INT;
		_;
		_reentrant = _FALSE_INT;
	}

	/** @dev EFFIN Private Functions */

	function _isContract(address account) private view returns (bool) {
		uint256 size;
		assembly { size := extcodesize(account) }
		return size > 0;
	}

	function _updateReferences(address account) private {
		_gainReference[account] = _maxGainReference - _totalGainReference;
		_overflowReference[account] = _overflow;
	}

	function _setPercentGains(uint256 percent) private {
		_capitalGains = percent;
	}

	function _setPercentLiquidity(uint256 percent) private {
		_sgLiquidity = percent;
	}

	function _setPercentMaxAccountBalance(uint256 percent) private {
		_maxAllowedBalance = (_totalSupply * percent) / (10**2);
	}

	function _setPercentTransactionLimit(uint256 percent) private {
		_transactionLimit = (_totalSupply * percent) / (10**2);
	}

	function _setSpecificMaxAccountBalance(uint256 limit) private {
		_maxAllowedBalance = limit;
	}

	function _setSpecificTransactionLimit(uint256 limit) private {
		_transactionLimit = limit;
	}

	function _setTimeTransactionLimit(uint256 secondsInt) private {
		_transactionTimeLimit = (secondsInt * 1 seconds);
	}

	function _setRouterAddress(address routerAddress) private nonReentrant {
		require(_isContract(routerAddress), "EFFIN: Router address not contract");
		swapRouter = IUniswapV2Router02(routerAddress);
		_routerAddress = address(swapRouter);
		_nogains[_routerAddress] = true;
		_notaxes[_routerAddress] = true;
	}

	function _setPairAddress() private nonReentrant {
		require(_routerAddress != address(0), "EFFIN: Router is zero address");
		swapRouter = IUniswapV2Router02(_routerAddress);
		IUniswapV2Factory swapFactory = IUniswapV2Factory(swapRouter.factory());
		_pairAddress = swapFactory.getPair(address(this), swapRouter.WETH());
		if (_pairAddress == address(0)) {
			_pairAddress = swapFactory.createPair(address(this), swapRouter.WETH());
		}
		_nogains[_pairAddress] = true;
		_notaxes[_pairAddress] = true;
	}

	function _setDexTrigger(uint256 amount) private {
		_internalTransferTrigger = amount;
	}

	function _setAddressGainsOff(address account) private nonReentrant {
		_disburseAction(account);
		_updateReferences(account);
		_nogains[account] = true;
	}

	function _setAddressGainsOn(address account) private nonReentrant {
		_updateReferences(account);
		_nogains[account] = false;
	}

	function _setAddressTaxedOff(address account) private {
		_notaxes[account] = true;
	}

	function _setAddressTaxedOn(address account) private {
		_notaxes[account] = false;
	}

	function _setAddressBothTaxedGainsOff(address account) private {
		_setAddressTaxedOff(account);
		_setAddressGainsOff(account);
	}

	function _setAddressBothTaxedGainsOn(address account) private {
		_setAddressTaxedOn(account);
		_setAddressGainsOn(account);
	}

	function _tokenAdminAddress(address admin) private nonReentrant {
		require(_projectDevelopmentAdmin == _msgSender(), "EFFIN: Not project admin");
		require(admin != address(0), "EFFIN: New admin is zero address");
		_pendingAdmin = admin;
		emit AdminNotice(_pendingAdmin, "EFFIN: Initiated new admin pending");
	}

	function _tokenAdminAddressConfirm() private {
		require(_pendingAdmin != address(0), "EFFIN: New admin is zero address");
		require(_pendingAdmin == _msgSender(), "EFFIN: Not project admin");
		address _oldAdmin = _projectDevelopmentAdmin;
		_projectDevelopmentAdmin = _pendingAdmin;
		_setAddressBothTaxedGainsOff(_projectDevelopmentAdmin);
		_setAddressBothTaxedGainsOn(_oldAdmin);
		_pendingAdmin = address(0);
		emit AdminNotice(_projectDevelopmentAdmin, "EFFIN: New admin set");
	}

	function _tokenAdminAddressRevert() private nonReentrant {
		require(_projectDevelopmentAdmin == _msgSender(), "EFFIN: Not project admin");
		_pendingAdmin = address(0);
		emit AdminNotice(_pendingAdmin, "EFFIN: Cancelled new admin pending");
	}

	function _tokenAdminFunds(address admin) private nonReentrant {
		require(_projectDevelopmentAdmin == _msgSender(), "EFFIN: Not project admin");
		require(admin != address(0), "EFFIN: New PDF is zero address");
		_pendingPDF = admin;
		emit AdminNotice(_pendingPDF, "EFFIN: Initiated new PDF pending");
	}

	function _tokenAdminFundsConfirm() private {
		require(_pendingPDF != address(0), "EFFIN: New PDF is zero address");
		require(_pendingPDF == _msgSender(), "EFFIN: Not PDF");
		address _oldPDF = _projectDevelopmentFunds;
		_projectDevelopmentFunds = _pendingPDF;
		_setAddressBothTaxedGainsOff(_projectDevelopmentFunds);
		_setAddressBothTaxedGainsOn(_oldPDF);
		_pendingPDF = address(0);
		emit AdminNotice(_projectDevelopmentFunds, "EFFIN: New PDF set");
	}

	function _tokenAdminFundsRevert() private nonReentrant {
		require(_projectDevelopmentAdmin == _msgSender(), "EFFIN: Not project admin");
		_pendingPDF = address(0);
		emit AdminNotice(_pendingAdmin, "EFFIN: Cancelled new PDF pending");
	}

	function _tokenAdminSafe(address safeAddress) private nonReentrant {
		require(_projectDevelopmentAdmin == _msgSender(), "EFFIN: Not project admin");
		require(safeAddress != address(0), "EFFIN: New safe is zero address");
		require((_projectDevelopmentAdmin == safeAddress) || _isContract(safeAddress), "EFFIN: Safe address not contract");
		effinVault = IEFFINvaultV1(safeAddress);
		_projectDevelopmentSafe = address(effinVault);
		emit AdminNotice(_projectDevelopmentSafe, "EFFIN: Safe address updated");
	}

	function _toggleTokenomicsActivity(bool boolean) private {
		_tokenomics = boolean == true ? _TRUE_INT : _FALSE_INT;
	}

	function _toggleTokenomicsDebug(bool boolean) private {
		_debug = boolean == true ? _TRUE_INT : _FALSE_INT;
	}

	function _toggleTokenomicsProjectFund(bool boolean) private {
		_disablePDF = boolean == true ? _TRUE_INT : _FALSE_INT;
	}

	function _toggleTokenomicsLiquidity(bool boolean) private {
		_disableLiq = boolean == true ? _TRUE_INT : _FALSE_INT;
	}

	function _toggleTokenomicsTaxAmount(bool boolean) private {
		_disableTax = boolean == true ? _TRUE_INT : _FALSE_INT;
	}

	function _toggleTokenomicsGains(bool boolean) private {
		_disableGns = boolean == true ? _TRUE_INT : _FALSE_INT;
	}

	function _toggleTokenomicsReports(bool boolean) private {
		_reportsToggle = boolean == true ? _TRUE_INT : _FALSE_INT;
	}

	function _tokenManualTriggerStray() private nonReentrant {
		require(address(this).balance > 0, "EFFIN: Contract has no balance");
		payable(_projectDevelopmentFunds).transfer(address(this).balance);
	}

	function _tokenManualTriggerStrayERC20(IERC20Upgradeable ercToken) private nonReentrant {
		require(ercToken.balanceOf(address(this)) > 0, "EFFIN: Contract has no balance");
		if (address(this) == address(ercToken)) {
			uint256 stayBalance = ((ercToken.balanceOf(address(this)) - _pendingTotalGains) - _pendingTotalLiquidity) - _pendingTotalPDF;
			require(ercToken.transfer(_projectDevelopmentFunds, stayBalance), "EFFIN: Transfer failed");
		} else {
			require(ercToken.transfer(_projectDevelopmentFunds, ercToken.balanceOf(address(this))), "EFFIN: Transfer failed");
		}
	}

	/** @dev EFFIN Tokenomics Private Functions */

	function _taxCalculation(uint256 amount) private view returns (uint256, uint256, uint256, uint256, uint256) {
		uint256 supplyNow = _balances[address(this)] > amount ? _balances[_pairAddress] + (_balances[address(this)] - amount) : _balances[_pairAddress] - amount;

		uint256 pdfTax = (amount * _transactionTax) / (10**3);
		uint256 sgLiquidityTax = (amount * _sgLiquidity) / (10**2);
		uint256 capitalGainsTax = (amount * _capitalGains) / (10**2);
		capitalGainsTax -= pdfTax;
		uint256 transactionTax = (amount * _transactionTax) / (10**2);

		uint256 realocateGains = capitalGainsTax * supplyNow;
		realocateGains = realocateGains / _totalSupply;

		pdfTax += (realocateGains * _transactionTax) / (10**3);
		sgLiquidityTax += (realocateGains * _sgLiquidity) / (10**2);
		capitalGainsTax = transactionTax - (pdfTax + sgLiquidityTax);

		return (realocateGains + capitalGainsTax, pdfTax, sgLiquidityTax, capitalGainsTax, transactionTax);
	}

	function _taxAction(address sender, address recipient, uint256 amount) private returns (uint256) {
		if (_disableTax == _TRUE_INT) return amount;

		(uint256 totalGainReference, uint256 pdfTax, uint256 sgLiquidityTax, uint256 capitalGainsTax, uint256 transactionTax) = _taxCalculation(amount);

		_totalGainReference -= totalGainReference;
		_pendingTotalPDF += pdfTax;
		_pendingTotalLiquidity += sgLiquidityTax;
		_pendingTotalGains += capitalGainsTax;

		_gainReference[sender] = _maxGainReference - _totalGainReference;
		_gainReference[recipient] = _maxGainReference - _totalGainReference;

		amount -= transactionTax;
		_balances[address(this)] += transactionTax;

		if (_maxAllowedBalance < (_balances[recipient] + amount)) require(_notaxes[recipient], "EFFIN: Recipient balance exceeds allowed limit.");

		delete totalGainReference;
		delete pdfTax;
		delete sgLiquidityTax;
		delete capitalGainsTax;
		delete transactionTax;

		return amount;
	}

	function _balanceOf(address account) private view returns (uint256, uint256, uint256, uint256) {
		uint256 balances = _balances[account];
		uint256 gainReference = _gainReference[account];
		uint256 overflowReference = _overflowReference[account];
		uint256 gain;
		uint256 gainRefNow = _maxGainReference - _totalGainReference;

		if (balances <= 0) {
			gainReference = gainRefNow;
			overflowReference = _overflow;
		}

		if (gainReference <= 0) {
			gainReference = gainRefNow;
			overflowReference = _overflow;
		}

		if ((gainReference > gainRefNow) && (overflowReference >= _overflow)) {
			gainReference = gainRefNow;
			overflowReference = _overflow;
		}

		if ((_disableGns != _TRUE_INT) && (balances > 0)) {
			if (_overflow > overflowReference) {
				gain = ((_maxGainReference - gainReference) / _totalSupply) * balances;
				overflowReference = _overflow;
				if (gain > _pendingTotalGains) {
					gain = 0;
				} else {
					gainReference = gainRefNow;
				}
			}

			if (gainReference < gainRefNow) {
				gain += ((gainRefNow - gainReference) * balances) / _totalSupply;
				gainReference = gainRefNow;
			}

			if (gain > _pendingTotalGains) gain = 0;
		} else {
			gainReference = gainRefNow;
		}

		delete gainRefNow;

		return (balances, gainReference, overflowReference, gain);
	}

	function _disburseAction(address account) private {
		/** @dev Overflow protection for continuity */
		if (_totalGainReference <= _totalSupply) {
			_totalGainReference = _maxGainReference;	
			_overflow += 1;
		}

		(uint256 balances, uint256 gainReference, uint256 overflowReference, uint256 gain) = _balanceOf(account);

		if (gain > 0) {
			balances += gain;
			_balances[address(this)] -= gain;
			_pendingTotalGains -= gain;
		}

		_gainReference[account] = gainReference;
		_overflowReference[account] = overflowReference;
		_balances[account] = balances;

		delete balances;
		delete gainReference;
		delete overflowReference;
		delete gain;
	}

	function _dexAction() private {
		uint256 tokenomicsPreviousStatus;
		tokenomicsPreviousStatus = _tokenomics;
		_tokenomics = _FALSE_INT;
		if ((_pendingTotalLiquidity >= _internalTransferTrigger) && (_disableLiq != _TRUE_INT)) {
			address[] memory pathA = new address[](2);
			pathA[0] = address(this);
			pathA[1] = swapRouter.WETH();

			uint256 tokenPairAmount = _internalTransferTrigger / 2;
			uint256 tokenThisAmount = _internalTransferTrigger - tokenPairAmount;
			uint256 ethBalance = address(this).balance;

			_approve(address(this), address(swapRouter), tokenPairAmount);
			swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenPairAmount, 0, pathA, address(this), block.timestamp);

			_pendingTotalLiquidity -= tokenPairAmount;

			uint256 newWethBalance = address(this).balance;
			uint256 ethForLiquidity = newWethBalance - ethBalance;

			_approve(address(this), address(swapRouter), tokenThisAmount);
			swapRouter.addLiquidityETH{value: ethForLiquidity}(address(this), tokenThisAmount, 0, 0, _projectDevelopmentSafe, block.timestamp);

			_pendingTotalLiquidity -= tokenThisAmount;

			emit AddedLiquidity(_pairAddress, tokenThisAmount, ethForLiquidity);

			delete pathA;
			delete tokenPairAmount;
			delete tokenThisAmount;
			delete ethBalance;
			delete newWethBalance;
			delete ethForLiquidity;
		} else if ((_pendingTotalPDF >= (_internalTransferTrigger / 2)) && (_disablePDF != _TRUE_INT)) {
			address[] memory pathB = new address[](2);
			pathB[0] = address(this);
			pathB[1] = swapRouter.WETH();

			uint256 pdfAmount = _internalTransferTrigger / 2;

			_approve(address(this), address(swapRouter), pdfAmount);
			swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(pdfAmount, 0, pathB, address(this), block.timestamp);

			_pendingTotalPDF -= pdfAmount;

			if (address(this).balance >= 1000000000000000000) payable(_projectDevelopmentFunds).transfer(address(this).balance);

			emit FundedProject(_projectDevelopmentFunds, "Thank you for your support");

			delete pathB;
			delete pdfAmount;
		}
		_tokenomics = tokenomicsPreviousStatus;
		delete tokenomicsPreviousStatus;
	}

	function _tokenomicsHook(address sender, address recipient, uint256 amount) private returns (uint256) {
		_tokenomicsActive = _TRUE_INT;
			require (amount <= _transactionLimit, "EFFIN: Amount is more than transaction limit");
			require (_transactionTime[sender] <= block.timestamp, "EFFIN: Over allowed transaction time");

 			//if (!_nogains[sender]) _dexAction();
			
			//if (!_nogains[sender]) _disburseAction(sender);

			//if (!_nogains[recipient]) _disburseAction(recipient);

			if (_notaxes[sender] && _notaxes[recipient]) {
				//_gainReference[sender] = _maxGainReference - _totalGainReference;
				//_gainReference[recipient] = _maxGainReference - _totalGainReference;
			} else {
				//amount = _taxAction(sender, recipient, amount);
			}

			//_transactionTime[sender] = block.timestamp + _transactionTimeLimit;

		_tokenomicsActive = _FALSE_INT;
		return amount;
	}

	function _transfer(address sender, address recipient, uint256 amount) private {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");
		require(_debug != _TRUE_INT, "EFFIN: No transfers while debug is active");
		if (sender != address(this)) require(_reentrant != _TRUE_INT, "EFFIN: Reentrant error");
		_reentrant = _TRUE_INT;

		uint256 taxedAmount =
			(sender == _projectDevelopmentAdmin) ||
			(recipient == _projectDevelopmentAdmin) ||
			(sender == _pairAddress) && (recipient == _routerAddress) ||
			(_tokenomics != _TRUE_INT) ||
			(_tokenomicsActive == _TRUE_INT)
		? amount : _tokenomicsHook(sender, recipient, amount);

		_balances[sender] -= amount;
		_balances[recipient] += taxedAmount;
		emit Transfer(sender, recipient, taxedAmount);

		_reentrant = _FALSE_INT;
	}

	/** @dev EFFIN Dapps Private Link Functions */

	function _dappTransactToken(uint256 amount) private returns (bool) {
		require(_balances[_msgSender()] >= amount, "EFFIN Dapp: Sender does not have enough balance.");
		uint256 supplyNow;
		uint256 pdfTax;
		uint256 sgLiquidityTax;
		uint256 capitalGainsTax;
		uint256 realocateGains;

		_balances[_msgSender()] -= amount;
		_balances[address(this)] += amount;

		supplyNow = _balances[_pairAddress] + _balances[address(this)];

		pdfTax = (amount * _transactionTax) / (10**2);
		sgLiquidityTax = (amount * _sgLiquidity) / 10;
		capitalGainsTax = (amount * _capitalGains) / 10;
		capitalGainsTax -= pdfTax;

		realocateGains = capitalGainsTax * supplyNow;
		realocateGains = realocateGains / _totalSupply;

		pdfTax += (realocateGains * _transactionTax) / (10**2);
		sgLiquidityTax += (realocateGains * _sgLiquidity) / 10;
		capitalGainsTax = amount - (pdfTax + sgLiquidityTax);

		_totalGainReference -= realocateGains + capitalGainsTax;
		_pendingTotalPDF += pdfTax;
		_pendingTotalLiquidity += sgLiquidityTax;
		_pendingTotalGains += capitalGainsTax;

		_gainReference[_msgSender()] = _maxGainReference - _totalGainReference;

		emit Transfer(_msgSender(), address(this), amount);
		emit DappTransaction(_msgSender(), amount, msg.value);

		delete supplyNow;
		delete pdfTax;
		delete sgLiquidityTax;
		delete capitalGainsTax;
		delete realocateGains;

		return true;
	}

	/** @dev EFFIN External Variables */

	function Reentrant() external view returns (bool) {
		return _reentrant == _TRUE_INT ? true : false;
	}

	function TokenomicsActive() external view returns (bool) {
		return _tokenomicsActive == _TRUE_INT ? true : false;
	}

	function Tokenomics() external view returns (bool) {
		return _tokenomics == _TRUE_INT ? true : false;
	}

	function CapitalGains() external view returns (uint256) {
		return _capitalGains;
	}

	function SelfGeneratedLiquidity() external view returns (uint256) {
		return _sgLiquidity;
	}

	function TransactionLimit() external view returns (uint256) {
		return _transactionLimit;
	}

	function MaximumBuyLimit() external view returns (uint256) {
		return _maxAllowedBalance;
	}

	function TransactionTimeLimit() external view returns (uint256) {
		return _transactionTimeLimit;
	}

	function PairAddress() external view returns (address) {
		return _pairAddress;
	}

	function RouterAddress() external view returns (address) {
		return _routerAddress;
	}

	function LPLockedStatus() external view returns (bool) {
		return _isContract(_projectDevelopmentSafe) ? effinVault.LockStatus() : false;
	}

	function LPUnlockDate() external view returns (uint256) {
		return _isContract(_projectDevelopmentSafe) ? effinVault.LockTimeEnd() : 0;
	}

	function LPLockedToken() external view returns (address) {
		return _isContract(_projectDevelopmentSafe) ? effinVault.TokenAddress() : address(0);
	}

	function dividendOf(address account) external view returns (uint256) {
		(, , , uint256 gain) = _balanceOf(account);
		return gain;
	}

	/** @dev EFFIN Tokenomics Admin Reports */

	function reportsAccount(address account) external view returns (uint256, uint256, uint256, bool, bool) {
		return _reportsToggle == _TRUE_INT ? (_balances[account], _gainReference[account], _overflowReference[account], _nogains[account], _notaxes[account]) : (0, 0, 0, false, false);
	}

	function reportsUints() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
		uint256 tokenLeaks = ((_balances[address(this)] - _pendingTotalGains) - _pendingTotalLiquidity) - _pendingTotalPDF;
		return _reportsToggle == _TRUE_INT ? (tokenLeaks, _maxGainReference - _totalGainReference, _balances[_pairAddress], _overflow, _pendingTotalGains, _pendingTotalLiquidity, _pendingTotalPDF, _internalTransferTrigger) : (0, 0, 0, 0, 0, 0, 0, 0);
	}

	function reportsBools() external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
		return _reportsToggle == _TRUE_INT ? (_reportsToggle, _disablePDF, _disableLiq, _disableTax, _disableGns, _tokenomicsActive) : (_reportsToggle, 1, 1, 1, 1, 1);
	}

	function reportsAdministration() external view returns (address, address, address, address, address) {
		return _reportsToggle == _TRUE_INT ? (_projectDevelopmentAdmin, _pendingAdmin, _projectDevelopmentFunds, _pendingPDF, _projectDevelopmentSafe) : (address(0), address(0), address(0), address(0), address(0));
	}

	function reportsTaxCalculation(uint256 amount) external view returns (uint256, uint256, uint256, uint256, uint256) {
		(uint256 totalGainReference, uint256 pdfTax, uint256 sgLiquidityTax, uint256 capitalGainsTax, uint256 transactionTax) = _taxCalculation(amount);
		return _reportsToggle == _TRUE_INT ? (totalGainReference, pdfTax, sgLiquidityTax, capitalGainsTax, transactionTax) : (0, 0, 0, 0, 0);
	}

	/** @dev EFFIN Tokenomics Admin Functions */

	function setPercentGains(uint256 percent) external onlyAdmin {
		_setPercentGains(percent);
	}

	function setPercentLiquidity(uint256 percent) external onlyAdmin {
		_setPercentLiquidity(percent);
	}

	function setPercentTransactionLimit(uint256 percent) external onlyAdmin {
		_setPercentTransactionLimit(percent);
	}

	function setPercentMaxAccountBalance(uint256 percent) external onlyAdmin {
		_setPercentMaxAccountBalance(percent);
	}

	function setSpecificTransactionLimit(uint256 limit) external onlyAdmin {
		_setSpecificTransactionLimit(limit);
	}

	function setSpecificMaxAccountBalance(uint256 limit) external onlyAdmin {
		_setSpecificMaxAccountBalance(limit);
	}

	function setTimeTransactionLimit(uint256 secondsInt) external onlyAdmin {
		_setTimeTransactionLimit(secondsInt);
	}

	function setDexRouterAddress(address router) external onlyAdmin {
		_setRouterAddress(router);
		_setPairAddress();
	}

	function setDexPairAddress() external onlyAdmin {
		_setPairAddress();
	}

	function setDexTrigger(uint256 amount) external onlyAdmin {
		_setDexTrigger(amount);
	}

	function setAddressGainsOff(address account) external onlyAdmin {
		_setAddressGainsOff(account);
	}

	function setAddressGainsOn(address account) external onlyAdmin {
		_setAddressGainsOn(account);
	}

	function setAddressTaxedOff(address account) external onlyAdmin {
		_setAddressTaxedOff(account);
	}

	function setAddressTaxedOn(address account) external onlyAdmin {
		_setAddressTaxedOn(account);
	}

	function setAddressBothTaxedGainsOff(address account) external onlyAdmin {
		_setAddressBothTaxedGainsOff(account);
	}

	function setAddressBothTaxedGainsOn(address account) external onlyAdmin {
		_setAddressBothTaxedGainsOn(account);
	}

	/** @dev EFFIN Contract Admin Management. */

	function tokenAdminAddress(address admin) external onlyAdmin {
		_tokenAdminAddress(admin);
	}

	function tokenAdminAddressConfirm() external {
		_tokenAdminAddressConfirm();
	}

	function tokenAdminAddressRevert() external onlyAdmin {
		_tokenAdminAddressRevert();
	}

	function tokenAdminFunds(address admin) external onlyAdmin {
		_tokenAdminFunds(admin);
	}

	function tokenAdminFundsConfirm() external {
		_tokenAdminFundsConfirm();
	}

	function tokenAdminFundsRevert() external onlyAdmin {
		_tokenAdminFundsRevert();
	}

	function tokenAdminSafe(address safeAddress) external onlyAdmin {
		_tokenAdminSafe(safeAddress);
	}

	/** @dev EFFIN Token Admin Toggles. */

	function toggleTokenomicsActivity(bool boolean) external onlyAdmin {
		_toggleTokenomicsActivity(boolean);
	}

	function toggleDebug(bool boolean) external onlyAdmin {
		_toggleTokenomicsDebug(boolean);
	}

	function toggleTokenomicsProjectFund(bool boolean) external onlyAdmin {
		_toggleTokenomicsProjectFund(boolean);
	}

	function toggleTokenomicsLiquidity(bool boolean) external onlyAdmin {
		_toggleTokenomicsLiquidity(boolean);
	}

	function toggleTokenomicsTaxAmount(bool boolean) external onlyAdmin {
		_toggleTokenomicsTaxAmount(boolean);
	}

	function toggleTokenomicsGains(bool boolean) external onlyAdmin {
		_toggleTokenomicsGains(boolean);
	}

	function toggleTokenomicsReports(bool boolean) external onlyAdmin {
		_toggleTokenomicsReports(boolean);
	}

	function tokenManualDexAction() external {
		_dexAction();
	}

	function tokenManualTriggerStray() external onlyAdmin {
		_tokenManualTriggerStray();
	}

	function tokenManualTriggerStrayERC20(IERC20Upgradeable ercToken) external onlyAdmin {
		_tokenManualTriggerStrayERC20(ercToken);
	}

	/** @dev EFFIN Dapps External Functions */

	function dappTransactToken(uint256 amount) external returns (bool) {
		return _dappTransactToken(amount);
	}

	function dappTransactTokenWithEth() external payable returns (bool, uint256, uint256) {
		require(_reentrant != _TRUE_INT, "EFFIN: Reentrant error");
		// require(_msgSender().balance >= msg.value, "EFFIN Dapp: Sender does not have enough ETH balance.");

		_reentrant = _TRUE_INT;

		address[] memory path = new address[](2);
		path[0] = swapRouter.WETH();
		path[1] = address(this);

		uint256 tokenomicsPreviousStatus;
		uint256 tokenBalance;
		uint256 tokenNewBalance;
		uint256 paymentAmount;
		uint256 supplyNow;
		uint256 pdfTax;
		uint256 sgLiquidityTax;
		uint256 capitalGainsTax;
		uint256 realocateGains;

		tokenomicsPreviousStatus = _tokenomics;
		_tokenomics = _FALSE_INT;

		_reentrant = _FALSE_INT;
		_disburseAction(_msgSender());
		tokenBalance = _balances[_msgSender()];
		swapRouter.swapExactETHForTokens{value: msg.value}(0, path, _msgSender(), block.timestamp);
		tokenNewBalance = _balances[_msgSender()];
		paymentAmount = tokenNewBalance - tokenBalance;
		_reentrant = _TRUE_INT;

		require(_balances[_msgSender()] >= paymentAmount, "EFFIN Dapp: ETH swap did not create enough tokens.");

		_balances[_msgSender()] -= paymentAmount;
		_balances[address(this)] += paymentAmount;

		supplyNow = _balances[_pairAddress] + _balances[address(this)];

		pdfTax = (paymentAmount * _transactionTax) / (10**2);
		sgLiquidityTax = (paymentAmount * _sgLiquidity) / 10;
		capitalGainsTax = (paymentAmount * _capitalGains) / 10;
		capitalGainsTax -= pdfTax;

		realocateGains = capitalGainsTax * supplyNow;
		realocateGains = realocateGains / _totalSupply;

		pdfTax += (realocateGains * _transactionTax) / (10**2);
		sgLiquidityTax += (realocateGains * _sgLiquidity) / 10;
		capitalGainsTax = paymentAmount - (pdfTax + sgLiquidityTax);

		_totalGainReference -= realocateGains + capitalGainsTax;
		_pendingTotalPDF += pdfTax;
		_pendingTotalLiquidity += sgLiquidityTax;
		_pendingTotalGains += capitalGainsTax;

		_updateReferences(_msgSender());

		_updateReferences(_pairAddress);

		_tokenomics = tokenomicsPreviousStatus;

		emit Transfer(_msgSender(), address(this), paymentAmount);
		emit DappTransaction(_msgSender(), paymentAmount, msg.value);

		delete path;
		delete tokenomicsPreviousStatus;
		delete tokenBalance;
		delete tokenNewBalance;
		delete supplyNow;
		delete pdfTax;
		delete sgLiquidityTax;
		delete capitalGainsTax;
		delete realocateGains;

		_reentrant = _FALSE_INT;

		return (true, paymentAmount, msg.value);
	}

	/** @dev Standard ERC20 Token Functions */

	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function decimals() public view returns (uint8) {
		return _decimals;
	}

	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
		return true;
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	/** @dev Overide Standard ERC20 Token Functions */

	function totalSupply() external view override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) external view override returns (uint256) {
		(uint256 balances, , , uint256 gain) = _balanceOf(account);
		return balances + gain;
	}

	function allowance(address owner, address spender) external view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) external override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
		return true;
	}
}