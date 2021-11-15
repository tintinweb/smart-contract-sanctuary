// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import './interfaces/IYieldWolfStrategy.sol';
import './interfaces/IYieldWolfCondition.sol';
import './interfaces/IYieldWolfAction.sol';

/**
 * @title YieldWolf Staking Contract
 * @notice handles deposits, withdraws, strategy execution and bounty rewards
 * @author YieldWolf
 */
contract YieldWolf is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Rule {
        address condition; // address of the rule condition
        uint256[] conditionIntInputs; // numeric inputs sent to the rule condition
        address[] conditionAddrInputs; // address inputs sent to the rule condition
        address action; // address of the rule action
        uint256[] actionIntInputs; // numeric inputs sent to the rule action
        address[] actionAddrInputs; // address inputs sent to the rule action
    }

    struct UserInfo {
        uint256 shares; // total of shares the user has on the pool
        Rule[] rules; // list of rules applied to the pool
    }

    struct PoolInfo {
        IERC20 stakeToken; // address of the token staked on the underlying farm
        IYieldWolfStrategy strategy; // address of the strategy for the pool
    }

    PoolInfo[] public poolInfo; // info of each pool
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // info of each user that stakes tokens
    mapping(address => EnumerableSet.UintSet) private userStakedPools; // all pools in which a user has tokens staked
    mapping(address => bool) public strategyExists; // map used to ensure strategies cannot be added twice

    uint256 constant DEPOSIT_FEE_CAP = 500;
    uint256 public depositFee = 0;

    uint256 constant WITHDRAW_FEE_CAP = 500;
    uint256 public withdrawFee = 50;

    uint256 constant PERFORMANCE_FEE_CAP = 500;
    uint256 public performanceFee = 100;
    uint256 public performanceFeeBountyPct = 1000;

    uint256 constant RULE_EXECUTION_FEE_CAP = 500;
    uint256 public ruleFee = 20;
    uint256 public ruleFeeBountyPct = 5000;

    uint256 constant MAX_USER_RULES_PER_POOL = 50;

    address public feeAddress;
    address public feeAddressSetter;

    bool private executeRuleLocked;

    // addresses allowed to operate the strategy, including pausing and unpausing it in case of emergency
    mapping(address => bool) public operators;

    event Add(IERC20 stakeToken, IYieldWolfStrategy strategy);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, address indexed to, uint256 indexed pid, uint256 amount);
    event AddRule(address indexed user, uint256 indexed pid);
    event RemoveRule(address indexed user, uint256 indexed pid, uint256 ruleIndex);
    event Earn(address indexed user, uint256 indexed pid, uint256 bountyReward);
    event ExecuteRule(uint256 indexed pid, address indexed user, uint256 ruleIndex);
    event SetOperator(address addr, bool isOperator);
    event SetDepositFee(uint256 depositFee);
    event SetWithdrawFee(uint256 withdrawFee);
    event SetPerformanceFee(uint256 performanceFee);
    event SetPerformanceFeeBountyPct(uint256 performanceFeeBountyPct);
    event SetRuleFee(uint256 ruleFee);
    event SetRuleFeeBountyPct(uint256 ruleFeeBountyPct);
    event SetStrategyRouter(IYieldWolfStrategy strategy, address router);
    event SetStrategySwapRouterEnabled(IYieldWolfStrategy strategy, bool enabled);
    event SetStrategySwapPath(IYieldWolfStrategy _strategy, address _token0, address _token1, address[] _path);
    event SetStrategyExtraEarnTokens(IYieldWolfStrategy _strategy, address[] _extraEarnTokens);
    event SetFeeAddress(address feeAddress);
    event SetFeeAddressSetter(address feeAddressSetter);

    modifier onlyOperator() {
        require(operators[msg.sender], 'onlyOperator: NOT_ALLOWED');
        _;
    }

    modifier onlyEndUser() {
        require(!Address.isContract(msg.sender) && tx.origin == msg.sender);
        _;
    }

    constructor(address _feeAddress) {
        operators[msg.sender] = true;
        feeAddressSetter = msg.sender;
        feeAddress = _feeAddress;
    }

    /**
     * @notice returns how many pools have been added
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @notice returns in how many pools a user has tokens staked
     * @param _user address of the user
     */
    function userStakedPoolLength(address _user) external view returns (uint256) {
        return userStakedPools[_user].length();
    }

    /**
     * @notice returns the pid of a pool in which the user has tokens staked
     * @dev helper for iterating over the array of user staked pools
     * @param _user address of the user
     * @param _index the index in the array of user staked pools
     */
    function userStakedPoolAt(address _user, uint256 _index) external view returns (uint256) {
        return userStakedPools[_user].at(_index);
    }

    /**
     * @notice returns a rule by pid, user and index
     * @dev helper for iterating over all the rules
     * @param _pid the pool id
     * @param _user address of the user
     * @param _ruleIndex the index of the rule
     */
    function userPoolRule(
        uint256 _pid,
        address _user,
        uint256 _ruleIndex
    ) external view returns (Rule memory rule) {
        rule = userInfo[_pid][_user].rules[_ruleIndex];
    }

    /**
     * @notice returns the number of rule a user has for a given pool
     * @param _pid the pool id
     * @param _user address of the user
     */
    function userRuleLength(uint256 _pid, address _user) external view returns (uint256) {
        return userInfo[_pid][_user].rules.length;
    }

    /**
     * @notice returns the amount of staked tokens by a user
     * @param _pid the pool id
     * @param _user address of the user
     */
    function stakedTokens(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        IYieldWolfStrategy strategy = pool.strategy;

        uint256 sharesTotal = strategy.sharesTotal();
        return sharesTotal > 0 ? (user.shares * strategy.totalStakeTokens()) / sharesTotal : 0;
    }

    /**
     * @notice adds a new pool with a given strategy
     * @dev can only be called by an operator
     * @param _strategy address of the strategy
     */
    function add(IYieldWolfStrategy _strategy) public onlyOperator {
        require(!strategyExists[address(_strategy)], 'add: STRATEGY_ALREADY_EXISTS');
        IERC20 stakeToken = IERC20(_strategy.stakeToken());
        poolInfo.push(PoolInfo({stakeToken: stakeToken, strategy: _strategy}));
        strategyExists[address(_strategy)] = true;
        emit Add(stakeToken, _strategy);
    }

    /**
     * @notice adds multiple new pools
     * @dev helper to add many pools at once
     * @param _strategies array of strategy addresses
     */
    function addMany(IYieldWolfStrategy[] calldata _strategies) external onlyOperator {
        for (uint256 i; i < _strategies.length; i++) {
            add(_strategies[i]);
        }
    }

    /**
     * @notice transfers tokens from the user and stakes them in the underlying farm
     * @dev tokens are transferred from msg.sender directly to the strategy
     * @param _pid the pool id
     * @param _depositAmount amount of tokens to transfer from msg.sender
     */
    function deposit(uint256 _pid, uint256 _depositAmount) external {
        _deposit(_pid, _depositAmount, msg.sender);
    }

    /**
     * @notice deposits stake tokens on behalf of another user
     * @param _pid the pool id
     * @param _depositAmount amount of tokens to transfer from msg.sender
     * @param _to address of the beneficiary
     */
    function depositTo(
        uint256 _pid,
        uint256 _depositAmount,
        address _to
    ) external {
        _deposit(_pid, _depositAmount, _to);
    }

    /**
     * @notice unstakes tokens from the underlying farm and transfers them to the user
     * @dev tokens are transferred directly from the strategy to the user
     * @param _pid the pool id
     * @param _withdrawAmount maximum amount of tokens to transfer to msg.sender
     */
    function withdraw(uint256 _pid, uint256 _withdrawAmount) external {
        _withdrawFrom(msg.sender, msg.sender, _pid, _withdrawAmount, address(0), 0, false);
    }

    /**
     * @notice withdraws all the token from msg.sender without harvesting first
     * @dev only for emergencies
     * @param _pid the pool id
     */
    function emergencyWithdraw(uint256 _pid) external {
        _withdrawFrom(msg.sender, msg.sender, _pid, type(uint256).max, address(0), 0, true);
    }

    /**
     * @notice adds a new rule
     * @dev each user can have multiple rules for each pool
     * @param _pid the pool id
     * @param _condition address of the condition contract
     * @param _conditionIntInputs array of integer inputs to be sent to the condition
     * @param _conditionAddrInputs array of address inputs to be sent to the condition
     * @param _action address of the action contract
     * @param _actionIntInputs array of integer inputs to be sent to the action
     * @param _actionAddrInputs array of address inputs to be sent to the action
     */
    function addRule(
        uint256 _pid,
        address _condition,
        uint256[] calldata _conditionIntInputs,
        address[] calldata _conditionAddrInputs,
        address _action,
        uint256[] calldata _actionIntInputs,
        address[] calldata _actionAddrInputs
    ) external {
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.rules.length <= MAX_USER_RULES_PER_POOL, 'addRule: CAP_EXCEEDED');
        require(IYieldWolfCondition(_condition).isCondition(), 'addRule: BAD_CONDITION');
        require(IYieldWolfAction(_action).isAction(), 'addRule: BAD_ACTION');

        Rule memory rule;
        rule.condition = _condition;
        rule.conditionIntInputs = _conditionIntInputs;
        rule.conditionAddrInputs = _conditionAddrInputs;
        rule.action = _action;
        rule.actionIntInputs = _actionIntInputs;
        rule.actionAddrInputs = _actionAddrInputs;
        user.rules.push(rule);
        emit AddRule(msg.sender, _pid);
    }

    /**
     * @notice removes a given rule
     * @param _pid the pool id
     * @param _ruleIndex the index of the rule in the user info for the given pool
     */
    function removeRule(uint256 _pid, uint256 _ruleIndex) external {
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_ruleIndex < user.rules.length, 'removeRule: BAD_INDEX');
        user.rules[_ruleIndex] = user.rules[user.rules.length - 1];
        user.rules.pop();
        emit RemoveRule(msg.sender, _pid, _ruleIndex);
    }

    /**
     * @notice runs the strategy and pays the bounty reward
     * @param _pid the pool id
     */
    function earn(uint256 _pid) external nonReentrant returns (uint256) {
        return _earn(_pid);
    }

    /**
     * @notice runs multiple strategies and pays multiple rewards
     * @param _pids array of pool ids
     */
    function earnMany(uint256[] calldata _pids) external nonReentrant {
        for (uint256 i; i < _pids.length; i++) {
            _earn(_pids[i]);
        }
    }

    /**
     * @notice checks wheter a rule passes its condition
     * @param _pid the pool id
     * @param _user address of the user
     * @param _ruleIndex the index of the rule
     */
    function checkRule(
        uint256 _pid,
        address _user,
        uint256 _ruleIndex
    ) external view returns (bool) {
        Rule memory rule = userInfo[_pid][_user].rules[_ruleIndex];
        return
            IYieldWolfCondition(rule.condition).check(
                address(poolInfo[_pid].strategy),
                _user,
                _pid,
                rule.conditionIntInputs,
                rule.conditionAddrInputs
            );
    }

    /**
     * @notice executes the rule action if the condition passes and sends the bounty reward to msg.sender
     * @param _pid the pool id
     * @param _user address of the user
     * @param _ruleIndex the index of the rule
     */
    function executeRule(
        uint256 _pid,
        address _user,
        uint256 _ruleIndex
    ) external onlyEndUser {
        require(!executeRuleLocked, 'executeRule: LOCKED');
        executeRuleLocked = true;
        UserInfo memory user = userInfo[_pid][_user];
        Rule memory rule = user.rules[_ruleIndex];
        IYieldWolfStrategy strategy = poolInfo[_pid].strategy;

        require(
            IYieldWolfCondition(rule.condition).check(
                address(strategy),
                _user,
                _pid,
                rule.conditionIntInputs,
                rule.conditionAddrInputs
            ),
            'executeAction: CONDITION_NOT_MET'
        );

        _tryEarn(strategy);
        IYieldWolfAction action = IYieldWolfAction(rule.action);
        (uint256 withdrawAmount, address withdrawTo) = action.execute(
            address(strategy),
            _user,
            _pid,
            rule.actionIntInputs,
            rule.actionAddrInputs
        );

        uint256 staked = stakedTokens(_pid, _user);
        if (withdrawAmount > staked) {
            withdrawAmount = staked;
        }

        if (withdrawAmount > 0) {
            uint256 ruleFeeAmount = (withdrawAmount * ruleFee) / 10000;
            _withdrawFrom(_user, withdrawTo, _pid, withdrawAmount, msg.sender, ruleFeeAmount, true);
        }
        action.callback(address(strategy), _user, _pid, rule.actionIntInputs, rule.actionAddrInputs);
        executeRuleLocked = false;
        emit ExecuteRule(_pid, _user, _ruleIndex);
    }

    /**
     * @notice adds or removes an operator
     * @dev can only be called by the owner
     * @param _addr address of the operator
     * @param _isOperator whether the given address will be set as an operator
     */
    function setOperator(address _addr, bool _isOperator) external onlyOwner {
        operators[_addr] = _isOperator;
        emit SetOperator(_addr, _isOperator);
    }

    /**
     * @notice updates the deposit fee
     * @dev can only be called by the owner
     * @param _depositFee new deposit fee in basis points
     */
    function setDepositFee(uint256 _depositFee) external onlyOwner {
        require(_depositFee <= DEPOSIT_FEE_CAP, 'setDepositFee: CAP_EXCEEDED');
        depositFee = _depositFee;
        emit SetDepositFee(_depositFee);
    }

    /**
     * @notice updates the withdraw fee
     * @dev can only be called by the owner
     * @param _withdrawFee new withdraw fee in basis points
     */
    function setWithdrawFee(uint256 _withdrawFee) external onlyOwner {
        require(_withdrawFee <= WITHDRAW_FEE_CAP, 'setWithdrawFee: CAP_EXCEEDED');
        withdrawFee = _withdrawFee;
        emit SetWithdrawFee(_withdrawFee);
    }

    /**
     * @notice updates the performance fee
     * @dev can only be called by the owner
     * @param _performanceFee new performance fee fee in basis points
     */
    function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
        require(_performanceFee <= PERFORMANCE_FEE_CAP, 'setPerformanceFee: CAP_EXCEEDED');
        performanceFee = _performanceFee;
        emit SetPerformanceFee(_performanceFee);
    }

    /**
     * @notice updates the percentage of the performance fee sent to the bounty hunter
     * @dev can only be called by the owner
     * @param _performanceFeeBountyPct percentage of the performance fee for the bounty hunter in basis points
     */
    function setPerformanceFeeBountyPct(uint256 _performanceFeeBountyPct) external onlyOwner {
        require(_performanceFeeBountyPct <= 10000, 'setPerformanceFeeBountyPct: CAP_EXCEEDED');
        performanceFeeBountyPct = _performanceFeeBountyPct;
        emit SetPerformanceFeeBountyPct(_performanceFeeBountyPct);
    }

    /**
     * @notice updates the rule execution fee
     * @dev can only be called by the owner
     * @param _ruleFee new rule fee fee in basis points
     */
    function setRuleFee(uint256 _ruleFee) external onlyOwner {
        require(_ruleFee <= RULE_EXECUTION_FEE_CAP, 'setRuleFee: CAP_EXCEEDED');
        ruleFee = _ruleFee;
        emit SetRuleFee(_ruleFee);
    }

    /**
     * @notice updates the percentage of the rule execution fee sent to the bounty hunter
     * @dev can only be called by the owner
     * @param _ruleFeeBountyPct percentage of the rule execution fee for the bounty hunter in basis points
     */
    function setRuleFeeBountyPct(uint256 _ruleFeeBountyPct) external onlyOwner {
        require(_ruleFeeBountyPct <= 10000, 'setRuleFeeBountyPct: CAP_EXCEEDED');
        ruleFeeBountyPct = _ruleFeeBountyPct;
        emit SetRuleFeeBountyPct(_ruleFeeBountyPct);
    }

    /**
     * @notice updates the swap router used by a given strategy
     * @dev can only be called by the owner
     * @param _strategy address of the strategy
     * @param _enabled whether to enable or disable the swap router
     */
    function setStrategySwapRouterEnabled(IYieldWolfStrategy _strategy, bool _enabled) external onlyOwner {
        _strategy.setSwapRouterEnabled(_enabled);
        emit SetStrategySwapRouterEnabled(_strategy, _enabled);
    }

    /**
     * @notice updates the swap path for a given pair
     * @dev can only be called by the owner
     * @param _strategy address of the strategy
     * @param _token0 address of token swap from
     * @param _token1 address of token swap to
     * @param _path swap path from token0 to token1
     */
    function setStrategySwapPath(
        IYieldWolfStrategy _strategy,
        address _token0,
        address _token1,
        address[] calldata _path
    ) external onlyOwner {
        require(_path.length != 1, 'setStrategySwapPath: INVALID_PATH');
        if (_path.length > 0) {
            // the first element must be token0 and the last one token1
            require(_path[0] == _token0 && _path[_path.length - 1] == _token1, 'setStrategySwapPath: INVALID_PATH');
        }
        _strategy.setSwapPath(_token0, _token1, _path);
        emit SetStrategySwapPath(_strategy, _token0, _token1, _path);
    }

    /**
     * @notice updates the swap path for a given pair
     * @dev can only be called by the owner
     * @param _strategy address of the strategy
     * @param _extraEarnTokens list of extra earn tokens for farms rewarding more than one token
     */
    function setStrategyExtraEarnTokens(IYieldWolfStrategy _strategy, address[] calldata _extraEarnTokens)
        external
        onlyOwner
    {
        require(_extraEarnTokens.length <= 5, 'setStrategyExtraEarnTokens: CAP_EXCEEDED');

        // tokens sanity check
        for (uint256 i; i < _extraEarnTokens.length; i++) {
            IERC20(_extraEarnTokens[i]).balanceOf(address(this));
        }

        _strategy.setExtraEarnTokens(_extraEarnTokens);
        emit SetStrategyExtraEarnTokens(_strategy, _extraEarnTokens);
    }

    /**
     * @notice updates the fee address
     * @dev can only be called by the fee address setter
     * @param _feeAddress new fee address
     */
    function setFeeAddress(address _feeAddress) external {
        require(msg.sender == feeAddressSetter && _feeAddress != address(0), 'setFeeAddress: NOT_ALLOWED');
        feeAddress = _feeAddress;
        emit SetFeeAddress(_feeAddress);
    }

    /**
     * @notice updates the fee address setter
     * @dev can only be called by the previous fee address setter
     * @param _feeAddressSetter new fee address setter
     */
    function setFeeAddressSetter(address _feeAddressSetter) external {
        require(msg.sender == feeAddressSetter && _feeAddressSetter != address(0), 'setFeeAddressSetter: NOT_ALLOWED');
        feeAddressSetter = _feeAddressSetter;
        emit SetFeeAddressSetter(_feeAddressSetter);
    }

    function _deposit(
        uint256 _pid,
        uint256 _depositAmount,
        address _to
    ) internal nonReentrant {
        require(_depositAmount > 0, 'deposit: MUST_BE_GREATER_THAN_ZERO');
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_to];

        if (pool.strategy.sharesTotal() > 0) {
            _tryEarn(pool.strategy);
        }

        // calculate deposit amount from balance before and after the transfer in order to support tokens with tax
        uint256 balanceBefore = pool.stakeToken.balanceOf(address(pool.strategy));
        pool.stakeToken.safeTransferFrom(address(msg.sender), address(pool.strategy), _depositAmount);
        _depositAmount = pool.stakeToken.balanceOf(address(pool.strategy)) - balanceBefore;

        uint256 sharesAdded = pool.strategy.deposit(_depositAmount);
        user.shares = user.shares + sharesAdded;
        userStakedPools[_to].add(_pid);

        emit Deposit(_to, _pid, _depositAmount);
    }

    function _withdrawFrom(
        address _user,
        address _to,
        uint256 _pid,
        uint256 _withdrawAmount,
        address _bountyHunter,
        uint256 _ruleFeeAmount,
        bool _skipEarn
    ) internal nonReentrant {
        require(_withdrawAmount > 0, '_withdrawFrom: MUST_BE_GREATER_THAN_ZERO');
        UserInfo storage user = userInfo[_pid][_user];
        IYieldWolfStrategy strategy = poolInfo[_pid].strategy;

        if (!_skipEarn) {
            _tryEarn(strategy);
        }

        uint256 sharesTotal = strategy.sharesTotal();

        require(user.shares > 0 && sharesTotal > 0, 'withdraw: NO_SHARES');

        uint256 maxAmount = (user.shares * strategy.totalStakeTokens()) / sharesTotal;
        if (_withdrawAmount > maxAmount) {
            _withdrawAmount = maxAmount;
        }
        uint256 sharesRemoved = strategy.withdraw(_withdrawAmount, _to, _bountyHunter, _ruleFeeAmount);
        user.shares = user.shares > sharesRemoved ? user.shares - sharesRemoved : 0;
        if (user.shares == 0) {
            userStakedPools[_user].remove(_pid);
        }

        emit Withdraw(_user, _to, _pid, _withdrawAmount);
    }

    function _earn(uint256 _pid) internal returns (uint256 bountyRewarded) {
        bountyRewarded = poolInfo[_pid].strategy.earn(msg.sender);
        emit Earn(msg.sender, _pid, bountyRewarded);
    }

    function _tryEarn(IYieldWolfStrategy _strategy) internal {
        try _strategy.earn(address(0)) {} catch {}
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
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

pragma solidity 0.8.4;

interface IYieldWolfStrategy {
    function stakeToken() external view returns (address);

    function sharesTotal() external view returns (uint256);

    function earn(address _bountyHunter) external returns (uint256);

    function deposit(uint256 _depositAmount) external returns (uint256);

    function withdraw(
        uint256 _withdrawAmount,
        address _withdrawTo,
        address _bountyHunter,
        uint256 _ruleFeeAmount
    ) external returns (uint256);

    function router() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function totalStakeTokens() external view returns (uint256);

    function setSwapRouterEnabled(bool _enabled) external;

    function setSwapPath(
        address _token0,
        address _token1,
        address[] calldata _path
    ) external;

    function setExtraEarnTokens(address[] calldata _extraEarnTokens) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IYieldWolfCondition {
    function isCondition() external view returns (bool);

    function check(
        address strategy,
        address user,
        uint256 pid,
        uint256[] memory intInputs,
        address[] memory addrInputs
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IYieldWolfAction {
    function isAction() external view returns (bool);

    function execute(
        address strategy,
        address user,
        uint256 pid,
        uint256[] memory intInputs,
        address[] memory addrInputs
    ) external view returns (uint256, address);

    function callback(
        address strategy,
        address user,
        uint256 pid,
        uint256[] memory intInputs,
        address[] memory addrInputs
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        return msg.data;
    }
}

