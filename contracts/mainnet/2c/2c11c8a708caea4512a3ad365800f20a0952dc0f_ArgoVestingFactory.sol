/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

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


/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract ArgoTokenVesting {
    using SafeMath for uint256;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // total balance of tokens sent to contract
    uint256 public totalBalance;
    // timestamp of release date and percent to be released
    struct VestPeriodInfo {
        uint256 releaseTime;
        uint256 percent;
        bool released;
    }
    // array of vesting period
    VestPeriodInfo[] public vestPeriodInfoArray;

    uint256 constant PRECISION = 10**25;
    uint256 constant PERCENT = 100 * PRECISION;

    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256[] memory releaseTimes_,
        uint256[] memory percents_,
        uint256 totalBalance_
    ) {
        // solhint-disable-next-line not-rely-on-time
        require(
            percents_.length == releaseTimes_.length,
            "ArgoTokenVesting: there should be equal percents and release times values"
        );
        require(
            beneficiary_ != address(0),
            "ArgoTokenVesting: beneficiary address should not be zero address"
        );
        require(
            address(token_) != address(0),
            "ArgoTokenVesting: token address should not be zero address"
        );

        _token = token_;
        for (uint256 i = 0; i < releaseTimes_.length; i++) {
            vestPeriodInfoArray.push(
                VestPeriodInfo({
                    percent: percents_[i],
                    releaseTime: releaseTimes_[i],
                    released: false
                })
            );
        }
        _beneficiary = beneficiary_;
        totalBalance = totalBalance_;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime(uint256 index) public view virtual returns (uint256) {
        return vestPeriodInfoArray[index].releaseTime;
    }

    /**
     * @return the percent of tokens to be released during a period.
     */
    function releasePercent(uint256 index)
        public
        view
        virtual
        returns (uint256)
    {
        return vestPeriodInfoArray[index].percent;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        // solhint-disable-next-line not-rely-on-time
        uint256 amount;
        for (uint256 i = 0; i < vestPeriodInfoArray.length; i++) {
            VestPeriodInfo memory vestPeriodInfo = vestPeriodInfoArray[i];
            if (vestPeriodInfo.releaseTime < block.timestamp) {
                if (!vestPeriodInfo.released) {
                    vestPeriodInfoArray[i].released = true;
                    amount = amount.add(
                        vestPeriodInfo
                            .percent
                            .mul(PRECISION)
                            .mul(totalBalance)
                            .div(PERCENT)
                    );
                }
            } else {
                break;
            }
        }
        require(amount > 0, "TokenTimelock: no tokens to release");
        token().transfer(_beneficiary, amount);
    }
}


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

contract ArgoVestingFactory is Ownable {
    event AddressWhitelisted(address indexed beneficiary);
    event VestingCreated(
        address indexed beneficiary,
        address indexed vestingAddress,
        uint256 amount
    );
    event EmergencyWithdraw(address owner, uint256 amount);

    // Argo Token Address
    address public argoToken;

    // Struct for white listed address
    struct WhiteListedAddressInfo {
        bool withdrawn;
        uint256 amount;
        address deployedVestingAddress;
    }
    //List of percent divisions
    uint256[] public percentList;

    // time difference epochs must be in same sequence as percent division, time will be calculated with current block time + timeDivsions [i]
    uint256[] public epochsToRelease;

    //mapping of address of their vesting contract with their address
    mapping(address => bool) public tokenVestingContractMappingStatus;

    //mapping of whiteListed users
    mapping(address => WhiteListedAddressInfo) public whiteListedAddressMapping;

    constructor(
        address _argoAddress,
        address[] memory _addressList,
        uint256[] memory _percentList,
        uint256[] memory _epochsToRelease,
        uint256[] memory _amountList
    ) {
        require(_percentList.length > 0, "No percent list provided");
        require(_addressList.length > 0, "No address List provided");
        require(
            _addressList.length == _amountList.length,
            "Address  and amount should be of equal length"
        );
        require(
            _epochsToRelease.length == _percentList.length,
            "Time and percent array length should be same"
        );

        percentList = _percentList;
        epochsToRelease = _epochsToRelease;
        for (uint256 i = 0; i < _addressList.length; i++) {
            tokenVestingContractMappingStatus[_addressList[i]] = true;
            whiteListedAddressMapping[_addressList[i]].amount = _amountList[i];
        }

        argoToken = _argoAddress;
    }

    function addAddressesToWhiteList(
        address[] memory _addressList,
        uint256[] memory _amountList
    ) public onlyOwner {
        require(
            _addressList.length == _amountList.length,
            "Address  and amount should be of equal length"
        );
        for (uint256 i = 0; i < _addressList.length; i++) {
            address _address = _addressList[i];

            if (!tokenVestingContractMappingStatus[_address]) {
                tokenVestingContractMappingStatus[_address] = true;
                whiteListedAddressMapping[_address].amount = _amountList[i];
            }

            emit AddressWhitelisted(_address);
        }
    }

    function removeAddressFromWhitelist(address _address) public onlyOwner {
        delete tokenVestingContractMappingStatus[_address];
        delete whiteListedAddressMapping[_address];
    }

    function createVesting() public {
        WhiteListedAddressInfo memory whiteListedAddressInfo =
            whiteListedAddressMapping[msg.sender];
        require(
            tokenVestingContractMappingStatus[msg.sender],
            "Address not whitelisted"
        );
        require(
            !whiteListedAddressInfo.withdrawn,
            "Amount already withdrawn by address"
        );
        require(
            whiteListedAddressInfo.amount > 0,
            "Withdraw amount is not set"
        );
        whiteListedAddressMapping[msg.sender].withdrawn = true;

        ArgoTokenVesting vesting =
            new ArgoTokenVesting(
                IERC20(argoToken),
                msg.sender,
                epochsToRelease,
                percentList,
                whiteListedAddressInfo.amount
            );
        whiteListedAddressMapping[msg.sender].deployedVestingAddress = address(
            vesting
        );
        IERC20(argoToken).transfer(
            address(vesting),
            whiteListedAddressInfo.amount
        );

        emit VestingCreated(
            msg.sender,
            address(vesting),
            whiteListedAddressInfo.amount
        );
    }

    function emergencyWithdraw(uint256 withdrawAmount) external onlyOwner {
        IERC20(argoToken).transfer(owner(), withdrawAmount);

        emit EmergencyWithdraw(owner(), withdrawAmount);
    }
}