// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import '@openzeppelin/contracts/access/AccessControl.sol';

import './interfaces/IERC20.sol';
import './interfaces/ITomiStaking.sol';
import './interfaces/ITomiConfig.sol';
import './interfaces/ITomiBallotFactory.sol';
import './interfaces/ITomiBallot.sol';
import './interfaces/ITomiBallotRevenue.sol';
import './interfaces/ITgas.sol';
import './interfaces/ITokenRegistry.sol';
import './libraries/ConfigNames.sol';
import './libraries/TransferHelper.sol';
import './modules/TgasStaking.sol';
import './modules/Ownable.sol';
import './libraries/SafeMath.sol';

contract TomiGovernance is TgasStaking, Ownable, AccessControl {
    using SafeMath for uint256;

    uint256 public version = 1;
    address public configAddr;
    address public ballotFactoryAddr;
    address public rewardAddr;
    address public stakingAddr;

    uint256 public T_CONFIG = 1;
    uint256 public T_LIST_TOKEN = 2;
    uint256 public T_TOKEN = 3;
    uint256 public T_SNAPSHOT = 4;
    uint256 public T_REVENUE = 5;

    uint256 public VOTE_DURATION;
    uint256 public FREEZE_DURATION;
    uint256 public REVENUE_VOTE_DURATION;
    uint256 public REVENUE_FREEZE_DURATION;
    uint256 public MINIMUM_TOMI_REQUIRED_IN_BALANCE = 100e18;

    bytes32 public constant SUPER_ADMIN_ROLE = keccak256(abi.encodePacked('SUPER_ADMIN_ROLE'));
    bytes32 REVENUE_PROPOSAL = bytes32('REVENUE_PROPOSAL');
    bytes32 SNAPSHOT_PROPOSAL = bytes32('SNAPSHOT_PROPOSAL');

    mapping(address => uint256) public ballotTypes;
    mapping(address => bytes32) public configBallots;
    mapping(address => address) public tokenBallots;
    mapping(address => uint256) public rewardOf;
    mapping(address => uint256) public ballotOf;
    mapping(address => mapping(address => uint256)) public applyTokenOf;
    mapping(address => mapping(address => bool)) public collectUsers;
    mapping(address => address) public tokenUsers;

    address[] public ballots;
    address[] public revenueBallots;

    event ConfigAudited(bytes32 name, address indexed ballot, uint256 proposal);
    event ConfigBallotCreated(
        address indexed proposer,
        bytes32 name,
        uint256 value,
        address indexed ballotAddr,
        uint256 reward
    );
    event TokenBallotCreated(
        address indexed proposer,
        address indexed token,
        uint256 value,
        address indexed ballotAddr,
        uint256 reward
    );
    event ProposalerRewardRateUpdated(uint256 oldVaue, uint256 newValue);
    event RewardTransfered(address indexed from, address indexed to, uint256 value);
    event TokenListed(address user, address token, uint256 amount);
    event ListTokenAudited(address user, address token, uint256 status, uint256 burn, uint256 reward, uint256 refund);
    event TokenAudited(address user, address token, uint256 status, bool result);
    event RewardCollected(address indexed user, address indexed ballot, uint256 value);
    event RewardReceived(address indexed user, uint256 value);

    modifier onlyRewarder() {
        require(msg.sender == rewardAddr, 'TomiGovernance: ONLY_REWARDER');
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), 'TomiGovernance: sender not allowed to do!');
        _;
    }

    constructor(
        address _tgas,
        uint256 _VOTE_DURATION,
        uint256 _FREEZE_DURATION,
        uint256 _REVENUE_VOTE_DURATION,
        uint256 _REVENUE_FREEZE_DURATION
    ) public TgasStaking(_tgas) {
        _setupRole(SUPER_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, SUPER_ADMIN_ROLE);

        VOTE_DURATION = _VOTE_DURATION;
        FREEZE_DURATION = _FREEZE_DURATION;
        REVENUE_VOTE_DURATION = _REVENUE_VOTE_DURATION;
        REVENUE_FREEZE_DURATION = _REVENUE_FREEZE_DURATION;
    }

    // called after deployment
    function initialize(
        address _rewardAddr,
        address _configContractAddr,
        address _ballotFactoryAddr,
        address _stakingAddr
    ) external onlyOwner {
        require(
            _rewardAddr != address(0) &&
                _configContractAddr != address(0) &&
                _ballotFactoryAddr != address(0) &&
                _stakingAddr != address(0),
            'TomiGovernance: INPUT_ADDRESS_IS_ZERO'
        );

        stakingAddr = _stakingAddr;
        rewardAddr = _rewardAddr;
        configAddr = _configContractAddr;
        ballotFactoryAddr = _ballotFactoryAddr;
        lockTime = getConfigValue(ConfigNames.UNSTAKE_DURATION);
    }

    function newStakingSettle(address _STAKING) external onlyRole(SUPER_ADMIN_ROLE) {
        require(stakingAddr != _STAKING, 'STAKING ADDRESS IS THE SAME');
        require(_STAKING != address(0), 'STAKING ADDRESS IS DEFAULT ADDRESS');
        stakingAddr = _STAKING;
    }

    function changeProposalDuration(uint256[4] calldata _durations) external onlyRole(SUPER_ADMIN_ROLE) {
        VOTE_DURATION = _durations[0];
        FREEZE_DURATION = _durations[1];
        REVENUE_VOTE_DURATION = _durations[2];
        REVENUE_FREEZE_DURATION = _durations[3];
    }

    function changeTomiMinimumRequired(uint256 _newMinimum) external onlyRole(SUPER_ADMIN_ROLE) {
        require(_newMinimum != MINIMUM_TOMI_REQUIRED_IN_BALANCE, 'TomiGovernance::Tomi required is identical!');
        MINIMUM_TOMI_REQUIRED_IN_BALANCE = _newMinimum;
    }

    // function changeProposalVoteDuration(uint _newDuration) external onlyRole(SUPER_ADMIN_ROLE) {
    //     require(_newDuration != VOTE_DURATION, "TomiGovernance::Vote duration has not changed");
    //     VOTE_DURATION = _newDuration;
    // }

    // function changeProposalFreezeDuration(uint _newDuration) external onlyRole(SUPER_ADMIN_ROLE) {
    //     require(_newDuration != FREEZE_DURATION, "TomiGovernance::Freeze duration has not changed");
    //     FREEZE_DURATION = _newDuration;
    // }

    // function changeRevenueProposalVoteDuration(uint _newDuration) external onlyRole(SUPER_ADMIN_ROLE) {
    //     require(_newDuration != REVENUE_VOTE_DURATION, "TomiGovernance::Vote duration has not changed");
    //     REVENUE_VOTE_DURATION = _newDuration;
    // }

    // function changeRevenueProposalFreezeDuration(uint _newDuration) external onlyRole(SUPER_ADMIN_ROLE) {
    //     require(_newDuration != REVENUE_FREEZE_DURATION, "TomiGovernance::Freeze duration has not changed");
    //     REVENUE_FREEZE_DURATION = _newDuration;
    // }

    function vote(
        address _ballot,
        uint256 _proposal,
        uint256 _collateral
    ) external {
        require(configBallots[_ballot] != REVENUE_PROPOSAL, 'TomiGovernance::Fail due to wrong ballot');
        uint256 collateralRemain = balanceOf[msg.sender];

        if (_collateral > collateralRemain) {
            uint256 collateralMore = _collateral.sub(collateralRemain);
            _transferForBallot(collateralMore, true, ITomiBallot(_ballot).executionTime());
        }

        ITomiBallot(_ballot).voteByGovernor(msg.sender, _proposal);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_collateral);

        _transferToStaking(_collateral);
        // rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_collateral);
    }

    function participate(address _ballot, uint256 _collateral) external {
        require(configBallots[_ballot] == REVENUE_PROPOSAL, 'TomiGovernance::Fail due to wrong ballot');

        uint256 collateralRemain = balanceOf[msg.sender];
        uint256 collateralMore = _collateral.sub(collateralRemain);

        _transferForBallot(collateralMore, true, ITomiBallot(_ballot).executionTime());
        ITomiBallotRevenue(_ballot).participateByGovernor(msg.sender);
    }

    function audit(address _ballot) external returns (bool) {
        if (ballotTypes[_ballot] == T_CONFIG) {
            return auditConfig(_ballot);
        } else if (ballotTypes[_ballot] == T_LIST_TOKEN) {
            return auditListToken(_ballot);
        } else if (ballotTypes[_ballot] == T_TOKEN) {
            return auditToken(_ballot);
        } else {
            revert('TomiGovernance: UNKNOWN_TYPE');
        }
    }

    function auditConfig(address _ballot) public returns (bool) {
        bool result = ITomiBallot(_ballot).end();
        require(result, 'TomiGovernance: NO_PASS');
        uint256 value = ITomiBallot(_ballot).value();
        bytes32 name = configBallots[_ballot];
        result = ITomiConfig(configAddr).changeConfigValue(name, value);
        if (name == ConfigNames.UNSTAKE_DURATION) {
            lockTime = value;
        } else if (name == ConfigNames.PRODUCE_TGAS_RATE) {
            _changeAmountPerBlock(value);
        }
        emit ConfigAudited(name, _ballot, value);
        return result;
    }

    function auditListToken(address _ballot) public returns (bool) {
        bool result = ITomiBallot(_ballot).end();
        address token = tokenBallots[_ballot];
        address user = tokenUsers[token];
        require(
            ITokenRegistry(configAddr).tokenStatus(token) == ITokenRegistry(configAddr).REGISTERED(),
            'TomiGovernance: AUDITED'
        );
        uint256 status = result ? ITokenRegistry(configAddr).PENDING() : ITokenRegistry(configAddr).CLOSED();
        uint256 amount = applyTokenOf[user][token];
        (uint256 burnAmount, uint256 rewardAmount, uint256 refundAmount) = (0, 0, 0);
        if (result) {
            burnAmount =
                (amount * getConfigValue(ConfigNames.LIST_TOKEN_SUCCESS_BURN_PRECENT)) /
                ITomiConfig(configAddr).PERCENT_DENOMINATOR();
            rewardAmount = amount - burnAmount;
            if (burnAmount > 0) {
                TransferHelper.safeTransfer(baseToken, address(0), burnAmount);
                totalSupply = totalSupply.sub(burnAmount);
            }
            if (rewardAmount > 0) {
                rewardOf[rewardAddr] = rewardOf[rewardAddr].add(rewardAmount);
                ballotOf[_ballot] = ballotOf[_ballot].add(rewardAmount);
                _rewardTransfer(rewardAddr, _ballot, rewardAmount);
            }
            ITokenRegistry(configAddr).publishToken(token);
        } else {
            burnAmount =
                (amount * getConfigValue(ConfigNames.LIST_TOKEN_FAILURE_BURN_PRECENT)) /
                ITomiConfig(configAddr).PERCENT_DENOMINATOR();
            refundAmount = amount - burnAmount;
            if (burnAmount > 0) TransferHelper.safeTransfer(baseToken, address(0), burnAmount);
            if (refundAmount > 0) TransferHelper.safeTransfer(baseToken, user, refundAmount);
            totalSupply = totalSupply.sub(amount);
            ITokenRegistry(configAddr).updateToken(token, status);
        }
        emit ListTokenAudited(user, token, status, burnAmount, rewardAmount, refundAmount);
        return result;
    }

    function auditToken(address _ballot) public returns (bool) {
        bool result = ITomiBallot(_ballot).end();
        uint256 status = ITomiBallot(_ballot).value();
        address token = tokenBallots[_ballot];
        address user = tokenUsers[token];
        require(ITokenRegistry(configAddr).tokenStatus(token) != status, 'TomiGovernance: TOKEN_STATUS_NO_CHANGE');
        if (result) {
            ITokenRegistry(configAddr).updateToken(token, status);
        } else {
            status = ITokenRegistry(configAddr).tokenStatus(token);
        }
        emit TokenAudited(user, token, status, result);
        return result;
    }

    function getConfigValue(bytes32 _name) public view returns (uint256) {
        return ITomiConfig(configAddr).getConfigValue(_name);
    }

    function _createProposalPrecondition(uint256 _amount, uint256 _executionTime) private {
        address sender = msg.sender;
        if (!hasRole(DEFAULT_ADMIN_ROLE, sender)) {
            require(
                IERC20(baseToken).balanceOf(sender).add(balanceOf[sender]) >= MINIMUM_TOMI_REQUIRED_IN_BALANCE,
                'TomiGovernance::Require minimum TOMI in balance'
            );
            require(
                _amount >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT),
                'TomiGovernance: NOT_ENOUGH_AMOUNT_TO_PROPOSAL'
            );

            uint256 collateralRemain = balanceOf[sender];

            if (_amount > collateralRemain) {
                uint256 collateralMore = _amount.sub(collateralRemain);
                _transferForBallot(collateralMore, true, _executionTime);
            }

            collateralRemain = balanceOf[sender];

            require(
                collateralRemain >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT),
                'TomiGovernance: COLLATERAL_NOT_ENOUGH_AMOUNT_TO_PROPOSAL'
            );
            balanceOf[sender] = collateralRemain.sub(_amount);

            _transferToStaking(_amount);
        }
    }

    function createRevenueBallot(string calldata _subject, string calldata _content)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (address)
    {
        uint256 endTime = block.timestamp.add(REVENUE_VOTE_DURATION);
        uint256 executionTime = endTime.add(REVENUE_FREEZE_DURATION);

        address ballotAddr = ITomiBallotFactory(ballotFactoryAddr).createShareRevenue(
            msg.sender,
            endTime,
            executionTime,
            _subject,
            _content
        );
        configBallots[ballotAddr] = REVENUE_PROPOSAL;
        uint256 reward = _createdBallot(ballotAddr, T_REVENUE);
        emit ConfigBallotCreated(msg.sender, REVENUE_PROPOSAL, 0, ballotAddr, reward);
        return ballotAddr;
    }

    function createSnapshotBallot(
        uint256 _amount,
        string calldata _subject,
        string calldata _content
    ) external returns (address) {
        uint256 endTime = block.timestamp.add(VOTE_DURATION);
        uint256 executionTime = endTime.add(FREEZE_DURATION);

        _createProposalPrecondition(_amount, executionTime);

        address ballotAddr = ITomiBallotFactory(ballotFactoryAddr).create(
            msg.sender,
            0,
            endTime,
            executionTime,
            _subject,
            _content
        );

        configBallots[ballotAddr] = SNAPSHOT_PROPOSAL;
        // rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_amount);

        uint256 reward = _createdBallot(ballotAddr, T_SNAPSHOT);
        emit ConfigBallotCreated(msg.sender, SNAPSHOT_PROPOSAL, 0, ballotAddr, reward);
        return ballotAddr;
    }

    function createConfigBallot(
        bytes32 _name,
        uint256 _value,
        uint256 _amount,
        string calldata _subject,
        string calldata _content
    ) external returns (address) {
        require(_value >= 0, 'TomiGovernance: INVALID_PARAMTERS');
        {
            // avoids stack too deep errors
            (uint256 minValue, uint256 maxValue, uint256 maxSpan, uint256 value, uint256 enable) = ITomiConfig(
                configAddr
            ).getConfig(_name);
            require(enable == 1, 'TomiGovernance: CONFIG_DISABLE');
            require(_value >= minValue && _value <= maxValue, 'TomiGovernance: OUTSIDE');
            uint256 span = _value >= value ? (_value - value) : (value - _value);
            require(maxSpan >= span, 'TomiGovernance: OVERSTEP');
        }

        uint256 endTime = block.timestamp.add(VOTE_DURATION);
        uint256 executionTime = endTime.add(FREEZE_DURATION);

        _createProposalPrecondition(_amount, executionTime);

        address ballotAddr = ITomiBallotFactory(ballotFactoryAddr).create(
            msg.sender,
            _value,
            endTime,
            executionTime,
            _subject,
            _content
        );

        configBallots[ballotAddr] = _name;
        // rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_amount);

        uint256 reward = _createdBallot(ballotAddr, T_CONFIG);
        emit ConfigBallotCreated(msg.sender, _name, _value, ballotAddr, reward);
        return ballotAddr;
    }

    function createTokenBallot(
        address _token,
        uint256 _value,
        uint256 _amount,
        string calldata _subject,
        string calldata _content
    ) external returns (address) {
        require(!_isDefaultToken(_token), 'TomiGovernance: DEFAULT_LIST_TOKENS_PROPOSAL_DENY');
        uint256 status = ITokenRegistry(configAddr).tokenStatus(_token);
        require(status == ITokenRegistry(configAddr).PENDING(), 'TomiGovernance: ONLY_ALLOW_PENDING');
        require(
            _value == ITokenRegistry(configAddr).OPENED() || _value == ITokenRegistry(configAddr).CLOSED(),
            'TomiGovernance: INVALID_STATUS'
        );
        require(status != _value, 'TomiGovernance: STATUS_NO_CHANGE');

        uint256 endTime = block.timestamp.add(VOTE_DURATION);
        uint256 executionTime = endTime.add(FREEZE_DURATION);

        _createProposalPrecondition(_amount, executionTime);

        address ballotAddr = _createTokenBallot(T_TOKEN, _token, _value, _subject, _content, endTime, executionTime);
        // rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_amount);
        return ballotAddr;
    }

    function listToken(
        address _token,
        uint256 _amount,
        string calldata _subject,
        string calldata _content
    ) external returns (address) {
        uint256 status = ITokenRegistry(configAddr).tokenStatus(_token);
        require(
            status == ITokenRegistry(configAddr).NONE() || status == ITokenRegistry(configAddr).CLOSED(),
            'TomiGovernance: LISTED'
        );
        // require(_amount >= getConfigValue(ConfigNames.LIST_TGAS_AMOUNT), "TomiGovernance: NOT_ENOUGH_AMOUNT_TO_LIST");
        tokenUsers[_token] = msg.sender;

        uint256 endTime = block.timestamp.add(VOTE_DURATION);
        uint256 executionTime = endTime.add(FREEZE_DURATION);

        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            require(
                _amount >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT),
                'TomiGovernance: NOT_ENOUGH_AMOUNT_TO_PROPOSAL'
            );

            uint256 collateralRemain = balanceOf[msg.sender];
            uint256 collateralMore = _amount.sub(collateralRemain);

            applyTokenOf[msg.sender][_token] = _transferForBallot(collateralMore, true, executionTime);
            collateralRemain = balanceOf[msg.sender];

            require(
                collateralRemain >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT),
                'TomiGovernance: COLLATERAL_NOT_ENOUGH_AMOUNT_TO_PROPOSAL'
            );
            balanceOf[msg.sender] = collateralRemain.sub(_amount);

            _transferToStaking(_amount);
        }

        ITokenRegistry(configAddr).registryToken(_token);
        address ballotAddr = _createTokenBallot(
            T_LIST_TOKEN,
            _token,
            ITokenRegistry(configAddr).PENDING(),
            _subject,
            _content,
            endTime,
            executionTime
        );
        // rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_amount);
        emit TokenListed(msg.sender, _token, _amount);
        return ballotAddr;
    }

    function _createTokenBallot(
        uint256 _type,
        address _token,
        uint256 _value,
        string memory _subject,
        string memory _content,
        uint256 _endTime,
        uint256 _executionTime
    ) private returns (address) {
        address ballotAddr = ITomiBallotFactory(ballotFactoryAddr).create(
            msg.sender,
            _value,
            _endTime,
            _executionTime,
            _subject,
            _content
        );

        uint256 reward = _createdBallot(ballotAddr, _type);
        ballotOf[ballotAddr] = reward;
        tokenBallots[ballotAddr] = _token;
        emit TokenBallotCreated(msg.sender, _token, _value, ballotAddr, reward);
        return ballotAddr;
    }

    function collectReward(address _ballot) external returns (uint256) {
        require(block.timestamp >= ITomiBallot(_ballot).endTime(), 'TomiGovernance: NOT_YET_ENDED');
        require(!collectUsers[_ballot][msg.sender], 'TomiGovernance: REWARD_COLLECTED');
        require(configBallots[_ballot] == REVENUE_PROPOSAL, 'TomiGovernance::Fail due to wrong ballot');

        uint256 amount = getRewardForRevenueProposal(_ballot);
        _rewardTransfer(_ballot, msg.sender, amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        stakingSupply = stakingSupply.add(amount);
        rewardOf[msg.sender] = rewardOf[msg.sender].sub(amount);
        collectUsers[_ballot][msg.sender] = true;

        emit RewardCollected(msg.sender, _ballot, amount);
    }

    // function getReward(address _ballot) public view returns (uint) {
    //     if (block.timestamp < ITomiBallot(_ballot).endTime() || collectUsers[_ballot][msg.sender]) {
    //         return 0;
    //     }
    //     uint amount;
    //     uint shares = ballotOf[_ballot];

    //     bool result = ITomiBallot(_ballot).result();

    //     if (result) {
    //         uint extra;
    //         uint rewardRate = getConfigValue(ConfigNames.VOTE_REWARD_PERCENT);
    //         if ( rewardRate > 0) {
    //            extra = shares * rewardRate / ITomiConfig(configAddr).PERCENT_DENOMINATOR();
    //            shares -= extra;
    //         }
    //         if (msg.sender == ITomiBallot(_ballot).proposer()) {
    //             amount = extra;
    //         }
    //     }

    //     if (ITomiBallot(_ballot).total() > 0) {
    //         uint reward = shares * ITomiBallot(_ballot).weight(msg.sender) / ITomiBallot(_ballot).total();
    //         amount += ITomiBallot(_ballot).proposer() == msg.sender ? 0: reward;
    //     }
    //     return amount;
    // }

    function getRewardForRevenueProposal(address _ballot) public view returns (uint256) {
        if (block.timestamp < ITomiBallotRevenue(_ballot).endTime() || collectUsers[_ballot][msg.sender]) {
            return 0;
        }

        uint256 amount = 0;
        uint256 shares = ballotOf[_ballot];

        if (ITomiBallotRevenue(_ballot).total() > 0) {
            uint256 reward = (shares * ITomiBallotRevenue(_ballot).weight(msg.sender)) /
                ITomiBallotRevenue(_ballot).total();
            amount += ITomiBallotRevenue(_ballot).proposer() == msg.sender ? 0 : reward;
        }
        return amount;
    }

    // TOMI TEST ONLY
    // function addReward(uint _value) external onlyRewarder returns (bool) {
    function addReward(uint256 _value) external returns (bool) {
        require(_value > 0, 'TomiGovernance: ADD_REWARD_VALUE_IS_ZERO');
        uint256 total = IERC20(baseToken).balanceOf(address(this));
        uint256 diff = total.sub(totalSupply);
        require(_value <= diff, 'TomiGovernance: ADD_REWARD_EXCEED');
        rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_value);
        totalSupply = total;
        emit RewardReceived(rewardAddr, _value);
    }

    function _rewardTransfer(
        address _from,
        address _to,
        uint256 _value
    ) private returns (bool) {
        require(_value >= 0 && rewardOf[_from] >= _value, 'TomiGovernance: INSUFFICIENT_BALANCE');
        rewardOf[_from] = rewardOf[_from].sub(_value);
        rewardOf[_to] = rewardOf[_to].add(_value);
        emit RewardTransfered(_from, _to, _value);
    }

    function _isDefaultToken(address _token) internal returns (bool) {
        address[] memory tokens = ITomiConfig(configAddr).getDefaultListTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function _transferForBallot(
        uint256 _amount,
        bool _wallet,
        uint256 _endTime
    ) internal returns (uint256) {
        if (_wallet && _amount > 0) {
            _add(msg.sender, _amount, _endTime);
            TransferHelper.safeTransferFrom(baseToken, msg.sender, address(this), _amount);
            totalSupply += _amount;
        }

        if (_amount == 0) allowance[msg.sender] = estimateLocktime(msg.sender, _endTime);

        return _amount;
    }

    function _transferToStaking(uint256 _amount) internal {
        if (stakingAddr != address(0)) {
            TransferHelper.safeTransfer(baseToken, stakingAddr, _amount);
            ITomiStaking(stakingAddr).updateRevenueShare(_amount);
        }
    }

    function _createdBallot(address _ballot, uint256 _type) internal returns (uint256) {
        uint256 reward = 0;

        if (_type == T_REVENUE) {
            reward = rewardOf[rewardAddr];
            ballotOf[_ballot] = reward;
            _rewardTransfer(rewardAddr, _ballot, reward);
        }

        _type == T_REVENUE ? revenueBallots.push(_ballot) : ballots.push(_ballot);
        ballotTypes[_ballot] = _type;
        return reward;
    }

    function ballotCount() external view returns (uint256) {
        return ballots.length;
    }

    function ballotRevenueCount() external view returns (uint256) {
        return revenueBallots.length;
    }

    function _changeAmountPerBlock(uint256 _value) internal returns (bool) {
        return ITgas(baseToken).changeInterestRatePerBlock(_value);
    }

    function updateTgasGovernor(address _new) external onlyOwner {
        ITgas(baseToken).upgradeGovernance(_new);
    }

    function upgradeApproveReward() external returns (uint256) {
        require(rewardOf[rewardAddr] > 0, 'TomiGovernance: UPGRADE_NO_REWARD');
        require(ITomiConfig(configAddr).governor() != address(this), 'TomiGovernance: UPGRADE_NO_CHANGE');
        TransferHelper.safeApprove(baseToken, ITomiConfig(configAddr).governor(), rewardOf[rewardAddr]);
        return rewardOf[rewardAddr];
    }

    function receiveReward(address _from, uint256 _value) external returns (bool) {
        require(_value > 0, 'TomiGovernance: RECEIVE_REWARD_VALUE_IS_ZERO');
        TransferHelper.safeTransferFrom(baseToken, _from, address(this), _value);
        rewardOf[rewardAddr] += _value;
        totalSupply += _value;
        emit RewardReceived(_from, _value);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

pragma solidity >=0.5.0;

interface ITomiStaking {
    function updateRevenueShare(uint256 revenueShared) external;
}

pragma solidity >=0.5.0;

interface ITomiConfig {
    function governor() external view returns (address);

    function dev() external view returns (address);

    function PERCENT_DENOMINATOR() external view returns (uint256);

    function getConfig(bytes32 _name)
        external
        view
        returns (
            uint256 minValue,
            uint256 maxValue,
            uint256 maxSpan,
            uint256 value,
            uint256 enable
        );

    function getConfigValue(bytes32 _name) external view returns (uint256);

    function changeConfigValue(bytes32 _name, uint256 _value) external returns (bool);

    function checkToken(address _token) external view returns (bool);

    function checkPair(address tokenA, address tokenB) external view returns (bool);

    function listToken(address _token) external returns (bool);

    function getDefaultListTokens() external returns (address[] memory);

    function platform() external view returns (address);

    function addToken(address _token) external returns (bool);
}

pragma solidity >=0.5.0;

interface ITomiBallotFactory {
    function create(
        address _proposer,
        uint256 _value,
        uint256 _endTime,
        uint256 _executionTime,
        string calldata _subject,
        string calldata _content
    ) external returns (address);

    function createShareRevenue(
        address _proposer,
        uint256 _endTime,
        uint256 _executionTime,
        string calldata _subject,
        string calldata _content
    ) external returns (address);
}

pragma solidity >=0.5.0;

interface ITomiBallot {
    function proposer() external view returns (address);

    function endTime() external view returns (uint256);

    function executionTime() external view returns (uint256);

    function value() external view returns (uint256);

    function result() external view returns (bool);

    function end() external returns (bool);

    function total() external view returns (uint256);

    function weight(address user) external view returns (uint256);

    function voteByGovernor(address user, uint256 proposal) external;
}

pragma solidity >=0.5.0;

interface ITomiBallotRevenue {
    function proposer() external view returns (address);

    function endTime() external view returns (uint256);

    function executionTime() external view returns (uint256);

    function end() external returns (bool);

    function total() external view returns (uint256);

    function weight(address user) external view returns (uint256);

    function participateByGovernor(address user) external;
}

pragma solidity >=0.5.0;

interface ITgas {
    function amountPerBlock() external view returns (uint256);

    function changeInterestRatePerBlock(uint256 value) external returns (bool);

    function getProductivity(address user) external view returns (uint256, uint256);

    function increaseProductivity(address user, uint256 value) external returns (bool);

    function decreaseProductivity(address user, uint256 value) external returns (bool);

    function take() external view returns (uint256);

    function takeWithBlock() external view returns (uint256, uint256);

    function mint() external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function upgradeImpl(address _newImpl) external;

    function upgradeGovernance(address _newGovernor) external;

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}

pragma solidity >=0.5.16;

interface ITokenRegistry {
    function tokenStatus(address _token) external view returns (uint256);

    function pairStatus(address tokenA, address tokenB) external view returns (uint256);

    function NONE() external view returns (uint256);

    function REGISTERED() external view returns (uint256);

    function PENDING() external view returns (uint256);

    function OPENED() external view returns (uint256);

    function CLOSED() external view returns (uint256);

    function registryToken(address _token) external returns (bool);

    function publishToken(address _token) external returns (bool);

    function updateToken(address _token, uint256 _status) external returns (bool);

    function updatePair(
        address tokenA,
        address tokenB,
        uint256 _status
    ) external returns (bool);

    function tokenCount() external view returns (uint256);

    function validTokens() external view returns (address[] memory);

    function iterateValidTokens(uint32 _start, uint32 _end) external view returns (address[] memory);
}

pragma solidity >=0.5.16;

library ConfigNames {
    bytes32 public constant PRODUCE_TGAS_RATE = bytes32('PRODUCE_TGAS_RATE');
    bytes32 public constant SWAP_FEE_PERCENT = bytes32('SWAP_FEE_PERCENT');
    bytes32 public constant LIST_TGAS_AMOUNT = bytes32('LIST_TGAS_AMOUNT');
    bytes32 public constant UNSTAKE_DURATION = bytes32('UNSTAKE_DURATION');
    // bytes32 public constant EXECUTION_DURATION = bytes32('EXECUTION_DURATION');
    bytes32 public constant REMOVE_LIQUIDITY_DURATION = bytes32('REMOVE_LIQUIDITY_DURATION');
    bytes32 public constant TOKEN_TO_TGAS_PAIR_MIN_PERCENT = bytes32('TOKEN_TO_TGAS_PAIR_MIN_PERCENT');
    bytes32 public constant LIST_TOKEN_FAILURE_BURN_PRECENT = bytes32('LIST_TOKEN_FAILURE_BURN_PRECENT');
    bytes32 public constant LIST_TOKEN_SUCCESS_BURN_PRECENT = bytes32('LIST_TOKEN_SUCCESS_BURN_PRECENT');
    bytes32 public constant PROPOSAL_TGAS_AMOUNT = bytes32('PROPOSAL_TGAS_AMOUNT');
    // bytes32 public constant VOTE_DURATION = bytes32('VOTE_DURATION');
    bytes32 public constant VOTE_REWARD_PERCENT = bytes32('VOTE_REWARD_PERCENT');
    bytes32 public constant TOKEN_PENGDING_SWITCH = bytes32('TOKEN_PENGDING_SWITCH');
    bytes32 public constant TOKEN_PENGDING_TIME = bytes32('TOKEN_PENGDING_TIME');
    bytes32 public constant LIST_TOKEN_SWITCH = bytes32('LIST_TOKEN_SWITCH');
    bytes32 public constant DEV_PRECENT = bytes32('DEV_PRECENT');
    bytes32 public constant FEE_GOVERNANCE_REWARD_PERCENT = bytes32('FEE_GOVERNANCE_REWARD_PERCENT');
    bytes32 public constant FEE_LP_REWARD_PERCENT = bytes32('FEE_LP_REWARD_PERCENT');
    bytes32 public constant FEE_FUNDME_REWARD_PERCENT = bytes32('FEE_FUNDME_REWARD_PERCENT');
    bytes32 public constant FEE_LOTTERY_REWARD_PERCENT = bytes32('FEE_LOTTERY_REWARD_PERCENT');
    bytes32 public constant FEE_STAKING_REWARD_PERCENT = bytes32('FEE_STAKING_REWARD_PERCENT');
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity >=0.5.16;

import '../libraries/TransferHelper.sol';
import '../libraries/SafeMath.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/ITomiConfig.sol';
import '../modules/BaseToken.sol';

contract TgasStaking is BaseToken {
    using SafeMath for uint256;

    uint256 public lockTime;
    uint256 public totalSupply;
    uint256 public stakingSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public allowance;

    constructor(address _baseToken) public {
        initBaseToken(_baseToken);
    }

    function estimateLocktime(address user, uint256 _endTime) internal view returns (uint256) {
        uint256 collateralLocktime = allowance[user];

        if (_endTime == 0) {
            uint256 depositLockTime = block.timestamp + lockTime;
            return depositLockTime > collateralLocktime ? depositLockTime : collateralLocktime;
        }

        return _endTime > collateralLocktime ? _endTime : collateralLocktime;
    }

    function _add(
        address user,
        uint256 value,
        uint256 endTime
    ) internal {
        require(value > 0, 'ZERO');
        balanceOf[user] = balanceOf[user].add(value);
        stakingSupply = stakingSupply.add(value);
        allowance[user] = estimateLocktime(user, endTime);
    }

    function _reduce(address user, uint256 value) internal {
        require(balanceOf[user] >= value && value > 0, 'TgasStaking: INSUFFICIENT_BALANCE');
        balanceOf[user] = balanceOf[user].sub(value);
        stakingSupply = stakingSupply.sub(value);
    }

    function deposit(uint256 _amount) external returns (bool) {
        TransferHelper.safeTransferFrom(baseToken, msg.sender, address(this), _amount);
        _add(msg.sender, _amount, 0);
        totalSupply = IERC20(baseToken).balanceOf(address(this));
        return true;
    }

    // function onBehalfDeposit(address _user, uint _amount) external returns (bool) {
    //     TransferHelper.safeTransferFrom(baseToken, msg.sender, address(this), _amount);
    //     _add(_user, _amount);
    //     totalSupply = IERC20(baseToken).balanceOf(address(this));
    //     return true;
    // }

    function withdraw(uint256 _amount) external returns (bool) {
        require(block.timestamp > allowance[msg.sender], 'TgasStaking: NOT_DUE');
        TransferHelper.safeTransfer(baseToken, msg.sender, _amount);
        _reduce(msg.sender, _amount);
        totalSupply = IERC20(baseToken).balanceOf(address(this));
        return true;
    }
}

pragma solidity >=0.5.16;

contract Ownable {
    address public owner;

    event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: FORBIDDEN');
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), 'Ownable: INVALID_ADDRESS');
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity >=0.5.16;

contract BaseToken {
    address public baseToken;

    // called after deployment
    function initBaseToken(address _baseToken) internal {
        require(baseToken == address(0), 'INITIALIZED');
        require(_baseToken != address(0), 'ADDRESS_IS_ZERO');
        baseToken = _baseToken; // it should be tgas token address
    }
}