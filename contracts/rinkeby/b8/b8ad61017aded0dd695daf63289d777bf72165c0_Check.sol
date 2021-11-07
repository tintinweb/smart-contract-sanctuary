/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

abstract contract CheckBase is IERC20, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet _exemptUsers;

    event IncludeInReward(address account);
    event ExcludeFromReward(address account);
    event IncludeInFee(address account);
    event ExcludeFromFee(address account);
    event UpdateFee(string indexed feeType, uint256 previousTaxFee, uint256 newTaxFee);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiquidity
    );
    event NumTokensSellToAddToLiquidityUpdate(uint256 oldNum, uint256 newNum);
    event WalletAddressUpdate(string walletName, address newWallet);

    address public constant BURNING_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public MARKETING_WALLET_ADDRESS = 0x16036E129b6D78AE7e37E971226528d5F649D424;  // To be provided
    address public LISTING_WALLET_ADDRESS = 0xC566e510bdFDb37167D8475A52A1F8A4239Ed5fD;  // To be provided

    mapping (address => uint256) _rOwned;
    mapping (address => uint256) _tOwned;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) _isExcludedFromFee;
    mapping (address => bool) _isExcluded;
    address[] _excluded;

    uint256 constant MAX = ~uint256(0);
    uint256 internal constant _tTotal = 100000 * 10**6 * 10**6;
    uint256 internal _rTotal = (MAX - (MAX % _tTotal));
    uint256 public currentRate = _rTotal / _tTotal;
    uint256 _tFeeTotal;

    uint256 public maxTxAmount = 10 * 10**6 * 10**6;
    uint256 public numTokensSellToAddToLiquidity = 600_000 * 10**6;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    IPancakeswapRouter02 public immutable pancakeswapRouter;
    address public immutable pancakeswapPair;

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        bool success = _exemptUsers.add(_msgSender());
        require(success, "Already added");

        contractDeploymentTime = block.timestamp;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // IPancakeswapRouter02 _pancakeswapRouter = IPancakeswapRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);  // BSC Main
        // IPancakeswapRouter02 _pancakeswapRouter = IPancakeswapRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);  // BSC Testnet
        IPancakeswapRouter02 _pancakeswapRouter = IPancakeswapRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  // Rinkeby


         // Create a pancakeswap pair for this new token
        pancakeswapPair = IPancakeswapFactory(_pancakeswapRouter.factory()).createPair(address(this), _pancakeswapRouter.WETH());

        // set the rest of the contract variables
        pancakeswapRouter = _pancakeswapRouter;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    uint256 public _taxFee = 2;
    uint256 _previousTaxFee = _taxFee;

    uint256 public _earlyTaxFee = 0;
    uint256 _previousEarlyTaxFee = _earlyTaxFee;

    uint256 public _liquidityFee = 2;
    uint256 _previousLiquidityFee = _liquidityFee;

    uint256 public _burnFee = 2;
    uint256 _previousBurnFee = _burnFee;

    uint256 public _marketingFee = 2;
    uint256 _previousMarketingFee = _marketingFee;

    uint256 public _listingFee = 2;
    uint256 _previousListingFee = _listingFee;

    uint256 public contractDeploymentTime;
    uint256 public constant earlySellTaxRate1 = 20;
    uint256 public constant earlySellTaxRate2 = 15;
    uint256 public constant earlySellTaxRate3 = 10;
    uint256 public constant numOfWalletsExemptFromEarlyTax = 500;
    uint256 public cumulativeEarlySellTaxFee = 0;
    uint256 public earlySellTaxFeeId = 0;

    function _balanceOf(address account) internal view returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return _tokenFromReflection(_rOwned[account]);
    }

    function _reflectionFromToken(uint256 tAmount, bool deductFee) internal view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function _tokenFromReflection(uint256 rAmount) internal view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less reflected total");
        return rAmount/currentRate;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from 0 address");
        require(spender != address(0), "ERC20: approve to 0 address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _rOwned[account] += amount * currentRate;
        _rTotal += amount * currentRate;
        _updateRate();
        emit Transfer(address(0), account, amount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _updateRate() private {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        currentRate = rSupply / tSupply;
    }

    function _excludeFromReward(address account) internal {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude pancakeswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = _tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
        emit ExcludeFromReward(account);
    }

    function _includeInReward(address account) internal {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _rOwned[account] = _tOwned[account] * currentRate;
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                emit IncludeInReward(account);
                break;
            }
        }
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
    }

    function _removeAllFee() private {
        if (_taxFee == 0 &&
            _liquidityFee == 0 &&
            _burnFee == 0 &&
            _marketingFee == 0 &&
            _listingFee == 0
        )
            return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _burnFee;
        _previousMarketingFee = _marketingFee;
        _previousListingFee = _listingFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _burnFee = 0;
        _marketingFee = 0;
        _listingFee = 0;
    }

    function _restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _burnFee = _previousBurnFee;
        _marketingFee = _previousMarketingFee;
        _listingFee = _previousListingFee;
    }

    function _getEarlySellTaxRate(address seller) private {
        if (_exemptUsers.contains(seller)) {
            _earlyTaxFee = 0;
            return;
        }
        if (block.timestamp - contractDeploymentTime < 30 days) {
            _earlyTaxFee = earlySellTaxRate1;
        } else if (block.timestamp - contractDeploymentTime < 60 days) {
            _earlyTaxFee = earlySellTaxRate2;
        } else if (block.timestamp - contractDeploymentTime < 90 days) {
            _earlyTaxFee = earlySellTaxRate3;
        } else {
            _earlyTaxFee = 0;
        }
    }

    function _getValues(uint256 tAmount)
        internal
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount)
        internal
        view
        returns (uint256, uint256, uint256)
    {
        uint256 tFee = _calculateTaxFee(tAmount);
        uint256 tLiquidity = _calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount - tFee - tLiquidity;
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity)
        internal
        view
        returns (uint256, uint256, uint256)
    {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity;
        return (rAmount, rTransferAmount, rFee);
    }

    function _calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount * _taxFee / 10**2;
    }

    function _calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount * (_liquidityFee + _burnFee + _marketingFee + _earlyTaxFee + _listingFee) / 10**2;
    }

    function _swapTokensForBNB(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapRouter.WETH();

        _approve(address(this), address(pancakeswapRouter), tokenAmount);

        uint256[] memory amountOutMin = pancakeswapRouter.getAmountsOut(tokenAmount, path);

        // make the swap
        pancakeswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            amountOutMin[1] * 9 / 10, // accept 9/10 of the amountOutMin
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapTokensForBNBWithAddr(uint256 tokenAmount, address addr) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapRouter.WETH();

        _approve(address(this), address(pancakeswapRouter), tokenAmount);

        uint256[] memory amountOutMin = pancakeswapRouter.getAmountsOut(tokenAmount, path);

        // make the swap
        pancakeswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            amountOutMin[1] * 9 / 10, // accept 9/10 of the amountOutMin
            path,
            addr,
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapRouter), tokenAmount);

        // add the liquidity
        (,, uint liquidity) = pancakeswapRouter.addLiquidityETH{value: bnbAmount} (
            address(this),
            tokenAmount,
            tokenAmount * 9 / 10, // slippage is 10%
            bnbAmount * 9 / 10, // slippage is 10%
            address(this),  // additional functions may be needed
            block.timestamp
        );
        require(liquidity > 0, "Liquidity must be greater than 0");
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from 0 address");
        require(to != address(0), "ERC20: transfer to 0 address");
        require(amount > 0, "ERC20: amount must be greater than 0");
        // if (from != owner() && to != owner())
        //     require(amount <= maxTxAmount, "Amount exceeds maxTxAmount");

        if (from == owner() && _exemptUsers.length() <= numOfWalletsExemptFromEarlyTax) {
            _exemptUsers.add(to);
        }

        // To router is a sell
        if (to == pancakeswapPair && _exemptUsers.length() <= numOfWalletsExemptFromEarlyTax) {
            _exemptUsers.add(from);
        }

        // From pair a buy
        if (from == pancakeswapPair) {
            require(amount <= maxTxAmount, "Amount exceeds maxTxAmount");
            _getEarlySellTaxRate(to);
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeswap pair.
        uint256 contractTokenBalance = _balanceOf(address(this));

        if (contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;

        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakeswapPair &&
            swapAndLiquifyEnabled
        ) {
            // TODO: fees can be applied here. They can be applied at other places.
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            _swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        //This needs to be distributed among burn, wallet and liquidity
        uint256 totalFee  = _burnFee + _marketingFee + _liquidityFee + _listingFee;
        uint256 spentAmount = 0;
        uint256 totalSpentAmount = 0;

        if (_burnFee != 0) {
            spentAmount  = (contractTokenBalance - cumulativeEarlySellTaxFee) * _burnFee / totalFee;
            _tokenTransferNoFee(address(this), BURNING_ADDRESS, spentAmount);
            totalSpentAmount = spentAmount;
        }

        if (_marketingFee != 0) {
            spentAmount = contractTokenBalance * _marketingFee / totalFee;
            _swapTokensForBNBWithAddr(spentAmount, MARKETING_WALLET_ADDRESS);
            totalSpentAmount += spentAmount;
        }

        if (_listingFee != 0) {
            spentAmount = (contractTokenBalance - cumulativeEarlySellTaxFee) * _listingFee / totalFee;
            _swapTokensForBNBWithAddr(spentAmount, LISTING_WALLET_ADDRESS);
            totalSpentAmount += spentAmount;
        }

        if (_liquidityFee != 0) {
            contractTokenBalance -= totalSpentAmount + cumulativeEarlySellTaxFee;
            // split the contract balance into halves
            uint256 half = contractTokenBalance / 2;
            uint256 otherHalf = contractTokenBalance - half;

            // capture the contract's current BNB balance.
            // this is so that we can capture exactly the amount of BNB that the
            // swap creates, and not make the liquidity event include any BNB that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;

            // swap tokens for BNB
            _swapTokensForBNB(half); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

            // how much BNB did we just swap into?
            uint256 newBalance = address(this).balance - initialBalance;

            // add liquidity to pancakeswap
            _addLiquidity(otherHalf, newBalance);

            emit SwapAndLiquify(half, newBalance, otherHalf);
        }

        if (cumulativeEarlySellTaxFee > 0) {
            if (earlySellTaxFeeId == 0 && block.timestamp - contractDeploymentTime > 30 days) {
                _tokenTransferNoFee(address(this), MARKETING_WALLET_ADDRESS, cumulativeEarlySellTaxFee);
                earlySellTaxFeeId += 1;
                cumulativeEarlySellTaxFee = 0;
            } else if (earlySellTaxFeeId == 1 && block.timestamp - contractDeploymentTime > 60 days) {
                _tokenTransferNoFee(address(this), MARKETING_WALLET_ADDRESS, cumulativeEarlySellTaxFee);
                earlySellTaxFeeId += 1;
                cumulativeEarlySellTaxFee = 0;
            } else if (earlySellTaxFeeId == 2 && block.timestamp - contractDeploymentTime > 90 days) {
                _tokenTransferNoFee(address(this), MARKETING_WALLET_ADDRESS, cumulativeEarlySellTaxFee);
                earlySellTaxFeeId += 1;
                cumulativeEarlySellTaxFee = 0;
            }
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee)
            _removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        // currentRate is only updated here for every transaction that has a tax fee.
        // Only when a tax fee is collected does the rate need to get updated.
        _updateRate();

        if (!takeFee)
            _restoreAllFee();
    }

    function _tokenTransferNoFee(address sender, address recipient, uint256 amount) private {
        _rOwned[sender] = _rOwned[sender] - amount * currentRate;
        _rOwned[recipient] = _rOwned[recipient] + amount * currentRate;

        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender] - amount;
        }

        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient] + amount;
        }

        emit Transfer(sender, recipient, amount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _buyback() internal {
        uint256 balance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = pancakeswapRouter.WETH();
        path[1] = address(this);

        uint256[] memory amountOutMin = pancakeswapRouter.getAmountsOut(balance, path);

        uint256[] memory amounts = pancakeswapRouter.swapExactETHForTokens{value: balance} (
            amountOutMin[1] * 9 / 10,
            path,
            address(this),
            block.timestamp
        );

        require(amounts[0] > 0, "No tokens are bought back");
    }

    function _withdrawBNB() internal {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdrawal of BNBs not successful");
    }

    function _withdrawCheck(address account) internal {
        uint256 balance = _balanceOf(address(this));
        _tokenTransferNoFee(address(this), account, balance);
    }
}

