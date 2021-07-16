//SourceUnit: WINR_flattened.sol

pragma solidity ^0.5.4;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

pragma solidity ^0.5.4;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address payable private _owner;
    mapping(address => bool) private _owners;
    event OwnershipGiven(address indexed newOwner);
    event OwnershipTaken(address indexed previousOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        address payable msgSender = msg.sender;
        _addOwnership(msgSender);
        _owner = msgSender;
        emit OwnershipGiven(msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() private view returns (address payable) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner 1");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _owners[msg.sender];
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function addOwnership(address payable newOwner) public onlyOwner {
        _addOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _addOwnership(address payable newOwner) private {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipGiven(newOwner);
        _owners[newOwner] = true;
    }

    function _removeOwnership(address payable __owner) private {
        _owners[__owner] = false;
        emit OwnershipTaken(__owner);
    }

    function removeOwnership(address payable __owner) public onlyOwner {
        _removeOwnership(__owner);
    }
}

pragma solidity ^0.5.4;

contract Sender is Ownable, Pausable {
    function sendTRX(
        address payable _to,
        uint256 _amount,
        uint256 _gasForTransfer
    ) external whenPaused onlyOwner {
        _to.call.value(_amount).gas(_gasForTransfer)("");
    }

    function sendTRC20(
        address payable _to,
        uint256 _amount,
        ITRC20 _token
    ) external whenPaused onlyOwner {
        _token.transfer(_to, _amount);
    }
}

pragma solidity ^0.5.4;

contract TRC20Detailed {
    //Token Details
    string public _name;
    string public _symbol;
    uint8 public _decimals;

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.4;

interface IStaking {
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 total,
        bytes data
    );
    event Unstaked(
        address indexed user,
        uint256 amount,
        uint256 total,
        bytes data
    );

    function stake(uint256 amount, bytes calldata data) external;

    function unstake(uint256 amount, bytes calldata data) external;

    function totalStaked() external view returns (uint256);

    function isStakeholder() external view returns (bool);

    function stats(uint256 dayCount)
        external
        view
        returns (uint256 staked, uint256 distributed);
}

pragma solidity ^0.5.4;

/**
 * @title TRC20 interface (compatible with ERC20 interface)
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.5.4;

/**
 * @title Standard TRC20 token (compatible with ERC20 token)
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract TRC20 is ITRC20, Pausable {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value)
        public
        whenNotPaused
        returns (bool)
    {
        require(_balances[msg.sender] >= value, "Insuffience Balance");
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        public
        whenNotPaused
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public whenNotPaused returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        whenNotPaused
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
            _allowed[msg.sender][spender].add(addedValue)
        );
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        whenNotPaused
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
            _allowed[msg.sender][spender].sub(subtractedValue)
        );
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
            value
        );
        _burn(account, value);
    }
}

pragma solidity ^0.5.4;

contract Staking is Sender, TRC20, TRC20Detailed {
    using SafeMath for uint256;
    event Staked(address payable indexed user, uint256 amount);
    event Unstaked(address payable indexed user, uint256 amount);
    event StakeWithdrawn(address payable indexed user, uint256 amount);
    event TRXRewardsDistributed();
    event TRC20RewardsDistributed();

    uint256 private rewardToDistribute;

    uint256 public gasForTransferTRX = 3000;

    mapping(address => uint256) internal _activeStakes;
    mapping(address => uint256) internal _passiveStakes;
    mapping(address => uint256) internal _unstakedTime;

    mapping(address => uint256) internal rewards;

    uint256 public activeStakesAmount;
    uint256 public passiveStakesAmount;
    uint256 public freezingPeriod = 86400;

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function sendTRX(
        address payable _to,
        uint256 _amount,
        uint256 _gasForTransferTRX
    ) external whenPaused onlyOwner {
        _to.call.value(_amount).gas(_gasForTransferTRX)("");
    }

    function isStakeholder(address _address) public view returns (bool) {
        return _passiveStakes[_address] > 0 || _activeStakes[_address] > 0;
    }

    function stakeOf(address _stakeholder)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _activeStakes[_stakeholder],
            _passiveStakes[_stakeholder],
            _unstakedTime[_stakeholder]
        );
    }

    function stake(uint256 _stake) external whenNotPaused() {
        require(
            _passiveStakes[msg.sender] == 0,
            "There is existing passive stake of the user"
        );
        require(_stake <= balanceOf(msg.sender), "Insufficient Balance");

        _balances[msg.sender] = _balances[msg.sender].sub(_stake);
        activeStakesAmount += _stake;

        _activeStakes[msg.sender] = _activeStakes[msg.sender].add(_stake);
        emit Staked(msg.sender, _stake);
    }

    function unstake() external whenNotPaused() {
        require(_activeStakes[msg.sender] > 0, "No stake to unstake");

        uint256 stake = _activeStakes[msg.sender];
        delete _activeStakes[msg.sender];

        _passiveStakes[msg.sender] = stake;
        _unstakedTime[msg.sender] = now;

        activeStakesAmount -= stake;
        passiveStakesAmount += stake;

        emit Unstaked(msg.sender, stake);
    }

    function withdrawStake() external whenNotPaused() {
        require(_passiveStakes[msg.sender] > 0, "No stake to withdraw.");
        require(now >= _unstakedTime[msg.sender] + freezingPeriod, "Time.");

        uint256 stake = _passiveStakes[msg.sender];
        delete _passiveStakes[msg.sender];

        passiveStakesAmount -= stake;

        _balances[msg.sender] = _balances[msg.sender].add(stake);
        emit StakeWithdrawn(msg.sender, stake);
    }

    function setGasForTRXTransfer(uint256 _gasForTransferTRXAmount)
        external
        onlyOwner
    {
        gasForTransferTRX = _gasForTransferTRXAmount;
    }

    function distributeTRXRewards(
        address payable[] memory _stakeholders,
        uint256[] memory _rewards
    ) public onlyOwner {
        require(
            _stakeholders.length == _rewards.length,
            "_stakeholders and _rewards array must have equal length"
        );
        for (uint256 i = 0; i < _stakeholders.length; i++) {
            (bool success, bytes memory data) = _stakeholders[i]
                .call
                .value(_rewards[i])
                .gas(gasForTransferTRX)("");
        }
        emit TRXRewardsDistributed();
    }

    function distributeTRC20Rewards(
        address payable[] memory _stakeholders,
        uint256[] memory _rewards,
        TRC20 token
    ) public onlyOwner {
        require(
            _stakeholders.length == _rewards.length,
            "_stakeholders and _rewards array must have equal length"
        );
        for (uint256 i = 0; i < _stakeholders.length; i++) {
            token.transfer(_stakeholders[i], _rewards[i]);
        }
        emit TRC20RewardsDistributed();
    }
}

pragma solidity ^0.5.4;

contract OwnedByRouter is Ownable {
    address payable internal routerContract;
    modifier onlyRouter() {
        require(
            msg.sender == routerContract,
            "Router Ownable: caller is not the router"
        );
        _;
    }

    function getRouter() public view returns (address router) {
        router = routerContract;
    }

    function setRouter(address payable _addr) public onlyOwner {
        removeOwnership(routerContract);
        routerContract = _addr;
        addOwnership(_addr);
    }
}

pragma solidity ^0.5.4;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.5.4;

interface ILottery {
    function buy(uint256[5] calldata, address payable) external;
}

interface IRouter {
    function getYesterday()
        external
        returns (
            uint256 wager,
            uint256 lose,
            uint256 win,
            uint256 sentBack,
            uint256 revenue,
            uint256 dailyCoefficient
        );
}

/**
Winr contract, extended from staking (TRC20)
*/

contract WINR is OwnedByRouter, Staking {
    event Set(address indexed addr, string indexed addrType);
    event RoundStart(uint256 indexed round, uint256 timestamp);
    event MintingEnd(uint256 date);
    event RewardsDistributed(uint256 amount);

    uint256 private maxSupply;
    uint256 private maxMinted;

    address private _lotteryContract;

    mapping(address => VestingData) public vestingData;

    struct VestingData {
        uint256 amount;
        uint256 vestedPeriods;
    }

    uint256 public vestingStartTime;
    uint256 public vestingPeriodsNumber = 6;
    uint256 public vestingPeriod = 90 days;

    uint256 public totalMinted = 0;
    uint256 public activeRound;
    bool private _roundsInstalled;
    bool private _mintingFinished = false;
    uint256 public _lotteryBalanceMint = 0;

    uint256[3] public topPlayersMultiplier = [500, 300, 200];
    address[3] public topPlayers;
    mapping(address => uint8) public topPlayerIndex;

    mapping(address => uint256) public minedToUser;

    Round[] public rounds;

    struct Round {
        uint16 allocation;
        uint256 amount;
        uint16 payout;
        uint256 minted;
        uint256 totalBeforeRound;
        bool exists;
    }

    constructor(
        address[] memory _vestingAddresses,
        uint256[] memory _vestingAmounts,
        address[] memory _mintedAddresses,
        uint256[] memory _mintedAmounts,
        uint256 _vestingStartTime
    ) public {
        _roundsInstalled = false;
        require(
            _vestingAddresses.length != 0 && _mintedAddresses.length != 0,
            "Addressess needed"
        );
        require(
            _vestingAddresses.length == _vestingAmounts.length,
            "Vesting addresses and amounts lengths must be equal."
        );
        require(
            _mintedAddresses.length == _mintedAmounts.length,
            "Minted addresses and amounts lengths must be equal."
        );

        maxSupply = 10 * 1e9 * 1e6;
        maxMinted = 6 * 1e9 * 1e6;
        vestingStartTime = _vestingStartTime;
        _lotteryContract = address(0);

        for (uint256 i = 0; i < _mintedAddresses.length; i++) {
            _mint(_mintedAddresses[i], _mintedAmounts[i]);
        }

        for (uint256 i = 0; i < _vestingAddresses.length; i++) {
            vestingData[_vestingAddresses[i]].amount = _vestingAmounts[i];
        }

        installRounds();
        _name = "WINR";
        _symbol = "WINR";
        _decimals = 6;
    }

    function withdrawVested() external returns (uint256 amount) {
        require(
            vestingData[msg.sender].amount > 0,
            "You aren't in the vesting list"
        );

        uint256 vestedPeriods = vestingData[msg.sender].vestedPeriods;

        require(
            vestedPeriods < vestingPeriodsNumber,
            "You vested all your WINRs."
        );

        uint256 periodsToVest = now
            .sub(vestingStartTime)
            .div(vestingPeriod)
            .sub(vestedPeriods);

        require(periodsToVest > 0, "Nothing to vest now");

        if (periodsToVest.add(vestedPeriods) > vestingPeriodsNumber) {
            periodsToVest = vestingPeriodsNumber.sub(vestedPeriods);
        }

        amount = vestingData[msg.sender].amount.mul(periodsToVest).div(
            vestingPeriodsNumber
        );

        vestingData[msg.sender].vestedPeriods = vestedPeriods.add(
            periodsToVest
        );
        _mint(msg.sender, amount);
    }

    function() external payable {}

    function installRounds() public {
        require(!_roundsInstalled, "This function can be executed once");
        addRound(152, 912000000, 5000);
        addRound(133, 798000000, 2500);
        addRound(95, 570000000, 1000);
        addRound(96, 576000000, 1250);
        addRound(48, 288000000, 1000);
        addRound(96, 576000000, 500);
        addRound(95, 570000000, 250);
        addRound(133, 798000000, 125);
        addRound(152, 912000000, 250);
        addRound(0, 0, 0);
        _roundsInstalled = true;
        activeRound = 0;
    }

    function addRound(
        uint16 allocation,
        uint256 amount,
        uint16 payout
    ) internal {
        Round memory round;
        round.allocation = allocation;
        round.amount = amount * 10**6;
        round.payout = payout;
        round.minted = 0;
        round.exists = true;
        rounds.push(round);
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    function getActiveRoundID() public view returns (uint256) {
        return activeRound;
    }

    function getRound(uint256 _roundID)
        public
        view
        returns (
            uint16 allocation,
            uint256 amount,
            uint16 payout,
            uint256 minted
        )
    {
        Round memory rnd = rounds[_roundID];
        return (rnd.allocation, rnd.amount, rnd.payout, rnd.minted);
    }

    function getActiveRound()
        public
        view
        returns (
            uint16 allocation,
            uint256 amount,
            uint16 payout,
            uint256 minted
        )
    {
        return getRound(activeRound);
    }

    function getTopPlayerMultiplier(address addr)
        public
        view
        returns (uint256)
    {
        if (topPlayerIndex[addr] != 0) {
            uint256 index = topPlayerIndex[addr];
            if (topPlayers[index] != addr) return 0;
            return topPlayersMultiplier[topPlayerIndex[addr] - 1];
        }
        return 0;
    }

    function setTopPlayers(
        address top1,
        address top2,
        address top3
    ) public onlyRouter {
        topPlayers[0] = top1;
        topPlayerIndex[top1] = 1;
        topPlayers[1] = top2;
        topPlayerIndex[top2] = 2;
        topPlayers[2] = top3;
        topPlayerIndex[top3] = 3;
    }

    function setTopPlayersMultipliers(
        uint8 top1multiplier,
        uint8 top2multiplier,
        uint8 top3multiplier
    ) public onlyRouter {
        topPlayersMultiplier = [top1multiplier, top2multiplier, top3multiplier];
    }

    event MiningData(
        uint256 wager,
        uint256 dailyCoef,
        uint256 payout,
        uint256 value
    );

    function mine(
        address to,
        uint256 wager,
        uint256 dailyCoef,
        uint256 totalWagered
    ) public onlyRouter {
        Round memory round = rounds[activeRound];
        dailyCoef = dailyCoef == 0 ? 1 : dailyCoef;
        totalWagered = totalWagered == 0 ? 1 : totalWagered;
        uint256 tokenValue = wager
            .mul(dailyCoef)
            .mul(round.payout)
            .div(1000)
            .div(totalWagered)
            .add(wager.mul(getTopPlayerMultiplier(to)).div(100));

        emit MiningData(wager, dailyCoef, round.payout, tokenValue);

        if (_mintingFinished) {
            mineFromLottery(to, tokenValue);
            return;
        }

        uint256 newTotal = totalMinted.add(tokenValue);
        if (newTotal >= maxMinted) {
            tokenValue = maxMinted.sub(totalMinted);
            _mintingFinished = true;
            _mint(to, tokenValue);
            totalMinted = totalMinted.add(tokenValue);
            rounds[activeRound].minted = round.minted.add(tokenValue);
            emit MintingEnd(now);
            activeRound++;
            return;
        }

        _mint(to, tokenValue);
        totalMinted = totalMinted.add(tokenValue);
        minedToUser[to] = minedToUser[to].add(tokenValue);
        rounds[activeRound].minted = round.minted.add(tokenValue);

        if (round.minted >= round.amount) {
            activeRound++;
            emit RoundStart(activeRound, now);
        }
    }

    function mineFromLottery(address to, uint256 tokenValue) private {
        uint256 lotteryBalance = balanceOf(_lotteryContract);
        if (tokenValue > lotteryBalance) {
            tokenValue = lotteryBalance;
        }
        _transfer(_lotteryContract, to, tokenValue);
        _lotteryBalanceMint += tokenValue;
    }

    function setLotteryContract(address addr) external onlyOwner {
        require(
            _lotteryContract == address(0),
            "This function can be executed only once"
        );
        _lotteryContract = addr;
    }

    function getLotteryContract() public view returns (address) {
        return _lotteryContract;
    }

    function buyLotteryTicket(uint256[5] memory numbers) public whenNotPaused {
        ILottery(_lotteryContract).buy(numbers, msg.sender);
        transfer(_lotteryContract, lotteryTicketPrice());
    }

    function lotteryTicketPrice() public view returns (uint256 price) {
        price = totalSupply() / 1000000000;
    }

    function distributeRewards(
        address[] calldata stakeholders,
        uint256[] calldata amounts
    ) external payable onlyOwner {
        require(msg.tokenid == 0, "Require only TRX");
        require(
            stakeholders.length == amounts.length,
            "Incorrect arrays lengths"
        );
        for (uint256 i = 0; i < stakeholders.length; i++) {
            stakeholders[i].call.value(amounts[i])("");
        }
        emit RewardsDistributed(msg.value);
    }
}