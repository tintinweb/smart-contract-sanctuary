// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ReflectiveToken.sol";

contract CatDoge is ReflectiveToken {
  using EnumerableSet for EnumerableSet.AddressSet;

  mapping(address => uint256) public stakeValue;
  mapping(address => uint256) public stakerPayouts;
  mapping(address => uint256) public bnbWithdrawn;

  uint256 public profitPerShare;
  uint256 public pendingShares;

  uint256 public totalDistributions;
  uint256 public totalReflected;
  uint256 public totalWithdrawn;
  uint256 public totalStaked;

  uint256 public buyLimit;
  uint256 public sellLimit;

  uint256 private immutable numTokensSellToAddToLiquidity;
  uint256 private constant DISTRIBUTION_MULTIPLIER = 2**64;

  EnumerableSet.AddressSet private _stakingExcluded;
  mapping(address => bool) private _isBlacklisted;

  event OnWithdraw(address sender, uint256 amount);
  event OnDistribute(uint256 tokenAmount, uint256 bnbReceived);
  event OnStakingInclude(address account);
  event OnStakingExclude(address account);
  event OnWithdrawIsolatedBNB(uint256 amount);

  constructor() ReflectiveToken("CatDoge", "CATDOGE", 10**15, 6, 2, 8) {
    _tOwned[_msgSender()] = _tTotal;

    // 0.03% of total supply
    numTokensSellToAddToLiquidity = (30000 * _tTotal) / 10**8;

    // 0.1% of total supply on both buy/sell initially (Whale prevention)
    buyLimit = (1000 * _tTotal) / 10**6;
    sellLimit = (1000 * _tTotal) / 10**6;

    _stakingExcluded.add(address(this));
    _stakingExcluded.add(_msgSender());

    emit OnStakingExclude(address(this));
    emit OnStakingExclude(_msgSender());
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    if (_stakingExcluded.contains(account)) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  function _takeSwapFee(uint256 tSwapFee) internal override {
    uint256 currentRate = _getRate();
    uint256 rSwapFee = tSwapFee * currentRate;

    if (_stakingExcluded.contains(address(this))) _tOwned[address(this)] += tSwapFee;
    else _rOwned[address(this)] += rSwapFee;
  }

  function _getRate() internal view override returns (uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;

    // Increases gas cost noticeably but will never be problematic:
    // `_stakingExcluded` is controlled and always small (<10 in practice)
    for (uint256 i = 0; i < _stakingExcluded.length(); i++) {
      address account = _stakingExcluded.at(i);
      if (_rOwned[account] > rSupply || _tOwned[account] > tSupply) return _rTotal / _tTotal;
      rSupply -= _rOwned[account];
      tSupply -= _tOwned[account];
    }

    if (rSupply < (_rTotal / _tTotal)) return _rTotal / _tTotal;
    return rSupply / tSupply;
  }

  function _validateTransfer(
    address sender,
    address recipient,
    uint256 amount,
    bool takeFee
  ) private view {
    // Excluded addresses don't have limits
    if (takeFee) {
      if (_isBuy(sender) && buyLimit != 0) {
        require(amount <= buyLimit, "Buy amount exceeds limit");
      } else if (_isSell(sender, recipient) && sellLimit != 0) {
        require(amount <= sellLimit, "Sell amount exceeds limit");
      }
    }
  }

  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount,
    bool takeFee
  ) internal virtual override returns (uint256) {
    require(sender != recipient, "Sending to yourself is disallowed");
    require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "Blacklisted account");
    _validateTransfer(sender, recipient, amount, takeFee);

    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tSwapFee
    ) = _getValues(amount, takeFee);

    uint256 senderDividends;

    if (_stakingExcluded.contains(sender)) _tOwned[sender] -= amount;
    else {
      senderDividends = dividendsOf(sender);
      totalStaked -= stakeValue[sender];
      _rOwned[sender] -= rAmount;
    }

    if (_stakingExcluded.contains(recipient)) _tOwned[recipient] += tTransferAmount;
    else _rOwned[recipient] += rTransferAmount;

    _takeSwapFee(tSwapFee);
    _reflectFee(rFee, tFee);
    _restake(sender, recipient, tTransferAmount, senderDividends);
    totalReflected += tFee;

    return tTransferAmount;
  }

  function _restake(
    address sender,
    address recipient,
    uint256 transferAmount,
    uint256 senderDividends
  ) private {
    bool senderExcluded = _stakingExcluded.contains(sender);
    bool recipientExcluded = _stakingExcluded.contains(recipient);

    if (!recipientExcluded) {
      uint256 payout = transferAmount * profitPerShare;
      stakerPayouts[recipient] += payout;
      stakeValue[recipient] += transferAmount;
      totalStaked += transferAmount;
    }

    // Before the initial distribution, `profitPerShare` will be stuck at 0
    // this line only protects against reverts from users
    // whom hold a balance before the initial distribution.
    if (!senderExcluded) {
      // Direct lookup over `balanceOf` to save on gas cost
      uint256 senderBalance = tokenFromReflection(_rOwned[sender]);
      stakerPayouts[sender] = senderBalance * profitPerShare;
      stakeValue[sender] = senderBalance;

      totalStaked += senderBalance;

      if (senderDividends > 0) {
        _withdraw(sender, senderDividends);
      }
    }
  }

  function _withdraw(address account, uint256 amount) private {
    payable(account).transfer(amount);
    bnbWithdrawn[account] += amount;
    totalWithdrawn += amount;

    emit OnWithdraw(account, amount);
  }

  function _checkSwapViability(address sender) internal virtual override {
    uint256 contractTokenBalance = balanceOf(address(this));
    bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;

    if (overMinTokenBalance && sender != address(uniswapV2Pair)) {
      swapAndDistribute(contractTokenBalance);
    }
  }

  function swapAndDistribute(uint256 contractTokenBalance) private {
    uint256 initialBalance = address(this).balance;
    swapTokensForBnb(contractTokenBalance);
    uint256 swappedAmount = address(this).balance - initialBalance;

    // Forward 10% to dev wallet
    uint256 devSplit = (swappedAmount * 10) / 100;
    uint256 amount = swappedAmount - devSplit;

    payable(owner()).transfer(devSplit);

    totalDistributions += amount;

    if (totalStaked > 0) {
      if (pendingShares > 0) {
        amount += pendingShares;
        pendingShares = 0;
      }
      profitPerShare += ((amount * DISTRIBUTION_MULTIPLIER) / totalStaked);
    } else {
      pendingShares += amount;
    }

    emit OnDistribute(contractTokenBalance, amount);
  }

  function dividendsOf(address staker) public view returns (uint256) {
    // Using `stakeValue` over actual balance because reflection shares cannot be calculated
    uint256 divPayout = stakeValue[staker] * profitPerShare;
    if (divPayout < stakerPayouts[staker]) return 0;

    return (divPayout - stakerPayouts[staker]) / DISTRIBUTION_MULTIPLIER;
  }

  // reflective earnings since last collection or transfer
  function reflectionEarnings() external view returns (uint256) {
    uint256 staked = stakeValue[_msgSender()];
    uint256 balance = balanceOf(_msgSender());

    return balance - staked;
  }

  function restake() external {
    uint256 staked = stakeValue[_msgSender()];
    uint256 balance = balanceOf(_msgSender());
    uint256 earnings = balance - staked;

    stakeValue[_msgSender()] += earnings;
    stakerPayouts[_msgSender()] += earnings * profitPerShare;
    totalStaked += earnings;
  }

  function withdraw() external payable {
    uint256 share = dividendsOf(_msgSender());

    //Effects
    // Resetting dividends back to 0
    stakerPayouts[_msgSender()] = stakeValue[_msgSender()] * profitPerShare;

    //Interactions
    _withdraw(_msgSender(), share);
  }

  function includeInStaking(address account) external onlyOwner {
    require(_stakingExcluded.contains(account), "Account already included");
    uint256 balance = _tOwned[account];

    _tOwned[account] = 0;
    _rOwned[account] = reflectionFromToken(balance);
    totalStaked += balance;
    stakeValue[account] = balance;
    stakerPayouts[account] = balance * profitPerShare;

    _stakingExcluded.remove(account);

    emit OnStakingInclude(account);
  }

  function excludeFromStaking(address account) external onlyOwner {
    require(!_stakingExcluded.contains(account), "Account already excluded");
    uint256 balance = tokenFromReflection(_rOwned[account]);

    uint256 dividends = dividendsOf(account);
    if (dividends > 0) _withdraw(account, dividends);

    _tOwned[account] = balance;
    totalStaked -= stakeValue[account];
    stakeValue[account] = 0;
    stakerPayouts[account] = 0;

    _stakingExcluded.add(account);

    emit OnStakingExclude(account);
  }

  function withdrawIsolatedBnb() external onlyOwner {
    uint256 pendingBnb = totalDistributions - totalWithdrawn;
    uint256 isolatedBnb = address(this).balance - pendingBnb;

    if (isolatedBnb > 0) {
      payable(_msgSender()).transfer(isolatedBnb);

      emit OnWithdrawIsolatedBNB(isolatedBnb);
    }
  }

  function updateBuyLimit(uint256 limit) external onlyOwner {
    // Buy limit can only be 0.1% or disabled, set to 0 to disable
    uint256 maxLimit = (1000 * _tTotal) / 10**6;
    require(limit == maxLimit || limit == 0, "Buy limit out of bounds");

    buyLimit = limit;
  }

  function updateSellLimit(uint256 limit) external onlyOwner {
    // Min sell limit is 0.1%, max is 0.5%. Set to 0 to disable
    uint256 minLimit = (1000 * _tTotal) / 10**6;
    uint256 maxLimit = (5000 * _tTotal) / 10**6;

    require((limit <= maxLimit && limit >= minLimit) || limit == 0, "Sell limit out of bounds");

    sellLimit = limit;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./ReflectiveERC20.sol";
import "./LiquidityAcquisition.sol";

contract ReflectiveToken is ReflectiveERC20 {
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 totalSupply_,
    uint8 decimals_,
    uint8 reflectionFee_,
    uint8 swapFee_
  ) ReflectiveERC20(name_, symbol_, totalSupply_, decimals_, reflectionFee_, swapFee_) {}

  receive() external payable {}

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    bool takeFee = true;

    if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
      takeFee = false;
    } else {
      _checkSwapViability(sender);
    }

    uint256 transferAmount = _tokenTransfer(sender, recipient, amount, takeFee);

    emit Transfer(sender, recipient, transferAmount);
  }

  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount,
    bool takeFee
  ) internal virtual returns (uint256) {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tSwapFee
    ) = _getValues(amount, takeFee);

    _rOwned[sender] -= rAmount;
    _rOwned[recipient] += rTransferAmount;

    _takeSwapFee(tSwapFee);
    _reflectFee(rFee, tFee);

    return tTransferAmount;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./LiquidityAcquisition.sol";

