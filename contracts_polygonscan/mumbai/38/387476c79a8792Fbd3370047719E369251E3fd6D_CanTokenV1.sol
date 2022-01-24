// SPDX-License-Identifier: ISC

/// @title CANE Token V1 / Polygon v1
/// @author Alfredo Lopez / CANEDROME 2022.1 */

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../lib/main/StabilityFee.sol";


contract CanTokenV1 is Initializable, StabilityFee {
	using AddressUpgradeable for address;
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;
	// Constant Max Total Supply of CANODROME
 	uint256 private constant _maxTotalSupply = 100_000_000 * (uint256(10) ** uint256(18));

	function initialize() initializer() public {
		__Ownable_init();
		__ERC20_init_unchained('CANODROME', 'CAN');
		__Pausable_init_unchained();
		__ERC20Permit_init('CANODROME');

		// Mint Total Supply
		mint(getMaxTotalSupply());
		// Begininng Deploy of Allocation in the ERC20
		// Allocation #1 / VestingType # 0, Seed (2)% and Start with 0 Months Locked the Token
		vestingTypes.push(VestingType(8333333333333333, 100000000000000000, 30 days, 0, true)); // 0 Days Locked, 8.333333333 Percent Initial Unlocked, 8.333333333 Percent Monthly for 11 Months
		// Allocation #1 / VestingType # 1, Private Sale 1 (2)% and Start with 0 Months Locked the Token
		vestingTypes.push(VestingType(8333333333333333, 100000000000000000, 30 days, 0, true)); // 0 Days Locked, 8.333333333 Percent Initial Unlocked, 8.333333333 Percent Monthly for 11 Months
		// Allocation #2 / VestingType # 2, Private Sale 2 (2)% and Start with 0 Months Locked the Token
		vestingTypes.push(VestingType(8333333333333333, 100000000000000000, 30 days, 0, true)); // 0 Days Locked, 8.333333333 Percent Initial Unlocked, 8.333333333 Percent Monthly for 11 Months
		// Allocation #3 / VestingType # 3, PreSale 1 (2)% and Start with 0 Months Locked the Token
		vestingTypes.push(VestingType(400000000000000000, 200000000000000000, 30 days, 0, true)); // 0 Days Locked, 33.333333333 Initial Unlocked, 33.333333333 Percent Monthly for 2 Months
		// Allocation #4 / VestingType # 4, PreSale 2 (3)% and Start with 0 Months Locked the Token
		vestingTypes.push(VestingType(40000000000000000, 20000000000000000, 30 days, 0, true)); // 0 Days Locked, 50 Percent Initial Unlocked, 50 Percent Monthly for 1 Months
		// Allocation #5 / VestingType # 5, Liquidity / Public Sale Total (4)% , Unlocked the all Token immediatly deploy the Token
		vestingTypes.push(VestingType(1000000000000000000, 1000000000000000000, 0, 0, true)); // 0 Days 100 Percent Unloked
		// Allocation #6 / VestingType # 6, Advisors (2)%, 1 Month Locked, and 2 Percent Monthly for 50 Months
		vestingTypes.push(VestingType(20000000000000000, 0, 30 days, 0, true));
		// Allocation #7 / VestingType # 7, Team (8)%, 11 Month Locked, and 8.333333333 Percent Monthly for 12 Months
		vestingTypes.push(VestingType(8333333333333333, 0, 330 days, 0, true));
		// Allocation #8 / VestingType # 8, Marketing (10)%, 3 Month Locked, and 4 Percent Monthly for 25 Months
		vestingTypes.push(VestingType(40000000000000000, 0, 90 days, 0, true));
		// Allocation #9 / VestingType # 9, Liquidity (5)%, 32 Month Locked, and 100 Percent for 1 Month after
		vestingTypes.push(VestingType(1000000000000000000, 0, 960 days, 0, true));
		// Allocation #10 / VestingType # 10, Reserves-Liquidty (10)%, 1 Month Locked, and 8.333333333 Percent Monthly for 12 Months
		vestingTypes.push(VestingType(8333333333333333, 0, 30 days, 0, true));
		// Allocation #11 / VestingType # 11, Development (12)%, 0 Month Locked, and  4 Percent Monthly for 25 Months
		vestingTypes.push(VestingType(40000000000000000, 40000000000000000, 0, 0, true));
		// Allocation #12 / VestingType # 12, Gameplay (15)%, 8 Month Locked, and 8.333333333 Percent Monthly for 12 Months
		vestingTypes.push(VestingType(8333333333333333, 0, 240 days, 0, true));
		// Allocation #13 / VestingType # 13, EcoSystem (20)%, 4 Month Locked, and 8.333333333 Percent Monthly for 12 Months
		vestingTypes.push(VestingType(8333333333333333, 0, 120 days, 0, true));
		// Allocation #14 / VestingType # 14, Initil Promotion (1)%, 0 Month Locked, 25 Percent Initial Unlocked and 25 Percent Monthly for 3 Months
		vestingTypes.push(VestingType(250000000000000000, 250000000000000000, 0, 0, true));
		// Allocation #15 / VestingType # 15, Charity (2)%, 5 Month Locked, 8.333333333 Percent Initial Unlocked and 8.333333333 Percent Monthly for 12 Months
		vestingTypes.push(VestingType(8333333333333333, 0, 180 days, 0, true));
	}

	/**
     * @dev This Method permit getting Maximun total Supply .
     * See {ERC20-_burn}.
     */
	function getMaxTotalSupply() public pure returns (uint256) {
		return _maxTotalSupply;
	}

	/**
     * @dev Circulating Supply Method for Calculated based on Wallets of CANODROME Foundation
     */
	function circulatingSupply() public view returns (uint256 result) {
		result = totalSupply().sub(balanceOf(owner()));
		for (uint256 i=0; i < cane_wallets.length ; i++ ) {
			if ((cane_wallets[i] != address(0)) && (result != 0)) {
				result -= balanceOf(cane_wallets[i]);
			}
		}
		for (uint256 i=0; i < frozenWalletsCount.length ; i++ ) {
			if ((frozenWalletsCount[i] != address(0)) && (result != 0)) {
				result -= getRestAmount(frozenWalletsCount[i]);
			}
		}
	}

	/**
     * @dev Implementation / Instance of paused methods() in the ERC20.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     * See {ERC20Pausable}.
     */
    function pause(bool status) public onlyOwner() {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

	/**
     * @dev Destroys `amount` tokens from the caller.
     * @param amount Amount token to burn
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

	/**
     * @dev Override the Hook of Open Zeppelin for checking before execute the method transfer/transferFrom/mint/burn.
	 * @param sender Addres of Sender of the token
     * @param amount Amount token to transfer/transferFrom/mint/burn, Verify that in hook _beforeTokenTransfer
     */
	function canTransfer(address sender, uint256 amount) public view returns (bool) {
        // Control is scheduled wallet
        if (!frozenWallets[sender].scheduled) {
            return true;
        }

        uint256 balance = balanceOf(sender);
        uint256 restAmount = getRestAmount(sender);

		if(balance.sub(restAmount) < amount) {
			return false;
		}

        return true;
	}

	/**
     * @dev Override the Hook of Open Zeppelin for checking before execute the method transfer/transferFrom/mint/burn.
	 * @param sender Addres of Sender of the token
	 * @param recipient Address of Receptor of the token
     * @param amount Amount token to transfer/transferFrom/mint/burn
     * See {ERC20 Upgradeable}.
     */
	function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal virtual override notBlacklisted(sender) {
		require(!isBlacklisted(recipient), "ERC20 CANE: recipient account is blacklisted");
		// Permit the Owner execute token transfer/mint/burn while paused contract
		if (_msgSender() != owner()) {
			require(!paused(), "ERC20 CANE: token transfer/mint/burn while paused");
		}
        require(canTransfer(sender, amount), "ERC20 CANE: Wait for vesting day!");
        super._beforeTokenTransfer(sender, recipient, amount);
    }

	/**
     * @dev Override the Standard Transfer Method of Open Zeppelin for checking before if Transfer status is Enabled or Disable.
	 * @param sender Addres of Sender of the token
	 * @param recipient Address of Receptor of the token
     * @param amount Amount token to transfer/transferFrom/mint/burn
     * See {https://github.com/ShieldFinanceHQ/contracts/blob/master/contracts/ShieldToken.sol}.
     */
	function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (isTransferDisabled()) {
            // anti-sniping bot defense is on
            // burn tokens instead of transferring them >:]
            super._burn(sender, amount);
            emit TransferBurned(sender, amount);
        } else {
			if ((!isWhale(sender)) && (!isGambler(sender)) && (sender != owner()) && (recipient != owner()) && (!isCaneWallet(sender)) && (!isCaneWallet(recipient))) {
				// Add the recipient to the list of Trader Wallets
				if (!isTrader(recipient)) {
					walletTraded[recipient] = getTimestamp();
				}
				super._transfer(sender, recipient, getRestAmountOfFee(sender, amount));
			} else {
				if (isGambler(sender)) {
					if (walletGamblers[sender] >= amount) {
						walletGamblers[sender] = walletGamblers[sender].sub(amount);
						super._transfer(sender, recipient, amount);
					} else if ((amount - walletGamblers[sender] ) > 10000 ether) {
						super._burn(sender, mulDiv(amount, 3e17, 1e18));
						amount = mulDiv(amount, 7e17, 1e18);
						super._transfer(sender, recipient, getRestAmountOfFee(sender, (amount - walletGamblers[sender])));
					} else {
						super._transfer(sender, recipient, walletGamblers[sender]);
						super._transfer(sender, recipient, getRestAmountOfFee(sender, (amount - walletGamblers[sender])));
					}
				} else if (isWhale(sender)) {
					// if the sender is a Whale, Burn 30% and the rest 70% is evaluated as a Trader Wallet,
					// and the Gamblers Wallet not take account in this evaluation
					super._burn(sender, mulDiv(amount, 3e17, 1e18));
					super._transfer(sender, recipient, getRestAmountOfFee(sender, mulDiv(amount, 7e17, 1e18)));
				} else {
					super._transfer(sender, recipient, amount);
				}
			}
		}
	}

	/**
     * @dev Creates `amount` new tokens for `to`.
	 * @param _amount Amount Token to mint
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `OWNER`.
		 * - After upgrade the SmartContract and Eliminate this method
     */
    function mint( uint256 _amount) public onlyOwner() {
		require(getMaxTotalSupply() >= totalSupply().add(_amount), "ERC20: Can't Mint, it exceeds the maximum supply ");
        _mint(owner(), _amount);
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
library SafeMathUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

/// @title CAN Token V1 / Polygon v1
/// @author Alfredo Lopez / CANDROME 2022.1 */

pragma solidity 0.8.4;

import "./Vesting.sol";

// Struct for detecting Whale Movement, where the receiver is the index of the mapping
 struct WhaleDetector {
	bool active;
	address sender;
	address receiver;
	uint256 amount;
	uint256 timestamp;
 }

/**
 * @title Blacklistable Methods
 * @dev Allows accounts to be blacklisted by Owner
 */
contract StabilityFee is Vesting {

	// Mapping of Wallet to Trade with CAN Token
	// Address Wallet / uint256 Timestamp
	mapping (address => uint256) public walletTraded;
	// Address Wallet / uint256 Amount of CAN Token permit to trade
	mapping (address => uint256) public walletGamblers;
	// Mapping for Whale Movement
	WhaleDetector[] public whaleMovement;

	/**
	 * @dev Allows Vefiry if the User are Trader or not with CAN Token
	 * @param _wallet Address of the User
	 * @return bool
	 */
	function isTrader(address _wallet) public view returns (bool) {
		return walletTraded[_wallet] != 0;
	}

	/**
	 * @dev Allows Vefiry if the User are Gamblers or not with CAN Token
	 * @param _wallet Address of the User
	 * @return bool
	 */
	function isGambler(address _wallet) public view returns (bool) {
		return walletGamblers[_wallet] != 0;
	}

	/**
	 * @dev Allows Vefiry if the User are Whale or not with CAN Token
	 * @param _wallet Address of the User
	 * @return bool
	 */
	function isWhale(address _wallet) public returns (bool) {
		// Eliminate all regiter Whale Movement,with a timestamp more than 90 days
		for (uint256 i = 0; i < whaleMovement.length; i++) {
			if (whaleMovement[i].timestamp <= (getTimestamp() - 90 days)) {
				whaleMovement[i] = whaleMovement[whaleMovement.length - 1];
				whaleMovement.pop();
			}
		}
		for (uint256 i = 0; i < whaleMovement.length; i++) {
			if ((whaleMovement[i].receiver == _wallet) && (whaleMovement[i].amount >= 10000 ether)) {
				return true;
			}
		}
	}

	/**
	 * @dev Allows to add a Trader to the list of Traders
	 * @param _wallet Address of the User
	 * @param _amount uint256 Amount of CAN Token permit to trade
	 * @return bool
	 */
	function addGambler(address _wallet, uint256 _amount) public returns (bool) {
		if (!isTrader(_wallet)) {
			walletTraded[_wallet] = getTimestamp();
		}
		walletGamblers[_wallet] += _amount;
		return true;
	}

	function getRestAmountOfFee(address _wallet, uint256 _amount) public returns (uint256) {
		uint256 time = getTimestamp();
		uint256 timeWallet = walletTraded[_wallet];
		if (timeWallet == 0) {
			// Add wallet i register of wallet that traded with CAN Token
			walletTraded[_wallet] = time;
			// Transfer 10% amount to Liquifidy Pool
			transfer(cane_wallets[1], mulDiv(_amount, 10e16, 1e18));
			// Transfer 10% amount of Reward Holders Pool of CAN Token
			transfer(cane_wallets[2], mulDiv(_amount, 10e16, 1e18));
			// Transfer 4% amount of Reward EcoSystem Pool of CAN Token
			transfer(cane_wallets[3], mulDiv(_amount, 4e16, 1e18));
			// Transfer 3% amount of Charity Pool of CAN Token
			transfer(cane_wallets[4], mulDiv(_amount, 3e16, 1e18));
			// Burn 3% amount of CAN Token to Tranfer to the Wallet
			_burn(msg.sender, mulDiv(_amount, 3e16, 1e18));
			return mulDiv(_amount, 70e16, 1e18);
		} else if (time <= (timeWallet+30 days)) {
			// Transfer 10% amount to Liquifidy Pool
			transfer(cane_wallets[1], mulDiv(_amount, 10e16, 1e18));
			// Transfer 10% amount of Reward Holders Pool of CAN Token
			transfer(cane_wallets[2], mulDiv(_amount, 10e16, 1e18));
			// Transfer 4% amount of Reward EcoSystem Pool of CAN Token
			transfer(cane_wallets[3], mulDiv(_amount, 4e16, 1e18));
			// Transfer 3% amount of Charity Pool of CAN Token
			transfer(cane_wallets[4], mulDiv(_amount, 3e16, 1e18));
			// Burn 3% amount of CAN Token to Tranfer to the Wallet
			_burn(msg.sender, mulDiv(_amount, 3e16, 1e18));
			return mulDiv(_amount, 70e16, 1e18);
		} else if ((time > (timeWallet+30 days)) && (time <= (timeWallet+90 days))) {
			// Transfer 4% amount to Liquifidy Pool
			transfer(cane_wallets[1], mulDiv(_amount, 4e16, 1e18));
			// Transfer 6% amount of Reward Holders Pool of CAN Token
			transfer(cane_wallets[2], mulDiv(_amount, 6e16, 1e18));
			// Transfer 2% amount of Reward EcoSystem Pool of CAN Token
			transfer(cane_wallets[3], mulDiv(_amount, 2e16, 1e18));
			// Transfer 1% amount of Charity Pool of CAN Token
			transfer(cane_wallets[4], mulDiv(_amount, 1e16, 1e18));
			// Burn 2% amount of CAN Token to Tranfer to the Wallet
			_burn(msg.sender, mulDiv(_amount, 2e16, 1e18));
			return mulDiv(_amount, 85e16, 1e18);
		} else if ((time > (timeWallet+90 days)) && (time <= (timeWallet+180 days))) {
			// Transfer 2% amount to Liquifidy Pool
			transfer(cane_wallets[1], mulDiv(_amount, 1e16, 1e18));
			// Transfer 3% amount of Reward Holders Pool of CAN Token
			transfer(cane_wallets[2], mulDiv(_amount, 3e16, 1e18));
			// Transfer 1% amount of Reward EcoSystem Pool of CAN Token
			transfer(cane_wallets[3], mulDiv(_amount, 1e16, 1e18));
			// Transfer 1% amount of Charity Pool of CAN Token
			transfer(cane_wallets[4], mulDiv(_amount, 1e16, 1e18));
			// Burn 1% amount of CAN Token to Tranfer to the Wallet
			_burn(msg.sender, mulDiv(_amount, 2e16, 1e18));
			return mulDiv(_amount, 92e16, 1e18);
		} else if ((time > (timeWallet+180 days)) && (time <= (timeWallet+360 days))) {
			// Transfer 1% amount of Reward Holders Pool of CAN Token
			transfer(cane_wallets[2], mulDiv(_amount, 2e16, 1e18));
			// Transfer 1% amount of Reward EcoSystem Pool of CAN Token
			transfer(cane_wallets[3], mulDiv(_amount, 1e16, 1e18));
			// Transfer 1% amount of Charity Pool of CAN Token
			transfer(cane_wallets[4], mulDiv(_amount, 1e16, 1e18));
			// Burn 1% amount of CAN Token to Tranfer to the Wallet
			_burn(msg.sender, mulDiv(_amount, 1e16, 1e18));
			return mulDiv(_amount, 95e16, 1e18);
		} else if (time > (timeWallet+360 days)) {
			return _amount;
		}
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

/// @title CANE Token V1 / Polygon v1
/// @author Alfredo Lopez / CANEDROME 2022.1 */

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./Claimable.sol";
import "./Math.sol";

struct FrozenWallet {
	bool scheduled;
	uint32 startDay;
    uint32 afterDays;
    address wallet;
    uint256 totalAmount;
    uint256 monthDelay;
	uint256 dailyAmount;
    uint256 initialAmount;
}

struct VestingType {
	uint256 dailyRate;
    uint256 initialRate;
    uint256 afterDays;
	uint256 monthDelay;
	bool vesting;
}

/**
 * @title Vesting Methods
 * @dev All Method to permit handle the Vesting Process of CANE token
 */
contract Vesting is OwnableUpgradeable, Math, Claimable, PausableUpgradeable, ERC20PermitUpgradeable {
	using SafeMathUpgradeable for uint256;

	// Mapping of FrozenWallet
	// Address Wallets -> Struc FrozenWallet
	mapping (address => FrozenWallet) public frozenWallets;
	// Count FrozenWallets
	address[] public frozenWalletsCount;
	// Array of Struc Vesting Types
    VestingType[] public vestingTypes;

	// Event
	event inFrozenWallet(
		bool scheduled,
		uint32 startDay,
		uint32 afterDays,
		address indexed wallet,
		uint256 indexed totalAmount,
		uint256 monthDelay,
		uint256 dailyAmount,
		uint256 initialAmount
	);

    /**
     * @dev Method to permit to get the Exactly Unix Epoch of Token Generate Event
     */
	function getReleaseTime() public pure returns (uint256) {
        return 1648818000; // "Friday, 1 April 2021 13:00:00 GMT"
    }

    /**
     * @dev Principal Method to permit Upload all wallets in all allocation, based on Vesting Process
	 * @dev this method was merge with transferMany method for reduce the cost in gass around 30%
	 * @param addresses Array of Wallets will be Frozen with Locked and Unlocked Token Based on the Predefined Allocation
	 * @param totalAmounts Array of Amount coprresponding with each wallets, will be Locked and Unlocked Based on the Predefined Allocation
	 * @param vestingTypeIndex Index corresponding to the List of Wallets to be Upload in the Smart Contract ERC20 of OMNI Foundation
     */
    function addAllocations(address[] calldata addresses, uint256[] calldata totalAmounts, uint256 vestingTypeIndex) external onlyOwner() whenNotPaused() returns (bool) {
        require(addresses.length == totalAmounts.length, "Address and totalAmounts length must be same");
		VestingType memory vestingType = vestingTypes[vestingTypeIndex];
        require(vestingType.vesting, "Vesting type isn't found");

        uint256 addressesLength = addresses.length;
		uint256 total = 0;

		for(uint256 i = 0; i < addressesLength; i++) {
			address _address = addresses[i];
			require(_address != address(0), "ERC20: transfer to the zero address");
			require(!isBlacklisted(_address), "ERC20 CANE: recipient account is blacklisted");
			require(totalAmounts[i] != 0, "ERC20 CANE: total amount token is zero");
			total = total.add(totalAmounts[i]);
		}

		if (total > balanceOf(msg.sender)) { revert("ERC20 CANE: insufficient funds"); }

        for(uint256 j = 0; j < addressesLength; j++) {
            address _address = addresses[j];
            uint256 totalAmount = totalAmounts[j];
            uint256 dailyAmount = mulDiv(totalAmounts[j], vestingType.dailyRate, 100e18);
            uint256 initialAmount = mulDiv(totalAmounts[j], vestingType.initialRate, 100e18);
            uint256 afterDay = vestingType.afterDays;
            uint256 monthDelay = vestingType.monthDelay;

			// Transfer Token to the Wallet
            transfer(_address, totalAmount);
            emit Transfer(msg.sender, _address, totalAmount);

			// Frozen Wallet
            addFrozenWallet(_address, totalAmount, dailyAmount, initialAmount, afterDay, monthDelay);
        }

        return true;
    }

    /**
     * @dev Auxiliary Method to permit Upload all wallets in all allocation, based on Vesting Process
	 * @param wallet Wallet will be Frozen based on correspondig Allocation
	 * @param totalAmount Total Amount of Stake holder based on Investment and the Allocation to participate
	 * @param dailyAmount Daily Amount of Stake holder based on Investment and the Allocation to participate
	 * @param initialAmount Initial Amount of Stake holder based on Investment and the Allocation to participate
	 * @param afterDays Period of Days after to start Unlocked Token based on the Allocation to participate
     */
	function addFrozenWallet(address wallet, uint256 totalAmount,uint256 dailyAmount ,uint256 initialAmount, uint256 afterDays, uint256 monthDelay) internal {
        uint256 releaseTime = getReleaseTime();

        // Create frozen wallets
        FrozenWallet memory frozenWallet = FrozenWallet(
			true,
			uint32(releaseTime.add(afterDays)),
            uint32(afterDays),
            wallet,
            totalAmount,
			monthDelay,
			dailyAmount,
            initialAmount
        );

        // Add wallet to frozen wallets
        frozenWallets[wallet] = frozenWallet;

		// Add wallet to frozen wallets count
		if (!isFrozenWalletsCount(wallet)) {
			// Verify if the wallet exist in the array
			frozenWalletsCount.push(wallet);
		}

		// emit Event add Frozen Wallet
		emit inFrozenWallet(
			true,
			uint32(releaseTime.add(afterDays)),
            uint32(afterDays),
			wallet,
            totalAmount,
			monthDelay,
			dailyAmount,
            initialAmount);
    }

    /**
     * @dev Auxiliary Method to permit to get the Last Exactly Unix Epoch of Blockchain timestamp
     */
    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

	/**
     * @dev Auxiliary Method to permit get the number of days elapsed time from the TGE to the current moment
	 * @param afterDays Period of Days after to start Unlocked Token based on the Allocation to participate
	 */
    function getDays(uint256 afterDays) public view returns (uint256 dias) {
        uint256 releaseTime = getReleaseTime();
        uint256 time = releaseTime.add(afterDays);

        if (block.timestamp < time) {
            return dias;
        }

        uint256 diff = block.timestamp.sub(time);
        dias = diff.div(24 hours);
    }

    /**
     * @dev Auxiliary Method to permit get of token can be transferable based on Allocation of the Frozen Wallet
	 * @param sender Wallets of Stakeholders to verify amount of Token are Unlocked based on Allocation
	 */
    function getTransferableAmount(address sender) public view returns (uint256 transferableAmount) {
		uint256 releaseTime = getReleaseTime();
		FrozenWallet memory frozenWallet = frozenWallets[sender];

		// Verify if the vesting is start or not, and if the vesting is start,
		// verify if the vesting allocation is different to Liquidity Pool
		// Because this Liquidity Pool must be transferable immediately
		if ((block.timestamp < releaseTime) && (frozenWallet.dailyAmount != frozenWallet.totalAmount)) {
            return transferableAmount;
        }

		uint256 dias = getDays(frozenWallet.afterDays);
		uint256 dailyTransferableAmount = frozenWallet.dailyAmount.mul(dias);
		transferableAmount = dailyTransferableAmount.add(frozenWallet.initialAmount);

        if (transferableAmount > frozenWallets[sender].totalAmount) {
            return frozenWallets[sender].totalAmount;
        }

        return transferableAmount;
    }


    /**
     * @dev Auxiliary Method to permit get of token can't be transferable based on Allocation of the Frozen Wallet
	 * @param sender Wallets of Stakeholders to verify amount of Token are locked based on Allocation
	 */
	function getRestAmount(address sender) public view returns (uint256 restAmount) {
        uint256 transferableAmount = getTransferableAmount(sender);
        restAmount = frozenWallets[sender].totalAmount.sub(transferableAmount);
    }

	function isFrozenWalletsCount (address wallet) public view returns (bool) {
		for(uint i = 0; i < frozenWalletsCount.length; i++) {
			if (frozenWalletsCount[i] == wallet) {
				return true;
			}
		}
		return false;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/draft-EIP712Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __Context_init_unchained();
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
    }

    function __ERC20Permit_init_unchained(string memory name) internal onlyInitializing {
        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

/// @title CANE Token V1 / Polygon v1
/// @author Alfredo Lopez / CANEDROME 2022.1 */

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./CirculatingSupply.sol";

/**
 * @title Claimable Methods
 * @dev Implementation of the claiming utils that can be useful for withdrawing accidentally sent tokens that are not used in bridge operations.
 */
contract Claimable is OwnableUpgradeable, CirculatingSupply {
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;
	// Event when the Smart Contract receive Amount of Native or ERC20 tokens
	event ValueReceived(address indexed sender, uint256 indexed value);

	/// @notice Handle receive ether
	receive() external payable
	{
		emit ValueReceived(_msgSender(), msg.value);
	}

    /**
     * @dev Withdraws the erc20 tokens or native coins from this contract.
     * Caller should additionally check that the claimed token is not a part of bridge operations (i.e. that token != erc20token()).
     * @param _token address of the claimed token or address(0) for native coins.
     * @param _to address of the tokens/coins receiver.
     */
    function claimValues(address _token, address _to) public validAddress(_to) notBlacklisted(_to) onlyOwner() {
        if (_token == address(0)) {
            _claimNativeCoins(_to);
        } else {
            _claimErc20Tokens(_token, _to);
        }
    }

    /**
     * @dev Internal function for withdrawing all native coins from the contract.
     * @param _to address of the coins receiver.
     */
    function _claimNativeCoins(address _to) private {
        uint256 amount = address(this).balance;

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = _to.call{ value: amount }("");
        require(success, "ERC20: Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC20 contract from this contract.
     * @param _token address of the claimed ERC20 token.
     * @param _to address of the tokens receiver.
     */
    function _claimErc20Tokens(address _token, address _to) private {
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_to, balance);
    }
}

// SPDX-License-Identifier: MIT

/// @title CANE Token V1 / Polygon v1
/// @author Alfredo Lopez / CANEDROME 2022.1 */

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/**
 * @title Math Library
 * @dev Allows handle 512-bit multiply, RoundingUp
 */
contract Math {
	using SafeMathUpgradeable for uint256;

	function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (type(uint256).max - denominator.add(uint256(1))) & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

/// @title CANE Token V1 / Polygon v1
/// @author Alfredo Lopez / CANEDROME 2022.1 */

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Antibots.sol";

/**
 * @title Circulating Supply Methods
 * @dev Allows update the wallets of CANE Foundation by Owner
 */
contract CirculatingSupply is OwnableUpgradeable, Antibots {
	// Array of address
    address[] internal cane_wallets;

    event InCaneWallet(address indexed _account);
    event OutCaneWallet(address indexed _account);

	/**
     * @dev function to verify if the address exist in CaneWallet or not
     * @param _account The address to check
     */
	function isCaneWallet(address _account) public view returns (bool) {
		if (_account == address(0)) {
			return false;
		}
		uint256 index = cane_wallets.length;
		for (uint256 i=0; i < index ; i++ ) {
			if (_account == cane_wallets[i]) {
				return true;			}
		}
		return false;
	}

	/**
     * @dev Include the wallet in the wallets address of CANE Foundation Wallets
     * @param _account The address to include
     */
	function addCaneWallet(address _account) public validAddress(_account) onlyOwner() returns (bool) {
		require(!isCaneWallet(_account), "ERC20 CANE: wallet is already");
		cane_wallets.push(_account);
		emit InCaneWallet(_account);
		return true;
	}

	/**
     * @dev Exclude the wallet in the wallets address of CANE Foundation Wallets
     * @param _account The address to exclude
     */
	function dropCaneWallet(address _account) public validAddress(_account) onlyOwner() returns (bool) {
		require(isCaneWallet(_account), "ERC20 CANE: Wallet don't exist");
		uint256 index = cane_wallets.length;
		for (uint256 i=0; i < index ; i++ ) {
			if (_account == cane_wallets[i]) {
				cane_wallets[i] = cane_wallets[index - 1];
				cane_wallets.pop();
				emit OutCaneWallet(_account);
				return true;
			}
		}
		return false;
	}

	/**
     * @dev Getting the all wallets address of CANE Foundation Wallets
     */
	function getCaneWallets() public view returns (address[] memory) {
		return cane_wallets;
	}

}

// SPDX-License-Identifier: MIT

/// @title CANE Token V1 / Polygon v1
/// @author Alfredo Lopez / CANEDROME 2022.1 */

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Blacklistable.sol";

/**
 * @title AntiBots Methods
 * @dev Allows  by Owner
 */
contract Antibots is OwnableUpgradeable, Blacklistable {

	// anti-sniping bot defense
    uint256 private burnBeforeBlockNumber;
    bool private burnBeforeBlockNumberDisabled;
	// Arrays whitelist
	address[] private whitelist_wallets;

	// Event where Transfer is Burned
	event TransferBurned(address indexed wallet, uint256 amount);
	// Event Disable Antibots defense forever
	event DisableDefenseAntiBots (uint256 blockNumber, bool statusDefense);
	// Event for Add/Drop Whitelist Wallets
	event InWhiteListWallet(address indexed _account);
    event OutWhiteListWallet(address indexed _account);

	// anti-sniping bot defense
	/**
     * @dev Getting Internal in the smart Contract the Status of Antibots Defense
     */
    function isTransferDisabled() internal view returns (bool) {
        if (_msgSender() == owner()) {
            // owner always can transfer
            return false;
        }
		if (isWhiteListed(_msgSender())) {
			// WhiteListed Wallets can transfer
			return false;
		}
        return (!burnBeforeBlockNumberDisabled && (block.number < burnBeforeBlockNumber));
    }

	/**
     * @dev Antibots Defense - Block any transfer and burn any tokens
	 * @dev Setting the number of blocks that disable the Transfer methods, and burn any call
	 * @param blocksDuration number of block that transfer are disabled, and any transfer will be burned
     */
    function disableTransfers(uint256 blocksDuration) public onlyOwner() {
        require(!burnBeforeBlockNumberDisabled, "Bot defense is disabled");
        burnBeforeBlockNumber = block.number + blocksDuration;
    }

	/**
     * @dev Antibots Defense - Disable Antibot Defense Forever!!
	 * @dev Setting boolean burnBeforeBlockNumberDisabled in true and disable the antibots Defense
     */
    function disableBurnBeforeBlockNumber() public onlyOwner() {
        burnBeforeBlockNumber = uint(0);
        burnBeforeBlockNumberDisabled = true;
		emit DisableDefenseAntiBots (block.number, burnBeforeBlockNumberDisabled);
    }
	/** --------------------- GETTER -----------------------------*/
	/**
     * @dev Antibots Defense - Getting the status of Transfer Disabled (true or false)
	 * @dev Return the status of TransferDisabled function
     */
	function getIsTransferDisabled() public view returns (bool) {
		return (!burnBeforeBlockNumberDisabled && (block.number < burnBeforeBlockNumber));
	}

	/**
     * @dev Antibots Defense - Getting the value of varialbe internal burnBeforeBlockNumber
	 * @dev Return the block Number when the Transfer are Enable again!!
     */
	function getBurnBeforeBlockNumber() public view onlyOwner() returns (uint256){
		return burnBeforeBlockNumber;
	}

	/**
     * @dev Antibots Defense - Getting the status of Antibots Defense are available (true or false)
	 * @dev Return boolean status if the Antibots Defense can used or never again!!
     */
	function getBurnBeforeBlockNumberDisabled() public view returns (bool) {
		return burnBeforeBlockNumberDisabled;
	}

	/** ----------------- WHITELIST ---------------------- */

	/**
     * @dev function to verify if the address exist or not in the Whitelisted Array
     * @param _account The address to check
     */
	function isWhiteListed(address _account) public view returns (bool) {
		if (_account == address(0)) {
			return false;
		}
		uint256 index = whitelist_wallets.length;
		for (uint256 i=0; i < index ; i++ ) {
			if (_account == whitelist_wallets[i]) {
				return true;			}
		}
		return false;
	}

	/**
     * @dev Include the wallet in the wallets address of Whitelisted in the Antibots Defense
     * @param _account The address to include
     */
	function addWhiteListed(address _account) public validAddress(_account) onlyOwner() returns (bool) {
		require(!isWhiteListed(_account), "ERC20 CANE: wallet is already");
		whitelist_wallets.push(_account);
		emit InWhiteListWallet(_account);
		return true;
	}

	/**
     * @dev Exclude the wallet in the wallets address of Whitelisted in the Antibots Defense
     * @param _account The address to exclude
     */
	function dropWhiteListed(address _account) public validAddress(_account) onlyOwner() returns (bool) {
		require(isWhiteListed(_account), "ERC20 CANE: Wallet don't exist");
		uint256 index = whitelist_wallets.length;
		for (uint256 i=0; i < index ; i++ ) {
			if (_account == whitelist_wallets[i]) {
				whitelist_wallets[i] = whitelist_wallets[index - 1];
				whitelist_wallets.pop();
				emit OutWhiteListWallet(_account);
				return true;
			}
		}
		return false;
	}

	/**
     * @dev Getting the all wallets address Whitelisted in the Antibots Defense
     */
	function getWhiteListWallets() public view returns (address[] memory) {
		return whitelist_wallets;
	}
}

// SPDX-License-Identifier: MIT

/// @title CANE Token V1 / Polygon v1
/// @author Alfredo Lopez / CANEDROME 2022.1 */

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Blacklistable Methods
 * @dev Allows accounts to be blacklisted by Owner
 */
contract Blacklistable is OwnableUpgradeable {

	// Index Address
	address[] private wallets;
	// Mapping blacklisted Address
    mapping(address => bool) private blacklisted;
	// Events when add or drop a wallets in the blacklisted mapping
    event InBlacklisted(address indexed _account);
    event OutBlacklisted(address indexed _account);


    /**
     * @dev Throws if argument account is blacklisted
     * @param _account The address to check
     */
    modifier notBlacklisted(address _account) {
        require(
            !blacklisted[_account],
            "ERC20 CANE: sender account is blacklisted"
        );
        _;
    }

	/**
     * @dev Throws if a given address is equal to address(0)
	 * @param _to The address to check
     */
    modifier validAddress(address _to) {
        require(_to != address(0), "ERC20 CANE: Not Add Zero Address");
        /* solcov ignore next */
        _;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check
     */
    function isBlacklisted(address _account) public view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
     */
    function addBlacklist(address _account) public validAddress(_account) notBlacklisted(_account) onlyOwner() {
        blacklisted[_account] = true;
		wallets.push(_account);
        emit InBlacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
     */
    function dropBlacklist(address _account) public validAddress(_account) onlyOwner() {
		require(isBlacklisted(_account), "ERC20 CANE: Wallet don't exist");
        blacklisted[_account] = false;
        emit OutBlacklisted(_account);
    }

    /**
     * @dev Getting the List of Address Blacklisted
     */
	function getBlacklist() public view returns (address[] memory) {
		return wallets;
	}

}