/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Owned {

    address public owner;
    address public nominatedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnerNominated(address indexed newOwner);

    constructor(address _owner) {
        require(_owner != address(0),
            "Address cannot be 0");

        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    function nominateNewOwner(address _owner)
    external
    onlyOwner {
        nominatedOwner = _owner;

        emit OwnerNominated(_owner);
    }

    function acceptOwnership()
    external {
        require(msg.sender == nominatedOwner,
            "You must be nominated before you can accept ownership");

        emit OwnershipTransferred(owner, nominatedOwner);

        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner,
            "Only the contract owner may perform this action");
        _;
    }

}



pragma solidity 0.8.7;

library DecimalMath {

    uint public constant decimals = 18;
    uint public constant UNIT = 10**uint(decimals);

    function unit() external pure returns (uint) {
        return UNIT;
    }

    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        return x * y / UNIT;
    }

    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        uint quotientTimesTen = x * y / (UNIT / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        return x * UNIT / y;
    }

    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        uint resultTimesTen = x * (UNIT * 10) / y;

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

}



pragma solidity 0.8.7;

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



pragma solidity 0.8.7;

interface IUniswapV2Pair {

  function getReserves()
  external view
  returns (
    uint112 reserve0,
    uint112 reserve1,
    uint32 blockTimestampLast
  );

}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );

  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]
pragma solidity ^0.8.0;


interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}




pragma solidity 0.8.7;

interface IExchangeRates {

  function aggregators(bytes32 _currencyKey)
  external view
  returns(AggregatorV2V3Interface);

  function rateAndUpdatedTime(bytes32 _currencyKey)
  external view
  returns(uint rate, uint time);

  function rateAndInvalid(bytes32 _currencyKey)
  external view
  returns (uint rate, bool isInvalid);

}



pragma solidity 0.8.7;




