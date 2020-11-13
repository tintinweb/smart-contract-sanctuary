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
interface ITokensTypeStorage {
  function isRegistred(address _address) external view returns(bool);

  function getType(address _address) external view returns(bytes32);

  function isPermittedAddress(address _address) external view returns(bool);

  function owner() external view returns(address);

  function addNewTokenType(address _token, string calldata _type) external;

  function setTokenTypeAsOwner(address _token, string calldata _type) external;
}
// Contains view methods for exchange
// We have separated the methods for the fund and for the exchange because they contain different methods.



interface PoolPortalViewInterface {
  function getDataForBuyingPool(IERC20 _poolToken, uint _type, uint256 _amount)
    external
    view
    returns(
      address[] memory connectorsAddress,
      uint256[] memory connectorsAmount
  );

  function getBacorConverterAddressByRelay(address relay)
  external
  view
  returns(address converter);

  function getBancorConnectorsAmountByRelayAmount
  (
    uint256 _amount,
    IERC20 _relay
  )
  external view returns(uint256 bancorAmount, uint256 connectorAmount);

  function getBancorConnectorsByRelay(address relay)
  external
  view
  returns(address[] memory connectorsAddress);

  function getBancorRatio(address _from, address _to, uint256 _amount)
  external
  view
  returns(uint256);

  function getUniswapConnectorsAmountByPoolAmount(
    uint256 _amount,
    address _exchange
  )
  external
  view
  returns(uint256 ethAmount, uint256 ercAmount);

  function getUniswapV2ConnectorsAmountByPoolAmount(
    uint256 _amount,
    address _exchange
  )
  external
  view
  returns(
    uint256 tokenAmountOne,
    uint256 tokenAmountTwo,
    address tokenAddressOne,
    address tokenAddressTwo
  );

  function getBalancerConnectorsAmountByPoolAmount(
    uint256 _amount,
    address _pool
  )
  external
  view
  returns(
    address[] memory tokens,
    uint256[] memory tokensAmount
  );

  function getUniswapTokenAmountByETH(address _token, uint256 _amount)
  external
  view
  returns(uint256);

  function getTokenByUniswapExchange(address _exchange)
  external
  view
  returns(address);
}
interface DefiPortalInterface {
  function callPayableProtocol(
    address[] memory tokensToSend,
    uint256[] memory amountsToSend,
    bytes calldata _additionalData,
    bytes32[] calldata _additionalArgs
  )
    external
    payable
    returns(
      string memory eventType,
      address[] memory tokensToReceive,
      uint256[] memory amountsToReceive
    );

  function callNonPayableProtocol(
    address[] memory tokensToSend,
    uint256[] memory amountsToSend,
    bytes calldata _additionalData,
    bytes32[] calldata _additionalArgs
  )
    external
    returns(
      string memory eventType,
      address[] memory tokensToReceive,
      uint256[] memory amountsToReceive
    );

  function getValue(
    address _from,
    address _to,
    uint256 _amount
  )
   external
   view
   returns(uint256);
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


interface IOneSplitAudit {
  function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 disableFlags
    ) external payable;

  function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 featureFlags // See contants in IOneSplit.sol
    )
      external
      view
      returns(
          uint256 returnAmount,
          uint256[] memory distribution
      );
}

/*
    Bancor Network interface
*/
interface BancorNetworkInterface {
   function getReturnByPath(
     IERC20[] calldata _path,
     uint256 _amount)
     external
     view
     returns (uint256, uint256);

    function convert(
        IERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn
    ) external payable returns (uint256);

    function claimAndConvert(
        IERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn
    ) external returns (uint256);

    function convertFor(
        IERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for
    ) external payable returns (uint256);

    function claimAndConvertFor(
        IERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for
    ) external returns (uint256);

    function conversionPath(
        IERC20 _sourceToken,
        IERC20 _targetToken
    ) external view returns (address[] memory);
}


