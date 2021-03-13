/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

// File: contracts/lib/AddressHelper.sol

pragma solidity 0.5.17;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library AddressHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferEther(address to, uint256 value) internal {
        (bool success, ) = to.call.value(value)(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    function isContract(address token) internal view returns (bool) {
        if (token == address(0x0)) {
            return false;
        }
        uint256 size;
        assembly {
            size := extcodesize(token)
        }
        return size > 0;
    }

    /**
     * @dev returns the address used within the protocol to identify ETH
     * @return the address assigned to ETH
     */
    function ethAddress() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

// File: contracts/lib/XNum.sol

pragma solidity 0.5.17;

library XNum {
    uint256 public constant BONE = 10**18;
    uint256 public constant MIN_BPOW_BASE = 1 wei;
    uint256 public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
    uint256 public constant BPOW_PRECISION = BONE / 10**10;

    function btoi(uint256 a) internal pure returns (uint256) {
        return a / BONE;
    }

    function bfloor(uint256 a) internal pure returns (uint256) {
        return btoi(a) * BONE;
    }

    function badd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
        (uint256 c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint256 a, uint256 b)
        internal
        pure
        returns (uint256, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
        uint256 z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `bpowi` for `b^e` and `bpowK` for k iterations
    // of approximation of b^0.w
    function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint256 whole = bfloor(exp);
        uint256 remain = bsub(exp, whole);

        uint256 wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(
        uint256 base,
        uint256 exp,
        uint256 precision
    ) internal pure returns (uint256) {
        // term 0:
        uint256 a = exp;
        (uint256 x, bool xneg) = bsubSign(base, BONE);
        uint256 term = BONE;
        uint256 sum = term;
        bool negative = false;

        // term(k) = numer / denom
        //         = (product(a - i + 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * BONE;
            (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }
}

// File: contracts/interfaces/IERC20.sol

pragma solidity 0.5.17;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}

// File: contracts/XHalfLife.sol

pragma solidity 0.5.17;






contract XHalfLife is ReentrancyGuard {
    using SafeMath for uint256;
    using AddressHelper for address;

    uint256 private constant ONE = 10**18;

    /**
     * @notice Counter for new stream ids.
     */
    uint256 public nextStreamId = 1;

    /**
     * @notice key: stream id, value: minimum effective value(0.0001 TOKEN)
     */
    mapping(uint256 => uint256) public effectiveValues;

    // halflife stream
    struct Stream {
        uint256 depositAmount; // total deposited amount, must >= 0.0001 TOKEN
        uint256 remaining; // un-withdrawable balance
        uint256 withdrawable; // withdrawable balance
        uint256 startBlock; // when should start
        uint256 kBlock; // interval K blocks
        uint256 unlockRatio; // must be between [1-999], which means 0.1% to 99.9%
        uint256 denom; // one readable coin represent
        uint256 lastRewardBlock; // update by create(), fund() and withdraw()
        address token; // ERC20 token address or 0xEe for Ether
        address recipient;
        address sender;
        bool cancelable; // can be cancelled or not
        bool isEntity;
    }

    /**
     * @notice The stream objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 => Stream) public streams;

    /**
     * @dev Throws if the provided id does not point to a valid stream.
     */
    modifier streamExists(uint256 streamId) {
        require(streams[streamId].isEntity, "stream does not exist");
        _;
    }

    /**
     * @dev Throws if the caller is not the sender of the recipient of the stream.
     *  Throws if the recipient is the zero address, the contract itself or the caller.
     *  Throws if the depositAmount is 0.
     *  Throws if the start block is before `block.number`.
     */
    modifier createStreamPreflight(
        address recipient,
        uint256 depositAmount,
        uint256 startBlock,
        uint256 kBlock
    ) {
        require(recipient != address(0), "stream to the zero address");
        require(recipient != address(this), "stream to the contract itself");
        require(recipient != msg.sender, "stream to the caller");
        require(depositAmount > 0, "deposit amount is zero");
        require(startBlock >= block.number, "start block before block.number");
        require(kBlock > 0, "k block is zero");
        _;
    }

    event StreamCreated(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        address token,
        uint256 depositAmount,
        uint256 startBlock,
        uint256 kBlock,
        uint256 unlockRatio,
        bool cancelable
    );

    event WithdrawFromStream(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount
    );

    event StreamCanceled(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance
    );

    event StreamFunded(uint256 indexed streamId, uint256 amount);

    /**
     * @notice Creates a new stream funded by `msg.sender` and paid towards `recipient`.
     * @dev Throws if paused.
     *  Throws if the token is not a contract address
     *  Throws if the recipient is the zero address, the contract itself or the caller.
     *  Throws if the depositAmount is 0.
     *  Throws if the start block is before `block.number`.
     *  Throws if the rate calculation has a math error.
     *  Throws if the next stream id calculation has a math error.
     *  Throws if the contract is not allowed to transfer enough tokens.
     * @param token The ERC20 token address
     * @param recipient The address towards which the money is streamed.
     * @param depositAmount The amount of money to be streamed.
     * @param startBlock stream start block
     * @param kBlock unlock every k blocks
     * @param unlockRatio unlock ratio from remaining balance,
     *                    value must be between [1-1000], which means 0.1% to 1%
     * @param cancelable can be cancelled or not
     * @return The uint256 id of the newly created stream.
     */
    function createStream(
        address token,
        address recipient,
        uint256 depositAmount,
        uint256 startBlock,
        uint256 kBlock,
        uint256 unlockRatio,
        bool cancelable
    )
        external
        createStreamPreflight(recipient, depositAmount, startBlock, kBlock)
        returns (uint256 streamId)
    {
        require(unlockRatio < 1000, "unlockRatio must < 1000");
        require(unlockRatio > 0, "unlockRatio must > 0");

        require(token.isContract(), "not contract");
        token.safeTransferFrom(msg.sender, address(this), depositAmount);

        streamId = nextStreamId;
        {
            uint256 denom = 10**uint256(IERC20(token).decimals());
            require(denom >= 10**6, "token decimal too small");

            // 0.0001 TOKEN
            effectiveValues[streamId] = denom.div(10**4);
            require(
                depositAmount >= effectiveValues[streamId],
                "deposit too small"
            );

            streams[streamId] = Stream({
                token: token,
                remaining: depositAmount,
                withdrawable: 0,
                depositAmount: depositAmount,
                startBlock: startBlock,
                kBlock: kBlock,
                unlockRatio: unlockRatio,
                denom: denom,
                lastRewardBlock: startBlock,
                recipient: recipient,
                sender: msg.sender,
                isEntity: true,
                cancelable: cancelable
            });
        }

        nextStreamId = nextStreamId.add(1);
        emit StreamCreated(
            streamId,
            msg.sender,
            recipient,
            token,
            depositAmount,
            startBlock,
            kBlock,
            unlockRatio,
            cancelable
        );
    }

    /**
     * @notice Creates a new ether stream funded by `msg.sender` and paid towards `recipient`.
     * @dev Throws if paused.
     *  Throws if the recipient is the zero address, the contract itself or the caller.
     *  Throws if the depositAmount is 0.
     *  Throws if the start block is before `block.number`.
     *  Throws if the rate calculation has a math error.
     *  Throws if the next stream id calculation has a math error.
     *  Throws if the contract is not allowed to transfer enough tokens.
     * @param recipient The address towards which the money is streamed.
     * @param startBlock stream start block
     * @param kBlock unlock every k blocks
     * @param unlockRatio unlock ratio from remaining balance
     * @param cancelable can be cancelled or not
     * @return The uint256 id of the newly created stream.
     */
    function createEtherStream(
        address recipient,
        uint256 startBlock,
        uint256 kBlock,
        uint256 unlockRatio,
        bool cancelable
    )
        external
        payable
        createStreamPreflight(recipient, msg.value, startBlock, kBlock)
        returns (uint256 streamId)
    {
        require(unlockRatio < 1000, "unlockRatio must < 1000");
        require(unlockRatio > 0, "unlockRatio must > 0");
        require(msg.value >= 10**14, "deposit too small");

        /* Create and store the stream object. */
        streamId = nextStreamId;
        streams[streamId] = Stream({
            token: AddressHelper.ethAddress(),
            remaining: msg.value,
            withdrawable: 0,
            depositAmount: msg.value,
            startBlock: startBlock,
            kBlock: kBlock,
            unlockRatio: unlockRatio,
            denom: 10**18,
            lastRewardBlock: startBlock,
            recipient: recipient,
            sender: msg.sender,
            isEntity: true,
            cancelable: cancelable
        });

        nextStreamId = nextStreamId.add(1);
        emit StreamCreated(
            streamId,
            msg.sender,
            recipient,
            AddressHelper.ethAddress(),
            msg.value,
            startBlock,
            kBlock,
            unlockRatio,
            cancelable
        );
    }

    /**
     * @notice Check if given stream exists.
     * @param streamId The id of the stream to query.
     * @return bool true=exists, otherwise false.
     */
    function hasStream(uint256 streamId) external view returns (bool) {
        return streams[streamId].isEntity;
    }

    /**
     * @notice Returns the stream with all its properties.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream to query.
     * @return sender
     * @return recipient
     * @return token
     * @return depositAmount
     * @return startBlock
     * @return kBlock
     * @return remaining
     * @return withdrawable
     * @return unlockRatio
     * @return lastRewardBlock
     * @return cancelable
     */
    function getStream(uint256 streamId)
        external
        view
        streamExists(streamId)
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
        )
    {
        Stream memory stream = streams[streamId];
        sender = stream.sender;
        recipient = stream.recipient;
        token = stream.token;
        depositAmount = stream.depositAmount;
        startBlock = stream.startBlock;
        kBlock = stream.kBlock;
        remaining = stream.remaining;
        withdrawable = stream.withdrawable;
        unlockRatio = stream.unlockRatio;
        lastRewardBlock = stream.lastRewardBlock;
        cancelable = stream.cancelable;
    }

    /**
     * @notice funds to an existing stream(for general purpose), 
     the amount of fund should be simply added to un-withdrawable.
     * @dev Throws if the caller is not the stream.sender
     * @param streamId The id of the stream to query.
     * @param amount deposit amount by stream sender
     */
    function singleFundStream(uint256 streamId, uint256 amount)
        external
        payable
        nonReentrant
        streamExists(streamId)
        returns (bool)
    {
        Stream storage stream = streams[streamId];
        require(
            msg.sender == stream.sender,
            "caller must be the sender of the stream"
        );
        require(amount > effectiveValues[streamId], "amount not effective");
        if (stream.token == AddressHelper.ethAddress()) {
            require(amount == msg.value, "bad ether fund");
        } else {
            stream.token.safeTransferFrom(msg.sender, address(this), amount);
        }

        (uint256 withdrawable, uint256 remaining) = balanceOf(streamId);

        // update remaining and withdrawable balance
        stream.lastRewardBlock = block.number;
        stream.remaining = remaining.add(amount); // = remaining + amount
        stream.withdrawable = withdrawable; // = withdrawable

        //add funds to total deposit amount
        stream.depositAmount = stream.depositAmount.add(amount);
        emit StreamFunded(streamId, amount);
        return true;
    }

    /**
     * @notice Implemented for XDEX farming and vesting,
     * the amount of fund should be splited to withdrawable and un-withdrawable according to lastRewardBlock.
     * @dev Throws if the caller is not the stream.sender
     * @param streamId The id of the stream to query.
     * @param amount deposit amount by stream sender
     * @param blockHeightDiff diff of block.number and farmPool's lastRewardBlock
     */
    function lazyFundStream(
        uint256 streamId,
        uint256 amount,
        uint256 blockHeightDiff
    ) external payable nonReentrant streamExists(streamId) returns (bool) {
        Stream storage stream = streams[streamId];
        require(
            msg.sender == stream.sender,
            "caller must be the sender of the stream"
        );
        require(amount > effectiveValues[streamId], "amount not effective");
        if (stream.token == AddressHelper.ethAddress()) {
            require(amount == msg.value, "bad ether fund");
        } else {
            stream.token.safeTransferFrom(msg.sender, address(this), amount);
        }

        (uint256 withdrawable, uint256 remaining) = balanceOf(streamId);

        //uint256 blockHeightDiff = block.number.sub(stream.lastRewardBlock);
        // If underflow m might be 0, peg true kBlock to 1, if bHD 0 then error.
        // Minimum amount is 100
        uint256 m = amount.mul(ONE).div(blockHeightDiff);
        // peg true kBlock to 1 so n over k always greater or equal 1
        uint256 noverk = blockHeightDiff.mul(ONE);
        // peg true mu to mu/kBlock
        uint256 mu = stream.unlockRatio.mul(ONE).div(1000).div(stream.kBlock);
        // Enlarged due to mu divided by kBlock
        uint256 onesubmu = ONE.sub(mu);
        // uint256 s = m.mul(ONE.sub(XNum.bpow(onesubmu,noverk))).div(ONE).div(mu).mul(ONE);
        uint256 s =
            m.mul(ONE.sub(XNum.bpow(onesubmu, noverk))).div(mu).div(ONE);

        // update remaining and withdrawable balance
        stream.lastRewardBlock = block.number;
        stream.remaining = remaining.add(s); // = remaining + s
        stream.withdrawable = withdrawable.add(amount).sub(s); // = withdrawable + (amount - s)

        // add funds to total deposit amount
        stream.depositAmount = stream.depositAmount.add(amount);
        emit StreamFunded(streamId, amount);
        return true;
    }

    /**
     * @notice Returns the available funds for the given stream id and address.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream for which to query the balance.
     * @return withdrawable The total funds allocated to `recipient` and `sender` as uint256.
     * @return remaining The total funds allocated to `recipient` and `sender` as uint256.
     */
    function balanceOf(uint256 streamId)
        public
        view
        streamExists(streamId)
        returns (uint256 withdrawable, uint256 remaining)
    {
        Stream memory stream = streams[streamId];

        if (block.number < stream.startBlock) {
            return (0, stream.depositAmount);
        }

        uint256 lastBalance = stream.withdrawable;

        uint256 n =
            block.number.sub(stream.lastRewardBlock).mul(ONE).div(
                stream.kBlock
            );
        uint256 k = stream.unlockRatio.mul(ONE).div(1000);
        uint256 mu = ONE.sub(k);
        uint256 r = stream.remaining.mul(XNum.bpow(mu, n)).div(ONE);
        uint256 w = stream.remaining.sub(r); // withdrawable, if n is float this process will be smooth and slightly

        if (lastBalance > 0) {
            w = w.add(lastBalance);
        }

        //If `remaining` + `withdrawable` < `depositAmount`, it means there have withdraws.
        require(
            r.add(w) <= stream.depositAmount,
            "balanceOf: remaining or withdrawable amount is bad"
        );

        if (w >= effectiveValues[streamId]) {
            withdrawable = w;
        } else {
            withdrawable = 0;
        }

        if (r >= effectiveValues[streamId]) {
            remaining = r;
        } else {
            remaining = 0;
        }
    }

    /**
     * @notice Withdraws from the contract to the recipient's account.
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if the amount exceeds the withdrawable balance.
     *  Throws if the amount < the effective withdraw value.
     *  Throws if the caller is not the recipient.
     * @param streamId The id of the stream to withdraw tokens from.
     * @param amount The amount of tokens to withdraw.
     * @return bool true=success, otherwise false.
     */
    function withdrawFromStream(uint256 streamId, uint256 amount)
        external
        nonReentrant
        streamExists(streamId)
        returns (bool)
    {
        Stream storage stream = streams[streamId];

        require(
            msg.sender == stream.recipient,
            "caller must be the recipient of the stream"
        );

        require(
            amount >= effectiveValues[streamId],
            "amount is zero or not effective"
        );

        (uint256 withdrawable, uint256 remaining) = balanceOf(streamId);

        require(
            withdrawable >= amount,
            "withdraw amount exceeds the available balance"
        );

        if (stream.token == AddressHelper.ethAddress()) {
            stream.recipient.safeTransferEther(amount);
        } else {
            stream.token.safeTransfer(stream.recipient, amount);
        }

        stream.lastRewardBlock = block.number;
        stream.remaining = remaining;
        stream.withdrawable = withdrawable.sub(amount);

        emit WithdrawFromStream(streamId, stream.recipient, amount);
        return true;
    }

    /**
     * @notice Cancels the stream and transfers the tokens back
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if the caller is not the sender or the recipient of the stream.
     *  Throws if there is a token transfer failure.
     * @param streamId The id of the stream to cancel.
     * @return bool true=success, otherwise false.
     */
    function cancelStream(uint256 streamId)
        external
        nonReentrant
        streamExists(streamId)
        returns (bool)
    {
        Stream memory stream = streams[streamId];

        require(stream.cancelable, "non cancelable stream");
        require(
            msg.sender == streams[streamId].sender ||
                msg.sender == streams[streamId].recipient,
            "caller must be the sender or the recipient"
        );

        (uint256 withdrawable, uint256 remaining) = balanceOf(streamId);

        //save gas
        delete streams[streamId];
        delete effectiveValues[streamId];

        if (withdrawable > 0) {
            if (stream.token == AddressHelper.ethAddress()) {
                stream.recipient.safeTransferEther(withdrawable);
            } else {
                stream.token.safeTransfer(stream.recipient, withdrawable);
            }
        }

        if (remaining > 0) {
            if (stream.token == AddressHelper.ethAddress()) {
                stream.sender.safeTransferEther(remaining);
            } else {
                stream.token.safeTransfer(stream.sender, remaining);
            }
        }

        emit StreamCanceled(
            streamId,
            stream.sender,
            stream.recipient,
            withdrawable,
            remaining
        );
        return true;
    }

    function getVersion() external pure returns (bytes32) {
        return bytes32("APOLLO");
    }
}