/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

// SPDX-License-Identifier: MIT
// File: Locker/SafeMath.sol



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

// File: Locker/Context.sol



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

// File: Locker/Ownable.sol



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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Locker/IERC20.sol


pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: Locker/Locker.sol


pragma solidity ^0.8.0;

// import "./IPancakePair.sol";




contract PICNICLocker is Ownable {

    using SafeMath for uint;
    uint public lockerCount;    

    uint public lockFee = 0.1 ether;
    uint public updateLokcerFee = 0.05 ether;

    mapping(uint => Loker)  public loker;
    mapping(address => uint[])  lockersListByTokenAddress;
    mapping(address => uint[])  lockersListByUserAddress;

    enum Status {LOCKED, WITHDRAWED}
    enum Type {TOKEN, LPTOKEN}

    struct Loker {
        uint id;
        Type _type;
        address owner; 
        address tokenAddress;
        uint numOfTokens;
        uint lockTime;
        uint unlockTime;
        Status status;
    }

    event Locked (uint id, address owner, address token, uint numOfTokens, uint unlockTime);
    event Unlocked (uint id, address owner, address token, uint numOfTokens);

    modifier OnlyLockerOnwer(uint _id) {
        require(loker[_id].owner == _msgSender(), "Only locker onwer is allowed."); 
        _;
    }

    modifier NotExpired(uint _id) {
        require(block.timestamp < loker[_id].unlockTime, "Not unlocked yet.");
        _;
    }

    modifier Expired(uint _id) {
        require(block.timestamp >= loker[_id].unlockTime, "The locker has been expired.");
        _;
    }


    function lockTokens(Type _type, address _token, uint _numOfTokens, uint _unlockTime) payable public {
        require(msg.value >= lockFee, "Please pay the fee");
        require(_unlockTime > block.timestamp, "The unlock time should in future");

        IERC20(_token).transferFrom(_msgSender(), address(this), _numOfTokens);

        // if(_type == Type.TOKEN){
        // }
        // else if(_type == Type.LPTOKEN){
        //     IPancakePair(_token).transferFrom(_msgSender(), address(this), _numOfTokens);
        // }

        lockerCount++;

        loker[lockerCount] = Loker(
            lockerCount,
            _type,
            _msgSender(),
            _token,
            _numOfTokens,
            block.timestamp,
            _unlockTime,
            Status.LOCKED
        );

        lockersListByUserAddress[_msgSender()].push(lockerCount);
        lockersListByTokenAddress[_token].push(lockerCount);

        emit Locked (lockerCount, _msgSender(), _token, _numOfTokens, _unlockTime );

    }

    function unlockTokens(uint _id, uint _numOfTokens) public OnlyLockerOnwer(_id) Expired(_id) {

        Loker memory lokerData = loker[_id];
        require(lokerData.numOfTokens >= _numOfTokens, "Not enough tokens to withdraw");

        IERC20(lokerData.tokenAddress).transfer(_msgSender(), _numOfTokens);
        // if(lokerData._type == Type.TOKEN){
        // }
        // else if(lokerData._type == Type.LPTOKEN){
        //     IPancakePair(lokerData.tokenAddress).transfer(_msgSender(), _numOfTokens);
        // }

        loker[_id].numOfTokens = lokerData.numOfTokens.sub(_numOfTokens);   

        if(loker[_id].numOfTokens == 0 ){
            loker[_id].status = Status.WITHDRAWED;
        }

        emit Unlocked (_id, _msgSender(), lokerData.tokenAddress, _numOfTokens);

    }

    function addTokenstoALocker(uint _id, uint _numOfTokens) payable public OnlyLockerOnwer(_id) NotExpired(_id) {

        require(msg.value >= updateLokcerFee, "Please pay the updating fee");
        require(_numOfTokens > 0, "Tokens should be more than zero");
        // require(loker[_id].status != Status.WITHDRAWED, "NO more tokens present. Kindly start anothre locker");

        IERC20(loker[_id].tokenAddress).transferFrom(_msgSender(), address(this), _numOfTokens);

        // if(loker[_id]._type == Type.TOKEN){
        // }
        // else if(loker[_id]._type == Type.LPTOKEN){
        //     IPancakePair(loker[_id].tokenAddress).transferFrom(_msgSender(), address(this), _numOfTokens);
        // }

        loker[_id].numOfTokens = loker[_id].numOfTokens.add(_numOfTokens);

    }

    function increaseLocktime(uint _id, uint _additionTime) payable public OnlyLockerOnwer(_id) NotExpired(_id) {

        require(msg.value >= updateLokcerFee, "please pay the updating fee");
        require(_additionTime > 0, "Addition time should be more than zero");
        // require(loker[_id].status != Status.WITHDRAWED, "NO more tokens present. Kindly start anothre locker");

        loker[_id].unlockTime = loker[_id].unlockTime.add(_additionTime);

    }

    function getLockersListbyUser(address _userAddress) public view returns (uint[] memory) {
        return lockersListByUserAddress[_userAddress];
    }

    function getLockersListbyToken(address _tokenAddress) public view returns (uint[] memory) {
        return lockersListByTokenAddress[_tokenAddress];
    }

    function updateFees(uint _lockFee, uint _updatingFee) public onlyOwner {
        lockFee = _lockFee;
        updateLokcerFee = _updatingFee;
    }

    function withdrawFunds() public onlyOwner {
        uint balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }
}