/**
 *Submitted for verification at polygonscan.com on 2021-11-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Test scenario
// Claim 100% after TGE

contract Advisor is Ownable{
    using SafeMath for uint256;

    IERC20 public token;

    uint256 public TGE = 0;
    
    uint256 internal maxVolume = 0;
    uint256 internal currentVolume = 0;

    uint256 public lockingTime = 0;
    uint256 internal timePerRound = 0;
    uint256 public nextRoundTime = 0;

    uint8 internal totalRound=0;
    uint8 internal currentRound=0;

    bool internal isStarted = false;
    
    struct WhiteListInfo {
        uint256 amount;
        uint256 claimed;
        uint8 lastRoundClaim;
    }

    mapping(address => WhiteListInfo) whitelist;

    event AddToWhiteList(address indexed _address, uint256 indexed _value);
    event Claim(address indexed _address, uint256 indexed _value);
    event OwnerWithdraw(uint256 indexed _value);

    /** The unit of this function is hour 
     * 1 hour = 60 * 60 = 3600 seconds
     * 
    **/

    constructor(address _token) {
        token = IERC20(_token);
        maxVolume = 200000000000;
        TGE = 1637884800;

        timePerRound = 2*3600 ; // 2 hours
        lockingTime = TGE + 26*3600; // 26 hours

        nextRoundTime = lockingTime;
        totalRound = 12;
    }
    
    function start() public onlyOwner {
        require(block.timestamp < TGE,"Must be start before TGE");
        require(token.transferFrom(_msgSender(), address(this), maxVolume), "Transfer from sender to contract failed");
        isStarted = true;
    }
    
    function ownerWithdraw() public onlyOwner {
        require(isStarted, "Owner must be start first");
        require(block.timestamp >= TGE, "Withdraw time is after TGE");
        require(currentVolume < maxVolume, "Nothing to withdraw");
        require(token.transfer(_msgSender(), maxVolume - currentVolume), "Transfer from contract to sender failed");
        emit OwnerWithdraw(maxVolume - currentVolume);
    }

    function addToWhiteList(address _address, uint256 _value) public onlyOwner {
        require(isStarted, "Owner must be start first");
        require(block.timestamp < TGE, "Not in adding time");
        require(currentVolume + _value <= maxVolume, "Out of volume");

        whitelist[_address].amount = _value;
        whitelist[_address].lastRoundClaim = 0;
        whitelist[_address].claimed = 0;
        
        currentVolume += _value;

        emit AddToWhiteList(_address, _value);
    }

    function claim() public returns (bool){
        require(isStarted, "Owner must be start first");
        require(block.timestamp >= lockingTime, "Too early");
        require(whitelist[_msgSender()].lastRoundClaim < totalRound);
        require(whitelist[_msgSender()].amount > 0, "Nothing to claim");

        while (block.timestamp >= nextRoundTime && currentRound < totalRound) {
            currentRound++;
            if (currentRound != totalRound) nextRoundTime += timePerRound;
        }

        require(whitelist[_msgSender()].lastRoundClaim < currentRound);
        if (currentRound == totalRound){
            require(token.transfer(_msgSender(), whitelist[_msgSender()].amount - whitelist[_msgSender()].claimed),"Transfer Failed");
            whitelist[_msgSender()].lastRoundClaim = totalRound;
            whitelist[_msgSender()].claimed = whitelist[_msgSender()].amount;
            emit Claim(_msgSender(), whitelist[_msgSender()].amount - whitelist[_msgSender()].claimed);
        } else{
            uint256 nextValueClaimed = whitelist[_msgSender()].amount*currentRound/totalRound;
            uint256 sendValue = nextValueClaimed - whitelist[_msgSender()].claimed;
            require(token.transfer(_msgSender(), sendValue), "Transfer Failed");
            whitelist[_msgSender()].claimed =  whitelist[_msgSender()].claimed + sendValue;
            whitelist[_msgSender()].lastRoundClaim = currentRound;
            emit Claim(_msgSender(), sendValue);
        }
        return true;
    }
    
    function getVolume() public view returns (uint256 max_Volume, uint256 current_Volume) {
        return (maxVolume, currentVolume);
    }

    function getLockingAddress(address _address) public view returns (uint256 amount, uint8 lastRoundClaim, uint256 claimed) {
        return(whitelist[_address].amount, whitelist[_address].lastRoundClaim, whitelist[_address].claimed);
    }

}