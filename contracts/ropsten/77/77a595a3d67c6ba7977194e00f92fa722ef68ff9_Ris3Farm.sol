/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

pragma solidity ^0.5.0;
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

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


    function calculateAmountsAfterFee(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (uint256 transferToAmount, uint256 transferToFeeDistributorAmount);

    //mint function
    function mintByGovernance(uint256 amount) external;
    
    //burn function
    function burn(uint256 amount) external;
    
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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

//government contract interface
interface ris3Gov {
    function getCurrentLaws() external view returns (uint256 taxRates, uint256 prodRates, string memory taxPoolUses);
    
    function getCycleStartTime() external view returns (uint256 _cycleStartTime);
    
    function getWithdrawingStartTime() external view returns (uint256 _withdrawingStartTime);
    
    function getGovElectionStartTime() external view returns (uint256 _govElectionStartTime);
    
    function getRis3Address() external view returns (address _ris3Address);
    
    function getTaxPoolAddress() external view returns (address _taxPoolAddress);
}

pragma solidity ^0.5.0;

contract Ris3Farm is Ownable {
    using SafeMath for uint256;
    
    address governmentAddress = 0x6ff53cd24E7a1345cE1ff221BD2BcD11ed4D023B;
    ris3Gov public government = ris3Gov(governmentAddress);
    
    address public ris3Address = government.getRis3Address();
    IERC20 public ris3 = IERC20(ris3Address);
    
    address public taxPoolAddress = government.getTaxPoolAddress();
    
    uint256 public currentTotalRewards;
    uint256 public totalStaked;
    uint256 public totalStakers;
    address[] private stakers;
    
    struct ris3Items {
        uint256 lastStakingTime;
        uint256 totalAmount;
    }
    mapping(address => ris3Items) public userBalance;
    
    struct ris3Rewards {
        uint256 totalWithdrawn;
        uint256 lastWithdrawTime;
    }
    mapping(address => ris3Rewards) public userRewardInfo;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Burned(uint256 amount);
    
    constructor () public {
        
    }
    
    //Lp token staking
    function stake(uint256 amount) public {
        require(amount > 0, "Cannot stake 0");
        uint256 cycleStartTime = government.getCycleStartTime();
        uint256 withdrawingStartTime = government.getWithdrawingStartTime();
        require(now > cycleStartTime && now < withdrawingStartTime, "Staking can be done only on first day"); //staking only on first day
        
        //add value in ris3 token balance for user
        userBalance[msg.sender].totalAmount = getUserBalance(msg.sender).add(amount);
        userBalance[msg.sender].lastStakingTime = now;
        
        //total liquidity
        totalStaked += amount;
        
        //add total stakers
        totalStakers++;
        
        ris3.burn(amount);
        emit Staked(msg.sender, amount);
    }
    
    function calculateRewardTesting(address userAddress) public view returns (uint256 _percnt, uint256 _diff, uint256 _userRewardPerMinute) {
        uint256 cycleStartTime = government.getCycleStartTime();
        //uint256 amount = 0;
        uint256 ris3Amount = getUserBalance(userAddress);
        uint256 percnt = ris3Amount.div(totalStaked);
                percnt = percnt.mul(100);
                
        (uint256 taxRates, uint256 totalRewards, string memory taxPoolUses) = government.getCurrentLaws();
        
        uint256 diff = 0;
        
        uint256 govElectionStartTime = government.getGovElectionStartTime();
        //if not withdrawn on current cycle yet
        if (userRewardInfo[userAddress].lastWithdrawTime < cycleStartTime) {
           if (now < govElectionStartTime) {
               diff = now - government.getWithdrawingStartTime();
           } else {
               diff = govElectionStartTime - government.getWithdrawingStartTime();
           }
           
        } else {
           if (now < govElectionStartTime) {
              diff = now - userRewardInfo[userAddress].lastWithdrawTime;
           } else {
              diff = govElectionStartTime - userRewardInfo[userAddress].lastWithdrawTime;
           }
        }
        diff = diff / 60 / 1; //count for every 1 min
        uint256 rewardsEveryMinutes = totalRewards / 5 / 24 / 60; //get rewards every minutes
        uint256 userRewardPerMinute = rewardsEveryMinutes.mul(percnt);
                userRewardPerMinute = userRewardPerMinute.div(100);
                userRewardPerMinute = userRewardPerMinute;
                
        return ( percnt, diff, userRewardPerMinute);
    }
    
    //calculate your rewards
    function calculateReward(address userAddress) public view returns (uint256 _reward, uint256 _tax) {
        uint256 cycleStartTime = government.getCycleStartTime();
        uint256 amount = 0;
        uint256 ris3Amount = getUserBalance(userAddress);
        uint256 percnt = ris3Amount.div(totalStaked);
                percnt = percnt.mul(100);
        
        (uint256 taxRates, uint256 totalRewards, string memory taxPoolUses) = government.getCurrentLaws();
        
        uint256 diff = 0;
        
        uint256 govElectionStartTime = government.getGovElectionStartTime();
        
        //rewards can be calculated after staking done only
        if (now < government.getWithdrawingStartTime()){
            return ( 0, 0 );
        } else {
            //if not withdrawn on current cycle yet
            if (userRewardInfo[userAddress].lastWithdrawTime < cycleStartTime) {
               if (now < govElectionStartTime) {
                   diff = now - government.getWithdrawingStartTime();
               } else {
                   diff = govElectionStartTime - government.getWithdrawingStartTime();
               }
               
            } else {
               if (now < govElectionStartTime) {
                  diff = now - userRewardInfo[userAddress].lastWithdrawTime;
               } else {
                  diff = govElectionStartTime - userRewardInfo[userAddress].lastWithdrawTime;
               }
            }
            diff = diff / 60 / 60; //count for every 1 second
            
            uint256 rewardsEveryMinutes = totalRewards / 5 / 24 / 60/ 60; //get rewards every minutes
            uint256 userRewardPerMinute = rewardsEveryMinutes.mul(percnt);
                    userRewardPerMinute = userRewardPerMinute.div(100);
                    userRewardPerMinute = userRewardPerMinute;
            
            amount = userRewardPerMinute.mul(diff);
            uint256 tax = amount.mul(taxRates);
                    tax = tax.div(100);
            return (amount - tax, tax);
        }
    }
    
    //withdraw your reward
    function withdrawRewards() public {
        ( uint256 amount, uint256 tax ) = calculateReward(msg.sender);
        require(amount > 0, "No rewards for this address");
        uint256 WithdrawingStartTime = government.getWithdrawingStartTime();
        require(now > WithdrawingStartTime, "Can withdraw after staking time");
        
        //update total reward collected
        userRewardInfo[msg.sender].totalWithdrawn = getTotalRewardCollectedByUser(msg.sender).add(amount);
        userRewardInfo[msg.sender].lastWithdrawTime = now;
        
        //transfer amount to user
        ris3.transfer(msg.sender, amount);
        
        //transfer tax to tax taxPool
        ris3.transfer(taxPoolAddress, tax);
        
        emit Withdrawn(msg.sender, amount);
    }
    
    //burn remaining rewards
    function governmentBurnTokens() public {
        //it will call when new cycle start
        require(msg.sender == governmentAddress, "Only government can burn tokens in farm");
        uint256 amount = ris3.balanceOf(address(this));
        
        totalStakers = 0;
        totalStaked = 0;
        
        ris3.burn(amount); //call burn function
        emit Burned(amount);
    }
    
    //get user balance
    function getUserBalance(address userAddress) view public returns (uint256 _amount)
    {
        if (userBalance[userAddress].lastStakingTime < government.getCycleStartTime()) {
            return 0;
        } else {
            return userBalance[userAddress].totalAmount;
        }
    }
    
    //get total rewards collected by user
    function getTotalRewardCollectedByUser(address userAddress) view public returns (uint256 _totalRewardCollected) 
    {
        if (userRewardInfo[userAddress].lastWithdrawTime < government.getCycleStartTime()) {
            return 0;
        } else {
            userRewardInfo[userAddress].totalWithdrawn;
        }
    }
    
    //get total no of stakers
    function getTotalStakers() view public returns (uint256 _noOfStakers)
    {
        return totalStakers;
    }
    
    function getTotalRemainingRewards() view public returns (uint256 _totalRemainingRewards)
    {
        return ris3.balanceOf(address(this)) - totalStaked;
    }
    
    //get total liquidity staked
    function getTotalStaked() view public returns (uint256 _totalStaked)
    {
        return totalStaked;
    }
    
    //set government address
    function setGovernmentAddress(address _govAddress) public onlyOwner {
        governmentAddress = _govAddress;
        government = ris3Gov(governmentAddress);
        ris3Address = government.getRis3Address();
        ris3 = IERC20(ris3Address);
        taxPoolAddress = government.getTaxPoolAddress();
    }
    
}