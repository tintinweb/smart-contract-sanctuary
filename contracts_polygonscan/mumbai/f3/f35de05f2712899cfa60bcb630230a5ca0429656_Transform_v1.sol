/**
 *Submitted for verification at polygonscan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

contract Transform_v1 is Ownable {
    using SafeMath for uint256;

    address private HODLAddress = 0x88eeDE6bb6e698364BaCAB55BB9fC4b93DF3BeBD;
    
    struct AffiliateItem {
        uint256 amount;
        address affiliate;
    }

    struct PoolInfo {
        mapping(address => AffiliateItem) affiliate_info;
        uint256 totalAmount_Affiliate;
        address[] addresses_Affiliate;

        mapping(address => uint256) amounts_NoAffiliate;
        uint256 totalAmount_NoAffiliate;
        address[] addresses_NoAffiliate;

        address tokenAddress;
        uint256 decimals;
        uint256 totalHODLamount;
        uint256 startTime;
        uint256 duration;
    }

    PoolInfo[10] pools;

    bool public enableDistribution = false;
    
    uint256 private HODL_DECIMALS = 8;
    uint256 public DAILY_HODL_QUANTITY = 1500000 * (10 ** HODL_DECIMALS);
    uint256 public DEFAULT_DURATION = 10 days;

    uint256 public DEFAULT_1TH_HODL_AMOUNT = 2500000 * (10 ** HODL_DECIMALS);
    uint256 public DEFAULT_2TH_HODL_AMOUNT = 2500000 * (10 ** HODL_DECIMALS);

    constructor() public {
    }

    function updatePool(
        uint256 _poolindex, 
        address _token,
        uint256 _decimals,
        uint256 _startTime, 
        uint256 _duration, 
        uint256 _totalHODLamount
        ) public onlyOwner {
            require(pools.length > _poolindex, "Exceeded pool index");
            pools[_poolindex].tokenAddress = _token;
            pools[_poolindex].decimals = _decimals;
            pools[_poolindex].startTime = _startTime;
            pools[_poolindex].duration = _duration;
            pools[_poolindex].totalHODLamount = _totalHODLamount * (10 ** HODL_DECIMALS);
    }

    function changeHODLAddress(address _address) public onlyOwner {
        HODLAddress = _address;
    }

    function IsValidTime(uint256 _poolindex) public view returns(bool) {
        require(pools.length > _poolindex, "Exceeded pool index");
        if(block.timestamp >= pools[_poolindex].startTime && 
            block.timestamp < pools[_poolindex].startTime.add(pools[_poolindex].duration))
                return true;
        return false;
    }

    function depositTokensWithoutAffiliate(uint256 _poolindex, uint256 _amt) public {
                
        require(pools.length > _poolindex, "Exceeded pool index");
        require(IsValidTime(_poolindex), "Invalid Time");

        uint256 _amount = _amt * (10 ** pools[_poolindex].decimals);
        require(IERC20(pools[_poolindex].tokenAddress).balanceOf(msg.sender) >= _amount, "Insuficient Balance");
        IERC20(pools[_poolindex].tokenAddress).transferFrom(msg.sender, address(this), _amount);

        uint256 previousDepositAmount = pools[_poolindex].amounts_NoAffiliate[msg.sender];
        pools[_poolindex].amounts_NoAffiliate[msg.sender] = previousDepositAmount.add(_amount);
        if(previousDepositAmount <= 0) {
            pools[_poolindex].addresses_NoAffiliate.push(msg.sender);
        }
        pools[_poolindex].totalAmount_NoAffiliate = pools[_poolindex].totalAmount_NoAffiliate.add(_amount);
    }
    
    function depositTokensWithAffiliate(uint256 _poolindex, uint256 _amt, address _affiliateAddress) public {
        require(pools.length > _poolindex, "Exceeded pool index");
        require(IsValidTime(_poolindex), "Invalid Time");

        uint256 _amount = _amt * (10 ** pools[_poolindex].decimals);
        require(IERC20(pools[_poolindex].tokenAddress).balanceOf(msg.sender) >= _amount, "Insuficient Balance");
        IERC20(pools[_poolindex].tokenAddress).transferFrom(msg.sender, address(this), _amount);

        uint256 previousDepositAmount = pools[_poolindex].affiliate_info[msg.sender].amount;
        pools[_poolindex].affiliate_info[msg.sender].amount = previousDepositAmount.add(_amount);
        if(previousDepositAmount <= 0) {
            pools[_poolindex].affiliate_info[msg.sender].affiliate = _affiliateAddress;
            pools[_poolindex].addresses_Affiliate.push(msg.sender);
        }
        pools[_poolindex].totalAmount_Affiliate = pools[_poolindex].totalAmount_Affiliate.add(_amount);
    }
    
    function depositMATICWithoutAffiliate() public payable {
        uint256 _poolindex = 0; // MATIC Pool
        require(pools.length > _poolindex, "Exceeded pool index");
        require(IsValidTime(_poolindex), "Invalid Time");

        uint256 previousDepositAmount = pools[_poolindex].amounts_NoAffiliate[msg.sender];
        pools[_poolindex].amounts_NoAffiliate[msg.sender] = previousDepositAmount.add(msg.value);
        if(previousDepositAmount <= 0) {
            pools[_poolindex].addresses_NoAffiliate.push(msg.sender);
        }
        pools[_poolindex].totalAmount_NoAffiliate = pools[_poolindex].totalAmount_NoAffiliate.add(msg.value);
    }
        
    function depositMATICWithAffiliate(address _affiliateAddress) public payable {
        uint256 _poolindex = 0;
        require(pools.length > _poolindex, "Exceeded pool index");
        require(IsValidTime(_poolindex), "Invalid Time");

        uint256 previousDepositAmount = pools[_poolindex].affiliate_info[msg.sender].amount;
        pools[_poolindex].affiliate_info[msg.sender].amount = previousDepositAmount.add(msg.value);
        if(previousDepositAmount <= 0) {
            pools[_poolindex].affiliate_info[msg.sender].affiliate = _affiliateAddress;
            pools[_poolindex].addresses_Affiliate.push(msg.sender);
        }
        pools[_poolindex].totalAmount_Affiliate = pools[_poolindex].totalAmount_Affiliate.add(msg.value);
    }

    function EnableDistribution(bool bEnable) public onlyOwner {
        enableDistribution = bEnable;
    }

    function distributionHODLs(uint256 _poolindex) public onlyOwner {
        require(enableDistribution);
        uint256 totalAmount = pools[_poolindex].totalAmount_Affiliate.add(pools[_poolindex].totalAmount_NoAffiliate);

        for(uint256 i = 0; i < pools[_poolindex].addresses_NoAffiliate.length; i++) {
            address add = pools[_poolindex].addresses_NoAffiliate[i];
            uint256 amount = pools[_poolindex].amounts_NoAffiliate[add];
            uint256 hodlamount = pools[_poolindex].totalHODLamount.mul(amount).div(totalAmount);               
            if(hodlamount <= 0) continue;
            IERC20(HODLAddress).transfer(add, hodlamount);
        }

        for(uint256 i = 0; i < pools[_poolindex].addresses_Affiliate.length; i++) {
            address add = pools[_poolindex].addresses_Affiliate[i];
            uint256 amount = pools[_poolindex].affiliate_info[add].amount;
            uint256 hodlamount = pools[_poolindex].totalHODLamount.mul(amount).div(totalAmount);               
            if(hodlamount <= 0) continue;
            IERC20(HODLAddress).transfer(add, hodlamount);
        }        
    }

    function distributionHODLsFor1thBonus() public onlyOwner {
        require(enableDistribution);
        uint256 affiliateCount = 0;
        for(uint256 i = 0; i < pools.length; i++) {
            affiliateCount = affiliateCount.add(pools[i].addresses_Affiliate.length);
        }

        uint256 hodlamount = DEFAULT_1TH_HODL_AMOUNT.div(affiliateCount);

        for(uint256 i = 0; i < pools.length; i++) {
            for(uint256 j = 0; j < pools[i].addresses_Affiliate.length; j++) {                
                if(hodlamount <= 0) continue;
                IERC20(HODLAddress).transfer(pools[i].addresses_Affiliate[j], hodlamount);
            }
        }
    }

    function distributionHODLsFor2thBonus() public onlyOwner {
        require(enableDistribution);
        for(uint256 i = 0; i < pools.length; i++) {
            for(uint256 j = 0; j < pools[i].addresses_Affiliate.length; j++) {
                address add = pools[i].addresses_Affiliate[j];
                
                uint256 hodlpercent = 0;
                for(uint256 k = 0; k < pools.length; k++) {
                    uint256 percentperpool = pools[k].affiliate_info[add].amount.mul(10 ** HODL_DECIMALS).div(pools[k].totalAmount_Affiliate);
                    hodlpercent = hodlpercent.add(percentperpool);
                }
                if(hodlpercent <= 0) continue;

                uint256 hodlamount = DEFAULT_2TH_HODL_AMOUNT.mul(hodlpercent).div(10 ** HODL_DECIMALS).div(pools.length);
                uint256 useramount = hodlamount.mul(9).div(10);
                uint256 affiliateamount = hodlamount.sub(useramount);

                IERC20(HODLAddress).transfer(add, useramount);
                IERC20(HODLAddress).transfer(pools[i].affiliate_info[add].affiliate, affiliateamount);
            }
        }
    }

    function approve(address tokenAddress, address spender, uint256 amount) public onlyOwner returns (bool) {
        IERC20(tokenAddress).approve(spender, amount);
        return true;
    }
    
    function releaseFunds(uint256 amount) external onlyOwner {
        msg.sender.transfer(amount);
    }
    
    function releaseFundsAll() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function recoverBEP20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
    
    event Recovered(address token, uint256 amount);
}