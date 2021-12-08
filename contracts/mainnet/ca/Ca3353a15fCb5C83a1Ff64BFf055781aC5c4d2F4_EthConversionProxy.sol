// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ChainlinkConversionPath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 * @title EthConversionProxy
 * @notice This contract converts from chainlink then swaps ETH (or native token)
 *         before paying a request thanks to a conversion payment proxy.
 *         The inheritance from ReentrancyGuard is required to perform
 *         "transferExactEthWithReferenceAndFee" on the eth-fee-proxy contract
 */
contract EthConversionProxy is ReentrancyGuard {
    address public paymentProxy;
    ChainlinkConversionPath public chainlinkConversionPath;
    address public nativeTokenHash;

    constructor(
        address _paymentProxyAddress,
        address _chainlinkConversionPathAddress,
        address _nativeTokenHash
    ) {
        paymentProxy = _paymentProxyAddress;
        chainlinkConversionPath = ChainlinkConversionPath(_chainlinkConversionPathAddress);
        nativeTokenHash = _nativeTokenHash;
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
    // This event is emitted by this contract from a delegate call of the payment-proxy
    event TransferWithReferenceAndFee(
        address to,
        uint256 amount,
        bytes indexed paymentReference,
        uint256 feeAmount,
        address feeAddress
    );

    /**
     * @notice Performs an ETH transfer with a reference computing the payment amount based on the request amount
     * @param _to Transfer recipient of the payement
     * @param _requestAmount Request amount
     * @param _path Conversion path
     * @param _paymentReference Reference of the payment related
     * @param _feeAmount The amount of the payment fee
     * @param _feeAddress The fee recipient
     * @param _maxRateTimespan Max time span with the oldestrate, ignored if zero
     */
    function transferWithReferenceAndFee(
        address _to,
        uint256 _requestAmount,
        address[] calldata _path,
        bytes calldata _paymentReference,
        uint256 _feeAmount,
        address _feeAddress,
        uint256 _maxRateTimespan
    ) external payable {
        require(
            _path[_path.length - 1] == nativeTokenHash,
            'payment currency must be the native token'
        );

        (uint256 amountToPay, uint256 amountToPayInFees) = getConversions(
            _path,
            _requestAmount,
            _feeAmount,
            _maxRateTimespan
        );

        // Pay the request and fees
        (bool status, ) = paymentProxy.delegatecall(
            abi.encodeWithSignature(
                'transferExactEthWithReferenceAndFee(address,uint256,bytes,uint256,address)',
                _to,
                amountToPay,
                _paymentReference,
                amountToPayInFees,
                _feeAddress
            )
        );

        require(status, 'paymentProxy transferExactEthWithReferenceAndFee failed');

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
    ) internal view returns (uint256 amountToPay, uint256 amountToPayInFees) {
        (uint256 rate, uint256 oldestTimestampRate, uint256 decimals) = chainlinkConversionPath
            .getRate(_path);

        // Check rate timespan
        require(
            _maxRateTimespan == 0 || block.timestamp - oldestTimestampRate <= _maxRateTimespan,
            'aggregator rate is outdated'
        );

        // Get the amount to pay in the native token
        amountToPay = (_requestAmount * rate) / decimals;
        amountToPayInFees = (_feeAmount * rate) / decimals;
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
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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