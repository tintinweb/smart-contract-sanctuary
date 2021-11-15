pragma solidity 0.8.0;

import './DataStorage.sol';

contract Access is DataStorage {

  uint internal constant ENTRY_ENABLED = 1;
  uint internal constant ENTRY_DISABLED = 2;

  uint internal reentryStatus;

  modifier blockReEntry() {
    require(reentryStatus != ENTRY_DISABLED, "Security Block");
    reentryStatus = ENTRY_DISABLED;

    _;

    reentryStatus = ENTRY_ENABLED;
  }

  modifier hasStarted()
  {
      require(block.timestamp > _startTime, "Presale has not started yet");
      _;
  }
  
  modifier hasClosed()
  {
      require(block.timestamp < _endTime, "Presale has already finished");
      _;
  }

  modifier alreadyClosed()
  {
      require(block.timestamp > _endTime, "Presale is going on");
      _;
  }
  
  modifier hasTokens()
  {
      require (saleToken.balanceOf(address(this)) > 0 , "No tokens left");
      _;
  }
}

pragma solidity 0.8.0;
import "./IBEP20.sol";

contract DataStorage {

	uint256 public PROJECT_FEE = 0.01 ether;
	uint256 public TOTAL_SLOT = 10;

  	uint256 public wasSale;
	uint256 public priceToken = 0.00001 ether;
	uint256 public totalSupply= 100000000000000;
	uint256 public minInvest = 0.1 ether;
	uint256 public totalRegister;
	uint256 public totalClaim = 0;
	
	address payable public saleWallet;

	struct User {
		address owner;
		uint256 amountInvest;
		uint256 tokenBuy;
		bool wasClaimed;
	}

	mapping (address => User) internal users;
	mapping (address => uint256) tokenHolders;

	uint256 public _startTime;
  	uint256 public _endTime;
	IBEP20 saleToken;

}

pragma solidity 0.8.0;

contract Events {
  event FeePayed(address indexed user, uint256 totalAmount);
  event TokenPurchase(address indexed purchaser, uint256 value,uint256 amount);
}

pragma solidity 0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity 0.8.0;

contract Manageable {
    mapping(address => bool) public admins;
    constructor() public {
        admins[msg.sender] = true;
    }

    modifier onlyAdmins() {
        require(admins[msg.sender]);
        _;
    }

    function modifyAdmins(address[] memory newAdmins, address[] memory removedAdmins) public onlyAdmins {
        for(uint256 index; index < newAdmins.length; index++) {
            admins[newAdmins[index]] = true;
        }
        for(uint256 index; index < removedAdmins.length; index++) {
            admins[removedAdmins[index]] = false;
        }
    }
}

pragma solidity 0.8.0;
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.8.0;
import "./SafeMath.sol";
import "./DataStorage.sol";
import "./Access.sol";
import "./Events.sol";
import "./Manageable.sol";
import "./IBEP20.sol";

contract VeroLaunchpad is DataStorage, Access, Events, Manageable {
    using SafeMath for uint256;

    constructor(
        address payable wallet,
        IBEP20 _saleToken,
        uint256 startTime,
        uint256 endTime
    ) public {
        saleWallet = wallet;
        reentryStatus = ENTRY_ENABLED;
        saleToken = _saleToken;
        _startTime = startTime;
        _endTime = endTime;
    }

    fallback() external payable {
        _registerBuy(msg.sender);
    }

    receive() external payable {
        _registerBuy(msg.sender);
    }

    function registerBuy() public payable blockReEntry()
    {
       _registerBuy(msg.sender);
    }

    function _registerBuy(address _beneficiary) internal {
        User storage user = users[_beneficiary];
        require(user.tokenBuy == 0, "Required: Only one time register");
        uint256 weiAmount = msg.value.sub(PROJECT_FEE);
        require(
            weiAmount >= minInvest,
            "Requried: Amount to buy token not enough"
        );        
        require(
            wasSale <= totalSupply,
            "Requried: Token was sold all"
        );
        
        _preValidatePurchase(_beneficiary, weiAmount);
        totalRegister += 1;
        require(totalRegister <= TOTAL_SLOT, "Required: Not engough slot to register");
        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);
        tokenHolders[_beneficiary] = tokens;
        // update state
        wasSale = wasSale.add(tokens);
        user.owner = _beneficiary;
        user.amountInvest = user.amountInvest.add(msg.value.sub(PROJECT_FEE));
        user.tokenBuy = user.tokenBuy.add(tokens);
        user.wasClaimed = false;

        emit TokenPurchase(_beneficiary, weiAmount, tokens);
        emit FeePayed(_beneficiary, PROJECT_FEE);
    }

    function claimToken() public payable alreadyClosed hasTokens blockReEntry {
        User storage user = users[msg.sender];
        require(user.wasClaimed == false,"Required: Only one time claim token");
        require(user.tokenBuy > 0,"Required: Must be register to claim token");
        require(msg.value == PROJECT_FEE, "Required: Must be paid fee to claim token");
        user.wasClaimed = true;
        totalClaim = totalClaim.add(1);
        _deliverTokens(msg.sender, user.tokenBuy);
        emit FeePayed(msg.sender, PROJECT_FEE);
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        view
        hasStarted
        hasClosed
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        saleToken.transfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        return _weiAmount.div(priceToken).mul(1e6);
    }

    /**
     * @dev Determines how BNB is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        saleWallet.transfer(msg.value.sub(PROJECT_FEE));
    }

    function setMinInvestBNB(uint256 _amount) external onlyAdmins {
        minInvest = _amount;
    }    

    function setProjectFee(uint256 _fee) external onlyAdmins {
        PROJECT_FEE = _fee;
    }

     function setSlotRegister(uint256 _slot) external onlyAdmins {
        TOTAL_SLOT = _slot;
    }

    function setPriceToken(uint256 _totalSuply, uint256 _price)
        external
        onlyAdmins
    {
        priceToken = _price;
        totalSupply = _totalSuply;
    }

    function setStartTime(uint256 time) external onlyAdmins {
        _startTime = time;
    }

    function setEndTime(uint256 time) external onlyAdmins {
        _endTime = time;
    }

    function setSaleWallet(address payable _saleAddress) external onlyAdmins {
        saleWallet = _saleAddress;
    }

    function handleForfeitedBalanceToken(address payable _addr, uint256 _amount)
        external
    {
        require((msg.sender == saleWallet), "Restricted Access!");

        saleToken.transfer(_addr, _amount);
    }

    function handleForfeitedBalance(address payable _addr, uint256 _amount)
        external
    {
        require((msg.sender == saleWallet), "Restricted Access!");

        (bool success, ) = _addr.call{value: _amount}("");

        require(success, "Failed");
    }

    function getUserInfo(address userAddress)
        public
        view
        returns (User memory)
    {
        User storage user = users[userAddress];        
        return user;
    }
}

