/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/interfaces/IOAXDEX_VotingRegistry.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.6.11;

interface IOAXDEX_VotingRegistry {
    function governance() external view returns (address);
    function newVote(address executor,
                        bytes32 name, 
                        bytes32[] calldata options, 
                        uint256 quorum, 
                        uint256 threshold, 
                        uint256 voteEndTime,
                        uint256 executeDelay, 
                        bytes32[] calldata executeParam
    ) external;
}


// File contracts/interfaces/IOAXDEX_Governance.sol


pragma solidity =0.6.11;

interface IOAXDEX_Governance {

    struct NewStake {
        uint256 amount;
        uint256 timestamp;
    }
    struct VotingConfig {
        uint256 minExeDelay;
        uint256 minVoteDuration;
        uint256 maxVoteDuration;
        uint256 minOaxTokenToCreateVote;
        uint256 minQuorum;
    }

    event ParamSet(bytes32 indexed name, bytes32 value);
    event ParamSet2(bytes32 name, bytes32 value1, bytes32 value2);
    event AddVotingConfig(bytes32 name, 
        uint256 minExeDelay,
        uint256 minVoteDuration,
        uint256 maxVoteDuration,
        uint256 minOaxTokenToCreateVote,
        uint256 minQuorum);
    event SetVotingConfig(bytes32 indexed configName, bytes32 indexed paramName, uint256 minExeDelay);

    event Stake(address indexed who, uint256 value);
    event Unstake(address indexed who, uint256 value);

    event NewVote(address indexed vote);
    event NewPoll(address indexed poll);
    event Vote(address indexed account, address indexed vote, uint256 option);
    event Poll(address indexed account, address indexed poll, uint256 option);
    event Executed(address indexed vote);
    event Veto(address indexed vote);

    function votingConfigs(bytes32) external view returns (uint256 minExeDelay,
        uint256 minVoteDuration,
        uint256 maxVoteDuration,
        uint256 minOaxTokenToCreateVote,
        uint256 minQuorum);
    function votingConfigProfiles(uint256) external view returns (bytes32);

    function oaxToken() external view returns (address);
    function freezedStake(address) external view returns (uint256 amount, uint256 timestamp);
    function stakeOf(address) external view returns (uint256);
    function totalStake() external view returns (uint256);

    function votingRegister() external view returns (address);
    function votingExecutor(uint256) external view returns (address);
    function votingExecutorInv(address) external view returns (uint256);
    function isVotingExecutor(address) external view returns (bool);
    function admin() external view returns (address);
    function minStakePeriod() external view returns (uint256);

    function voteCount() external view returns (uint256);
    function votingIdx(address) external view returns (uint256);
    function votings(uint256) external view returns (address);


	function votingConfigProfilesLength() external view returns(uint256);
	function getVotingConfigProfiles(uint256 start, uint256 length) external view returns(bytes32[] memory profiles);
    function getVotingParams(bytes32) external view returns (uint256 _minExeDelay, uint256 _minVoteDuration, uint256 _maxVoteDuration, uint256 _minOaxTokenToCreateVote, uint256 _minQuorum);

    function setVotingRegister(address _votingRegister) external;
    function votingExecutorLength() external view returns (uint256);
    function initVotingExecutor(address[] calldata _setVotingExecutor) external;
    function setVotingExecutor(address _setVotingExecutor, bool _bool) external;
    function initAdmin(address _admin) external;
    function setAdmin(address _admin) external;
    function addVotingConfig(bytes32 name, uint256 minExeDelay, uint256 minVoteDuration, uint256 maxVoteDuration, uint256 minOaxTokenToCreateVote, uint256 minQuorum) external;
    function setVotingConfig(bytes32 configName, bytes32 paramName, uint256 paramValue) external;
    function setMinStakePeriod(uint _minStakePeriod) external;

    function stake(uint256 value) external;
    function unlockStake() external;
    function unstake(uint256 value) external;
    function allVotings() external view returns (address[] memory);
    function getVotingCount() external view returns (uint256);
    function getVotings(uint256 start, uint256 count) external view returns (address[] memory _votings);

    function isVotingContract(address votingContract) external view returns (bool);

    function getNewVoteId() external returns (uint256);
    function newVote(address vote, bool isExecutiveVote) external;
    function voted(bool poll, address account, uint256 option) external;
    function executed() external;
    function veto(address voting) external;
    function closeVote(address vote) external;
}


// File contracts/interfaces/IOAXDEX_VotingContract.sol


pragma solidity =0.6.11;

interface IOAXDEX_VotingContract {

    function governance() external view returns (address);
    function executor() external view returns (address);

    function id() external view returns (uint256);
    function name() external view returns (bytes32);
    function _options(uint256) external view returns (bytes32);
    function quorum() external view returns (uint256);
    function threshold() external view returns (uint256);

    function voteStartTime() external view returns (uint256);
    function voteEndTime() external view returns (uint256);
    function executeDelay() external view returns (uint256);

