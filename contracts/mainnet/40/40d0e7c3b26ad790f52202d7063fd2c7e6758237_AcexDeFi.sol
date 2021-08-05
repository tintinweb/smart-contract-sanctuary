/**
 *Submitted for verification at Etherscan.io on 2020-05-14
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/GSN/Context.sol

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

// File: openzeppelin-solidity/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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

// File: openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// File: contracts/AcexDeFi.sol

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;




contract TetherToken {
    function transfer(address _to, uint _value) public {}
    function transferFrom(address _from, address _to, uint _value) public {}
}

library Lending {
    
    /*
     * 4 stages:
     * 
     * Funding Stage: Before "startTime"
     * Lending Stage: Between "startTime" and "startTime + duration"
     * Processing Stage: Between "startTime + duration" and "startTime + duration + 3 days"
     * Redeem Stage: After "startTime + duration + 3 days"
     *
     * --- Funding --- | --- Lending --- | --- Processing --- | --- Redeem ---
     *            startTime
     *                 |     duration    |       3 days       |
     *
     */
    
    struct Round {
        uint256 startTime;
        uint256 duration;
        uint256 apr; // in thousands (80 for 8%, 100 for 10%)
        uint256 softCap; // 5,000 USDT
        uint256 hardCap; // 1,000,000 USDT
        uint256 personalCap; // 2,000 USDT
        
        uint256 totalLendingAmount;
        bool withdrawn;
        bool disabled;
    }
    
    struct PersonalRound {
        Round round;
        
        uint256 lendingAmount;
        bool redeemed;
    }
}

contract AcexDeFi is
    Ownable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    
    address private _usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // Mainnet USDT
    TetherToken private _usdtContract = TetherToken(_usdtAddress);
    uint256 public _minAmount = 0;
    uint256 public _processPeriod = 3 days;
    
    Lending.Round[] private _rounds;
    mapping (uint256 => mapping (address => uint256)) private _lendingAmounts;
    mapping (uint256 => mapping (address => bool)) private _redeemed;
    
    event Lend (
        address indexed lender,
        uint256 amount,
        uint256 round
    );
    
    event Redeem (
        address indexed lender,
        uint256 amount,
        uint256 round
    );
    
    function addRound (
        uint256 startTime,
        uint256 duration,
        uint256 apr,
        uint256 softCap,
        uint256 hardCap,
        uint256 personalCap
    )
        public
        onlyOwner 
    {
        _rounds.push(Lending.Round(
            startTime,
            duration,
            apr,
            softCap,
            hardCap,
            personalCap,
            0,
            false,
            false
        ));
    }
    
    function ownerUpdateMinAmount(uint256 minAmount)
        public
        onlyOwner
    {
        _minAmount = minAmount;
    }
    
    function ownerUpdateProcessPeriod(uint256 processPeriod)
        public
        onlyOwner
    {
        _processPeriod = processPeriod;
    }
    
    function ownerWithdrawRound(uint256 index)
        public
        onlyOwner
    {
        Lending.Round storage round = _rounds[index];
        
        // Check round withdrawn
        require(!round.withdrawn, "ACEX DeFi: Round already withdrawn");
        
        // Check current time (after startTime)
        require(now > round.startTime, "ACEX DeFi: Cannot redeem in funding phase.");
        
        // Check soft cap
        require(round.totalLendingAmount >= round.softCap, "ACEX DeFi: Cannot redeem for failed round (lower than SoftCap).");
        
        round.withdrawn = true;
        _usdtContract.transfer(msg.sender, round.totalLendingAmount);
    }
    
    function ownerDisableRound(uint256 index)
        public
        onlyOwner
    {
        _rounds[index].disabled = true;
    }
    
    // Safety method in case user sends in ETH
    function ownerWithdrawAllETH()
        public
        onlyOwner
    {
        msg.sender.transfer(address(this).balance);
    }
    
    function getRounds()
        public
        view
        returns (Lending.Round[] memory rounds)
    {
        return _rounds;
    }
    
    function getPersonalRounds()
        public
        view
        returns (Lending.PersonalRound[] memory rounds)
    {
        rounds = new Lending.PersonalRound[](_rounds.length);
        
        for(uint i = 0; i < _rounds.length; i++) {
            rounds[i].round = _rounds[i];
            rounds[i].lendingAmount = _lendingAmounts[i][msg.sender];
            rounds[i].redeemed = _redeemed[i][msg.sender];
        }
        
        return rounds;
    }
    
    function lend (
        uint256 index,
        uint256 amount
    )
        public
        nonReentrant
    {
        Lending.Round storage round = _rounds[index];
        
        // Check if round is disabled
        require(!round.disabled, "ACEX DeFi: Round is disabled.");
        
        // Check current time (funding phase)
        require(now < round.startTime, "ACEX DeFi: Funding phase has passed.");
        
        // Check minimum amount
        require(amount > _minAmount, "ACEX DeFi: Amount too low");
        
        // Check personal cap
        uint256 personalLendingAmount = _lendingAmounts[index][msg.sender].add(amount);
        require(personalLendingAmount <= round.personalCap, "ACEX DeFi: Exceeds personal cap.");
        
        // Check hard cap
        uint256 totalLendingAmount = round.totalLendingAmount.add(amount);
        require(totalLendingAmount <= round.hardCap, "ACEX DeFi: Exceeds round hard cap.");
        
        _usdtContract.transferFrom(msg.sender, address(this), amount);
        _lendingAmounts[index][msg.sender] = personalLendingAmount;
        round.totalLendingAmount = totalLendingAmount;
        
        emit Lend(msg.sender, amount, index);
    }
    
    function redeem (
        uint256 index
    )
        public
        nonReentrant
    {
        Lending.Round storage round = _rounds[index];
        
        // Check if round is disabled
        require(!round.disabled, "ACEX DeFi: Round is disabled.");
        
        // Check current time (after startTime)
        require(now > round.startTime, "ACEX DeFi: Cannot redeem in funding phase.");
        
        // Check if user has redeemed
        require(!_redeemed[index][msg.sender], "ACEX DeFi: Already redeemed.");
        
        if (round.totalLendingAmount < round.softCap) {
            // Did not reach softCap, users can redeem after "startTime"
            
            // Pay back to user
            uint256 originalAmount = _lendingAmounts[index][msg.sender];
            
            _usdtContract.transfer(msg.sender, originalAmount);
            _redeemed[index][msg.sender] = true;
            emit Redeem(msg.sender, originalAmount, index);
        } else {
            // Reached softCap, users can redeem "amount + interest" after "startTime + duration + 3 days"
            
            // Check current time (redeem phase)
            require(now > round.startTime.add(round.duration).add(_processPeriod), "ACEX DeFi: Not redeem phase yet.");
            
            uint256 originalAmount = _lendingAmounts[index][msg.sender];
            
            // Interest = original * (apr * duration / 1 year in seconds)
            uint256 interestAmount = originalAmount.mul(round.apr).mul(round.duration).div(1000).div(365 days);
            uint256 totalAmount = originalAmount + interestAmount;
            
            _usdtContract.transfer(msg.sender, totalAmount);
            _redeemed[index][msg.sender] = true;
            emit Redeem(msg.sender, totalAmount, index);
        }
    }
}