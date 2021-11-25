//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/IERC20.sol";
import "./utils/Initializable.sol";
import "./utils/SafeMath.sol";
import "./utils/Ownable.sol";

contract Staker is Initializable, Ownable {
    using SafeMath for uint256;
	IERC20 public cbcToken;
    IERC20 public rewardToken;

    event DepositFinished(address indexed user, uint256 amount, uint256 depositAt);
    event WithdrawFinished(address indexed user, uint256 amount, uint256 withdrawAt);
    event ClaimFinished(address indexed user, uint256 amount, uint256 claimAt);
    event ChangedWithdrawFeeApplyStatus(
        address indexed user,
        bool applyFeeStatus
    );
    event ChangedRewardRate(uint256 _rewardRate);

	uint256 minDeposit;
    uint256 rewardRate; // per month as total rewards
    uint256 totalDepositAmount;
	uint256 lockTime;
	bool lockEnabled;

    struct StakeList {
        uint256 stakesAmount;
        uint256 rewardsAmount;
		uint256 availableClaimTime;
        uint256 lastUpdateTime;
    }

	bool enabled;

    /**
     * @notice The accumulated stake status for each stakeholder.
     */
    mapping(address => StakeList) public stakeLists;
    mapping(address => bool) public withdrawFeeApplyStatus;

    /**
     * @dev Creates a staker contract that handles the diposit, withdraw, getReward features
     * for RewardToken tokens.
     * @param _tokenAddress RewardToken contract addresss that is already deployed
     * @param _cbcAddress cbc contract addresss that is already deployed
     */
    function initialize(IERC20 _tokenAddress, IERC20 _cbcAddress) public initializer {
        rewardToken = _tokenAddress;
		cbcToken = _cbcAddress;

		minDeposit = 1000;
		rewardRate = 1000;
		lockTime = 86400;  /// 24 hours
		enabled = true;
		lockEnabled = false;

		__Ownable_init();
    }

    /**
     * @notice A method for investor/staker to create/add the diposit.
     * @param _amount The amount of the diposit to be created.
     */
    function deposit(uint256 _amount) external {
		require(enabled == true, "Staking Contract is disabled for a while");
        require(
            cbcToken.balanceOf(msg.sender) >= _amount,
            "Please deposit more cbc to your wallet!"
        );
        require(
            _amount > minDeposit,
            "Deposit amount should be larger than minimum deposit amount"
        );

        cbcToken.transferFrom(msg.sender, address(this), _amount);
        StakeList storage _personStakeStatus = stakeLists[msg.sender];
        _personStakeStatus.rewardsAmount = updateReward(msg.sender);
		if(_personStakeStatus.stakesAmount == 0) {
			_personStakeStatus.availableClaimTime = block.timestamp + lockTime;
		}
        totalDepositAmount += _amount;
        _personStakeStatus.stakesAmount += _amount;
        _personStakeStatus.lastUpdateTime = block.timestamp;

        emit DepositFinished(msg.sender, _amount, _personStakeStatus.lastUpdateTime);
    }

    /**
     * @notice A method for the stakeholder to withdraw.
     * @param _amount The amount of the withdraw.
     */
    function withdraw(uint256 _amount) external {
		require(enabled == true, "Staking Contract is disabled for a while");
        StakeList storage _personStakeStatus = stakeLists[msg.sender];

        require(_personStakeStatus.stakesAmount != 0, "No stake");
        require(
            _amount > 0,
            "The amount to be transferred should be larger than 0"
        );
        require(
            _amount <= _personStakeStatus.stakesAmount,
            "The amount to be transferred should be equal or less than Deposite"
        );

        cbcToken.transfer(msg.sender, _amount);
        _personStakeStatus.rewardsAmount = updateReward(msg.sender);
        totalDepositAmount -= _amount;
        _personStakeStatus.stakesAmount -= _amount;
        _personStakeStatus.lastUpdateTime = block.timestamp;

        emit WithdrawFinished(msg.sender, _amount, _personStakeStatus.lastUpdateTime);
    }

    /**
     * @notice A method to allow the stakeholder to claim his rewards.
     */
    function claimReward() external {
		require(enabled == true, "Staking Contract is disabled for a while");
        StakeList storage _personStakeStatus = stakeLists[msg.sender];
		if(lockEnabled) {
			require(_personStakeStatus.availableClaimTime > block.timestamp, "Cannot withdraw within lock time from first deposit");
		}
        _personStakeStatus.rewardsAmount = updateReward(msg.sender);
        require(_personStakeStatus.rewardsAmount != 0, "No rewards");

        uint256 getRewardAmount = _personStakeStatus.rewardsAmount;

        rewardToken.mint(msg.sender, getRewardAmount);
        _personStakeStatus.rewardsAmount = 0;
        _personStakeStatus.lastUpdateTime = block.timestamp;

        emit ClaimFinished(msg.sender, getRewardAmount, _personStakeStatus.lastUpdateTime);
    }

    /**
     * @notice A method to calcaulate the stake rewards for a stakeholder for all transactions.
     * rewardRate with per-mille unit
     * withdrawFee with percentage unit
     * rewardRate - the total amount of rewards per month
     * @param _account The stakeholder to retrieve the stake rewards for.
     * @return uint256 The amount of tokens.
     */
    function updateReward(address _account) internal view returns (uint256) {
        StakeList storage _personStakeStatus = stakeLists[_account];

        if (_personStakeStatus.stakesAmount == 0) {
            return _personStakeStatus.rewardsAmount;
        }
        return
            _personStakeStatus.rewardsAmount
            .add(block.timestamp
            .sub(_personStakeStatus.lastUpdateTime)
            .mul(rewardRate)
            .mul(_personStakeStatus.stakesAmount)
			.div(100000000)
            .div(86400)
            );
    }

    /**
     * @notice A method for only owner to change whether it will be applied withdraw fee for a stakeholder or not.
     * false by the default - user pays the fee
     * If true owner pays the fee
     * @param _stakeholder The stakeholder address.
     */
    function setWithdrawFeeApplyStatus(address _stakeholder, bool _applyFee)
        public
        onlyOwner
        returns (bool)
    {
        withdrawFeeApplyStatus[_stakeholder] = _applyFee;
        emit ChangedWithdrawFeeApplyStatus(_stakeholder, _applyFee);

        return true;
    }

    /**
     * @notice A method for only owner to change the reward rate.
     * @param _rewardRate new reward rate
     */
    function setRewardRate(uint256 _rewardRate)
        public
        onlyOwner
        returns (bool)
    {
        require(_rewardRate > 0, "The reward rate should be larger than 0");
        rewardRate = _rewardRate;
        emit ChangedRewardRate(_rewardRate);

        return true;
    }

	/**
	 * @notice update minimum deposit amount
	 * @param _amount new minimum deposit amount
	 */
	function setMinimumDepositAmount(uint256 _amount) external onlyOwner {
		minDeposit = _amount;
	}

	/**
	 * @notice change staking contract status
	 * @param _status updated status
	 */
	function updateStatus(bool _status) external onlyOwner {
		enabled = _status;
	}

	/**
	 * @notice change lock time status
	 * @param _status updated status
	 */
	function updateLockEnabled(bool _status) external onlyOwner {
		lockEnabled = _status;
	}

	/**
	 * @notice set lock time
	 * @param _lockTime new lock time
	 */
	function setLockTime(uint256 _lockTime) external onlyOwner {
		lockTime = _lockTime;
	}

    /**
     * @notice A method to retrieve the amount of depoiste for a stakeholder.
     * @param _stakeholder The stakeholder address.
     * @return uint256 The amount of tokens.
     */
    function depositeOf(address _stakeholder) public view returns (uint256) {
        StakeList storage _personStakeStatus = stakeLists[_stakeholder];
        return _personStakeStatus.stakesAmount;
    }

    /**
     * @notice A method to retrieve the amount of rewards for a stakeholder.
     * @param _stakeholder The stakeholder address.
     * @return uint256 The amount of tokens.
     */
    function rewardOf(address _stakeholder) public view returns (uint256) {
        StakeList storage _personStakeStatus = stakeLists[_stakeholder];
        return _personStakeStatus.rewardsAmount;
    }

    /**
     * @notice A method to get the total amount of the deposied tokens
     */
    function getTotalDepositAmount() public view returns (uint256) {
        return totalDepositAmount;
    }

    /**
     * @notice A method to get the reward rate
     */
    function getRewardRate() public view returns (uint256) {
        return rewardRate;
    }

    /**
     * @notice A method to retrieve withdraw fee apply status for stakeholder.
     * @param _stakeholder The stakeholder address.
     */
    function getWithdrawFeeApplyStatus(address _stakeholder)
        public
        view
        returns (bool)
    {
        return withdrawFeeApplyStatus[_stakeholder];
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
	 * @dev mint function
	 */
	function mint(address recipient, uint256 amount) external;

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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./Context.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable, Context {
    address private _owner_;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function __Ownable_init() internal initializer {
        address msgSender = _msgSender();
        _owner_ = msgSender;
        emit OwnershipTransferred(address(0), _owner_);

        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {}

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            msg.sender == _owner_,
            "Ownable#onlyOwner: SENDER_IS_NOT_OWNER"
        );
        _;
    }

    /**
     * @notice Transfers the ownership of the contract to new address
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable#transferOwnership: INVALID_ADDRESS"
        );
        emit OwnershipTransferred(_owner_, _newOwner);
        _owner_ = _newOwner;
    }

    /**
     * @notice Returns the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";

abstract contract Context is Initializable {
    //Upgradable init method
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}