    function executed() external view returns (bool);
    function vetoed() external view returns (bool);

    function accountVoteOption(address) external view returns (uint256);
    function accountVoteWeight(address) external view returns (uint256);

    function _optionsWeight(uint256) external view returns (uint256);
    function totalVoteWeight() external view returns (uint256);
    function totalWeight() external view returns (uint256);
    function _executeParam(uint256) external view returns (bytes32);

    function getParams() external view returns (
        address executor_,
        uint256 id_,
        bytes32 name_,
        bytes32[] memory options_,
        uint256 voteStartTime_,
        uint256 voteEndTime_,
        uint256 executeDelay_,
        bool[2] memory status_, // [executed, vetoed]
        uint256[] memory optionsWeight_,
        uint256[3] memory quorum_, // [quorum, threshold, totalWeight]
        bytes32[] memory executeParam_
    );

    function veto() external;
    function optionsCount() external view returns(uint256);
    function options() external view returns (bytes32[] memory);
    function optionsWeight() external view returns (uint256[] memory);
    function execute() external;
    function vote(uint256 option) external;
    function updateWeight(address account) external;
    function executeParam() external view returns (bytes32[] memory);
}


// File contracts/libraries/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

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


// File contracts/OAXDEX_VotingContract.sol


pragma solidity =0.6.11;
interface IOAXDEX_VotingExecutor {
    function execute(bytes32[] calldata params) external;
}

contract OAXDEX_VotingContract is IOAXDEX_VotingContract {
    using SafeMath for uint256;

    uint256 constant WEI = 10 ** 18;
    
    address public override governance;
    address public override executor;

    uint256 public override id;
    bytes32 public override name;
    bytes32[] public override _options;
    uint256 public override quorum;
    uint256 public override threshold;
    
    uint256 public override voteStartTime;
    uint256 public override voteEndTime;
    uint256 public override executeDelay;
    bool public override executed;
    bool public override vetoed;
    

    mapping (address => uint256) public override accountVoteOption;
    mapping (address => uint256) public override accountVoteWeight;
    uint256[] public override  _optionsWeight;
    uint256 public override totalVoteWeight;
    uint256 public override totalWeight;
    bytes32[] public override _executeParam;

    constructor(address governance_, 
                address executor_, 
                uint256 id_, 
                bytes32 name_, 
                bytes32[] memory options_, 
                uint256 quorum_, 
                uint256 threshold_, 
                uint256 voteEndTime_,
                uint256 executeDelay_, 
                bytes32[] memory executeParam_
               ) public {
        require(block.timestamp <= voteEndTime_, 'VotingContract: Voting already ended');
        if (executeParam_.length != 0){
            require(IOAXDEX_Governance(governance_).isVotingExecutor(executor_), "VotingContract: Invalid executor");
            require(options_.length == 2 && options_[0] == 'Y' && options_[1] == 'N', "VotingContract: Invalid options");
            require(threshold_ <= WEI, "VotingContract: Invalid threshold");
            require(executeDelay_ > 0, "VotingContract: Invalid execute delay");
        }
        governance = governance_;
        executor = executor_;
        totalWeight = IOAXDEX_Governance(governance).totalStake();
        id = id_;
        name = name_;
        _options = options_;
        quorum = quorum_;
        threshold = threshold_;
        _optionsWeight = new uint256[](options_.length);
        
        voteStartTime = block.timestamp;
        voteEndTime = voteEndTime_;
        executeDelay = executeDelay_;
        _executeParam = executeParam_;
    }
    function getParams() external view override returns (
        address executor_,
        uint256 id_,
        bytes32 name_,
        bytes32[] memory options_,
        uint256 voteStartTime_,
        uint256 voteEndTime_,
        uint256 executeDelay_,
        bool[2] memory status_, // [executed, vetoed]
        uint256[] memory optionsWeight_,
        uint256[3] memory quorum_, // [quorum, threshold, totalWeight]
        bytes32[] memory executeParam_
    ) {
        return (executor, id, name, _options, voteStartTime, voteEndTime, executeDelay, [executed, vetoed], _optionsWeight, [quorum, threshold, totalWeight], _executeParam);
    }
    function veto() external override {
        require(msg.sender == governance, 'OAXDEX_VotingContract: Not from Governance');
        require(!executed, 'OAXDEX_VotingContract: Already executed');
        vetoed = true;
    }
    function optionsCount() external view override returns(uint256){
        return _options.length;
    }
    function options() external view override returns (bytes32[] memory){
        return _options;
    }
    function optionsWeight() external view override returns (uint256[] memory){
        return _optionsWeight;
    }
    function execute() external override {
        require(block.timestamp > voteEndTime.add(executeDelay), "VotingContract: Execute delay not past yet");
        require(!vetoed, 'VotingContract: Vote already vetoed');
        require(!executed, 'VotingContract: Vote already executed');
        require(_executeParam.length != 0, 'VotingContract: Execute param not defined');

        require(totalVoteWeight >= quorum, 'VotingContract: Quorum not met');
        require(_optionsWeight[0] > _optionsWeight[1], "VotingContract: Majority not met"); // 0: Y, 1:N
        require(_optionsWeight[0].mul(WEI) > totalVoteWeight.mul(threshold), "VotingContract: Threshold not met");
        executed = true;
        IOAXDEX_VotingExecutor(executor).execute(_executeParam);
        IOAXDEX_Governance(governance).executed();
    }
    function vote(uint256 option) external override {
        require(block.timestamp <= voteEndTime, 'VotingContract: Vote already ended');
        require(!vetoed, 'VotingContract: Vote already vetoed');
        require(!executed, 'VotingContract: Vote already executed');
        require(option < _options.length, 'VotingContract: Invalid option');

        IOAXDEX_Governance(governance).voted(_executeParam.length == 0, msg.sender, option);

        uint256 currVoteWeight = accountVoteWeight[msg.sender];
        if (currVoteWeight > 0){
            uint256 currVoteIdx = accountVoteOption[msg.sender];    
            _optionsWeight[currVoteIdx] = _optionsWeight[currVoteIdx].sub(currVoteWeight);
            totalVoteWeight = totalVoteWeight.sub(currVoteWeight);
        }
        
        uint256 weight = IOAXDEX_Governance(governance).stakeOf(msg.sender);
        require(weight > 0, "VotingContract: Not staked to vote");
        accountVoteOption[msg.sender] = option;
        accountVoteWeight[msg.sender] = weight;
        _optionsWeight[option] = _optionsWeight[option].add(weight);
        totalVoteWeight = totalVoteWeight.add(weight);

        totalWeight = IOAXDEX_Governance(governance).totalStake();
    }
    function updateWeight(address account) external override {
        // use if-cause and don't use requrie() here to avoid revert as Governance is looping through all votings
        if (block.timestamp <= voteEndTime && !vetoed && !executed){
            uint256 weight = IOAXDEX_Governance(governance).stakeOf(account);
            uint256 currVoteWeight = accountVoteWeight[account];
            if (currVoteWeight > 0 && currVoteWeight != weight){
                uint256 currVoteIdx = accountVoteOption[account];
                accountVoteWeight[account] = weight;
                _optionsWeight[currVoteIdx] = _optionsWeight[currVoteIdx].sub(currVoteWeight).add(weight);
                totalVoteWeight = totalVoteWeight.sub(currVoteWeight).add(weight);
            }
            totalWeight = IOAXDEX_Governance(governance).totalStake();
        }
    }
    function executeParam() external view override returns (bytes32[] memory){
        return _executeParam;
    }
}


