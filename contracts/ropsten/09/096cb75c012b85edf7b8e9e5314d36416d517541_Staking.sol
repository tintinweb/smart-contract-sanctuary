/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

pragma solidity ^0.5.0;

//import "../SafeMath.sol";

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


//import "../IErc20Token.sol";

pragma solidity ^0.5.0;

interface IErc20Token {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


//import "../NamedContract.sol";

pragma solidity ^0.5.0;

/// @title Named Contract
contract NamedContract {
    /// @notice The name of contract, which can be set once
    string public name;

    /// @notice Sets contract name.
    function setContractName(string memory newName) internal {
        name = newName;
    }
}


//import "./StakingStorage.sol";

pragma solidity ^0.5.0;

/// @title Staking Storage Contract
contract StakingStorage {
    struct Checkpoint {
        uint256 blockNumberOrCheckpointIndex;
        uint256 stakedAmount;
    }

    /// @notice Initialized flag - indicates that initialization was made once
    bool internal _initialized;

    address public _guardian;
    address public _authorizedNewGuardian;

    address public _sxpTokenAddress;

    uint256 public _minimumStakeAmount;
    mapping (address => mapping (uint256 => Checkpoint)) internal _stakedMap;
    uint256 public _totalStaked;

    uint256 public _prevRewardCycle;
    uint256 public _prevRewardAmount;
    uint256 public _prevRewardCycleTimestamp;
    uint256 public _rewardCycle;
    uint256 public _rewardAmount;
    uint256 public _rewardCycleTimestamp;
    uint256 public _rewardPoolAmount;
    address public _rewardProvider;

    uint256 public _claimNonce;
    mapping (address => mapping (uint256 => uint256)) public _approvedClaimMap;
}


//import "./StakingEvent.sol";

pragma solidity ^0.5.0;

/// @title Staking Event Contract
contract StakingEvent {

    event Initialize(
        address indexed owner,
        address indexed sxp,
        address indexed rewardProvider,
        uint256 minimumStakeAmount,
        uint256 rewardCycle,
        uint256 rewardAmount,
        uint256 rewardCycleTimestamp
    );

    event Stake(
        address indexed staker,
        uint256 indexed amount
    );

    event Claim(
        address indexed toAddress,
        uint256 indexed amount,
        uint256 indexed nonce
    );

    event Withdraw(
        address indexed toAddress,
        uint256 indexed amount
    );

    event GuardianshipTransferAuthorization(
        address indexed authorizedAddress
    );

    event GuardianUpdate(
        address indexed oldValue,
        address indexed newValue
    );

    event MinimumStakeAmountUpdate(
        uint256 indexed oldValue,
        uint256 indexed newValue
    );

    event RewardProviderUpdate(
        address indexed oldValue,
        address indexed newValue
    );

    event RewardPolicyUpdate(
        uint256 oldCycle,
        uint256 oldAmount,
        uint256 indexed newCycle,
        uint256 indexed newAmount,
        uint256 indexed newTimeStamp
    );

    event DepositRewardPool(
        address indexed depositor,
        uint256 indexed amount
    );

    event WithdrawRewardPool(
        address indexed toAddress,
        uint256 indexed amount
    );

    event ApproveClaim(
        address indexed toAddress,
        uint256 indexed amount,
        uint256 indexed nonce
    );
}


/// @title Staking Contract
contract Staking is NamedContract, StakingStorage, StakingEvent {
    using SafeMath for uint256;

    constructor() public {
        setContractName('Swipe Staking');
    }

    /********************
     * STANDARD ACTIONS *
     ********************/

    /**
     * @notice Gets the staked amount of the provided address.
     *
     * @return The staked amount
     */
    function getStakedAmount(address staker) public view returns (uint256) {
        Checkpoint storage current = _stakedMap[staker][0];

        return current.stakedAmount;
    }

    /**
     * @notice Gets the prior staked amount of the provided address, at the provided block number.
     *
     * @return The staked amount
     */
    function getPriorStakedAmount(address staker, uint256 blockNumber) external view returns (uint256) {
        if (blockNumber == 0) {
            return getStakedAmount(staker);
        }

        Checkpoint storage current = _stakedMap[staker][0];

        for (uint i = current.blockNumberOrCheckpointIndex; i > 0; i--) {
            Checkpoint storage checkpoint = _stakedMap[staker][i];
            if (checkpoint.blockNumberOrCheckpointIndex <= blockNumber) {
                return checkpoint.stakedAmount;
            }
        }
        
        return 0;
    }

    /**
     * @notice Stakes the provided amount of SXP from the message sender into this wallet.
     *
     * @param amount The amount to stake
     */
    function stake(uint256 amount) external {
        require(
            amount >= _minimumStakeAmount,
            "Too small amount"
        );

        Checkpoint storage current = _stakedMap[msg.sender][0];
        current.blockNumberOrCheckpointIndex = current.blockNumberOrCheckpointIndex.add(1);
        current.stakedAmount = current.stakedAmount.add(amount);
        _stakedMap[msg.sender][current.blockNumberOrCheckpointIndex] = Checkpoint({
            blockNumberOrCheckpointIndex: block.number,
            stakedAmount: current.stakedAmount
        });
        _totalStaked = _totalStaked.add(amount);

        emit Stake(
            msg.sender,
            amount
        );

        require(
            IErc20Token(_sxpTokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Stake failed"
        );
    }

    /**
     * @notice Claims reward of the provided nonce.
     *
     * @param nonce The claim nonce uniquely identifying the authorization to claim
     */
    function claim(uint256 nonce) external {
        uint256 amount = _approvedClaimMap[msg.sender][nonce];

        require(
            amount > 0,
            "Invalid nonce"
        );

        require(
            _rewardPoolAmount >= amount,
            "Insufficient reward pool"
        );

        delete _approvedClaimMap[msg.sender][nonce];
        _rewardPoolAmount = _rewardPoolAmount.sub(amount);

        emit Claim(
            msg.sender,
            amount,
            nonce
        );

        require(
            IErc20Token(_sxpTokenAddress).transfer(
                msg.sender,
                amount
            ),
            "Claim failed"
        );
    }

    /**
     * @notice Withdraws the provided amount of staked
     *
     * @param amount The amount to withdraw
    */
    function withdraw(uint256 amount) external {
        require(
            getStakedAmount(msg.sender) >= amount,
            "Exceeded amount"
        );

        Checkpoint storage current = _stakedMap[msg.sender][0];
        current.blockNumberOrCheckpointIndex = current.blockNumberOrCheckpointIndex.add(1);
        current.stakedAmount = current.stakedAmount.sub(amount);
        _stakedMap[msg.sender][current.blockNumberOrCheckpointIndex] = Checkpoint({
            blockNumberOrCheckpointIndex: block.number,
            stakedAmount: current.stakedAmount
        });
        _totalStaked = _totalStaked.sub(amount);

        emit Withdraw(
            msg.sender,
            amount
        );

        require(
            IErc20Token(_sxpTokenAddress).transfer(
                msg.sender,
                amount
            ),
            "Withdraw failed"
        );
    }

    /*****************
     * ADMIN ACTIONS *
     *****************/

    /**
     * @notice Initializes contract.
     *
     * @param guardian Guardian address
     * @param sxpTokenAddress SXP token address
     * @param rewardProvider The reward provider address
     */
    function initialize(
        address guardian,
        address sxpTokenAddress,
        address rewardProvider
    ) external {
        require(
            !_initialized,
            "Contract has been already initialized"
        );

        _guardian = guardian;
        _sxpTokenAddress = sxpTokenAddress;
        _rewardProvider = rewardProvider;
        _minimumStakeAmount = 1000 * (10**18);
        _rewardCycle = 1 days;
        _rewardAmount = 40000 * (10**18);
        _rewardCycleTimestamp = block.timestamp;
        _initialized = true;

        emit Initialize(
            _guardian,
            _sxpTokenAddress,
            _rewardProvider,
            _minimumStakeAmount,
            _rewardCycle,
            _rewardAmount,
            _rewardCycleTimestamp
        );
    }

    /**
     * @notice Authorizes the transfer of guardianship from guardian to the provided address.
     * NOTE: No transfer will occur unless authorizedAddress calls assumeGuardianship( ).
     * This authorization may be removed by another call to this function authorizing
     * the null address.
     *
     * @param authorizedAddress The address authorized to become the new guardian.
     */
    function authorizeGuardianshipTransfer(address authorizedAddress) external {
        require(
            msg.sender == _guardian,
            "Only the guardian can authorize a new address to become guardian"
        );

        _authorizedNewGuardian = authorizedAddress;

        emit GuardianshipTransferAuthorization(_authorizedNewGuardian);
    }

    /**
     * @notice Transfers guardianship of this contract to the _authorizedNewGuardian.
     */
    function assumeGuardianship() external {
        require(
            msg.sender == _authorizedNewGuardian,
            "Only the authorized new guardian can accept guardianship"
        );
        address oldValue = _guardian;
        _guardian = _authorizedNewGuardian;
        _authorizedNewGuardian = address(0);

        emit GuardianUpdate(oldValue, _guardian);
    }

    /**
     * @notice Updates the minimum stake amount.
     *
     * @param newMinimumStakeAmount The amount to be allowed as minimum to users
     */
    function setMinimumStakeAmount(uint256 newMinimumStakeAmount) external {
        require(
            msg.sender == _guardian || msg.sender == _rewardProvider,
            "Only the guardian or reward provider can set the minimum stake amount"
        );

        require(
            newMinimumStakeAmount > 0,
            "Invalid amount"
        );

        uint256 oldValue = _minimumStakeAmount;
        _minimumStakeAmount = newMinimumStakeAmount;

        emit MinimumStakeAmountUpdate(oldValue, _minimumStakeAmount);
    }

    /**
     * @notice Updates the Reward Provider address, the only address that can provide reward.
     *
     * @param newRewardProvider The address of the new Reward Provider
     */
    function setRewardProvider(address newRewardProvider) external {
        require(
            msg.sender == _guardian,
            "Only the guardian can set the reward provider address"
        );

        address oldValue = _rewardProvider;
        _rewardProvider = newRewardProvider;

        emit RewardProviderUpdate(oldValue, _rewardProvider);
    }

    /**
     * @notice Updates the reward policy, the only address that can provide reward.
     *
     * @param newRewardCycle New reward cycle
     * @param newRewardAmount New reward amount a cycle
     */
    function setRewardPolicy(uint256 newRewardCycle, uint256 newRewardAmount) external {
        require(
            msg.sender == _rewardProvider,
            "Only the reward provider can set the reward policy"
        );

        _prevRewardCycle = _rewardCycle;
        _prevRewardAmount = _rewardAmount;
        _prevRewardCycleTimestamp = _rewardCycleTimestamp;
        _rewardCycle = newRewardCycle;
        _rewardAmount = newRewardAmount;
        _rewardCycleTimestamp = block.timestamp;

        emit RewardPolicyUpdate(
            _prevRewardCycle,
            _prevRewardAmount,
            _rewardCycle,
            _rewardAmount,
            _rewardCycleTimestamp
        );
    }

    /**
     * @notice Deposits the provided amount into reward pool.
     *
     * @param amount The amount to deposit into reward pool
     */
    function depositRewardPool(uint256 amount) external {
        require(
            msg.sender == _rewardProvider,
            "Only the reword provider can deposit"
        );

        _rewardPoolAmount = _rewardPoolAmount.add(amount);

        emit DepositRewardPool(
            msg.sender,
            amount
        );

        require(
            IErc20Token(_sxpTokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Deposit reward pool failed"
        );
    }

    /**
     * @notice Withdraws the provided amount from reward pool.
     *
     * @param amount The amount to withdraw from reward pool
     */
    function withdrawRewardPool(uint256 amount) external {
        require(
            msg.sender == _rewardProvider,
            "Only the reword provider can withdraw"
        );

        require(
            _rewardPoolAmount >= amount,
            "Exceeded amount"
        );

        _rewardPoolAmount = _rewardPoolAmount.sub(amount);

        emit WithdrawRewardPool(
            msg.sender,
            amount
        );

        require(
            IErc20Token(_sxpTokenAddress).transfer(
                msg.sender,
                amount
            ),
            "Withdraw failed"
        );
    }

    /**
     * @notice Approves the provided address to claim the provided amount.
     *
     * @param toAddress The address can claim reward
     * @param amount The amount to claim
     */
    function approveClaim(address toAddress, uint256 amount) external returns(uint256) {
        require(
            msg.sender == _rewardProvider,
            "Only the reword provider can approve"
        );

        require(
            _rewardPoolAmount >= amount,
            "Insufficient reward pool"
        );

        _claimNonce = _claimNonce.add(1);
        _approvedClaimMap[toAddress][_claimNonce] = amount;

        emit ApproveClaim(
            toAddress,
            amount,
            _claimNonce
        );

        return _claimNonce;
    }
    
    /********************
     * VALUE ACTIONS *
     ********************/

    /**
     * @notice Does not accept ETH.
     */
    function () external payable {
        revert();
    }

    /**
     * @notice Transfers out any accidentally sent ERC20 tokens.
     *
     * @param tokenAddress ERC20 token address, must not SXP
     * @param amount The amount to transfer out
     */
    function transferOtherErc20Token(address tokenAddress, uint256 amount) external returns (bool) {
        require(
            msg.sender == _guardian,
            "Only the guardian can transfer out"
        );

        require(
            tokenAddress != _sxpTokenAddress,
            "Can't transfer SXP token out"
        );

        return IErc20Token(tokenAddress).transfer(
            _guardian,
            amount
        );
    }
}