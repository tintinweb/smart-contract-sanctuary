/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: Apache-2.0 AND MIT

pragma solidity ^0.8.4;

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

/**
 * @title UTREE token contract interface
 *
 * @dev UTREE token contract interface
 */
interface IUTREE is IERC20 {
    /**
     * @dev Burn `amount` of tokens from owner account, see {ERC20-_burn}
     *
     * @param amount Amount to burn
     */
    function burn(uint256 amount) external;

    /**
     * @dev Mint `amount` of tokens to owner account, see {ERC20-_mint}
     *
     * @param amount Amount to mint
     */
    function mint(uint256 amount) external;

    /**
     * @dev Set `staking` contract address, that could approve token transfers
     *
     * @param staking Staking contract address
     */
    function setStaking(address staking) external;

    /**
     * @dev Set `voting` contract address, that could approve token transfers
     *
     * @param voting Voting contract address
     */
    function setVoting(address voting) external;

    /**
     * @dev Approve allowance to transfer tokens `amount` from `owner` to `spender`, see {IERC20-_approve}
     *
     * @param owner Tokens owner from whom it is allowed to transfer tokens
     * @param spender Someone who can transfer tokens
     * @param amount Amount of tokens allowance to transfer
     */
    function approveTransfer(
        address owner,
        address spender,
        uint256 amount
    ) external;
}


/*
 * @title Voting contract
 *
 * @dev Voting contract extends by {Context} and {Ownable} contracts from OpenZeppelin
 */
contract Voting is Context, Ownable {
    using SafeMath for uint256;

    struct Option {
        string description;
        uint256 votersCount;
        uint256 totalAmounts;
        mapping(address => uint256) amounts;
        mapping(uint256 => address) voters;
    }

    struct Issue {
        string description;
        uint256 finishAt;
        uint256 optionsCount;
        mapping(uint256 => Option) options;
    }

    struct OptionItem {
        uint256 index;
        string description;
        bool isWinning;
        uint256 votesCount;
    }

    struct IssueItem {
        uint256 index;
        string description;
        uint256 finishAt;
    }

    IUTREE private _token;

    uint256 private _lastIssue;

    mapping(uint256 => Issue) private _issues;
    mapping(uint256 => mapping(address => uint256)) private _returned;

    constructor(IUTREE token) {
        _token = token;
    }

    /**
     * @dev Create new voting issue
     *
     * Emit {IssueCreated} event with issue parameters
     *
     * @param description Description of issue
     * @param duration Duration of issue
     * @param options List of issue options
     */
    function createIssue(
        string calldata description,
        uint256 duration,
        string[] calldata options
    ) external onlyOwner {
        // solhint-disable-next-line not-rely-on-time
        uint256 finishAt = block.timestamp.add(duration);

        Issue storage issue = _issues[_lastIssue];

        issue.description = description;
        issue.finishAt = finishAt;
        issue.optionsCount = options.length;

        for (uint256 i = 0; i < options.length; i += 1) {
            Option storage option = issue.options[i];

            option.description = options[i];
        }

        emit IssueCreated(_lastIssue, description, finishAt);

        _lastIssue += 1;
    }

    /**
     * @dev Vote by token holder by `issueIndex` and `optionIndex` with `amount` tokens
     *
     * @notice Vote in issue `issueIndex` for option `optionIndex` with `amount` tokens
     *
     * Emit {VoteCounted} event with vote parameters
     *
     * @param issueIndex Issue index
     * @param optionIndex Options index
     * @param amount Tokens amount for vote
     */
    function vote(
        uint256 issueIndex,
        uint256 optionIndex,
        uint256 amount
    ) external {
        require(_msgSender() != owner(), "Owner cannot vote");
        require(amount >= 100 * 10**18, "Minimum amount is 100");

        // solhint-disable-next-line not-rely-on-time
        require(_issues[issueIndex].finishAt > block.timestamp, "Voting already finished");
        require(_issues[issueIndex].optionsCount > optionIndex, "Wrong option index");

        _token.approveTransfer(_msgSender(), address(this), amount);
        require(_token.transferFrom(_msgSender(), address(this), amount), "Cannot transfer tokens");

        Option storage option = _issues[issueIndex].options[optionIndex];

        option.amounts[_msgSender()] = option.amounts[_msgSender()].add(amount);
        option.totalAmounts = option.totalAmounts.add(amount);
        option.voters[option.votersCount] = _msgSender();

        option.votersCount += 1;

        emit VoteCounted(issueIndex, optionIndex, _msgSender(), amount);
    }

    /**
     * @dev Finish voting issue by `issueIndex`
     *
     * Emit {IssueFinished} event with issue finish parameters
     *
     * @param issueIndex Issue index for finishing
     */
    function finishIssue(uint256 issueIndex) external onlyOwner {
        // solhint-disable-next-line not-rely-on-time
        uint256 finishAt = block.timestamp;

        Issue storage issue = _issues[issueIndex];

        require(issue.finishAt > finishAt, "Voting already finished");

        issue.finishAt = finishAt;

        for (uint256 i = 0; i < issue.optionsCount; i += 1) {
            Option storage option = issue.options[i];

            for (uint256 j = 0; j < option.votersCount; j += 1) {
                address voter = option.voters[j];

                if (_returned[issueIndex][voter] == 0) {
                    uint256 amount = option.amounts[voter];

                    _token.approve(address(this), amount);
                    require(_token.transferFrom(address(this), voter, amount), "Cannot return tokens");

                    _returned[issueIndex][voter] = amount;
                }
            }
        }

        emit IssueFinished(issueIndex, finishAt);
    }

    /**
     * @dev Get a list of voting issues
     *
     * @notice Get a list of voting issues
     */
    function listIssues() external view returns (IssueItem[] memory) {
        IssueItem[] memory issues = new IssueItem[](_lastIssue);

        for (uint256 i = 0; i < _lastIssue; i += 1) {
            IssueItem memory item;

            item.index = i;
            item.description = _issues[i].description;
            item.finishAt = _issues[i].finishAt;

            issues[i] = item;
        }

        return issues;
    }

    /**
     * @dev Get a list of voting issue options
     *
     * @notice Get a list of voting issue options
     *
     * @param issueIndex Issue index
     */
    function listIssueOptions(uint256 issueIndex) external view returns (OptionItem[] memory) {
        require(_issues[issueIndex].optionsCount > 0, "Wrong issue index");

        OptionItem[] memory options = new OptionItem[](_issues[issueIndex].optionsCount);

        uint256 votersCount;
        uint256 winningIndex;

        for (uint256 i = 0; i < _issues[issueIndex].optionsCount; i += 1) {
            OptionItem memory item;

            item.index = i;
            item.description = _issues[issueIndex].options[i].description;
            item.votesCount = _issues[issueIndex].options[i].totalAmounts.div(100 * 10**18);

            if (item.votesCount > votersCount) {
                votersCount = item.votesCount;
                winningIndex = i;
            }

            options[i] = item;
        }

        options[winningIndex].isWinning = true;

        return options;
    }

    event IssueCreated(uint256 issueIndex, string description, uint256 finishAt);
    event IssueFinished(uint256 issueIndex, uint256 finishAt);
    event VoteCounted(uint256 issueIndex, uint256 optionIndex, address voter, uint256 amount);
}