//SourceUnit: YBCDMXSFarm.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @title TRC20 interface
 */
interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
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

pragma experimental ABIEncoderV2;

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

/**
 * @title SafeTRC20
 * @dev Wrappers around TRC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeTRC20 for TRC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeTRC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ITRC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(ITRC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.

        //        require(address(token).isContract());
        require(address(token) != tx.origin);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) {// Return data is optional
            require(abi.decode(returndata, (bool)));
        }
    }
}

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

contract YBCDMXSFarm is Context, Ownable {

    using SafeMath for uint256;
    using SafeTRC20 for ITRC20;

    struct User {
        address referral;
        uint256 amount;
        uint256 balance;
        uint256 stake_reward;
        uint256 referral_reward;
        Order[] orders;
        bool exist;
    }

    struct Order {
        uint256 amount;
        uint256 time;
    }

    mapping(address => User) public users;

    ITRC20 public token = ITRC20(0x41849C6188A39DC6298219AC10D74BB20E97AF0317);
    ITRC20 public lpToken = ITRC20(0x4177FF3B85B14C6ACECABE95E591299E2098065816);

    uint256 public rewardDuration = 30 days;
    uint256 public constant PERCENT = 100;
    uint256 public REFERRAL_RATE = 30;
    uint256 public totalStakeAmount = 0;

    event Referral(address indexed addr, address indexed upline);
    event Stake(address indexed addr, uint256 amount);
    event CancelStake(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event ReferralReward(address indexed addr, address indexed referral, uint256 amount);

    constructor() public {
    }

    function _setReferral(address _addr, address _referral) private {
        if (_referral != address(0) && users[_addr].referral == address(0) && _referral != _addr) {
            users[_addr].referral = _referral;
            users[_addr].exist = true;
            emit Referral(_addr, _referral);
        }
    }

    function _referralReward(address _addr, uint256 _amount) private {
        if (users[_addr].referral != address(0)) {
            uint256 reward = _amount.mul(REFERRAL_RATE).div(PERCENT);

            if (reward > 0) {
                if (users[users[_addr].referral].exist == true && users[users[_addr].referral].amount > 0) {
                    users[users[_addr].referral].referral_reward = users[users[_addr].referral].referral_reward.add(reward);
                    token.safeTransfer(users[_addr].referral, reward);

                    emit ReferralReward(_addr, users[_addr].referral, reward);
                }
            }
        }
    }

    function _stake(address _addr, uint256 _amount) private {
        require(users[_addr].referral != address(0), 'need referral');

        lpToken.safeTransferFrom(_addr, address(this), _amount);
        users[_addr].amount = users[_addr].amount.add(_amount);
        totalStakeAmount = totalStakeAmount.add(_amount);

        users[_addr].orders.push(Order(
                _amount,
                block.timestamp
            ));

        emit Stake(msg.sender, _amount);
    }

    function stake( uint256 _amount, address _referral) public {
        _setReferral(msg.sender, _referral);
        _stake(msg.sender, _amount);
    }

    function cancelStake() public {
        uint256 stake_amount = users[msg.sender].amount;
        require(stake_amount > 0, 'no stake');

        uint256 reward = getUnSettlementReward(msg.sender);
        users[msg.sender].balance = users[msg.sender].balance.add(reward);
        users[msg.sender].amount = 0;
        delete users[msg.sender].orders;

        if (totalStakeAmount > stake_amount) {
            totalStakeAmount = totalStakeAmount.sub(stake_amount);
        } else {
            totalStakeAmount = 0;
        }

        lpToken.safeTransfer(msg.sender, stake_amount);
        emit CancelStake(msg.sender, stake_amount);
    }

    function withdraw() public {
        uint256 reward = getUnSettlementReward(msg.sender);
        _refreshOrders(msg.sender);

        reward = reward.add(users[msg.sender].balance);

        require(reward > 0 ,'no reward');

        users[msg.sender].balance = 0;
        token.safeTransfer(msg.sender, reward);

        emit Withdraw(msg.sender, reward);
        _referralReward(msg.sender, reward);
    }

    function _refreshOrders(address _addr) internal{
        Order[] storage orders = users[_addr].orders;

        for(uint i=0;i<orders.length;i++) {
            if (orders[i].time.add(rewardDuration) <= block.timestamp) {
                uint256 period =  (block.timestamp.sub(orders[i].time)).div(rewardDuration);
                orders[i].time = orders[i].time.add(period.mul(rewardDuration));
            }
        }
    }

    function getUserReward() public view returns(uint256) {
        uint256 reward = getUnSettlementReward(msg.sender);
        reward = reward.add(users[msg.sender].balance);

        return reward;
    }

    function getUnSettlementReward(address _addr) public view returns(uint256){
        Order[] storage orders = users[_addr].orders;

        uint256 poolAmount = getGlobalPoolAmount();
        uint256 reward = 0;

        if (poolAmount > 0) {
            for(uint i=0;i<orders.length;i++) {
                if (orders[i].time.add(rewardDuration) <= block.timestamp) {
                    uint256 period =  (block.timestamp.sub(orders[i].time)).div(rewardDuration);

                    if (period > 0) {
                        reward = reward.add(orders[i].amount.mul(getPoolReward()).mul(period).div(poolAmount));
                    }

                }
            }
        }

        return reward;
    }

    function getGlobalPoolAmount() public view returns(uint256) {
        return lpToken.totalSupply();
    }

    function getPoolReward() public view returns(uint256) {
        return token.balanceOf(address(this));
    }

    function getUserStake(address _addr) public view returns(uint256, uint256) {
        return (users[_addr].amount, totalStakeAmount);
    }
}