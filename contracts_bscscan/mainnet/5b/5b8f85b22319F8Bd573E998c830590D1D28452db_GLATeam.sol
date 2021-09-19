/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

// SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}




// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/GLATeam.sol


pragma solidity ^0.8.0;






contract GLATeam is Ownable {
    struct TeamLeadInfo {
        uint256 depositBalance;
        uint256 totalClaimable;
        uint256 claimed;
    }
    using SafeMath for uint256;
    
    address teamWallet; 
    address glaTokenAddress;
    
    mapping(address=>bool) leaderAddresses; // Team leader addresses
    mapping(address=>TeamLeadInfo) leaderInfos;
    mapping(uint256 => uint256) unlockFundRate; // phase => unlock rate
       
    uint256 tgeUnlockTime; // PancakeSwap listing time
    uint256 unlockTimeLock = 30 days;

    bool isUnlockClaim = false;
    
    constructor(address _glaTokenAddress, address _teamWallet){
        glaTokenAddress = _glaTokenAddress;
        teamWallet = _teamWallet;
        // 6% unlock per month after TGE
        unlockFundRate[0] = 0; 
        unlockFundRate[1] = 6;
        unlockFundRate[2] = 12;
        unlockFundRate[3] = 18;
        unlockFundRate[4] = 24;
        unlockFundRate[5] = 30;
        unlockFundRate[6] = 36;
        unlockFundRate[7] = 42;
        unlockFundRate[8] = 48;
        unlockFundRate[9] = 54;
        unlockFundRate[10] = 60;
        unlockFundRate[11] = 66;
        unlockFundRate[12] = 72;
        unlockFundRate[13] = 78;
        unlockFundRate[14] = 84;
        unlockFundRate[15] = 90;
        unlockFundRate[16] = 96;
        unlockFundRate[17] = 100;
        
        registLeaderAddress();
    }
    
    function withdrawPoolAmount() public onlyOwner{
        IERC20(glaTokenAddress).transfer(teamWallet, IERC20(glaTokenAddress).balanceOf(address(this)));
    }
    
    function unlockClaim() public onlyOwner{
        tgeUnlockTime = block.timestamp;
        isUnlockClaim = true;
    }
        
    function setGLAToken(address _glaTokenAddress) public onlyOwner{
        glaTokenAddress = _glaTokenAddress;
    }
    
    function setTeamWallet(address _teamWallet) public onlyOwner{
        teamWallet = _teamWallet;
    }
    
    // team leads can change their receiving address
    function changeReceiver(address _changeAddress) public{
        require(isLeaderAddress(_msgSender()),"Not in seed sale address");
        leaderAddresses[_msgSender()] = false;
        leaderAddresses[_changeAddress] = true;
        leaderInfos[_changeAddress] = leaderInfos[_msgSender()]; 
    }

    function registLeaderAddress()  internal {
        leaderAddresses[address(0x23A6Ba1B29990bDF3846b08018df77d734fA05b3)] = true ; // Dev
        leaderAddresses[address(0x55190075b6258da3806DdfCB24034f188b4a4308)] = true ; // Advisor
        leaderAddresses[address(0x7bCbBF7483B6625F60fa3eB81BC34F6A4133F03a)] = true ; // Team lead
        leaderAddresses[address(0xA304232b9FB4446eE4e1A3a02028E176ED875ac6)] = true ; // Ideas
        leaderAddresses[address(0xd13cADa769F71B1dDDd2DB604462627c258E3C8C)] = true ; // Finance 
        leaderAddresses[address(0x153cFEe8D57219fBC6AAa75369c55cC6a0A040Fc)] = true ; // Market
        leaderAddresses[address(0x9f601E04e2729F87054e1Cf66CDf5c3b2394D802)] = true ; // Design 
        leaderAddresses[address(0xD65C9fa28b6c6438d388cF76558C866CF4696969)] = true ; // airdrop 

        leaderInfos[address(0x23A6Ba1B29990bDF3846b08018df77d734fA05b3)].depositBalance = 9*3*10**23; //  30%
        leaderInfos[address(0x55190075b6258da3806DdfCB24034f188b4a4308)].depositBalance = 9*1*10**23; //  10%
        leaderInfos[address(0x7bCbBF7483B6625F60fa3eB81BC34F6A4133F03a)].depositBalance = 9*1*10**23; //  10%
        leaderInfos[address(0xA304232b9FB4446eE4e1A3a02028E176ED875ac6)].depositBalance = 9*1*10**23; //  10%
        leaderInfos[address(0xd13cADa769F71B1dDDd2DB604462627c258E3C8C)].depositBalance = 9*1*10**23; //  10%
        leaderInfos[address(0x153cFEe8D57219fBC6AAa75369c55cC6a0A040Fc)].depositBalance = 9*1*10**23; //  10%
        leaderInfos[address(0x9f601E04e2729F87054e1Cf66CDf5c3b2394D802)].depositBalance = 9*1*10**23; //  10%
        leaderInfos[address(0xD65C9fa28b6c6438d388cF76558C866CF4696969)].depositBalance = 9*1*10**23; //  10%
        
        leaderInfos[address(0x23A6Ba1B29990bDF3846b08018df77d734fA05b3)].totalClaimable = 9*3*10**23;
        leaderInfos[address(0x55190075b6258da3806DdfCB24034f188b4a4308)].totalClaimable = 9*1*10**23;
        leaderInfos[address(0x7bCbBF7483B6625F60fa3eB81BC34F6A4133F03a)].totalClaimable = 9*1*10**23;
        leaderInfos[address(0xA304232b9FB4446eE4e1A3a02028E176ED875ac6)].totalClaimable = 9*1*10**23;
        leaderInfos[address(0xd13cADa769F71B1dDDd2DB604462627c258E3C8C)].totalClaimable = 9*1*10**23;
        leaderInfos[address(0x153cFEe8D57219fBC6AAa75369c55cC6a0A040Fc)].totalClaimable = 9*1*10**23;
        leaderInfos[address(0x9f601E04e2729F87054e1Cf66CDf5c3b2394D802)].totalClaimable = 9*1*10**23;
        leaderInfos[address(0xD65C9fa28b6c6438d388cF76558C866CF4696969)].totalClaimable = 9*1*10**23;
    }
    
    function claim() public {
        require(isUnlockClaim, "Not unlock claim");
        require(isLeaderAddress(_msgSender()),"Not in leader address");
        
        uint256 unlockedAmount = getUnlockedAmount(_msgSender());
        
        // claimable amount
        uint256 availableForClaimAmount = availableClaim(_msgSender());
        require(availableForClaimAmount > 0, "Nothing for claim");
        
        // send to leader
        IERC20(glaTokenAddress).transfer(_msgSender(), availableForClaimAmount);

        // reset claimed tokens
        leaderInfos[_msgSender()].claimed = unlockedAmount;
    }
    
    function getTotalDeposit(address _address) public view returns(uint256){
        return leaderInfos[_address].depositBalance;
    }
    
    function getTotalClaimableBalance(address _address) public view returns(uint256){
        return leaderInfos[_address].totalClaimable;
    }
    
    function getNextTimestampClaim() public view returns(uint256){
        uint256 unlockFundRateIndex = block.timestamp.sub(tgeUnlockTime).div(unlockTimeLock).add(1);
        return unlockFundRateIndex.mul(unlockTimeLock).add(tgeUnlockTime);
    }
    
    function isLeaderAddress(address _address) public view returns(bool){
        return leaderAddresses[_address];
    }
    
    function availableRemainClaimable(address _address) public view returns(uint256){
        return  leaderInfos[_address].totalClaimable.sub(leaderInfos[_address].claimed);
    }
    
    function availableClaim(address _address) public view returns(uint256){
        uint256 unlockedAmount = getUnlockedAmount(_address);
        return unlockedAmount - leaderInfos[_address].claimed;
    }
    
    function getUnlockedAmount(address _address) internal view returns(uint256){
        // get index of unlockFundRate
        uint256 unlockFundRateIndex = block.timestamp.sub(tgeUnlockTime).div(unlockTimeLock);
        
        // release all in 17 months 
        if(unlockFundRateIndex > 17) 
            unlockFundRateIndex = 17;

        // return rate * claimable tokens
        return leaderInfos[_address].totalClaimable.mul(unlockFundRate[unlockFundRateIndex]).div(100);
    }
}