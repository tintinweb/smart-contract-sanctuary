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

interface IYFVIRewards {
    function stakingPower(address account) external view returns (uint256);
}

interface IYFVIGovernanceRewardScaler {
    function votingValueGovernance(address poolAddress, uint256 votingItem, uint16 votingValue) external view returns (uint16);
}

contract YFVIVote {
    using SafeMath for uint256;

    address public governance;

    uint8 public constant MAX_VOTERS_PER_ITEM = 200;

    uint16 public defaultVotingValueMin = 50; // reward scaling factor 50% (x0.5 times)
    uint16 public defaultVotingValueMax = 150; // reward scaling factor 150% (x1.5 times)

    mapping(address => mapping(uint256 => uint8)) public numVoters; // poolAddress -> votingItem (periodFinish) -> numVoters (the number of voters in this round)
    mapping(address => mapping(uint256 => address[MAX_VOTERS_PER_ITEM])) public voters; // poolAddress -> votingItem (periodFinish) -> voters (array)
    mapping(address => mapping(uint256 => mapping(address => bool))) public isInTopVoters; // poolAddress -> votingItem (periodFinish) -> isInTopVoters (map: voter -> in_top (true/false))
    mapping(address => mapping(uint256 => mapping(address => uint16))) public voter2VotingValue; // poolAddress -> votingItem (periodFinish) -> voter2VotingValue (map: voter -> voting value)

    mapping(address => mapping(uint256 => uint16)) public votingValueMinimums; // poolAddress -> votingItem (proposalId) -> votingValueMin
    mapping(address => mapping(uint256 => uint16)) public votingValueMaximums; // poolAddress -> votingItem (proposalId) -> votingValueMax

    address public governanceRewardScaler;

    event Voted(address poolAddress, address indexed user, uint256 votingItem, uint16 votingValue);

    constructor () public {
        governance = msg.sender;
    }

    function setDefaultVotingValueRange(uint16 minValue, uint16 maxValue) public {
        require(msg.sender == governance, "!governance");
        require(minValue < maxValue, "Invalid voting range");
        defaultVotingValueMin = minValue;
        defaultVotingValueMax = maxValue;
    }

    function setVotingValueRange(address poolAddress, uint256 votingItem, uint16 minValue, uint16 maxValue) public {
        require(msg.sender == governance, "!governance");
        require(minValue < maxValue, "Invalid voting range");
        votingValueMinimums[poolAddress][votingItem] = minValue;
        votingValueMaximums[poolAddress][votingItem] = maxValue;
    }

    function setGovernanceRewardsScaler(address _governanceRewardScaler) public {
        require(msg.sender == governance, "!governance");
        governanceRewardScaler = _governanceRewardScaler;
    }

    function isVotable(address poolAddress, address account, uint256 votingItem) public view returns (bool) {
        // already voted
        if (voter2VotingValue[poolAddress][votingItem][account] > 0) return false;

        IYFVIRewards rewards = IYFVIRewards(poolAddress);
        // hasn't any staking power
        if (rewards.stakingPower(account) == 0) return false;

        // number of voters is under limit still
        if (numVoters[poolAddress][votingItem] < MAX_VOTERS_PER_ITEM) return true;
        for (uint8 i = 0; i < numVoters[poolAddress][votingItem]; i++) {
            if (rewards.stakingPower(voters[poolAddress][votingItem][i]) < rewards.stakingPower(account)) return true;
            // there is some voters has lower staking power
        }

        return false;
    }

    function averageVotingValueNoGovernance(address poolAddress, uint256 votingItem) public view returns (uint16) {
        if (numVoters[poolAddress][votingItem] == 0) return 0; // no votes
        uint256 totalStakingPower = 0;
        uint256 totalWeightVotingValue = 0;
        IYFVIRewards rewards = IYFVIRewards(poolAddress);
        for (uint8 i = 0; i < numVoters[poolAddress][votingItem]; i++) {
            address voter = voters[poolAddress][votingItem][i];
            totalStakingPower = totalStakingPower.add(rewards.stakingPower(voter));
            totalWeightVotingValue = totalWeightVotingValue.add(rewards.stakingPower(voter).mul(voter2VotingValue[poolAddress][votingItem][voter]));
        }
        return (uint16) (totalWeightVotingValue.div(totalStakingPower));
    }

    function averageVotingValue(address poolAddress, uint256 votingItem) public view returns (uint16) {
        uint16 avgValue = 0;
        if (numVoters[poolAddress][votingItem] > 0) {
            avgValue = averageVotingValueNoGovernance(poolAddress, votingItem);
        }
        if (governanceRewardScaler != address(0)) {
            return IYFVIGovernanceRewardScaler(governanceRewardScaler).votingValueGovernance(poolAddress, votingItem, avgValue);
        }
        return avgValue;
    }

    function vote(address poolAddress, uint256 votingItem, uint16 votingValue) public {
        if (votingValueMinimums[poolAddress][votingItem] > 0 && votingValueMaximums[poolAddress][votingItem] > 0) {
            require(votingValue >= votingValueMinimums[poolAddress][votingItem], "votingValue is smaller than minimum accepted value");
            require(votingValue <= votingValueMaximums[poolAddress][votingItem], "votingValue is greater than maximum accepted value");
        } else {
            require(votingValue >= defaultVotingValueMin, "votingValue is smaller than defaultVotingValueMin");
            require(votingValue <= defaultVotingValueMax, "votingValue is greater than defaultVotingValueMax");
        }
        if (!isInTopVoters[poolAddress][votingItem][msg.sender]) {
            require(isVotable(poolAddress, msg.sender, votingItem), "This account is not votable");
            uint8 voterIndex = MAX_VOTERS_PER_ITEM;
            if (numVoters[poolAddress][votingItem] < MAX_VOTERS_PER_ITEM) {
                voterIndex = numVoters[poolAddress][votingItem];
            } else {
                IYFVIRewards rewards = IYFVIRewards(poolAddress);
                uint256 minStakingPower = rewards.stakingPower(msg.sender);
                for (uint8 i = 0; i < numVoters[poolAddress][votingItem]; i++) {
                    if (rewards.stakingPower(voters[poolAddress][votingItem][i]) < minStakingPower) {
                        voterIndex = i;
                        minStakingPower = rewards.stakingPower(voters[poolAddress][votingItem][i]);
                    }
                }
            }
            if (voterIndex < MAX_VOTERS_PER_ITEM) {
                if (voterIndex < numVoters[poolAddress][votingItem]) {
                    // remove lower power previous voter
                    isInTopVoters[poolAddress][votingItem][voters[poolAddress][votingItem][voterIndex]] = false;
                } else {
                    ++numVoters[poolAddress][votingItem];
                }
                isInTopVoters[poolAddress][votingItem][msg.sender] = true;
                voters[poolAddress][votingItem][voterIndex] = msg.sender;
            }
        }
        voter2VotingValue[poolAddress][votingItem][msg.sender] = votingValue;
        emit Voted(poolAddress, msg.sender, votingItem, votingValue);
    }

    event EmergencyERC20Drain(address token, address governance, uint256 amount);

    // governance can drain tokens that are sent here by mistake
    function emergencyERC20Drain(ERC20 token, uint amount) external {
        require(msg.sender == governance, "!governance");
        emit EmergencyERC20Drain(address(token), governance, amount);
        token.transfer(governance, amount);
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}