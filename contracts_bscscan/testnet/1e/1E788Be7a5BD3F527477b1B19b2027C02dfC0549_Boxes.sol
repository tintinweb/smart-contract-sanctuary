// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Boxes is ReentrancyGuard {

    using Counters for Counters.Counter;
    Counters.Counter public _itemIds;
    Counters.Counter public _standard;
    Counters.Counter public _deluxe;
    address payable private _wallet;
    uint public priceStandard = 0.096 ether;
    uint public priceDeluxe = 0.24 ether;
    uint public priceStandardDisc = 0.088 ether;
    uint public priceDeluxeDisc = 0.216 ether;

    struct BoxItem {
        uint itemId;
        address buyer;
        uint256 price;
        uint box;
    }

    struct BoxDetail {
        uint standard;
        uint deluxe;
    }

    mapping(uint256 => BoxItem) public itemsBox;
    mapping(address => BoxDetail) private boxes;

    event BoxItemCreated (
        uint indexed itemId,
        address buyer,
        uint256 price,
        uint box
    );

    constructor (address payable wallet) {
        _wallet = wallet;
    }

    function buyStandard() public payable nonReentrant {
        require(msg.value == priceStandard, "Amount not enough");
        _wallet.transfer(msg.value);
        _itemIds.increment();
        _standard.increment();
        uint256 itemId = _itemIds.current();

        itemsBox[itemId] = BoxItem(
            itemId,
            msg.sender,
            msg.value,
            1
        );

        boxes[msg.sender].standard += 1;

        emit BoxItemCreated(
            itemId,
            msg.sender,
            msg.value,
            1
        );
    }

    function buyStandardDiscount() public payable nonReentrant {
        require(msg.value == priceStandardDisc, "Amount not enough");
        _wallet.transfer(msg.value);
        _itemIds.increment();
        _standard.increment();
        uint256 itemId = _itemIds.current();

        itemsBox[itemId] = BoxItem(
            itemId,
            msg.sender,
            msg.value,
            1
        );

        boxes[msg.sender].standard += 1;

        emit BoxItemCreated(
            itemId,
            msg.sender,
            msg.value,
            1
        );
    }

    function buyDeluxe() public payable nonReentrant {
        require(msg.value == priceDeluxe, "Amount not enough");
        _wallet.transfer(msg.value);
        _itemIds.increment();
        _deluxe.increment();
        uint256 itemId = _itemIds.current();

        itemsBox[itemId] = BoxItem(
            itemId,
            msg.sender,
            msg.value,
            2
        );

        boxes[msg.sender].deluxe += 1;

        emit BoxItemCreated(
            itemId,
            msg.sender,
            msg.value,
            2
        );
    }

    function buyDeluxeDiscount() public payable nonReentrant {
        require(msg.value == priceDeluxeDisc, "Amount not enough");
        _wallet.transfer(msg.value);
        _itemIds.increment();
        _deluxe.increment();
        uint256 itemId = _itemIds.current();

        itemsBox[itemId] = BoxItem(
            itemId,
            msg.sender,
            msg.value,
            2
        );

        boxes[msg.sender].deluxe += 1;

        emit BoxItemCreated(
            itemId,
            msg.sender,
            msg.value,
            2
        );
    }

    function boxByWallet(address user) public view returns (BoxDetail memory){
        require(user != address(0), "Address user is zero");
        return boxes[user];
    }

    function building(uint boxType) public {
        if (boxType == 1) {
            boxes[msg.sender].standard -= 1;
        } else {
            boxes[msg.sender].deluxe -= 1;
        }
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