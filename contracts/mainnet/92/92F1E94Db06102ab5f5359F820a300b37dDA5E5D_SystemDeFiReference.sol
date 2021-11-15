// SPDX-License-Identifier: MIT
/*
░██████╗██╗░░░██╗░██████╗████████╗███████╗███╗░░░███╗  ██████╗░███████╗███████╗██╗  ███████╗░█████╗░██████╗░
██╔════╝╚██╗░██╔╝██╔════╝╚══██╔══╝██╔════╝████╗░████║  ██╔══██╗██╔════╝██╔════╝██║  ██╔════╝██╔══██╗██╔══██╗
╚█████╗░░╚████╔╝░╚█████╗░░░░██║░░░█████╗░░██╔████╔██║  ██║░░██║█████╗░░█████╗░░██║  █████╗░░██║░░██║██████╔╝
░╚═══██╗░░╚██╔╝░░░╚═══██╗░░░██║░░░██╔══╝░░██║╚██╔╝██║  ██║░░██║██╔══╝░░██╔══╝░░██║  ██╔══╝░░██║░░██║██╔══██╗
██████╔╝░░░██║░░░██████╔╝░░░██║░░░███████╗██║░╚═╝░██║  ██████╔╝███████╗██║░░░░░██║  ██║░░░░░╚█████╔╝██║░░██║
╚═════╝░░░░╚═╝░░░╚═════╝░░░░╚═╝░░░╚══════╝╚═╝░░░░░╚═╝  ╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝

██████╗░███████╗███████╗███████╗██████╗░███████╗███╗░░██╗░█████╗░███████╗
██╔══██╗██╔════╝██╔════╝██╔════╝██╔══██╗██╔════╝████╗░██║██╔══██╗██╔════╝
██████╔╝█████╗░░█████╗░░█████╗░░██████╔╝█████╗░░██╔██╗██║██║░░╚═╝█████╗░░
██╔══██╗██╔══╝░░██╔══╝░░██╔══╝░░██╔══██╗██╔══╝░░██║╚████║██║░░██╗██╔══╝░░
██║░░██║███████╗██║░░░░░███████╗██║░░██║███████╗██║░╚███║╚█████╔╝███████╗
╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚══╝░╚════╝░╚══════╝
Developed by systemdefi.crypto and rsd.cash teams
*/
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IReferenceSystemDeFi.sol";
import "./IWETH.sol";
import "./SdrHelper.sol";

