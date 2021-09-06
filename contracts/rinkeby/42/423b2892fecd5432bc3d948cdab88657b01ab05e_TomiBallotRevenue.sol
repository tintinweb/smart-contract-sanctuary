// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import '../interfaces/IERC20.sol';
import '../interfaces/ITomiGovernance.sol';
import '../libraries/SafeMath.sol';

/**
 * @title TomiBallot
 * @dev Implements voting process along with vote delegation
 */
contract TomiBallotRevenue {
    using SafeMath for uint;

    struct Participator {
        uint256 weight; // weight is accumulated by delegation
        bool participated; // if true, that person already voted
        address delegate; // person delegated to
    }

    mapping(address => Participator) public participators;

    address public TOMI;
    address public governor;
    address public proposer;
    uint256 public endTime;
    uint256 public executionTime;
    bool public ended;
    string public subject;
    string public content;


    uint256 public total;
    uint256 public createTime;

    modifier onlyGovernor() {
        require(msg.sender == governor, 'TomiBallot: FORBIDDEN');
        _;
    }

    /**
     * @dev Create a new ballot.
     */
    constructor(
        address _TOMI,
        address _proposer,
        uint256 _endTime,
        uint256 _executionTime,
        address _governor,
        string memory _subject,
        string memory _content
    ) public {
        TOMI = _TOMI;
        proposer = _proposer;
        endTime = _endTime;
        executionTime = _executionTime;
        governor = _governor;
        subject = _subject;
        content = _content;
        createTime = block.timestamp;
    }


    /**
     * @dev Give 'participator' the right to vote on this ballot.
     * @param participator address of participator
     */
    function _giveRightToJoin(address participator) private returns (Participator storage) {
        require(block.timestamp < endTime, 'Ballot is ended');
        Participator storage sender = participators[participator];
        require(!sender.participated, 'You already participate in');
        sender.weight += IERC20(governor).balanceOf(participator);
        require(sender.weight != 0, 'Has no right to participate in');
        return sender;
    }

    function _stakeCollateralToJoin(uint256 collateral) private returns (bool) {
        uint256 collateralRemain = IERC20(governor).balanceOf(msg.sender);
        uint256 collateralMore = collateral.sub(collateralRemain);
        require(IERC20(TOMI).allowance(msg.sender, address(this)) >= collateralMore, "TomiBallot:Collateral allowance is not enough to vote!");
        IERC20(TOMI).transferFrom(msg.sender, address(this), collateralMore);
        IERC20(TOMI).approve(governor, collateralMore);
        bool success = ITomiGovernance(governor).onBehalfDeposit(msg.sender, collateralMore);
        return success;
    }

    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     */
    function delegate(address to) public {
        Participator storage sender = _giveRightToJoin(msg.sender);
        require(to != msg.sender, 'Self-delegation is disallowed');

        while (participators[to].delegate != address(0)) {
            to = participators[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, 'Found loop in delegation');
        }
        sender.participated = true;
        sender.delegate = to;
        Participator storage delegate_ = participators[to];
        if (delegate_.participated) {
            // If the delegate already voted,
            // directly add to the number of votes
            total += msg.sender != proposer ? sender.weight: 0;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
            total += msg.sender != proposer ? sender.weight: 0;
        }
    }

    // /**
    //  * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
    //  */
    // function participate(uint256 collateral) public {
    //     if (collateral > 0) {
    //         require(_stakeCollateralToJoin(collateral), "TomiBallotRevenue:Fail due to stake TOMI as collateral!");
    //     }

    //     Participator storage sender = _giveRightToJoin(msg.sender);
    //     sender.participated = true;

    //     if (msg.sender != proposer) {
    //         total += sender.weight;
    //     }
    // }

    function participateByGovernor(address user) public onlyGovernor {
        Participator storage sender = _giveRightToJoin(user);
        sender.participated = true;

        if (user != proposer) {
            total += sender.weight;
        }
    }

    function end() public onlyGovernor returns (bool) {
        require(block.timestamp >= executionTime, 'ballot not yet ended');
        require(!ended, 'end has already been called');
        ended = true;
        return ended;
    }

    function weight(address user) external view returns (uint256) {
        Participator memory participator = participators[user];
        return participator.weight;
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.5.0;

interface ITomiGovernance {
    function addPair(address _tokenA, address _tokenB) external returns (bool);
    function addReward(uint _value) external returns (bool);
    function deposit(uint _amount) external returns (bool);
    function onBehalfDeposit(address _user, uint _amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}