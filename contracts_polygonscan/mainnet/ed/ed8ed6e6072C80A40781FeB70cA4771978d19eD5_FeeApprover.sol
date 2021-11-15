// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // for WETH
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract FeeApprover is Ownable {

	// In this contract, e do calculate fee and the real amount to be sent to the recepient

	address tokenUniswapPair;
	IUniswapV2Factory public uniswapFactory;
	address internal WETHAddress;
	address eonsTokenAddress;
	address eonsVaultAddress;
	uint8 public feePercentX100; // max 255 = 25.5% artificial clamp
	uint256 public lastTotalSupplyOfLPTokens;
	bool paused;

	constructor (address _EonsAddress, address _WETHAddress, address _uniswapFactory) public {
		eonsTokenAddress = _EonsAddress;
		WETHAddress = _WETHAddress;
		tokenUniswapPair = IUniswapV2Factory(_uniswapFactory).getPair(
			WETHAddress,
			eonsTokenAddress
		);
		feePercentX100 = 10;
		paused = true; // We start paused until sync post LGE happens.
	}

    // HAL9K token is pausable
	function setPaused(bool _pause) public onlyOwner {
		paused = _pause;
	}

	function setFeeMultiplier(uint8 _feeMultiplier) public onlyOwner {
		feePercentX100 = _feeMultiplier;
	}

	function setEonsVaultAddress(address _eonsVaultAddress) public onlyOwner {
		eonsVaultAddress = _eonsVaultAddress;
	}

	function sync() public {
		uint256 _LPSupplyOfPairTotal = IERC20(tokenUniswapPair).totalSupply();
		lastTotalSupplyOfLPTokens = _LPSupplyOfPairTotal;
	}

	function calculateAmountsAfterFee(
		address sender,
		address recipient, // unusued maybe use din future
		uint256 amount
	)
		public
		returns (
				uint256 transferToAmount,
				uint256 transferToFeeDistributorAmount
		)
	{
		require(paused == false, "FEE APPROVER: Transfers Paused");
		uint256 _LPSupplyOfPairTotal = IERC20(tokenUniswapPair).totalSupply();

		if (sender == tokenUniswapPair)
			require(
				lastTotalSupplyOfLPTokens <= _LPSupplyOfPairTotal,
				"Liquidity withdrawals forbidden"
			);

		if (sender == eonsVaultAddress || sender == tokenUniswapPair) {
				// Dont have a fee when eonsvault is sending, or infinite loop
				// And when pair is sending ( buys are happening, no tax on it)
			transferToFeeDistributorAmount = 0;
			transferToAmount = amount;
		} else {
			transferToFeeDistributorAmount = amount*feePercentX100/1000;
			transferToAmount = amount-transferToFeeDistributorAmount;
		}

		lastTotalSupplyOfLPTokens = _LPSupplyOfPairTotal;
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

