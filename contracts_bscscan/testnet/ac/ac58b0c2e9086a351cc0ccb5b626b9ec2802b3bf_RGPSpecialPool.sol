/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

// SPDX-License-Identifier: UNLICENSED

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

// File: contracts/token/BEP20/IBEP20.sol

// pragma solidity >=0.4.0;

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

// File: contracts/utils/Address.sol

pragma solidity ^0.6.12;

/**
 * @dev Collection of functions related to the address type
 */


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
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// pragma solidity >=0.4.0;


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
contract Ownable is Context {
    address private _owner;

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

// File: contracts/MasterChef.sol

pragma solidity 0.6.12;

contract RGPSpecialPool is Ownable {
    
    using SafeMath for uint256;
    address public TOKEN;
    
    // store user details
    // amount of token staked
    // timestamp
    // address of the user
    // A Struct "A struct in solidity is just a custom type that you can define. You define the struct with a name and associated properties inside of it"
    // implementations "https://docs.soliditylang.org/en/v0.8.9/structure-of-a-contract.html?highlight=struct"
    struct UserData {
        uint256 tokenQuantity;
        uint256 intialTimestamp;
        uint256 referralID;
        uint256 _referralBonus;
        address user;
    }
    
    // what mapping really is :
    // Mappings act as hash tables which consist of key types and corresponding value type pairs. They are defined like any other variable type in Solidity:
    // implementations "https://docs.soliditylang.org/en/v0.8.9/style-guide.html?highlight=mapping#mappings"
    mapping(address => bool) public isAdminAddress; // updating and checking the addresses that are admins
    mapping(address => UserData) public userData; // get user detatils
    mapping(address => mapping(address => bool )) public myReferral;
    
    // event manager help to update user on token staked. 
    // extract from "https://docs.soliditylang.org/en/v0.8.9/structure-of-a-contract.html?highlight=event#structure-events"
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
    
    event adminAdded(
        address[] _admins,
        bool
    );
    
    // $RGP distribution according to specifications...
    uint256 public ENTRY_RATE = 7.5E18;
    uint256 public DAYS30_RATE = 8E18;
    uint256 public YEAR_RATE = 10E18;
    uint256 public referralBonus;
    
    // total numbers of $RGP staked
    uint256 public totalStaking;
    
    // minimum staked amount
    uint256 minimum;
    
    // called once at every deployment
    // A constructor is an optional function that is executed upon contract creation.
    constructor(address _token, uint256 miniMumStake, uint256 referral) public {
        minimum = miniMumStake;
        TOKEN = _token;
        referralBonus = referral;
        isAdminAddress[_msgSender()] = true;
    }
    
    // check to be sure that only License address/addresses can called a specific functions in this contract.
    // A modifier allows you to control the behavior of your smart contract functions.
    // implementations "https://docs.soliditylang.org/en/v0.8.9/structure-of-a-contract.html?highlight=modifier"
    modifier onlyAdmin() {
        require(isAdminAddress[_msgSender()]);
        _;
    }

    // where user can stake their $RGP,
    // _quantity: amount of $RGP that user want to stake.
    // user must approve the staking contract adrress before calling this function
    function stake(uint256 _quantity, address _referral) public {
        require(_quantity >= minimum, "amount staked is less than minimum staking amount");
        UserData storage _userData = userData[_msgSender()];
        
        if (_referral != address(0x0)) {
            UserData storage updateReferral = userData[_referral];
            require(updateReferral.tokenQuantity != 0, "Referral's account must have staked their $RGP.");
            require(updateReferral.user != _msgSender(), "Referral's account not on the List.");
            require(myReferral[_msgSender()][_referral] != true, "RIGEL: cant refer same address twice");
            myReferral[_msgSender()][_referral] = true;
            
            updateReferral.referralID++;
            updateReferral._referralBonus = updateReferral._referralBonus.add(referralBonus);
            updateReferral.tokenQuantity = updateReferral.tokenQuantity.add(updateReferral._referralBonus);
        }
        
        // get user current rewards if input token quantity is 0
        uint256 pendingReward = calculateRewards(_userData.user);
        
        // if user had previously staked then an update in user data is require
        if(_userData.tokenQuantity > 0 ) {
            _userData.tokenQuantity = _userData.tokenQuantity.add(pendingReward);
            emit addPreviousRewardToUserBal( pendingReward, address(this), _msgSender(), block.timestamp);
        }
        
        // mode of transfering token from user to the staking pool
        IBEP20(TOKEN).transferFrom(_msgSender(), address(this), _quantity);
        
        _userData.user = _msgSender(); // update caller to the list of stakers
        _userData.tokenQuantity = _userData.tokenQuantity.add(_quantity); // update user staked amount
        _userData.intialTimestamp = block.timestamp; // update time staked
        
        totalStaking = totalStaking.add(_quantity); // update total staking amount
        emit Stake(_msgSender(), _quantity, block.timestamp); // emission of events to enable listening to a specific act of an address that successfully staked
        
    }
    

    // use by an address that have staked there $RGP to unstake at a desire time.    
    // is _quantity is 0 it will withdraw user rewards from the contract
    function unStake(uint256 _amount) public {
        
        UserData storage _userData = userData[_msgSender()]; // get user from the list of staked address
        require(_userData.tokenQuantity >= _amount, "RGP: Insufficient amount"); // requirement that input amount by the caller is less than what user staked
        
        uint256 pendingReward = calculateRewards(userData[_msgSender()].user); //get the current rewards of User
        
        // if input amount is 0 it will withdraw user current rewards
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
    
    function calculateRewards(address _stakerAddress) public view returns(uint256 reward) {
        UserData storage _userData = userData[_stakerAddress];
        _userData.user == _stakerAddress;
        uint256 time = block.timestamp.sub(_userData.intialTimestamp);
    
        if (block.timestamp <= _userData.intialTimestamp.add(30 days)) {
            uint256 pendingReward = (_userData.tokenQuantity.mul(ENTRY_RATE))/100E18;
            uint256 yearly = (pendingReward / 365 days);
            reward = (yearly.mul(time));
            return reward;
        }
        
        if (block.timestamp >= _userData.intialTimestamp.add(30 days) && block.timestamp <= _userData.intialTimestamp.add(90 days)) {
            uint256 pendingReward = (_userData.tokenQuantity.mul(DAYS30_RATE))/100E18;
            uint256 yearly = (pendingReward / 365 days);
            reward = (yearly.mul(time));
            // reward = (pendingReward.div(90 days).mul(time));
            return reward;
        }
        
        if (block.timestamp > _userData.intialTimestamp.add(90 days)) {
            uint256 pendingReward = (_userData.tokenQuantity.mul(YEAR_RATE))/100E18;
            uint256 yearly = (pendingReward / 365 days);
            reward = (yearly.mul(time));
            return reward;
        }
    }
    
    function userInfo(address _addr) public view returns(address _staker, uint256 _amountStaked, uint256 _userReward, uint _timeStaked, uint256 totalReferralBonus, uint256 id) {
        UserData storage _userData = userData[_addr];
        uint256 _reward = calculateRewards(_userData.user);
        if(_userData.tokenQuantity > 0) {
           _userReward = _userData.tokenQuantity.add(_reward);
        }
        
        return(
            _userData.user, 
            _userData.tokenQuantity,
            _userReward,
            _userData.intialTimestamp,
            _userData._referralBonus,
            _userData.referralID
            );
    }
    
    function safeTokenTransfer(address staker, uint256 amount) internal {
        IBEP20(TOKEN).transfer(staker, amount);
    }
    
    function multipleAdmin(address[] calldata _adminAddress, bool status) external onlyOwner {
        if (status == true) {
           for(uint256 i = 0; i < _adminAddress.length; i++) {
            isAdminAddress[_adminAddress[i]] = status;
            } 
        } else{
            for(uint256 i = 0; i < _adminAddress.length; i++) {
                delete(isAdminAddress[_adminAddress[i]]);
            } 
        }
    }
    
    // Safe Rigel withdraw function by admin
    function safeRigelWithdraw(address _to, uint256 _amount) onlyOwner external {
        uint256 rigelBalalance = IBEP20(TOKEN).balanceOf(address(this));
        if (_amount > rigelBalalance) {
            IBEP20(TOKEN).transfer(_to, rigelBalalance);
        } else {
            IBEP20(TOKEN).transfer(_to, _amount);
        }
    }
    
    function updateReferralBonus(uint256 _newBonus) public onlyOwner {
        referralBonus = _newBonus;
    }
    
     function getMinimumStakeAmount() public view returns(uint256 min) {
        return minimum;
    }
    
    function setMinimumStakeAmount(uint256 min) external onlyOwner {
        minimum = min;
    }
    
}