interface IGetBancorData {
  function getBancorContractAddresByName(string calldata _name) external view returns (address result);
  function getBancorRatioForAssets(IERC20 _from, IERC20 _to, uint256 _amount) external view returns(uint256 result);
  function getBancorPathForAssets(IERC20 _from, IERC20 _to) external view returns(address[] memory);
}


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














contract ExchangePortal is ExchangePortalInterface, Ownable {
  using SafeMath for uint256;

  uint public version = 5;

  // Contract for handle tokens types
  ITokensTypeStorage public tokensTypes;

  // Contract for merkle tree white list verification
  IMerkleTreeTokensVerification public merkleTreeWhiteList;

  // 1INCH
  IOneSplitAudit public oneInch;

  // 1 inch protocol for calldata
  address public oneInchETH;

  // BANCOR
  IGetBancorData public bancorData;

  // CoTrader portals
  PoolPortalViewInterface public poolPortal;
  DefiPortalInterface public defiPortal;

  // 1 inch flags
  // By default support Bancor + Uniswap + Uniswap v2
  uint256 oneInchFlags = 570425349;

  // Enum
  // NOTE: You can add a new type at the end, but DO NOT CHANGE this order,
  // because order has dependency in other contracts like ConvertPortal
  enum ExchangeType { Paraswap, Bancor, OneInch, OneInchETH }

  // This contract recognizes ETH by this address
  IERC20 constant private ETH_TOKEN_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

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
  *
  * @param _defiPortal             address of defiPortal contract
  * @param _bancorData             address of GetBancorData helper
  * @param _poolPortal             address of pool portal
  * @param _oneInch                address of 1inch OneSplitAudit contract
  * @param _oneInchETH             address of oneInch ETH contract
  * @param _tokensTypes            address of the ITokensTypeStorage
  * @param _merkleTreeWhiteList    address of the IMerkleTreeWhiteList
  */
  constructor(
    address _defiPortal,
    address _bancorData,
    address _poolPortal,
    address _oneInch,
    address _oneInchETH,
    address _tokensTypes,
    address _merkleTreeWhiteList
    )
    public
  {
    defiPortal = DefiPortalInterface(_defiPortal);
    bancorData = IGetBancorData(_bancorData);
    poolPortal = PoolPortalViewInterface(_poolPortal);
    oneInch = IOneSplitAudit(_oneInch);
    oneInchETH = _oneInchETH;
    tokensTypes = ITokensTypeStorage(_tokensTypes);
    merkleTreeWhiteList = IMerkleTreeTokensVerification(_merkleTreeWhiteList);
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
    if (_source == ETH_TOKEN_ADDRESS) {
      require(msg.value == _sourceAmount);
    } else {
      require(msg.value == 0);
    }

    // SHOULD TRADE PARASWAP HERE
    if (_type == uint(ExchangeType.Paraswap)) {
      revert("PARASWAP not supported");
    }
    // SHOULD TRADE BANCOR HERE
    else if (_type == uint(ExchangeType.Bancor)){
      receivedAmount = _tradeViaBancorNewtork(
          address(_source),
          address(_destination),
          _sourceAmount
      );
    }
    // SHOULD TRADE 1INCH HERE
    else if (_type == uint(ExchangeType.OneInch)){
      receivedAmount = _tradeViaOneInch(
          address(_source),
          address(_destination),
          _sourceAmount,
          _additionalData
      );
    }

    // SHOULD TRADE 1INCH ETH HERE
    else if (_type == uint(ExchangeType.OneInchETH)){
      receivedAmount = _tradeViaOneInchETH(
          address(_source),
          address(_destination),
          _sourceAmount,
          _additionalData
      );
    }

    else {
      // unknown exchange type
      revert();
    }

    // Additional check
    require(receivedAmount > 0, "received amount can not be zerro");

    // Send destination
    if (_destination == ETH_TOKEN_ADDRESS) {
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

  // Facilitates for send source remains
  function _sendRemains(IERC20 _source, address _receiver) private {
    // After the trade, any _source that exchangePortal holds will be sent back to msg.sender
    uint256 endAmount = (_source == ETH_TOKEN_ADDRESS)
    ? address(this).balance
    : _source.balanceOf(address(this));

    // Check if we hold a positive amount of _source
    if (endAmount > 0) {
      if (_source == ETH_TOKEN_ADDRESS) {
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

 // Facilitates trade with 1inch
 function _tradeViaOneInch(
   address sourceToken,
   address destinationToken,
   uint256 sourceAmount,
   bytes memory _additionalData
   )
   private
   returns(uint256 destinationReceived)
 {
    (uint256 flags,
     uint256[] memory _distribution) = abi.decode(_additionalData, (uint256, uint256[]));

    if(IERC20(sourceToken) == ETH_TOKEN_ADDRESS) {
      oneInch.swap.value(sourceAmount)(
        IERC20(sourceToken),
        IERC20(destinationToken),
        sourceAmount,
        1,
        _distribution,
        flags
        );
    } else {
      _transferFromSenderAndApproveTo(IERC20(sourceToken), sourceAmount, address(oneInch));
      oneInch.swap(
        IERC20(sourceToken),
        IERC20(destinationToken),
        sourceAmount,
        1,
        _distribution,
        flags
        );
    }

    destinationReceived = tokenBalance(IERC20(destinationToken));
    tokensTypes.addNewTokenType(destinationToken, "CRYPTOCURRENCY");
 }

  // Facilitates trade with 1inch ETH
  // this protocol require calldata from 1inch api
  function _tradeViaOneInchETH(
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
     if(IERC20(sourceToken) == ETH_TOKEN_ADDRESS) {
       (success, ) = oneInchETH.call.value(sourceAmount)(
         _additionalData
       );
     }
     // from ERC20
     else {
       _transferFromSenderAndApproveTo(IERC20(sourceToken), sourceAmount, address(oneInchETH));
       (success, ) = oneInchETH.call(
         _additionalData
       );
     }
     // check trade status
     require(success, "Fail 1inch call");
     // get received amount
     destinationReceived = tokenBalance(IERC20(destinationToken));
     // set token type
     tokensTypes.addNewTokenType(destinationToken, "CRYPTOCURRENCY");
  }


 // Facilitates trade with Bancor
 function _tradeViaBancorNewtork(
   address sourceToken,
   address destinationToken,
   uint256 sourceAmount
   )
   private
   returns(uint256 returnAmount)
 {
    // get latest bancor contracts
    BancorNetworkInterface bancorNetwork = BancorNetworkInterface(
      bancorData.getBancorContractAddresByName("BancorNetwork")
    );

    // Get Bancor tokens path
    address[] memory path = bancorData.getBancorPathForAssets(IERC20(sourceToken), IERC20(destinationToken));

    // Convert addresses to ERC20
    IERC20[] memory pathInERC20 = new IERC20[](path.length);
    for(uint i=0; i<path.length; i++){
        pathInERC20[i] = IERC20(path[i]);
    }

    // trade
    if (IERC20(sourceToken) == ETH_TOKEN_ADDRESS) {
      returnAmount = bancorNetwork.convert.value(sourceAmount)(pathInERC20, sourceAmount, 1);
    }
    else {
      _transferFromSenderAndApproveTo(IERC20(sourceToken), sourceAmount, address(bancorNetwork));
      returnAmount = bancorNetwork.claimAndConvert(pathInERC20, sourceAmount, 1);
    }

    tokensTypes.addNewTokenType(destinationToken, "BANCOR_ASSET");
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
    if (_token == ETH_TOKEN_ADDRESS)
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
  * @return best price from 1inch for ERC20, or ratio for Uniswap and Bancor pools
  */
  function getValue(address _from, address _to, uint256 _amount)
    public
    override
    view
    returns (uint256)
  {
    if(_amount > 0){
      // get asset type
      bytes32 assetType = tokensTypes.getType(_from);

      // get value by asset type
      if(assetType == bytes32("CRYPTOCURRENCY")){
        return getValueViaDEXsAgregators(_from, _to, _amount);
      }
      else if (assetType == bytes32("BANCOR_ASSET")){
        return getValueViaBancor(_from, _to, _amount);
      }
      else if (assetType == bytes32("UNISWAP_POOL")){
        return getValueForUniswapPools(_from, _to, _amount);
      }
      else if (assetType == bytes32("UNISWAP_POOL_V2")){
        return getValueForUniswapV2Pools(_from, _to, _amount);
      }
      else if (assetType == bytes32("BALANCER_POOL")){
        return getValueForBalancerPool(_from, _to, _amount);
      }
      else{
        // Unmarked type, try find value
        return findValue(_from, _to, _amount);
      }
    }
    else{
      return 0;
    }
  }

  /**
  * @dev find the ratio by amount of token _from in token _to trying all available methods
  *
  * @param _from      Address of token we're converting from
  * @param _to        Address of token we're getting the value in
  * @param _amount    The amount of _from
  *
  * @return best price from 1inch for ERC20, or ratio for Uniswap and Bancor pools
  */
  function findValue(address _from, address _to, uint256 _amount) private view returns (uint256) {
     if(_amount > 0){
       // Check at first value from defi portal, maybe there are new defi protocols
       // If defiValue return 0 continue check from another sources
       uint256 defiValue = defiPortal.getValue(_from, _to, _amount);
       if(defiValue > 0)
          return defiValue;

       // If 1inch return 0, check from Bancor network for ensure this is not a Bancor pool
       uint256 oneInchResult = getValueViaDEXsAgregators(_from, _to, _amount);
       if(oneInchResult > 0)
         return oneInchResult;

       // If Bancor return 0, check from Balancer network for ensure this is not Balancer asset
       uint256 bancorResult = getValueViaBancor(_from, _to, _amount);
       if(bancorResult > 0)
          return bancorResult;

       // If Balancer return 0, check from Uniswap pools for ensure this is not Uniswap pool
       uint256 balancerResult = getValueForBalancerPool(_from, _to, _amount);
       if(balancerResult > 0)
          return balancerResult;

       // If Uniswap return 0, check from Uniswap version 2 pools for ensure this is not Uniswap V2 pool
       uint256 uniswapResult = getValueForUniswapPools(_from, _to, _amount);
       if(uniswapResult > 0)
          return uniswapResult;

       // Uniswap V2 pools return 0 if these is not a Uniswap V2 pool
       return getValueForUniswapV2Pools(_from, _to, _amount);
     }
     else{
       return 0;
     }
  }


  // helper for get value via 1inch
  // in this interface can be added more DEXs aggregators
  function getValueViaDEXsAgregators(
    address _from,
    address _to,
    uint256 _amount
  )
  public view returns (uint256){
    // if direction the same, just return amount
    if(_from == _to)
       return _amount;

    // try get value via 1inch
    if(_amount > 0){
      // try get value from 1inch aggregator
      return getValueViaOneInch(_from, _to, _amount);
    }
    else{
      return 0;
    }
  }


  // helper for get ratio between assets in 1inch aggregator
  function getValueViaOneInch(
    address _from,
    address _to,
    uint256 _amount
  )
    public
    view
    returns (uint256 value)
  {
    // if direction the same, just return amount
    if(_from == _to)
       return _amount;

    // try get rate
    try oneInch.getExpectedReturn(
       IERC20(_from),
       IERC20(_to),
       _amount,
       10,
       oneInchFlags)
      returns(uint256 returnAmount, uint256[] memory distribution)
     {
       value = returnAmount;
     }
     catch{
       value = 0;
     }
  }


  // helper for get ratio between assets in Bancor network
  function getValueViaBancor(
    address _from,
    address _to,
    uint256 _amount
  )
    public
    view
    returns (uint256 value)
  {
    // if direction the same, just return amount
    if(_from == _to)
       return _amount;

    // try get rate
    if(_amount > 0){
      try poolPortal.getBancorRatio(_from, _to, _amount) returns(uint256 result){
        value = result;
      }catch{
        value = 0;
      }
    }else{
      return 0;
    }
  }


  // helper for get value via Balancer
  function getValueForBalancerPool(
    address _from,
    address _to,
    uint256 _amount
  )
    public
    view
    returns (uint256 value)
  {
    // get value for each pool share
    try poolPortal.getBalancerConnectorsAmountByPoolAmount(_amount, _from)
    returns(
      address[] memory tokens,
      uint256[] memory tokensAmount
    )
    {
     // convert and sum value via DEX aggregator
     for(uint i = 0; i < tokens.length; i++){
       value += getValueViaDEXsAgregators(tokens[i], _to, tokensAmount[i]);
     }
    }
    catch{
      value = 0;
    }
  }


  // helper for get ratio between pools in Uniswap network
  // _from - should be uniswap pool address
  function getValueForUniswapPools(
    address _from,
    address _to,
    uint256 _amount
  )
  public
  view
  returns (uint256)
  {
    // get connectors amount
    try poolPortal.getUniswapConnectorsAmountByPoolAmount(
      _amount,
      _from
    ) returns (uint256 ethAmount, uint256 ercAmount)
    {
      // get ERC amount in ETH
      address token = poolPortal.getTokenByUniswapExchange(_from);
      uint256 ercAmountInETH = getValueViaDEXsAgregators(token, address(ETH_TOKEN_ADDRESS), ercAmount);
      // sum ETH with ERC amount in ETH
      uint256 totalETH = ethAmount.add(ercAmountInETH);

      // if _to == ETH no need additional convert, just return ETH amount
      if(_to == address(ETH_TOKEN_ADDRESS)){
        return totalETH;
      }
      // convert ETH into _to asset via 1inch
      else{
        return getValueViaDEXsAgregators(address(ETH_TOKEN_ADDRESS), _to, totalETH);
      }
    }catch{
      return 0;
    }
  }


  // helper for get ratio between pools in Uniswap network version 2
  // _from - should be uniswap pool address
  function getValueForUniswapV2Pools(
    address _from,
    address _to,
    uint256 _amount
  )
  public
  view
  returns (uint256)
  {
    // get connectors amount by pool share
    try poolPortal.getUniswapV2ConnectorsAmountByPoolAmount(
      _amount,
      _from
    ) returns (
      uint256 tokenAmountOne,
      uint256 tokenAmountTwo,
      address tokenAddressOne,
      address tokenAddressTwo
      )
    {
      // convert connectors amount via DEX aggregator
      uint256 amountOne = getValueViaDEXsAgregators(tokenAddressOne, _to, tokenAmountOne);
      uint256 amountTwo = getValueViaDEXsAgregators(tokenAddressTwo, _to, tokenAmountTwo);
      // return value
      return amountOne + amountTwo;
    }catch{
      return 0;
    }
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

  // owner can change oneInch
  function setNewOneInch(address _oneInch) external onlyOwner {
    oneInch = IOneSplitAudit(_oneInch);
  }

  // owner can change oneInch
  function setNewOneInchETH(address _oneInchETH) external onlyOwner {
    oneInchETH = _oneInchETH;
  }

  // owner can set new pool portal
  function setNewPoolPortal(address _poolPortal) external onlyOwner {
    poolPortal = PoolPortalViewInterface(_poolPortal);
  }

  // owner can set new defi portal
  function setNewDefiPortal(address _defiPortal) external onlyOwner {
    defiPortal = DefiPortalInterface(_defiPortal);
  }

  // owner of portal can update 1 incg DEXs sources
  function setOneInchFlags(uint256 _oneInchFlags) external onlyOwner {
    oneInchFlags = _oneInchFlags;
  }

  // owner of portal can change getBancorData helper, for case if Bancor do some major updates
  function setNewGetBancorData(address _bancorData) external onlyOwner {
    bancorData = IGetBancorData(_bancorData);
  }

  // fallback payable function to receive ether from other contract addresses
  fallback() external payable {}

}