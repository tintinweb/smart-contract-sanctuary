/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/interfaces/IOAXDEX_Governance.sol

// SPDX-License-Identifier: GPL-3.0-only
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


// File contracts/interfaces/IERC20.sol


pragma solidity =0.6.11;

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


// File contracts/libraries/Context.sol



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/libraries/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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


// File contracts/libraries/TransferHelper.sol


pragma solidity =0.6.11;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/OAXDEX_Governance.sol


pragma solidity =0.6.11;
contract OAXDEX_Governance is IOAXDEX_Governance, Ownable {
    using SafeMath for uint256;

    modifier onlyVoting() {
        require(isVotingExecutor[msg.sender], "OAXDEX: Not from voting");
        _; 
    }
    modifier onlyVotingRegistry() {
        require(msg.sender == votingRegister, "Governance: Not from votingRegistry");
        _; 
    }

    uint256 constant WEI = 10 ** 18;

    mapping (bytes32 => VotingConfig) public override votingConfigs;
	bytes32[] public override votingConfigProfiles;

    address public override oaxToken;
    mapping (address => NewStake) public override freezedStake;
    mapping (address => uint256) public override stakeOf;
    uint256 public override totalStake;

    address public override votingRegister;
    address[] public override votingExecutor;
    mapping (address => uint256) public override votingExecutorInv;
    mapping (address => bool) public override isVotingExecutor;
    address public override admin;
    uint256 public override minStakePeriod;

    uint256 public override voteCount;
    mapping (address => uint256) public override votingIdx;
    address[] public override votings;

    constructor(
        address _oaxToken, 
        bytes32[] memory _names,
        uint256[] memory _minExeDelay, 
        uint256[] memory _minVoteDuration, 
        uint256[] memory _maxVoteDuration, 
        uint256[] memory _minOaxTokenToCreateVote, 
        uint256[] memory _minQuorum,
        uint256 _minStakePeriod
    ) public {
        oaxToken = _oaxToken;

        require(_names.length == _minExeDelay.length && 
                _minExeDelay.length == _minVoteDuration.length && 
                _minVoteDuration.length == _maxVoteDuration.length && 
                _maxVoteDuration.length == _minOaxTokenToCreateVote.length && 
                _minOaxTokenToCreateVote.length == _minQuorum.length, "OAXDEX: Argument lengths not matched");
        for (uint256 i = 0 ; i < _names.length ; i++) {
            require(_minExeDelay[i] > 0 && _minExeDelay[i] <= 604800, "OAXDEX: Invalid minExeDelay");
            require(_minVoteDuration[i] < _maxVoteDuration[i] && _minVoteDuration[i] <= 604800, "OAXDEX: Invalid minVoteDuration");

            VotingConfig storage config = votingConfigs[_names[i]];
            config.minExeDelay = _minExeDelay[i];
            config.minVoteDuration = _minVoteDuration[i];
            config.maxVoteDuration = _maxVoteDuration[i];
            config.minOaxTokenToCreateVote = _minOaxTokenToCreateVote[i];
            config.minQuorum = _minQuorum[i];
			votingConfigProfiles.push(_names[i]);
            emit AddVotingConfig(_names[i], config.minExeDelay, config.minVoteDuration, config.maxVoteDuration, config.minOaxTokenToCreateVote, config.minQuorum);
        }

        require(_minStakePeriod > 0 && _minStakePeriod <= 2592000, "OAXDEX: Invalid minStakePeriod"); // max 30 days
        minStakePeriod = _minStakePeriod;

        emit ParamSet("minStakePeriod", bytes32(minStakePeriod));
    }


	function votingConfigProfilesLength() external view override returns(uint256) {
		return votingConfigProfiles.length;
	}
	function getVotingConfigProfiles(uint256 start, uint256 length) external view override returns(bytes32[] memory profiles) {
		if (start < votingConfigProfiles.length) {
            if (start.add(length) > votingConfigProfiles.length)
                length = votingConfigProfiles.length.sub(start);
            profiles = new bytes32[](length);
            for (uint256 i = 0 ; i < length ; i++) {
                profiles[i] = votingConfigProfiles[i.add(start)];
            }
        }
	}
    function getVotingParams(bytes32 name) external view override returns (uint256 _minExeDelay, uint256 _minVoteDuration, uint256 _maxVoteDuration, uint256 _minOaxTokenToCreateVote, uint256 _minQuorum) {
        VotingConfig storage config = votingConfigs[name];
        if (config.minOaxTokenToCreateVote == 0){
            config = votingConfigs["vote"];
        }
        return (config.minExeDelay, config.minVoteDuration, config.maxVoteDuration, config.minOaxTokenToCreateVote, config.minQuorum);
    }

    function setVotingRegister(address _votingRegister) external override onlyOwner {
        require(votingRegister == address(0), "OAXDEX: Already set");
        votingRegister = _votingRegister;
        emit ParamSet("votingRegister", bytes32(bytes20(votingRegister)));
    }    
    function votingExecutorLength() external view override returns (uint256) {
        return votingExecutor.length;
    }
    function initVotingExecutor(address[] calldata  _votingExecutor) external override onlyOwner {
        require(votingExecutor.length == 0, "OAXDEX: executor already set");
        uint256 length = _votingExecutor.length;
        for (uint256 i = 0 ; i < length ; i++) {
            _setVotingExecutor(_votingExecutor[i], true);
        }
    }
    function setVotingExecutor(address _votingExecutor, bool _bool) external override onlyVoting {
        _setVotingExecutor(_votingExecutor, _bool);
    }
    function _setVotingExecutor(address _votingExecutor, bool _bool) internal {
        require(_votingExecutor != address(0), "OAXDEX: Invalid executor");
        
        if (votingExecutor.length==0 || votingExecutor[votingExecutorInv[_votingExecutor]] != _votingExecutor) {
            votingExecutorInv[_votingExecutor] = votingExecutor.length; 
            votingExecutor.push(_votingExecutor);
        } else {
            require(votingExecutorInv[_votingExecutor] != 0, "OAXDEX: cannot reset main executor");
        }
        isVotingExecutor[_votingExecutor] = _bool;
        emit ParamSet2("votingExecutor", bytes32(bytes20(_votingExecutor)), bytes32(uint256(_bool ? 1 : 0)));
    }
    function initAdmin(address _admin) external override onlyOwner {
        require(admin == address(0), "OAXDEX: Already set");
        _setAdmin(_admin);
    }
    function setAdmin(address _admin) external override onlyVoting {
        _setAdmin(_admin);
    }
    function _setAdmin(address _admin) internal {
        require(_admin != address(0), "OAXDEX: Invalid admin");
        admin = _admin;
        emit ParamSet("admin", bytes32(bytes20(admin)));
    }
    function addVotingConfig(bytes32 name, uint256 minExeDelay, uint256 minVoteDuration, uint256 maxVoteDuration, uint256 minOaxTokenToCreateVote, uint256 minQuorum) external override onlyVoting {
        require(minExeDelay > 0 && minExeDelay <= 604800, "OAXDEX: Invalid minExeDelay");
        require(minVoteDuration < maxVoteDuration && minVoteDuration <= 604800, "OAXDEX: Invalid voteDuration");
        require(minOaxTokenToCreateVote <= totalStake, "OAXDEX: Invalid minOaxTokenToCreateVote");
        require(minQuorum <= totalStake, "OAXDEX: Invalid minQuorum");

        VotingConfig storage config = votingConfigs[name];
        require(config.minExeDelay == 0, "OAXDEX: Config already exists");

        config.minExeDelay = minExeDelay;
        config.minVoteDuration = minVoteDuration;
        config.maxVoteDuration = maxVoteDuration;
        config.minOaxTokenToCreateVote = minOaxTokenToCreateVote;
        config.minQuorum = minQuorum;
		votingConfigProfiles.push(name);
        emit AddVotingConfig(name, minExeDelay, minVoteDuration, maxVoteDuration, minOaxTokenToCreateVote, minQuorum);
    }
    function setVotingConfig(bytes32 configName, bytes32 paramName, uint256 paramValue) external override onlyVoting {
        require(votingConfigs[configName].minExeDelay > 0, "OAXDEX: Config not exists");
        if (paramName == "minExeDelay") {
            require(paramValue > 0 && paramValue <= 604800, "OAXDEX: Invalid minExeDelay");
            votingConfigs[configName].minExeDelay = paramValue;
        } else if (paramName == "minVoteDuration") {
            require(paramValue < votingConfigs[configName].maxVoteDuration && paramValue <= 604800, "OAXDEX: Invalid voteDuration");
            votingConfigs[configName].minVoteDuration = paramValue;
        } else if (paramName == "maxVoteDuration") {
            require(votingConfigs[configName].minVoteDuration < paramValue, "OAXDEX: Invalid voteDuration");
            votingConfigs[configName].maxVoteDuration = paramValue;
        } else if (paramName == "minOaxTokenToCreateVote") {
            require(paramValue <= totalStake, "OAXDEX: Invalid minOaxTokenToCreateVote");
            votingConfigs[configName].minOaxTokenToCreateVote = paramValue;
        } else if (paramName == "minQuorum") {
            require(paramValue <= totalStake, "OAXDEX: Invalid minQuorum");
            votingConfigs[configName].minQuorum = paramValue;
        }
        emit SetVotingConfig(configName, paramName, paramValue);
    }
    function setMinStakePeriod(uint _minStakePeriod) external override onlyVoting {
        require(_minStakePeriod > 0 && _minStakePeriod <= 2592000, "OAXDEX: Invalid minStakePeriod"); // max 30 days
        minStakePeriod = _minStakePeriod;
        emit ParamSet("minStakePeriod", bytes32(minStakePeriod));
    }

    function stake(uint256 value) external override {
        require(value <= IERC20(oaxToken).balanceOf(msg.sender), "Governance: insufficient balance");
        TransferHelper.safeTransferFrom(oaxToken, msg.sender, address(this), value);

        NewStake storage newStake = freezedStake[msg.sender];
        newStake.amount = newStake.amount.add(value);
        newStake.timestamp = block.timestamp;
    }
    function unlockStake() external override {
        NewStake storage newStake = freezedStake[msg.sender];
        require(newStake.amount > 0, "Governance: Nothing to stake");
        require(newStake.timestamp.add(minStakePeriod) < block.timestamp, "Governance: Freezed period not passed");
        uint256 value = newStake.amount;
        delete freezedStake[msg.sender];
        _stake(value);
    }
    function _stake(uint256 value) private {
        stakeOf[msg.sender] = stakeOf[msg.sender].add(value);
        totalStake = totalStake.add(value);
        updateWeight(msg.sender);
        emit Stake(msg.sender, value);
    }
    function unstake(uint256 value) external override {
        require(value <= stakeOf[msg.sender].add(freezedStake[msg.sender].amount), "Governance: unlock value exceed locked fund");
        if (value <= freezedStake[msg.sender].amount){
            freezedStake[msg.sender].amount = freezedStake[msg.sender].amount.sub(value);
        } else {
            uint256 value2 = value.sub(freezedStake[msg.sender].amount);
            delete freezedStake[msg.sender];
            stakeOf[msg.sender] = stakeOf[msg.sender].sub(value2);
            totalStake = totalStake.sub(value2);
            updateWeight(msg.sender);
            emit Unstake(msg.sender, value2);
        }
        TransferHelper.safeTransfer(oaxToken, msg.sender, value);
    }

    function allVotings() external view override returns (address[] memory) {
        return votings;
    }
    function getVotingCount() external view override returns (uint256) {
        return votings.length;
    }
    function getVotings(uint256 start, uint256 count) external view override returns (address[] memory _votings) {
        if (start.add(count) > votings.length) {
            count = votings.length - start;
        }
        _votings = new address[](count);
        uint256 j = start;
        for (uint256 i = 0; i < count ; i++) {
            _votings[i] = votings[j];
            j++;
        }
    }

    function isVotingContract(address votingContract) external view override returns (bool) {
        return votings[votingIdx[votingContract]] == votingContract;
    }

    function getNewVoteId() external override onlyVotingRegistry returns (uint256) {
        voteCount++;
        return voteCount;
    }

    function newVote(address vote, bool isExecutiveVote) external override onlyVotingRegistry {
        require(vote != address(0), "Governance: Invalid voting address");
        require(votings.length == 0 || votings[votingIdx[vote]] != vote, "Governance: Voting contract already exists");

        // close expired poll
        uint256 i = 0;
        while (i < votings.length) {
            IOAXDEX_VotingContract voting = IOAXDEX_VotingContract(votings[i]);
            if (voting.executeParam().length == 0 && voting.voteEndTime() < block.timestamp) {
                _closeVote(votings[i]);
            } else {
                i++;
            }
        }

        votingIdx[vote] = votings.length;
        votings.push(vote);
        if (isExecutiveVote){
            emit NewVote(vote);
        } else {
            emit NewPoll(vote);
        }
    }

    function voted(bool poll, address account, uint256 option) external override {
        require(votings[votingIdx[msg.sender]] == msg.sender, "Governance: Voting contract not exists");
        if (poll)
            emit Poll(account, msg.sender, option);
        else
            emit Vote(account, msg.sender, option);
    }

    function updateWeight(address account) private {
        for (uint256 i = 0; i < votings.length; i ++){
            IOAXDEX_VotingContract(votings[i]).updateWeight(account);
        }
    }

    function executed() external override {
        require(votings[votingIdx[msg.sender]] == msg.sender, "Governance: Voting contract not exists");
        _closeVote(msg.sender);
        emit Executed(msg.sender);
    }

    function veto(address voting) external override {
        require(msg.sender == admin, "OAXDEX: Not from shutdown admin");
        IOAXDEX_VotingContract(voting).veto();
        _closeVote(voting);
        emit Veto(voting);
    }

    function closeVote(address vote) external override {
        require(IOAXDEX_VotingContract(vote).executeParam().length == 0, "Governance: Not a Poll");
        require(block.timestamp > IOAXDEX_VotingContract(vote).voteEndTime(), "Governance: Voting not ended");
        _closeVote(vote);
    }
    function _closeVote(address vote) internal {
        uint256 idx = votingIdx[vote];
        require(idx > 0 || votings[0] == vote, "Governance: Voting contract not exists");
        if (idx < votings.length - 1) {
            votings[idx] = votings[votings.length - 1];
            votingIdx[votings[idx]] = idx;
        }
        votingIdx[vote] = 0;
        votings.pop();
    }
}