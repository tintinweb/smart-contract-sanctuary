pragma solidity ^0.5.17;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
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
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
interface ERC20Basic {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 Advanced interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20Advanced {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title ERC20Standard
 * @dev Full ERC20 interface
 */
contract ERC20Standard is ERC20Basic, ERC20Advanced {}

contract TokenDistribution is Ownable {
    using SafeMath for uint256;

    /*                                               GENERAL VARIABLES                                                */
    /* ============================================================================================================== */

    ERC20Standard public token;                         // ERC20Token contract variable

    uint256 constant internal base18 = 1000000000000000000;

    uint256 public standardRate;

    uint256 public percentBonus;                        // Percentage Bonus
    uint256 public withdrawDate;                        // Withdraw Date
    uint256 public totalNumberOfInvestments;            // total number of investments
    uint256 public totalEtherInvested;                  // total amount of ethers invested from all investments

    // details of an Investment
    struct Investment {
        address investAddr;
        uint256 ethAmount;
        bool hasClaimed;
        uint256 principalClaimed;
        uint256 bonusClaimed;
        uint256 claimTime;
    }

    // mapping investment number to the details of the investment
    mapping(uint256 => Investment) public investments;

    // mapping investment address to the investment ID of all the investments made by this address
    mapping(address => uint256[]) public investmentIDs;

    uint256 private unlocked;

    /*                                                   MODIFIERS                                                    */
    /* ============================================================================================================== */
    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }          

    /*                                                   INITIALIZER                                                  */
    /* ============================================================================================================== */
    function initialize
    (
        address[] calldata _investors,
        uint256[] calldata _ethAmounts,
        ERC20Standard _erc20Token,
        uint256 _withdrawDate,
        uint256 _standardRate,
        uint256 _percentBonus
    )
        external initializer
    {
        Ownable.initialize(_msgSender());

        // set investments
        addInvestments(_investors, _ethAmounts);
        // set ERC20Token contract variable
        setERC20Token(_erc20Token);

        // Set withdraw date
        withdrawDate = _withdrawDate;

        standardRate = _standardRate;

        // Set percentage bonus
        percentBonus = _percentBonus;

        //Reentrancy lock
        unlocked = 1;
    }

    /*                                                      EVENTS                                                    */
    /* ============================================================================================================== */
    event WithDrawn(
        address indexed investor,
        uint256 indexed investmentID,
        uint256 principal,
        uint256 bonus,
        uint256 withdrawTime
    );

    /*                                                 YIELD FARMING FUNCTIONS                                        */
    /* ============================================================================================================== */

    /**
     * @notice Withdraw tokens
     * @param investmentID uint256 investment ID of the investment for which the bonus tokens are distributed
     * @return bool true if the withdraw is successful
     */
    function withdraw(uint256 investmentID) external lock returns (bool) {
        require(investments[investmentID].investAddr == msg.sender, "You are not the investor of this investment");
        require(block.timestamp >= withdrawDate, "Can only withdraw after withdraw date");
        require(!investments[investmentID].hasClaimed, "Tokens already withdrawn for this investment");
        require(investments[investmentID].ethAmount > 0, "0 ether in this investment");

        // get the ether amount of this investment
        uint256 _ethAmount = investments[investmentID].ethAmount;

        (uint256 _principal, uint256 _bonus, uint256 _principalAndBonus) = calculatePrincipalAndBonus(_ethAmount);

        _updateWithdraw(investmentID, _principal, _bonus);

        // transfer tokens to this investor
        require(token.transfer(msg.sender, _principalAndBonus), "Fail to transfer tokens");

        emit WithDrawn(msg.sender, investmentID, _principal, _bonus, block.timestamp);
        return true;
    }

