pragma solidity 0.8.0;
// SPDX-License-Identifier: Unlicensed

import "./IERC20.sol";
import "./AntiBot.sol";
import "./Address.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract MINXIE is Context, IERC20, Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using Address for address;

	mapping (address => uint256) private _rOwned;
	mapping (address => uint256) private _tOwned;
	mapping (address => mapping (address => uint256)) private _allowances;

	mapping (address => bool) private _isExcludedFromFee;
	mapping (address => bool) private _isExcludedFromReward;
	address[] private _excludedFromReward;

	address BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

	uint256 private constant MAX = ~uint256(0);
	uint256 private _tTotal = 10000000000 * 10**18;
	uint256 private _rTotal = (MAX - (MAX % _tTotal));
	uint256 private _tHODLrRewardsTotal;
    IPinkAntiBot public pinkAntiBot;
    bool public antiBotEnabled;

	string private _name = "MINXIE";
	string private _symbol = "MINX";
	uint8 private _decimals = 18;

	uint256 public _rewardFee = 3;
	uint256 private _previousRewardFee = _rewardFee;

	uint256 public _burnFee = 3;
	uint256 private _previousBurnFee = _burnFee;


	uint256 public _maxTxAmount = 10000000000 * 10**18;

	event TransferBurn(address indexed from, address indexed burnAddress, uint256 value);

	constructor () {
        address pinkAntiBot_  = 0xbb06F5C7689eA93d9DeACCf4aF8546C4Fe0Bf1E5;
		_rOwned[_msgSender()] = _rTotal;
		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromReward[address(this)] = true;
		_isExcludedFromFee[BURN_ADDRESS] = true;
		_isExcludedFromReward[BURN_ADDRESS] = true;
		emit Transfer(address(0), _msgSender(), _tTotal);
        pinkAntiBot = IPinkAntiBot(pinkAntiBot_);
        pinkAntiBot.setTokenOwner(msg.sender);
	}

	function name() public view returns (string memory) {return _name;}
	function symbol() public view returns (string memory) {return _symbol;}
	function decimals() public view returns (uint8) {return _decimals;}
	function totalSupply() public view override returns (uint256) {return _tTotal;}

	function balanceOf(address account) public view override returns (uint256) {
		if (_isExcludedFromReward[account]) return _tOwned[account];
		return tokenFromReflection(_rOwned[account]);
	}

    function setEnableAntiBot(bool _enable) external onlyOwner {
    antiBotEnabled = _enable;
}

	function withdraw() external onlyOwner nonReentrant{
		uint256 balance = IERC20(address(this)).balanceOf(address(this));
		IERC20(address(this)).transfer(msg.sender, balance);
		payable(msg.sender).transfer(address(this).balance);
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
        if (antiBotEnabled) {
        pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
     }
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

	function totalHODLrRewards() public view returns (uint256) {
		return _tHODLrRewardsTotal;
	}

	function totalBurned() public view returns (uint256) {
		return balanceOf(BURN_ADDRESS);
	}

	function deliver(uint256 tAmount) public {
		address sender = _msgSender();
		require(!_isExcludedFromReward[sender], "Excluded addresses cannot call this function");
		(uint256 rAmount,,,,,) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rTotal = _rTotal.sub(rAmount);
		_tHODLrRewardsTotal = _tHODLrRewardsTotal.add(tAmount);
	}

	function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
		require(tAmount <= _tTotal, "Amount must be less than supply");
		if (!deductTransferFee) {
			(uint256 rAmount,,,,,) = _getValues(tAmount);
			return rAmount;
		} else {
			(,uint256 rTransferAmount,,,,) = _getValues(tAmount);
			return rTransferAmount;
		}
	}

	function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
		require(rAmount <= _rTotal, "Amount must be less than total reflections");
		uint256 currentRate =  _getRate();
		return rAmount.div(currentRate);
	}

	function isExcludedFromReward(address account) public view returns (bool) {
		return _isExcludedFromReward[account];
	}

	function excludeFromReward(address account) public onlyOwner {
		require(!_isExcludedFromReward[account], "Account is already excluded");
		if(_rOwned[account] > 0) {
			_tOwned[account] = tokenFromReflection(_rOwned[account]);
		}
		_isExcludedFromReward[account] = true;
		_excludedFromReward.push(account);
	}

	function includeInReward(address account) external onlyOwner {
		require(_isExcludedFromReward[account], "Account is already excluded");
		for (uint256 i = 0; i < _excludedFromReward.length; i++) {
			if (_excludedFromReward[i] == account) {
				_excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
				_tOwned[account] = 0;
				_isExcludedFromReward[account] = false;
				_excludedFromReward.pop();
				break;
			}
		}
	}

	function excludeFromFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = true;
	}

	function includeInFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = false;
	}

	function setRewardFeePercent(uint256 rewardFee) external onlyOwner {
		_rewardFee = rewardFee;
	}

	function setBurnFeePercent(uint256 burnFee) external onlyOwner {
		_burnFee = burnFee;
	}

	function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
		_maxTxAmount = _tTotal.mul(maxTxPercent).div(
			10**2
		);
	}

	receive() external payable {}

	function _HODLrFee(uint256 rHODLrFee, uint256 tHODLrFee) private {
		_rTotal = _rTotal.sub(rHODLrFee);
		_tHODLrRewardsTotal = _tHODLrRewardsTotal.add(tHODLrFee);
	}

	function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
		(uint256 tTransferAmount, uint256 tHODLrFee, uint256 tBurn) = _getTValues(tAmount);
		(uint256 rAmount, uint256 rTransferAmount, uint256 rHODLrFee) = _getRValues(tAmount, tHODLrFee, tBurn, _getRate());
		return (rAmount, rTransferAmount, rHODLrFee, tTransferAmount, tHODLrFee, tBurn);
	}

	function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
		uint256 tHODLrFee = calculateRewardFee(tAmount);
		uint256 tBurn = calculateBurnFee(tAmount);
		uint256 tTransferAmount = tAmount.sub(tHODLrFee).sub(tBurn);
		return (tTransferAmount, tHODLrFee, tBurn);
	}

	function _getRValues(uint256 tAmount, uint256 tHODLrFee, uint256 tBurn, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
		uint256 rAmount = tAmount.mul(currentRate);
		uint256 rHODLrFee = tHODLrFee.mul(currentRate);
		uint256 rBurn = tBurn.mul(currentRate);
		uint256 rTransferAmount = rAmount.sub(rHODLrFee).sub(rBurn);
		return (rAmount, rTransferAmount, rHODLrFee);
	}

	function _getRate() private view returns(uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply.div(tSupply);
	}

	function _getCurrentSupply() private view returns(uint256, uint256) {
		uint256 rSupply = _rTotal;
		uint256 tSupply = _tTotal;
		for (uint256 i = 0; i < _excludedFromReward.length; i++) {
			if (_rOwned[_excludedFromReward[i]] > rSupply || _tOwned[_excludedFromReward[i]] > tSupply) return (_rTotal, _tTotal);
			rSupply = rSupply.sub(_rOwned[_excludedFromReward[i]]);
			tSupply = tSupply.sub(_tOwned[_excludedFromReward[i]]);
		}
		if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
		return (rSupply, tSupply);
	}



	function calculateRewardFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_rewardFee).div(
			10**2
		);
	}

	function calculateBurnFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_burnFee).div(
			10**2
		);
	}

	function removeAllFee() private {
		if(_rewardFee == 0 && _burnFee == 0) return;
		_previousRewardFee = _rewardFee;
		_previousBurnFee = _burnFee;
		_rewardFee = 0;
		_burnFee = 0;
	}

	function restoreAllFee() private {
		_rewardFee = _previousRewardFee;
		_burnFee = _previousBurnFee;
	}

	function isExcludedFromFee(address account) public view returns(bool) {
		return _isExcludedFromFee[account];
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _transfer(
		address from,
		address to,
		uint256 amount
	) private {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");
		if(from != owner() && to != owner())
			require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
		bool takeFee = true;
		if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
			takeFee = false;
		}
        if (antiBotEnabled) {
        pinkAntiBot.onPreTransferCheck(from, to, amount);
        }
		_tokenTransfer(from,to,amount,takeFee);
	}
	function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
		if(!takeFee)
			removeAllFee();
		if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            if (antiBotEnabled) {
            pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
            }
			_transferFromExcluded(sender, recipient, amount);
		} else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            if (antiBotEnabled) {
            pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
            }
			_transferToExcluded(sender, recipient, amount);
		} else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            if (antiBotEnabled) {
            pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
            }
			_transferStandard(sender, recipient, amount);
		} else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            if (antiBotEnabled) {
            pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
            }
            pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
			_transferBothExcluded(sender, recipient, amount);
		} else {
            if (antiBotEnabled) {
            pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
            }
			_transferStandard(sender, recipient, amount);
		}
		if(!takeFee)
			restoreAllFee();
	}

	function _transferBurn(uint256 tBurn) private {
		uint256 currentRate = _getRate();
		uint256 rBurn = tBurn.mul(currentRate);
		_rOwned[BURN_ADDRESS] = _rOwned[BURN_ADDRESS].add(rBurn);
		if(_isExcludedFromReward[BURN_ADDRESS])
			_tOwned[BURN_ADDRESS] = _tOwned[BURN_ADDRESS].add(tBurn);
	}

	function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
		(
			uint256 rAmount,
			uint256 rTransferAmount,
			uint256 rHODLrFee,
			uint256 tTransferAmount,
			uint256 tHODLrFee,
			uint256 tBurn
		) = _getValues(tAmount);
		_tOwned[sender] = _tOwned[sender].sub(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_transferBurn(tBurn);
		_HODLrFee(rHODLrFee, tHODLrFee);
		emit TransferBurn(sender, BURN_ADDRESS, tBurn);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rHODLrFee, uint256 tTransferAmount, uint256 tHODLrFee, uint256 tBurn) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_transferBurn(tBurn);
		_HODLrFee(rHODLrFee, tHODLrFee);
		emit TransferBurn(sender, BURN_ADDRESS, tBurn);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferStandard(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rHODLrFee, uint256 tTransferAmount, uint256 tHODLrFee, uint256 tBurn) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_transferBurn(tBurn);
		_HODLrFee(rHODLrFee, tHODLrFee);
		emit TransferBurn(sender, BURN_ADDRESS, tBurn);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rHODLrFee, uint256 tTransferAmount, uint256 tHODLrFee, uint256 tBurn) = _getValues(tAmount);
		_tOwned[sender] = _tOwned[sender].sub(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_transferBurn(tBurn);
		_HODLrFee(rHODLrFee, tHODLrFee);
		emit TransferBurn(sender, BURN_ADDRESS, tBurn);
		emit Transfer(sender, recipient, tTransferAmount);
	}

}