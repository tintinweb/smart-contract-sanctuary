/*
	For the sake of this contract and any contract
	associated with house game, when "building" is
	referred, it means both houses and utility
	buildings.

	Dutch Auction ✅
	Minting
	Rendering NFTs
	Tax System (leaderboard, distributing rewards, building weekly pool)
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Importing contracts
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Importing interfaces
import "./interfaces/IBuildings.sol";

/**
	This is the main House Game contract. All player
	interactions will be held through this contract.
*/
contract HouseGame is Ownable, ReentrancyGuard, Pausable {

	// Variables for presale and public sale
	// as well as for generations.
  bool public PUBLIC_SALE_HAS_STARTED;
	uint8 public PRESALE_MAX_TOKEN_WALLET = 3;
	uint8 public PUBLIC_SALE_MAX_TOKEN_WALLET = 5;

	// Prices of buildings for public and presales
	uint256 public constant PRESALE_HOUSE_PRICE = 0.07 ether;
	uint256 public constant PRESALE_UTILITY_PRICE = 0.35 ether;
	uint256 public constant PUBLIC_SALE_HOUSE_MAX = 0.35 ether;
	uint256 public constant PUBLIC_SALE_HOUSE_MIN = 0.07 ether;
	uint256 public constant PUBLIC_SALE_UTILITY_MAX = 1.75 ether;
	uint256 public constant PUBLIC_SALE_UTILITY_MIN = 0.35 ether;

	// Public sale will be a dutch auction. These
	// variables contain information for it.
	uint256 public PUBLIC_SALE_START_TIME;
	uint256 public constant PUBLIC_SALE_DECREMENT_AMOUNT = 0.01 ether;
	uint256 public constant PUBLIC_SALE_DECREMENT_TIME = 3 seconds;

	// Structs for whitelist and last write
	struct Whitelist {
		bool isWhitelisted;
		uint8 minted;
	}

	struct LastWrite {
		uint64 time;
		uint64 blockNum;
	}

	// Mapping for whitelisted and last write
	mapping(address => Whitelist) private _whitelistAddresses;
	mapping(address => LastWrite) private _lastWrite;

	// References to the other game contracts
	IBuildings public buildings;

	/// @notice Initializes the contract in a paused state.
	constructor() {
		_pause();
	}

	/**
		Modifiers
	*/

	modifier onlyEOA() {
		require(tx.origin == _msgSender());
		_;
	}

	modifier requireContracts() {
		require(address(buildings) != address(0), "Contracts have not been set");
		_;
	}

	/**
		External Functions
	*/

	/// @notice Mints both houses and utility buildings.
	function mint(uint32 _amount, bool _house, bool _stake) external payable nonReentrant whenNotPaused onlyEOA {
		uint16 minted = buildings.minted();
		uint16 maxTokens = buildings.maxTokens();
		uint16 ethTokens = buildings.ethTokens();

		require(minted + _amount <= maxTokens, "All tokens have been minted");
		require(_amount > 0 && _amount <= PUBLIC_SALE_MAX_TOKEN_WALLET, "Invalid amount of tokens to be minted");

		if (minted < ethTokens) {
			require(minted + _amount <= ethTokens, "All tokens selling for ETH have been minted");
			if (PUBLIC_SALE_HAS_STARTED) {
				require(_house ? msg.value >= _amount * currentMintPrice(true) : msg.value >= _amount * currentMintPrice(false), "Invalid payment");
			} else {
				require(_whitelistAddresses[_msgSender()].isWhitelisted, "Wallet is not whitelisted");
				require(_whitelistAddresses[_msgSender()].minted + _amount <= PRESALE_MAX_TOKEN_WALLET, "No more whitelist mints available");
				require(_house ? msg.value == _amount * currentMintPrice(true) : msg.value == _amount * currentMintPrice(false), "Invalid payment");
				// _whitelistAddresses[_msgSender()].minted += uint16(_amount);
			}
		} else {
			require(msg.value == 0, "You cannot purchase new tokens with ETH");
		}

		LastWrite storage lw = _lastWrite[tx.origin];

		uint256 seed = 0;
		uint128 totalCashCost = 0;
		uint16[] memory tokenIds = new uint16[](_amount);

		for (uint16 i = 0; i < _amount; i++) {
			seed = 5;
			minted++;
		}
	}

	/**
		Public Functions
	*/

	/// @notice Gets the current price of a building.
  function currentMintPrice(bool _house) public view whenNotPaused onlyEOA returns (uint256 price) {
		if (!PUBLIC_SALE_HAS_STARTED) {
			return (_house ? PRESALE_HOUSE_PRICE : PRESALE_UTILITY_PRICE);
		} else {
			uint256 decrementTimes = (block.timestamp - PUBLIC_SALE_START_TIME) / PUBLIC_SALE_DECREMENT_TIME;
			uint256 decrementAmount = decrementTimes * PUBLIC_SALE_DECREMENT_AMOUNT;

			if ((PUBLIC_SALE_HOUSE_MAX - decrementAmount) < PUBLIC_SALE_HOUSE_MIN) {
				return (_house ? PUBLIC_SALE_HOUSE_MIN     : PUBLIC_SALE_UTILITY_MIN);
			}  

			return (_house ? PUBLIC_SALE_HOUSE_MAX - decrementAmount : PUBLIC_SALE_UTILITY_MAX - (decrementAmount * 5));
		}
  }

	/**
		Owner functions
	*/

	/// @notice Sets game contracts
	function setContracts(address _buildings) external onlyOwner {
		buildings = IBuildings(_buildings);
	}

	/// @notice Starts the public mint
	function startPublicMint() external onlyOwner {
		PUBLIC_SALE_HAS_STARTED = true;
		PUBLIC_SALE_START_TIME = block.timestamp;
	}

	/// @notice Allows the owner to pause/unpause.
	function setPaused(bool _paused) public requireContracts onlyOwner {
		_paused ? _pause() : _unpause();
	}

	/// @notice Whitelists addresses
	function whitelistAddress(address[] calldata _addresses) external onlyOwner {
		for (uint16 i = 0; i < _addresses.length; i++) {
			_whitelistAddresses[_addresses[i]] = Whitelist(true, 0);
		}
	}

	/// @notice Allows the owner to withdraw funds.
	function withdraw() external onlyOwner {
		payable(owner()).transfer(address(this).balance);
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBuildings {

  function mint(address recipient, bool isHouse, uint256 seed) external;
  function minted() external view returns(uint16);
  function maxTokens() external view returns(uint16);
  function ethTokens() external view returns(uint16);

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