/**
 *Submitted for verification at FtmScan.com on 2022-01-20
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/IMinimalMasterchef.sol

pragma solidity ^0.8.9;

interface IMinimalMasterchef {
	function deposit(uint256 _pid, uint256 _amount) external;

	function withdraw(uint256 _pid, uint256 _amount) external;

	function emergencyWithdraw(uint256 _pid) external;

	function pendingRewards(uint256 _pid, address _user) external view returns (uint256);
}


// File contracts/IMinimalRouter.sol

pragma solidity ^0.8.9;

interface IMinimalRouter {
	function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

	function getAmountOut(uint amountIn, address[] memory path) external pure returns (uint[] memory amounts);
}


// File contracts/MIMCompounder.sol

pragma solidity ^0.8.9;




contract MIMCompounder is Ownable {
	uint256 public constant SLIPPAGE_DENOMINATOR = 10000; // 100%

    address public mim;
	address public weve;
	address public exchange;
	address public masterchef;
	uint256 public pid;
	uint256 public swapSlippage;
	uint256 public deposited;

    constructor(address _mim, address _weve, address _exchange, address _masterchef) {
		mim = _mim;
		weve = _weve;
		exchange = _exchange;
		masterchef = _masterchef;
		pid = 4;
		swapSlippage = 10; // 0.1%

		uint256 max = 2**256 - 1;

		// Approve tokens to sender
		IERC20(mim).approve(msg.sender, max);
		IERC20(weve).approve(msg.sender, max);

		// Approve MIM to masterchef
		IERC20(mim).approve(masterchef, max);

		// Approve WeVe to exchange
		IERC20(weve).approve(exchange, max);
    }

	function tokenBalance(address _token) public view returns (uint256) {
		return IERC20(_token).balanceOf(address(this));
	}

	function pendingRewards() public view  returns (uint256) {
		return IMinimalMasterchef(masterchef).pendingRewards(pid, address(this));
	}

	function deposit(uint256 _amount) public onlyOwner {
		_depositToMasterchef(_amount);
	}

	function depositAll() public onlyOwner {
		_depositToMasterchef(IERC20(mim).balanceOf(address(this)));
	}

	function withdraw(uint256 _amount) public onlyOwner {
		_withdrawFromMasterchef(_amount);
	}

	function withdrawAll() public onlyOwner {
		_withdrawFromMasterchef(deposited);
	}

	function claimRewards() public onlyOwner {
		_withdrawFromMasterchef(0);
	}

	function compound() public onlyOwner {
		_withdrawFromMasterchef(0);

		uint256 amountToSell = IERC20(weve).balanceOf(address(this));

		require(amountToSell > 0, "No rewards to sell");

		address[] memory path = new address[](2);
		path[0] = weve;
		path[1] = mim;

		uint256[] memory amountOut = IMinimalRouter(exchange).getAmountOut(amountToSell, path);

		uint256 minAmount = amountOut[1] - ((amountOut[1] * swapSlippage) / SLIPPAGE_DENOMINATOR);

		uint256[] memory result = IMinimalRouter(exchange).swapExactTokensForTokens(amountToSell, minAmount, path, address(this), block.timestamp + 600);

		_depositToMasterchef(result[1]);
	}

	function setPID(uint256 _pid) public onlyOwner {
		pid = _pid;
	}

	function setMasterchef(address _masterchef) public onlyOwner {
		masterchef = _masterchef;
	}

	function setExchange(address _exchange) public onlyOwner {
		exchange = _exchange;
	}

	function setMim(address _mim) public onlyOwner {
		exchange = _mim;
	}

	function setWeve(address _weve) public onlyOwner {
		exchange = _weve;
	}

	function setAllowance(address _token, address _spender, uint256 _amount) public onlyOwner {
		IERC20(_token).approve(_spender, _amount);
	}

	function setSwapSlippage(uint256 _swapSlippage) public onlyOwner {
		swapSlippage = _swapSlippage;
	}

	function _depositToMasterchef(uint256 _amount) internal {
		require(IERC20(mim).balanceOf(address(this)) >= _amount, "Insufficient MIM on contract");

		IMinimalMasterchef(masterchef).deposit(pid, _amount);

		deposited += _amount;
	}

	function _withdrawFromMasterchef(uint256 _amount) internal {
		require(deposited >= _amount, "Not enough MIM deposited");

		IMinimalMasterchef(masterchef).withdraw(pid, _amount);

		deposited -= _amount;
	}
}