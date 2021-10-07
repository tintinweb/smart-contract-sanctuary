//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }



    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}


contract BXStaking is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    /*
    ***********VARIABLES***********
    */
	string public name = "PDOG - Staking";
    IERC20 public tokenA;
    IERC20 public rewardToken;
    uint256 public rewardRate;
    uint256 public blockLimit;
	address[] public stakers;
	mapping(address=>uint256) public stakingStartTime; // to manage the time when the user started the staking 
	mapping(address => uint) public stakedBalance;     // to manage the staking of token A  and distibue the profit as token B
	mapping(address => bool) public hasStaked;
	mapping(address => bool) public isStaking;
	mapping(address => uint256) public oldReward;
	uint256 private _totalSupply;
    /*
        ***********EVENTS***********
    */
	event Reward(address indexed from, address indexed to, uint256 amount);
	event StakeTransfer(address indexed from, address indexed to, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
    event ExternalTokenTransfered(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event EthFromContractTransferred(
        uint256 amount
    );
    event SetRewardRate(uint256 rate);
    event SetRewardToken(IERC20 token);

	constructor(IERC20 _tokenA, uint256 _rewardRate, uint256 _blockLimit) {
		tokenA = _tokenA;
		rewardToken = _tokenA;
        rewardRate = _rewardRate;
        blockLimit = _blockLimit;
	}

	/* Stakes Tokens (Deposit): An investor will deposit the TokenA into the smart contracts
	to starting earning rewards.
		
	Core Thing: Transfer the tokenA from the investor's wallet to this smart contract. */
	function stakeTokenA(uint _amount) external virtual nonReentrant whenNotPaused {
        require(block.number >= blockLimit, "current block number is below the Block Limit");		
        require(_amount > 0, "staking balance cannot be 0");
        require(tokenA.balanceOf(msg.sender) > _amount);
		// add user to stakers array *only* if they haven't staked already
		// save the time when they started staking 
		if(!hasStaked[msg.sender]) {
			stakers.push(msg.sender);
		}
		if(isStaking[msg.sender]){
		    uint256 oldR = calculateReward();
		    oldReward[msg.sender] = oldReward[msg.sender] + oldR;
		}
		tokenA.transferFrom(msg.sender, address(this), _amount);
		// update staking balance
		stakedBalance[msg.sender] = stakedBalance[msg.sender] + _amount;
		// update stakng status
		stakingStartTime[msg.sender] = block.timestamp;
		isStaking[msg.sender] = true;
		hasStaked[msg.sender] = true;
        emit StakeTransfer(msg.sender, address(this), _amount);
    }
    
    function unstakeTokenA() external virtual nonReentrant whenNotPaused {
        require(isStaking[msg.sender], "User have no staked tokens to unstake");
        uint balance = stakedBalance[msg.sender];
        require(balance > 0, "staking balance cannot be 0");
        require(tokenA.balanceOf(address(this)) > balance, "Not Enough staked tokens in the smart contract");
        uint256 reward = calculateReward();
        uint256 totalReward = reward.add(oldReward[msg.sender]);
        require(rewardToken.balanceOf(address(this)) > totalReward, "Not Enough tokens in the smart contract");
        rewardToken.transfer(msg.sender, totalReward);
		tokenA.transfer(msg.sender, balance);
		emit StakeTransfer(address(this), msg.sender, balance);
		oldReward[msg.sender] = 0;
		// reset staking balance
		stakedBalance[msg.sender] = 0;
		// update staking status and stakingStartTime (restore to zero)
		isStaking[msg.sender] = false;
		stakingStartTime[msg.sender] = 0;
        emit Reward(address(this), msg.sender, totalReward);
	}

    function calculateReward() public view returns(uint256){
        uint balances = stakedBalance[msg.sender];
		// require amount greater than 0
		uint256 rewards = 0;
		if(balances > 0){
		    uint256 timeDifferences = block.timestamp - stakingStartTime[msg.sender];
		    //Reward Calculation
		    rewards = balances.mul(timeDifferences).mul(rewardRate).div(100).div(3600);
		}
		return rewards;
    }

    function withdrawFromStaked(uint256 amount) external virtual nonReentrant {
        require(isStaking[msg.sender], "User have no staked tokens to unstake");
        require(amount > 0, "Cannot withdraw 0");
        uint256 oldR = calculateReward();
        if(oldR >0 && oldR <= rewardToken.balanceOf(address(this))){
            oldReward[msg.sender] = oldReward[msg.sender] + oldR;
        }
        stakedBalance[msg.sender] = stakedBalance[msg.sender].sub(amount);
        tokenA.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getTotalStaked() external view returns (uint256) {
        return tokenA.balanceOf(address(this));
    }

    function claimMyReward() external nonReentrant whenNotPaused {
        require(isStaking[msg.sender], "User have no staked tokens to get the reward");
        uint balance = stakedBalance[msg.sender];
        require(balance > 0, "staking balance cannot be 0");
        uint256 reward = calculateReward();
        uint256 tReward = reward.add(oldReward[msg.sender]);
        require(rewardToken.balanceOf(address(this)) > tReward, "Not Enough tokens in the smart contract");
		rewardToken.transfer(msg.sender, tReward);
        emit Reward(address(this), msg.sender, tReward);
		//stakingStartTime (set to current time)
		stakingStartTime[msg.sender] = block.timestamp;
	}
	
	function withdrawERC20Token(address _tokenContract, uint256 _amount) external virtual onlyOwner {
        require(_tokenContract != address(0), "Address cant be zero address");
		// require amount greter than 0
		require(_amount > 0, "amount cannot be 0");
        IERC20 tokenContract = IERC20(_tokenContract);
        require(tokenContract.balanceOf(address(this)) > _amount);
		tokenContract.transfer(msg.sender, _amount);
        emit ExternalTokenTransfered(_tokenContract, msg.sender, _amount);
	}
	
	function getBalance() internal view returns (uint256) {
        return address(this).balance;
    }
	
	function withdrawETHFromContract(uint256 amount) external virtual onlyOwner {
        require(amount <= getBalance());        
        address payable _owner = payable(msg.sender);        
        _owner.transfer(amount);        
        emit EthFromContractTransferred(amount);
    }

    function setRewardRate(uint256 _rewardRate) external virtual onlyOwner whenNotPaused {
        rewardRate = _rewardRate;
        emit SetRewardRate(rewardRate);
    }
    
    function setRewardToken(IERC20 _tokenA) external virtual onlyOwner whenNotPaused {
        rewardToken = _tokenA;
        emit SetRewardToken(rewardToken);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}