interface IPancakeswapRouter01 {
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

interface IPancakeswapRouter02 is IPancakeswapRouter01 {
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

interface IPancakeswapFactory {
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

interface IPancakeswapPair {
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

contract Check is CheckBase {

    string public constant name = "Paycheck";
    string public constant symbol = "CHECK";
    uint8 public constant decimals = 6;

     //to recieve ETH from pancakeSwapV2Router when swaping
    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) external override view returns (uint256) {
        return _balanceOf(account);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function mint(address account, uint256 amount) external onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }

    function buyback() external onlyOwner returns (bool) {
        _buyback();
        return true;
    }

    function withdrawBNB() external onlyOwner returns (bool) {
        _withdrawBNB();
        return true;
    }

    function withdrawCheck() external onlyOwner returns (bool) {
        _withdrawCheck(_msgSender());
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductFee) external view returns (uint256) {
        return _reflectionFromToken(tAmount, deductFee);
    }

    function tokenFromReflection(uint256 rAmount) external view returns(uint256) {
        return _tokenFromReflection(rAmount);
    }

    function excludeFromReward(address account) external onlyOwner {
        _excludeFromReward(account);
    }

    function includeInReward(address account) external onlyOwner {
        _includeInReward(account);
    }

    function excludeFromFee(address account) external onlyOwner {
        require(!_isExcludedFromFee[account], "Account is already excluded");
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
    }

