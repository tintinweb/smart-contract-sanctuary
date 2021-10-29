/**
 *Submitted for verification at polygonscan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

// File: contracts/access/Owned.sol
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
// File: contracts/utils/DecimalMath.sol
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
// File: contracts/interfaces/IERC20.sol
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
// File: contracts/interfaces/IUniswapV2Pair.sol
interface IUniswapV2Pair {
  function getReserves()
  external view
  returns (
    uint112 reserve0,
    uint112 reserve1,
    uint32 blockTimestampLast
  );
}
// File: contracts/Payer.sol
contract Payer is Owned {
  using DecimalMath for uint;
  IERC20 altcoin;
  IUniswapV2Pair pair;
  uint public tokenPrice;  // Single NFT Price by ETH
  // 18 decimal float number (float * 10 *18)
  // If it is 20% discount, its value is 2 * 10**17
  uint public altcoinDiscount;
  bool public altcoinDisabled;
  address public WETH = 0x9140243B6572728A142f3e26F9De52F21Be8155f;
  address vault;
  event AltcoinUpdated(address altcoin);
  event TokenPairUpdated(address pair);
  event TokenPriceUpdated(uint price);
  event DiscountRateUpdated(uint discountRate);
  event AltcoinPaymentStatusUpdated(bool status);
  constructor(
    IERC20 _altcoin,
    IUniswapV2Pair _pair,
    uint _tokenPrice,
    uint _altcoinDiscount,
    address _vault,
    address _owner
  ) Owned(_owner) {
    _setAltcoin(_altcoin);
    _setTokenPair(_pair);
    _setTokenPrice(_tokenPrice);
    _setDiscount(_altcoinDiscount);
    _setVault(_vault);
  }
  function setWrappedBaseCurrency(address _newCurrency)
  external
  onlyOwner {
    WETH = _newCurrency;
  }
  function setAltcoin(IERC20 _newAltcoinAddress)
  external
  onlyOwner {
    _setAltcoin(_newAltcoinAddress);
  }
  function setTokenPair(IUniswapV2Pair _newTokenPair)
  external
  onlyOwner {
    _setTokenPair(_newTokenPair);
  }
  function setTokenPrice(uint _price)
  external
  onlyOwner {
    _setTokenPrice(_price);
  }
  function setDiscount(uint _discount)
  external
  onlyOwner {
    _setDiscount(_discount);
  }
  function setVault(address _newVault)
  external
  onlyOwner {
    _setVault(_newVault);
  }
  function setAltcoinDisabled(bool _disable)
  external
  onlyOwner {
    altcoinDisabled = _disable;
    emit AltcoinPaymentStatusUpdated(_disable);
  }
  /** VIEW **/
  /**
   * @notice It returns the token exchange rate [alt/eth]
   */
  function getExchangeRate()
  external view
  returns(uint) {
    return _getExchangeRate();
  }
  /**
   * @notice It returns the token price in altcoin with discount applied.
   */
  function getAltcoinPrice()
  external view
  returns(uint) {
    return _getAltcoinPrice();
  }
  /** INTERNAL **/
  function _setAltcoin(IERC20 _newAltcoinAddress)
  internal {
    altcoin = _newAltcoinAddress;
    emit AltcoinUpdated(address(_newAltcoinAddress));
  }
  function _setTokenPair(IUniswapV2Pair _newTokenPair)
  internal {
    pair = _newTokenPair;
    emit TokenPairUpdated(address(_newTokenPair));
  }
  function _setTokenPrice(uint _price)
  internal {
    tokenPrice = _price;
    emit TokenPriceUpdated(_price);
  }
  function _setDiscount(uint _discount)
  internal {
    require(_discount >= 0 && _discount < 10**18,
      "Invalid input value");
    altcoinDiscount = _discount;
    emit DiscountRateUpdated(_discount);
  }
  function _setVault(address _newVault)
  internal {
    require(_newVault != address(0),
      "Empty address is not allowed");
    vault = _newVault;
  }
  function _ethereumPayment(uint _numberOfMint)
  internal
  returns(bool) {
    require(msg.value == tokenPrice * _numberOfMint,
      "Paying amount is not correct");
    (bool sent, ) = vault.call{ value: msg.value }("");
    return sent;
  }
  function _altPayment(address _buyer, uint _numberOfMint)
  internal
  returns(bool) {
    require(!altcoinDisabled,
      "Altcoin payment is not supported");
    uint altcoinPrice = _getAltcoinPrice();
    return altcoin.transferFrom(_buyer, vault, altcoinPrice * _numberOfMint);
  }
  /**
   * @notice It calculates exchange rate [Altcoin/Eth]
   */
  function _getExchangeRate()
  internal view
  returns(uint) {
    (uint112 _reserveA, uint112 _reserveB, ) = pair.getReserves();
    (address a, ) = _sortTokens(WETH, address(altcoin));
    (uint256 reserveA, uint256 reserveB) = (uint256(_reserveA), uint256(_reserveB));
    return a == WETH ? reserveB.divideDecimal(reserveA) : reserveA.divideDecimal(reserveB);
  }
  function _getAltcoinPrice()
  internal view
  returns(uint) {
    return tokenPrice.multiplyDecimal(_getExchangeRate()).multiplyDecimal(10**18 - altcoinDiscount);
  }
  function _sortTokens(address _tokenA, address _tokenB)
  internal pure
  returns (address token0, address token1) {
    require(_tokenA != _tokenB, 'Identical address');
    (token0, token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
    require(token0 != address(0), "address is zero");
  }
}
// File: contracts/interfaces/IDogepunk.sol
interface IDogepunk {
  function mint(address minter, uint numOfMint) external;
}
// File: contracts/Seller.sol
contract Seller is Payer {
  IDogepunk dogepunk;
  uint32 public mintStartTime;
  bool public systemSuspended;
  event SystemStatusUpdated(bool suspended);
  event MintStartTimeUpdated(uint32 startTime);
  constructor(
    IDogepunk _dogepunk,
    IERC20 _altCoin,
    IUniswapV2Pair _pair,
    uint _tokenPrice,
    uint _altCoinDiscount,
    uint32 _mintStartTime,
    address _vault,
    address _owner
  ) Payer(
    _altCoin,
    _pair,
    _tokenPrice,
    _altCoinDiscount,
    _vault,
    _owner
  ) {
    dogepunk = _dogepunk;
    _setStartTime(_mintStartTime);
  }
  function setSystemSuspension(bool _suspended)
  external
  onlyOwner {
    systemSuspended = _suspended;
    emit SystemStatusUpdated(_suspended);
  }
  function setStartTime(uint32 _newMintStartTime)
  external
  onlyOwner {
    _setStartTime(_newMintStartTime);
  }
  function mint(uint _numOfMint, bool _ethPayment)
  external payable
  isSuspended {
    require(mintStartTime != 0 && mintStartTime <= block.timestamp,
      "Mint is not started yet");
    if(_ethPayment) {
      require(_ethereumPayment(_numOfMint),
        "Ethereum Payment: failed");
    } else {
      require(_altPayment(msg.sender, _numOfMint),
        "Altcoin Payment: failed");
    }
    dogepunk.mint(msg.sender, _numOfMint);
  }
  function _setStartTime(uint32 _newMintStartTime)
  internal {
    mintStartTime = _newMintStartTime;
    emit MintStartTimeUpdated(_newMintStartTime);
  }
  modifier isSuspended {
    require(!systemSuspended,
      "System is suspended");
    _;
  }
}