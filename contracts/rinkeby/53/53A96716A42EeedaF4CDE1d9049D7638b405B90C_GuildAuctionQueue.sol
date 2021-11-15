// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
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

    constructor () {
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMOLOCH.sol";
import "./interfaces/IMinion.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract GuildAuctionQueue is ReentrancyGuard, Initializable {
    IERC20 public token;
    address public owner; // typically a dao's minion
    address public destination; // where tokens go when bids are accepted
    uint256 public lockupPeriod; // period for which bids are locked and cannot be withdrawn, in seconds
    uint256 public minBid; // adjustable by the owner

    uint256 public membersCanAccept; // whether moloch members can accept bids individually, or if the owner must do so (eg with a minion proposal)
    uint256 public minShares; // the number of moloch shares a member must have to be eligible to accept a bid; only set if memberCanAccept == 1

    uint256 public newBidId; // the id of the next bid to be submitted; starts at 0

    // -- Data Models --

    mapping(uint256 => Bid) public bids;

    enum BidStatus {queued, accepted, cancelled}

    struct Bid {
        uint256 amount;
        address submitter;
        uint256 createdAt; // block.timestamp from tx when bid was created
        BidStatus status;
    }

    // -- Functions --

    function init(
        address _owner,
        address _token,
        address _destination,
        uint256 _lockupPeriod,
        uint256 _minBid,
        uint256 _minShares
    ) external initializer {
        require(_token != address(0), "invalid token");
        require(_destination != address(0), "invalid destination");

        if (_minShares > 0) {
            minShares = _minShares;
            membersCanAccept = 1;
        }
        // else: solidity uints default to 0 so no need to explicitly set minShares or membersCanAccept to 0

        token = IERC20(_token);
        destination = _destination;
        lockupPeriod = _lockupPeriod;
        minBid = _minBid;
        owner = _owner;
    }

    function submitBid(uint256 _amount, bytes32 _details)
        external
        nonReentrant
        returns (uint256)
    {
        require(_amount >= minBid, "bid too low");

        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "token transfer failed"
        );

        Bid storage bid = bids[newBidId];

        bid.amount = _amount;
        bid.submitter = msg.sender;
        bid.status = BidStatus.queued;

        bid.createdAt = block.timestamp;
        uint256 id = newBidId;
        newBidId++;

        emit NewBid(_amount, msg.sender, id, _details);

        return id;
    }

    function increaseBid(uint256 _amount, uint256 _id) external nonReentrant {
        require(_id < newBidId, "invalid bid");
        Bid storage bid = bids[_id];
        require(bid.status == BidStatus.queued, "bid inactive");

        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "token transfer failed"
        );

        bid.amount += _amount;

        emit BidIncreased(bid.amount, _id);
    }

    function withdrawBid(uint256 _amount, uint32 _id) external nonReentrant {
        require(_id < newBidId, "invalid bid");
        Bid storage bid = bids[_id];
        require(bid.status == BidStatus.queued, "bid inactive");

        require(bid.submitter == msg.sender, "!submitter");
        require(bid.amount - _amount >= minBid, "remaining bid too low");

        require(
            (bid.createdAt + lockupPeriod) < block.timestamp,
            "lockupPeriod not over"
        );

        bid.amount -= _amount; // reverts on underflow

        require(token.transfer(msg.sender, _amount), "token transfer failed");

        emit BidWithdrawn(bid.amount, _id);
    }

    function cancelBid(uint256 _id) external nonReentrant {
        require(_id < newBidId, "invalid bid");
        Bid storage bid = bids[_id];
        require(bid.status == BidStatus.queued, "bid inactive");

        require(bid.submitter == msg.sender, "!submitter");

        require(
            (bid.createdAt + lockupPeriod) < block.timestamp,
            "lockupPeriod not over"
        );

        bid.status = BidStatus.cancelled;

        require(token.transfer(msg.sender, bid.amount));

        emit BidCanceled(_id);
    }

    function acceptBid(uint256 _id) external accepterOnly nonReentrant {
        require(_id < newBidId, "invalid bid");
        Bid storage bid = bids[_id];
        require(bid.status == BidStatus.queued, "bid inactive");

        bid.status = BidStatus.accepted;

        require(token.transfer(destination, bid.amount));

        emit BidAccepted(msg.sender, _id);
    }

    function changeMinBid(uint256 _newMin) external nonReentrant {
        require(msg.sender == owner, "!owner");

        minBid = _newMin;

        emit MinBidChanged(_newMin);
    }

    // -- Helper Functions --

    function isMember(address user) public view returns (bool) {
        // if owner is a minion, fetch its moloch parent
        IMinion maybeMinion = IMinion(owner);
        address molochAddress = maybeMinion.moloch(); // reverts if owner doesn't have a moloch getter

        IMOLOCH moloch = IMOLOCH(molochAddress);
        address member = moloch.memberAddressByDelegateKey(user);
        (, uint256 shares, , , , ) = moloch.members(member);
        return shares >= minShares;
    }

    // -- Modifiers --
    modifier accepterOnly() {
        if (membersCanAccept == 1) {
            require(isMember(msg.sender), "!full moloch member");
        } else {
            require(msg.sender == owner, "!owner");
        }

        _;
    }

    // -- Events --

    event NewBid(
        uint256 amount,
        address submitter,
        uint256 id,
        bytes32 details
    );
    event BidIncreased(uint256 newAmount, uint256 id);
    event BidWithdrawn(uint256 newAmount, uint256 id);
    event BidCanceled(uint256 id);
    event BidAccepted(address acceptedBy, uint256 id);
    event MinBidChanged(uint256 newMinBid);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMOLOCH {
    // brief interface for moloch dao v2

    function depositToken() external view returns (address);

    function tokenWhitelist(address token) external view returns (bool);

    function getProposalFlags(uint256 proposalId)
        external
        view
        returns (bool[6] memory);

    function members(address user)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        );

    function memberAddressByDelegateKey(address user)
        external
        view
        returns (address);

    function userTokenBalances(address user, address token)
        external
        view
        returns (uint256);

    function cancelProposal(uint256 proposalId) external;

    function submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        string calldata details
    ) external returns (uint256);

    function withdrawBalance(address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMinion {
    function moloch() external view returns (address);
}

