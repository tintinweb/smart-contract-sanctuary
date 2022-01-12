// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time, max-states-count

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interfaces/ICollab.sol";
import "./libraries/SignatureDecoder.sol";

contract MetaCollab is ICollab, Initializable, Context, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public giver;
    address public doer;

    enum Status {
        init,
        active,
        countdown,
        locked,
        resolved,
        cancelled,
        expired,
        done
    }

    struct Gig {
        Status status;
        address[] tokens;
        uint256[] amounts;
        uint256 startTimestamp;
        uint256 countdownTimestamp;
        uint256 endTimestamp;
        uint256[3] durations; // [cancellationDuration, countdownDuration, expirationDuration]
        address resolver;
        uint256 fixedResolverFee;
        uint8[2] resolverFeeRatio;
    }

    event GigInit(uint256 indexed gigId, bytes hash);
    event GigActive(uint256 indexed gigId);
    event GigHashUpdated(uint256 indexed gigId, bytes hash);
    event GigResolverUpdated(uint256 indexed gigId);
    event GigLockCountdownStarted(uint256 indexed gigId);
    event GigLockedForDispute(uint256 indexed gigId);
    event GigCancelled(uint256 indexed gigId);
    event GigExpired(uint256 indexed gigId);
    event GigDone(uint256 indexed gigId, uint8 giverShare, uint8 doerShare);
    event GigResolved(uint256 indexed gigId, uint8 giverShare, uint8 doerShare);

    mapping(uint256 => Gig) public gigs;
    uint256 public gigCount;

    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    function init(address _giver, address _doer) external override initializer {
        require(_giver != address(0), "invalid giver");
        require(_doer != address(0), "invalid doer");

        giver = _giver;
        doer = _doer;
    }

    modifier verified(bytes calldata _data, bytes calldata _signatures) {
        SignatureDecoder.verifySignatures(_data, _signatures, giver, doer);
        _;
    }

    modifier onlyGiver() {
        require(_msgSender() == giver, "only giver");
        _;
    }

    modifier onlyParty() {
        require(_msgSender() == giver || _msgSender() == doer, "only party");
        _;
    }

    modifier onlyResolver(uint256 _gigId) {
        Gig storage gig = gigs[_gigId];
        require(_msgSender() == gig.resolver, "only resolver");
        _;
    }

    function _newGig(
        bytes memory _hash,
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256[3] memory _durations,
        address _resolver
    ) internal {
        Gig storage gig = gigs[gigCount];
        gig.status = Status.init;
        gig.tokens = _tokens;
        gig.amounts = _amounts;
        gig.startTimestamp = block.timestamp;
        require(_durations[2] > 0, "invalid expiration duration");
        gig.durations = _durations;

        if (_resolver != address(0)) {
            gig.resolver = _resolver;
            // TODO: init resolver fees
        }

        emit GigInit(gigCount, _hash);
        gigCount++;
    }

    function createNewGig(bytes calldata _data, bytes calldata _signatures)
        external
        override
        nonReentrant
        verified(_data, _signatures)
    {
        (
            bytes memory _hash,
            address[] memory _tokens,
            uint256[] memory _amounts,
            uint256[3] memory _durations,
            address _resolver,
            address _collab,
            uint256 _gigCount
        ) = abi.decode(
                _data,
                (
                    bytes,
                    address[],
                    uint256[],
                    uint256[3],
                    address,
                    address,
                    uint256
                )
            );
        require(
            _gigCount == gigCount &&
                _collab == address(this) &&
                _tokens.length == _amounts.length,
            "invalid data"
        );

        _newGig(_hash, _tokens, _amounts, _durations, _resolver);
    }

    function startNewGig(bytes calldata _data, bytes calldata _signatures)
        external
        override
        nonReentrant
        verified(_data, _signatures)
    {
        (
            bytes memory _hash,
            address[] memory _tokens,
            uint256[] memory _amounts,
            uint256[3] memory _durations,
            address _resolver,
            address _collab,
            uint256 _gigCount
        ) = abi.decode(
                _data,
                (
                    bytes,
                    address[],
                    uint256[],
                    uint256[3],
                    address,
                    address,
                    uint256
                )
            );
        require(
            _gigCount == gigCount &&
                _collab == address(this) &&
                _tokens.length == _amounts.length,
            "invalid data"
        );
        _newGig(_hash, _tokens, _amounts, _durations, _resolver);
        _startGig(_gigCount);
    }

    function _startGig(uint256 _gigId) internal {
        Gig storage gig = gigs[_gigId];
        require(gig.status == Status.init, "invalid gig");
        for (uint256 i = 0; i < gig.tokens.length; i = i + 1) {
            IERC20 token = IERC20(gig.tokens[i]);
            token.safeTransferFrom(giver, address(this), gig.amounts[i]);
        }
        gig.status = Status.active;

        emit GigActive(_gigId);
    }

    function startGig(bytes calldata _data, bytes calldata _signatures)
        external
        override
        nonReentrant
        verified(_data, _signatures)
    {
        (address _collab, uint256 _gigId) = abi.decode(
            _data,
            (address, uint256)
        );
        require(_collab == address(this), "invalid data");

        _startGig(_gigId);
    }

    function _distributeGigRewards(
        uint256 _gigId,
        uint8 _giverShare,
        uint8 _doerShare
    ) internal {
        uint8 denom = _giverShare + _doerShare;
        require(denom != 0, "invalid distribution");
        Gig storage gig = gigs[_gigId];

        for (uint256 i = 0; i < gig.tokens.length; i = i + 1) {
            uint256 giverReward = (gig.amounts[i] * _giverShare) / denom;
            uint256 doerReward = gig.amounts[i] - giverReward;
            IERC20 token = IERC20(gig.tokens[i]);
            if (giverReward > 0) {
                token.safeTransferFrom(address(this), giver, giverReward);
            }
            if (doerReward > 0) {
                token.safeTransferFrom(address(this), doer, doerReward);
            }
        }
    }

    function cancelGig(uint256 _gigId)
        external
        override
        nonReentrant
        onlyGiver
    {
        Gig storage gig = gigs[_gigId];
        require(gig.status == Status.active, "invalid gig");
        uint256 timeElapsed = block.timestamp - gig.startTimestamp;

        if (timeElapsed < gig.durations[0]) {
            gig.status = Status.cancelled;
            _distributeGigRewards(_gigId, 1, 0);
            emit GigCancelled(_gigId);
        } else if (timeElapsed > gig.durations[2]) {
            gig.status = Status.expired;
            _distributeGigRewards(_gigId, 1, 0);
            emit GigExpired(_gigId);
        } else {
            revert("invalid timestamp");
        }
    }

    function lockGig(uint256 _gigId)
        external
        payable
        override
        nonReentrant
        onlyParty
    {
        Gig storage gig = gigs[_gigId];
        require(gig.resolver != address(0), "invalid resolver");
        if (gig.status == Status.active) {
            gig.status = Status.countdown;
            gig.countdownTimestamp = block.timestamp;
            emit GigLockCountdownStarted(_gigId);
        } else if (gig.status == Status.countdown) {
            uint256 timeElapsed = block.timestamp - gig.countdownTimestamp;
            require(timeElapsed >= gig.durations[0], "still counting");
            require(msg.value == gig.fixedResolverFee, "invalid value");
            if (gig.fixedResolverFee > 0) {
                payable(gig.resolver).transfer(gig.fixedResolverFee);
            }
            gig.status = Status.locked;
            emit GigLockedForDispute(_gigId);
        } else {
            revert("invalid gig");
        }
    }

    function completeGig(bytes calldata _data, bytes calldata _signatures)
        external
        override
        nonReentrant
        verified(_data, _signatures)
    {
        (
            address _collab,
            uint256 _gigId,
            uint8 _giverShare,
            uint8 _doerShare
        ) = abi.decode(_data, (address, uint256, uint8, uint8));
        require(_collab == address(this), "invalid data");
        Gig storage gig = gigs[_gigId];
        require(
            gig.status == Status.active || gig.status == Status.countdown,
            "invalid gig"
        );
        gig.status = Status.done;
        _distributeGigRewards(_gigId, _giverShare, _doerShare);
        emit GigDone(_gigId, _giverShare, _doerShare);
    }

    function _resolveGigRewards(
        uint256 _gigId,
        uint8 _giverShare,
        uint8 _doerShare
    ) internal {
        Gig storage gig = gigs[_gigId];
        require(gig.status == Status.locked, "invalid gig");
        uint8 denom = _giverShare + _doerShare;
        uint8 feeDenom = gig.resolverFeeRatio[0] + gig.resolverFeeRatio[1];
        require(denom != 0 && feeDenom != 0, "invalid distribution");

        for (uint256 i = 0; i < gig.tokens.length; i = i + 1) {
            uint256 resolverReward = (gig.amounts[i] *
                gig.resolverFeeRatio[0]) / feeDenom;
            uint256 partyReward = gig.amounts[i] - resolverReward;
            uint256 giverReward = (partyReward * _giverShare) / denom;
            uint256 doerReward = partyReward - giverReward;
            IERC20 token = IERC20(gig.tokens[i]);
            if (resolverReward > 0) {
                token.safeTransferFrom(
                    address(this),
                    gig.resolver,
                    resolverReward
                );
            }
            if (giverReward > 0) {
                token.safeTransferFrom(address(this), giver, giverReward);
            }
            if (doerReward > 0) {
                token.safeTransferFrom(address(this), doer, doerReward);
            }
        }
        gig.status = Status.resolved;
    }

    function resolveGig(
        uint256 _gigId,
        uint8 _giverShare,
        uint8 _doerShare
    ) external override nonReentrant onlyResolver(_gigId) {
        _resolveGigRewards(_gigId, _giverShare, _doerShare);
        emit GigResolved(_gigId, _giverShare, _doerShare);
    }

    function updateGigHash(bytes calldata _data, bytes calldata _signatures)
        external
        override
        nonReentrant
        verified(_data, _signatures)
    {
        (address _collab, uint256 _gigId, bytes memory _hash) = abi.decode(
            _data,
            (address, uint256, bytes)
        );
        require(_collab == address(this), "invalid data");
        Gig storage gig = gigs[_gigId];
        require(
            gig.status == Status.active || gig.status == Status.init,
            "invalid gig"
        );
        emit GigHashUpdated(_gigId, _hash);
    }

    function updateGigResolver(bytes calldata _data, bytes calldata _signatures)
        external
        override
        nonReentrant
        verified(_data, _signatures)
    {
        (address _collab, uint256 _gigId, address _resolver) = abi.decode(
            _data,
            (address, uint256, address)
        );
        require(
            _collab == address(this) && _resolver != address(0),
            "invalid data"
        );
        Gig storage gig = gigs[_gigId];
        require(
            gig.status == Status.active || gig.status == Status.init,
            "invalid gig"
        );
        gig.resolver = _resolver;
        // TODO: init resolver fees
        emit GigResolverUpdated(_gigId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface ICollab {
    function init(address _giver, address _doer) external;

    function createNewGig(bytes calldata _data, bytes calldata _signatures)
        external;

    function startNewGig(bytes calldata _data, bytes calldata _signatures)
        external;

    function startGig(bytes calldata _data, bytes calldata _signatures)
        external;

    function cancelGig(uint256 _gigId) external;

    function completeGig(bytes calldata _data, bytes calldata _signatures)
        external;

    function lockGig(uint256 _gigId) external payable;

    function resolveGig(
        uint256 _gigId,
        uint8 _giverShare,
        uint8 _doerShare
    ) external;

    function updateGigHash(bytes calldata _data, bytes calldata _signatures)
        external;

    function updateGigResolver(bytes calldata _data, bytes calldata _signatures)
        external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes

library SignatureDecoder {
    /// @dev Recovers address who signed the message
    /// @param messageHash keccak256 hash of message
    /// @param messageSignatures concatenated message signatures
    /// @param pos which signature to read
    function recoverKey(
        bytes32 messageHash,
        bytes calldata messageSignatures,
        uint256 pos
    ) internal pure returns (address) {
        if (messageSignatures.length % 65 != 0) {
            return (address(0));
        }

        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = signatureSplit(messageSignatures, pos);

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(toEthSignedMessageHash(messageHash), v, r, s);
        }
    }

    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := byte(0, mload(add(signatures, add(signaturePos, 0x60))))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
    }

    function recoverAddresses(bytes calldata _data, bytes calldata _signatures)
        public
        pure
        returns (address[2] memory _recoveredArray)
    {
        bytes32 _hash = keccak256(_data);
        for (uint256 i = 0; i < 2; i++) {
            _recoveredArray[i] = recoverKey(_hash, _signatures, i);
        }
    }

    function verifySignatures(
        bytes calldata _data,
        bytes calldata _signatures,
        address _a,
        address _b
    ) public pure {
        address[2] memory signers = recoverAddresses(_data, _signatures);
        require(
            (signers[0] == _a && signers[1] == _b) ||
                (signers[0] == _b && signers[1] == _a),
            "invalid signature"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}