/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: contracts/interfaces/IXHalfLife.sol

pragma solidity 0.5.17;

interface IXHalfLife {
    function createStream(
        address token,
        address recipient,
        uint256 depositAmount,
        uint256 startBlock,
        uint256 kBlock,
        uint256 unlockRatio,
        bool cancelable
    ) external returns (uint256);

    function createEtherStream(
        address recipient,
        uint256 startBlock,
        uint256 kBlock,
        uint256 unlockRatio,
        bool cancelable
    ) external payable returns (uint256);

    function hasStream(uint256 streamId) external view returns (bool);

    function getStream(uint256 streamId)
        external
        view
        returns (
            address sender,
            address recipient,
            address token,
            uint256 depositAmount,
            uint256 startBlock,
            uint256 kBlock,
            uint256 remaining,
            uint256 withdrawable,
            uint256 unlockRatio,
            uint256 lastRewardBlock,
            bool cancelable
        );

    function balanceOf(uint256 streamId)
        external
        view
        returns (uint256 withdrawable, uint256 remaining);

    function withdrawFromStream(uint256 streamId, uint256 amount)
        external
        returns (bool);

    function cancelStream(uint256 streamId) external returns (bool);

    function singleFundStream(uint256 streamId, uint256 amount)
        external
        payable
        returns (bool);

    function lazyFundStream(
        uint256 streamId,
        uint256 amount,
        uint256 blockHeightDiff
    ) external payable returns (bool);

    function getVersion() external pure returns (bytes32);
}

// File: contracts/XdexStream.sol

pragma solidity 0.5.17;




contract XdexStream is ReentrancyGuard {
    uint256 constant ONE = 10**18;

    //The XDEX Token!
    address public xdex;
    address public xdexFarmMaster;

    /**
     * @notice An interface of XHalfLife, the contract responsible for creating, funding and withdrawing from streams.
     * No one could cancle the xdex resward stream except the recipient, because the stream sender is this contract.
     */
    IXHalfLife public halflife;

    struct LockStream {
        address depositor;
        bool isEntity;
        uint256 streamId;
    }

    //unlock ratio is 0.1% for both Voting and Normal Pool
    uint256 private constant unlockRatio = 1;

    //unlock k block for Voting Pool
    uint256 private constant unlockKBlocksV = 540;
    // key: recipient, value: Locked Stream
    mapping(address => LockStream) private votingStreams;

    //funds for Normal Pool
    uint256 private constant unlockKBlocksN = 60;
    // key: recipient, value: Locked Stream
    mapping(address => LockStream) private normalStreams;

    // non cancelable farm streams
    bool private constant cancelable = false;

    /**
     * @notice User can have at most one votingStream and one normalStream.
     * @param streamType The type of stream: 0 is votingStream, 1 is normalStream;
     */
    modifier lockStreamExists(address who, uint256 streamType) {
        bool found = false;
        if (streamType == 0) {
            //voting stream
            found = votingStreams[who].isEntity;
        } else if (streamType == 1) {
            //normal stream
            found = normalStreams[who].isEntity;
        }

        require(found, "the lock stream does not exist");
        _;
    }

    modifier validStreamType(uint256 streamType) {
        require(
            streamType == 0 || streamType == 1,
            "invalid stream type: 0 or 1"
        );
        _;
    }

    constructor(
        address _xdex,
        address _halfLife,
        address _farmMaster
    ) public {
        xdex = _xdex;
        halflife = IXHalfLife(_halfLife);
        xdexFarmMaster = _farmMaster;
    }

    /**
     * If the user has VotingStream or has NormalStream.
     */
    function hasStream(address who)
        public
        view
        returns (bool hasVotingStream, bool hasNormalStream)
    {
        hasVotingStream = votingStreams[who].isEntity;
        hasNormalStream = normalStreams[who].isEntity;
    }

    /**
     * @notice Get a user's voting or normal stream id.
     * @dev stream id must > 0.
     * @param streamType The type of stream: 0 is votingStream, 1 is normalStream;
     */
    function getStreamId(address who, uint256 streamType)
        public
        view
        lockStreamExists(who, streamType)
        returns (uint256 streamId)
    {
        if (streamType == 0) {
            return votingStreams[who].streamId;
        } else if (streamType == 1) {
            return normalStreams[who].streamId;
        }
    }

    /**
     * @notice Creates a new stream funded by `msg.sender` and paid towards to `recipient`.
     * @param streamType The type of stream: 0 is votingStream, 1 is normalStream;
     */
    function createStream(
        address recipient,
        uint256 depositAmount,
        uint256 streamType,
        uint256 startBlock
    )
        external
        nonReentrant
        validStreamType(streamType)
        returns (uint256 streamId)
    {
        require(msg.sender == xdexFarmMaster, "only farmMaster could create");
        require(recipient != address(0), "stream to the zero address");
        require(recipient != address(this), "stream to the contract itself");
        require(recipient != msg.sender, "stream to the caller");
        require(depositAmount > 0, "depositAmount is zero");
        require(startBlock >= block.number, "start block before block.number");

        if (streamType == 0) {
            require(
                !(votingStreams[recipient].isEntity),
                "voting stream exists"
            );
        }
        if (streamType == 1) {
            require(
                !(normalStreams[recipient].isEntity),
                "normal stream exists"
            );
        }

        uint256 unlockKBlocks = unlockKBlocksN;
        if (streamType == 0) {
            unlockKBlocks = unlockKBlocksV;
        }

        /* Approve the XHalflife contract to spend. */
        IERC20(xdex).approve(address(halflife), depositAmount);

        /* Transfer the tokens to this contract. */
        IERC20(xdex).transferFrom(msg.sender, address(this), depositAmount);

        streamId = halflife.createStream(
            xdex,
            recipient,
            depositAmount,
            startBlock,
            unlockKBlocks,
            unlockRatio,
            cancelable
        );

        if (streamType == 0) {
            votingStreams[recipient] = LockStream({
                depositor: msg.sender,
                isEntity: true,
                streamId: streamId
            });
        } else if (streamType == 1) {
            normalStreams[recipient] = LockStream({
                depositor: msg.sender,
                isEntity: true,
                streamId: streamId
            });
        }
    }

    /**
     * @notice Send funds to the stream
     * @param streamId The given stream id;
     * @param amount New amount fund to add;
     * @param blockHeightDiff diff of block.number and farmPool's lastRewardBlock;
     */
    function fundsToStream(
        uint256 streamId,
        uint256 amount,
        uint256 blockHeightDiff
    ) public returns (bool result) {
        require(amount > 0, "amount is zero");

        /* Approve the XHalflife contract to spend. */
        IERC20(xdex).approve(address(halflife), amount);

        /* Transfer the tokens to this contract. */
        IERC20(xdex).transferFrom(msg.sender, address(this), amount);

        result = halflife.lazyFundStream(streamId, amount, blockHeightDiff);
    }
}