    function includeInFee(address account) external onlyOwner {
        require(_isExcludedFromFee[account], "Account is not excluded");
        _isExcludedFromFee[account] = false;
        emit IncludeInFee(account);
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        require(taxFee <= 20, "TaxFee exceeds 20");
        _taxFee = taxFee;
        emit UpdateFee("Tax", _taxFee, taxFee);
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        require(liquidityFee <= 20, "LiquidityFee exceeds 20");
        _liquidityFee = liquidityFee;
        emit UpdateFee("Liquidity", _liquidityFee, liquidityFee);
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner {
        require(burnFee <= 20, "BurnFee exceeds 20");
        _burnFee = burnFee;
        emit UpdateFee("Burn", _burnFee, burnFee);
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner {
        require(marketingFee <= 20, "MarketingFee exceeds 20");
        _marketingFee = marketingFee;
        emit UpdateFee("Marketing", _marketingFee, marketingFee);
    }

    function setListingFeePercent(uint256 listingFee) external onlyOwner {
        require(listingFee <= 20, "ListingFee exceeds 20");
        _listingFee = listingFee;
        emit UpdateFee("Listing", _listingFee, listingFee);
    }

    function setMaxTxThousandth(uint256 maxTxThousandth) external onlyOwner {
        require(maxTxThousandth <= 200, "MaxTxPercent exceeds 200");
        uint256 newMaxTxAmount = _tTotal * maxTxThousandth / 10**3;
        maxTxAmount = newMaxTxAmount;
        emit UpdateFee("MaxTx", maxTxAmount, newMaxTxAmount);
    }

    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(swapAndLiquifyEnabled);
    }

    function setMarketingWallet(address newMarketingWallet) external onlyOwner {
        require(newMarketingWallet != MARKETING_WALLET_ADDRESS, "Same marketing wallet");
        MARKETING_WALLET_ADDRESS = newMarketingWallet;
        emit WalletAddressUpdate("Marketing", newMarketingWallet);
    }

    function setListingWallet(address newListingWallet) external onlyOwner {
        require(newListingWallet != LISTING_WALLET_ADDRESS, "Same listing wallet");
        LISTING_WALLET_ADDRESS = newListingWallet;
        emit WalletAddressUpdate("Listing", newListingWallet);
    }

    function setNumTokensSellToAddToLiquidity(uint256 _numTokensSellToAddToLiquidity) external onlyOwner {
        require(numTokensSellToAddToLiquidity != _numTokensSellToAddToLiquidity, "Same number");
        emit NumTokensSellToAddToLiquidityUpdate(numTokensSellToAddToLiquidity, _numTokensSellToAddToLiquidity);
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;
    }
}