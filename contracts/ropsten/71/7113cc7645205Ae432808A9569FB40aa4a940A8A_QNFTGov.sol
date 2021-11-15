// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interface/structs.sol";
import "../interface/IQNFT.sol";

/**
 * @author fantasy
 */
contract QNFTGov is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    event VoteGovernanceAddress(
        address indexed voter,
        address indexed multisig,
        uint256 amount
    );
    event WithdrawToGovernanceAddress(
        address indexed user,
        address indexed multisig,
        uint256 amount
    );
    event SafeWithdraw(
        address indexed owner,
        address indexed ultisig,
        uint256 amount
    );

    // constants
    uint256 public constant VOTE_QUORUM = 50; // 50%
    uint256 public constant PERCENT_MAX = 100;

    // vote options
    mapping(address => uint256) public voteResult; // vote amount of give multisig wallet
    mapping(address => address) public voteAddressByVoter; // vote address of given user
    mapping(address => uint256) public voteWeightsByVoter; // vote amoutn of given user

    IQNFT public qnft;

    modifier onlyQnft() {
        require(address(qnft) == _msgSender(), "Ownable: caller is not QNFT");
        _;
    }

    constructor() {}

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev votes on a given multisig wallet with the locked qstk balance of the user
     */
    function voteGovernanceAddress(address multisig) public {
        require(qnft.mintStarted(), "QNFTGov: mint not started");
        require(qnft.mintFinished(), "QNFTGov: NFT sale not ended");

        uint256 qstkAmount = qnft.qstkBalances(msg.sender);
        require(qstkAmount > 0, "QNFTGov: non-zero qstk balance");

        if (voteAddressByVoter[msg.sender] != address(0x0)) {
            voteResult[voteAddressByVoter[msg.sender]] = voteResult[
                voteAddressByVoter[msg.sender]
            ]
                .sub(voteWeightsByVoter[msg.sender]);
        }

        voteResult[multisig] = voteResult[multisig].add(qstkAmount);
        voteWeightsByVoter[msg.sender] = qstkAmount;
        voteAddressByVoter[msg.sender] = multisig;

        emit VoteGovernanceAddress(msg.sender, multisig, qstkAmount);
    }

    /**
     * @dev withdraws to the governance address if it has enough vote amount
     */
    function withdrawToGovernanceAddress(address payable multisig)
        public
        nonReentrant
    {
        VoteStatus status = qnft.voteStatus();
        require(status != VoteStatus.NotStarted, "QNFTGov: vote not started");
        require(status != VoteStatus.InProgress, "QNFTGov: vote in progress");

        require(
            voteResult[multisig] >=
                qnft.totalAssignedQstk().mul(VOTE_QUORUM).div(PERCENT_MAX),
            "QNFTGov: specified multisig address is not voted enough"
        );

        uint256 amount = address(this).balance;

        multisig.transfer(amount);

        emit WithdrawToGovernanceAddress(msg.sender, multisig, amount);
    }

    /**
     * @dev withdraws to multisig wallet by owner - need to pass the safe vote end duration
     */
    function safeWithdraw(address payable multisig)
        public
        onlyOwner
        nonReentrant
    {
        VoteStatus status = qnft.voteStatus();
        require(status != VoteStatus.NotStarted, "QNFTGov: vote not started");
        require(status != VoteStatus.InProgress, "QNFTGov: vote in progress");
        require(
            status == VoteStatus.AbleToSafeWithdraw,
            "QNFTGov: wait until safe vote end time"
        );

        uint256 amount = address(this).balance;

        multisig.transfer(amount);

        emit SafeWithdraw(msg.sender, multisig, amount);
    }

    /**
     * @dev updates the votes amount of the given user
     */
    function updateVoteAmount(
        address user,
        uint256 minusAmount,
        uint256 plusAmount
    ) public onlyQnft {
        if (voteAddressByVoter[user] != address(0x0)) {
            // just updates the vote amount if the user has previous vote.

            voteWeightsByVoter[user] = voteWeightsByVoter[user]
                .add(plusAmount)
                .sub(minusAmount);

            voteResult[voteAddressByVoter[msg.sender]] = voteResult[
                voteAddressByVoter[msg.sender]
            ]
                .add(plusAmount)
                .sub(minusAmount);

            if (voteWeightsByVoter[user] == 0) {
                voteAddressByVoter[user] = address(0x0);
            }
        }
    }

    /**
     * @dev sets QNFT contract address
     */
    function setQNft(IQNFT _qnft) public onlyOwner {
        require(qnft != _qnft, "QNFTGov: QNFT already set");

        qnft = _qnft;
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// structs
enum VoteStatus {
    NotStarted, // vote not started
    InProgress, // vote started, min vote duration not passed
    AbleToWithdraw, // vote started, min vote duration passed, safe vote end time not passed
    AbleToSafeWithdraw // vote started, min vote duration passed, safe vote end time passed
}

struct LockOption {
    uint256 minAmount; // e.g. 0QSTK, 100QSTK, 200QSTK, 300QSTK
    uint256 maxAmount; // e.g. 0QSTK, 100QSTK, 200QSTK, 300QSTK
    uint256 lockDuration; // e.g. 3 months, 6 months, 1 year
    uint256 discount; // percent e.g. 10%, 20%, 30%
}
struct NFTBackgroundImage {
    // Sunrise-Noon-Evening-Night: based on local time
    string background1;
    string background2;
    string background3;
    string background4;
}
struct NFTArrowImage {
    // global crypto market change - up, normal, down
    string image1;
    string image2;
    string image3;
}
struct NFTImageDesigner {
    // information of NFT iamge designer
    string name;
    address wallet;
    string meta_info;
}
struct NFTImage {
    // each NFT has 5 emotions
    uint256 mintPrice;
    string emotion1;
    string emotion2;
    string emotion3;
    string emotion4;
    string emotion5;
    NFTImageDesigner designer;
}
struct NFTFavCoin {
    // information of favorite coins
    uint256 mintPrice;
    string name;
    string symbol;
    string icon;
    string website;
    string social;
    address erc20;
    string other;
}
struct NFTCreator {
    // NFT minter informations
    string name;
    address wallet;
}
struct NFTMeta {
    // NFT meta informations
    string name;
    string color;
    string story;
}
struct NFTData {
    // NFT data
    uint256 imageId;
    uint256 bgImageId;
    uint256 favCoinId;
    uint256 lockOptionId;
    uint256 lockAmount;
    uint256 defaultImageIndex;
    uint256 createdAt;
    bool withdrawn;
    NFTMeta meta;
    NFTCreator creator;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./structs.sol";

interface IQNFT {
    function qstk() external view returns (address);

    function mintStarted() external view returns (bool);

    function mintFinished() external view returns (bool);

    function voteStatus() external view returns (VoteStatus);

    function qstkBalances(address user) external view returns (uint256);

    function totalAssignedQstk() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

