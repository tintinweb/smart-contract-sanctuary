pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface IMonsterToken{
    function mintNomics(address _addr, uint256 _amount) external;
    function burn(address _addr, uint256 _amount) external;
}
contract MonsterTokenomics is Ownable {
    using SafeMath for uint256;

    IMonsterToken public token;
    uint256 public startDate;

    uint256 constant public MAX_SUPPLY = 1000 * 10**6 * 10**18;

    uint256 public PUBLICSALE_ALLOCATION = MAX_SUPPLY.mul(20).div(100); // 20%
    uint256 public TGE_PUBLICSALE = PUBLICSALE_ALLOCATION;

    uint256 public PRIVATESALE_ALLOCATION = MAX_SUPPLY.mul(10).div(100); // 10%
    uint256 public DEV_ALLOCATION = MAX_SUPPLY.mul(5).div(100);         // 5%
    uint256 public AIRDROP_ALLOCATION = MAX_SUPPLY.mul(5).div(100);     // 5%
    uint256 public LP_ALLOCATION = MAX_SUPPLY.mul(20).div(100);         // 20%
    uint256 public LOCK_UNICRYPT_ALLOCATION = MAX_SUPPLY.mul(5).div(100);         // 5%

    uint256 public WEEK = 1 weeks;
    uint256 public MONTH_LOCK = WEEK * 4;
    uint256 public PRIVATE_DURATION = WEEK * 4 * 10;
    uint256 public PRIVATE_REMAINING = PRIVATESALE_ALLOCATION.mul(85).div(100);
    uint256 public PRIVATE_WEEK_MINT = PRIVATE_REMAINING.mul(WEEK).div(PRIVATE_DURATION);
    uint256 public PRIVATE_NEXT_UNLOCK;

    uint256 public DEV_LOCK = 365 days * 3;
    uint256 public DEV_DURATION = WEEK * 52;
    uint256 public DEV_WEEK_MINT = DEV_ALLOCATION.mul(WEEK).div(DEV_DURATION);
    uint256 public DEV_NEXT_UNLOCK;
    uint256 public DEV_PAID = 0;

    address public bossAddress;

    uint256 public AIRDROP_REMAINING = AIRDROP_ALLOCATION;

    uint256 public TGE_UNICRYPT = LOCK_UNICRYPT_ALLOCATION;
    uint256 public TGE_PRIVATESALE = PRIVATESALE_ALLOCATION.mul(15).div(100);
    uint256 public TGE_LP_PROVIDER = LP_ALLOCATION;

    event SetBossAddress(address addr);
    event DistributionPrivateSale(address addr, uint256 amount);
    event DistributionDevBoss(address addr, uint256 amount);
    event DistributionAirdrop(address addr, uint256 amount);

    constructor() {
        startDate = block.timestamp;
        PRIVATE_NEXT_UNLOCK = block.timestamp;
        DEV_NEXT_UNLOCK = startDate + DEV_LOCK + WEEK;
        bossAddress = msg.sender;
    }

    function initToken(address _token) public{
        require(address(token) == address(0), "revert init");
        token = IMonsterToken(_token);
    }

    function setAddressBoss(address _addr) public onlyOwner{
        bossAddress = _addr;
        emit SetBossAddress(bossAddress);
    }

    function tgeUnicrypt() public onlyOwner {
        require(TGE_UNICRYPT > 0, "TGE Unicrypt minted");
        token.mintNomics(_msgSender(), TGE_UNICRYPT);
        TGE_UNICRYPT = 0;
    }

    function tgePrivateSale() public onlyOwner {
        require(TGE_PRIVATESALE > 0, "TGE Private Sale minted");
        token.mintNomics(_msgSender(), TGE_PRIVATESALE);
        TGE_PRIVATESALE = 0;
    }

    function tgeLPprovider() public onlyOwner {
        require(TGE_LP_PROVIDER > 0, "TGE LP Provider minted");

        token.mintNomics(_msgSender(), TGE_LP_PROVIDER);
        TGE_LP_PROVIDER = 0;
    }

    function publicUnlock() public onlyOwner {
        require(TGE_PUBLICSALE > 0, "TGE PublicSale minted");

        token.mintNomics(_msgSender(), TGE_PUBLICSALE);
        TGE_PUBLICSALE = 0;
    }

    function privateUnlock() public onlyOwner {
        require(startDate + MONTH_LOCK <= block.timestamp, "lock time");
        require(PRIVATE_NEXT_UNLOCK <= block.timestamp, "not time yet");
        require(PRIVATE_REMAINING>0, "End, insufficient amount");
        PRIVATE_REMAINING = PRIVATE_REMAINING.sub(PRIVATE_WEEK_MINT);
        PRIVATE_NEXT_UNLOCK = PRIVATE_NEXT_UNLOCK.add(WEEK);
        token.mintNomics(_msgSender(), PRIVATE_WEEK_MINT);
        emit DistributionPrivateSale(_msgSender(), PRIVATE_WEEK_MINT);
    }

    function devUnlock() public onlyOwner {
        require(startDate + DEV_LOCK <= block.timestamp, "cliff time");
        require(DEV_NEXT_UNLOCK <= block.timestamp, "not time yet");
        require(DEV_ALLOCATION - DEV_PAID > 0, "End, insufficient amount");
    

        DEV_NEXT_UNLOCK = DEV_NEXT_UNLOCK.add(WEEK);
        uint256 amount;
        if(DEV_ALLOCATION.sub(DEV_PAID) >= DEV_WEEK_MINT*2){
            amount = DEV_WEEK_MINT;
            DEV_PAID = DEV_PAID.add(DEV_WEEK_MINT);
        } else{
            amount = DEV_ALLOCATION.sub(DEV_PAID);
            DEV_PAID = DEV_ALLOCATION;
        }
        token.mintNomics(bossAddress, amount);
        emit DistributionDevBoss(bossAddress, amount);
    }

    function airdropUnlock(address _addr, uint256 _amount) public onlyOwner {
        require(AIRDROP_REMAINING > _amount, "amount error");
        require(AIRDROP_REMAINING > 0, "insufficient amount");

        AIRDROP_REMAINING = AIRDROP_REMAINING.sub(_amount);
        token.mintNomics(_addr, _amount);
        emit DistributionAirdrop(_addr, _amount);
    }
}

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

