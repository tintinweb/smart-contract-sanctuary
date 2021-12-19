// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import './DataStorageCow.sol';

contract Access is DataStorageCow {

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
import "./IBEP20.sol";

contract DataStorageCow {

	uint256 public PROJECT_FEE = 0 ether;
	uint256 public CLAIM_FEE = 0.001 ether;
	uint256 public TOTAL_SLOT = 2500;

  	uint256 public wasSale;
	uint256 public quantityToken = 142857142900000000000;
	uint256 public totalSupply= 357142857250000000000000;
	uint256 public minInvest = 20*10**18;
	uint256 public maxInvest = 20*10**18;
	uint256 public totalRegister;
	uint256 public totalClaim = 0;
	uint256 public TIME_STEP = 30 days;
	uint256 public LIMIT_CLAIMED = 4;
	
	address payable public saleWallet;

	struct User {
		address owner;
		uint256 amountInvest;
		uint256 tokenBuy;
		uint256 countClaimed;
		uint256 lastClaimed;
        uint256 amountClaimed;
	}

	mapping (address => User) internal users;
	mapping (address => uint256) tokenHolders;

	uint256 public _startTime;
  	uint256 public _endTime;
	IBEP20 public saleToken;
	IBEP20 public buyToken;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Events {
  event FeePayed(address indexed user, uint256 totalAmount);
  event TokenPurchase(address indexed purchaser, uint256 value,uint256 amount);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
import "./SafeMath.sol";
import "./DataStorageCow.sol";
import "./Access.sol";
import "./Events.sol";
import "./IBEP20.sol";
import "./Ownable.sol";

contract Launchpad is Ownable, DataStorageCow, Access, Events {
    using SafeMath for uint256;

    constructor(
        address payable wallet,
        IBEP20 _saleToken,
        IBEP20 _buyToken,
        uint256 startTime,
        uint256 endTime
    ) public {
        saleWallet = wallet;
        reentryStatus = ENTRY_ENABLED;
        saleToken = _saleToken;
        buyToken = _buyToken;
        _startTime = startTime;
        _endTime = endTime;
    }

    function registerBuy(uint256 amount) public payable blockReEntry {
        _registerBuy(msg.sender, amount);
    }

    function _registerBuy(address _beneficiary, uint256 amount) internal {
        User storage user = users[_beneficiary];
        require(user.tokenBuy == 0, "Required: Only one time register");
        require(
            msg.value == PROJECT_FEE,
            "Required: Must be paid fee to register"
        );
        require(
            buyToken.allowance(_beneficiary, address(this)) >= amount,
            "Token allowance too low"
        );
        uint256 weiAmount = amount;
        require(
            weiAmount >= minInvest,
            "Requried: Amount to buy token not enough"
        );
        require(
            weiAmount <= maxInvest,
            "Requried: Amount to buy token too much"
        );
        require(wasSale <= totalSupply, "Requried: Token was sold all");

        _preValidatePurchase(_beneficiary, weiAmount);
        totalRegister += 1;
        require(
            totalRegister <= TOTAL_SLOT,
            "Required: Not engough slot to register"
        );
        tokenHolders[_beneficiary] = quantityToken;
        // update state
        wasSale = wasSale.add(quantityToken);
        user.owner = _beneficiary;
        user.amountInvest = user.amountInvest.add(amount);
        user.tokenBuy = user.tokenBuy.add(quantityToken);
        _forwardFunds(amount, _beneficiary);
        emit TokenPurchase(_beneficiary, weiAmount, quantityToken);
        emit FeePayed(_beneficiary, PROJECT_FEE);
    }

    function claimToken() public payable alreadyClosed hasTokens blockReEntry {
        User storage user = users[msg.sender];
        require(
            user.countClaimed.add(1) <= LIMIT_CLAIMED,
            "Required: claimed almost done"
        );
        require(
            block.timestamp >= user.lastClaimed.add(TIME_STEP),
            "Required: waiting enough time to claim"
        );
        require(user.tokenBuy > 0, "Required: Must be register to claim token");
        require(
            msg.value == CLAIM_FEE,
            "Required: Must be paid fee to claim token"
        );
        uint256 _amountToken;
        uint256 ratio = block.timestamp.sub(_endTime).div(TIME_STEP);
        if (ratio.add(user.countClaimed) >= LIMIT_CLAIMED) {
            ratio = LIMIT_CLAIMED - user.countClaimed;
        }
        if(user.countClaimed == 0 && ratio == 0) {
            ratio = 1;
        }
        require(ratio > 0, "almost done");
        _amountToken = user.tokenBuy.mul(ratio);
        user.lastClaimed = block.timestamp;
        user.countClaimed = user.countClaimed.add(ratio);
        user.amountClaimed = user.amountClaimed.add(_amountToken);
        totalClaim = totalClaim.add(_amountToken);

        _deliverTokens(msg.sender, _amountToken);
        emit FeePayed(msg.sender, CLAIM_FEE);
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
        saleWallet.transfer(msg.value);
        saleToken.transfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Determines how BNB is stored/forwarded on purchases.
     */
    function _forwardFunds(uint256 amount, address userAddress) internal {
        saleWallet.transfer(msg.value);
        buyToken.transferFrom(userAddress, saleWallet, amount);
    }

    function setMinInvestBNB(uint256 _amount) external onlyOwner {
        minInvest = _amount;
    }

    function setMaxInvestBNB(uint256 _amount) external onlyOwner {
        maxInvest = _amount;
    }

    function setBuyToken(address _token) external onlyOwner {
        buyToken = IBEP20(_token);
    }

    function setProjectFee(uint256 _fee) external onlyOwner {
        PROJECT_FEE = _fee;
    }

    function setClaimFee(uint256 _fee) external onlyOwner {
        CLAIM_FEE = _fee;
    }

    function setSlotRegister(uint256 _slot) external onlyOwner {
        TOTAL_SLOT = _slot;
    }

    function setTimeStep(uint256 _time) external onlyOwner {
        TIME_STEP = _time;
    }

    function setLimitClaimed(uint256 _count) external onlyOwner {
        LIMIT_CLAIMED = _count;
    }

    function setPriceToken(uint256 _totalSuply, uint256 _quantity)
        external
        onlyOwner
    {
        quantityToken = _quantity;
        totalSupply = _totalSuply;
    }

    function setStartTime(uint256 time) external onlyOwner {
        _startTime = time;
    }

    function setEndTime(uint256 time) external onlyOwner {
        _endTime = time;
    }

    function setSaleWallet(address payable _saleAddress) external onlyOwner {
        saleWallet = _saleAddress;
    }

    function setTokenSale(address _token) external onlyOwner {
        saleToken = IBEP20(_token);
    }

    function handleForfeitedBalance(
        address coinAddress,
        uint256 value,
        address payable to
    ) public onlyOwner {
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IBEP20(coinAddress).transfer(to, value);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
import "./Context.sol";
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