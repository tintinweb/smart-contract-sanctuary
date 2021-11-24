/**
 *Submitted for verification at polygonscan.com on 2021-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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
    ) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract Seed is Ownable{
    using SafeMath for uint256;

    IERC20 public token;

    uint256 public TGE = 0;
    
    uint256 public maxVolume = 0;
    uint256 public currentVolume = 0;

    uint256 public nextRoundTime=0;
    uint256[] public validClaimTime;
    
    uint8 internal totalRound=0;
    uint8 internal currentRound=0;

    uint8[] public ratioAfterRound;
    
    struct WhiteListInfo {
        uint256 amount;
        uint256 claimed;
        uint8 lastRoundClaim;
    }

    mapping(address => WhiteListInfo) whitelist;

    /** The unit of this function is hour 
     * 1 hour = 60 * 60 = 3600 seconds
     * 
    **/

    constructor(address _token) {
        token = IERC20(_token);
        maxVolume = 1000000000000;
        TGE = 1637751600;

        validClaimTime.push(TGE); // TGE
        validClaimTime.push(TGE + 12*3600); // 12th hour
        validClaimTime.push(TGE + 24*3600); // 24th hour
        validClaimTime.push(TGE + 30*3600); // 30th hour
        validClaimTime.push(TGE + 36*3600); // 36th hour

        ratioAfterRound.push(0);
        ratioAfterRound.push(25);
        ratioAfterRound.push(50);
        ratioAfterRound.push(75);
        ratioAfterRound.push(100);

        nextRoundTime = validClaimTime[1];
        totalRound = 4;
    }
    
    function start() public onlyOwner {

        require(block.timestamp < TGE,"Must be start before TGE");
        token.transferFrom(_msgSender(), address(this), maxVolume);
    }
    
    function ownerWithdraw() public onlyOwner {
        require(currentVolume < maxVolume);
        token.transfer(_msgSender(), maxVolume - currentVolume);
    }

    function addToWhiteList(address _address, uint256 _value) public onlyOwner {
        require(block.timestamp < TGE);
        require(currentVolume + _value <= maxVolume);

        whitelist[_address].amount = _value;
        whitelist[_address].lastRoundClaim = 0;
        whitelist[_address].claimed = 0;
        
        currentVolume += _value;
    }

    function claim() public returns (bool){
        require(block.timestamp >= validClaimTime[1]);
        require(whitelist[_msgSender()].lastRoundClaim < totalRound);
        require(whitelist[_msgSender()].amount > 0);

        while (block.timestamp >= nextRoundTime && currentRound < totalRound) {
            currentRound++;
            if (currentRound != totalRound) nextRoundTime = validClaimTime[currentRound+1];
        }

        require(whitelist[_msgSender()].lastRoundClaim < currentRound);
        if (currentRound == totalRound){
            require(
            token.transfer(_msgSender(), whitelist[_msgSender()].amount - whitelist[_msgSender()].claimed));
            whitelist[_msgSender()].lastRoundClaim = totalRound;
            whitelist[_msgSender()].claimed = whitelist[_msgSender()].amount ;
        } else{
            uint256 sendValue = whitelist[_msgSender()].amount*ratioAfterRound[currentRound]/100 - whitelist[_msgSender()].claimed;
            require(token.transfer(_msgSender(), sendValue));
            whitelist[_msgSender()].claimed =  whitelist[_msgSender()].claimed + sendValue;
            whitelist[_msgSender()].lastRoundClaim = currentRound;
        }
        return true;
    }
    
    function getVolume() public view returns (uint256 max_Volume, uint256 current_Volume) {
        return (maxVolume, currentVolume);
    }

    function getLockingAddress(address _address) public view returns (uint256 amount, uint8 lastRoundClaim, uint256 claimed) {
        return(whitelist[_address].amount, whitelist[_address].lastRoundClaim, whitelist[_address].claimed);
    }
    
    function getValidClaimTime() public view returns (uint256[] memory){
        return validClaimTime;
    }
    
    function getTimePoint() public view returns (uint256 token_generation_event){
        return TGE;
    }

}