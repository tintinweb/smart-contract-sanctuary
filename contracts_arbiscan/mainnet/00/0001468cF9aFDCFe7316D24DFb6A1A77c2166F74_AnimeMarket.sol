/**
 *Submitted for verification at arbiscan.io on 2021-12-02
*/

// Sources flattened with hardhat v2.6.6 https://hardhat.org

// File @devprotocol/protocol-v2/contracts/interface/[email protected]

// SPDX-License-Identifier: MPL-2.0
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

interface IMarket {
	function authenticate(address _prop, string[] memory _args)
		external
		returns (bool);

	function authenticateFromPropertyFactory(
		address _prop,
		address _author,
		string[] memory _args
	) external returns (bool);

	function authenticatedCallback(address _property, bytes32 _idHash)
		external
		returns (address);

	function deauthenticate(address _metrics) external;

	function name() external view returns (string memory);

	function schema() external view returns (string memory);

	function behavior() external view returns (address);

	function issuedMetrics() external view returns (uint256);

	function enabled() external view returns (bool);

	function votingEndTimestamp() external view returns (uint256);

	function getAuthenticatedProperties()
		external
		view
		returns (address[] memory);

	function toEnable() external;
}


// File @devprotocol/protocol-v2/contracts/interface/[email protected]

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

interface IMarketBehavior {
	function authenticate(
		address _prop,
		string[] memory _args,
		address account
	) external returns (bool);

	function setAssociatedMarket(address _market) external;

	function associatedMarket() external view returns (address);

	function name() external view returns (string memory);

	function schema() external view returns (string memory);

	function getId(address _metrics) external view returns (string memory);

	function getMetrics(string memory _id) external view returns (address);
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File contracts/AnimeMarket.sol

pragma solidity ^0.8.0;



contract AnimeMarket is IMarketBehavior, Ownable {
	address public override associatedMarket;
	address public marketFactory;
	mapping(address => string) internal keys;
	mapping(address => bool) internal isAnimeStudio;
	mapping(string => address) private addresses;
	address public currentAuthinticateAccount;

	function schema() external override pure returns (string memory) {
    return '["Anime Studio Name"]';
  }

	/**
	 * Initialize the passed address as Market Factory address.
	 */
	constructor(address _marketFactory) {
		marketFactory = _marketFactory;
	}

	function setAssociatedMarket(address _associatedMarket) external override {
		require(marketFactory == msg.sender, "illegal sender");
		associatedMarket = _associatedMarket;
	}

	function name() external pure override returns (string memory) {
		return "Anime Bank Market1";
	}

	function setAnimeStudio(address studio) external onlyOwner {
		isAnimeStudio[studio] = true;
	}

	function authenticate(
		address _prop,
		string[] memory _args,
		address account
	) external override returns (bool) {
		require(msg.sender == associatedMarket, "Invalid sender");
		require(isAnimeStudio[account], "Invalid account");

		bytes32 idHash = keccak256(abi.encodePacked(_args[0]));
		address _metrics = IMarket(msg.sender).authenticatedCallback(
			_prop,
			idHash
		);
		keys[_metrics] = _args[0];
		addresses[_args[0]] = _metrics;
		currentAuthinticateAccount = account;

		return true;
	}

	function getId(address _metrics)
		external
		view
		override
		returns (string memory)
	{
		return keys[_metrics];
	}

	function getMetrics(string memory _id)
		external
		view
		override
		returns (address)
	{
		return addresses[_id];
	}

	function setMarketFactory(address _marketFactory) external onlyOwner {
		marketFactory = _marketFactory;
	}
}