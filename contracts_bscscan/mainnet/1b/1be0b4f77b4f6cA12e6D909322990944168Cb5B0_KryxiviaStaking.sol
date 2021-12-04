// SPDX-License-Identifier: MIT

import "./libs/SafeMath.sol";
import "./interfaces/IBEP20.sol";

pragma solidity >= 0.8.0;

struct StakingDetails {
    uint256 amount;
    uint256 start_block;
    uint256 end_block;
    bool validated;
}

contract KryxiviaStaking {

    // Use alias imports
    using SafeMath for uint256;


    // Kryxivia coin hash: 0x2223bf1d7c19ef7c06dab88938ec7b85952ccd89
    address                             private _kryxiviaCoin;

    // Decimal point of the Kryxivia coin
    uint256                             private _coinDecimal = 1e18;

    // Staking contract manager: 0x605639FfFdBf3747A886fbFd47B159BF88263394
    address                             private _kryxiviaManager;

    // State of the contract: active per default
    bool                                public _stakingState = true;

    // Total amount of blocks needed to lock KXA
    uint256                             public _amountOfTotalBlocks;

    // Minimum required to lock KXA token
    uint256                             public _minimumRequiredLock;

    // Total amount of KXA locked
    uint256                             public _totalLocked;

    // Total numbers of stakers in the contract
    uint256                             public _lockersIndex;

    // Count of total stakers in the contract
    uint256                             public _stakersCount;

    // Array of lockers addresses for Alpha selection
    address[]                             public _lockersAddress;

    // List of stakers in the contract
    mapping(address => StakingDetails)  public _stakers;


    constructor(address kryxiviaCoin, address kryxiviaManager)
    {
        _kryxiviaCoin = kryxiviaCoin;
        _kryxiviaManager = kryxiviaManager;

        // average of blocks number per month on the Binance smart chain network
        _amountOfTotalBlocks = 832399;
        
        // minimum amount of KXA to lock per default is 15k KXA
        uint256 defaultAmount = 15000;
        _minimumRequiredLock = (defaultAmount).mul(_coinDecimal);
    }


    // ******* GETTERS (READ ONLY) *******

        /*
        ** Return the minimum required to be able to lock in the KXA contract
        */
        function getMinimumRequiredLock() public view returns(uint256) {
            return _minimumRequiredLock;
        }

        /*
        ** Return total blocks to be past before unlock
        */
        function getTotalBlocks() public view returns(uint256) {
            return _amountOfTotalBlocks;
        }

        /*
        ** Return the state of the staking contract (can lock or not)
        */
        function getStakingState() public view returns(bool) {
            return _stakingState;
        }

        /*
        ** Return visibility on if a specific address is whitelisted for the alpha access
        */
        function getValidatedState(address addr) public view returns(bool) {
            return _stakers[addr].validated;
        }

        /*
        ** Total KXA locked amount for a specific address
        */
        function getAddrLockAmount(address addr) public view returns(uint256) {
            return _stakers[addr].amount;
        }

        /*
        ** Get lock date for a specific address
        */
        function getAddrStartBlock(address addr) public view returns(uint256) {
            return _stakers[addr].start_block;
        }

        /*
        ** Get end date for a specific address
        */
        function getAddrEndBlock(address addr) public view returns(uint256) {
            return _stakers[addr].end_block;
        }

        /*
        ** Return the public address of the index locker
        */
        function getLockerIndexAddress(uint256 index) public view returns(address) {
            return _lockersAddress[index];
        }

        /*
        ** Get total array index lockers
        */
        function getLockersIndex() public view returns(uint256) {
            return _lockersIndex;
        }

        /*
        ** Get total stakers active in the contract
        */
        function getTotalStakers() public view returns(uint256) {
            return _stakersCount;
        }

    // ******* GETTERS (READ ONLY) *******


    // ******* SETTERS (READ/WRITE) *******
    
        /*
        ** Update the minimum amount of KXA needed to lock in the contract
        */
        function setMinimumRequiredLock(uint256 amountKxa) public {
            require(
                msg.sender == _kryxiviaManager,
                "Only the Kryxivia manager can update minimum lock required");
            _minimumRequiredLock = amountKxa;
        }

        /*
        ** Update the staking contract state (only for manager)
        */
        function setStakingState(bool state) public {
            require(
                msg.sender == _kryxiviaManager,
                "Only the Kryxivia manager can update staking state");
            _stakingState = state;
        }

        /*
        ** Update validation state for accessing the alpha (only for manager)
        */
        function setValidatedState(address addr, bool state) public {
            require(
                msg.sender == _kryxiviaManager,
                "Only the Kryxivia manager can update validation state");
            _stakers[addr].validated = state;
        }

        /*
        ** Set total amounts of blocks needed past before being able to unlock KXA
        */
        function setTotalBlocks(uint256 amountOfBlocks) public {
            require(
                msg.sender == _kryxiviaManager,
                "Only the Kryxivia manager can update total amount of blocks needed for unlock");
            _amountOfTotalBlocks = amountOfBlocks; 
        }

        /*
        ** Stake Kryxivia Coin in the staking contract
        */
        function stakeKXA(uint256 amountToLock) public {
            IBEP20 kxaToken = IBEP20(_kryxiviaCoin);
            require(
                _stakers[msg.sender].amount == 0,
                "You already staked KXA in the contract, please unstake first!");
            require(
                amountToLock >= _minimumRequiredLock,
                "Not enough KXA to fit requirements"
            );
            require(
                kxaToken.balanceOf(msg.sender) >= amountToLock,
                "Insufficient funds from the sender");
            require(
                kxaToken.transferFrom(msg.sender, address(this), amountToLock) == true,
                 "Error transferFrom on the contract");
            
            _stakers[msg.sender].start_block = block.number;
            _stakers[msg.sender].end_block = block.number.add(_amountOfTotalBlocks);
            _stakers[msg.sender].amount = amountToLock;
            _totalLocked = _totalLocked.add(amountToLock);
            _lockersAddress.push(msg.sender);
            _lockersIndex = _lockersIndex.add(1);
            _stakersCount = _stakersCount.add(1);
        }

        /*
        ** Unstake Kryxivia Coin in the staking contract
        */
        function unStakeKXA() public {
            IBEP20 kxaToken = IBEP20(_kryxiviaCoin);
            uint256 stakedAmount = _stakers[msg.sender].amount;

            require (
                stakedAmount > 0,
                "You did not locked any KXA in the staking contract!"
            );
            require(
                block.number >= _stakers[msg.sender].end_block,
                "You cant unlock your KXA yet!"
            );
            require(
                kxaToken.balanceOf(address(this)) >= stakedAmount,
                "Not enough KXA funds in the staking contract"
            );

            _stakers[msg.sender].amount = 0;
            _totalLocked = _totalLocked.sub(stakedAmount);
            _stakersCount = _stakersCount.sub(1);
            require(
                kxaToken.transfer(msg.sender, stakedAmount) == true,
                "Error transfer on the contract"
            );
        }


    // ******* SETTERS (READ/WRITE) *******
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBEP20 {
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

    function decimals() external view returns (uint8);

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