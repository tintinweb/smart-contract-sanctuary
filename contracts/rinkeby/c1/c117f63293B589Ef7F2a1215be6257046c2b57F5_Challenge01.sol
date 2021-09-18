// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


interface LootCharacterInterface {
    function ownerOf(uint256 lootCharacterId) external returns (address owner);
}

interface LootCharacterGuildsInterface {
    function guildLoots(uint256 lootCharacterId) external returns (uint256 guildId);
    function guildVaults(uint256 lootCharacterId) external returns (address guildVaultAddress);
}

interface LootCharacterItemsInterface {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface LootCharacterChallengesInterface {
    function updateChallengeStatus(uint256 challengeId, uint256 lootCharacterId, bool _completed) external;
    function completed(uint256 challengeId, uint256 lootCharacterId) external returns (bool completedStatus);
}

interface AGLDInterface {
    function transfer(address recipient, uint256 amount) external;
}

contract Challenge01 is Ownable, Pausable {
    bytes32 public keyHashed = keccak256(abi.encodePacked(keccak256(abi.encodePacked("andrew"))));
    bool public open1 = false;
    bool public open2 = false;
    bool public open3 = false;
    bool public open4 = false;
    bool public open5 = false;
    bool public open6 = false;
    bool public open7 = false;
    bool public open8 = false;
    LootCharacterInterface private lootCharacterContract;
    LootCharacterGuildsInterface private lootCharacterGuildsContract;
    LootCharacterItemsInterface lootCharacterItemsContract;
    LootCharacterChallengesInterface private lootCharacterChallengesContract;
    AGLDInterface private agldContract;

    modifier isLootOwner(uint256 lootCharacterId) {
        require(msg.sender == lootCharacterContract.ownerOf(lootCharacterId), "Sender does not own Loot Character");
        _;
    }

    modifier isGuilded(uint256 lootCharacterId) {
        require(lootCharacterGuildsContract.guildLoots(lootCharacterId) != 0, "Loot is not Guilded");
        _;
    }

    modifier hasNotCompletedChallenge(uint256 lootCharacterId) {
        require(!lootCharacterChallengesContract.completed(1, lootCharacterId), "Already completed this challenge");
        _;
    }
    
    constructor(address lootCharacterContractAddress, address lootCharacterGuildsContractAddress, address lootCharacterItemsContractAddress, address lootCharacterChallengesContractAddress, address agldContractAddress) {
        lootCharacterContract = LootCharacterInterface(lootCharacterContractAddress);
        lootCharacterGuildsContract = LootCharacterGuildsInterface(lootCharacterGuildsContractAddress);
        lootCharacterItemsContract = LootCharacterItemsInterface(lootCharacterItemsContractAddress);
        lootCharacterChallengesContract = LootCharacterChallengesInterface(lootCharacterChallengesContractAddress);
        agldContract = AGLDInterface(agldContractAddress); 
    }

    function openChest(bytes32 key, uint256 lootCharacterId) external isLootOwner(lootCharacterId) isGuilded(lootCharacterId) hasNotCompletedChallenge(lootCharacterId) {
        if(!open1) {
            require(keccak256(abi.encodePacked(key)) == keyHashed, "You are not worthy.");
            agldContract.transfer(msg.sender, 500);
            lootCharacterItemsContract.transferFrom(address(this), msg.sender, 1);
            (bool sent, bytes memory data) = payable(msg.sender).call{value: address(this).balance / 3 }("");
            require(sent, "Failed to send ETH to chest opener");
            (sent, data) = payable(lootCharacterGuildsContract.guildVaults(lootCharacterGuildsContract.guildLoots(lootCharacterId))).call{value: address(this).balance}("");
            require(sent, "Failed to send ETH to guild");
            open1 = true;
        } else if(!open2) {
            lootCharacterItemsContract.transferFrom(address(this), msg.sender, 2);
            open2 = true;
        } else if(!open3) {
            lootCharacterItemsContract.transferFrom(address(this), msg.sender, 3);
            open3 = true;
        } else if(!open4) {
            lootCharacterItemsContract.transferFrom(address(this), msg.sender, 4);
            open4 = true;
        } else if(!open5) {
            lootCharacterItemsContract.transferFrom(address(this), msg.sender, 5);
            open5 = true;
        } else if(!open6) {
            lootCharacterItemsContract.transferFrom(address(this), msg.sender, 6);
            open6 = true;
        } else if(!open7) {
            lootCharacterItemsContract.transferFrom(address(this), msg.sender, 7);
            open7 = true;
        } else if(!open8) {
            lootCharacterItemsContract.transferFrom(address(this), msg.sender, 8);
            open8 = true;
        }

        // Nothing to claim, but this loot character solved the challenge
        lootCharacterChallengesContract.updateChallengeStatus(1, lootCharacterId, true);
    }

    function returnAGLD(address to, uint256 amt) external onlyOwner {
        agldContract.transfer(to, amt);
    }

    function returnETH(address payable to) external onlyOwner {
        (bool sent, bytes memory data) = to.call{value: address(this).balance}("");
        require(sent, "Failed to send ETH to \"to\" address");
    }

    function returnLootCharacterItem(address to, uint256 itemId) external onlyOwner {
        lootCharacterItemsContract.transferFrom(address(this), to, itemId);       
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

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
 * @dev String operations.
 */
library Strings {
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}