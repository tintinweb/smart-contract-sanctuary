/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
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


contract BoneLocker is Ownable {
    using SafeMath for uint256;
    IERC20 boneToken;
    address emergencyAddress;
    bool emergencyFlag = false;

    struct LockInfo{
        uint256 _amount;
        uint256 _timestamp;
        bool _isDev;
    }

    uint256 public lockingPeriod;
    uint256 public devLockingPeriod;

    mapping (address => LockInfo[]) public lockInfoByUser;
    mapping (address => uint256) public latestCounterByUser;
    mapping (address => uint256) public unclaimedTokensByUser;

    constructor(address _boneToken, address _emergencyAddress, uint256 _lockingPeriodInDays, uint256 _devLockingPeriodInDays) public {
        boneToken = IERC20(_boneToken);
        emergencyAddress = _emergencyAddress;
        lockingPeriod = _lockingPeriodInDays;
        devLockingPeriod = _devLockingPeriodInDays * 1 days;
    }

    // function to lock user reward bone tokens in token contract, called by onlyOwner that would be TopDog.sol
    function lock(address _holder, uint256 _amount, bool _isDev) public onlyOwner {
        require(_holder != address(0), "Invalid user address");
        require(_amount > 0, "Invalid amount entered");

        lockInfoByUser[_holder].push(LockInfo(_amount, now, _isDev));
        unclaimedTokensByUser[_holder] = unclaimedTokensByUser[_holder].add(_amount);
    }

    // function to claim all the tokens locked by user, after the locking period
    function claimAll(uint256 r) public {
        require(r>latestCounterByUser[msg.sender], "Increase right header, already claimed till this");
        require(r<=lockInfoByUser[msg.sender].length, "Decrease right header, it exceeds total length");
        LockInfo[] memory lockInfoArrayForUser = lockInfoByUser[msg.sender];
        uint256 totalTransferableAmount = 0;
        uint i;
        for (i=latestCounterByUser[msg.sender]; i<r; i++){
            uint256 lockingPeriodHere = lockingPeriod;
            if(lockInfoArrayForUser[i]._isDev){
                lockingPeriodHere = devLockingPeriod;
            }
            if(now >= (lockInfoArrayForUser[i]._timestamp.add(lockingPeriodHere))){
                totalTransferableAmount = totalTransferableAmount.add(lockInfoArrayForUser[i]._amount);
                unclaimedTokensByUser[msg.sender] = unclaimedTokensByUser[msg.sender].sub(lockInfoArrayForUser[i]._amount);
                latestCounterByUser[msg.sender] = i.add(1);
            } else {
                break;
            }
        }
        boneToken.transfer(msg.sender, totalTransferableAmount);

    }

    // function to get claimable amount for any user
    function getClaimableAmount(address _user) public view returns(uint256) {
        LockInfo[] memory lockInfoArrayForUser = lockInfoByUser[_user];
        uint256 totalTransferableAmount = 0;
        uint i;
        for (i=latestCounterByUser[_user]; i<lockInfoArrayForUser.length; i++){
            uint256 lockingPeriodHere = lockingPeriod;
            if(lockInfoArrayForUser[i]._isDev){
                lockingPeriodHere = devLockingPeriod;
            }
            if(now >= (lockInfoArrayForUser[i]._timestamp.add(lockingPeriodHere))){
                totalTransferableAmount = totalTransferableAmount.add(lockInfoArrayForUser[i]._amount);
            } else {
                break;
            }
        }
        return totalTransferableAmount;
    }

    // get the left and right headers for a user, left header is the index counter till which we have already iterated, right header is basically the length of user's lockInfo array
    function getLeftRightCounters(address _user) public view returns(uint256, uint256){
        return(latestCounterByUser[_user], lockInfoByUser[_user].length);
    }

    // in cases of emergency, emergency address can set this to true, which will enable emergencyWithdraw function
    function setEmergencyFlag(bool _emergencyFlag) public {
        require(msg.sender == emergencyAddress, "This function can only be called by emergencyAddress");
        emergencyFlag = _emergencyFlag;
    }

    // In emergency, users can withdraw all their locked tokens before locking period
    function emergencyWithdraw() public {
        require(emergencyFlag, "Cant withdraw, not an emergency, Chill");
        uint256 amount = unclaimedTokensByUser[msg.sender];
        unclaimedTokensByUser[msg.sender] = 0;
        boneToken.transfer(msg.sender, amount);
        latestCounterByUser[msg.sender] = lockInfoByUser[msg.sender].length;
    }

    // function for owner to transfer all tokens to another address
    function emergencyWithdrawOwner(address _to) public onlyOwner{
        uint256 amount = boneToken.balanceOf(address(this));
        require(boneToken.transfer(_to, amount), 'BoneLocker: Transfer failed.');
    }

    // emergency address can be updated from here
    function setEmergencyAddr(address _newAddr) public {
        require(msg.sender == emergencyAddress, "This function can only be called by emergencyAddress");
        emergencyAddress = _newAddr;
    }

    // function to update/change the normal & dev locking period
    function setLockingPeriod(uint256 _newLockingPeriod, uint256 _newDevLockingPeriod) public onlyOwner {
        lockingPeriod = _newLockingPeriod;
        devLockingPeriod = _newDevLockingPeriod;
    }
}