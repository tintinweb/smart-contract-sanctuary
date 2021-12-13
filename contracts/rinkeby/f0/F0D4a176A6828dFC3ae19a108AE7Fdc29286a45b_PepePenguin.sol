// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LPBasic.sol";

contract PepePenguin is LPBasic {

		constructor(string memory name, string memory symbol, uint256 supply) LPBasic(name, symbol, supply) { }

}

/* Welcome To PepePenguin!
 *
 * -------------------------------------------------------------------------------------------------------------------
 *
 * PepePenguin ($PP)
 * PepePenguin.io
 * twitter.com/PPepe_Penguin
 * t.me/PepePenguinTG
 *
 * -------------------------------------------------------------------------------------------------------------------
 *
 * PepePenguin ($PP) is a fully decentralized fair launch meme token that has been optimized for price appreciation.
 * PP collects a liquidity pool (LP) fee on each transaction that scales based on the LP size. Instead of immediately
 * depositing the LP fee back into the LP, PP optimizes the rate of deposit to increase or decrease the token's
 * volatility (speed at which the price moves) depending on the token's current value. In simple terms, PP increases
 * the speed of price appreciation in price zones of optimal price appreciation and decreases the speed of price
 * deprecation in prices zone prone to consolidation. This is achieved by the contract holding the LP fee as a token
 * reserve and slowly depositing the LP pair fee into the LP in appreciating price zones and rapidly depositing during
 * price deprecation zones. In this way PP LP dynamics help drive the market price to a steady increase followed with
 * consolidation, boosting the next increase and damping any price reductions. Further, PP has re-engineered the fair
 * launch model to allow for an optimal token wallet distribution. PP limits the maximum purchase to 1,000,000 tokens
 * per wallet and the contract will collect any amount over the maximum adding to the token LP reserves. In addition,
 * the LP of the contract has been locked forever.
 *
 * -------------------------------------------------------------------------------------------------------------------
 *
 * Tokenomics breakdown
 *
 * Max Token Supply: 100,000,000
 *
 * IF LP < 5 ETH:
 * 	LP TAX : 15%
 * 	Max LP push is 250k token
 * 	Max Wallet is 1M tokens - amount over max wallet is taxed 100% and sent to LP
 * 	Standard transfers are not limited
 * 	50% of pool size is max purchase size
 * 	1.5% Dev Fee on every Transaction
 *
 * IF 5ETH < LP < 20ETH:
 * 	LP TAX : 5%
 * 	IF contract holds more tokens than LP, push greater of: 500,000 tokens or 5% pool balance
 * 	ELSE push lesser of: 250,000 tokens or 1% pool balance
 * 	Max Wallet is 1M tokens - amount over max wallet is taxed 100% and sent to LP
 * 	Standard transfers are not limited
 * 	50% of pool size is max purchase size
 * 	1.5% Dev Fee on every Transaction
 *
 * IF 20ETH < LP < 100ETH
 * 	LP TAX : 2.5%
 * 	Max LP push size of 1% pool balance
 * 	Max Wallet is permanently disabled
 *  Max purchase size is permanently disabled
 * 	Standard transfers are not limited
 * 	1.5% Dev Fee on every Transaction
 *
 * IF 100ETH < LP
 *	NO LP TAX
 * 	LP tax still held by contract push to LP size of 1% pool balance
 * 	Standard transfers are not limited
 * 	1.5% Dev Fee on every Transaction
 *
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import './ERC20.sol';

contract LPBasic is Ownable, ERC20 {
		using Address for address;

		address payable internal _devWallet;
		function setDevWallet(address payable devwallet) public onlyOwner { _devWallet = devwallet; }

		/* --- rate configuration --- */

		uint256 internal constant _rateDivisor =  1000000;  // rate at this value = 100%

		uint256 internal _lpRateA  =      150000;
		uint256 internal _lpRateB  =       50000;
		uint256 internal _lpRateC  =       25000;

		uint256 internal _lpTierA  = 5 * (10 ** 18);
		uint256 internal _lpTierB  = 20 * (10 ** 18);
		uint256 internal _lpTierC  = 100 * (10 ** 18);

		uint256 internal _lpPendingBalance;
		function pendingBalanceLP() public view returns(uint256) { return _lpPendingBalance; }
		
		uint256 internal _lpPendingThrottle = 250000 * (10 ** 18); // while LP ETH < 20ETH - MAX PUSH TO LP
		
		
		uint256 internal _txMaximum = 500000; // maximum tx size in % of current pool

		uint256 internal _walletMax = 1000000 * (10 ** 18); // while LP ETH < 20ETH - WALLET LIMIT
		uint256 internal _walletMaxTier = 20 * (10 ** 18);

		uint256 internal _devRate  =       15000;

		uint256 internal _devPendingBalance;
		function pendingBalanceDev() public view returns(uint256) { return _devPendingBalance; }

		bool _feePendingAlternate;
		uint256 internal _feePendingThreshold = 1 * (10 ** 16); // 0.01 ETH
		
		

		/* --- current state - once top tier is exited permanently inactive --- */

		bool internal _lpRateActive = true;
		bool internal _lpLimitActive = true;

		bool internal _tradingEnabled = false;
		function setTradingEnabled() public onlyOwner { _tradingEnabled = true; }
		


		/* --- uniswap v2 - router and pair configurable - no fees will be charged until pair is set --- */

		address _uniswapFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
		address _uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
		function setRouterAddress(address routeraddress) public onlyOwner { _uniswapRouterAddress = routeraddress; }
		address internal _uniswapPairAddress;
		function setPairAddress(address pairaddress) public onlyOwner { _uniswapPairAddress = pairaddress; }
		function getPairAddress() public view returns(address) { return _uniswapPairAddress; }

		address internal _tokenAddressWETH;
		
		
		bool _locked;
    modifier locked() {
        require(!_locked,"LPBasic: Blocked reentrant call.");
        _locked = true;
        _;
        _locked = false;
    }


		constructor(string memory name, string memory symbol, uint256 supply) ERC20(name, symbol) {
				_mint(address(this),supply);
				_tokenAddressWETH = IUniswapV2Router02(_uniswapRouterAddress).WETH();
		}


		/* --- transfer functions --- */

		function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
				_transfer(_msgSender(), recipient, amount);
				return true;
		}

		function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
				_transfer(sender, recipient, amount);
				uint256 currentAllowance = _allowances[sender][_msgSender()];
				require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
				unchecked {
						_approve(sender, _msgSender(), currentAllowance - amount);
				}
				return true;
		}

		function _transfer( address sender, address recipient, uint256 amount ) internal virtual override {

				require(sender != address(0), "ERC20: transfer from the zero address");
				require(recipient != address(0), "ERC20: transfer to the zero address");
				require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

				(bool isTaxed, bool isSell, uint256 lpToken, uint256 lpEth) = _isTaxed(sender,recipient);
				if(isTaxed) require(amount < _transferMaximum(lpToken,lpEth),"LPBasic: amount exceeds maximum allowed");

				if(isTaxed) {
						require(_tradingEnabled, "LPBasic: trading has not been enabled");
						_transferTaxed(sender,recipient,amount,lpToken,lpEth,isSell);
				}
				else _transferUntaxed(sender,recipient,amount);

		}
		
		function _transferMaximum(uint256 lpToken, uint256 lpEth) internal view returns(uint256 transferMax) {
				if(!_lpLimitActive) return _totalSupply;
				else transferMax = _txMaximum * lpToken / _rateDivisor;
		}

		function _isTaxed(address sender, address recipient) internal returns(bool isTaxed,bool isSell,uint256 tokenReserves,uint256 ethReserves) {

				if(sender==address(this) || recipient==address(this)) return (false,false,0,0);

				if((sender == _uniswapPairAddress && recipient == _uniswapRouterAddress)
						|| (recipient == _uniswapPairAddress && sender == _uniswapRouterAddress))
						return (false,false,0,0);

				if(_uniswapPairAddress==address(0)) return (false,false,0,0);

				bool isBuy = sender==_uniswapRouterAddress || sender==_uniswapPairAddress;
				isSell = recipient==_uniswapRouterAddress || recipient==_uniswapPairAddress;

				isTaxed = isBuy || isSell;

				if(isTaxed) {
						(tokenReserves,ethReserves) = _getReserves();

						if(_lpLimitActive && ethReserves > _walletMaxTier) _lpLimitActive = false;

						// one way switch disabled - lp fee can turn back on when eth balance returns to tier c
						//if(_lpRateActive && ethReserves > _lpTierC) _lpRateActive = false;
				}
		}
		
		function _getReserves() internal returns(uint256 tokenReserves,uint256 ethReserves) {
				(uint256 reserve0,uint256 reserve1,) = IUniswapV2Pair(_uniswapPairAddress).getReserves();
				if(IUniswapV2Pair(_uniswapPairAddress).token0()==address(this)) {
						tokenReserves = reserve0;
						ethReserves = reserve1;
				} else {
						ethReserves = reserve0;
						tokenReserves = reserve1;
				}
		}

		function _transferUntaxed( address sender, address recipient, uint256 amount ) internal {
				_beforeTokenTransfer(sender, recipient, amount);
				_balances[sender] -= amount;
				_balances[recipient] += amount;
				emit Transfer(sender, recipient, amount);
				_afterTokenTransfer(sender, recipient, amount);
		}

		function _lpTaxRate(uint256 ethBalance) internal view returns(uint256 _taxRate) {
				if(_lpRateActive) {
						if(ethBalance < _lpTierA) { _taxRate = _lpRateA; }
						else if(ethBalance < _lpTierB) { _taxRate = _lpRateB; }
						else if(ethBalance < _lpTierC) { _taxRate = _lpRateC; }
						else { _taxRate = 0; }
				}
		}

		function _transferTaxed( address sender, address recipient, uint256 amount, uint256 lpTokenBalance, uint256 lpEthBalance, bool isSell ) internal {
				
				if(isSell) {
						bool pendingDevReady = (_devPendingBalance * lpEthBalance / lpTokenBalance) > _feePendingThreshold;
						bool pendingLpReady = (_lpPendingBalance * lpEthBalance / lpTokenBalance) > _feePendingThreshold;
						bool pendingReady = pendingDevReady || pendingLpReady;
						if(!_locked && isSell && pendingReady) {
								if(!pendingLpReady || (_feePendingAlternate && pendingDevReady)) {
										_convertTaxDev();
										_feePendingAlternate = false;
								}
								else {
										_processTaxLP(lpTokenBalance,lpEthBalance);
										_feePendingAlternate = true;
								}
						}
				}

				uint256 taxRate = _lpTaxRate(lpEthBalance);
				
				uint256 taxAmount = (taxRate>0 ? amount * taxRate / _rateDivisor : 0);
				uint256 devAmount = amount * _devRate / _rateDivisor;

				_balances[sender] -= amount;

				uint256 recAmount = amount - (taxAmount + devAmount);

				if(!isSell && _lpLimitActive && (_balances[recipient] + recAmount) > _walletMax) {
						uint256 overMax = (_balances[recipient] > _walletMax ? recAmount : _balances[recipient] + recAmount - _walletMax);
						recAmount -= overMax;
						taxAmount += overMax;
				}

				if(recAmount>0) {
						_balances[recipient] += recAmount;
						emit Transfer(sender, recipient, recAmount);
				}
				if(taxAmount>0) {
						_balances[address(this)] += taxAmount;
						_lpPendingBalance += taxAmount;
						emit Transfer(sender, address(this), taxAmount);
				}
				if(devAmount>0) {
						_balances[address(this)] += devAmount;
						_devPendingBalance += devAmount;
						emit Transfer(sender, address(this), devAmount);
				}
		}

		function _convertTaxDev() internal locked {
				(uint256 tokenDelta,) = _swapTokensForEth(_devPendingBalance, _devWallet);
				_devPendingBalance -= tokenDelta;
		}

		function _processTaxLP(uint256 poolTokenBalance, uint256 poolEthBalance) internal locked {
				
				uint256 ethBalance = address(this).balance;
				uint256 ethBalanceValue = (ethBalance * poolTokenBalance) / poolEthBalance;
				uint256 ethDelta;
				uint256 tokenDelta;
				
				uint256 lpPendingThreshold = pendingThreshold(poolTokenBalance,poolEthBalance);
				
				uint256 pendingAmount = ( (_lpPendingBalance>lpPendingThreshold) ? lpPendingThreshold : _lpPendingBalance );
				if(ethBalanceValue<pendingAmount) {
						uint256 ethConvert = ((pendingAmount + ethBalanceValue) / 2) - ethBalanceValue;
						(tokenDelta,ethDelta) = _swapTokensForEth(ethConvert,address(this));
				}
				(uint256 tokenDeposit,) = _addLiquidity(pendingAmount-tokenDelta,ethDelta+ethBalance);
				_lpPendingBalance -= (tokenDelta + tokenDeposit);
		}
		
		function pendingThreshold(uint256 poolTokenBalance,uint256 poolEthBalance) internal returns(uint256 threshold) {
				if( poolTokenBalance < _balances[address(this)] && poolEthBalance < (20 * (10 ** 18)) && poolEthBalance > (5 * (10 ** 18)) )
						threshold = ( ( (_lpPendingThrottle * 2) > ( (poolTokenBalance * 5) / 100 )) ? _lpPendingThrottle * 2 : ( (poolTokenBalance * 5) / 100 ) );
				else if(poolEthBalance < (5 * (10 ** 18)) ) threshold = _lpPendingThrottle;
				else if(poolEthBalance > (20 * (10 ** 18)) ) threshold = poolTokenBalance / 100;
				else threshold = ( ( _lpPendingThrottle < ( poolTokenBalance / 100 )) ? _lpPendingThrottle : ( poolTokenBalance / 100 ) );
		}



		function _swapTokensForEth(uint256 tokenAmount, address destination) internal returns(uint256 tokenDelta, uint256 ethDelta) {

				(uint256 tokenReserve, uint256 ethReserve) = _getReserves();

				_approve(address(this), _uniswapRouterAddress, tokenAmount);

				address[] memory path = new address[](2);
				path[0] = address(this);
				path[1] = _tokenAddressWETH;


				IUniswapV2Router02(_uniswapRouterAddress).swapExactTokensForETHSupportingFeeOnTransferTokens(
						tokenAmount,
						0,
						path,
						destination,
						block.timestamp + 100
				);
				(uint256 tokenReserveAfter, uint256 ethReserveAfter) = _getReserves();

				tokenDelta = uint256(tokenReserveAfter-tokenReserve);
				ethDelta = uint256(ethReserve-ethReserveAfter);
		}

		function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal returns(uint256 tokenDeposit,uint256 ethDeposit) {
				_approve(address(this), _uniswapRouterAddress, tokenAmount);
				(tokenDeposit, ethDeposit,) = IUniswapV2Router02(_uniswapRouterAddress).addLiquidityETH{value:ethAmount}(
						address(this),
						tokenAmount,
						0,
						0,
						address(this),
						block.timestamp + 100
				);
		}

		function initializeLiquidityPool() public payable onlyOwner {
				require(_uniswapPairAddress==address(0),"Pair address already set");
				IUniswapV2Factory _factory = IUniswapV2Factory(_uniswapFactoryAddress);
				_factory.createPair(address(this),_tokenAddressWETH);
				_uniswapPairAddress = _factory.getPair(address(this),_tokenAddressWETH);
				_addLiquidity(_balances[address(this)], msg.value);
		}




		receive() external payable {}





}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/*
 * @dev Implementation of the {IERC20} interface.
 * based on @openzeppelin/contracts/token/ERC20/ERC20.sol
 */

contract ERC20 is Context, IERC20, IERC20Metadata {

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

pragma solidity >=0.6.2;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}