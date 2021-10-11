// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

/*
   ▄████████  ▄█     █▄   ▄██████▄     ▄████████ ████████▄     ▄████████ 
  ███    ███ ███     ███ ███    ███   ███    ███ ███   ▀███   ███    ███ 
  ███    █▀  ███     ███ ███    ███   ███    ███ ███    ███   ███    █▀  
  ███        ███     ███ ███    ███  ▄███▄▄▄▄██▀ ███    ███   ███        
▀███████████ ███     ███ ███    ███ ▀▀███▀▀▀▀▀   ███    ███ ▀███████████ 
         ███ ███     ███ ███    ███ ▀███████████ ███    ███          ███ 
   ▄█    ███ ███ ▄█▄ ███ ███    ███   ███    ███ ███   ▄███    ▄█    ███ 
 ▄████████▀   ▀███▀███▀   ▀██████▀    ███    ███ ████████▀   ▄████████▀  
                                      ███    ███                         

                       GIMMIX ENTERTAINMENT MMXXI
*/

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISwordsMarket} from "./interfaces/ISwordsMarket.sol";
import {ISwordsEvent} from "./interfaces/ISwordsEvent.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC2981Royalties {
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

contract SwordsMarket is ISwordsMarket, Ownable {
    mapping(address => uint256) public eventRegistry;
    mapping(uint256 => address) public eventContracts;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        private _eventTokenBidders;
    mapping(uint256 => mapping(uint256 => uint256)) private _eventTokenAsks;
    mapping(uint256 => mapping(uint256 => bool)) private _eventTokenAskExists;

    modifier onlyEventCaller() {
        require(eventRegistry[msg.sender] != 0, "only event contract");
        _;
    }

    function bidForEventTokenBidder(
        uint256 eventId,
        uint256 tokenId,
        address bidder
    ) external view returns (uint256) {
        return _eventTokenBidders[eventId][tokenId][bidder];
    }

    function currentAskForEventToken(uint256 eventId, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return _eventTokenAsks[eventId][tokenId];
    }

    function isValidBid(uint256 bidAmount) public pure returns (bool) {
        return bidAmount != 0;
    }

    function splitShare(uint256 sharePercentage, uint256 amount)
        public
        pure
        returns (uint256)
    {
        return (amount * sharePercentage) / 100;
    }

    function registerEvent(uint256 eventId, address eventAddress)
        external
        onlyOwner
    {
        require(
            eventContracts[eventId] == address(0),
            "event already configured"
        );
        require(
            eventRegistry[eventAddress] == 0,
            "contract already used in another event"
        );
        eventContracts[eventId] = eventAddress;
        eventRegistry[eventAddress] = eventId;
    }

    function setAsk(
        uint256 eventId,
        uint256 tokenId,
        uint256 askAmount
    ) public onlyEventCaller {
        require(isValidBid(askAmount), "SwordsMarket: Ask invalid");
        _eventTokenAsks[eventId][tokenId] = askAmount;
        _eventTokenAskExists[eventId][tokenId] = true;
        emit AskCreated(eventId, tokenId, askAmount);
    }

    function removeAsk(uint256 eventId, uint256 tokenId)
        external
        onlyEventCaller
    {
        delete _eventTokenAsks[eventId][tokenId];
        _eventTokenAskExists[eventId][tokenId] = false;
        emit AskRemoved(eventId, tokenId, _eventTokenAsks[eventId][tokenId]);
    }

    /**
     * @notice Sets the bid on a particular media for a bidder. The token being used to bid
     * is transferred from the spender to this contract to be held until removed or accepted.
     * If another bid already exists for the bidder, it is refunded.
     */
    function setBid(
        uint256 eventId,
        uint256 tokenId,
        uint256 bidAmount,
        address bidder
    ) public payable onlyEventCaller {
        require(bidder != address(0), "bidder cannot be 0 address");
        require(bidAmount != 0, "cannot bid amount of 0");
        require(msg.value == bidAmount, "bid amount must match msg value");

        uint256 existingBidAmount = _eventTokenBidders[eventId][tokenId][
            bidder
        ];

        // If there is an existing bid from this bidder, refund it before continuing
        if (existingBidAmount > 0) {
            removeBid(eventId, tokenId, bidder);
        }

        _eventTokenBidders[eventId][tokenId][bidder] = bidAmount;
        emit BidCreated(eventId, tokenId, bidAmount, bidder);

        // If a bid meets the criteria for an ask, automatically accept the bid.
        // If no ask is set or the bid does not meet the requirements, ignore.
        if (
            _eventTokenAskExists[eventId][tokenId] == true &&
            bidAmount >= _eventTokenAsks[eventId][tokenId]
        ) {
            // Finalize exchange
            _finalizeNFTTransfer(eventId, tokenId, bidder);
        }
    }

    /**
     * @notice Removes the bid on a particular media for a bidder. The bid amount
     * is transferred from this contract to the bidder, if they have a bid placed.
     */
    function removeBid(
        uint256 eventId,
        uint256 tokenId,
        address bidder
    ) public onlyEventCaller {
        uint256 bidAmount = _eventTokenBidders[eventId][tokenId][bidder];

        require(bidAmount > 0, "cannot remove bid amount of 0");
        payable(bidder).call{value: bidAmount}("");

        emit BidRemoved(eventId, tokenId, bidAmount, bidder);
        delete _eventTokenBidders[eventId][tokenId][bidder];
    }

    /**
     * @notice Accepts a bid from a particular bidder. Can only be called by the media contract.
     * See {_finalizeNFTTransfer}
     * Provided bid must match a bid in storage. This is to prevent a race condition
     * where a bid may change while the acceptBid call is in transit.
     * A bid cannot be accepted if it cannot be split equally into its shareholders.
     * This should only revert in rare instances (example, a low bid with a zero-decimal token),
     * but is necessary to ensure fairness to all shareholders.
     */
    function acceptBid(
        uint256 eventId,
        uint256 tokenId,
        uint256 expectedBidAmount,
        address expectedBidBidder
    ) external onlyEventCaller {
        uint256 bidAmount = _eventTokenBidders[eventId][tokenId][
            expectedBidBidder
        ];
        require(bidAmount > 0, "cannot accept bid of 0");
        require(bidAmount == expectedBidAmount, "unexpected bid found.");

        _finalizeNFTTransfer(eventId, tokenId, expectedBidBidder);
    }

    /**
     * @notice Given a token ID and a bidder, this method transfers the value of
     * the bid to the shareholders. It also transfers the ownership of the media
     * to the bid recipient. Finally, it removes the accepted bid and the current ask.
     */
    function _finalizeNFTTransfer(
        uint256 eventId,
        uint256 tokenId,
        address bidder
    ) private {
        uint256 bidAmount = _eventTokenBidders[eventId][tokenId][bidder];
        ISwordsEvent swordsContract = ISwordsEvent(eventContracts[eventId]);

        (address eventBank, uint256 amount) = IERC2981Royalties(
            eventContracts[eventId]
        ).royaltyInfo(tokenId, bidAmount);

        // Transfer royalty share to event bank address
        payable(eventBank).call{value: amount}("");

        // Transfer remainder to current owner
        payable(IERC721(eventContracts[eventId]).ownerOf(tokenId)).call{
            value: bidAmount - amount
        }("");

        // Transfer media to bidder
        swordsContract.exchangeTransfer(tokenId, bidder);

        // Remove the accepted bid
        delete _eventTokenBidders[eventId][tokenId][bidder];

        emit BidFinalized(eventId, tokenId, bidAmount, bidder);
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

interface ISwordsMarket {
    event BidCreated(
        uint256 indexed eventId,
        uint256 indexed tokenId,
        uint256 amount,
        address bidder
    );
    event BidRemoved(
        uint256 indexed eventId,
        uint256 indexed tokenId,
        uint256 amount,
        address bidder
    );
    event BidFinalized(
        uint256 indexed eventId,
        uint256 indexed tokenId,
        uint256 amount,
        address bidder
    );
    event AskCreated(
        uint256 indexed eventId,
        uint256 indexed tokenId,
        uint256 amount
    );
    event AskRemoved(
        uint256 indexed eventId,
        uint256 indexed tokenId,
        uint256 amount
    );

    function bidForEventTokenBidder(
        uint256 eventId,
        uint256 tokenId,
        address bidder
    ) external view returns (uint256);

    function currentAskForEventToken(uint256 eventId, uint256 tokenId)
        external
        view
        returns (uint256);

    function isValidBid(uint256 bidAmount) external view returns (bool);

    function splitShare(uint256 sharePercentage, uint256 amount)
        external
        pure
        returns (uint256);

    function registerEvent(uint256 eventId, address eventAddress) external;

    function setAsk(
        uint256 eventId,
        uint256 tokenId,
        uint256 amount
    ) external;

    function removeAsk(uint256 eventId, uint256 tokenId) external;

    function setBid(
        uint256 eventId,
        uint256 tokenId,
        uint256 amount,
        address bidder
    ) external payable;

    function removeBid(
        uint256 eventId,
        uint256 tokenId,
        address bidder
    ) external;

    function acceptBid(
        uint256 eventId,
        uint256 tokenId,
        uint256 amount,
        address bidder
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import {ISwordsMarket} from "./ISwordsMarket.sol";

interface ISwordsEvent {
    // * MODELS * //
    enum EventState {
        INITIALIZED,
        ACTIVE,
        FINISHED
    }

    // * EVENTS * //
    event EventStateChanged(EventState state, uint256 moveNumber);
    event MoveMade(bytes8 move, uint256 moveNumber);
    event PieceDestroyed(
        uint256 tokenId,
        uint256 destroyedBy,
        uint256 moveNumber
    );
    event EventFinished(uint8 endState);
    event PrizeClaimed(uint256 tokenId);

    // * CONSTRUCTORS *  //
    function mint(uint256 tokenId) external payable;

    // * PRODUCER FUNCTIONS * //
    function startEvent() external;

    function submitMove(bytes8 move) external;

    function submitMoveAndDestroy(
        bytes8 move,
        uint256 tokenId,
        uint256 destroyedBy
    ) external;

    // * WINNER FUNCTIONS * //
    function claimPrize() external;

    // * MARKETPLACE * //
    function setAsk(uint256 tokenId, uint256 amount) external;

    function removeAsk(uint256 tokenId) external;

    function setBid(uint256 tokenId, uint256 amount) external payable;

    function removeBid(uint256 tokenId) external;

    function acceptBid(
        uint256 tokenId,
        uint256 amount,
        address bidder
    ) external;

    function exchangeTransfer(uint256 tokenId, address recipient) external;

    function revokeApproval(uint256 tokenId) external;
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