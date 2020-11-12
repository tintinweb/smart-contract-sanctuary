interface ITokensTypeStorage {
  function isRegistred(address _address) external view returns(bool);

  function getType(address _address) external view returns(bytes32);

  function isPermittedAddress(address _address) external view returns(bool);

  function owner() external view returns(address);

  function addNewTokenType(address _token, string calldata _type) external;

  function setTokenTypeAsOwner(address _token, string calldata _type) external;
}
interface IYearnToken {
  function token() external view returns(address);
  function deposit(uint _amount) external;
  function withdraw(uint _shares) external;
  function getPricePerFullShare() external view returns (uint);
}
// For support new Defi protocols
pragma solidity ^0.6.12;



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





contract DefiPortal {
  using SafeMath for uint256;

  uint public version = 4;
  address constant private ETH_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  // Contract for handle tokens types
  ITokensTypeStorage public tokensTypes;

  // Enum
  // NOTE: You can add a new type at the end, but DO NOT CHANGE this order
  enum DefiActions { YearnDeposit, YearnWithdraw }

  constructor(address _tokensTypes) public {
    tokensTypes = ITokensTypeStorage(_tokensTypes);
  }

  /**
  *
  * if need paybale protocol, in new version of this portal can be added such function
  *
  function callNonPayableProtocol(
    address[] memory tokensToSend,
    uint256[] memory amountsToSend,
    bytes memory _additionalData,
    bytes32[] memory _additionalArgs
  )
   external
   returns(
     string memory eventType,
     address[] memory tokensToReceive,
     uint256[] memory amountsToReceive
  );
  */


  // param _additionalArgs[0] require DefiActions type
  function callNonPayableProtocol(
    address[] memory tokensToSend,
    uint256[] memory amountsToSend,
    bytes memory _additionalData,
    bytes32[] memory _additionalArgs
  )
    external
    returns(
      string memory eventType,
      address[] memory tokensToReceive,
      uint256[] memory amountsToReceive
    )
  {
    if(uint(_additionalArgs[0]) == uint(DefiActions.YearnDeposit)){
      (tokensToReceive, amountsToReceive) = _YearnDeposit(
        tokensToSend[0],
        amountsToSend[0],
        _additionalData
      );
      eventType = "YEARN_DEPOSIT";
    }
    else if(uint(_additionalArgs[0]) == uint(DefiActions.YearnWithdraw)){
       (tokensToReceive, amountsToReceive) = _YearnWithdraw(
         tokensToSend[0],
         amountsToSend[0],
         _additionalData
        );
       eventType = "YEARN_WITHDRAW";
    }
    else{
      revert("Unknown DEFI action");
    }
  }

  // for new DEFI protocols Exchange portal get value here
  function getValue(
    address _from,
    address _to,
    uint256 _amount
  )
   public
   view
   returns(uint256)
  {
    return 0;
  }


  // param _additionalData require address yTokenAddress, uint256 minReturn
  function _YearnDeposit(
    address tokenAddress,
    uint256 tokenAmount,
    bytes memory _additionalData
  )
    private
    returns(
    address[] memory tokensToReceive,
    uint256[] memory amountsToReceive
  )
  {
    // get yToken instance
    (address yTokenAddress, uint256 minReturn) = abi.decode(_additionalData, (address, uint256));
    IYearnToken yToken = IYearnToken(yTokenAddress);
    // transfer underlying from sender
    _transferFromSenderAndApproveTo(IERC20(tokenAddress), tokenAmount, yTokenAddress);
    // mint yToken
    yToken.deposit(tokenAmount);
    // get received tokens
    uint256 receivedYToken = IERC20(yTokenAddress).balanceOf(address(this));
    // min return check
    require(receivedYToken >= minReturn, "MIN_RETURN_FAIL");
    // send yToken to sender
    IERC20(yTokenAddress).transfer(msg.sender, receivedYToken);
    // send remains if there is some remains
    _sendRemains(IERC20(tokenAddress), msg.sender);
    // Update type
    // DEV NOTE don't need mark this tokens as YEARN assets, we can use 1inch ratio
    // for this token as for CRYPTOCURRENCY
    tokensTypes.addNewTokenType(yTokenAddress, "CRYPTOCURRENCY");
    // return data
    tokensToReceive = new address[](1);
    tokensToReceive[0] = yTokenAddress;
    amountsToReceive = new uint256[](1);
    amountsToReceive[0] = receivedYToken;
  }


  // param _additionalData require  uint256 minReturn
  function _YearnWithdraw(
    address yTokenAddress,
    uint256 sharesAmount,
    bytes memory _additionalData
  )
    private
    returns(
    address[] memory tokensToReceive,
    uint256[] memory amountsToReceive
    )
  {
    (uint256 minReturn) = abi.decode(_additionalData, (uint256));
    IYearnToken yToken = IYearnToken(yTokenAddress);
    // transfer underlying from sender
    _transferFromSenderAndApproveTo(IERC20(yTokenAddress), sharesAmount, yTokenAddress);
    // mint yToken
    yToken.withdraw(sharesAmount);
    // get underlying address
    address underlyingToken = yToken.token();
    // get received tokens
    uint256 received = IERC20(underlyingToken).balanceOf(address(this));
    // min return check
    require(received >= minReturn, "MIN_RETURN_FAIL");
    // send underlying to sender
    IERC20(underlyingToken).transfer(msg.sender, received);
    // send remains if there is some remains
    _sendRemains(IERC20(yTokenAddress), msg.sender);
    // return data
    tokensToReceive = new address[](1);
    tokensToReceive[0] = underlyingToken;
    amountsToReceive = new uint256[](1);
    amountsToReceive[0] = received;
  }


  // Facilitates for send source remains
  function _sendRemains(IERC20 _source, address _receiver) private {
    // After the trade, any _source that exchangePortal holds will be sent back to msg.sender
    uint256 endAmount = (_source == IERC20(ETH_TOKEN_ADDRESS))
    ? address(this).balance
    : _source.balanceOf(address(this));

    // Check if we hold a positive amount of _source
    if (endAmount > 0) {
      if (_source == IERC20(ETH_TOKEN_ADDRESS)) {
        payable(_receiver).transfer(endAmount);
      } else {
        _source.transfer(_receiver, endAmount);
      }
    }
  }


  /**
  * @dev Transfers tokens to this contract and approves them to another address
  *
  * @param _source          Token to transfer and approve
  * @param _sourceAmount    The amount to transfer and approve (in _source token)
  * @param _to              Address to approve to
  */
  function _transferFromSenderAndApproveTo(IERC20 _source, uint256 _sourceAmount, address _to) private {
    require(_source.transferFrom(msg.sender, address(this), _sourceAmount));
    // reset previos approve because some tokens require allowance 0
    _source.approve(_to, 0);
    // approve
    _source.approve(_to, _sourceAmount);
  }
}