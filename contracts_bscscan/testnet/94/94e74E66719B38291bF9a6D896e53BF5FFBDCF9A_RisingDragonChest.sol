// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./interfaces/IChest.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RisingDragonChest is IChest, Ownable, ReentrancyGuard {
    string public constant chestName = "Rising Dragon Pack";
    uint256 public constant totalSupply = 300000;
    uint256 public constant totalChestCtrHolderCanBuy = 1000;
    uint256 public constant totalChestUserCanBuy = 500;

    mapping (address => bool) winnerAddr;
    mapping (address => bool) ctrHolderAddr;

    using Counters for Counters.Counter;
    Counters.Counter private _totalClaimedChestCounter;
    mapping (address => uint256) _claimedChest;

    uint256 public chestPrice;

    uint256 public startR1Timestamp;
    uint256 public endR1Timestamp;
    uint256 public startR2Timestamp;

    constructor(
        uint256 _chestPrice,
        address[] memory _winnerList,
        address[] memory _ctrHolderList,
        uint256 _startR1Timestamp,
        uint256 _endR2Timestamp,
        uint256 _startR2Timestamp
    ) {
        chestPrice = _chestPrice;
        winnerlistAddress(_winnerList);
        ctrHolderlistAddress(_ctrHolderList);
        startR1Timestamp = _startR1Timestamp;
        endR1Timestamp = _endR2Timestamp;
        startR2Timestamp = _startR2Timestamp;
    }

    function winnerlistAddress(address[] memory users) private onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            winnerAddr[users[i]] = true;
        }
    }

    function ctrHolderlistAddress(address[] memory users) private onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            ctrHolderAddr[users[i]] = true;
        }
    }

    function isInWinnerList(address users) public view returns(bool) {
        return winnerAddr[users];
    }

    function isInCtrHolderList(address users) public view returns(bool) {
        return ctrHolderAddr[users];
    }

    function setChestPrice(uint256 chestPrice_) external override onlyOwner {
        require(chestPrice_ >= 0, "Chest price must be greater than or equal to 0");
        chestPrice = chestPrice_;
    }

    function buyChest() external override payable {
        uint256 timestamp = block.timestamp;

        require(msg.value == chestPrice, "Chest price is not true");
        require(_totalClaimedChestCounter.current() < totalSupply, "Chest currently out of stock");

        if (timestamp >= startR1Timestamp && timestamp <= endR1Timestamp) {
            require(isInWinnerList(msg.sender), "Your address is not in winner list");
            require(_claimedChest[msg.sender] < totalChestCtrHolderCanBuy, "You have purchased more than the specified quantity");
        } else if (timestamp < startR2Timestamp) {
            revert("Not right time");
        } else {
            if (isInCtrHolderList(msg.sender)) {
                require(_claimedChest[msg.sender] < totalChestCtrHolderCanBuy, "You have purchased more than the specified quantity");
            } else {
                require(_claimedChest[msg.sender] < totalChestUserCanBuy, "You have purchased more than the specified quantity");
            }
        }
        
        // The cards transfer will be processed by back-end
        emit BuyAChest(chestName, msg.sender, msg.value);
        _claimedChest[msg.sender] += 1;
        _totalClaimedChestCounter.increment();
    }

    function adminWithdrawMoney() external override onlyOwner {
        address payable to = payable(owner());
        to.transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

interface IChest {
    function setChestPrice(uint256 chestPrice_) external;

    function buyChest() external payable;

    function adminWithdrawMoney() external;

    event BuyAChest(string chestName, address buyer, uint256 price);
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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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