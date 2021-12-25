// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface AggregatorInterface {
	function latestAnswer() external view returns (int256);
}


contract YenPurchase is Ownable {

	using SafeMath for uint256;

  address supplier;

  address public yenToken;
	uint256 internal decimals;
	uint256 public minimumPurchaseAmount;
	uint256 public maximumPurchaseAmount;

	AggregatorInterface internal priceFeedEthUsd;
	AggregatorInterface internal priceFeedJpyUsd;

	modifier onlySupplier {
		require(
			// msg.sender == supplier,
      msg.sender == supplier,
			"msg.sender must be  supplier."
		);
		_;
	}

	mapping(address => AggregatorInterface) private priceFeedERC20Usd;

	constructor(address _yenToken, address jpy_usd_feed, address uth_usd_feed) {
		supplier = msg.sender;
		yenToken = _yenToken;
		decimals = IERC20(_yenToken).decimals();
		minimumPurchaseAmount = 1000e18;
		maximumPurchaseAmount = 200000e18;
		priceFeedJpyUsd = AggregatorInterface(jpy_usd_feed);
		priceFeedEthUsd = AggregatorInterface(uth_usd_feed);
	}


	/**
	 * Returns the minimum purchase amount per transaction.
	 */
	function updateMinimumPurchaseAmount(uint _newMinimumPurchaseAmount) external onlyOwner {
		minimumPurchaseAmount = _newMinimumPurchaseAmount;
	}

	/**
	 * Changes the maximum purchase amount.
	 */
	function updateMaximumPurchaseAmount(uint _newMaximumPurchaseAmount) external onlyOwner {
		maximumPurchaseAmount = _newMaximumPurchaseAmount;
	}

	/**
	 * Returns the price feed contract interface of `_tokenAddress` and USD.
	 */
	function getPriceFeedContract(address _tokenAddress) external view returns (AggregatorInterface contractAddress) {
		return priceFeedERC20Usd[_tokenAddress];
	}

	/**
	 * Add the `_chainlinkPriceFeed` interface of `_tokenAddress` and USD.
	 */
	function addPriceFeed(address _tokenAddress, address _chainlinkPriceFeed) external onlySupplier {
		priceFeedERC20Usd[_tokenAddress] = AggregatorInterface(_chainlinkPriceFeed);
	}

	/**
	 * update supplier to `_supplier`.
	 */
	function updateSupplier(address  _supplier) public payable onlyOwner {
		require(_supplier != address(0), "_supplier is the zero address");
		supplier = _supplier;
	}



	/**
	 * Returns the current ETH price in USD.
	 */
	function getLatestEthUsdPrice() public view returns (int256) {
		return priceFeedEthUsd.latestAnswer();
	}

	/**
	 * Returns the current JPY price in USD.
	 */
	function getLatestJpyUsdPrice() public view returns (int256) {
		return priceFeedJpyUsd.latestAnswer();
	}

	/**
	 * Returns the required `ethAmount` for the `_yenAmount` you input.
	 */
	function getETHAmountFromYen (uint256 _yenAmount) public view returns (uint256 ethAmount) {
		uint256 usdAmount = uint256(getLatestJpyUsdPrice()).mul(_yenAmount);
		return ethAmount = usdAmount.div(uint256(getLatestEthUsdPrice()));
	}

	/**
	 * Returns the `yenAmount` equals to `_ethAmount` you input.
	 */
	function getYenAmountFromETH (uint256 _ethAmount) public view returns (uint256 yenAmount) {
		uint256 usdAmount = uint256(getLatestEthUsdPrice()).mul(_ethAmount);
		return yenAmount = usdAmount.div(uint256(getLatestJpyUsdPrice()));
	}

	/**
	 * Receives exact amount of Yen (_yenAmount) for as much as ETH as possible, along the chainlink pricefeed.
	 */
	function purchaseExactYenWithETH(uint256 _yenAmount, uint256 _amountOutMax) payable external {
		require(minimumPurchaseAmount <= _yenAmount && _yenAmount <= maximumPurchaseAmount, "purchase amount must be within purchase range");
		require(_yenAmount <= IERC20(yenToken).allowance(supplier, address(this)), "insufficient allowance of Yen");

		uint256 ethAmount = getETHAmountFromYen(_yenAmount);
		require(ethAmount <= _amountOutMax, 'excessive slippage amount');
		require(msg.value >= ethAmount, "msg.value must greater than calculated ether amount");

		payable(supplier).transfer(ethAmount);
		IERC20(yenToken).transferFrom(supplier, msg.sender, _yenAmount);

		if (msg.value > ethAmount) payable(msg.sender).transfer(msg.value - ethAmount);
	}

	/**
	 * Receives as many Yen  as possible for an msg.value of ETH, along the chinlink price feed.
	 */
	function purchaseYenWithExactETH(uint256 _amountInMin) payable external {
    uint256 yenAmountFromEth = getYenAmountFromETH(msg.value);
		require(minimumPurchaseAmount <= yenAmountFromEth && yenAmountFromEth <= maximumPurchaseAmount, "purchase amount must be within purchase range");
		require(yenAmountFromEth <= IERC20(yenToken).allowance(supplier, address(this)), "insufficient allowance of YEN");
		require(yenAmountFromEth >= _amountInMin, 'excessive slippage amount');

		payable(supplier).transfer(msg.value);
		IERC20(yenToken).transferFrom(supplier, msg.sender, yenAmountFromEth);
  }


	/**
	 * Returns the current ETH20 of `_tokenAddress` price in USD.
	 */
	function getLatestERC20UsdPrice(address _tokenAddress) public view returns (int) {
		return priceFeedERC20Usd[_tokenAddress].latestAnswer();
	}

	/**
	 * Returns the required `erc20Amount` for the `_yenAmount` you input.
	 */
	function getERC20AmountFromYen (uint256 _yenAmount, address _tokenAddress) public view returns (uint256 erc20Amount) {
		uint256 usdAmount = uint256(getLatestJpyUsdPrice()).mul(_yenAmount).div(10 ** (decimals.sub(IERC20(_tokenAddress).decimals())));
		return erc20Amount = usdAmount.div(uint256(getLatestERC20UsdPrice(_tokenAddress)));
	}

	/**
	 * Returns the `yenAmount` equals to `_erc20Amount` you input.
	 */
	function getYenAmountFromERC20 (uint _erc20Amount, address _tokenAddress) public view returns (uint256 yenAmount) {
		uint256 usdAmount = uint256(getLatestERC20UsdPrice(_tokenAddress)).mul(_erc20Amount).mul(10 ** (decimals.sub(IERC20(_tokenAddress).decimals())));
		return yenAmount = usdAmount.div(uint256(getLatestJpyUsdPrice()));
	}

	/**
	 * Receives exact amount of YEN (_yenAmount) for as much as ERC20 as possible, along the chainlink pricefeed.
	 */
	function purchaseExactYenWithERC20(uint256 _yenAmount, uint256 _amountOutMax, address _tokenAddress) external {
		require(minimumPurchaseAmount <= _yenAmount && _yenAmount <= maximumPurchaseAmount, "purchase amount must be within purchase range");
		require(_yenAmount <= IERC20(yenToken).allowance(supplier, address(this)), "insufficient allowance of YEN");

		uint256 erc20Amount = getERC20AmountFromYen(_yenAmount, _tokenAddress);
		require(erc20Amount <= _amountOutMax, 'excessive slippage amount');
		require(IERC20(_tokenAddress).balanceOf(msg.sender) >= erc20Amount, "insufficient balance of ERC20 token");

		IERC20(_tokenAddress).transferFrom(msg.sender, supplier, erc20Amount);
		IERC20(yenToken).transferFrom(supplier, msg.sender, _yenAmount);
	}

	/**
	 * Receives as many YEN  as possible for an _erc20Amount, along the chinlink price feed.
	 */
	function purchaseYenWithExactERC20(uint256 _erc20Amount, uint256 _amountInMin, address _tokenAddress) external {
		uint256 yenAmountFromERC20 = getYenAmountFromERC20(_erc20Amount, _tokenAddress);
		require(minimumPurchaseAmount <= yenAmountFromERC20 && yenAmountFromERC20 <= maximumPurchaseAmount, "purchase amount must be within purchase range");
		require(yenAmountFromERC20 <= IERC20(yenToken).allowance(supplier, address(this)), "insufficient allowance of YEN");
		require(yenAmountFromERC20 >= _amountInMin, 'excessive slippage amount');

		require(IERC20(_tokenAddress).balanceOf(msg.sender) >= _erc20Amount, "insufficient balance of ERC20 token");

		IERC20(_tokenAddress).transferFrom(msg.sender, supplier, _erc20Amount);
		IERC20(yenToken).transferFrom(supplier, msg.sender, yenAmountFromERC20);
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
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