contract SystemDeFiReference is Context, IERC20, Ownable {

	using SafeMath for uint256;

	bool private _inSwapAndLiquify;
	bool private _initialLiquidityCalled = false;
	bool public mustChargeFees = true;
	bool public swapAndLiquifyEnabled = true;

	uint256 private _decimals = 18;
	uint256 private _totalSupply;
	uint256 private _reflectedSupply;
	uint256 private _numTokensSellToAddToLiquidity;
	uint256 public lastPoolRate;

	address public rsdTokenAddress;
	address public sdrHelperAddress;
	address public farmContractAddress;
	address public marketingAddress;
	address public immutable rsdEthPair;
	address public immutable sdrRsdPair;

	mapping (address => uint256) private _balancesReflected;
	mapping (address => mapping (address => uint256)) private _allowances;

	string private _name;
	string private _symbol;

	struct Fees {
		uint256 farm;
		uint256 holder;
		uint256 liquidity;
		uint256 marketing;
	}

	Fees public fees = Fees(46, 17, 27, 10);
	IUniswapV2Router02 private _uniswapV2Router;
	IReferenceSystemDeFi private _rsdToken;
	IWETH private _weth;

	event FeesAdjusted(uint256 newHolderFee, uint256 newLiquidityFee, uint256 newFarmFee);
	event FeeForFarm(uint256 farmFeeAmount);
	event FeeForHolders(uint256 holdersFeeAmount);
	event FeeForLiquidity(uint256 liquidityFeeAmount);
	event FeeForMarketing(uint256 marketingFeeAmount);
	event MustChargeFeesUpdated(bool mustChargeFeesEnabled);
	event SwapAndLiquifyEnabledUpdated(bool enabled);
	event SwapAndLiquifySdrRsd(
		uint256 tokensSwapped,
		uint256 rsdReceived,
		uint256 tokensIntoLiqudity
	);
	event SwapAndLiquifyRsdEth(uint256 rsdTokensSwapped, uint256 ethReceived);

	modifier lockTheSwap {
		_inSwapAndLiquify = true;
		_;
		_inSwapAndLiquify = false;
	}

	constructor (
		string memory name_,
		string memory symbol_,
		address uniswapRouterAddress_,
		address rsdTokenAddres_,
		address farmContractAddress_,
		address marketingAddress_,
		address[] memory team
	) {
		_name = name_;
		_symbol = symbol_;
		farmContractAddress = farmContractAddress_;
		marketingAddress = marketingAddress_;

		uint256 portion = ((10**_decimals).mul(300000)).div((team.length).add(1));
		_mint(_msgSender(), portion);
		for (uint256 i = 0; i < team.length; i = i.add(1)) {
			_mint(team[i], portion);
		}
		_mint(address(this), (10**_decimals).mul(700000));

		_numTokensSellToAddToLiquidity = _totalSupply.div(10000);

		rsdTokenAddress = rsdTokenAddres_; // 0x61ed1c66239d29cc93c8597c6167159e8f69a823
		_rsdToken = IReferenceSystemDeFi(rsdTokenAddress);

		// PancakeSwap Router address: (BSC testnet) 0xD99D1c33F9fC3444f8101754aBC46c52416550D1  (BSC mainnet) V2 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F (Primary) | 0x10ED43C718714eb63d5aA57B78B54704E256024E (Secondary)
		// Ethereum Mainnet: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D | 0x1d5C6F1607A171Ad52EFB270121331b3039dD83e
		IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(uniswapRouterAddress_);
		_weth = IWETH(uniswapV2Router.WETH());

	  // Create two uniswap pairs for this new token with RSD and with ETH/BNB/MATIC/etc.
		address _sdrRsdPair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), rsdTokenAddress);
		if (_sdrRsdPair == address(0))
	  	_sdrRsdPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), rsdTokenAddress);
		sdrRsdPair = _sdrRsdPair;

		address _rsdEthPair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(rsdTokenAddress, address(_weth));
		if (_rsdEthPair == address(0))
	  	_rsdEthPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(rsdTokenAddress, address(_weth));
		rsdEthPair = _rsdEthPair;

		_uniswapV2Router = uniswapV2Router;

		delete _sdrRsdPair;
		delete _rsdEthPair;
		delete uniswapV2Router;
	}

	function name() external view virtual returns (string memory) {
    return _name;
  }

  function symbol() external view virtual returns (string memory) {
    return _symbol;
  }

  function decimals() external view virtual returns (uint256) {
    return _decimals;
  }

  function totalSupply() external view virtual override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balancesReflected[account].div(_getRate());
  }

  function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    _approve(sender, _msgSender(), currentAllowance.sub(amount));

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));

    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);
		_adjustFeesDynamically();

		uint256 senderBalance = balanceOf(sender);
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

    uint256 amountToTransfer;
		Fees memory amounts;

    if (sender != address(this)) {
      if (mustChargeFees) {
        (amountToTransfer, amounts) = _calculateAmountsFromFees(amount, fees);
      } else {
				Fees memory zeroFees;
        (amountToTransfer, amounts) = (amount, zeroFees);
			}
    } else {
      amountToTransfer = amount;
    }

		uint256 contractTokenBalance = balanceOf(address(this));
		bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
		if (overMinTokenBalance && !_inSwapAndLiquify && sender != sdrRsdPair && swapAndLiquifyEnabled) {
			uint256 sdrRsdPoolBalance = _rsdToken.balanceOf(sdrRsdPair);
			_swapAndLiquify(contractTokenBalance);
			sdrRsdPoolBalance = _rsdToken.balanceOf(sdrRsdPair);
			_rsdToken.generateRandomMoreThanOnce();
		}

    uint256 rAmount = reflectedAmount(amount);
    uint256 rAmountToTransfer = reflectedAmount(amountToTransfer);

    _balancesReflected[sender] = _balancesReflected[sender].sub(rAmount);
    _balancesReflected[recipient] = _balancesReflected[recipient].add(rAmountToTransfer);

    _balancesReflected[address(this)] = _balancesReflected[address(this)].add(reflectedAmount(amounts.liquidity));
		_balancesReflected[farmContractAddress] = _balancesReflected[farmContractAddress].add(reflectedAmount(amounts.farm));
		_balancesReflected[marketingAddress] = _balancesReflected[marketingAddress].add(reflectedAmount(amounts.marketing));

    _reflectedSupply = _reflectedSupply.sub(reflectedAmount(amounts.holder));

    emit Transfer(sender, recipient, amountToTransfer);
		if (amounts.farm > 0) {
			emit FeeForFarm(amounts.farm);
			emit Transfer(sender, farmContractAddress, amounts.farm);
		}
    if (amounts.holder > 0) {
      emit FeeForHolders(amounts.holder);
      emit Transfer(sender, address(this), amounts.holder);
    }
    if (amounts.liquidity > 0) {
    	emit FeeForLiquidity(amounts.liquidity);
      emit Transfer(sender, address(this), amounts.liquidity);
    }
		if (amounts.marketing > 0) {
			emit FeeForMarketing(amounts.marketing);
			emit Transfer(sender, marketingAddress, amounts.marketing);
		}

    delete rAmount;
    delete rAmountToTransfer;
		delete contractTokenBalance;
		delete amountToTransfer;
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    uint256 rAmount = reflectedAmount(amount);
    _balancesReflected[account] = _balancesReflected[account].add(rAmount);
    _totalSupply = _totalSupply.add(amount);
    _reflectedSupply = _reflectedSupply.add(rAmount);
    emit Transfer(address(0), account, amount);
    delete rAmount;
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

		uint256 accountBalance = balanceOf(account);
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    _balancesReflected[account] = _balancesReflected[account].sub(reflectedAmount(amount));
    _totalSupply = _totalSupply.sub(amount);
    _reflectedSupply = _reflectedSupply.sub(reflectedAmount(amount));

    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
		if (_reflectedSupply < _totalSupply)
			_reflectedSupply = _getNewReflectedValue();
	}

	function _addLiquidityRsd(uint256 sdrTokenAmount, uint256 rsdTokenAmount) private returns(bool) {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(_uniswapV2Router), sdrTokenAmount);
		_rsdToken.approve(address(_uniswapV2Router), rsdTokenAmount);

    // add the liquidity for SDR/RSD pair
    _uniswapV2Router.addLiquidity(
      address(this),
      rsdTokenAddress,
			sdrTokenAmount,
			rsdTokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      address(0),
      block.timestamp
    );

		return true;
  }

  function _addLiquidityRsdEth(uint256 rsdTokenAmount, uint256 ethAmount) private returns(bool) {
    // approve token transfer to cover all possible scenarios
    _rsdToken.approve(address(_uniswapV2Router), rsdTokenAmount);
		_weth.approve(address(_uniswapV2Router), ethAmount);

    // add the liquidity
		_uniswapV2Router.addLiquidity(
			rsdTokenAddress,
			address(_weth),
			rsdTokenAmount,
			ethAmount,
			0, // slippage is unavoidable
			0, // slippage is unavoidable
			address(0),
			block.timestamp
		);
		return true;
  }

	function _adjustFeesDynamically() private {
		uint256 currentPoolRate = _getPoolRate();
		uint256 rate;
		uint256 total = 100 - fees.marketing;
		if (currentPoolRate > lastPoolRate) {
			// DECREASE holderFee, INCREASE liquidityFee and farmFee
			lastPoolRate = lastPoolRate == 0 ? 1 : lastPoolRate;
			rate = currentPoolRate.mul(100).div(lastPoolRate);
			if (fees.holder > 2) {
				fees.holder = fees.holder.sub(2);
				fees.liquidity = total.sub(fees.holder).sub(fees.farm).sub(1);
				fees.farm = total.sub(fees.liquidity).sub(fees.holder);
				emit FeesAdjusted(fees.holder, fees.liquidity, fees.farm);
			}
		} else if (currentPoolRate < lastPoolRate) {
			// INCREASE holderFee, DECREASE liquidityFee and farmFee
			currentPoolRate = currentPoolRate == 0 ? 1 : currentPoolRate;
			rate = lastPoolRate.mul(100).div(currentPoolRate);
			if (fees.liquidity > 1) {
				fees.liquidity = fees.liquidity.sub(1);
				fees.farm = fees.farm.sub(1);
				fees.holder = total.sub(fees.liquidity).sub(fees.farm);
				emit FeesAdjusted(fees.holder, fees.liquidity, fees.farm);
			}
		}

		lastPoolRate = currentPoolRate;
		delete currentPoolRate;
		delete rate;
		delete total;
	}

  function _calculateAmountsFromFees(uint256 amount, Fees memory fees_) internal pure returns(uint256, Fees memory) {
    uint256 totalFees;
		Fees memory amounts_;
		amounts_.farm = amount.mul(fees_.farm).div(1000);
    amounts_.holder = amount.mul(fees_.holder).div(1000);
    amounts_.liquidity = amount.mul(fees_.liquidity).div(1000);
		amounts_.marketing = amount.mul(fees_.marketing).div(1000);
		totalFees = totalFees.add(amounts_.farm).add(amounts_.holder).add(amounts_.liquidity).add(amounts_.marketing);
    return (amount.sub(totalFees), amounts_);
  }

	function _getNewReflectedValue() private view returns(uint256) {
		uint256 total = (10**_decimals).mul(1000000);
		uint256 max = total.mul(10**50);
		uint256 reflected = (max - (max.mod(total)));
		delete max;
		delete total;
		return reflected;
	}

	function _getPoolRate() private view returns(uint256) {
		uint256 rsdBalance = _rsdToken.balanceOf(sdrRsdPair);
		uint256 sdrBalance = balanceOf(sdrRsdPair);
		sdrBalance = sdrBalance == 0 ? 1 : sdrBalance;
		return (rsdBalance.div(sdrBalance));
	}

  function _getRate() private view returns(uint256) {
    if (_reflectedSupply > 0 && _totalSupply > 0 && _reflectedSupply >= _totalSupply) {
      return _reflectedSupply.div(_totalSupply);
    } else {
			uint256 total = (10**_decimals).mul(1000000);
			uint256 reflected = _getNewReflectedValue();
			if (_totalSupply > 0)
				return reflected.div(_totalSupply);
			else
      	return reflected.div(total);
    }
  }

	function burn(uint256 amount) external {
		_burn(_msgSender(), amount);
	}

	function changeInitialLiquidityCalledFlag() external onlyOwner {
		_initialLiquidityCalled = !_initialLiquidityCalled;
	}

	function disableFeesCharging() external onlyOwner {
		mustChargeFees = false;
		emit MustChargeFeesUpdated(mustChargeFees);
	}

	function enableFeesCharging() external onlyOwner {
    mustChargeFees = true;
		emit MustChargeFeesUpdated(mustChargeFees);
  }

	function provideInitialLiquidity() external onlyOwner {
		require(!_initialLiquidityCalled, "SDR: Initial SDR/RSD liquidity already provided!");
		swapAndLiquifyEnabled = false;
		_addLiquidityRsd(balanceOf(address(this)), _rsdToken.balanceOf(address(this)));
		_initialLiquidityCalled = true;
		swapAndLiquifyEnabled = true;
	}

	function reflectedBalance(address account) external view returns(uint256) {
		return _balancesReflected[account];
	}

  function reflectedAmount(uint256 amount) public view returns(uint256) {
    return amount.mul(_getRate());
  }

	function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    uint256 rsdPart = contractTokenBalance.div(4).mul(3);
    uint256 sdrPart = contractTokenBalance.sub(rsdPart);
    uint256 rsdInitialBalance = _rsdToken.balanceOf(address(this));
		uint256 ethInitialBalance = address(this).balance;

		SdrHelper sdrHelper;
		if (sdrHelperAddress == address(0)) {
			sdrHelper = new SdrHelper(address(this));
			sdrHelperAddress = address(sdrHelper);
		}

		if (_swapTokensForRsd(rsdPart)) {
			sdrHelper = SdrHelper(sdrHelperAddress);
			sdrHelper.withdrawTokensSent(rsdTokenAddress);

	    uint256 rsdBalance = _rsdToken.balanceOf(address(this)).sub(rsdInitialBalance);
	    if (_addLiquidityRsd(sdrPart, rsdBalance.div(3)))
				emit SwapAndLiquifySdrRsd(rsdPart, rsdBalance.div(3), sdrPart);

			rsdBalance = _rsdToken.balanceOf(address(this)).sub(rsdInitialBalance);
			if (_swapRsdTokensForEth(rsdBalance.div(2))) {
				sdrHelper.withdrawTokensSent(address(_weth));

				uint256 newEthBalance = IERC20(address(_weth)).balanceOf(address(this)).sub(ethInitialBalance);
				if (_addLiquidityRsdEth(rsdBalance.div(2), newEthBalance))
					emit SwapAndLiquifyRsdEth(rsdBalance.div(2), newEthBalance);
			}
		}
  }

	function _swapTokensForRsd(uint256 tokenAmount) private returns(bool) {
    // generate the uniswap pair path of SDR -> RSD
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = rsdTokenAddress;

    _approve(address(this), address(_uniswapV2Router), tokenAmount);

    try _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of RSD
      path,
      sdrHelperAddress,
      block.timestamp
    ) { return true; } catch { return false; }
  }

	function _swapRsdTokensForEth(uint256 rsdTokenAmount) private returns(bool) {
    // generate the uniswap pair path of RSD -> WETH
    address[] memory path = new address[](2);
    path[0] = rsdTokenAddress;
    path[1] = address(_weth);

		_rsdToken.approve(address(_uniswapV2Router), rsdTokenAmount.add(1));

    // make the swap
		try _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
			rsdTokenAmount,
			0, // accept any amount of RSD
			path,
			sdrHelperAddress,
			block.timestamp
		) { return true; } catch { return false; }
  }

	function setFarmContractAddress(address farmContractAddress_) external onlyOwner {
		farmContractAddress = farmContractAddress_;
	}

	function setMarketingAddress(address marketingAddress_) external onlyOwner {
		marketingAddress = marketingAddress_;
	}

	function setSwapAndLiquifyEnabled(bool enabled_) external onlyOwner {
		swapAndLiquifyEnabled = enabled_;
		emit SwapAndLiquifyEnabledUpdated(enabled_);
	}

	function withdrawNativeCurrencySent(address payable account) external onlyOwner {
		require(address(this).balance > 0, "SDR: does not have any balance");
		account.transfer(address(this).balance);
	}

	function withdrawTokensSent(address tokenAddress) external onlyOwner {
		IERC20 token = IERC20(tokenAddress);
		if (token.balanceOf(address(this)) > 0)
			token.transfer(owner(), token.balanceOf(address(this)));
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReferenceSystemDeFi is IERC20 {
    function burn(uint256 amount) external;
    function generateRandomMoreThanOnce() external;
    function getCrowdsaleDuration() external view returns(uint128);
    function getExpansionRate() external view returns(uint16);
    function getSaleRate() external view returns(uint16);
    function log_2(uint x) external pure returns (uint y);
    function mintForStakeHolder(address stakeholder, uint256 amount) external;
    function obtainRandomNumber(uint256 modulus) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IWETH {
		function approve(address to, uint amount) external returns (bool);
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SdrHelper is Context {

	address immutable private sdrTokenAddress;

	modifier fromSdrToken {
		require(_msgSender() == sdrTokenAddress, "SDR Helper: only SDR token contract can call this function");
		_;
	}

	constructor(address sdrTokenAddress_) {
		sdrTokenAddress = sdrTokenAddress_;
	}

	function withdrawTokensSent(address tokenAddress) external fromSdrToken {
		IERC20 token = IERC20(tokenAddress);
		if (token.balanceOf(address(this)) > 0)
			token.transfer(_msgSender(), token.balanceOf(address(this)));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

