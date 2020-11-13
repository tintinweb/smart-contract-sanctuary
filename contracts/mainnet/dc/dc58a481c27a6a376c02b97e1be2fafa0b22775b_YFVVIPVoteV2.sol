// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity 0.5.17;

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

interface IYFVRewards {
    function stakingPower(address account) external view returns (uint256);
}

contract YFVVIPVoteV2 {
    using SafeMath for uint256;

    uint8 public constant MAX_VOTERS_PER_ITEM = 200;
    uint256 public constant POOL_REWARD_SUPPLY_INFLATION_RATE_VOTE_ITEM = 10000;
    uint256 public constant VIP_3_VOTE_ITEM = 3;

    mapping(address => mapping(uint256 => uint8)) public numVoters; // poolAddress -> votingItem (periodFinish) -> numVoters (the number of voters in this round)
    mapping(address => mapping(uint256 => address[MAX_VOTERS_PER_ITEM])) public voters; // poolAddress -> votingItem (periodFinish) -> voters (array)
    mapping(address => mapping(uint256 => mapping(address => bool))) public isInTopVoters; // poolAddress -> votingItem (periodFinish) -> isInTopVoters (map: voter -> in_top (true/false))
    mapping(address => mapping(uint256 => mapping(address => uint64))) public voter2VotingValue; // poolAddress -> votingItem (periodFinish) -> voter2VotingValue (map: voter -> voting value)

    mapping(address => mapping(uint256 => uint64)) public votingValueMinimums; // poolAddress -> votingItem (proposalId) -> votingValueMin
    mapping(address => mapping(uint256 => uint64)) public votingValueMaximums; // poolAddress -> votingItem (proposalId) -> votingValueMax

    mapping(address => mapping(uint256 => uint256)) public votingStarttimes; // poolAddress -> votingItem (proposalId) -> voting's starttime
    mapping(address => mapping(uint256 => uint256)) public votingEndtimes; // poolAddress -> votingItem (proposalId) -> voting's endtime

    mapping(address => uint8) poolVotingValueLeftBitRanges; // poolAddress -> left bit range
    mapping(address => uint8) poolVotingValueRightBitRanges; // poolAddress -> right bit range

    address public stakeGovernancePool = 0xD120f23438AC0edbBA2c4c072739387aaa70277a; // Stake Pool v2

    address public governance;
    address public operator; // help to replace weak voter by higher power one

    event Voted(address poolAddress, address indexed user, uint256 votingItem, uint64 votingValue);

    constructor () public {
        governance = msg.sender;
        operator = msg.sender;
        // BAL Pool
        poolVotingValueLeftBitRanges[0x62a9fE913eb596C8faC0936fd2F51064022ba22e] = 5;
        poolVotingValueRightBitRanges[0x62a9fE913eb596C8faC0936fd2F51064022ba22e] = 0;
        // YFI Pool
        poolVotingValueLeftBitRanges[0x70b83A7f5E83B3698d136887253E0bf426C9A117] = 10;
        poolVotingValueRightBitRanges[0x70b83A7f5E83B3698d136887253E0bf426C9A117] = 5;
        // BAT Pool
        poolVotingValueLeftBitRanges[0x1c990fC37F399C935625b815975D0c9fAD5C31A1] = 15;
        poolVotingValueRightBitRanges[0x1c990fC37F399C935625b815975D0c9fAD5C31A1] = 10;
        // REN Pool
        poolVotingValueLeftBitRanges[0x752037bfEf024Bd2669227BF9068cb22840174B0] = 20;
        poolVotingValueRightBitRanges[0x752037bfEf024Bd2669227BF9068cb22840174B0] = 15;
        // KNC Pool
        poolVotingValueLeftBitRanges[0x9b74774f55C0351fD064CfdfFd35dB002C433092] = 25;
        poolVotingValueRightBitRanges[0x9b74774f55C0351fD064CfdfFd35dB002C433092] = 20;
        // BTC Pool
        poolVotingValueLeftBitRanges[0xFBDE07329FFc9Ec1b70f639ad388B94532b5E063] = 30;
        poolVotingValueRightBitRanges[0xFBDE07329FFc9Ec1b70f639ad388B94532b5E063] = 25;
        // WETH Pool
        poolVotingValueLeftBitRanges[0x67FfB615EAEb8aA88fF37cCa6A32e322286a42bb] = 35;
        poolVotingValueRightBitRanges[0x67FfB615EAEb8aA88fF37cCa6A32e322286a42bb] = 30;
        // LINK Pool
        poolVotingValueLeftBitRanges[0x196CF719251579cBc850dED0e47e972b3d7810Cd] = 40;
        poolVotingValueRightBitRanges[0x196CF719251579cBc850dED0e47e972b3d7810Cd] = 35;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setOperator(address _operator) public {
        require(msg.sender == governance, "!governance");
        operator = _operator;
    }

    function setVotingConfig(address poolAddress, uint256 votingItem, uint64 minValue, uint64 maxValue, uint256 starttime, uint256 endtime) public {
        require(msg.sender == governance, "!governance");
        require(minValue < maxValue, "Invalid voting range");
        require(starttime < endtime, "Invalid time range");
        require(endtime > block.timestamp, "Endtime has passed");
        votingValueMinimums[poolAddress][votingItem] = minValue;
        votingValueMaximums[poolAddress][votingItem] = maxValue;
        votingStarttimes[poolAddress][votingItem] = starttime;
        votingEndtimes[poolAddress][votingItem] = endtime;
    }

    function setStakeGovernancePool(address _stakeGovernancePool) public {
        require(msg.sender == governance, "!governance");
        stakeGovernancePool = _stakeGovernancePool;
    }

    function setPoolVotingValueBitRanges(address poolAddress, uint8 leftBitRange, uint8 rightBitRange) public {
        require(msg.sender == governance, "!governance");
        poolVotingValueLeftBitRanges[poolAddress] = leftBitRange;
        poolVotingValueRightBitRanges[poolAddress] = rightBitRange;
    }

    function isVotable(address poolAddress, address account, uint256 votingItem) public view returns (bool) {
        if (block.timestamp < votingStarttimes[poolAddress][votingItem]) return false; // vote is not open yet
        if (block.timestamp > votingEndtimes[poolAddress][votingItem]) return false; // vote is closed

        IYFVRewards rewards = IYFVRewards(poolAddress);
        // hasn't any staking power
        if (rewards.stakingPower(account) == 0) return false;

        // number of voters is under limit still
        if (numVoters[poolAddress][votingItem] < MAX_VOTERS_PER_ITEM) return true;
        return false;
    }

    // for VIP: multiply by 100 for more precise
    function averageVotingValueX100(address poolAddress, uint256 votingItem) public view returns (uint64) {
        if (numVoters[poolAddress][votingItem] == 0) return 0; // no votes
        uint256 totalStakingPower = 0;
        uint256 totalWeightedVotingValue = 0;
        IYFVRewards rewards = IYFVRewards(poolAddress);
        for (uint8 i = 0; i < numVoters[poolAddress][votingItem]; i++) {
            address voter = voters[poolAddress][votingItem][i];
            totalStakingPower = totalStakingPower.add(rewards.stakingPower(voter));
            totalWeightedVotingValue = totalWeightedVotingValue.add(rewards.stakingPower(voter).mul(voter2VotingValue[poolAddress][votingItem][voter]));
        }
        return (uint64) (totalWeightedVotingValue.mul(100).div(totalStakingPower));
    }

    // multiply by 100 for more precise
    function averageVotingValueByBitsX100(address poolAddress, uint256 votingItem, uint8 leftBitRange, uint8 rightBitRange) public view returns (uint64) {
        if (numVoters[poolAddress][votingItem] == 0) return 0; // no votes
        uint256 totalStakingPower = 0;
        uint256 totalWeightedVotingValue = 0;
        IYFVRewards rewards = IYFVRewards(poolAddress);
        uint64 bitmask = (uint64(1) << (leftBitRange - rightBitRange)) - 1;
        for (uint8 i = 0; i < numVoters[poolAddress][votingItem]; i++) {
            address voter = voters[poolAddress][votingItem][i];
            totalStakingPower = totalStakingPower.add(rewards.stakingPower(voter));
            uint64 votingValueByBits = (voter2VotingValue[poolAddress][votingItem][voter] >> rightBitRange) & bitmask;
            totalWeightedVotingValue = totalWeightedVotingValue.add(rewards.stakingPower(voter).mul(votingValueByBits));
        }
        return (uint64) (totalWeightedVotingValue.mul(100).div(totalStakingPower));
    }

    function verifyOfflineVote(address poolAddress, uint256 votingItem, uint64 votingValue, uint256 timestamp, address voter, uint8 v, bytes32 r, bytes32 s) public pure returns (bool) {
        bytes32 signatureHash = keccak256(abi.encodePacked(voter, poolAddress, votingItem, votingValue, timestamp));
        return voter == ecrecover(signatureHash, v, r, s);
    }

    // if more than 200 voters participate, we may need to replace a weak (low power) voter by a stronger (high power) one
    function replaceVoter(address poolAddress, uint256 votingItem, uint8 voterIndex, address newVoter) public {
        require(msg.sender == governance || msg.sender == operator, "!governance && !operator");
        require(numVoters[poolAddress][votingItem] > voterIndex, "index is out of range");
        require(!isInTopVoters[poolAddress][votingItem][newVoter], "newVoter is in the list already");
        IYFVRewards rewards = IYFVRewards(poolAddress);
        address currentVoter = voters[poolAddress][votingItem][voterIndex];
        require(rewards.stakingPower(currentVoter) < rewards.stakingPower(newVoter), "newVoter does not have high power than currentVoter");
        isInTopVoters[poolAddress][votingItem][currentVoter] = false;
        isInTopVoters[poolAddress][votingItem][newVoter] = true;
        voters[poolAddress][votingItem][voterIndex] = newVoter;
    }

    function vote(address poolAddress, uint256 votingItem, uint64 votingValue) public {
        require(block.timestamp >= votingStarttimes[poolAddress][votingItem], "voting is not open yet");
        require(block.timestamp <= votingEndtimes[poolAddress][votingItem], "voting is closed");
        if (votingValueMinimums[poolAddress][votingItem] > 0 || votingValueMaximums[poolAddress][votingItem] > 0) {
            require(votingValue >= votingValueMinimums[poolAddress][votingItem], "votingValue is smaller than minimum accepted value");
            require(votingValue <= votingValueMaximums[poolAddress][votingItem], "votingValue is greater than maximum accepted value");
        }

        if (!isInTopVoters[poolAddress][votingItem][msg.sender]) {
            require(isVotable(poolAddress, msg.sender, votingItem), "This account is not votable");
            if (numVoters[poolAddress][votingItem] < MAX_VOTERS_PER_ITEM) {
                isInTopVoters[poolAddress][votingItem][msg.sender] = true;
                voters[poolAddress][votingItem][numVoters[poolAddress][votingItem]] = msg.sender;
                ++numVoters[poolAddress][votingItem];
            }
        }
        voter2VotingValue[poolAddress][votingItem][msg.sender] = votingValue;
        emit Voted(poolAddress, msg.sender, votingItem, votingValue);
    }

    function averageVotingValue(address poolAddress, uint256) public view returns (uint16) {
        uint8 numInflationVoters = numVoters[stakeGovernancePool][POOL_REWARD_SUPPLY_INFLATION_RATE_VOTE_ITEM];
        if (numInflationVoters == 0) return 0; // no votes

        uint8 leftBitRange = poolVotingValueLeftBitRanges[poolAddress];
        uint8 rightBitRange = poolVotingValueRightBitRanges[poolAddress];
        if (leftBitRange == 0 && rightBitRange == 0) return 0; // we dont know about this pool
        // empowerment Factor (every 100 is 5%) (slider 0% - 5% - 10% - .... - 80%)
        uint64 empowermentFactor = averageVotingValueByBitsX100(stakeGovernancePool, VIP_3_VOTE_ITEM, leftBitRange, rightBitRange) / 20;
        if (empowermentFactor > 80) empowermentFactor = 80; // minimum 0% -> maximum 80%
        uint64 farmingFactor = 100 - empowermentFactor; // minimum 20% -> maximum 100%

        uint256 totalFarmingPower = 0;
        uint256 totalStakingPower = 0;
        uint256 totalWeightedFarmingVotingValue = 0;
        uint256 totalWeightedStakingVotingValue = 0;
        IYFVRewards farmingPool = IYFVRewards(poolAddress);
        IYFVRewards stakingPool = IYFVRewards(stakeGovernancePool);
        uint64 bitmask = (uint64(1) << (leftBitRange - rightBitRange)) - 1;
        for (uint8 i = 0; i < numInflationVoters; i++) {
            address voter = voters[stakeGovernancePool][POOL_REWARD_SUPPLY_INFLATION_RATE_VOTE_ITEM][i];
            totalFarmingPower = totalFarmingPower.add(farmingPool.stakingPower(voter));
            totalStakingPower = totalStakingPower.add(stakingPool.stakingPower(voter));
            uint64 votingValueByBits = (voter2VotingValue[stakeGovernancePool][POOL_REWARD_SUPPLY_INFLATION_RATE_VOTE_ITEM][voter] >> rightBitRange) & bitmask;
            totalWeightedFarmingVotingValue = totalWeightedFarmingVotingValue.add(farmingPool.stakingPower(voter).mul(votingValueByBits));
            totalWeightedStakingVotingValue = totalWeightedStakingVotingValue.add(stakingPool.stakingPower(voter).mul(votingValueByBits));
        }
        uint64 farmingAvgValue = (uint64) (totalWeightedFarmingVotingValue.mul(farmingFactor).div(totalFarmingPower));
        uint64 stakingAvgValue = (uint64) (totalWeightedStakingVotingValue.mul(empowermentFactor).div(totalStakingPower));
        uint16 avgValue = (uint16) ((farmingAvgValue + stakingAvgValue) / 100);
        // 0 -> x0.2, 1 -> x0.25, ..., 20 -> x1.20
        if (avgValue > 20) return 120;
        return 20 + avgValue * 5;
    }

    function votingValueGovernance(address poolAddress, uint256 votingItem, uint16) public view returns (uint16) {
        return averageVotingValue(poolAddress, votingItem);
    }

    // governance can drain tokens that are sent here by mistake
    function emergencyERC20Drain(ERC20 token, uint amount) external {
        require(msg.sender == governance, "!governance");
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