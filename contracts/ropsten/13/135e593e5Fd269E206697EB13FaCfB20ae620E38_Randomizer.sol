//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoBees.sol";

contract Randomizer is Ownable {
    ICryptoBees beesContract;
    uint256[] private unrevealedTokens;
    uint256 private unrevealedTokenIndex = 1;

    event MintRevealed(address indexed owner, uint256 tokenId, uint256 _type);

    constructor() {}

    function setBeesContract(address _BEES_CONTRACT) external onlyOwner {
        beesContract = ICryptoBees(_BEES_CONTRACT);
    }

    function unrevealedTokensPush(uint256 blockNum) external {
        require(_msgSender() == address(beesContract), "DONT CHEAT!");
        unrevealedTokens.push(blockNum);
    }

    function revealToken(uint256 blockNum) external {
        require(_msgSender() == address(beesContract), "DONT CHEAT!");

        if (unrevealedTokens[unrevealedTokenIndex] < blockNum) {
            uint256 seed = random(unrevealedTokenIndex);
            uint256 num = ((seed & 0xFFFF) % 100);
            uint8 _type = 1;
            if (num == 0) _type = 3;
            else if (num < 10) _type = 2;
            beesContract.setTokenType(unrevealedTokenIndex, _type);
            emit MintRevealed(_msgSender(), unrevealedTokenIndex, _type);
            unrevealedTokenIndex++;
        }
    }

    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tx.origin, blockhash(block.number - 1), block.timestamp, seed)));
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

//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICryptoBees {
    struct Token {
        uint8 _type;
        uint32 pot;
        uint48 lastAttackTimestamp;
        uint48 cooldownTillTimestamp;
    }

    function getMinted() external view returns (uint256 m);

    function increateTokensPot(uint256 tokenId, uint32 amount) external;

    function updateTokensLastAttack(
        uint256 tokenId,
        uint48 timestamp,
        uint48 till
    ) external;

    // function mintForEth(uint256 amount, bool presale) external payable;

    // function mintForHoney(uint256 amount) external;

    // function mintForWool(uint256 amount) external;

    function withdrawERC20(
        address erc20TokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function mint(uint256 tokenId) external;

    function isWhitelisted(address who) external view returns (bool);

    function setPaused(bool _paused) external;

    function getTokenData(uint256 tokenId) external view returns (Token memory token);

    function getOwnerOf(uint256 tokenId) external view returns (address);

    function doesExist(uint256 tokenId) external view returns (bool exists);

    function setTokenType(uint256 tokenId, uint8 _type) external;

    function performTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function performSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
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