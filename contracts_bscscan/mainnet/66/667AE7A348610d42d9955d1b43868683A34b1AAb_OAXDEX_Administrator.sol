/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/interfaces/IOAXDEX_Administrator.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.6.11;

interface IOAXDEX_Administrator {

    event SetMaxAdmin(uint256 maxAdmin);
    event AddAdmin(address admin);
    event RemoveAdmin(address admin);

    event VotedVeto(address indexed admin, address indexed votingContract, bool YorN);
    event VotedFactoryShutdown(address indexed admin, address indexed factory, bool YorN);
    event VotedFactoryRestart(address indexed admin, address indexed factory, bool YorN);
    event VotedPairShutdown(address indexed admin, address indexed pair, bool YorN);
    event VotedPairRestart(address indexed admin, address indexed pair, bool YorN);

    function governance() external view returns (address);
    function allAdmins() external view returns (address[] memory);
    function maxAdmin() external view returns (uint256);
    function admins(uint256) external view returns (address);
    function adminsIdx(address) external view returns (uint256);

    function vetoVotingVote(address, address) external view returns (bool);
    function factoryShutdownVote(address, address) external view returns (bool);
    function factoryRestartVote(address, address) external view returns (bool);
    function pairShutdownVote(address, address) external view returns (bool);
    function pairRestartVote(address, address) external view returns (bool);

    function setMaxAdmin(uint256 _maxAdmin) external;
    function addAdmin(address _admin) external;
    function removeAdmin(address _admin) external;

    function vetoVoting(address votingContract, bool YorN) external;
    function getVetoVotingVote(address votingContract) external view returns (bool[] memory votes);
    function executeVetoVoting(address votingContract) external;

    function factoryShutdown(address factory, bool YorN) external;
    function getFactoryShutdownVote(address factory) external view returns (bool[] memory votes);
    function executeFactoryShutdown(address factory) external;
    function factoryRestart(address factory, bool YorN) external;
    function getFactoryRestartVote(address factory) external view returns (bool[] memory votes);
    function executeFactoryRestart(address factory) external;

