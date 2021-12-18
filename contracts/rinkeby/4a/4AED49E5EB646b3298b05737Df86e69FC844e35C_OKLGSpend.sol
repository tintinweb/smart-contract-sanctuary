// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import './interfaces/IOKLGSpend.sol';
import './OKLGWithdrawable.sol';

/**
 * @title OKLGSpend
 * @dev Logic for spending OKLG on products in the product ecosystem.
 */
contract OKLGSpend is IOKLGSpend, OKLGWithdrawable {
  address payable private constant _deadWallet =
    payable(0x000000000000000000000000000000000000dEaD);
  address payable public paymentWallet =
    payable(0x000000000000000000000000000000000000dEaD);

  AggregatorV3Interface internal priceFeed;

  uint256 public totalSpentWei = 0;
  mapping(uint8 => uint256) public defaultProductPriceUSD;
  mapping(address => uint256) public overrideProductPriceUSD;
  mapping(address => bool) public removeCost;
  event Spend(address indexed user, address indexed product, uint256 value);

  constructor(address _linkPriceFeedContract) {
    // https://docs.chain.link/docs/reference-contracts/
    // https://github.com/pcaversaccio/chainlink-price-feed/blob/main/README.md
    priceFeed = AggregatorV3Interface(_linkPriceFeedContract);
  }

  function getProductCostWei(uint256 _productCostUSD)
    public
    view
    returns (uint256)
  {
    // Creates a USD balance with 18 decimals
    uint256 paymentUSD18 = 10**18 * _productCostUSD;

    // adding back 18 decimals to get returned value in wei
    return (10**18 * paymentUSD18) / getLatestETHPrice();
  }

  /**
   * Returns the latest ETH/USD price with returned value at 18 decimals
   * https://docs.chain.link/docs/get-the-latest-price/
   */
  function getLatestETHPrice() public view returns (uint256) {
    uint8 decimals = priceFeed.decimals();
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price) * (10**18 / 10**decimals);
  }

  function setPriceFeed(address _feedContract) external onlyOwner {
    priceFeed = AggregatorV3Interface(_feedContract);
  }

  function setPaymentWallet(address _newPaymentWallet) external onlyOwner {
    paymentWallet = payable(_newPaymentWallet);
  }

  function setDefaultProductUSDPrice(uint8 _product, uint256 _priceUSD)
    external
    onlyOwner
  {
    defaultProductPriceUSD[_product] = _priceUSD;
  }

  function setDefaultProductPricesUSDBulk(
    uint8[] memory _productIds,
    uint256[] memory _pricesUSD
  ) external onlyOwner {
    require(
      _productIds.length == _pricesUSD.length,
      'arrays need to be the same length'
    );
    for (uint256 _i = 0; _i < _productIds.length; _i++) {
      defaultProductPriceUSD[_productIds[_i]] = _pricesUSD[_i];
    }
  }

  function setOverrideProductPriceUSD(address _productCont, uint256 _priceUSD)
    external
    onlyOwner
  {
    overrideProductPriceUSD[_productCont] = _priceUSD;
  }

  function setOverrideProductPricesUSDBulk(
    address[] memory _contracts,
    uint256[] memory _pricesUSD
  ) external onlyOwner {
    require(
      _contracts.length == _pricesUSD.length,
      'arrays need to be the same length'
    );
    for (uint256 _i = 0; _i < _contracts.length; _i++) {
      overrideProductPriceUSD[_contracts[_i]] = _pricesUSD[_i];
    }
  }

  function setRemoveCost(address _productCont, bool _isRemoved)
    external
    onlyOwner
  {
    removeCost[_productCont] = _isRemoved;
  }

  /**
   * spendOnProduct: used by an OKLG product for a user to spend native token on usage of a product
   */
  function spendOnProduct(address _payor, uint8 _product)
    external
    payable
    override
  {
    if (removeCost[msg.sender]) return;

    uint256 _productCostUSD = overrideProductPriceUSD[msg.sender] > 0
      ? overrideProductPriceUSD[msg.sender]
      : defaultProductPriceUSD[_product];
    if (_productCostUSD == 0) return;

    uint256 _productCostWei = getProductCostWei(_productCostUSD);

    require(
      msg.value >= _productCostWei,
      'not enough ETH sent to pay for product'
    );
    address payable _paymentWallet = paymentWallet == _deadWallet ||
      paymentWallet == address(0)
      ? payable(owner())
      : paymentWallet;
    _paymentWallet.call{ value: _productCostWei }('');
    totalSpentWei += _productCostWei;
    emit Spend(msg.sender, _payor, _productCostWei);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title IOKLGSpend
 * @dev Logic for spending OKLG on products in the product ecosystem.
 */
interface IOKLGSpend {
  function spendOnProduct(address _payor, uint8 _product) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

/**
 * @title OKLGWithdrawable
 * @dev Supports being able to get tokens or ETH out of a contract with ease
 */
contract OKLGWithdrawable is Ownable {
  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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