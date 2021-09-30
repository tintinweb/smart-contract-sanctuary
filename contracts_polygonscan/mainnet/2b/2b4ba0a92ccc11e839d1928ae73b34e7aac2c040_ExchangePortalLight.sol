/**
 *Submitted for verification at polygonscan.com on 2021-09-30
*/

interface IMerkleTreeTokensVerification {
  function verify(
    address _leaf,
    bytes32 [] calldata proof,
    uint256 [] calldata positions
  )
    external
    view
    returns (bool);
}
pragma solidity ^0.6.0;

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


interface ExchangePortalInterface {
  function trade(
    IERC20 _source,
    uint256 _sourceAmount,
    IERC20 _destination,
    uint256 _type,
    bytes32[] calldata _proof,
    uint256[] calldata _positions,
    bytes calldata _additionalData,
    bool _verifyDestanation
  )
    external
    payable
    returns (uint256);


  function getValue(address _from, address _to, uint256 _amount) external view returns (uint256);

  function getTotalValue(
    address[] calldata _fromAddresses,
    uint256[] calldata _amounts,
    address _to
    )
    external
    view
   returns (uint256);
}
interface IPricePortal {
  function getPrice(
    address _from,
    address _to,
    uint256 _amount
  )
    external
    view
    returns (uint256 value);
}
// Light portal without tokens type storage and trade only erc20



/*
* This contract do swap for ERC20 via 1inch

  Also this contract allow get ratio between crypto curency assets
  Also get ratio for Bancor and Uniswap pools
*/





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





// SPDX-License-Identifier: GPL-3.0



interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}






interface IUniswapV2Router is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}



