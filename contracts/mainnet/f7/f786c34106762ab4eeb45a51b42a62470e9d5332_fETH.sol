/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-02-28
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.1;
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
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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



// File: openzeppelin-solidity\contracts\token\ERC20\IERC20.sol

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

// File: openzeppelin-solidity\contracts\utils\Address.sol


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


contract fETH is IERC20 {
    using Address for address;
    enum TxType { FromExcluded, ToExcluded, BothExcluded, Standard }

    mapping (address => uint256) private rBnbBalance;
    mapping (address => uint256) private tBnbBalance;
    mapping (address => mapping (address => uint256)) private _allowances;

    EnumerableSet.AddressSet excluded;

    uint256 private tBnbSupply;
    uint256 private rBnbSupply;
    uint256 private feesAccrued;
 
    string private _name = 'FEG Wrapped ETH'; 
    string private _symbol = 'fETH';
    uint8  private _decimals = 18;
    
    address private op;
    address private op2;
    
    event  Deposit(address indexed dst, uint amount);
    event  Withdrawal(address indexed src, uint amount);

    receive() external payable {
        deposit();
    }

    constructor () {
        op = address(0x4c9BC793716e8dC05d1F48D8cA8f84318Ec3043C);
        op2 = op;
        EnumerableSet.add(excluded, address(0)); // stablity - zen.
        emit Transfer(address(0), msg.sender, 0);
    }

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
        return tBnbSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (EnumerableSet.contains(excluded, account)) return tBnbBalance[account];
        (uint256 r, uint256 t) = currentSupply();
        return (rBnbBalance[account] * t)  / r;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return EnumerableSet.contains(excluded, account);
    }

    function totalFees() public view returns (uint256) {
        return feesAccrued;
    }
    
    function deposit() public payable {
        require(msg.value > 0, "can't deposit nothing");
        (uint256 r, uint256 t) = currentSupply();
        tBnbSupply += msg.value;
        uint256 fee = msg.value / 100; 
        uint256 df = fee / 10;
        uint256 net = fee != 0 ? (msg.value - (fee)) : msg.value;
        if(isExcluded(msg.sender)){
            tBnbBalance[msg.sender] += (msg.value - fee);
        } 
        feesAccrued += fee;
        rBnbBalance[op] += ((df * r) / t);
        rBnbSupply += (((net + df) * r) / t);
        rBnbBalance[msg.sender] += ((net * r) / t);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amt) public {
        require(balanceOf(msg.sender) >= amt && amt <= totalSupply(), "invalid amt");
        (uint256 r, uint256 t) = currentSupply();
        uint256 fee = amt / 100;
        uint256 wf = fee / 8;
        uint256 net = amt - fee;
        if(isExcluded(msg.sender)) {
            tBnbBalance[msg.sender] -= amt;
            rBnbBalance[msg.sender] -= ((amt * r) / t);
        } else {
            rBnbBalance[msg.sender] -= ((amt * r) / t);
        }
        tBnbSupply -= (net + wf);
        rBnbSupply -= (((net + wf) * r ) / t);
        rBnbBalance[op] += ((wf * r) / t);
        feesAccrued += wf;
        payable(msg.sender).transfer(net); 
        emit Withdrawal(msg.sender, net);
    }
    
    function rBnbToEveryone(uint256 amt) public {
        require(!isExcluded(msg.sender), "not allowed");
        (uint256 r, uint256 t) = currentSupply();
        rBnbBalance[msg.sender] -= ((amt * r) / t);
        rBnbSupply -= ((amt * r) / t);
        feesAccrued += amt;
    }

    function excludeFromFees(address account) external {
        require(msg.sender == op2, "op only");
        require(!EnumerableSet.contains(excluded, account), "address excluded");
        if(rBnbBalance[account] > 0) {
            (uint256 r, uint256 t) = currentSupply();
            tBnbBalance[account] = (rBnbBalance[account] * (t)) / (r);
        }
        EnumerableSet.add(excluded, account);
    }

    function includeInFees(address account) external {
        require(msg.sender == op2, "op only");
        require(EnumerableSet.contains(excluded, account), "address excluded");
        tBnbBalance[account] = 0;
        EnumerableSet.remove(excluded, account);
    }
    
    function tBnbFromrBnb(uint256 rBnbAmount) external view returns (uint256) {
        (uint256 r, uint256 t) = currentSupply();
        return (rBnbAmount * t) / r;
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getTtype(address sender, address recipient) internal view returns (TxType t) {
        bool isSenderExcluded = EnumerableSet.contains(excluded, sender);
        bool isRecipientExcluded = EnumerableSet.contains(excluded, recipient);
        if (isSenderExcluded && !isRecipientExcluded) {
            t = TxType.FromExcluded;
        } else if (!isSenderExcluded && isRecipientExcluded) {
            t = TxType.ToExcluded;
        } else if (!isSenderExcluded && !isRecipientExcluded) {
            t = TxType.Standard;
        } else if (isSenderExcluded && isRecipientExcluded) {
            t = TxType.BothExcluded;
        } else {
            t = TxType.Standard;
        }
        return t;
    }
    function _transfer(address sender, address recipient, uint256 amt) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amt > 0, "Transfer amt must be greater than zero");
        (uint256 r, uint256 t) = currentSupply();
        uint256 fee = amt / 100;
        TxType tt = getTtype(sender, recipient);
        if (tt == TxType.ToExcluded) {
            rBnbBalance[sender] -= ((amt * r) / t);
            tBnbBalance[recipient] += (amt - fee);
            rBnbBalance[recipient] += (((amt - fee) * r) / t);
        } else if (tt == TxType.FromExcluded) {
            tBnbBalance[sender] -= (amt);
            rBnbBalance[sender] -= ((amt * r) / t);
            rBnbBalance[recipient] += (((amt - fee) * r) / t);
        } else if (tt == TxType.BothExcluded) {
            tBnbBalance[sender] -= (amt);
            rBnbBalance[sender] -= ((amt * r) / t);
            tBnbBalance[recipient] += (amt - fee);
            rBnbBalance[recipient] += (((amt - fee) * r) / t);
        } else {
            rBnbBalance[sender] -= ((amt * r) / t);
            rBnbBalance[recipient] += (((amt - fee) * r) / t);
        }
        rBnbSupply  -= ((fee * r) / t);
        feesAccrued += fee;
        emit Transfer(sender, recipient, amt - fee);
    }

    function currentSupply() public view returns(uint256, uint256) {
        if(rBnbSupply == 0 || tBnbSupply == 0) return (1000000000, 1);
        uint256 rSupply = rBnbSupply;
        uint256 tSupply = tBnbSupply;
        for (uint256 i = 0; i < EnumerableSet.length(excluded); i++) {
            if (rBnbBalance[EnumerableSet.at(excluded, i)] > rSupply || tBnbBalance[EnumerableSet.at(excluded, i)] > tSupply) return (rBnbSupply, tBnbSupply);
            rSupply -= (rBnbBalance[EnumerableSet.at(excluded, i)]);
            tSupply -= (tBnbBalance[EnumerableSet.at(excluded, i)]);
        }
        if (rSupply < rBnbSupply / tBnbSupply) return (rBnbSupply, tBnbSupply);
        return (rSupply, tSupply);
    }
    
    function setOp(address opper, address opper2) external {
        require(msg.sender == op, "only op can call");
        op = opper;
        op2 = opper2;
    }
}