contract Payer is Owned {

  using DecimalMath for uint;

  IExchangeRates public exchangeRates;

  struct AltCurrency {
    address currencyAddress;
    // It has 4 deicmals precision. (It regards 10^4 as a unit. 0.2(20%) will be 2 * 10^3)
    // It will converted to uint256 when it is used for caculation.
    // With 20% discount, it will be converted to 2 * 10^17.
    uint16 discountRate;
    uint8 decimals;
    bool aggregatorSupport;  // It uses aggregator for exchange rate
    bool paySupport;
  }

  mapping(bytes32 => AltCurrency) public altCurrencies;

  mapping(bytes32 => IUniswapV2Pair) public pairs;

  bytes32 constant internal WETH = "WETH";
  bytes32 constant internal ETH = "ETH";
  address public WETH_ADDRESS = 0x9140243B6572728A142f3e26F9De52F21Be8155f;

  address public vault;

  uint public tokenPrice = 4 * 10**16;  // Token price [ETH]

  uint public whitelistDiscount = 3 * 10**17; // if 30% discount, it should be 0.3 * 10^18

  event TokenPriceUpdated(uint newPrice);
  event WhitelistDiscountUpdated(uint newWhitelistDiscount);
  event DiscountRateUpdated(bytes32 currencyKey, uint16 updatedDiscountRate);
  event AggregatorSupportUpdated(bytes32 currencyKey, bool updatedAggregatorSupport);
  event CurrencyPaySupportUpdated(bytes32 currencyKey, bool updatedPaySupport);
  event PaymentFulfilled(bytes32 currencyKey, uint amount, uint numberOfMint);

  constructor(
    address _exchangeRates,
    address _vault,
    address _owner
  ) Owned(_owner) {
    require(_vault != address(0),
      "Vault cannot be empty");

    altCurrencies[ETH].paySupport = true;
    vault = _vault;
    exchangeRates = IExchangeRates(_exchangeRates);
  }

  /** EXCLUSIVE **/

  function setNewVault(address _newVault)
  external
  onlyOwner {
    require(_newVault != address(0),
      "vault cannot be empty");

    vault = _newVault;
  }

  function setTokenPrice(uint _newTokenPrice)
  external
  onlyOwner {
    tokenPrice = _newTokenPrice;

    emit TokenPriceUpdated(_newTokenPrice);
  }

  function setWhitelistDiscount(uint _newWhitelistDiscount)
  external
  onlyOwner {
    require(_newWhitelistDiscount <= 10**18,
      "discount rate is out of bounds");

    whitelistDiscount = _newWhitelistDiscount;

    emit WhitelistDiscountUpdated(_newWhitelistDiscount);
  }

  /**
   * @dev The wrapped base currency is constructing pair with paying currency.
   */
  function setWrappedBaseCurrency(address _newAddress)
  external
  onlyOwner {
    WETH_ADDRESS = _newAddress;
  }

  function setExchangeRates(IExchangeRates _newExchangeRates)
  external
  onlyOwner {
    exchangeRates = _newExchangeRates;
  }

  function setAltCurrencies(
    bytes32[] calldata _currencyKeys,
    address[] calldata _altcoinAddresses,
    uint16[] calldata _discountRates,
    uint8[] calldata _decimals,
    bool[] calldata _aggregatorSupports
  ) external
  onlyOwner {
    require(
      _currencyKeys.length == _altcoinAddresses.length &&
      _currencyKeys.length == _discountRates.length &&
      _currencyKeys.length == _decimals.length &&
      _currencyKeys.length == _aggregatorSupports.length,
      "Input lengths not matched"
    );

    for(uint i = 0; i < _currencyKeys.length; i++) {
      _setAltCurrencies(
        _currencyKeys[i],
        _altcoinAddresses[i],
        _discountRates[i],
        _decimals[i],
        _aggregatorSupports[i],
        true
      );
    }
  }

  function removeAltCurrency(bytes32 _currencyKey)
  external
  onlyOwner {
    delete altCurrencies[_currencyKey];
  }

  function setPairAddress(bytes32 _currencyKey, address _pairAddress)
  external
  onlyOwner {
    pairs[_currencyKey] = IUniswapV2Pair(_pairAddress);
  }

  function setPaymentStatus(bytes32 _currencyKey, bool _status)
  external
  onlyOwner {
    // Yet ETH is not treated as alt currency, it uses AltCurrency structure for managing pay support
    altCurrencies[_currencyKey].paySupport = _status;

    emit CurrencyPaySupportUpdated(_currencyKey, _status);
  }

  function changeDiscountRate(bytes32 _currencyKey, uint16 _newDiscountRate)
  external
  onlyOwner {
    AltCurrency memory _altCurrency = _currencyKeyRegistered(_currencyKey);

    _shouldInDiscountRateLimit(_newDiscountRate);

    _altCurrency.discountRate = _newDiscountRate;

    altCurrencies[_currencyKey] = _altCurrency;

    emit DiscountRateUpdated(_currencyKey, _newDiscountRate);
  }

  function changeAggregatorSupport(bytes32 _currencyKey, bool _aggregatorSupport)
  external
  onlyOwner {
    AltCurrency memory _altCurrency = _currencyKeyRegistered(_currencyKey);

    if(!_aggregatorSupport) {
      _shouldHavePair(_currencyKey);
    } else {
      _shouldHaveAggregator(_currencyKey);
    }

    _altCurrency.aggregatorSupport = _aggregatorSupport;

    altCurrencies[_currencyKey] = _altCurrency;

    emit AggregatorSupportUpdated(_currencyKey, _aggregatorSupport);
  }

  function _payment(
    address _payer,
    uint _numberOfMint,
    bytes32 _currencyKey,
    bool _whitelist
  ) internal
  returns(bool payed) {
    // Whitelist is paying only with ETH
    if(_whitelist || _currencyKey == ETH) {
      require(altCurrencies[_currencyKey].paySupport,
        "ETH payment is not supported");
      if(_whitelist) {
        require(msg.value == tokenPrice.multiplyDecimal(10**18 - whitelistDiscount) * _numberOfMint,
          "Paying amount is not correct");
      } else {
        require(msg.value == tokenPrice * _numberOfMint,
          "Paying amount is not correct");
      }

      (bool _payed, ) = vault.call{ value: msg.value }("");

      payed = _payed;

      if(payed) {
        emit PaymentFulfilled(_currencyKey, msg.value, _numberOfMint);
      }
    } else {
      AltCurrency memory _altCurrency = _currencyKeyRegistered(_currencyKey);

      require(_altCurrency.paySupport,
        "This currency payment is not supported");

      uint altCurrencyPrice = _getAltCurrencyPrice(
        _currencyKey,
        _altCurrency.currencyAddress,
        _altCurrency.discountRate,
        _altCurrency.aggregatorSupport
      );

      if(altCurrencies[_currencyKey].decimals < 18) {
        altCurrencyPrice = altCurrencyPrice / (10 ** (18 - uint(altCurrencies[_currencyKey].decimals)));
      }

      payed = IERC20(_altCurrency.currencyAddress).transferFrom(_payer, vault, altCurrencyPrice * _numberOfMint);

      emit PaymentFulfilled(_currencyKey, altCurrencyPrice * _numberOfMint, _numberOfMint);
    }
  }


  /** VIEWER **/

  function getAltCurrencyPrice(bytes32 _currencyKey)
  external view
  returns(uint) {
    AltCurrency memory _altCurrency = _currencyKeyRegistered(_currencyKey);

    return _getAltCurrencyPrice(
      _currencyKey,
      _altCurrency.currencyAddress,
      _altCurrency.discountRate,
      _altCurrency.aggregatorSupport
    );
  }

  /**
   * @notice It returns altcoin exchange rates [ALT/ETH]
   */
  function getExchangeRate(bytes32 _currencyKey)
  external view
  returns(uint) {
    AltCurrency memory _altCurrency = _currencyKeyRegistered(_currencyKey);

    return _getExchangeRate(
      _currencyKey,
      _altCurrency.currencyAddress,
      _altCurrency.aggregatorSupport
    );
  }


  /** INTERNAL **/

  function _getAltCurrencyPrice(
    bytes32 _currencyKey,
    address _currencyAddress,
    uint16 _discountRate,
    bool _aggregatorSupport
  ) internal view
  returns(uint price) {
    return tokenPrice
      .multiplyDecimal(_getExchangeRate(_currencyKey, _currencyAddress, _aggregatorSupport))
      .multiplyDecimal(10**18 - (uint(_discountRate) * 10**14));
  }


  function _setAltCurrencies(
    bytes32 _currencyKey,
    address _altcoinAddress,
    uint16 _discountRate,
    uint8 _decimals,
    bool _aggregatorSupport,
    bool _paySupport
  ) internal {
    require(_currencyKey != WETH && _currencyKey != ETH,
      "Basecurrency cannot be altcoin");
    require(_altcoinAddress != address(0),
      "address cannot be empty");
    _shouldInDiscountRateLimit(_discountRate);
    if(!_aggregatorSupport) {
      _shouldHavePair(_currencyKey);
    } else {
      _shouldHaveAggregator(_currencyKey);
    }
    require(_decimals <= 18,
      "given decimals out of bound");

    altCurrencies[_currencyKey] = AltCurrency(
      _altcoinAddress,
      _discountRate,
      _decimals,
      _aggregatorSupport,
      _paySupport
    );
  }

  function _sortTokens(address _tokenA, address _tokenB)
  internal pure
  returns (address token0, address token1) {
    require(_tokenA != _tokenB, 'Identical address');

    (token0, token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);

    require(token0 != address(0), "address is zero");
  }

  /**
   * @notice It calculates exchange rate [Altcoin/Eth]
   */
  function _getExchangeRate(
    bytes32 _currencyKey,
    address _currencyAddress,
    bool _aggregatorSupport
  ) internal view
  returns(uint) {
    if(!_aggregatorSupport) {
      IUniswapV2Pair pair = pairs[_currencyKey];

      require(address(pair) != address(0),
        "Pair is not given");

      (uint112 _reserveA, uint112 _reserveB, ) = pair.getReserves();

      (address a, ) = _sortTokens(WETH_ADDRESS, address(_currencyAddress));
      (uint256 reserveA, uint256 reserveB) = (uint256(_reserveA), uint256(_reserveB));

      return a == WETH_ADDRESS ? reserveB.divideDecimal(reserveA) : reserveA.divideDecimal(reserveB);
    } else {
      (uint ethExRate, bool _ethIsInvalid) = exchangeRates.rateAndInvalid(ETH);
      (uint altExRate, bool _altIsInvalid) = exchangeRates.rateAndInvalid(_currencyKey);

      require(!_ethIsInvalid && !_altIsInvalid,
        "Rate is invalid");

      return altExRate.divideDecimal(ethExRate);
    }
  }

  function _currencyKeyRegistered(bytes32 _currencyKey)
  internal view
  returns(AltCurrency memory) {
    AltCurrency memory _altCurrency = altCurrencies[_currencyKey];
    require(_altCurrency.currencyAddress != address(0),
      "Currency key is not registered");

    return _altCurrency;
  }

  function _shouldInDiscountRateLimit(uint16 _discountRate)
  internal pure {
    require(_discountRate < 10000,
      "given discount rate out of bound");
  }

  function _shouldHavePair(bytes32 _currencyKey)
  internal view {
    require(address(pairs[_currencyKey]) != address(0),
      "Currency doesn't have pair");
  }

  function _shouldHaveAggregator(bytes32 _currencyKey)
  internal view {
    require(address(exchangeRates.aggregators(_currencyKey)) != address(0),
      "Currency doesn't have aggregator");
  }

}



