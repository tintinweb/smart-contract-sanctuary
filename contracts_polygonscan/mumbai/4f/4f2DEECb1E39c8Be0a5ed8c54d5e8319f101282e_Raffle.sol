// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Entities.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Raffle is Ownable {
	uint rafflesCount;
    mapping(uint => Entities.Raffle) public raffles;
	mapping(address => Entities.Raffle[]) public rafflesByAddress;

	uint prizesCount;
	mapping(uint => Entities.Prize) private prizes;

	address exchangeToken;
	address treasury;

	uint8 feePercentage;

	constructor() {
		rafflesCount = 0;
		prizesCount = 0;
	}

    function createRaffle(
        uint256 _price,
        uint256 _resolutionTimestamp,
        Entities.Prize[] memory _prizes,
        uint256 _maxTickets
    ) public {
		uint[] memory _prizesIds = new uint[](_prizes.length);
		for (uint i = 0; i < _prizes.length; i++) {
			uint prizeId = prizesCount + i + 1;
			prizes[prizeId] = _prizes[i];
			_prizesIds[i] = prizeId;
		}

		Entities.Raffle memory raffle = Entities.Raffle({
			sponsor: msg.sender,
			price: _price,
			maxTickets: _maxTickets,
			mintedTickets: new uint[](0),
			prizesIds: _prizesIds,
			resolutionTimestamp: _resolutionTimestamp,
			winnerTicket: -1,
			exists: true
		});

        raffles[rafflesCount] = raffle;
		rafflesByAddress[msg.sender].push(raffle);
		rafflesCount++;
    }

	function setExchangeToken(address _address) external onlyOwner {
		exchangeToken = _address;
	}

	function setTreasury(address _address) external onlyOwner {
		treasury = _address;
	}

	function setFeePercentage(uint8 _feePercentage) external onlyOwner {
		feePercentage = _feePercentage;
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Entities {
    struct Raffle {
        address sponsor;
        uint price;
        uint maxTickets;
        uint[] mintedTickets;
        uint[] prizesIds;
        uint resolutionTimestamp;
        int winnerTicket;
        bool exists;
    }

    struct Prize {
        string name;
        uint amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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