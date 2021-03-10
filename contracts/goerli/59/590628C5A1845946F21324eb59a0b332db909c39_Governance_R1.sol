// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.11;

import "./Governable.sol";

contract Config is Governable {

    event ConfigSet(bytes32 config, uint256 value);

    mapping (bytes32 => uint256) private _config;

    function initialize() external initializer {
        super.initialize(msg.sender);
         setConfig("PROVIDER_MINIMUM_ANKR_STAKING", 100000 ether);
         setConfig("PROVIDER_MINIMUM_ETH_STAKING", 2 ether);
         setConfig("REQUESTER_MINIMUM_POOL_STAKING", 500 finney);
         setConfig("EXIT_BLOCKS", 24);
    }

    function setConfig(bytes32 config, uint256 value) public governance {
        _config[config] = value;
    }

    function getConfig(bytes32 config) public view returns(uint256) {
        return _config[config];
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

contract Governable is Initializable {
    address public governor;

    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev Contract initializer.
     * called once by the factory at time of deployment
     */
    function initialize(address governor_) virtual public initializer {
        governor = governor_;
        emit GovernorshipTransferred(address(0), governor);
    }

    modifier governance() {
        require(msg.sender == governor);
        _;
    }

    /**
     * @dev Allows the current governor to relinquish control of the contract.
     * @notice Renouncing to governorship will leave the contract without an governor.
     * It will not be possible to call the functions with the `governance.js`
     * modifier anymore.
     */
    function renounceGovernorship() public governance {
        emit GovernorshipTransferred(governor, address(0));
        governor = address(0);
    }

    /**
     * @dev Allows the current governor to transfer control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function transferGovernorship(address newGovernor) public governance {
        _transferGovernorship(newGovernor);
    }

    /**
     * @dev Transfers control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function _transferGovernorship(address newGovernor) internal {
        require(newGovernor != address(0));
        emit GovernorshipTransferred(governor, newGovernor);
        governor = newGovernor;
    }

    uint256[50] private __gap;
}

pragma solidity ^0.6.11;

contract Configurable {
    mapping (bytes32 => uint) internal config;

    mapping (bytes32 => string) internal configString;

    mapping (bytes32 => address) internal configAddress;

    function getConfig(bytes32 key) public view returns (uint) {
        return config[key];
    }
    function getConfig(bytes32 key, uint index) public view returns (uint) {
        return config[bytes32(uint(key) ^ index)];
    }
    function getConfig(bytes32 key, address addr) public view returns (uint) {
        return config[bytes32(uint(key) ^ uint(addr))];
    }

    function _setConfig(bytes32 key, uint value) internal {
        if(config[key] != value)
            config[key] = value;
    }
    function _setConfig(bytes32 key, uint index, uint value) internal {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function _setConfig(bytes32 key, address addr, uint value) internal {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }

    function setConfig(bytes32 key, uint value) internal {
        _setConfig(key, value);
    }
    function setConfig(bytes32 key, uint index, uint value) internal {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function setConfig(bytes32 key, address addr, uint value) internal {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
    function getConfigString(bytes32 key) public view returns (string memory) {
        return configString[key];
    }
    function getConfigString(bytes32 key, uint index) public view returns (string memory) {
        return configString[bytes32(uint(key) ^ index)];
    }
    function setConfigString(bytes32 key, string memory value) internal {
        configString[key] = value;
    }
    function setConfigString(bytes32 key, uint index, string memory value) internal {
        setConfigString(bytes32(uint(key) ^ index), value);
    }

    function getConfigAddress(bytes32 key) public view returns (address) {
        return configAddress[key];
    }

    function getConfigAddress(bytes32 key, uint index) public view returns (address) {
        return configAddress[bytes32(uint(key) ^ index)];
    }

    function setConfigAddress(bytes32 key, address addr) internal {
        configAddress[key] = addr;
    }

    function setConfigAddress(bytes32 key, uint index, address addr) internal {
        setConfigAddress(bytes32(uint(key) ^ index), addr);
    }
}

pragma solidity ^0.6.11;

abstract contract Lockable {
    mapping(address => bool) private _locks;

    modifier unlocked(address addr) {
        require(!_locks[addr], "Reentrancy protection");
        _locks[addr] = true;
        _;
        _locks[addr] = false;
    }

    uint256[50] private __gap;
}

pragma solidity 0.6.11;
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

contract Pausable is  OwnableUpgradeSafe {
    mapping (bytes32 => bool) internal _paused;

    modifier whenNotPaused(bytes32 action) {
        require(!_paused[action], "This action currently paused");
        _;
    }

    function togglePause(bytes32 action) public onlyOwner {
        _paused[action] = !_paused[action];
    }

    function isPaused(bytes32 action) public view returns(bool) {
        return _paused[action];
    }

    uint256[50] private __gap;
}

pragma solidity ^0.6.11;
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

interface IAETH is IERC20 {
    function burn(uint256 amount) external;

    function updateMicroPoolContract(address microPoolContract) external;

    function ratio() external returns (uint256);

    function mintFrozen(address account, uint256 amount) external;

    function mint(address account, uint256 amount) external returns(uint256);

    function mintPool() payable external;

    function fundPool(uint256 poolIndex, uint256 amount) external;
}

pragma solidity ^0.6.11;

interface IConfig {
    function getConfig(bytes32 config) external view returns (uint256);

    function setConfig(bytes32 config, uint256 value) external;
}

pragma solidity ^0.6.11;

interface IMarketPlace {
    function ethUsdRate() external returns (uint256);

    function ankrEthRate() external returns (uint256);

    function burnAeth(uint256 etherAmount) external returns (uint256);
}

pragma solidity ^0.6.11;

interface IStaking {
    function compensateLoss(address provider, uint256 ethAmount) external returns (bool, uint256, uint256);

    function freeze(address user, uint256 amount) external returns (bool);

    function unfreeze(address user, uint256 amount) external returns (bool);

    function frozenStakesOf(address staker) external view returns (uint256);

    function stakesOf(address staker) external view returns (uint256);

    function frozenDepositsOf(address staker) external view returns (uint256);

    function depositsOf(address staker) external view returns (uint256);

    function deposit() external;

    function deposit(address user) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.11;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "../lib/Lockable.sol";
import "../lib/interfaces/IAETH.sol";
import "../lib/interfaces/IMarketPlace.sol";
import "../lib/Configurable.sol";

contract AnkrDeposit_R1 is OwnableUpgradeSafe, Lockable, Configurable {
    using SafeMath for uint256;

    event Deposit(
        address indexed user,
        uint256 value
    );

    // if ends at value is zero,
    event Freeze(
        address indexed user,
        uint256 value,
        uint256 endsAt
    );

    event Unfreeze(
        address indexed user,
        uint256 value
    );

    event Withdraw(
        address indexed user,
        uint256 value
    );

    event Compensate(address indexed provider, uint256 ankrAmount, uint256 etherAmount);

    IAETH private _AETHContract;

    IMarketPlace _marketPlaceContract;

    IERC20 private _ankrContract;

    address private _globalPoolContract;

    address _governanceContract;

    address _operator;

    mapping (address => uint256[]) public _userLocks;

    bytes32 constant _deposit_ = "AnkrDeposit#Deposit";

    bytes32 constant _freeze_ = "AnkrDeposit#Freeze";
    bytes32 constant _unfreeze_ = "AnkrDeposit#Unfreeze";
    bytes32 constant _lockTotal_ = "AnkrDeposit#LockTotal";
    bytes32 constant _lockEndsAt_ = "AnkrDeposit#LockEndsAt";
    bytes32 constant _lockAmount_ = "AnkrDeposit#LockAmount";
    bytes32 constant _lockID_ = "AnkrDeposit#LockID";

    bytes32 constant _allowed_ = "AnkrDeposit#Allowed";


    function deposit_init(address ankrContract, address globalPoolContract, address aethContract) internal initializer {
        OwnableUpgradeSafe.__Ownable_init();

        _ankrContract = IERC20(ankrContract);
        _globalPoolContract = globalPoolContract;
        _AETHContract = IAETH(aethContract);
        allowAddressForFunction(globalPoolContract, _unfreeze_);
        allowAddressForFunction(globalPoolContract, _freeze_);
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Ankr Deposit#onlyOperator: not allowed");
        _;
    }

    modifier addressAllowed(address addr, bytes32 topic) {
        require(getConfig(_allowed_ ^ topic, addr) > 0, "Ankr Deposit#addressAllowed: You are not allowed to run this function");
        _;
    }

    function deposit() public unlocked(msg.sender) returns (uint256) {
        return _claimAndDeposit(msg.sender);
    }

    function deposit(address user) public unlocked(user) returns (uint256) {
        return _claimAndDeposit(user);
    }
    /*
        This function used to deposit ankr with transferFrom
    */
    function _claimAndDeposit(address user) private returns (uint256) {
        address ths = address(this);
        uint256 allowance = _ankrContract.allowance(user, ths);

        if (allowance == 0) {
            return 0;
        }

        _ankrContract.transferFrom(user, ths, allowance);

        setConfig(_deposit_, user, depositsOf(user).add(allowance));

        cleanUserLocks(user);

        emit Deposit(user, allowance);

        return allowance;
    }

    function withdraw(uint256 amount) public unlocked(msg.sender) returns (bool) {
        address sender = msg.sender;
        uint256 available = availableDepositsOf(sender);

        require(available >= amount, "Ankr Deposit#withdraw: You dont have available deposit balance");

        setConfig(_deposit_, sender, depositsOf(sender).sub(amount));

        _transferToken(sender, amount);

        cleanUserLocks(sender);

        emit Withdraw(sender, amount);

        return true;
    }

    function _unfreeze(address addr, uint256 amount)
    internal
    returns (bool)
    {
        setConfig(_freeze_, addr, _frozenDeposits(addr).sub(amount, "Ankr Deposit#_unfreeze: Insufficient funds"));
        cleanUserLocks(addr);
        emit Unfreeze(addr, amount);
        return true;
    }

    function _freeze(address addr, uint256 amount)
    internal
    returns (bool)
    {
        _claimAndDeposit(addr);

        require(depositsOf(addr) >= amount, "Ankr Deposit#_freeze: You dont have enough amount to freeze ankr");
        setConfig(_freeze_, addr, _frozenDeposits(addr).add(amount));

        cleanUserLocks(addr);

        emit Freeze(addr, amount, 0);
        return true;
    }

    function unfreeze(address addr, uint256 amount)
    public
    addressAllowed(_globalPoolContract, _unfreeze_)
    returns (bool)
    {
        return _unfreeze(addr, amount);
    }

    function freeze(address addr, uint256 amount)
    public
    addressAllowed(_globalPoolContract, _freeze_)
    returns (bool)
    {
        return _freeze(addr, amount);
    }

    function availableDepositsOf(address user) public view returns (uint256) {
        return depositsOf(user).sub(frozenDepositsOf(user));
    }

    function depositsOf(address user) public view returns (uint256) {
        return getConfig(_deposit_, user);
    }

    function frozenDepositsOf(address user) public view returns (uint256) {
        return _frozenDeposits(user).add(lockedDepositsOf(user));
    }

    function _frozenDeposits(address user) internal view returns(uint256) {
        return getConfig(_freeze_, user);
    }

    function lockedDepositsOf(address user) public view returns(uint256) {
        return getConfig(_lockTotal_, user).sub(availableAmountForUnlock(user));
    }

    function _transferToken(address to, uint256 amount) internal {
        require(_ankrContract.transfer(to, amount), "Failed token transfer");
    }

    function allowAddressForFunction(address addr, bytes32 topic) public onlyOperator {
        setConfig(_allowed_ ^ topic, addr, 1);
    }

    function _addNewLockToUser(address user, uint256 amount, uint256 endsAt, uint256 lockId) internal {
        uint256 deposits = depositsOf(user);
        uint256 lockedDeposits = lockedDepositsOf(user);
        if (amount <= lockedDeposits) {
            return;
        }
        amount = amount.sub(lockedDeposits);
        require(amount <= deposits, "Ankr Deposit#_addNewLockToUser: Insufficient funds");

        require(getConfig(_lockEndsAt_, lockId) == 0, "Ankr Deposit#_addNewLockToUser: Cannot set same lock id");
        if (amount == 0) return;
        // set ends at property for lock
        setConfig(_lockEndsAt_, lockId, endsAt);
        // set amount property for lock
        setConfig(_lockAmount_, lockId, amount);
        setConfig(_lockTotal_, user, getConfig(_lockTotal_, user).add(amount));

        // set lock id
        _userLocks[user].push(lockId);
    }

    function cleanUserLocks(address user) public {
        uint256 userLockCount = _userLocks[user].length;
        uint256 currentTs = block.timestamp;

        if (userLockCount == 0) return;

        for (uint256 i = 0; i < userLockCount; i++) {
            uint256 lockId = _userLocks[user][i];
            if (getConfig(_lockEndsAt_, lockId) > currentTs && getConfig(_lockAmount_, lockId) != 0) {
                continue;
            }

            // set total lock amount for user
            setConfig(_lockTotal_, user, getConfig(_lockTotal_, user).sub(getConfig(_lockAmount_, lockId)));
            // remove lock from array
            _userLocks[user][i] = _userLocks[user][userLockCount.sub(1)];
            _userLocks[user].pop();
            //
            userLockCount--;
            i--;
        }
    }

    function availableAmountForUnlock(address user) public view returns (uint256) {
        uint256 userLockCount = _userLocks[user].length;
        uint256 amount = 0;
        if (userLockCount == 0) {
            return amount;
        }

        for (uint256 i = 0; i < userLockCount; i++) {
            uint256 lockId = _userLocks[user][i];
            if (getConfig(_lockEndsAt_, lockId) <= now) {
                amount += getConfig(_lockAmount_, lockId);
            }
        }

        return amount;
    }

    function changeOperator(address operator) public onlyOwner {
        _operator = operator;
    }
}

pragma solidity ^0.6.11;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "../lib/Pausable.sol";
import "../lib/interfaces/IConfig.sol";
import "../lib/interfaces/IStaking.sol";
import "../lib/Configurable.sol";
import "../Config.sol";
import "./AnkrDeposit_R1.sol";

contract Governance_R1 is Pausable, AnkrDeposit_R1 {
    using SafeMath for uint256;

    event ConfigurationChanged(bytes32 indexed key, uint256 oldValue, uint256 newValue);
    event Vote(address indexed holder, bytes32 indexed ID, bytes32 vote, uint256 votes);
    event Propose(address indexed proposer, bytes32 proposeID, string topic, string content, uint span);
    event ProposalFinished(bytes32 indexed proposeID, bool result, uint256 yes, uint256 no);

    IConfig private configContract;
    IStaking private depositContract;

    bytes32 internal constant _spanLo_ = "Gov#spanLo";
    bytes32 internal constant _spanHi_ = "Gov#spanHi";
    bytes32 internal constant _proposalMinimumThreshold_ = "Gov#minimumDepositThreshold";

    bytes32 internal constant _startBlock_ = "Gov#startBlock";

    bytes32 internal constant _proposeTopic_ = "Gov#proposeTopic";
    bytes32 internal constant _proposeContent_ = "Gov#proposeContent";

    bytes32 internal constant _proposeEndAt_ = "Gov#ProposeEndAt";
    bytes32 internal constant _proposeStartAt_ = "Gov#ProposeStartAt";
    bytes32 internal constant _proposeTimelock_ = "Gov#ProposeTimelock";

    bytes32 internal constant _proposeCountLimit_ = "Gov#ProposeCountLimit";

    bytes32 internal constant _proposerLastProposeAt_ = "Gov#ProposerLastProposeAt";
    bytes32 internal constant _proposerProposeCountInMonth_ = "Gov#ProposeCountInMonth";

    bytes32 internal constant _proposer_ = "Gov#proposer";
    bytes32 internal constant _proposerHasActiveProposal_ = "Gov#hasActiveProposal";

    bytes32 internal constant _totalProposes_ = "Gov#proposer";
    bytes32 internal constant _minimumVoteAcceptance_ = "Gov#minimumVoteAcceptance";

    bytes32 internal constant _proposeID_ = "Gov#proposeID";
    bytes32 internal constant _proposeStatus_ = "Gov#proposeStatus";

    bytes32 internal constant _votes_ = "Gov#votes";
    bytes32 internal constant _voteCount_ = "Gov#voteCount";

    uint256 internal constant PROPOSE_STATUS_WAITING = 0;
    uint256 internal constant PROPOSE_STATUS_VOTING = 1;
    uint256 internal constant PROPOSE_STATUS_FAIL = 2;
    uint256 internal constant PROPOSE_STATUS_PASS = 3;
    uint256 internal constant PROPOSE_STATUS_CANCELED = 4;

    uint256 internal constant MONTH = 2592000;

    bytes32 internal constant VOTE_YES = "VOTE_YES";
    bytes32 internal constant VOTE_NO = "VOTE_NO";
    bytes32 internal constant VOTE_CANCEL = "VOTE_CANCEL";

    uint256 internal constant DIVISOR = 1 ether;

    function initialize(address ankrContract, address globalPoolContract, address aethContract) public initializer {
        __Ownable_init();
        deposit_init(ankrContract, globalPoolContract, aethContract);

        // minimum ankrs deposited needed for voting
        changeConfiguration(_proposalMinimumThreshold_, 5000000 ether);

        changeConfiguration("PROVIDER_MINIMUM_ANKR_STAKING", 100000 ether);
        changeConfiguration("PROVIDER_MINIMUM_ETH_TOP_UP", 0.1 ether);
        changeConfiguration("PROVIDER_MINIMUM_ETH_STAKING", 2 ether);
        changeConfiguration("REQUESTER_MINIMUM_POOL_STAKING", 500 finney);
        changeConfiguration("EXIT_BLOCKS", 24);

        changeConfiguration(_proposeCountLimit_, 2);

        // 2 days
        changeConfiguration(_proposeTimelock_, 60 * 60 * 24 * 2);

        changeConfiguration(_spanLo_, 24 * 60 * 60 * 3);
        // 3 days
        changeConfiguration(_spanHi_, 24 * 60 * 60 * 7);
        // 7 days
    }

    function propose(uint256 _timeSpan, string memory _topic, string memory _content) public {
        require(_timeSpan >= getConfig(_spanLo_), "Gov#propose: Timespan lower than limit");
        require(_timeSpan <= getConfig(_spanHi_), "Gov#propose: Timespan greater than limit");

        uint256 proposalMinimum = getConfig(_proposalMinimumThreshold_);
        address sender = msg.sender;
        uint256 senderInt = uint(sender);

        require(getConfig(_proposerHasActiveProposal_, sender) == 0, "Gov#propose: You have an active proposal");

        setConfig(_proposerHasActiveProposal_, sender, 1);

        deposit();
        require(depositsOf(sender) >= proposalMinimum, "Gov#propose: Not enough balance");

        // proposer can create 2 proposal in a month
        uint256 lastProposeAt = getConfig(_proposerLastProposeAt_, senderInt);
        if (now.sub(lastProposeAt) < MONTH) {
            // get new count in this month
            uint256 proposeCountInMonth = getConfig(_proposerProposeCountInMonth_, senderInt).add(1);
            require(proposeCountInMonth <= getConfig(_proposeCountLimit_), "Gov#propose: Cannot create more proposals this month");
            setConfig(_proposerProposeCountInMonth_, senderInt, proposeCountInMonth);
        }
        else {
            setConfig(_proposerProposeCountInMonth_, senderInt, 1);
        }
        // set last propose at for proposer
        setConfig(_proposerLastProposeAt_, senderInt, now);

        uint256 totalProposes = getConfig(_totalProposes_);
        bytes32 _proposeID = bytes32(senderInt ^ totalProposes ^ block.number);
        uint256 idInteger = uint(_proposeID);

        setConfig(_totalProposes_, totalProposes.add(1));

        // set started block
        setConfig(_startBlock_, idInteger, block.number);
        // set sender
        setConfigAddress(_proposer_, idInteger, sender);
        // set
        setConfigString(_proposeTopic_, idInteger, _topic);
        setConfigString(_proposeContent_, idInteger, _content);

        // proposal will start after #timelock# days
        uint256 endsAt = _timeSpan.add(getConfig(_proposeTimelock_)).add(now);

        setConfig(_proposeEndAt_, idInteger, endsAt);
        setConfig(_proposeStatus_, idInteger, PROPOSE_STATUS_WAITING);

        setConfig(_proposeStartAt_, idInteger, now);

        // add new lock to user
        _addNewLockToUser(sender, proposalMinimum, endsAt, senderInt ^ idInteger);

        // set proposal status (pending)
        emit Propose(sender, _proposeID, _topic, _content, _timeSpan);
        __vote(_proposeID, VOTE_YES, false);
    }

    function vote(bytes32 _ID, bytes32 _vote) public {
        deposit();
        uint256 ID = uint256(_ID);
        uint256 status = getConfig(_proposeStatus_, ID);
        uint256 startAt = getConfig(_proposeStartAt_, ID);
        // if propose status is waiting and enough time passed, change status
        if (status == PROPOSE_STATUS_WAITING && now.sub(startAt) >= getConfig(_proposeTimelock_)) {
            setConfig(_proposeStatus_, ID, PROPOSE_STATUS_VOTING);
            status = PROPOSE_STATUS_VOTING;
        }
        require(status == PROPOSE_STATUS_VOTING, "Gov#__vote: Propose status is not VOTING");
        require(getConfigAddress(_proposer_, ID) != msg.sender, "Gov#__vote: Proposers cannot vote their own proposals") ;

        __vote(_ID, _vote, true);
    }

    string public go;

    function __vote(bytes32 _ID, bytes32 _vote, bool _lockTokens) internal {

        uint256 ID = uint256(_ID);
        address _holder = msg.sender;

        uint256 _holderID = uint(_holder) ^ uint(ID);
        uint256 endsAt = getConfig(_proposeEndAt_, ID);

        if (now < endsAt) {
            // previous vote type
            bytes32 voted = bytes32(getConfig(_votes_, _holderID));
            require(voted == 0x0 || _vote == VOTE_CANCEL, "Gov#__vote: You already voted to this proposal");
            // previous vote count
            uint256 voteCount = getConfig(_voteCount_, _holderID);

            uint256 ID_voted = uint256(_ID ^ voted);
            // if this is a cancelling operation, set vote count to 0 for user and remove votes
            if ((voted == VOTE_YES || voted == VOTE_NO) && _vote == VOTE_CANCEL) {
                setConfig(_votes_, ID_voted, getConfig(_votes_, ID_voted).sub(voteCount));
                setConfig(_voteCount_, _holderID, 0);

                setConfig(_votes_, _holderID, uint256(_vote));
                emit Vote(_holder, _ID, _vote, 0);
                return;
            }
            else if (_vote == VOTE_YES || _vote == VOTE_NO) {
                uint256 ID_vote = uint256(_ID ^ _vote);
                // get total stakes from deposit contract
                uint256 staked = depositsOf(_holder);

                // add new lock to user
                if (_lockTokens) {
                    _addNewLockToUser(_holder, staked, endsAt, _holderID);
                }

                setConfig(_votes_, ID_vote, getConfig(_votes_, ID_vote).add(staked.div(DIVISOR)));
                setConfig(_votes_, _holderID, uint256(_vote));
                emit Vote(_holder, _ID, _vote, staked);
            }
        }
    }

    //0xc7bc95c2
    function getVotes(bytes32 _ID, bytes32 _vote) public view returns (uint256) {
        return getConfig(_votes_, uint256(_ID ^ _vote));
    }

    function finishProposal(bytes32 _ID) public {
        uint256 ID = uint256(_ID);
        require(getConfig(_proposeEndAt_, ID) <= now, "Gov#finishProposal: There is still time for proposal");
        uint256 status = getConfig(_proposeStatus_, ID);
        require(status == PROPOSE_STATUS_VOTING || status == PROPOSE_STATUS_WAITING, "Gov#finishProposal: You cannot finish proposals that already finished");

        _finishProposal(_ID);
    }

    function _finishProposal(bytes32 _ID) internal returns (bool result) {
        uint256 ID = uint256(_ID);
        uint256 yes = 0;
        uint256 no = 0;

        (result, yes, no,,,,,) = proposal(_ID);

        setConfig(_proposeStatus_, ID, result ? PROPOSE_STATUS_PASS : PROPOSE_STATUS_FAIL);

        setConfig(_proposerHasActiveProposal_, getConfigAddress(_proposer_, ID), 0);

        emit ProposalFinished(_ID, result, yes, no);
    }

    function proposal(bytes32 _ID) public view returns (
        bool result,
        uint256 yes,
        uint256 no,
        string memory topic,
        string memory content,
        uint256 status,
        uint256 startTime,
        uint256 endTime
    ) {
        uint256 idInteger = uint(_ID);
        yes = getConfig(_votes_, uint256(_ID ^ VOTE_YES));
        no = getConfig(_votes_, uint256(_ID ^ VOTE_NO));

        result = yes > no && yes.add(no) > getConfig(_minimumVoteAcceptance_);

        topic = getConfigString(_proposeTopic_, idInteger);
        content = getConfigString(_proposeContent_, idInteger);

        endTime = getConfig(_proposeEndAt_, idInteger);
        startTime = getConfig(_proposeStartAt_, idInteger);

        status = getConfig(_proposeStatus_, idInteger);
        if (status == PROPOSE_STATUS_WAITING && now.sub(getConfig(_proposeStartAt_, idInteger)) >= getConfig(_proposeTimelock_)) {
            status = PROPOSE_STATUS_VOTING;
        }
    }

    function changeConfiguration(bytes32 key, uint256 value) public onlyOperator {
        uint256 oldValue = config[key];
        if (oldValue != value) {
            config[key] = value;
            emit ConfigurationChanged(key, oldValue, value);
        }
    }

    function cancelProposal(bytes32 _ID, string memory _reason) public onlyOwner {
        uint256 ID = uint(_ID);
        require(getConfig(_proposeStatus_, ID) == PROPOSE_STATUS_WAITING, "Gov#cancelProposal: Only waiting proposals can be canceled");
        address sender = msg.sender;
        // set status cancel
        setConfig(_proposeStatus_, ID, PROPOSE_STATUS_CANCELED);
        // remove from propose count for month
        setConfig(_proposerProposeCountInMonth_, ID, getConfig(_proposerProposeCountInMonth_, ID).sub(1));
        // remove locked amount
        setConfig(_lockTotal_, sender, getConfig(_lockTotal_, sender).sub(getConfig(_lockAmount_, uint(sender) ^ ID)));
        // set locked amount to zero for this proposal
        setConfig(_lockAmount_, uint(sender) ^ ID, 0);
    }
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


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

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

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