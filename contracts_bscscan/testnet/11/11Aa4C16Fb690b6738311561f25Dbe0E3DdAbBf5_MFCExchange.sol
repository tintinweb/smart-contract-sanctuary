// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./lib/token/BEP20/BEP20.sol";
import "./lib/utils/Context.sol";

contract MFCExchange is Context {

  uint256 public constant EXPIRES_IN = 2592000;
  uint256 public constant MINIMUM_SWAP_IN_BUSD = 100000000000000000000;
  uint256 public constant BUSD_FEE = 20000000000000000;
  uint256 public constant MFC_FEE = 20000000000000000;
  uint256 public constant MULTIPLIER = 10**18;

  address private _busdAddress;
  uint256 private _nonce = 1;
  bytes32 private constant MFC_BUSD = keccak256("MFC_BUSD");
  bytes32 private constant BUSD_MFC = keccak256("BUSD_MFC");

  struct Offer {
    uint256 id;
    bytes32 tradingPair;
    uint256 quantity;
    uint256 price;
    uint256 expiresAt;
    bool isOpen;
  }

  struct TradingPair {
    address makerAssetAddress;
    address takerAssetAddress;
    address makerTreasuryAddress;
    address takerTreasuryAddress;
    uint256 makerFeeRate;
    uint256 takerFeeRate;
  }

  mapping(address => mapping(uint256 => Offer)) private _offers;
  mapping(bytes32 => TradingPair) private _tradingPairs;

  event CreateOffer(uint256 id, address seller, bytes32 tradingPair, uint256 quantity, uint256 price, uint256 expiresAt, uint256 timestamp);
  event TradeOffer(uint256 id, address buyer, uint256 sellerQuantity, uint256 buyerQuantity, uint256 unfilledQuantity, uint256 timestamp);
  event CloseOffer(uint256 id, uint256 timestamp);

  constructor(address mfcAddress_, address busdAddress_, address mfcTreasuryAddress_, address busdTreasuryAddress_) {
    _busdAddress = busdAddress_;
    _tradingPairs[MFC_BUSD] = TradingPair(mfcAddress_, busdAddress_, mfcTreasuryAddress_, busdTreasuryAddress_, MFC_FEE, BUSD_FEE);
    _tradingPairs[BUSD_MFC] = TradingPair(busdAddress_, mfcAddress_, busdTreasuryAddress_, mfcTreasuryAddress_, BUSD_FEE, MFC_FEE);
  }

  function getOffer(uint256 id, address seller) external view returns (Offer memory) {
    return _offers[seller][id];
  }

  function createOffer(bytes32 tradingPair, uint256 quantity, uint256 price) external {
    require(_pairExist(tradingPair), "Invalid pair");
    require(quantity > 0, "Invalid quantity");
    require(price > 0, "Invalid price");
    BEP20 token = _getSpendingTokenAndCheck(_tradingPairs[tradingPair].makerAssetAddress, quantity);
    uint256 expiresAt = block.timestamp + EXPIRES_IN;
    uint256 id = _nonce++;
    _offers[_msgSender()][id] = Offer(id, tradingPair, quantity, price, expiresAt, true);
    token.transferFrom(_msgSender(), address(this), quantity);
    emit CreateOffer(id, _msgSender(), tradingPair, quantity, price, expiresAt, block.timestamp);
  }

  function tradeOffer(uint256 id, address seller, uint256 quantity) external {
    require(_isOfferActive(id, seller), "Invalid offer");
    require(quantity > 0, "Invalid quantity");

    TradingPair memory tradingPair = _tradingPairs[_offers[seller][id].tradingPair];
    uint256 maxInput = _offers[seller][id].quantity * _offers[seller][id].price / MULTIPLIER;
    uint256 minInput;

    if (tradingPair.makerAssetAddress == _busdAddress) {
      minInput = MINIMUM_SWAP_IN_BUSD * _offers[seller][id].price / MULTIPLIER;
    } else if (tradingPair.takerAssetAddress == _busdAddress) {
      minInput = MINIMUM_SWAP_IN_BUSD;
    } else {
      revert("Unsupported pair");
    }

    require(quantity <= maxInput, "Not enough to sell");
    require(quantity >= minInput, "Minimum swap not reached");

    uint256 buyQuantity = _tradeOffer(tradingPair, seller, quantity, _offers[seller][id].price);

    require(_offers[seller][id].quantity >= buyQuantity, "Bad calculations");
    _offers[seller][id].quantity -= buyQuantity;

    bool makerCloseout = (tradingPair.makerAssetAddress == _busdAddress && _offers[seller][id].quantity < MINIMUM_SWAP_IN_BUSD);
    bool takerCloseout = (tradingPair.takerAssetAddress == _busdAddress && _offers[seller][id].quantity * _offers[seller][id].price / MULTIPLIER < MINIMUM_SWAP_IN_BUSD);

    if (makerCloseout || takerCloseout) {
      _closeOffer(id, seller);
    }

    // For [MFC_BUSD] pair, sellerQuantity = MFC, buyerQuantity = BUSD
    emit TradeOffer(id, _msgSender(), buyQuantity, quantity, _offers[seller][id].quantity, block.timestamp);
  }

  function closeOffer(uint256 id) external {
    require(_isOfferActive(id, _msgSender()), "Invalid offer");
    _closeOffer(id, _msgSender());
  }

  function _pairExist(bytes32 tradingPair) private view returns (bool) {
    return _tradingPairs[tradingPair].makerAssetAddress != address(0);
  }

  function _isOfferActive(uint256 id, address seller) private view returns (bool) {
    return _offers[seller][id].isOpen && _offers[seller][id].expiresAt > block.timestamp;
  }

  function _getSpendingTokenAndCheck(address assetAddress, uint256 quantity) private view returns (BEP20) {
    BEP20 token = BEP20(assetAddress);
    require(token.allowance(_msgSender(), address(this)) >= quantity, "Insufficient allowance");
    require(token.balanceOf(_msgSender()) >= quantity, "Insufficient balance");
    return token;
  }

  // @dev returns maker quantity fulfilled by this trade
  function _tradeOffer(TradingPair memory tradingPair, address seller, uint256 quantity, uint256 price) private returns (uint256) {
    BEP20 makerAsset = BEP20(tradingPair.makerAssetAddress);
    BEP20 takerAsset = _getSpendingTokenAndCheck(tradingPair.takerAssetAddress, quantity);

    // Offer is 1,000 MFC at 10.0 BUSD each (10,000 BUSD in total)
    // Taker want to swap 100 BUSD for 10 MFC
    // buyQuantity should be 100 BUSD * (10^18 / 10^19) = 10 MFC
    uint256 buyQuantity = quantity * MULTIPLIER / price;

    uint256 makerFee = quantity * tradingPair.makerFeeRate / MULTIPLIER;
    uint256 takerFee = buyQuantity * tradingPair.takerFeeRate / MULTIPLIER;

    uint256 makerReceives = quantity - makerFee;
    uint256 takerReceives = buyQuantity - takerFee;

    takerAsset.transferFrom(_msgSender(), address(this), makerReceives);
    takerAsset.transfer(seller, makerReceives);
    takerAsset.transferFrom(_msgSender(), tradingPair.takerTreasuryAddress, makerFee);
    makerAsset.transfer(_msgSender(), takerReceives);
    makerAsset.transfer(tradingPair.makerTreasuryAddress, takerFee);

    return buyQuantity;
  }

  function _closeOffer(uint256 id, address seller) private {
    uint256 remainingQuantity = _offers[seller][id].quantity;
    _offers[seller][id].isOpen = false;
    if (remainingQuantity > 0) {
      _offers[seller][id].quantity = 0;
      BEP20 token = BEP20(_tradingPairs[_offers[seller][id].tradingPair].makerAssetAddress);
      token.transfer(seller, remainingQuantity);
    }
    emit CloseOffer(id, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

pragma solidity ^0.8.4;

import "../../access/Ownable.sol";
import "../../utils/Context.sol";
import "./IBEP20.sol";

/**
 * @dev @dev Implementation of the {IBEP20} interface.
 */
contract BEP20 is Context, IBEP20, Ownable {
  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor(string memory name_, string memory symbol_, uint8 decimals_) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external override view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external override view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external override view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
    return true;
  }

  /**
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */
  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
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
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] -= amount;
    _totalSupply -= amount;
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   *
   * See {_burn} and {_approve}.
   */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()] - amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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