    /*                                                 SETTER FUNCTIONS                                               */
    /* ============================================================================================================== */
    /**
     * @dev Add new investments
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function addInvestments(address[] memory _investors, uint256[] memory _ethAmounts) public onlyOwner {
        require(_investors.length == _ethAmounts.length, "The number of investing addresses should equal the number of ether amounts");
        for (uint256 i = 0; i < _investors.length; i++) {
             addInvestment(_investors[i], _ethAmounts[i]); 
        }
    }

    /**
     * @dev Set ERC20Token contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setERC20Token(ERC20Standard _erc20Token) public onlyOwner {
        token = _erc20Token; 
    }

    /**
     * @dev Set percentage bonus. Percentage bonus is amplified 10**8 times for float precision
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setPercentBonus(uint256 _percentBonus) public onlyOwner {
        percentBonus = _percentBonus; 
    }

    /**
     * @notice This function transfers tokens out of this contract to a new address
     * @dev This function is used to transfer unclaimed KittieFightToken to a new address,
     *      or transfer other tokens erroneously tranferred to this contract back to their original owner
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function returnTokens(address _token, uint256 _amount, address _newAddress) external onlyOwner {
        require(block.timestamp >= withdrawDate.add(7 * 24 * 60 * 60), "Cannot return any token within 7 days of withdraw date");
        uint256 balance = ERC20Standard(_token).balanceOf(address(this));
        require(_amount <= balance, "Exceeds balance");
        require(ERC20Standard(_token).transfer(_newAddress, _amount), "Fail to transfer tokens");
    }

    /**
     * @notice Set withdraw date for the token
     * @param _withdrawDate uint256 withdraw date for the token
     * @dev    This function can only be carreid out by the owner of this contract.
     */
    function setWithdrawDate(uint256 _withdrawDate) public onlyOwner {
        withdrawDate = _withdrawDate;
    }

    /*                                                 GETTER FUNCTIONS                                               */
    /* ============================================================================================================== */
    
    /**
     * @return true and 0 if it is time to withdraw, false and time until withdraw if it is not the time to withdraw yet
     */
    function canWithdraw() public view returns (bool, uint256) {
        if (block.timestamp >= withdrawDate) {
            return (true, 0);
        } else {
            return (false, withdrawDate.sub(block.timestamp));
        }
    }

    /**
     * @return uint256 bonus tokens calculated for the amount of ether specified
     */
    function calculatePrincipalAndBonus(uint256 _ether)
        public view returns (uint256, uint256, uint256)
    {
        uint256 principal = _ether.mul(standardRate).div(base18);
        uint256 bonus = principal.mul(percentBonus).div(base18);
        uint256 principalAndBonus = principal.add(bonus);
        return (principal, bonus, principalAndBonus);
    }

    /**
     * @return address an array of the ID of each investment belonging to the investor
     */
    function getInvestmentIDs(address _investAddr) external view returns (uint256[] memory) {
        return investmentIDs[_investAddr];
    }

    /**
     * @return the details of an investment associated with an investment ID, including the address 
     *         of the investor, the amount of ether invested in this investment, whether bonus tokens
     *         have been claimed for this investment, the amount of bonus tokens already claimed for
     *         this investment(0 if bonus tokens are not claimed yet), the unix time when the bonus tokens
     *         have been claimed(0 if bonus tokens are not claimed yet)
     */
    function getInvestment(uint256 _investmentID) external view
        returns(address _investAddr, uint256 _ethAmount, bool _hasClaimed,
                uint256 _principalClaimed, uint256 _bonusClaimed, uint256 _claimTime)
    {
        _investAddr = investments[_investmentID].investAddr;
        _ethAmount = investments[_investmentID].ethAmount;
        _hasClaimed = investments[_investmentID].hasClaimed;
        _principalClaimed = investments[_investmentID].principalClaimed;
        _bonusClaimed = investments[_investmentID].bonusClaimed;
        _claimTime = investments[_investmentID].claimTime;
    }
    

    /*                                                 PRIVATE FUNCTIONS                                             */
    /* ============================================================================================================== */
    /**
     * @param _investmentID uint256 investment ID of the investment for which tokens are withdrawn
     * @param _bonus uint256 tokens distributed to this investor
     * @dev this function updates the storage upon successful withdraw of tokens.
     */
    function _updateWithdraw(uint256 _investmentID, uint256 _principal, uint256 _bonus) 
        private
    {
        investments[_investmentID].hasClaimed = true;
        investments[_investmentID].principalClaimed = _principal;
        investments[_investmentID].bonusClaimed = _bonus;
        investments[_investmentID].claimTime = block.timestamp;
        investments[_investmentID].ethAmount = 0;
    }

    /**
     * @dev Add one new investment
     */
    function addInvestment(address _investor, uint256 _eth) private {
        uint256 investmentID = totalNumberOfInvestments.add(1);
        investments[investmentID].investAddr = _investor;
        investments[investmentID].ethAmount = _eth;
   
        totalEtherInvested = totalEtherInvested.add(_eth);
        totalNumberOfInvestments = investmentID;

        investmentIDs[_investor].push(investmentID);
    }
}