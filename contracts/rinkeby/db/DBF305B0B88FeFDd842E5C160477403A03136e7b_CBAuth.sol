/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: contracts/CBAuth.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;




/// @title Crypto Briefing User Authentication
/// @author Anton Tarasov
/// @notice Enables users to get access to SIMETRI via ETH or a stablecoin
/// @dev Lifetime subsription via an NFT minter will be implemented
contract CBAuth is Ownable {

	/// @notice Emitted when a person is subscribed for the service
	/// @param subscriber Subscriber ETH address
	event Subscribed(address subscriber);

	/// @notice Emitted when a person gets a refund
	/// @param subscriber Subscriber ETH address
	event Refunded(address subscriber);

	/// @notice Subscription price is in USD
	/// @dev Assigned in constructor
	uint256 public subscriptionPrice;

	/// @dev Lengths of subscription and grace period in seconds for tracking expiration & refund eligibility
	uint256 internal year = 31536000;
	uint256 internal gracePeriod = 2592000;

	/// @dev IERC20 interface for interacting with DAI
	IERC20 internal dai;

	/// @dev Chainlink interface for getting the price of ETH in USD
	AggregatorV3Interface internal ETHUSDPriceFeed;

	/// @dev Helps determining in which currency the subscriber paid, important for refunds
	enum Currency { ETH, DAI }
	Currency constant defaultChoice = Currency.ETH;

	/// @dev Data used for checking whether a subscription is active and is refund possible
	struct Subscription {
		uint256 expiration;
		Currency currency;
		uint256 balance;
	}

	/// @notice Information about each ETH address subscription, all zeroes means "not subscribed"
	mapping(address=>Subscription) public subscriptions;

	/// @param daiAddress Address of the DAI contract
	/// @param ethUsdOracle Address of Chainlink data feed
	/// @param initSubscriptionPrice Sets initial price of a subscription in USD w/o decimals
	/// @dev Had to use USDT contract on Rinkeby instead of DAI
	constructor(address daiAddress, address ethUsdOracle, uint256 initSubscriptionPrice) {
			dai = IERC20(daiAddress);
			ETHUSDPriceFeed = AggregatorV3Interface(ethUsdOracle);
			subscriptionPrice = initSubscriptionPrice; 
	}

	modifier notSubscribed {
		require(subscriptions[msg.sender].expiration == 0 || subscriptions[msg.sender].expiration < block.timestamp, "Already subscribed.");
		_;
	}

	modifier subscribed {
		require(subscriptions[msg.sender].expiration != 0 || subscriptions[msg.sender].expiration > block.timestamp, "Not subscribed.");
		_;
	}

	modifier refundActive {
		require(subscriptions[msg.sender].expiration - year + gracePeriod > block.timestamp, "Grace Period Ended.");
		_;
	}
    
	///@dev Queries ETH/USD price from Chainlink data feed, the feed returns multiple items but we only need "answer"
	function getETHUSDPrice() 
		internal 
		view 
		returns (int256) {
			(
					, int256 answer, , ,
			) = ETHUSDPriceFeed.latestRoundData();
			return answer / 1e8;
		}

	/// @dev Uses Chainlink data to calculate price of a subscription, DAI has 18 decimals, so multiplying the price by 1e18
	function calculateETHPrice()
		public 
		view
		returns (uint256) {
			int256 ethPrice = getETHUSDPrice();
			return subscriptionPrice * 1e18 / uint256(ethPrice);
		}

	/// @notice Checks whether a sender has enough ETH and if yes accepts payment and makes a new subscription
	/// @dev Accepts only the exact amount to avoid the need to send funds back
	function subscribeETH() 
		external 
		payable 
		notSubscribed {
			require(msg.value == calculateETHPrice(), "Please, pay the exact amount in ETH.");

			subscriptions[msg.sender].expiration = block.timestamp + year;
			subscriptions[msg.sender].currency = Currency.ETH;
			subscriptions[msg.sender].balance = msg.value;

			emit Subscribed(msg.sender);
    }

	/// @notice Checks whether a sender has enough DAI and if yes accepts payment and makes a new subscription
	/// @dev Prevent an unnecessary call to DAI contract in the case of not enough funds with "require"
	function subscribeDAI() 
		external 
		notSubscribed {
			require(dai.balanceOf(msg.sender) >= subscriptionPrice * 1e18, "You don't have enough DAI.");

			dai.transferFrom(msg.sender, address(this), subscriptionPrice * 1e18);
			subscriptions[msg.sender].expiration = block.timestamp + year;
			subscriptions[msg.sender].currency = Currency.DAI;
			subscriptions[msg.sender].balance = subscriptionPrice * 1e18;

			emit Subscribed(msg.sender);
    }

	/// @notice Mint an NFT that represents a lifetime subscription
	/// @dev The NFT minter will be a separate contract
	function subscribeLifetime() external {
		// TODO: create an external NFT minter an a function that calls it and updates state.
	}

	/// @notice Checks whether an address is subscribed
	/// @param subscriber ETH address being checked
	function isSubscribed(address subscriber) 
		public 
		view 
		returns(bool) {
			if (subscriptions[subscriber].expiration == 0 || subscriptions[subscriber].expiration < block.timestamp)
				return false;
			else
				return true;
	}

	/// @notice Checks whether an address is subscribed and the grace period of 30 days isn't over, then refunds
	/// @dev Uses checks-effects-interactions pattern to prevent re-entrancy
	function requestRefund() 
		external 
		subscribed 
		refundActive {
			uint256 refundAmount = subscriptions[msg.sender].balance;

			subscriptions[msg.sender].balance = 0;
			subscriptions[msg.sender].expiration = 0;

			if (subscriptions[msg.sender].currency == Currency.ETH) {
					(bool sent, ) = msg.sender.call{value: refundAmount}("");
					require(sent, "Failed to Refund");
			} else if (subscriptions[msg.sender].currency == Currency.DAI) {
					dai.transfer(msg.sender, refundAmount);
			}
		}

	/// @notice Lets the owner to update the yearly price in USD
	/// @param _subscriptionPrice New subscription price
	function updatePrice(uint256 _subscriptionPrice)
		external
		onlyOwner {
			subscriptionPrice = _subscriptionPrice;
		}
		
	/// @notice Lets the owner to withdraw funds
	/// @dev Prevents unnecessary call to DAI if the contract doesn't hold DAI
	function withdraw() 
			external 
			onlyOwner {
				(bool sent, ) = owner().call{value: address(this).balance}("");
				require(sent, "Failed to withdraw");
				if (dai.balanceOf(address(this)) > 0)
					dai.transfer(msg.sender, dai.balanceOf(address(this)));
		}
}