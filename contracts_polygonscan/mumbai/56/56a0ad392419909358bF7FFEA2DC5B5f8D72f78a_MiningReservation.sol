/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
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


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
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


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


contract MiningReservation is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct MiningLogicManagerAddressInfo {
        address[] MiningLogicManagerAddress;
        uint256[] percent;
        uint256 voteStartTime;
    }

    /*lock time */
    uint256 public lockTime = 1642665600; //1st April 2024
    uint256 public totalLocked = 15000000 * (10**18);
    uint256 public multipler = 1;

    /* Min release rate */
    uint256 public minReleaseRate = 7125 * 10**16; //71.25 DG

    /* Available at first */
    uint256 public startAmount = 4560 * (10**18);
    uint256 public beginAmount = 4560 * (10**18);

    /* Votation time*/
    uint256 public votationStartTime = 0;
    uint256 public votationDuration = 0;

    /* votation staking*/
    mapping(address => uint256) stakeAmount;
    mapping(uint256 => address) stakers;
    uint256 public totalStakeAmount;
    uint256 public stakerCount = 0;

    /* votation info */
    mapping(address => uint256) voteInfo;
    mapping(uint256 => uint256) totalVoteInfo;
    mapping(uint256 => uint256) totalVotedDG;
    mapping(address => MiningLogicManagerAddressInfo) miningLogicInfo;

    address public voteSetter = 0x40985df70659b5E81aE5838d6c88796cAa9b0c6c;
    /* Votation address set time*/
    uint256 public voteOption = 2;

    /* the address of the token contract */
    IERC20 public dataGen;

    /* Dead address */
    address[] MiningLogicManagerAddress;
    uint256[] percent;
    uint256 countMiningLogicManagerAddress;
    address deadAddr = 0x40985df70659b5E81aE5838d6c88796cAa9b0c6c;
    address[] newMiningLogicManagerAddress;
    uint256[] new_percent;

    event SetMiningLogicManagerAddress(
        address indexed user,
        address[] indexed MiningLogicManagerAddress
    );
    event getWinnerInfo(
        uint winnerInfo,
        address[] indexed MiningLogicManagerAddress,
        uint[] indexed percents
    );

    modifier duringVotation() {
        require(votationStartTime > 0, "votation start time is not set");
        require(votationDuration > 0, "votation duration is not set");
        require(
            block.timestamp >= votationStartTime,
            "votation is not started"
        );
        require(
            block.timestamp <= votationStartTime + votationDuration,
            "votation ended"
        );
        _;
    }
    modifier beforeVotationStart() {
        require(
            votationStartTime == 0 && votationDuration == 0,
            "you can't set voteOption currently"
        );
        _;
    }

    modifier afterVotation() {
        require(votationStartTime > 0, "votation start time is not set");
        require(votationDuration > 0, "votation duration is not set");
        require(
            block.timestamp >= votationStartTime + votationDuration,
            "votation not ended"
        );
        _;
    }

    modifier onlyVoteSetter() {
        require(msg.sender == voteSetter, "you are not setter");
        _;
    }

    modifier onlyStaker() {
        uint256 found = 0;
        for (uint256 i = 0; i < stakerCount; i++) {
            address stakerAddr = stakers[i];
            if (msg.sender == stakerAddr) {
                found = 1;
                break;
            }
        }
        require(found == 1, "you are not staker");
        _;
    }

    /*  initialization, set the token address */
    constructor(IERC20 _dataGen) {
        dataGen = _dataGen;
        countMiningLogicManagerAddress = 1;
        MiningLogicManagerAddress.push(deadAddr);
        percent.push(100);
        newMiningLogicManagerAddress.push(deadAddr);
    }

    function setMiningLogicManagerAddress(
        address[] memory _newMiningLogicManagerAddress,
        uint256[] memory _percent
    ) internal afterVotation {
        MiningLogicManagerAddress = _newMiningLogicManagerAddress;
        percent = _percent;
        countMiningLogicManagerAddress = _percent.length;

        votationStartTime = 0;
        votationDuration = 0;
        voteSetter = deadAddr;

        emit SetMiningLogicManagerAddress(
            msg.sender,
            MiningLogicManagerAddress
        );
    }

    function stake(uint256 amount) external nonReentrant {
        require(
            dataGen.balanceOf(msg.sender) >= amount,
            "you have not enough #DG to stake"
        );
        require(voteInfo[msg.sender] == 0, "you can't stake after vote");

        if (
            stakeAmount[msg.sender] + amount >= 100000 * 10**18 &&
            voteSetter == deadAddr
        ) {
            require(
                miningLogicInfo[msg.sender].voteStartTime != 0,
                "You must set vote option using voteOptionSet before stake 100000 DG"
            );
        }

        if (stakeAmount[msg.sender] == 0) {
            stakers[stakerCount] = msg.sender;
            stakerCount++;
        }
        stakeAmount[msg.sender] += amount;

        if (
            stakeAmount[msg.sender] >= 100000 * 10**18 && voteSetter == deadAddr
        ) {
            voteSetter = msg.sender;
            votationStartTime = miningLogicInfo[msg.sender].voteStartTime;
            votationDuration = 3600;
            newMiningLogicManagerAddress = miningLogicInfo[msg.sender]
                .MiningLogicManagerAddress;
            new_percent = miningLogicInfo[msg.sender].percent;
        }
        totalStakeAmount += amount;
        dataGen.transferFrom(msg.sender, address(this), amount);
    }

    /*
	min 3 days
	max 60 days
	cannot set after set
*/
    function voteOptionSet(
        address[] memory _newMiningLogicManagerAddress,
        uint256[] memory _percent,
        uint256 _voteStartTime
        ) external beforeVotationStart {
        require(
            _newMiningLogicManagerAddress.length > 1 ||
                _newMiningLogicManagerAddress[0] != deadAddr,
            "already set new mining wallet address"
        );
        require(
            
                _voteStartTime <= block.timestamp + 60 days,
            "voteStartTime must be bigger than 3 days from now and lesser than 60 days from now"
        );
        uint256 len_percent = _percent.length;
        uint256 len_wallet = _newMiningLogicManagerAddress.length;
        require(
            len_percent == len_wallet,
            "_newMiningLogicManagerAddress and percent count are not match"
        );
        uint256 total_percent = 0;
        for (uint256 i = 0; i < len_percent; i++) {
            total_percent += _percent[i];
        }
        require(total_percent == 100, "total percent must be 100");
        miningLogicInfo[msg.sender]
            .MiningLogicManagerAddress = _newMiningLogicManagerAddress;
        miningLogicInfo[msg.sender].percent = _percent;
        miningLogicInfo[msg.sender].voteStartTime = _voteStartTime;
    }

    /*
	min DG 20
*/
    function vote(uint256 position) external duringVotation nonReentrant {
        require(
            stakeAmount[msg.sender] > 20 * 10**18,
            "you must stake before vote"
        );
        require(voteInfo[msg.sender] == 0, "you already voted");
        require(voteOption > 0, "total vote option is not set yet");
        require(position > 0, "vote position must be bigger than 0");
        require(
            position <= voteOption,
            "position must be less than total vote option count"
        );

        voteInfo[msg.sender] = position;
        totalVoteInfo[position]++;
        totalVotedDG[position] += stakeAmount[msg.sender];
    }

    function getVoteInfo(uint256 position) external view returns (uint256) {
        require(position > 0, "position must be bigger than 0");
        require(
            position <= voteOption,
            "position must be less than total vote option count"
        );
        return totalVoteInfo[position];
    }

    function getWinner()
        external
        afterVotation
        nonReentrant
        onlyStaker
        returns (uint256) {
        uint256 winnerDGCount = 0;
        uint256 winnerInfo;
        for (uint256 i = 1; i <= voteOption; i++) {
            if (winnerDGCount < totalVotedDG[i]) {
                winnerDGCount = totalVotedDG[i];
                winnerInfo = i;
            }
        }
        for (uint256 i = 0; i < stakerCount; i++) {
            address stakerAddr = stakers[i];
            dataGen.transfer(stakerAddr, stakeAmount[stakerAddr]);
            voteInfo[stakerAddr] = 0;
            stakeAmount[stakerAddr] = 0;
            stakers[i] = deadAddr;
            miningLogicInfo[stakerAddr].voteStartTime = 0;
        }

        for (uint256 i = 1; i <= voteOption; i++) {
            totalVoteInfo[i] = 0;
            totalVotedDG[i] = 0;
        }
        totalStakeAmount = 0;
        stakerCount = 0;

        uint256[] memory tempPercent;
        tempPercent = new uint256[](1);
        tempPercent[0] = 100;
        address[] memory tempAddr;
        tempAddr = new address[](1);
        tempAddr[0] = deadAddr;
        if (winnerInfo == 1) {
            setMiningLogicManagerAddress(tempAddr, tempPercent);
            emit getWinnerInfo(
                winnerInfo,
                tempAddr,
                tempPercent
            );
        }
        else if (winnerInfo == 2) {
            setMiningLogicManagerAddress(
                newMiningLogicManagerAddress,
                new_percent
            );
            emit getWinnerInfo(
                winnerInfo,
                newMiningLogicManagerAddress,
                new_percent
            );
        }
        return winnerInfo;
    }

    function releaseDataGen() public nonReentrant {
        require(dataGen.balanceOf(address(this)) > 0, "Zero #DG left.");
        require(block.timestamp >= lockTime, "Still locked.");

        uint256 balance = dataGen.balanceOf(address(this));

        uint256 plusDate = multipler.mul(1095).sub(1095);
        uint256 epochs = block
            .timestamp
            .sub(lockTime)
            .div(60)
            .add(1)
            .sub(plusDate);
        if (epochs > 1095) {
            epochs = epochs - 1095;
            multipler++;
            beginAmount = beginAmount.div(2);
            if (beginAmount < minReleaseRate) beginAmount = minReleaseRate;
        }

        uint256 counter = multipler;
        uint256 releaseAmount = 0;
        uint256 mintUnitAmount = startAmount;
        while (counter > 1) {
            releaseAmount = releaseAmount + mintUnitAmount.mul(1095);
            mintUnitAmount = mintUnitAmount.div(2);
            counter--;
        }
        releaseAmount = beginAmount.mul(epochs).add(releaseAmount);
        uint256 leftAmount = totalLocked.sub(releaseAmount);

        require(balance > leftAmount, "Already released.");
        uint256 transferAmount = balance.sub(leftAmount);
        if (transferAmount > 0) {
            require(balance >= transferAmount, "Wrong amount to transfer");
            for (uint256 i = 0; i < countMiningLogicManagerAddress; i++) {
                uint256 amount = (transferAmount * percent[i]) / 100;
                dataGen.transfer(MiningLogicManagerAddress[i], amount);
            }
        }
    }
}