/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

// SPDX-License-Identifier: UNLICENSED


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

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


interface IBEP20 {
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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    
    function burn(uint256 _value) external;

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

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity 0.6.12;

contract LaunchMoneyPool is Ownable {
    
    using SafeMath for uint256;
    address public TOKEN;
    
    struct UserData {
        uint256 tokenQuantity;
        uint256 intialTimestamp;
        address user;
    }
    
    mapping(address => UserData) public userData;
    
    event Stake(
        address indexed userAddress,
        uint256 stakedAmount,
        uint256 Time
    );
    
    event UnStake(
        address indexed userAddress,
        uint256 unStakedAmount,
        uint256 _userReward,
        uint256 Time
    );
    
    event withdrawReward(
        uint256 tokenAmount,
        address indexed _from,
        address indexed _to,
        uint _time
    );
    
    event addPreviousRewardToUserBal(
        uint256 prviousrewards,
        address indexed _from,
        address indexed _to,
        uint _time
    );
    
    
    uint256 public APY = 5E18;
    uint256 public minStake;
    
    uint256 public totalStaking;
    
    constructor(address _token, uint256 _minStake) public {
        TOKEN = _token;
        minStake = _minStake;
        _owner = _msgSender();
    }
    
    function changeMinStake(uint256 _newMin) public {
        require(_msgSender() == _owner, "caller is not the owner");
        minStake = _newMin;
    }
    
    function stake(uint256 _quantity) public {
        require(_quantity >= minStake, "amount less than minimum require");
        UserData storage _userData = userData[_msgSender()];
        uint256 pendingReward = calculateRewards(_userData.user);
        
        if(_userData.tokenQuantity > 0 ) {
            _userData.tokenQuantity = _userData.tokenQuantity.add(pendingReward);
            emit addPreviousRewardToUserBal( pendingReward, address(this), _msgSender(), block.timestamp);
        }
        
        IBEP20(TOKEN).transferFrom(_msgSender(), address(this), _quantity);
        
        _userData.user = _msgSender();
        _userData.tokenQuantity = _userData.tokenQuantity.add(_quantity);
        _userData.intialTimestamp = block.timestamp;
        
        totalStaking = totalStaking.add(_quantity);
        emit Stake(_msgSender(), _quantity, block.timestamp);
        
    }
    
    function unStake(uint256 _amount) public {
        
        UserData storage _userData = userData[_msgSender()];
        require(_userData.tokenQuantity >= _amount, "RGP: Insufficient amount");
        
        uint256 pendingReward = calculateRewards(userData[_msgSender()].user);
        
        if(_amount == 0) {
            require(_userData.tokenQuantity > 0, "RGP: NO REWARD YET.");
            safeTokenTransfer(_msgSender(), pendingReward);
            _userData.tokenQuantity = _userData.tokenQuantity;
            _userData.intialTimestamp = block.timestamp;
            emit withdrawReward( pendingReward, address(this), _msgSender(), block.timestamp);
        }
        if(_amount > 0) {
            
            require( _amount <= _userData.tokenQuantity, "RGP: AMOUNT IS GREATER THAN USER STAKED TOKEN");
            _userData.tokenQuantity = _userData.tokenQuantity.sub(_amount);
            
            safeTokenTransfer(_msgSender(), pendingReward);
            IBEP20(TOKEN).transfer(_msgSender(), _amount);
            totalStaking = totalStaking.sub(_amount);
            
            _userData.intialTimestamp = block.timestamp;
            
            emit UnStake(_msgSender(), _amount, pendingReward, block.timestamp);
        }
    }
    
    function ownerBurn(uint256 _amount) public onlyOwner {
        IBEP20(TOKEN).burn(_amount);
    }
    
    function calculateRewards(address _stakerAddress) public view returns(uint256 reward) {
        UserData storage _userData = userData[_stakerAddress];
        _userData.user == _stakerAddress;
        uint256 time = block.timestamp.sub(_userData.intialTimestamp);
        uint256 pendingReward = (_userData.tokenQuantity.mul(APY))/100E18;
        uint256 yearly = (pendingReward / 365 days);
        reward = (yearly.mul(time));
        return reward;
    }
    
    function userInfo(address _addr) public view returns(address _staker, uint256 _amountStaked, uint256 _userReward, uint _timeStaked) {
        UserData storage _userData = userData[_addr];
        uint256 _reward = calculateRewards(_userData.user);
        if(_userData.tokenQuantity > 0) {
           _userReward = _userData.tokenQuantity.add(_reward);
        }
        
        return(_userData.user, _userData.tokenQuantity, _userReward, _userData.intialTimestamp);
    }
    
    function safeTokenTransfer(address staker, uint256 amount) internal {
        IBEP20(TOKEN).transfer(staker, amount);
    }
    
    
    // Safe Rigel withdraw function by admin
    function withdrawLaunchPoolToken(address _to, uint256 _amount) onlyOwner external {
        uint256 Lbalance = IBEP20(TOKEN).balanceOf(address(this));
        if (_amount > Lbalance) {
            IBEP20(TOKEN).transfer(_to, Lbalance);
        } else {
            IBEP20(TOKEN).transfer(_to, _amount);
        }
    }
    
}