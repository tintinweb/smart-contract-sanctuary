// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOwnable.sol";


/*
Alice and Bob want to trade ownable items

Alice put some addresses in a A list
    [aItem1Address, aItem2Address, aItem3Address]
Bob put some addresses in a B list
    [bItem1Address, bItem2Address]

*/

contract FairTrade is Ownable {
    uint256 _seed = 0;

    struct Trade {
        uint256 deadline;
        address a;
        address[] aItems;
        bool hasAConfirmed;
        address b;
        address[] bItems;
        bool hasBConfirmed;
        TradeStatus status;
    }

    enum TradeStatus{PENDING, CONFIRMED, DONE, CANCELED}

    mapping(bytes32 => Trade) _trades;

    function initTrade(address[] calldata items, uint256 deadline) public returns (bytes32){
        bytes32 tradeId = getUniqueIdentifier(msg.sender);

        address[] memory _bItems;

        Trade memory trade = Trade({
        deadline : deadline,
        a : msg.sender,
        aItems : items,
        hasAConfirmed : false,
        b : address(0),
        bItems : _bItems,
        hasBConfirmed : false,
        status : TradeStatus.PENDING
        });

        //marchera pas en l'état puisque pas owner
        //plutôt mettre une mécanique de check sous le bouton confirm pour s'assurer que tous les ownership ont bien été transmis
        /*
        for (uint i = 0; i < items.length; i++) {
            IOwnable(items[i]).transferOwnership(address(this));
        }
*/
        _trades[tradeId] = trade;

        return tradeId;
    }

    function seeTrade(bytes32 tradeId) external view returns (Trade memory){
        Trade memory trade = _trades[tradeId];
        return trade;
    }

    function joinTrade(bytes32 tradeId, address[] calldata items) public {
        Trade memory trade = _trades[tradeId];
        require(trade.a != address(0), "Bad tradeId");

        trade.b = msg.sender;
        trade.bItems = items;

        _trades[tradeId] = trade;
    }

    function confirmTrade(bytes32 tradeId) public {
        Trade memory trade = _trades[tradeId];
        checkTradeParticipant(trade, msg.sender);
        //check that all ownerShip have been transferred to this contract
        if (trade.a == msg.sender) {
            for (uint i = 0; i < trade.aItems.length; i++) {
                require(IOwnable(trade.aItems[i]).owner() == address(this), "An item ownership has not been transferred");
            }
            trade.hasAConfirmed = true;
        } else {
            for (uint i = 0; i < trade.bItems.length; i++) {
                require(IOwnable(trade.bItems[i]).owner() == address(this), "An item ownership has not been transferred");
            }
            trade.hasBConfirmed = true;
        }
        if (trade.hasAConfirmed && trade.hasBConfirmed) {
            trade.status = TradeStatus.CONFIRMED;
        }
        _trades[tradeId] = trade;
    }

    function checkTradeParticipant(Trade memory trade, address participantAddress) pure internal {
        require(trade.a == participantAddress || trade.b == participantAddress, "Participant not in this trade");
    }

    function cancelTrade(bytes32 tradeId) public {
        Trade memory trade = _trades[tradeId];
        require(!(trade.hasAConfirmed && trade.hasBConfirmed), "Trade already confirmed");

        for (uint i = 0; i < trade.aItems.length; i++) {
            IOwnable(trade.aItems[i]).transferOwnership(trade.a);
        }

        for (uint i = 0; i < trade.bItems.length; i++) {
            IOwnable(trade.bItems[i]).transferOwnership(trade.b);
        }

        trade.status = TradeStatus.CANCELED;
        _trades[tradeId] = trade;
    }

    function getUniqueIdentifier(address a) internal returns (bytes32){
        _seed++;
        return keccak256(abi.encodePacked(_seed, a));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0;

interface IOwnable{
    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
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