// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.2;

/*
    TENSET IS THE BEST !!!
    DIAMOND HANDS
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Package.sol";
import "./RetrieveTokensFeature.sol";

contract InfinityDeposit is RetrieveTokensFeature, Package {
    using SafeMath for uint256;

    IERC20 public Tenset;
    struct Deposit {
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        uint256 idxPackage;
        bool    withdrawn;
    }

    uint256 public depositId;
    uint256[] public allDepositIds;
    uint256 public totalUsersBalance;

    mapping (address => uint256[]) public depositsByWithdrawalAddress;
    mapping (uint256 => Deposit) public lockedToken;
    mapping(address => uint256) public walletTokenBalance;

    event LogWithdrawal(uint256 Id, uint256 IndexPackage, address WithdrawalAddress, uint256 Amount);
    event LogDeposit(uint256 Id, uint256 IndexPackage, address WithdrawalAddress, uint256 Amount, uint256 BonusAmount, uint256 UnlockTime);
    event LogExtend(uint256 Id, uint256 IndexPackage, address WithdrawalAddress, uint256 UnlockTime);

    constructor(address addrToken) public {
        Tenset = IERC20(addrToken);
    }

    function makeDeposit(address _withdrawalAddress, uint256 _idxPackage, uint256 _amount) public canBuy(_idxPackage, _amount) returns(uint256 _id) {
        //update balance in address
        uint256 tensetFixedBalance = _amount.sub(_decreaseAmountFee(_amount));

        walletTokenBalance[_withdrawalAddress] = walletTokenBalance[_withdrawalAddress].add(tensetFixedBalance);
        totalUsersBalance += tensetFixedBalance;

        _id = ++depositId;
        lockedToken[_id].withdrawalAddress = _withdrawalAddress;
        lockedToken[_id].tokenAmount = tensetFixedBalance;
        lockedToken[_id].unlockTime = _deltaTimestamp(_idxPackage);
        lockedToken[_id].idxPackage = _idxPackage;
        lockedToken[_id].withdrawn = false;

        allDepositIds.push(_id);
        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);

        // transfer tokens into contract
        require(Tenset.transferFrom(msg.sender, address(this), _amount));
        // Count bonus from package without decrease fee
        uint256 WithBonusAmount = tensetFixedBalance.mul(availablePackage[_idxPackage].dailyPercentage).div(100).add(tensetFixedBalance);
        emit LogDeposit(_id, _idxPackage, _withdrawalAddress, tensetFixedBalance, WithBonusAmount, lockedToken[_id].unlockTime);
    }

    /**
     *Extend lock Duration
    */
    function extendLockDuration(uint256 _id) public {
        require(!lockedToken[_id].withdrawn);
        require(msg.sender == lockedToken[_id].withdrawalAddress);
        require(activePackage(lockedToken[_id].idxPackage), "Package is not active");

        //set new unlock time
        lockedToken[_id].unlockTime = _deltaTimestamp(lockedToken[_id].idxPackage);
        emit LogExtend(_id, lockedToken[_id].idxPackage, lockedToken[_id].withdrawalAddress, lockedToken[_id].unlockTime);
    }

    /**
     *withdraw tokens
    */
    function withdrawTokens(uint256 _id) public {
        require(block.timestamp >= lockedToken[_id].unlockTime);
        require(msg.sender == lockedToken[_id].withdrawalAddress);
        require(!lockedToken[_id].withdrawn);

        lockedToken[_id].withdrawn = true;
        uint256 _idPackage = lockedToken[_id].idxPackage;
        //update balance in address
        walletTokenBalance[msg.sender] = walletTokenBalance[msg.sender].sub(lockedToken[_id].tokenAmount);
        totalUsersBalance -= lockedToken[_id].tokenAmount;

        //remove this id from this address
        uint256 j;
        uint256 arrLength = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length;

        for (j=0; j<arrLength; j++) {
            if (depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] == _id) {
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][arrLength - 1];
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].pop();
                break;
            }
        }

        // transfer tokens to wallet address
        require(Tenset.transfer(msg.sender, lockedToken[_id].tokenAmount));
        emit LogWithdrawal(_id, _idPackage, msg.sender, lockedToken[_id].tokenAmount);
    }

    function getTotalTokenBalance() view public returns (uint256) {
        return Tenset.balanceOf(address(this));
    }

    /*get total token balance by address*/
    function getTokenBalanceByAddress(address _walletAddress) view public returns (uint256) {
        return walletTokenBalance[_walletAddress];
    }

    /*get allDepositIds*/
    function getAllDepositIds() view public returns (uint256[] memory) {
        return allDepositIds;
    }

    /*get getDepositDetails*/
    function getDepositDetails(uint256 _id) view public returns (uint256 package, address _withdrawalAddress, uint256 _tokenAmount, uint256 _unlockTime, bool _withdrawn) {
        return(lockedToken[_id].idxPackage, lockedToken[_id].withdrawalAddress, lockedToken[_id].tokenAmount, lockedToken[_id].unlockTime,lockedToken[_id].withdrawn);
    }

    /*get DepositsByWithdrawalAddress*/
    function getDepositsByWithdrawalAddress(address _withdrawalAddress) view public returns (uint256[] memory) {
        return depositsByWithdrawalAddress[_withdrawalAddress];
    }

    function retrieveTokensFromStaking(address to) public onlyOwner() {
        RetrieveTokensFeature.retrieveTokens(to, address(Tenset), getStakingPool());
    }

    function getStakingPool() public view returns(uint256 _pool) {
        _pool = getTotalTokenBalance().sub(totalUsersBalance);
    }
}

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Package is Ownable {
    using SafeMath for uint256;

    function _decreaseAmountFee(uint256 _oldAmount) internal pure returns(uint256 _newAmount) {
        uint256 scaledFee = 2;
        uint256 scalledPercentage = 100;
        return _oldAmount.mul(scaledFee).div(scalledPercentage);
    }

    modifier canBuy(uint256 _idxPackage, uint256 _amount) {
        require(_idxPackage < availablePackage.length, "Index out of range");
        require(_amount > 0);
        require(availablePackage.length >= _idxPackage, "Package doesn't exists");
        require(availablePackage[_idxPackage].active, "Package is not active ");
        require(_amount.sub(_decreaseAmountFee(_amount)) > availablePackage[_idxPackage].minTokenAmount, "Amount is too small");
            _;
    }

    struct PackageItem {
        string  aliasName;
        uint256 daysLock;
        uint256 minTokenAmount;
        uint256 dailyPercentage;
        bool    active;
    }
    PackageItem[] public availablePackage;

    function showPackageDetail(uint16 _index) public view returns(string memory, uint256, uint256, uint256, bool) {
        require(_index < availablePackage.length, "Index out of range");
        return (
            availablePackage[_index].aliasName,
            availablePackage[_index].daysLock,
            availablePackage[_index].minTokenAmount,
            availablePackage[_index].dailyPercentage,
            availablePackage[_index].active
        );
    }

    function pushPackageDetail(
        string memory _aliasName,
        uint256 _daysLock,
        uint256 _minTokenAmount,
        uint256 _dailyPercentage
    ) public onlyOwner {
        PackageItem memory pkg = PackageItem({
            aliasName: _aliasName,
            daysLock: _daysLock,
            minTokenAmount: _minTokenAmount,
            dailyPercentage: _dailyPercentage,
            active: true
        });
        availablePackage.push(pkg);
    }

    function getLengthPackage() public view returns(uint256) {
        return availablePackage.length;
    }

    function _deltaTimestamp(uint256 _idxPackage) internal view returns(uint) {
        return availablePackage[_idxPackage].daysLock * 1 days + now;
    }

    function setActive(uint256 _idxPackage, bool _active) public onlyOwner {
        require(_idxPackage < availablePackage.length, "Index out of range");
        availablePackage[_idxPackage].active = _active;
    }

    function activePackage(uint _idxPackage) internal view returns(bool) {
        return availablePackage[_idxPackage].active;
    }
}

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RetrieveTokensFeature is Context, Ownable {

    function retrieveTokens(address to, address anotherToken, uint256 amount) virtual public onlyOwner() {
        IERC20 alienToken = IERC20(anotherToken);
        alienToken.transfer(to, amount);
    }

    function retriveETH(address payable to) virtual public onlyOwner() {
        to.transfer(address(this).balance);
    }

}

