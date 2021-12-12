//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Elo is Ownable {
	mapping(address => uint256) private elo;

	address private _masterContract;

	event EloChanged(address indexed player, uint256 newElo);

	modifier onlyMaster() {
		require(_masterContract == msg.sender, "Function only for Core contract!");
		_;
	}

	function changeMaster(address _newMaster) external onlyOwner {
		_masterContract = _newMaster;
	}

	function getElo(address _player) public view returns (uint256) {
		if (elo[_player] == 0) return 700;
		else return elo[_player];
	}

	function setElo(address _player, uint256 _elo) public onlyMaster {
		if (_elo > 100) {
			elo[_player] = _elo;
			emit EloChanged(_player, _elo);
		}
	}

	function recordResult(
		address player1,
		address player2,
		uint8 outcome
	) external onlyMaster returns (uint256, uint256) {
		// Get current scores
		uint256 scoreA = getElo(player1);
		uint256 scoreB = getElo(player2);

		// Calculate new score
		int256 change = getScoreChange(int256(scoreA) - int256(scoreB), outcome);
		uint256 eloA = uint256(int256(scoreA) + change);
		uint256 eloB = uint256(int256(scoreB) - change);
		setElo(player1, eloA);
		setElo(player2, eloB);
		return ((eloA > 100 ? eloA : 100), (eloB > 100 ? eloB : 100));
	}

	function getScoreChange(int256 difference, uint256 outcome)
		public
		pure
		returns (int256)
	{
		bool reverse = (difference > 0); // note if difference was positive
		uint256 diff = abs(difference); // take absolute to lookup in positive table
		// Score change lookup table
		int256 scoreChange = 10;
		if (diff > 636) scoreChange = 20;
		else if (diff > 436) scoreChange = 19;
		else if (diff > 338) scoreChange = 18;
		else if (diff > 269) scoreChange = 17;
		else if (diff > 214) scoreChange = 16;
		else if (diff > 168) scoreChange = 15;
		else if (diff > 126) scoreChange = 14;
		else if (diff > 88) scoreChange = 13;
		else if (diff > 52) scoreChange = 12;
		else if (diff > 17) scoreChange = 11;
		// Depending on result (win/draw/lose), calculate score changes
		if (outcome == 3) {
			return (reverse ? 20 - scoreChange : scoreChange);
		} else if (outcome == 4) {
			return (reverse ? scoreChange - 20 : -scoreChange);
		} else {
			return (reverse ? 10 - scoreChange : scoreChange - 10);
		}
	}

	function abs(int256 value) public pure returns (uint256) {
		if (value >= 0) return uint256(value);
		else return uint256(-1 * value);
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