    function pairShutdown(address pair, bool YorN) external;
    function getPairShutdownVote(address pair) external view returns (bool[] memory votes);
    function executePairShutdown(address factory, address pair) external;
    function pairRestart(address pair, bool YorN) external;
    function getPairRestartVote(address pair) external view returns (bool[] memory votes);
    function executePairRestart(address factory, address pair) external;
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


// File contracts/interfaces/IOAXDEX_PausableFactory.sol


pragma solidity =0.6.11;

interface IOAXDEX_PausableFactory {
    function isLive() external returns (bool);
    function setLive(bool _isLive) external;
    function setLiveForPair(address pair, bool live) external;
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


// File contracts/OAXDEX_Administrator.sol


pragma solidity =0.6.11;
contract OAXDEX_Administrator is IOAXDEX_Administrator {
    using SafeMath for uint256;

    modifier onlyVoting() {
        require(IOAXDEX_Governance(governance).isVotingExecutor(msg.sender), "OAXDEX: Not from voting");
        _; 
    }
    modifier onlyShutdownAdmin() {
        require(admins[adminsIdx[msg.sender]] == msg.sender, "Admin: Not a shutdown admin");
        _; 
    }

    address public override immutable governance;

    uint256 public override maxAdmin;
    address[] public override admins;
    mapping (address => uint256) public override adminsIdx;

    mapping (address => mapping (address => bool)) public override vetoVotingVote;
    mapping (address => mapping (address => bool)) public override factoryShutdownVote;
    mapping (address => mapping (address => bool)) public override factoryRestartVote;
    mapping (address => mapping (address => bool)) public override pairShutdownVote;
    mapping (address => mapping (address => bool)) public override pairRestartVote;
    
    constructor(address _governance) public {
        governance = _governance;
    }

    function allAdmins() external override view returns (address[] memory) {
        return admins;
    }

    function setMaxAdmin(uint256 _maxAdmin) external override onlyVoting {
        maxAdmin = _maxAdmin;
        emit SetMaxAdmin(maxAdmin);
    }
    function addAdmin(address _admin) external override onlyVoting {
        require(admins.length.add(1) <= maxAdmin, "OAXDEX: Max shutdown admin reached");
        require(_admin != address(0), "OAXDEX: INVALID_SHUTDOWN_ADMIN");
        require(admins.length == 0 || admins[adminsIdx[_admin]] != _admin, "OAXDEX: already a shutdown admin");
         adminsIdx[_admin] = admins.length;
        admins.push(_admin);
        emit AddAdmin(_admin);
    }
    function removeAdmin(address _admin) external override onlyVoting {
        uint256 idx = adminsIdx[_admin];
        require(idx > 0 || admins[0] == _admin, "Admin: Shutdown admin not exists");

        if (idx < admins.length - 1) {
            admins[idx] = admins[admins.length - 1];
            adminsIdx[admins[idx]] = idx;
        }
        adminsIdx[_admin] = 0;
        admins.pop();
        emit RemoveAdmin(_admin);
    }

    function getVote(mapping (address => bool) storage map) private view returns (bool[] memory votes) {
        uint length = admins.length;
        votes = new bool[](length);
        for (uint256 i = 0 ; i < length ; i++) {
            votes[i] = map[admins[i]];
        }
    }
    function checkVote(mapping (address => bool) storage map) private view returns (bool){
        uint256 count = 0;
        uint length = admins.length;
        uint256 quorum = length >> 1;
        for (uint256 i = 0 ; i < length ; i++) {
            if (map[admins[i]]) {
                count++;
                if (count > quorum) {
                    return true;
                }
            }
        }
        return false;
    }
    function clearVote(mapping (address => bool) storage map) private {
        uint length = admins.length;
        for (uint256 i = 0 ; i < length ; i++) {
            map[admins[i]] = false;
        }
    }

    function vetoVoting(address votingContract, bool YorN) external override onlyShutdownAdmin {
        vetoVotingVote[votingContract][msg.sender] = YorN;
        emit VotedVeto(msg.sender, votingContract, YorN);
    }
    function getVetoVotingVote(address votingContract) external override view returns (bool[] memory votes) {
        return getVote(vetoVotingVote[votingContract]);
    }
    function executeVetoVoting(address votingContract) external override {
        require(checkVote(vetoVotingVote[votingContract]), "Admin: executeVetoVoting: Quorum not met");
        IOAXDEX_Governance(governance).veto(votingContract);
        clearVote(vetoVotingVote[votingContract]);
    }

    function factoryShutdown(address factory, bool YorN) external override onlyShutdownAdmin {
        factoryShutdownVote[factory][msg.sender] = YorN;
        emit VotedFactoryShutdown(msg.sender, factory, YorN);
    }
    function getFactoryShutdownVote(address factory) external override view returns (bool[] memory votes) {
        return getVote(factoryShutdownVote[factory]);
    }
    function executeFactoryShutdown(address factory) external override {
        require(checkVote(factoryShutdownVote[factory]), "Admin: executeFactoryShutdown: Quorum not met");
        IOAXDEX_PausableFactory(factory).setLive(false);
        clearVote(factoryShutdownVote[factory]);
    }

    function factoryRestart(address factory, bool YorN) external override onlyShutdownAdmin {
        factoryRestartVote[factory][msg.sender] = YorN;
        emit VotedFactoryRestart(msg.sender, factory, YorN);
    }
    function getFactoryRestartVote(address factory) external override view returns (bool[] memory votes) {
        return getVote(factoryRestartVote[factory]);
    }
    function executeFactoryRestart(address factory) external override {
        require(checkVote(factoryRestartVote[factory]), "Admin: executeFactoryRestart: Quorum not met");
        IOAXDEX_PausableFactory(factory).setLive(true);
        clearVote(factoryRestartVote[factory]);
    }

    function pairShutdown(address pair, bool YorN) external override onlyShutdownAdmin {
        pairShutdownVote[pair][msg.sender] = YorN;
        emit VotedPairShutdown(msg.sender, pair, YorN);
    }
    function getPairShutdownVote(address pair) external override view returns (bool[] memory votes) {
        return getVote(pairShutdownVote[pair]);
    }
    function executePairShutdown(address factory, address pair) external override {
        require(checkVote(pairShutdownVote[pair]), "Admin: executePairShutdown: Quorum not met");
        IOAXDEX_PausableFactory(factory).setLiveForPair(pair, false);
        clearVote(pairShutdownVote[pair]);
    }

    function pairRestart(address pair, bool YorN) external override onlyShutdownAdmin {
        pairRestartVote[pair][msg.sender] = YorN;
        emit VotedPairRestart(msg.sender, pair, YorN);
    }
    function getPairRestartVote(address pair) external override view returns (bool[] memory votes) {
        return getVote(pairRestartVote[pair]);
    }
    function executePairRestart(address factory, address pair) external override {
        require(checkVote(pairRestartVote[pair]), "Admin: executePairRestart: Quorum not met");
        IOAXDEX_PausableFactory(factory).setLiveForPair(pair, true);
        clearVote(pairRestartVote[pair]);
    }
}