// File contracts/OAXDEX_VotingRegistry.sol


pragma solidity =0.6.11;
contract OAXDEX_VotingRegistry is IOAXDEX_VotingRegistry {
    using SafeMath for uint256;

    address public override governance;

    constructor(address _governance) public {
        governance = _governance;
    }

    function newVote(address executor,
                     bytes32 name, 
                     bytes32[] calldata options, 
                     uint256 quorum, 
                     uint256 threshold, 
                     uint256 voteEndTime,
                     uint256 executeDelay, 
                     bytes32[] calldata executeParam
    ) external override {
        bool isExecutiveVote = executeParam.length != 0;
        {
        require(IOAXDEX_Governance(governance).isVotingExecutor(executor), "OAXDEX_VotingRegistry: Invalid executor");
        bytes32 configName = isExecutiveVote ? executeParam[0] : bytes32("poll");
        (uint256 minExeDelay, uint256 minVoteDuration, uint256 maxVoteDuration, uint256 minOaxTokenToCreateVote, uint256 minQuorum) = IOAXDEX_Governance(governance).getVotingParams(configName);
        uint256 staked = IOAXDEX_Governance(governance).stakeOf(msg.sender);
        require(staked >= minOaxTokenToCreateVote, "OAXDEX_VotingRegistry: minOaxTokenToCreateVote not met");
        require(voteEndTime.sub(block.timestamp) >= minVoteDuration, "OAXDEX_VotingRegistry: minVoteDuration not met");
        require(voteEndTime.sub(block.timestamp) <= maxVoteDuration, "OAXDEX_VotingRegistry: exceeded maxVoteDuration");
        if (isExecutiveVote) {
            require(quorum >= minQuorum, "OAXDEX_VotingRegistry: minQuorum not met");
            require(executeDelay >= minExeDelay, "OAXDEX_VotingRegistry: minExeDelay not met");
        }
        }

        uint256 id = IOAXDEX_Governance(governance).getNewVoteId();
        OAXDEX_VotingContract voting = new OAXDEX_VotingContract(governance, executor, id, name, options, quorum, threshold, voteEndTime, executeDelay, executeParam);
        IOAXDEX_Governance(governance).newVote(address(voting), isExecutiveVote);
    }
}