pragma solidity 0.8.7;

contract Seller is Payer {

  mapping(address => uint) public whitePaymentCount;
  mapping(uint64 => address) public idAssignedTo;
  mapping(address => uint) public individualPaymentCount;
  mapping(address => mapping(uint => uint64)) private _ownedTokenIdByIndex;

  uint64 immutable public cap;  // it does not count whitelist payment
  uint64 public nextTokenId = 1;
  uint64 public nextWhitelistTokenId = 10001;
  uint40 immutable public whitelistTimeLimit;
  uint8 public maxNumberOfMint = 10;
  uint8 public maxNumberOfWhitePayment = 2;
  bool public sellingHalted;

  event SellingStatusUpdated(bool newStatus);
  event MaxNumberOfMintUpdated(uint8 newMaxMint);
  event MaxNumberOfWhitePaymentUpdated(uint8 newMaxWhitePayment);
  event TokenRequested(address buyer, uint tokenId);

  constructor(
    uint64 _cap,
    uint40 _whitelistTimeLimit,
    address _exchangeRates,
    address _vault,
    address _owner
  ) Payer(
    _exchangeRates,
    _vault,
    _owner
  ) {
    cap = _cap;
    whitelistTimeLimit = _whitelistTimeLimit;
  }

  function setMaxNumberOfMint(uint8 _newMaxNumOfMint)
  external
  onlyOwner {
    maxNumberOfMint = _newMaxNumOfMint;

    emit MaxNumberOfMintUpdated(_newMaxNumOfMint);
  }

  function setMaxNumberOfWhitePayment(uint8 _newMaxNumberOfWhitePayment)
  external
  onlyOwner {
    maxNumberOfWhitePayment = _newMaxNumberOfWhitePayment;

    emit MaxNumberOfWhitePaymentUpdated(_newMaxNumberOfWhitePayment);
  }

  function setSellingHalted(bool _status)
  external
  onlyOwner {
    sellingHalted = _status;

    emit SellingStatusUpdated(_status);
  }

  function payment(uint8 _numOfMint, bytes32 _payingCurrencyKey)
  external payable
  sellingOn {
    require(_numOfMint <= maxNumberOfMint && _numOfMint > 0,
      "Number of mint is out of bounds");
    require(nextTokenId + _numOfMint <= cap + 1,
      "Trying to mint out of cap");

    require(_payment(msg.sender, _numOfMint, _payingCurrencyKey, false),
      "Payment is failed");

    for(uint8 i = 0; i < _numOfMint; i++) {
      _tokenAssign(msg.sender, false);
    }
  }

  function whitePayment(uint8 _numOfMint)
  external payable
  sellingOn {
    require(block.timestamp <= uint(whitelistTimeLimit),
      "Whitelist promotion is ended");
    require(_numOfMint <= maxNumberOfMint && _numOfMint > 0,
      "Number of mint is out of bounds");
    whitePaymentCount[msg.sender] += _numOfMint;
    require(whitePaymentCount[msg.sender] <= maxNumberOfWhitePayment,
      "Exceeds max number of white payment");

    require(_payment(msg.sender, _numOfMint, ETH, true),
      "Payment is failed");

    for(uint8 i = 0; i < _numOfMint; i++) {
      _tokenAssign(msg.sender, true);
    }
  }

  function ownedTokenIdByIndex(address _tokenOwner, uint _index)
  external view
  returns(uint) {
    require(_index < individualPaymentCount[_tokenOwner],
      "index out of bounds");

    return _ownedTokenIdByIndex[_tokenOwner][_index];
  }

  function getOwnedTokens(
    address _tokenOwner,
    uint _begin,
    uint _end
  ) external view
  returns(uint64[] memory) {
    require(_begin <= _end,
      "beginning index should less or equal to end index");
    require(_end < individualPaymentCount[_tokenOwner],
      "end index is out of bounds");

    uint64[] memory _tokenIds = new uint64[](_end - _begin + 1);
    uint _dataIndex = 0;
    for(uint i = _begin; i <= _end; i++) {
      _tokenIds[_dataIndex] = _ownedTokenIdByIndex[_tokenOwner][i];

      _dataIndex++;
    }

    return _tokenIds;
  }

  function _tokenAssign(address _to, bool _whitelist)
  internal {
    uint64 _tokenId = _whitelist ? nextWhitelistTokenId++ : nextTokenId++;

    idAssignedTo[_tokenId] = _to;
    _ownedTokenIdByIndex[_to][individualPaymentCount[_to]] = _tokenId;
    individualPaymentCount[_to]++;

    emit TokenRequested(_to, _tokenId);
  }

  modifier sellingOn {
    require(!sellingHalted,
      "Selling is halted");
    _;
  }

}