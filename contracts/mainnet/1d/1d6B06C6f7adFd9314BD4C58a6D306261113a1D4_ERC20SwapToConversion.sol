// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/SafeERC20.sol";
import "./Erc20ConversionProxy.sol";
import "./ChainlinkConversionPath.sol";


interface IUniswapV2Router02 {
  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
}


/**
 * @title ERC20SwapToConversion
 * @notice This contract swaps ERC20 tokens before paying a request thanks to a payment proxy
  */
contract ERC20SwapToConversion is Ownable {
  using SafeERC20 for IERC20;

  IUniswapV2Router02 public swapRouter;
  Erc20ConversionProxy public paymentProxy;
  ChainlinkConversionPath public chainlinkConversionPath;

  constructor(address _swapRouterAddress, address _paymentProxyAddress) {
    swapRouter = IUniswapV2Router02(_swapRouterAddress);
    paymentProxy = Erc20ConversionProxy(_paymentProxyAddress);
    chainlinkConversionPath = ChainlinkConversionPath(paymentProxy.chainlinkConversionPath());
  }

  /**
  * @notice Performs a request payment, denominated in a token or currency A,
  *         where the issuer expects a token B, and the payer uses a token C.
  *         The conversion rate from A to B is done using Chainlink.
  *         The token swap is done using Uniswap.
  * @param _to Transfer recipient = request issuer
  * @param _requestAmount Amount to transfer in request currency
  * @param _amountInMax Maximum amount allowed to spend for currency swap, in payment network currency.
            This amount should take into account the fees.
    @param _uniswapPath, path of ERC20 tokens to swap from paymentNetworkToken to spentToken. The first
            address of the path should be the spent currency. The last element should be the
            payment network currency.
    @param _chainlinkPath, path of currencies to convert from request currency to paymentNetworkToken. The first
            address of the path should be the request currency. The last element should be the
            payment network currency.
  * @param _paymentReference Reference of the payment related
  * @param _requestFeeAmount Amount of the fee in request currency
  * @param _feeAddress Where to pay the fee
  * @param _uniswapDeadline Deadline for the swap to be valid
  * @param _chainlinkMaxRateTimespan Max time span with the oldestrate, ignored if zero
  */
  function swapTransferWithReference(
    address _to,
    uint256 _requestAmount, // requestCurrency
    uint256 _amountInMax, // SpentToken
    address[] memory _uniswapPath, // from paymentNetworkToken to spentToken on uniswap
    address[] memory _chainlinkPath, // from requestCurrency to spentToken on chainlink
    bytes calldata _paymentReference,
    uint256 _requestFeeAmount, // requestCurrency
    address _feeAddress,
    uint256 _uniswapDeadline,
    uint256 _chainlinkMaxRateTimespan
  )
    external
  {
    require(
      _uniswapPath[_uniswapPath.length-1] == _chainlinkPath[_chainlinkPath.length-1],
      "the requested token on uniswap must be the payment currency");

    // Get the amount to pay in paymentNetworkToken
    uint256 paymentNetworkTotalAmount = getConversion(_chainlinkPath, _requestAmount, _requestFeeAmount);

    require(
      IERC20(_uniswapPath[0]).safeTransferFrom(msg.sender, address(this), _amountInMax),
      "Could not transfer payment token from swapper-payer");

    swapRouter.swapTokensForExactTokens(
      paymentNetworkTotalAmount,
      _amountInMax,
      _uniswapPath,
      address(this),
      _uniswapDeadline
    );

    // Pay the request and fees
    paymentProxy.transferFromWithReferenceAndFee(
      _to,
      _requestAmount,
      _chainlinkPath,
      _paymentReference,
      _requestFeeAmount,
      _feeAddress,
      paymentNetworkTotalAmount, // _maxToSpend
      _chainlinkMaxRateTimespan
    );

    // Give the change back to the payer, in both currencies (only spent token should remain)
    if (IERC20(_uniswapPath[0]).balanceOf(address(this)) > 0) {
      IERC20(_uniswapPath[0]).safeTransfer(msg.sender, IERC20(_uniswapPath[0]).balanceOf(address(this)));
    }
    if (IERC20(_uniswapPath[_uniswapPath.length-1]).balanceOf(address(this)) > 0) {
      IERC20(_uniswapPath[0]).safeTransfer(msg.sender, IERC20(_uniswapPath[0]).balanceOf(address(this)));
    }
  }

 /**
  * @notice Authorizes the proxy to spend a new request currency (ERC20).
  * @param _erc20Address Address of an ERC20 used as a request currency
  */
  function approvePaymentProxyToSpend(address _erc20Address) public {
    IERC20 erc20 = IERC20(_erc20Address);
    uint256 max = 2**256 - 1;
    erc20.safeApprove(address(paymentProxy), max);
  }

 /**
  * @notice Authorizes the swap router to spend a new payment currency (ERC20).
  * @param _erc20Address Address of an ERC20 used for payment
  */
  function approveRouterToSpend(address _erc20Address) public {
    IERC20 erc20 = IERC20(_erc20Address);
    uint256 max = 2**256 - 1;
    erc20.safeApprove(address(swapRouter), max);
  }

  /*
  * Admin functions to edit the admin, router address or proxy address
  */
  function setPaymentProxy(address _paymentProxyAddress) public onlyOwner {
    paymentProxy = Erc20ConversionProxy(_paymentProxyAddress);
    chainlinkConversionPath = ChainlinkConversionPath(paymentProxy.chainlinkConversionPath());
  }

  function setRouter(address _newSwapRouterAddress) public onlyOwner {
    swapRouter = IUniswapV2Router02(_newSwapRouterAddress);
  }

  /*
  * Internal functions to reduce the stack in swapTransferWithReference()
  */
  function getConversion(
    address[] memory _path,
    uint256 _requestAmount,
    uint256 _requestFeeAmount
  )
    internal
    view
    returns (uint256 conversion)
  {
    (conversion, ) = chainlinkConversionPath.getConversion(_requestAmount + _requestFeeAmount, _path);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title SafeERC20
 * @notice Works around implementations of ERC20 with transferFrom not returning success status.
 */
library SafeERC20 {

  /**
   * @notice Call transferFrom ERC20 function and validates the return data of a ERC20 contract call.
   * @dev This is necessary because of non-standard ERC20 tokens that don't have a return value.
   * @return result The return value of the ERC20 call, returning true for non-standard tokens
   */
  function safeTransferFrom(
    IERC20  _token,
    address _from,
    address _to,
    uint256 _amount
  ) internal returns (bool result)
  {
    // solium-disable-next-line security/no-low-level-calls
    (bool success, bytes memory data) = address(_token).call(abi.encodeWithSignature(
      "transferFrom(address,address,uint256)",
      _from,
      _to,
      _amount
    ));

    return success && (data.length == 0 || abi.decode(data, (bool)));
  }

  /**
   * @notice Call approve ERC20 function and validates the return data of a ERC20 contract call.
   * @dev This is necessary because of non-standard ERC20 tokens that don't have a return value.
   * @return result The return value of the ERC20 call, returning true for non-standard tokens
   */
  function safeApprove(IERC20 _token, address _spender, uint256 _amount) internal returns (bool result) {
    // solium-disable-next-line security/no-low-level-calls
    (bool success, bytes memory data) = address(_token).call(abi.encodeWithSignature(
      "approve(address,uint256)",
      _spender,
      _amount
    ));

    return success && (data.length == 0 || abi.decode(data, (bool)));
  }

  /**
   * @notice Call transfer ERC20 function and validates the return data of a ERC20 contract call.
   * @dev This is necessary because of non-standard ERC20 tokens that don't have a return value.
   * @return result The return value of the ERC20 call, returning true for non-standard tokens
   */
  function safeTransfer(IERC20 _token, address _to, uint256 _amount) internal  returns (bool result) {
    // solium-disable-next-line security/no-low-level-calls
    (bool success, bytes memory data) = address(_token).call(abi.encodeWithSignature(
      "transfer(address,uint256)",
      _to,
      _amount
    ));

    return success && (data.length == 0 || abi.decode(data, (bool)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ChainlinkConversionPath.sol";
import "./interfaces/ERC20FeeProxy.sol";


/**
 * @title Erc20ConversionProxy
 * @notice This contract convert from chainlink then swaps ERC20 tokens
 *         before paying a request thanks to a conversion payment proxy
  */
contract Erc20ConversionProxy {
  address public paymentProxy;
  ChainlinkConversionPath public chainlinkConversionPath;

  constructor(address _paymentProxyAddress, address _chainlinkConversionPathAddress) {
    paymentProxy = _paymentProxyAddress;
    chainlinkConversionPath = ChainlinkConversionPath(_chainlinkConversionPathAddress);
  }

  // Event to declare a conversion with a reference
  event TransferWithConversionAndReference(
    uint256 amount,
    address currency,
    bytes indexed paymentReference,
    uint256 feeAmount,
    uint256 maxRateTimespan
  );
  
  // Event to declare a transfer with a reference
  event TransferWithReferenceAndFee(
    address tokenAddress,
    address to,
    uint256 amount,
    bytes indexed paymentReference,
    uint256 feeAmount,
    address feeAddress
  );

  /**
   * @notice Performs an ERC20 token transfer with a reference computing the payment amount based on the request amount
   * @param _to Transfer recipient of the payement
   * @param _requestAmount Request amount
   * @param _path Conversion path
   * @param _paymentReference Reference of the payment related
   * @param _feeAmount The amount of the payment fee
   * @param _feeAddress The fee recipient
   * @param _maxToSpend Amount max that we can spend on the behalf of the user
   * @param _maxRateTimespan Max time span with the oldestrate, ignored if zero
   */
  function transferFromWithReferenceAndFee(
    address _to,
    uint256 _requestAmount,
    address[] calldata _path,
    bytes calldata _paymentReference,
    uint256 _feeAmount,
    address _feeAddress,
    uint256 _maxToSpend,
    uint256 _maxRateTimespan
  )
  external
  {
    (uint256 amountToPay, uint256 amountToPayInFees) = getConversions(
      _path,
      _requestAmount,
      _feeAmount,
      _maxRateTimespan);

    require(
      amountToPay + amountToPayInFees <= _maxToSpend,
      "Amount to pay is over the user limit"
    );

    // Pay the request and fees
    (bool status, ) = paymentProxy.delegatecall(
      abi.encodeWithSignature(
        "transferFromWithReferenceAndFee(address,address,uint256,bytes,uint256,address)",
        // payment currency
        _path[_path.length - 1],
        _to,
        amountToPay,
        _paymentReference,
        amountToPayInFees,
        _feeAddress
      )
    );
    require(status, "transferFromWithReferenceAndFee failed");

    // Event to declare a transfer with a reference
    emit TransferWithConversionAndReference(
      _requestAmount,
      // request currency
      _path[0],
      _paymentReference,
      _feeAmount,
      _maxRateTimespan
    );
  }

  function getConversions(
    address[] memory _path,
    uint256 _requestAmount,
    uint256 _feeAmount,
    uint256 _maxRateTimespan
  )
    internal
    view
    returns (uint256 amountToPay, uint256 amountToPayInFees)
  {
    (uint256 rate, uint256 oldestTimestampRate, uint256 decimals) = chainlinkConversionPath.getRate(_path);

    // Check rate timespan
    require(
      _maxRateTimespan == 0 || block.timestamp - oldestTimestampRate <= _maxRateTimespan,
      "aggregator rate is outdated"
    );

    // Get the amount to pay in the crypto currency chosen
    amountToPay = (_requestAmount * rate) / decimals;
    amountToPayInFees = (_feeAmount * rate) /decimals;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./legacy_openzeppelin/contracts/access/roles/WhitelistAdminRole.sol";

interface ERC20fraction {
  function decimals() external view returns (uint8);
}

interface AggregatorFraction {
  function decimals() external view returns (uint8);
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
}


/**
 * @title ChainlinkConversionPath
 *
 * @notice ChainlinkConversionPath is a contract computing currency conversion rates based on Chainlink aggretators
 */
contract ChainlinkConversionPath is WhitelistAdminRole {
  uint constant DECIMALS = 1e18;

  // Mapping of Chainlink aggregators (input currency => output currency => contract address)
  // input & output currencies are the addresses of the ERC20 contracts OR the sha3("currency code")
  mapping(address => mapping(address => address)) public allAggregators;

  // declare a new aggregator
  event AggregatorUpdated(address _input, address _output, address _aggregator);

  /**
    * @notice Update an aggregator
    * @param _input address representing the input currency
    * @param _output address representing the output currency
    * @param _aggregator address of the aggregator contract
  */
  function updateAggregator(address _input, address _output, address _aggregator)
    external
    onlyWhitelistAdmin
  {
    allAggregators[_input][_output] = _aggregator;
    emit AggregatorUpdated(_input, _output, _aggregator);
  }

  /**
    * @notice Update a list of aggregators
    * @param _inputs list of addresses representing the input currencies
    * @param _outputs list of addresses representing the output currencies
    * @param _aggregators list of addresses of the aggregator contracts
  */
  function updateAggregatorsList(
    address[] calldata _inputs,
    address[] calldata _outputs,
    address[] calldata _aggregators
  )
    external
    onlyWhitelistAdmin
  {
    require(_inputs.length == _outputs.length, "arrays must have the same length");
    require(_inputs.length == _aggregators.length, "arrays must have the same length");

    // For every conversions of the path
    for (uint i; i < _inputs.length; i++) {
      allAggregators[_inputs[i]][_outputs[i]] = _aggregators[i];
      emit AggregatorUpdated(_inputs[i], _outputs[i], _aggregators[i]);
    }
  }

  /**
  * @notice Computes the conversion of an amount through a list of intermediate conversions
  * @param _amountIn Amount to convert
  * @param _path List of addresses representing the currencies for the intermediate conversions
  * @return result The result after all the conversions
  * @return oldestRateTimestamp The oldest timestamp of the path
  */
  function getConversion(
    uint256 _amountIn,
    address[] calldata _path
  )
    external
    view
    returns (uint256 result, uint256 oldestRateTimestamp)
  {
    (uint256 rate, uint256 timestamp, uint256 decimals) = getRate(_path);

    // initialize the result
    result = (_amountIn * rate) / decimals;

    oldestRateTimestamp = timestamp;
  }

  /**
  * @notice Computes the conversion rate from a list of currencies
  * @param _path List of addresses representing the currencies for the conversions
  * @return rate The rate
  * @return oldestRateTimestamp The oldest timestamp of the path
  * @return decimals of the conversion rate
  */
  function getRate(
    address[] memory _path
  )
    public
    view
    returns (uint256 rate, uint256 oldestRateTimestamp, uint256 decimals)
  {
    // initialize the result with 18 decimals (for more precision)
    rate = DECIMALS;
    decimals = DECIMALS;
    oldestRateTimestamp = block.timestamp;

    // For every conversion of the path
    for (uint i; i < _path.length - 1; i++) {
      (
        AggregatorFraction aggregator,
        bool reverseAggregator,
        uint256 decimalsInput,
        uint256 decimalsOutput
      ) = getAggregatorAndDecimals(_path[i], _path[i + 1]);

      // store the latest timestamp of the path
      uint256 currentTimestamp = aggregator.latestTimestamp();
      if (currentTimestamp < oldestRateTimestamp) {
        oldestRateTimestamp = currentTimestamp;
      }

      // get the rate of the current step
      uint256 currentRate = uint256(aggregator.latestAnswer());
      // get the number of decimals of the current rate
      uint256 decimalsAggregator = uint256(aggregator.decimals());

      // mul with the difference of decimals before the current rate computation (for more precision)
      if (decimalsAggregator > decimalsInput) {
        rate = rate * (10**(decimalsAggregator-decimalsInput));
      }
      if (decimalsAggregator < decimalsOutput) {
        rate = rate * (10**(decimalsOutput-decimalsAggregator));
      }

      // Apply the current rate (if path uses an aggregator in the reverse way, div instead of mul)
      if (reverseAggregator) {
        rate = rate * (10**decimalsAggregator) / currentRate;
      } else {
        rate = rate * currentRate / (10**decimalsAggregator);
      }

      // div with the difference of decimals AFTER the current rate computation (for more precision)
      if (decimalsAggregator < decimalsInput) {
        rate = rate / (10**(decimalsInput-decimalsAggregator));
      }
      if (decimalsAggregator > decimalsOutput) {
        rate = rate / (10**(decimalsAggregator-decimalsOutput));
      }
    }
  }

  /**
  * @notice Gets aggregators and decimals of two currencies
  * @param _input input Address
  * @param _output output Address
  * @return aggregator to get the rate between the two currencies
  * @return reverseAggregator true if the aggregator returned give the rate from _output to _input
  * @return decimalsInput decimals of _input
  * @return decimalsOutput decimals of _output
  */
  function getAggregatorAndDecimals(address _input, address _output)
    private
    view
    returns (AggregatorFraction aggregator, bool reverseAggregator, uint256 decimalsInput, uint256 decimalsOutput)
  {
    // Try to get the right aggregator for the conversion
    aggregator = AggregatorFraction(allAggregators[_input][_output]);
    reverseAggregator = false;

    // if no aggregator found we try to find an aggregator in the reverse way
    if (address(aggregator) == address(0x00)) {
      aggregator = AggregatorFraction(allAggregators[_output][_input]);
      reverseAggregator = true;
    }

    require(address(aggregator) != address(0x00), "No aggregator found");

    // get the decimals for the two currencies
    decimalsInput = getDecimals(_input);
    decimalsOutput = getDecimals(_output);
  }

  /**
  * @notice Gets decimals from an address currency
  * @param _addr address to check
  * @return decimals number of decimals
  */
  function getDecimals(address _addr)
    private
    view
    returns (uint256 decimals)
  {
    // by default we assume it is FIAT so 8 decimals
    decimals = 8;
    // if address is the hash of the ETH currency
    if (_addr == address(0xF5AF88e117747e87fC5929F2ff87221B1447652E)) {
      decimals = 18;
    } else if (isContract(_addr)) {
      // otherwise, we get the decimals from the erc20 directly
      decimals = ERC20fraction(_addr).decimals();
    }
  }

  /**
  * @notice Checks if an address is a contract
  * @param _addr Address to check
  * @return true if the address hosts a contract, false otherwise
  */
  function isContract(address _addr)
    private
    view
    returns (bool)
  {
    uint32 size;
    // solium-disable security/no-inline-assembly
    assembly {
      size := extcodesize(_addr)
    }
    return (size > 0);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20FeeProxy {
  event TransferWithReferenceAndFee(
    address tokenAddress,
    address to,
    uint256 amount,
    bytes indexed paymentReference,
    uint256 feeAmount,
    address feeAddress
  );

  function transferFromWithReferenceAndFee(
    address _tokenAddress,
    address _to,
    uint256 _amount,
    bytes calldata _paymentReference,
    uint256 _feeAmount,
    address _feeAddress
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import "../Roles.sol";

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
abstract contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}