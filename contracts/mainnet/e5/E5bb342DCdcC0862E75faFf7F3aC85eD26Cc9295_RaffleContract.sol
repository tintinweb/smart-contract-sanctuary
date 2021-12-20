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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RaffleContract is Ownable {
    struct Raffle {
        uint256 seed;
        string listURI;
    }

    Raffle[] private raffles;

    /**
     * @dev Generates a random number and adds the IPFS link to the raffle data
     */
    function addRaffle(string memory _listURI) external onlyOwner {
        raffles.push(Raffle(_generateSeed(), _listURI));
    }

    /**
     * @dev Returns the IPFS link for the raffle
     */
    function getRaffleURI(uint256 _raffleId)
        external
        view
        returns (string memory)
    {
        require(_raffleId < raffles.length, "Invalid raffle id");

        return raffles[_raffleId].listURI;
    }

    /**
     * @dev Returns a list of random numbers for the given input
     * This out is deterministic, by using the seed generated when
     * the raffle was created.
     */
    function getRaffleResults(
        uint256 _raffleId,
        uint256 _totalParticipants,
        uint256 _quantity,
        uint256 _offset
    ) external view returns (uint256[] memory) {
        require(_raffleId < raffles.length, "Invalid raffle id");

        uint256[] memory results = new uint256[](_quantity);
        for (uint256 i = _offset; i < _quantity + _offset; i++) {
            results[i - _offset] = _getRandomNumber(
                _totalParticipants,
                raffles[_raffleId].seed,
                i
            );
        }

        return results;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(
        uint256 _upper,
        uint256 _seed,
        uint256 _index
    ) private pure returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(_seed, _index)));

        return random % _upper;
    }

    /**
     * @dev Generates a pseudo-random seed for a raffle.
     */
    function _generateSeed() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        raffles.length,
                        blockhash(block.number - 1),
                        block.coinbase,
                        block.difficulty,
                        msg.sender
                    )
                )
            );
    }
}