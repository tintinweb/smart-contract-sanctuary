pragma solidity 0.5.0;

/*       AmpleForthGold AAU Midas Distributor. 
** 
**       (c) 2020. Developed by the AmpleForthGold Team.
**  
**       www.ampleforth.gold
*/


//import "openzeppelin-solidity/contracts/math/SafeMath.sol";
//pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


//import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
//pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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



//import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
//pragma solidity ^0.5.0;

//import "../GSN/Context.sol";
//pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


//import "./TokenPool.sol";
//pragma solidity 0.5.0;

//import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
//import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

/**
 * @title A simple holder of tokens.
 * This is a simple contract to hold tokens. It's useful in the case where a separate contract
 * needs to hold multiple distinct pools of the same token.
 */
contract TokenPool is Ownable {
    IERC20 public token;

    constructor(IERC20 _token) public {
        token = _token;
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function transfer(address to, uint256 value)
        external
        onlyOwner
        returns (bool)
    {
        return token.transfer(to, value);
    }
}

/**
 * @title Midas Distributor
 * @dev A smart-contract based mechanism to distribute tokens over time, inspired loosely by
 *      Compound, Uniswap and Ampleforth.
 *
 *      The ampleforth geyser has the concept of a 'locked pool' in the geyser. MidasDistributor
 *      performs a similar action to the ampleforth geyser locked pool but allows for multiple
 *      geysers (which we call MidasAgents).
 *
 *      Distribution tokens are added to a pool in the contract and, over time, are sent to
 *      multiple midas agents based on a distribution share. Each agent gets a set
 *      percentage of the pool each time a distribution occurs.
 *
 *      Before unstaking the tokens in an agent it would be benifical to maximise the 
 *      take: to perform a distribution. That distribution event would be at the stakholders
 *      expense, and we allow anyone to perform a distribution.
 *
 *      Multiple midas agents can be registered, deregistered and have their distribution
 *      percentage adjusted. The distributor must be locked for adjustments to be made.
 *
 *      More background and motivation available at the AmpleForthGold github & website.
 */
contract MidasDistributor is Ownable {
    using SafeMath for uint256;

    event TokensLocked(uint256 amount, uint256 total);
    event TokensDistributed(uint256 amount, uint256 total);

    /* the ERC20 token to distribute */
    IERC20 public token;

    /* timestamp of last distribution event. */
    uint256 public lastDistributionTimestamp;

    /* When *true* the distributor:
     *      1) shall distribute tokens to agents,
     *      2) shall not allow for the registration or
     *         modification of agent details.
     * When *false* the distributor:
     *      1) shall not distribute tokens to agents,
     *      2) shall allow for the registration and
     *         modification of agent details.
     */
    bool public distributing = false;

    /* Allows us to represent a number by moving the decimal point. */
    uint256 public constant DECIMALS_EXP = 10**12;

    /* Represents the distribution rate per second.
     * Distribution rate is (0.5% per day) == (5.78703e-8 per second).
     */
    uint256 public constant PER_SECOND_INTEREST 
        = (DECIMALS_EXP * 5) / (1000 * 1 days);

    /* The collection of Agents and their percentage share. */
    struct MidasAgent {
        
        /* reference to a Midas Agent (destination for distributions) */
        address agent;

        /* Share of the distribution as a percentage.
         * i.e. 14% == 14
         * The sum of all shares must be equal to 100.
         */
        uint8 share;
    }
    MidasAgent[] public agents;

    /**
     * @param _distributionToken The token to be distributed.
     */
    constructor(IERC20 _distributionToken) public {
        token = _distributionToken;
        lastDistributionTimestamp = block.timestamp;
    }

    /**
     * @notice Sets the distributing state of the contract
     * @param _distributing the distributing state.
     */
    function setDistributionState(bool _distributing) external onlyOwner {
        /* we can only become enabled if the sum of shares == 100%. */
        if (_distributing == true) {
            require(checkAgentPercentage() == true);
        }

        distributing = _distributing;
    }

    /**
     * @notice Adds an Agent
     * @param _agent Address of the destination agent
     * @param _share Percentage share of distribution (can be 0)
     */
    function addAgent(address _agent, uint8 _share) external onlyOwner {
        require(_share <= uint8(100));
        distributing = false;
        agents.push(MidasAgent({agent: _agent, share: _share}));
    }

    /**
     * @notice Removes an Agent
     * @param _index Index of Agent to remove.
     *              Agent ordering may have changed since adding.
     */
    function removeAgent(uint256 _index) external onlyOwner {
        require(_index < agents.length, "index out of bounds");
        distributing = false;
        if (_index < agents.length - 1) {
            agents[_index] = agents[agents.length - 1];
        }
        agents.length--;
    }

    /**
     * @notice Sets an Agents share of the distribution.
     * @param _index Index of Agents. Ordering may have changed since adding.
     * @param _share Percentage share of the distribution (can be 0).
     */
    function setAgentShare(uint256 _index, uint8 _share) external onlyOwner {
        require(
            _index < agents.length,
            "index must be in range of stored tx list"
        );
        require(_share <= uint8(100));
        distributing = false;
        agents[_index].share = _share;
    }

    /**
     * @return Number of midas agents in agents list.
     */
    function agentsSize() public view returns (uint256) {
        return agents.length;
    }

    /**
     * @return boolean true if the percentage of all
     *         agents equals 100%. */
    function checkAgentPercentage() public view returns (bool) {
        uint256 sum = 0;
        for (uint256 i = 0; i < agents.length; i++) {
            sum += agents[i].share;
        }
        return (uint256(100) == sum);
    }

    /**
     * @return gets the total balance of the distributor
     */
    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getElapsedTime() public view returns(uint256) {
        /* Checking for a wormhole or time dialation event.
         * this error may also be caused by sunspots. */
        require(block.timestamp >= lastDistributionTimestamp);
        return (block.timestamp - lastDistributionTimestamp);
    }

    /* Gets the (total) amount that would be distributed
     * if a distribution event happened now. */
    function getDistributionAmount() public view returns (uint256) {
        return
            balance()
            .mul(getElapsedTime())
            .mul(PER_SECOND_INTEREST)
            .div(DECIMALS_EXP);
    }

    /* Gets the amount that would be distributed to a specific agent
     * if a distribution event happened now. */
    function getAgentDistributionAmount(uint256 index)
        public
        view
        returns (uint256)
    {
        require(checkAgentPercentage() == true);
        require(index < agents.length);

        return
            getDistributionAmount()
            .mul(agents[index].share)
            .div(100);
    }

    /**
     * Distributes the tokens based on the balance and the distribution rate.
     *
     * Anyone can call, and should call prior to an unstake event.
     */
    function distribute() external {
        require(distributing == true);
        require(checkAgentPercentage() == true);
        require(getDistributionAmount() > 0);

        for (uint256 i = 0; i < agents.length; i++) {
            uint256 amount = getAgentDistributionAmount(i);
            if (amount > 0) {
                require(token.transfer(agents[i].agent, amount));
            }
        }
        lastDistributionTimestamp = block.timestamp;
    }

    /**
     * Returns the balance to the owner of the contract. This is needed
     * if there is a contract upgrade & for testing & validation purposes.
     */
    function returnBalance2Owner() external onlyOwner returns (bool) {
        uint256 value = balance();
        if (value == 0) {
            return true;
        }
        return token.transfer(owner(), value);
    }
}