contract ReflectiveERC20 is IERC20, Context, LiquidityAcquisition {
  mapping(address => uint256) internal _rOwned;
  mapping(address => uint256) internal _tOwned;
  mapping(address => mapping(address => uint256)) internal _allowances;

  mapping(address => bool) internal _isExcludedFromFee;

  string internal _name;
  string internal _symbol;
  uint8 internal _decimals;

  uint256 private constant MAX = ~uint256(0);
  uint256 internal _tTotal;
  uint256 internal _rTotal;
  uint256 internal _tFeeTotal;

  uint8 public reflectionFee;
  uint8 public swapFee;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 totalSupply_,
    uint8 decimals_,
    uint8 reflectionFee_,
    uint8 swapFee_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
    _tTotal = totalSupply_ * 10**_decimals;
    _rTotal = (MAX - (MAX % _tTotal));

    // Reflective fee defaults
    _isExcludedFromFee[_msgSender()] = true;
    _isExcludedFromFee[address(this)] = true;
    reflectionFee = reflectionFee_;
    swapFee = swapFee_;

    _rOwned[_msgSender()] = _rTotal;

    emit Transfer(address(0), _msgSender(), _tTotal);
  }

  /**
   * Base ERC20 Functions
   */

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return tokenFromReflection(_rOwned[account]);
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    _approve(sender, _msgSender(), currentAllowance - amount);

    return true;
  }

  /**
   * ERC20 Helpers
   */

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual override {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  // Always expected to be overwritten by parent contract
  // since its' implementation is contract-specific
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {}

  /**
   * Base Reflection Functions
   */

  function isExcludedFromFee(address account) public view returns (bool) {
    return _isExcludedFromFee[account];
  }

  function totalFees() public view returns (uint256) {
    return _tFeeTotal;
  }

  function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
    require(rAmount <= _rTotal, "Amount must be less than total reflections");
    return rAmount / _getRate();
  }

  function reflectionFromToken(uint256 tAmount) public view returns (uint256) {
    require(tAmount <= _tTotal, "Amount must be less than supply");
    return tAmount * _getRate();
  }

  /**
   * Reflection Helpers
   */

  function _getValues(uint256 tAmount, bool takeFee)
    internal
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 currentRate = _getRate();
    uint256 tFee = 0;
    uint256 tSwap = 0;

    if (takeFee) {
      tFee = (tAmount * reflectionFee) / 100;
      tSwap = (tAmount * swapFee) / 100;
    }

    uint256 tTransferAmount = tAmount - tFee - tSwap;

    uint256 rAmount = tAmount * currentRate;
    uint256 rFee = tFee * currentRate;
    uint256 rSwap = tSwap * currentRate;
    uint256 rTransferAmount = rAmount - rFee - rSwap;

    return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tSwap);
  }

  function _getRate() internal view virtual returns (uint256) {
    return _rTotal / _tTotal;
  }

  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }

  function includeInFee(address account) public onlyOwner {
    require(account != address(this), "Contract can't be included");
    _isExcludedFromFee[account] = false;
  }

  function _reflectFee(uint256 rFee, uint256 tFee) internal {
    _rTotal -= rFee;
    _tFeeTotal += tFee;
  }

  function _takeSwapFee(uint256 tSwapFee) internal virtual {
    uint256 currentRate = _getRate();
    uint256 rSwapFee = tSwapFee * currentRate;
    _rOwned[address(this)] += rSwapFee;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./uniswapv2/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract InternalToken {
  // This is always expected to be
  // overwritten by a parent contract
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {}
}

contract LiquidityAcquisition is InternalToken, Ownable {
  IUniswapV2Router02 public uniswapV2Router;
  IUniswapV2Pair public uniswapV2Pair;

  event SwapFailure(string reason);

  constructor() {
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    IUniswapV2Pair _uniswapV2Pair = IUniswapV2Pair(
      IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH())
    );
    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;
  }

  function setRouterAddress(address newRouter) public onlyOwner {
    IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
    uniswapV2Pair = IUniswapV2Pair(
      IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH())
    );
    uniswapV2Router = _newPancakeRouter;
  }

  // Always expected to be overwritten by parent contract
  // since its' implementation is contract-specific
  function _checkSwapViability(address sender) internal virtual {}

  function _isSell(address sender, address recipient) internal view returns (bool) {
    // Transfer to pair from non-router address is a sell swap
    return sender != address(uniswapV2Router) && recipient == address(uniswapV2Pair);
  }

  function _isBuy(address sender) internal view returns (bool) {
    // Transfer from pair is a buy swap
    return sender == address(uniswapV2Pair);
  }

  function swapTokensForBnb(uint256 tokenAmount) internal {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    try
      uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount,
        0,
        path,
        address(this),
        block.timestamp
      )
    {} catch Error(string memory reason) {
      emit SwapFailure(reason);
    }
  }

  function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) public onlyOwner {
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    try
      uniswapV2Router.addLiquidityETH{ value: bnbAmount }(
        address(this),
        tokenAmount,
        0,
        0,
        address(this),
        block.timestamp
      )
    {} catch Error(string memory reason) {
      emit SwapFailure(reason);
    }
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;
  function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
    constructor () {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountTokenA,
        uint amountTokenB,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountToken,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken1, uint amountETH, uint liquidity);

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