contract ExchangePortalLight is ExchangePortalInterface, Ownable {
  using SafeMath for uint256;

  uint public version = 6;

  // Contract for merkle tree white list verification
  IMerkleTreeTokensVerification public merkleTreeWhiteList;

  // 1 inch protocol for calldata
  address public OneInchRoute;

  address public WETH;
  address public uniswapRouter;

  IPricePortal public pricePortal;


  // Enum
  // NOTE: You can add a new type at the end, but DO NOT CHANGE this order,
  // because order has dependency in other contracts like ConvertPortal
  enum ExchangeType { Paraswap, Bancor, OneInch, OneInchETH, UniswapV2 }

  // Trade event
  event Trade(
     address trader,
     address src,
     uint256 srcAmount,
     address dest,
     uint256 destReceived,
     uint8 exchangeType
  );

  // black list for non trade able tokens
  mapping (address => bool) disabledTokens;

  // Modifier to check that trading this token is not disabled
  modifier tokenEnabled(IERC20 _token) {
    require(!disabledTokens[address(_token)]);
    _;
  }

  /**
  * @dev contructor
  * @param _pricePortal            address of price portal
  * @param _OneInchRoute           address of oneInch ETH contract
  * @param _merkleTreeWhiteList    address of the IMerkleTreeWhiteList
  * @param _WETH                   WBNB address
  */
  constructor(
    address _pricePortal,
    address _OneInchRoute,
    address _merkleTreeWhiteList,
    address _WETH,
    address _uniswapRouter
    )
    public
  {
    pricePortal = IPricePortal(_pricePortal);
    OneInchRoute = _OneInchRoute;
    merkleTreeWhiteList = IMerkleTreeTokensVerification(_merkleTreeWhiteList);
    WETH = _WETH;
    uniswapRouter = _uniswapRouter;
  }


  // EXCHANGE Functions

  /**
  * @dev Facilitates a trade for a SmartFund
  *
  * @param _source            ERC20 token to convert from
  * @param _sourceAmount      Amount to convert from (in _source token)
  * @param _destination       ERC20 token to convert to
  * @param _type              The type of exchange to trade with
  * @param _proof             Merkle tree proof (if not used just set [])
  * @param _positions         Merkle tree positions (if not used just set [])
  * @param _additionalData    For additional data (if not used just set 0x0)
  * @param _verifyDestanation For additional check if token in list or not
  *
  * @return receivedAmount    The amount of _destination received from the trade
  */
  function trade(
    IERC20 _source,
    uint256 _sourceAmount,
    IERC20 _destination,
    uint256 _type,
    bytes32[] calldata _proof,
    uint256[] calldata _positions,
    bytes calldata _additionalData,
    bool _verifyDestanation
  )
    external
    override
    payable
    tokenEnabled(_destination)
    returns (uint256 receivedAmount)
  {
    // throw if destanation token not in white list
    if(_verifyDestanation)
      _verifyToken(address(_destination), _proof, _positions);

    require(_source != _destination, "source can not be destination");

    // check ETH payable case
    if (_source == IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
      require(msg.value == _sourceAmount);
    } else {
      require(msg.value == 0);
    }

    // trade via 1inch
    if (_type == uint(ExchangeType.OneInchETH)){
      receivedAmount = _tradeViaOneInchRoute(
          address(_source),
          address(_destination),
          _sourceAmount,
          _additionalData
      );
    }

    // trade via Uniswap
    else if(_type == uint(ExchangeType.UniswapV2)){
      receivedAmount = _tradeViaUniswapV2BasedDEX(
        address(_source),
        address(_destination),
        _sourceAmount,
        uniswapRouter
      );
    }

    // unknown exchange type
    else {
      revert("Unknown type");
    }

    // Additional check
    require(receivedAmount > 0, "received amount can not be zerro");

    // Send destination
    if (_destination == IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
      (msg.sender).transfer(receivedAmount);
    } else {
      // transfer tokens received to sender
      _destination.transfer(msg.sender, receivedAmount);
    }

    // Send remains
    _sendRemains(_source, msg.sender);

    // Trigger event
    emit Trade(
      msg.sender,
      address(_source),
      _sourceAmount,
      address(_destination),
      receivedAmount,
      uint8(_type)
    );
  }

  // Facilitates trade with 1inch ETH
  // this protocol require calldata from 1inch api
  function _tradeViaOneInchRoute(
    address sourceToken,
    address destinationToken,
    uint256 sourceAmount,
    bytes memory _additionalData
    )
    private
    returns(uint256 destinationReceived)
  {
     bool success;
     // from ETH
     if(IERC20(sourceToken) == IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
       (success, ) = OneInchRoute.call.value(sourceAmount)(
         _additionalData
       );
     }
     // from ERC20
     else {
       _transferFromSenderAndApproveTo(IERC20(sourceToken), sourceAmount, OneInchRoute);
       (success, ) = OneInchRoute.call(
         _additionalData
       );
     }
     // check trade status
     require(success, "Fail 1inch call");
     // get received amount
     destinationReceived = tokenBalance(IERC20(destinationToken));
  }

  function _tradeViaUniswapV2BasedDEX(
    address sourceToken,
    address destinationToken,
    uint256 sourceAmount,
    address router
  )
    private
    returns(uint256 destinationReceived)
  {
     address[] memory path = new address[](2);

     // swap from ETH
     if(IERC20(sourceToken) == IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
       path[0] = WETH;
       path[1] = destinationToken;

       IUniswapV2Router(router).swapExactETHForTokens.value(sourceAmount)(
         1,
         path,
         address(this),
         now + 15 minutes
       );
     }
     // swap to ETH
     else if(IERC20(destinationToken) == IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
       path[0] = sourceToken;
       path[1] = WETH;

       _transferFromSenderAndApproveTo(IERC20(sourceToken), sourceAmount, router);

       IUniswapV2Router(router).swapExactTokensForETH(
         sourceAmount,
         1,
         path,
         address(this),
         now + 15 minutes
       );
     }
     // swap between ERC20 only
     else{
       path[0] = sourceToken;
       path[1] = destinationToken;

       _transferFromSenderAndApproveTo(IERC20(sourceToken), sourceAmount, router);

       IUniswapV2Router(router).swapExactTokensForTokens(
           sourceAmount,
           1,
           path,
           address(this),
           now + 15 minutes
       );
     }

     destinationReceived = tokenBalance(IERC20(destinationToken));
  }

  // Facilitates for send source remains
  function _sendRemains(IERC20 _source, address _receiver) private {
    // After the trade, any _source that exchangePortal holds will be sent back to msg.sender
    uint256 endAmount = (_source == IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE))
    ? address(this).balance
    : _source.balanceOf(address(this));

    // Check if we hold a positive amount of _source
    if (endAmount > 0) {
      if (_source == IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
        payable(_receiver).transfer(endAmount);
      } else {
        _source.transfer(_receiver, endAmount);
      }
    }
  }


  // Facilitates for verify destanation token input (check if token in merkle list or not)
  // revert transaction if token not in list
  function _verifyToken(
    address _destination,
    bytes32 [] memory proof,
    uint256 [] memory positions)
    private
    view
  {
    bool status = merkleTreeWhiteList.verify(_destination, proof, positions);

    if(!status)
      revert("Dest not in white list");
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



  // VIEW Functions

  function tokenBalance(IERC20 _token) private view returns (uint256) {
    if (_token == IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE))
      return address(this).balance;
    return _token.balanceOf(address(this));
  }

  /**
  * @dev Gets the ratio by amount of token _from in token _to by totekn type
  *
  * @param _from      Address of token we're converting from
  * @param _to        Address of token we're getting the value in
  * @param _amount    The amount of _from
  *
  * @return ration between from and to
  */
  function getValue(address _from, address _to, uint256 _amount)
    public
    override
    view
    returns (uint256)
  {
    return pricePortal.getPrice(_from, _to, _amount);
  }


  /**
  * @dev Gets the total value of array of tokens and amounts
  *
  * @param _fromAddresses    Addresses of all the tokens we're converting from
  * @param _amounts          The amounts of all the tokens
  * @param _to               The token who's value we're converting to
  *
  * @return The total value of _fromAddresses and _amounts in terms of _to
  */
  function getTotalValue(
    address[] calldata _fromAddresses,
    uint256[] calldata _amounts,
    address _to)
    external
    override
    view
    returns (uint256)
  {
    uint256 sum = 0;
    for (uint256 i = 0; i < _fromAddresses.length; i++) {
      sum = sum.add(getValue(_fromAddresses[i], _to, _amounts[i]));
    }
    return sum;
  }

  // SETTERS Functions

  /**
  * @dev Allows the owner to disable/enable the buying of a token
  *
  * @param _token      Token address whos trading permission is to be set
  * @param _enabled    New token permission
  */
  function setToken(address _token, bool _enabled) external onlyOwner {
    disabledTokens[_token] = _enabled;
  }

  // owner can change price portal
  function setNewPricePortal(address _pricePortal) external onlyOwner {
    pricePortal = IPricePortal(_pricePortal);
  }

  // owner can set new 1inch router
  function setNewOneInchRouter(address _OneInchRoute) external onlyOwner {
    OneInchRoute = _OneInchRoute;
  }

  // fallback payable function to receive ether from other contract addresses
  fallback() external payable {}

}