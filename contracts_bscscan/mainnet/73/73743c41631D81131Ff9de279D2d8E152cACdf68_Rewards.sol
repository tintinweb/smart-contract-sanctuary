/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/Rewards.sol


pragma solidity >=0.8.0;


//initialization interface for later implementation
interface IREWARDS {
    // Functions

    function incrementRewards(address p_user, uint256 p_amount)
        external
        returns (bool);

    function rewards(address p_user)
        external
        view
        returns (
            uint256 amount,
            uint256 amountAvailable,
            uint256 timeStamp
        );

    function liquidateRewards() external returns (bool);

    // Events  for the front through web3
    event e_incrementRewards(address indexed user, uint256 amount);
    event e_liquidateRewards(address indexed owner);
}

contract Rewards is IREWARDS {
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // STATE
    //////////////////////////////////////////////////////////////////////////////////////////////////

    // Rewards [wallet => amount]
    mapping(address => uint256) s_rewards;

    // Rewards [wallet => timestamp]
    mapping(address => uint256) s_rewardsTimestamp;

    // ERC20 Utility Token Address
    address private immutable ERC20_ADDRESS;

    // Logic Contract Address
    address private LOGIC_REWARDS_ADDRESS;

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////////////////////////////////////////////

    constructor(address p_erc20) {
        ERC20_ADDRESS = p_erc20;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Public functions
    //////////////////////////////////////////////////////////////////////////////////////////////////

    // function to increase rewards, where we first validate that it can only be called by the logic proxy
    function incrementRewards(address p_user, uint256 p_amount)
        public
        override
        returns (bool)
    {
        require(_canIncrementReward(), "Not allowed");

        s_rewards[p_user] += p_amount;
        if (s_rewardsTimestamp[p_user] == 0) {
            s_rewardsTimestamp[p_user] = block.timestamp;
        }

        emit e_incrementRewards(p_user, p_amount);

        return true;
    }

    // Get rewards
    function rewards(address p_user)
        public
        view
        override
        returns (
            uint256 amount,
            uint256 amountAvailable,
            uint256 timeStamp
        )
    {
        amount = _rewards(p_user);
        amountAvailable = _amountAvailable(p_user);
        timeStamp = _rewardsTimestamp(p_user);
    }

    // Liquidate rewards
    function liquidateRewards() public override returns (bool) {
        require(_canLiquidateReward(), "Not allowed");

       

        IERC20(ERC20_ADDRESS).transfer(
            msg.sender,
            _amountAvailable(msg.sender)
        );
        
         delete s_rewards[msg.sender];
        delete s_rewardsTimestamp[msg.sender];

        emit e_liquidateRewards(msg.sender);

        return true;
    }

    //Let's set the proxy to evolve the functionality, this implements the 1166
    address private proxyDelegate = msg.sender;
    modifier proxyCaller() {
        require(
            msg.sender == proxyDelegate,
            "proxyDelegate verification failed"
        );
        _;
    }

    function setLogicContract(address _address) external proxyCaller {
        LOGIC_REWARDS_ADDRESS = _address;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Internal functions
    //////////////////////////////////////////////////////////////////////////////////////////////////

    // Can liquidate reward
    function _canLiquidateReward() internal view returns (bool) {
        if (_rewards(msg.sender) == 0 || _rewardsTimestamp(msg.sender) == 0) {
            return false;
        }

        return true;
    }

    // function to increase rewards, where we first validate that it can only be called by the logic proxy
    function _canIncrementReward() internal view returns (bool) {
        if (msg.sender != LOGIC_REWARDS_ADDRESS) {
            return false;
        }

        return true;
    }

    // Get rewards
    function _rewards(address p_user) internal view returns (uint256) {
        return s_rewards[p_user];
    }

    // Get rewards Available
    function _amountAvailable(address p_user) internal view returns (uint256) {
        uint256 numDays = (block.timestamp - _rewardsTimestamp(p_user)) /
            24 hours;
        uint256 fee1 = _rewards(p_user) / 100; // 1%
        if (_rewards(p_user) == 0) {
            return 0;
        }

        if (numDays == 0) {
            return s_rewards[p_user] - (fee1 * 30);
        }
        if (numDays >= 15) {
            return s_rewards[p_user];
        }

        return s_rewards[p_user] - (fee1 * (30 - (numDays * 2)));
    }

    // Get timestamp
    function _rewardsTimestamp(address p_user) internal view returns (uint256) {
        return s_rewardsTimestamp[p_user];
    }
}