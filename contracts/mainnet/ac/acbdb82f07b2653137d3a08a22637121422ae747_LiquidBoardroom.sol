//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./interfaces/IVotingEscrow.sol";
import "./Boardroom.sol";

/// Boardroom distributes token emission among shareholders that stake Klon and lock Klon in veToken
contract LiquidBoardroom is Boardroom {
    /// Address of veToken
    IVotingEscrow public veToken;

    /// Creates new Boardroom
    /// @param _stakingToken address of the base token
    /// @param _tokenManager address of the TokenManager
    /// @param _emissionManager address of the EmissionManager
    /// @param _start start of the boardroom date
    constructor(
        address _stakingToken,
        address _tokenManager,
        address _emissionManager,
        uint256 _start
    )
        public
        Boardroom(_stakingToken, _tokenManager, _emissionManager, _start)
    {}

    /// Update veToken
    /// @param _veToken new token address
    function setVeToken(address _veToken) public onlyOwner {
        veToken = IVotingEscrow(_veToken);
        emit VeTokenChanged(msg.sender, _veToken);
    }

    /// Shows the balance of the virtual token that participates in reward calculation
    /// @param owner the owner of the share tokens
    function shareTokenBalance(address owner)
        public
        view
        override
        returns (uint256)
    {
        return stakingTokenBalances[owner].add(veToken.locked__balance(owner));
    }

    /// Shows the supply of the virtual token that participates in reward calculation
    function shareTokenSupply() public view override returns (uint256) {
        return stakingTokenSupply.add(veToken.supply());
    }

    event VeTokenChanged(address indexed operator, address newVeToken);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// Voting escrow interface
interface IVotingEscrow is IERC20 {
    function locked__balance(address _addr) external view returns (uint256);

    function supply() external view returns (uint256);

    function withdraw() external;

    function deposit_for(address _addr, uint256 _value) external;

    function create_lock(uint256 _value, uint256 _unlock_time) external;

    function increase_amount(uint256 _value) external;

    function increase_unlock_time(uint256 _unlock_time) external;
}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./time/Timeboundable.sol";
import "./SyntheticToken.sol";
import "./interfaces/ITokenManager.sol";
import "./interfaces/IBoardroom.sol";

/// Boardroom distributes token emission among shareholders
contract Boardroom is IBoardroom, ReentrancyGuard, Timeboundable, Operatable {
    using SafeMath for uint256;

    /// Added each time reward to the Boardroom is added
    struct PoolRewardSnapshot {
        /// when snapshost was made
        uint256 timestamp;
        /// how much reward was added at this snapshot
        uint256 addedSyntheticReward;
        /// accumulated reward per share unit (10^18 of reward token)
        uint256 accruedRewardPerShareUnit;
    }

    /// Accumulated personal rewards available for claiming
    struct PersonRewardAccrual {
        /// Last accrual time represented by snapshotId
        uint256 lastAccrualSnaphotId;
        /// Accrued and ready for distribution reward
        uint256 accruedReward;
    }

    /// A set of PoolRewardSnapshots for every synthetic token
    mapping(address => PoolRewardSnapshot[]) public poolRewardSnapshots;
    /// A set of records of personal accumulated income.
    /// The first key is token, the second is holder address.
    mapping(address => mapping(address => PersonRewardAccrual))
        public personRewardAccruals;

    /// Pause
    bool public pause;

    /// one unit of staking token (e.g. # of wei in eth)
    uint256 public immutable stakingUnit;

    /// Staking token. Both base and boost token yield reward token which ultimately participates in rewards distribution.
    SyntheticToken public stakingToken;
    /// TokenManager ref
    ITokenManager public tokenManager;
    /// EmissionManager ref
    address public emissionManager;

    /// Staking token supply in the Boardroom
    uint256 public stakingTokenSupply;
    /// Staking token balances in the Boardroom
    mapping(address => uint256) public stakingTokenBalances;

    /// Creates new Boardroom
    /// @param _stakingToken address of the base token. Should have 18 decimals.
    /// @param _tokenManager address of the TokenManager
    /// @param _emissionManager address of the EmissionManager
    /// @param _start start of the boardroom date
    constructor(
        address _stakingToken,
        address _tokenManager,
        address _emissionManager,
        uint256 _start
    ) public Timeboundable(_start, 0) {
        stakingToken = SyntheticToken(_stakingToken);
        stakingUnit = uint256(10)**18;
        tokenManager = ITokenManager(_tokenManager);
        emissionManager = _emissionManager;
    }

    // ------- Modifiers ----------

    /// Checks if pause is set
    modifier unpaused() {
        require(!pause, "Boardroom operations are paused");
        _;
    }

    // ------- Public ----------

    /// Funds available for user to withdraw
    /// @param syntheticTokenAddress the token we're looking up balance for
    /// @param owner the owner of the token
    function availableForWithdraw(address syntheticTokenAddress, address owner)
        public
        view
        returns (uint256)
    {
        PersonRewardAccrual storage accrual =
            personRewardAccruals[syntheticTokenAddress][owner];
        PoolRewardSnapshot[] storage tokenSnapshots =
            poolRewardSnapshots[syntheticTokenAddress];
        if (tokenSnapshots.length == 0) {
            return 0;
        }
        PoolRewardSnapshot storage lastSnapshot =
            tokenSnapshots[tokenSnapshots.length.sub(1)];
        uint256 lastOverallRPSU = lastSnapshot.accruedRewardPerShareUnit;
        PoolRewardSnapshot storage lastAccrualSnapshot =
            tokenSnapshots[accrual.lastAccrualSnaphotId];
        uint256 lastUserAccrualRPSU =
            lastAccrualSnapshot.accruedRewardPerShareUnit;
        uint256 deltaRPSU = lastOverallRPSU.sub(lastUserAccrualRPSU);
        uint256 addedUserReward =
            shareTokenBalance(owner).mul(deltaRPSU).div(stakingUnit);
        return accrual.accruedReward.add(addedUserReward);
    }

    /// Stake tokens into Boardroom
    /// @param to the receiver of the token
    /// @param amount amount of staking token
    function stake(address to, uint256 amount)
        public
        nonReentrant
        inTimeBounds
        unpaused
    {
        require((amount > 0), "Boardroom: amount should be > 0");
        updateAccruals(msg.sender);
        stakingTokenBalances[to] = stakingTokenBalances[to].add(amount);
        stakingTokenSupply = stakingTokenSupply.add(amount);
        _doStakeTransfer(msg.sender, to, amount);
        emit Staked(msg.sender, to, amount);
    }

    /// Withdraw tokens from Boardroom
    /// @param to the receiver of the token
    /// @param amount amount of base token
    function withdraw(address to, uint256 amount) public nonReentrant {
        require((amount > 0), "Boardroom: amount should be > 0");
        updateAccruals(msg.sender);
        stakingTokenBalances[msg.sender] = stakingTokenBalances[msg.sender].sub(
            amount
        );
        stakingTokenSupply = stakingTokenSupply.sub(amount);
        _doWithdrawTransfer(msg.sender, to, amount);
        emit Withdrawn(msg.sender, to, amount);
    }

    /// Called inside `stake` method after updating internal balances
    /// @param from the owner of the staking tokens
    /// @param amount amount to stake
    function _doStakeTransfer(
        address from,
        address,
        uint256 amount
    ) internal virtual {
        stakingToken.transferFrom(from, address(this), amount);
    }

    /// Called inside `withdraw` method after updating internal balances
    /// @param to the receiver of the staking tokens
    /// @param amount amount to unstake
    function _doWithdrawTransfer(
        address,
        address to,
        uint256 amount
    ) internal virtual {
        stakingToken.transfer(to, amount);
    }

    /// Shows the balance of the virtual token that participates in reward calculation
    /// @param owner the owner of the share tokens
    function shareTokenBalance(address owner)
        public
        view
        virtual
        returns (uint256)
    {
        return stakingTokenBalances[owner];
    }

    /// Shows the supply of the virtual token that participates in reward calculation
    function shareTokenSupply() public view virtual returns (uint256) {
        return stakingTokenSupply;
    }

    /// Update accrued rewards for all tokens of sender
    /// @param owner address to update accruals
    function updateAccruals(address owner) public unpaused {
        address[] memory tokens = tokenManager.allTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            _updateAccrual(tokens[i], owner);
        }
    }

    /// Transfer all rewards to sender
    /// @param to reward receiver
    function claimRewards(address to) public nonReentrant unpaused {
        updateAccruals(msg.sender);
        address[] memory tokens = tokenManager.allTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            _claimReward(to, tokens[i]);
        }
    }

    // ------- Public, EmissionManager ----------

    /// Notify Boardroom about new incoming reward for token
    /// @param token Rewards denominated in this token
    /// @param amount The amount of rewards
    function notifyTransfer(address token, uint256 amount) external override {
        require(
            msg.sender == address(emissionManager),
            "Boardroom: can only be called by EmissionManager"
        );
        uint256 shareSupply = shareTokenSupply();
        require(
            shareSupply > 0,
            "Boardroom: Cannot receive incoming reward when token balance is 0"
        );
        PoolRewardSnapshot[] storage tokenSnapshots =
            poolRewardSnapshots[token];
        PoolRewardSnapshot storage lastSnapshot =
            tokenSnapshots[tokenSnapshots.length - 1];
        uint256 deltaRPSU = amount.mul(stakingUnit).div(shareSupply);
        tokenSnapshots.push(
            PoolRewardSnapshot({
                timestamp: block.timestamp,
                addedSyntheticReward: amount,
                accruedRewardPerShareUnit: lastSnapshot
                    .accruedRewardPerShareUnit
                    .add(deltaRPSU)
            })
        );
        emit IncomingBoardroomReward(token, msg.sender, amount);
    }

    // ------- Public, Owner (timelock) ----------

    /// Updates TokenManager
    /// @param _tokenManager new TokenManager
    function setTokenManager(address _tokenManager) public onlyOwner {
        tokenManager = ITokenManager(_tokenManager);
        emit UpdatedTokenManager(msg.sender, _tokenManager);
    }

    /// Updates EmissionManager
    /// @param _emissionManager new EmissionManager
    function setEmissionManager(address _emissionManager) public onlyOwner {
        emissionManager = _emissionManager;
        emit UpdatedEmissionManager(msg.sender, _emissionManager);
    }

    // ------- Public, Operator (multisig) ----------

    /// Set pause
    /// @param _pause pause value
    function setPause(bool _pause) public onlyOperator {
        pause = _pause;
        emit UpdatedPause(msg.sender, _pause);
    }

    // ------- Internal ----------

    function _claimReward(address to, address syntheticTokenAddress) internal {
        uint256 reward =
            personRewardAccruals[syntheticTokenAddress][msg.sender]
                .accruedReward;
        if (reward > 0) {
            personRewardAccruals[syntheticTokenAddress][msg.sender]
                .accruedReward = 0;
            SyntheticToken token = SyntheticToken(syntheticTokenAddress);
            token.transfer(to, reward);
            emit RewardPaid(syntheticTokenAddress, msg.sender, to, reward);
        }
    }

    function _updateAccrual(address syntheticTokenAddress, address owner)
        internal
    {
        PersonRewardAccrual storage accrual =
            personRewardAccruals[syntheticTokenAddress][owner];
        PoolRewardSnapshot[] storage tokenSnapshots =
            poolRewardSnapshots[syntheticTokenAddress];
        if (tokenSnapshots.length == 0) {
            tokenSnapshots.push(
                PoolRewardSnapshot({
                    timestamp: block.timestamp,
                    addedSyntheticReward: 0,
                    accruedRewardPerShareUnit: 0
                })
            );
        }
        if (accrual.lastAccrualSnaphotId == tokenSnapshots.length - 1) {
            return;
        }
        PoolRewardSnapshot storage lastSnapshot =
            tokenSnapshots[tokenSnapshots.length - 1];
        uint256 lastOverallRPSU = lastSnapshot.accruedRewardPerShareUnit;
        PoolRewardSnapshot storage lastAccrualSnapshot =
            tokenSnapshots[accrual.lastAccrualSnaphotId];
        uint256 lastUserAccrualRPSU =
            lastAccrualSnapshot.accruedRewardPerShareUnit;
        uint256 deltaRPSU = lastOverallRPSU.sub(lastUserAccrualRPSU);
        uint256 addedUserReward =
            shareTokenBalance(owner).mul(deltaRPSU).div(stakingUnit);
        accrual.lastAccrualSnaphotId = tokenSnapshots.length - 1;
        accrual.accruedReward = accrual.accruedReward.add(addedUserReward);
        emit RewardAccrued(
            syntheticTokenAddress,
            owner,
            addedUserReward,
            accrual.accruedReward
        );
    }

    // ------- Events ----------

    event RewardAccrued(
        address syntheticTokenAddress,
        address to,
        uint256 incrementalReward,
        uint256 totalReward
    );
    event RewardPaid(
        address indexed syntheticTokenAddress,
        address indexed from,
        address indexed to,
        uint256 reward
    );
    event IncomingBoardroomReward(
        address indexed token,
        address indexed from,
        uint256 amount
    );
    event Staked(address indexed from, address indexed to, uint256 amount);
    event Withdrawn(address indexed from, address indexed to, uint256 amount);
    event UpdatedPause(address indexed operator, bool pause);
    event UpdatedTokenManager(
        address indexed operator,
        address newTokenManager
    );
    event UpdatedEmissionManager(
        address indexed operator,
        address newEmissionManager
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

/// Checks time bounds for contract
abstract contract Timeboundable {
    uint256 public immutable start;
    uint256 public immutable finish;

    /// @param _start The block timestamp to start from (in secs). Use 0 for unbounded start.
    /// @param _finish The block timestamp to finish in (in secs). Use 0 for unbounded finish.
    constructor(uint256 _start, uint256 _finish) internal {
        require(
            (_start != 0) || (_finish != 0),
            "Timebound: either start or finish must be nonzero"
        );
        require(
            (_finish == 0) || (_finish > _start),
            "Timebound: finish must be zero or greater than start"
        );
        uint256 s = _start;
        if (s == 0) {
            s = block.timestamp;
        }
        uint256 f = _finish;
        if (f == 0) {
            f = uint256(-1);
        }
        start = s;
        finish = f;
    }

    /// Checks if timebounds are satisfied
    modifier inTimeBounds() {
        require(block.timestamp >= start, "Timeboundable: Not started yet");
        require(block.timestamp <= finish, "Timeboundable: Already finished");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "./access/Operatable.sol";

/// @title Synthetic token for the Klondike platform
contract SyntheticToken is ERC20Burnable, Operatable {
    /// Creates a new synthetic token
    /// @param _name Name of the token
    /// @param _symbol Ticker for the token
    /// @param _decimals Number of decimals
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
    }

    ///  Mints tokens to the recepient
    ///  @param recipient The address of recipient
    ///  @param amount The amount of tokens to mint
    function mint(address recipient, uint256 amount)
        public
        onlyOperator
        returns (bool)
    {
        _mint(recipient, amount);
    }

    ///  Burns token from the caller
    ///  @param amount The amount of tokens to burn
    function burn(uint256 amount) public override onlyOperator {
        super.burn(amount);
    }

    ///  Burns token from address
    ///  @param account The account to burn from
    ///  @param amount The amount of tokens to burn
    ///  @dev The allowance for sender in address account must be
    ///  strictly >= amount. Otherwise the function call will fail.
    function burnFrom(address account, uint256 amount)
        public
        override
        onlyOperator
    {
        super.burnFrom(account, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./ISmelter.sol";

/// Token manager as seen by other managers
interface ITokenManager is ISmelter {
    /// A set of synthetic tokens under management
    /// @dev Deleted tokens are still present in the array but with address(0)
    function allTokens() external view returns (address[] memory);

    /// Checks if the token is managed by Token Manager
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @return True if token is managed
    function isManagedToken(address syntheticTokenAddress)
        external
        view
        returns (bool);

    /// Address of the underlying token
    /// @param syntheticTokenAddress The address of the synthetic token
    function underlyingToken(address syntheticTokenAddress)
        external
        view
        returns (address);

    /// Average price of the synthetic token according to price oracle
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param syntheticTokenAmount The amount to be priced
    /// @return The equivalent amount of the underlying token required to buy syntheticTokenAmount (average)
    /// @dev Fails if the token is not managed
    function averagePrice(
        address syntheticTokenAddress,
        uint256 syntheticTokenAmount
    ) external view returns (uint256);

    /// Current price of the synthetic token according to Uniswap
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param syntheticTokenAmount The amount to be priced
    /// @return The equivalent amount of the underlying token required to buy syntheticTokenAmount
    /// @dev Fails if the token is not managed
    function currentPrice(
        address syntheticTokenAddress,
        uint256 syntheticTokenAmount
    ) external view returns (uint256);

    /// Updates Oracle for the synthetic asset
    /// @param syntheticTokenAddress The address of the synthetic token
    function updateOracle(address syntheticTokenAddress) external;

    /// Get one synthetic unit
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @return one unit of the synthetic asset
    function oneSyntheticUnit(address syntheticTokenAddress)
        external
        view
        returns (uint256);

    /// Get one underlying unit
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @return one unit of the underlying asset
    function oneUnderlyingUnit(address syntheticTokenAddress)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

/// Boardroom as seen by others
interface IBoardroom {
    /// Notify Boardroom about new incoming reward for token
    /// @param token Rewards denominated in this token
    /// @param amount The amount of rewards
    function notifyTransfer(address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";

/// Introduces `Operator` role that can be changed only by Owner.
abstract contract Operatable is Ownable {
    address public operator;

    constructor() internal {
        operator = msg.sender;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator can call this method");
        _;
    }

    /// Set new operator
    /// @param newOperator New operator to be set
    /// @dev Only owner is allowed to call this method.
    function transferOperator(address newOperator) public onlyOwner {
        emit OperatorTransferred(operator, newOperator);
        operator = newOperator;
    }

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

/// Smelter can mint and burn tokens
interface ISmelter {
    /// Burn SyntheticToken
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param owner Owner of the tokens to burn
    /// @param amount Amount to burn
    function burnSyntheticFrom(
        address syntheticTokenAddress,
        address owner,
        uint256 amount
    ) external;

    /// Mints synthetic token
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param receiver Address to receive minted token
    /// @param amount Amount to mint
    function mintSynthetic(
        address syntheticTokenAddress,
        address receiver,
        uint256 amount
    ) external;

    /// Check if address is token admin
    /// @param admin - address to check
    function isTokenAdmin(address admin) external view returns (bool);
}