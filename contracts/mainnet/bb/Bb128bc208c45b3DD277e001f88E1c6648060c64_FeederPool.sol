/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.2;


struct BassetPersonal {
    // Address of the bAsset
    address addr;
    // Address of the bAsset
    address integrator;
    // An ERC20 can charge transfer fee, for example USDT, DGX tokens.
    bool hasTxFee; // takes a byte in storage
    // Status of the bAsset
    BassetStatus status;
}

struct BassetData {
    // 1 Basset * ratio / ratioScale == x Masset (relative value)
    // If ratio == 10e8 then 1 bAsset = 10 mAssets
    // A ratio is divised as 10^(18-tokenDecimals) * measurementMultiple(relative value of 1 base unit)
    uint128 ratio;
    // Amount of the Basset that is held in Collateral
    uint128 vaultBalance;
}

abstract contract IMasset {
    // Mint
    function mint(
        address _input,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 mintOutput);

    function mintMulti(
        address[] calldata _inputs,
        uint256[] calldata _inputQuantities,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 mintOutput);

    function getMintOutput(address _input, uint256 _inputQuantity)
        external
        view
        virtual
        returns (uint256 mintOutput);

    function getMintMultiOutput(address[] calldata _inputs, uint256[] calldata _inputQuantities)
        external
        view
        virtual
        returns (uint256 mintOutput);

    // Swaps
    function swap(
        address _input,
        address _output,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 swapOutput);

    function getSwapOutput(
        address _input,
        address _output,
        uint256 _inputQuantity
    ) external view virtual returns (uint256 swapOutput);

    // Redemption
    function redeem(
        address _output,
        uint256 _mAssetQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 outputQuantity);

    function redeemMasset(
        uint256 _mAssetQuantity,
        uint256[] calldata _minOutputQuantities,
        address _recipient
    ) external virtual returns (uint256[] memory outputQuantities);

    function redeemExactBassets(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities,
        uint256 _maxMassetQuantity,
        address _recipient
    ) external virtual returns (uint256 mAssetRedeemed);

    function getRedeemOutput(address _output, uint256 _mAssetQuantity)
        external
        view
        virtual
        returns (uint256 bAssetOutput);

    function getRedeemExactBassetsOutput(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities
    ) external view virtual returns (uint256 mAssetAmount);

    // Views
    function getBasket() external view virtual returns (bool, bool);

    function getBasset(address _token)
        external
        view
        virtual
        returns (BassetPersonal memory personal, BassetData memory data);

    function getBassets()
        external
        view
        virtual
        returns (BassetPersonal[] memory personal, BassetData[] memory data);

    function bAssetIndexes(address) external view virtual returns (uint8);

    // SavingsManager
    function collectInterest() external virtual returns (uint256 swapFeesGained, uint256 newSupply);

    function collectPlatformInterest()
        external
        virtual
        returns (uint256 mintAmount, uint256 newSupply);

    // Admin
    function setCacheSize(uint256 _cacheSize) external virtual;

    function upgradeForgeValidator(address _newForgeValidator) external virtual;

    function setFees(uint256 _swapFee, uint256 _redemptionFee) external virtual;

    function setTransferFeesFlag(address _bAsset, bool _flag) external virtual;

    function migrateBassets(address[] calldata _bAssets, address _newIntegration) external virtual;
}


// Status of the Basset - has it broken its peg?
enum BassetStatus {
    Default,
    Normal,
    BrokenBelowPeg,
    BrokenAbovePeg,
    Blacklisted,
    Liquidating,
    Liquidated,
    Failed
}

struct BasketState {
    bool undergoingRecol;
    bool failed;
}

struct InvariantConfig {
    uint256 a;
    WeightLimits limits;
}

struct WeightLimits {
    uint128 min;
    uint128 max;
}

struct FeederConfig {
    uint256 supply;
    uint256 a;
    WeightLimits limits;
}

struct AmpData {
    uint64 initialA;
    uint64 targetA;
    uint64 rampStartTime;
    uint64 rampEndTime;
}

struct FeederData {
    uint256 swapFee;
    uint256 redemptionFee;
    uint256 govFee;
    uint256 pendingFees;
    uint256 cacheSize;
    BassetPersonal[] bAssetPersonal;
    BassetData[] bAssetData;
    AmpData ampData;
    WeightLimits weightLimits;
}

struct AssetData {
    uint8 idx;
    uint256 amt;
    BassetPersonal personal;
}

struct Asset {
    uint8 idx;
    address addr;
    bool exists;
}

abstract contract IFeederPool {
    // Mint
    function mint(
        address _input,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 mintOutput);

    function mintMulti(
        address[] calldata _inputs,
        uint256[] calldata _inputQuantities,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 mintOutput);

    function getMintOutput(address _input, uint256 _inputQuantity)
        external
        view
        virtual
        returns (uint256 mintOutput);

    function getMintMultiOutput(address[] calldata _inputs, uint256[] calldata _inputQuantities)
        external
        view
        virtual
        returns (uint256 mintOutput);

    // Swaps
    function swap(
        address _input,
        address _output,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 swapOutput);

    function getSwapOutput(
        address _input,
        address _output,
        uint256 _inputQuantity
    ) external view virtual returns (uint256 swapOutput);

    // Redemption
    function redeem(
        address _output,
        uint256 _mAssetQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 outputQuantity);

    function redeemProportionately(
        uint256 _mAssetQuantity,
        uint256[] calldata _minOutputQuantities,
        address _recipient
    ) external virtual returns (uint256[] memory outputQuantities);

    function redeemExactBassets(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities,
        uint256 _maxMassetQuantity,
        address _recipient
    ) external virtual returns (uint256 mAssetRedeemed);

    function getRedeemOutput(address _output, uint256 _mAssetQuantity)
        external
        view
        virtual
        returns (uint256 bAssetOutput);

    function getRedeemExactBassetsOutput(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities
    ) external view virtual returns (uint256 mAssetAmount);

    // Views
    function getPrice() public view virtual returns (uint256 price, uint256 k);

    function getConfig() external view virtual returns (FeederConfig memory config);

    function getBasset(address _token)
        external
        view
        virtual
        returns (BassetPersonal memory personal, BassetData memory data);

    function getBassets()
        external
        view
        virtual
        returns (BassetPersonal[] memory personal, BassetData[] memory data);

    // SavingsManager
    function collectPlatformInterest()
        external
        virtual
        returns (uint256 mintAmount, uint256 newSupply);
}

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


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
abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    // constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

contract ERC205 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

abstract contract InitializableERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     * @notice To avoid variable shadowing appended `Arg` after arguments name.
     */
    function _initialize(
        string memory nameArg,
        string memory symbolArg,
        uint8 decimalsArg
    ) internal {
        _name = nameArg;
        _symbol = symbolArg;
        _decimals = decimalsArg;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

abstract contract InitializableToken is ERC205, InitializableERC20Detailed {
    /**
     * @dev Initialization function for implementing contract
     * @notice To avoid variable shadowing appended `Arg` after arguments name.
     */
    function _initialize(string memory _nameArg, string memory _symbolArg) internal {
        InitializableERC20Detailed._initialize(_nameArg, _symbolArg, 18);
    }
}

contract ModuleKeys {
    // Governance
    // ===========
    // keccak256("Governance");
    bytes32 internal constant KEY_GOVERNANCE =
        0x9409903de1e6fd852dfc61c9dacb48196c48535b60e25abf92acc92dd689078d;
    //keccak256("Staking");
    bytes32 internal constant KEY_STAKING =
        0x1df41cd916959d1163dc8f0671a666ea8a3e434c13e40faef527133b5d167034;
    //keccak256("ProxyAdmin");
    bytes32 internal constant KEY_PROXY_ADMIN =
        0x96ed0203eb7e975a4cbcaa23951943fa35c5d8288117d50c12b3d48b0fab48d1;

    // mStable
    // =======
    // keccak256("OracleHub");
    bytes32 internal constant KEY_ORACLE_HUB =
        0x8ae3a082c61a7379e2280f3356a5131507d9829d222d853bfa7c9fe1200dd040;
    // keccak256("Manager");
    bytes32 internal constant KEY_MANAGER =
        0x6d439300980e333f0256d64be2c9f67e86f4493ce25f82498d6db7f4be3d9e6f;
    //keccak256("Recollateraliser");
    bytes32 internal constant KEY_RECOLLATERALISER =
        0x39e3ed1fc335ce346a8cbe3e64dd525cf22b37f1e2104a755e761c3c1eb4734f;
    //keccak256("MetaToken");
    bytes32 internal constant KEY_META_TOKEN =
        0xea7469b14936af748ee93c53b2fe510b9928edbdccac3963321efca7eb1a57a2;
    // keccak256("SavingsManager");
    bytes32 internal constant KEY_SAVINGS_MANAGER =
        0x12fe936c77a1e196473c4314f3bed8eeac1d757b319abb85bdda70df35511bf1;
    // keccak256("Liquidator");
    bytes32 internal constant KEY_LIQUIDATOR =
        0x1e9cb14d7560734a61fa5ff9273953e971ff3cd9283c03d8346e3264617933d4;
    // keccak256("InterestValidator");
    bytes32 internal constant KEY_INTEREST_VALIDATOR =
        0xc10a28f028c7f7282a03c90608e38a4a646e136e614e4b07d119280c5f7f839f;
}

interface INexus {
    function governor() external view returns (address);

    function getModule(bytes32 key) external view returns (address);

    function proposeModule(bytes32 _key, address _addr) external;

    function cancelProposedModule(bytes32 _key) external;

    function acceptProposedModule(bytes32 _key) external;

    function acceptProposedModules(bytes32[] calldata _keys) external;

    function requestLockModule(bytes32 _key) external;

    function cancelLockModule(bytes32 _key) external;

    function lockModule(bytes32 _key) external;
}

abstract contract ImmutableModule is ModuleKeys {
    INexus public immutable nexus;

    /**
     * @dev Initialization function for upgradable proxy contracts
     * @param _nexus Nexus contract address
     */
    constructor(address _nexus) {
        require(_nexus != address(0), "Nexus address is zero");
        nexus = INexus(_nexus);
    }

    /**
     * @dev Modifier to allow function calls only from the Governor.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        require(msg.sender == _governor(), "Only governor can execute");
    }

    /**
     * @dev Modifier to allow function calls only from the Governance.
     *      Governance is either Governor address or Governance address.
     */
    modifier onlyGovernance() {
        require(
            msg.sender == _governor() || msg.sender == _governance(),
            "Only governance can execute"
        );
        _;
    }

    /**
     * @dev Modifier to allow function calls only from the ProxyAdmin.
     */
    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "Only ProxyAdmin can execute");
        _;
    }

    /**
     * @dev Modifier to allow function calls only from the Manager.
     */
    modifier onlyManager() {
        require(msg.sender == _manager(), "Only manager can execute");
        _;
    }

    /**
     * @dev Returns Governor address from the Nexus
     * @return Address of Governor Contract
     */
    function _governor() internal view returns (address) {
        return nexus.governor();
    }

    /**
     * @dev Returns Governance Module address from the Nexus
     * @return Address of the Governance (Phase 2)
     */
    function _governance() internal view returns (address) {
        return nexus.getModule(KEY_GOVERNANCE);
    }

    /**
     * @dev Return Staking Module address from the Nexus
     * @return Address of the Staking Module contract
     */
    function _staking() internal view returns (address) {
        return nexus.getModule(KEY_STAKING);
    }

    /**
     * @dev Return ProxyAdmin Module address from the Nexus
     * @return Address of the ProxyAdmin Module contract
     */
    function _proxyAdmin() internal view returns (address) {
        return nexus.getModule(KEY_PROXY_ADMIN);
    }

    /**
     * @dev Return MetaToken Module address from the Nexus
     * @return Address of the MetaToken Module contract
     */
    function _metaToken() internal view returns (address) {
        return nexus.getModule(KEY_META_TOKEN);
    }

    /**
     * @dev Return OracleHub Module address from the Nexus
     * @return Address of the OracleHub Module contract
     */
    function _oracleHub() internal view returns (address) {
        return nexus.getModule(KEY_ORACLE_HUB);
    }

    /**
     * @dev Return Manager Module address from the Nexus
     * @return Address of the Manager Module contract
     */
    function _manager() internal view returns (address) {
        return nexus.getModule(KEY_MANAGER);
    }

    /**
     * @dev Return SavingsManager Module address from the Nexus
     * @return Address of the SavingsManager Module contract
     */
    function _savingsManager() internal view returns (address) {
        return nexus.getModule(KEY_SAVINGS_MANAGER);
    }

    /**
     * @dev Return Recollateraliser Module address from the Nexus
     * @return  Address of the Recollateraliser Module contract (Phase 2)
     */
    function _recollateraliser() internal view returns (address) {
        return nexus.getModule(KEY_RECOLLATERALISER);
    }
}

abstract contract PausableModule is ImmutableModule {
    /**
     * @dev Emitted when the pause is triggered by Governor
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by Governor
     */
    event Unpaused(address account);

    bool internal _paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Initializes the contract in unpaused state.
     * Hooks into the Module to give the Governor ability to pause
     * @param _nexus Nexus contract address
     */
    constructor(address _nexus) ImmutableModule(_nexus) {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     * @return Returns `true` when paused, otherwise `false`
     */
    function paused() external view returns (bool) {
        return _paused;
    }

    /**
     * @dev Called by the Governor to pause, triggers stopped state.
     */
    function pause() external onlyGovernor whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by Governor to unpause, returns to normal state.
     */
    function unpause() external onlyGovernor whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract InitializableReentrancyGuard {
    bool private _notEntered;

    function _initializeReentrancyGuard() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

interface IBasicToken {
    function decimals() external view returns (uint8);
}

library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library StableMath {
    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /**
     * @dev Token Ratios are used when converting between units of bAsset, mAsset and MTA
     * Reasoning: Takes into account token decimals, and difference in base unit (i.e. grams to Troy oz for gold)
     * bAsset ratio unit for use in exact calculations,
     * where (1 bAsset unit * bAsset.ratio) / ratioScale == x mAsset unit
     */
    uint256 private constant RATIO_SCALE = 1e8;

    /**
     * @dev Provides an interface to the scaling unit
     * @return Scaling unit (1e18 or 1 * 10**18)
     */
    function getFullScale() internal pure returns (uint256) {
        return FULL_SCALE;
    }

    /**
     * @dev Provides an interface to the ratio unit
     * @return Ratio scale unit (1e8 or 1 * 10**8)
     */
    function getRatioScale() internal pure returns (uint256) {
        return RATIO_SCALE;
    }

    /**
     * @dev Scales a given integer to the power of the full scale.
     * @param x   Simple uint256 to scale
     * @return    Scaled value a to an exact number
     */
    function scaleInteger(uint256 x) internal pure returns (uint256) {
        return x * FULL_SCALE;
    }

    /***************************************
              PRECISE ARITHMETIC
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @param scale Scale unit
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        // return 9e38 / 1e18 = 9e18
        return (x * y) / scale;
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x * y;
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled + FULL_SCALE - 1;
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil / FULL_SCALE;
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x     Left hand input to division
     * @param y     Right hand input to division
     * @return      Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e18 * 1e18 = 8e36
        // e.g. 8e36 / 10e18 = 8e17
        return (x * FULL_SCALE) / y;
    }

    /***************************************
                  RATIO FUNCS
    ****************************************/

    /**
     * @dev Multiplies and truncates a token ratio, essentially flooring the result
     *      i.e. How much mAsset is this bAsset worth?
     * @param x     Left hand operand to multiplication (i.e Exact quantity)
     * @param ratio bAsset ratio
     * @return c    Result after multiplying the two inputs and then dividing by the ratio scale
     */
    function mulRatioTruncate(uint256 x, uint256 ratio) internal pure returns (uint256 c) {
        return mulTruncateScale(x, ratio, RATIO_SCALE);
    }

    /**
     * @dev Multiplies and truncates a token ratio, rounding up the result
     *      i.e. How much mAsset is this bAsset worth?
     * @param x     Left hand input to multiplication (i.e Exact quantity)
     * @param ratio bAsset ratio
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              ratio scale, rounded up to the closest base unit.
     */
    function mulRatioTruncateCeil(uint256 x, uint256 ratio) internal pure returns (uint256) {
        // e.g. How much mAsset should I burn for this bAsset (x)?
        // 1e18 * 1e8 = 1e26
        uint256 scaled = x * ratio;
        // 1e26 + 9.99e7 = 100..00.999e8
        uint256 ceil = scaled + RATIO_SCALE - 1;
        // return 100..00.999e8 / 1e8 = 1e18
        return ceil / RATIO_SCALE;
    }

    /**
     * @dev Precisely divides two ratioed units, by first scaling the left hand operand
     *      i.e. How much bAsset is this mAsset worth?
     * @param x     Left hand operand in division
     * @param ratio bAsset ratio
     * @return c    Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divRatioPrecisely(uint256 x, uint256 ratio) internal pure returns (uint256 c) {
        // e.g. 1e14 * 1e8 = 1e22
        // return 1e22 / 1e12 = 1e10
        return (x * RATIO_SCALE) / ratio;
    }

    /***************************************
                    HELPERS
    ****************************************/

    /**
     * @dev Calculates minimum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Minimum of the two inputs
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }

    /**
     * @dev Calculated maximum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Maximum of the two inputs
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /**
     * @dev Clamps a value to an upper bound
     * @param x           Left hand input
     * @param upperBound  Maximum possible value to return
     * @return            Input x clamped to a maximum value, upperBound
     */
    function clamp(uint256 x, uint256 upperBound) internal pure returns (uint256) {
        return x > upperBound ? upperBound : x;
    }
}

interface IPlatformIntegration {
    /**
     * @dev Deposit the given bAsset to Lending platform
     * @param _bAsset bAsset address
     * @param _amount Amount to deposit
     */
    function deposit(
        address _bAsset,
        uint256 _amount,
        bool isTokenFeeCharged
    ) external returns (uint256 quantityDeposited);

    /**
     * @dev Withdraw given bAsset from Lending platform
     */
    function withdraw(
        address _receiver,
        address _bAsset,
        uint256 _amount,
        bool _hasTxFee
    ) external;

    /**
     * @dev Withdraw given bAsset from Lending platform
     */
    function withdraw(
        address _receiver,
        address _bAsset,
        uint256 _amount,
        uint256 _totalAmount,
        bool _hasTxFee
    ) external;

    /**
     * @dev Withdraw given bAsset from the cache
     */
    function withdrawRaw(
        address _receiver,
        address _bAsset,
        uint256 _amount
    ) external;

    /**
     * @dev Returns the current balance of the given bAsset
     */
    function checkBalance(address _bAsset) external returns (uint256 balance);

    /**
     * @dev Returns the pToken
     */
    function bAssetToPToken(address _bAsset) external returns (address pToken);
}

library FeederManager {
    using SafeERC20 for IERC20;
    using StableMath for uint256;

    event BassetsMigrated(address[] bAssets, address newIntegrator);
    event StartRampA(uint256 currentA, uint256 targetA, uint256 startTime, uint256 rampEndTime);
    event StopRampA(uint256 currentA, uint256 time);

    uint256 private constant MIN_RAMP_TIME = 1 days;
    uint256 private constant MAX_A = 1e6;

    /**
     * @dev Calculates the gains accrued across all lending markets.
     * @param _bAssetPersonal   Basset personal storage array
     * @param _bAssetData       Basset data storage array
     * @return idxs             Array [0,1]
     * @return rawGains         Raw increases in vault Balance
     */
    function calculatePlatformInterest(
        BassetPersonal[] memory _bAssetPersonal,
        BassetData[] storage _bAssetData
    ) external returns (uint8[] memory idxs, uint256[] memory rawGains) {
        // Get basket details
        BassetData[] memory bAssetData_ = _bAssetData;
        uint256 count = bAssetData_.length;
        idxs = new uint8[](count);
        rawGains = new uint256[](count);
        // 1. Calculate rawGains in each bAsset, in comparison to current vault balance
        for (uint256 i = 0; i < count; i++) {
            idxs[i] = uint8(i);
            BassetPersonal memory bPersonal = _bAssetPersonal[i];
            BassetData memory bData = bAssetData_[i];
            // If there is no integration, then nothing can have accrued
            if (bPersonal.integrator == address(0)) continue;
            uint256 lending =
                IPlatformIntegration(bPersonal.integrator).checkBalance(bPersonal.addr);
            uint256 cache = 0;
            if (!bPersonal.hasTxFee) {
                cache = IERC20(bPersonal.addr).balanceOf(bPersonal.integrator);
            }
            uint256 balance = lending + cache;
            uint256 oldVaultBalance = bData.vaultBalance;
            if (balance > oldVaultBalance && bPersonal.status == BassetStatus.Normal) {
                _bAssetData[i].vaultBalance = SafeCast.toUint128(balance);
                uint256 interestDelta = balance - oldVaultBalance;
                rawGains[i] = interestDelta;
            } else {
                rawGains[i] = 0;
            }
        }
    }

    /**
     * @dev Transfers all collateral from one lending market to another - used initially
     *      to handle the migration between Aave V1 and Aave V2. Note - only supports non
     *      tx fee enabled assets. Supports going from no integration to integration, but
     *      not the other way around.
     * @param _bAssetPersonal   Basset data storage array
     * @param _bAssets          Array of basket assets to migrate
     * @param _newIntegration   Address of the new platform integration
     */
    function migrateBassets(
        BassetPersonal[] storage _bAssetPersonal,
        address[] calldata _bAssets,
        address _newIntegration
    ) external {
        uint256 len = _bAssets.length;
        require(len > 0, "Must migrate some bAssets");

        for (uint256 i = 0; i < len; i++) {
            // 1. Check that the bAsset is in the basket
            address bAsset = _bAssets[i];
            uint256 index = _getAssetIndex(_bAssetPersonal, bAsset);
            require(!_bAssetPersonal[index].hasTxFee, "A bAsset has a transfer fee");

            // 2. Withdraw everything from the old platform integration
            address oldAddress = _bAssetPersonal[index].integrator;
            require(oldAddress != _newIntegration, "Must transfer to new integrator");
            (uint256 cache, uint256 lendingBal) = (0, 0);
            if (oldAddress == address(0)) {
                cache = IERC20(bAsset).balanceOf(address(this));
            } else {
                IPlatformIntegration oldIntegration = IPlatformIntegration(oldAddress);
                cache = IERC20(bAsset).balanceOf(address(oldIntegration));
                // 2.1. Withdraw from the lending market
                lendingBal = oldIntegration.checkBalance(bAsset);
                if (lendingBal > 0) {
                    oldIntegration.withdraw(address(this), bAsset, lendingBal, false);
                }
                // 2.2. Withdraw from the cache, if any
                if (cache > 0) {
                    oldIntegration.withdrawRaw(address(this), bAsset, cache);
                }
            }
            uint256 sum = lendingBal + cache;

            // 3. Update the integration address for this bAsset
            _bAssetPersonal[index].integrator = _newIntegration;

            // 4. Deposit everything into the new
            //    This should fail if we did not receive the full amount from the platform withdrawal
            // 4.1. Deposit all bAsset
            IERC20(bAsset).safeTransfer(_newIntegration, sum);
            IPlatformIntegration newIntegration = IPlatformIntegration(_newIntegration);
            if (lendingBal > 0) {
                newIntegration.deposit(bAsset, lendingBal, false);
            }
            // 4.2. Check balances
            uint256 newLendingBal = newIntegration.checkBalance(bAsset);
            uint256 newCache = IERC20(bAsset).balanceOf(address(newIntegration));
            uint256 upperMargin = 10001e14;
            uint256 lowerMargin = 9999e14;

            require(
                newLendingBal >= lendingBal.mulTruncate(lowerMargin) &&
                    newLendingBal <= lendingBal.mulTruncate(upperMargin),
                "Must transfer full amount"
            );
            require(
                newCache >= cache.mulTruncate(lowerMargin) &&
                    newCache <= cache.mulTruncate(upperMargin),
                "Must transfer full amount"
            );
        }

        emit BassetsMigrated(_bAssets, _newIntegration);
    }

    /**
     * @dev Simply gets the asset index by looping through bAssets. Given there are only
     * ever 2 assets, should not be gas intensive.
     */
    function _getAssetIndex(BassetPersonal[] storage _bAssetPersonal, address _asset)
        internal
        view
        returns (uint8 idx)
    {
        uint256 len = _bAssetPersonal.length;
        for (uint8 i = 0; i < len; i++) {
            if (_bAssetPersonal[i].addr == _asset) return i;
        }
        revert("Invalid asset");
    }

    /**
     * @dev Starts changing of the amplification var A
     * @param _targetA      Target A value
     * @param _rampEndTime  Time at which A will arrive at _targetA
     */
    function startRampA(
        AmpData storage _ampData,
        uint256 _targetA,
        uint256 _rampEndTime,
        uint256 _currentA,
        uint256 _precision
    ) external {
        require(
            block.timestamp >= (_ampData.rampStartTime + MIN_RAMP_TIME),
            "Sufficient period of previous ramp has not elapsed"
        );
        require(_rampEndTime >= (block.timestamp + MIN_RAMP_TIME), "Ramp time too short");
        require(_targetA > 0 && _targetA < MAX_A, "A target out of bounds");

        uint256 preciseTargetA = _targetA * _precision;

        if (preciseTargetA > _currentA) {
            require(preciseTargetA <= _currentA * 10, "A target increase too big");
        } else {
            require(preciseTargetA >= _currentA / 10, "A target decrease too big");
        }

        _ampData.initialA = SafeCast.toUint64(_currentA);
        _ampData.targetA = SafeCast.toUint64(preciseTargetA);
        _ampData.rampStartTime = SafeCast.toUint64(block.timestamp);
        _ampData.rampEndTime = SafeCast.toUint64(_rampEndTime);

        emit StartRampA(_currentA, preciseTargetA, block.timestamp, _rampEndTime);
    }

    /**
     * @dev Stops the changing of the amplification var A, setting
     * it to whatever the current value is.
     */
    function stopRampA(AmpData storage _ampData, uint256 _currentA) external {
        require(block.timestamp < _ampData.rampEndTime, "Amplification not changing");

        _ampData.initialA = SafeCast.toUint64(_currentA);
        _ampData.targetA = SafeCast.toUint64(_currentA);
        _ampData.rampStartTime = SafeCast.toUint64(block.timestamp);
        _ampData.rampEndTime = SafeCast.toUint64(block.timestamp);

        emit StopRampA(_currentA, block.timestamp);
    }
}

library Root {
    /**
     * @dev Returns the square root of a given number
     * @param x Input
     * @return y Square root of Input
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint256(r < r1 ? r : r1);
        }
    }
}

library MassetHelpers {
    using SafeERC20 for IERC20;

    function transferReturnBalance(
        address _sender,
        address _recipient,
        address _bAsset,
        uint256 _qty
    ) internal returns (uint256 receivedQty, uint256 recipientBalance) {
        uint256 balBefore = IERC20(_bAsset).balanceOf(_recipient);
        IERC20(_bAsset).safeTransferFrom(_sender, _recipient, _qty);
        recipientBalance = IERC20(_bAsset).balanceOf(_recipient);
        receivedQty = recipientBalance - balBefore;
    }

    function safeInfiniteApprove(address _asset, address _spender) internal {
        IERC20(_asset).safeApprove(_spender, 0);
        IERC20(_asset).safeApprove(_spender, 2**256 - 1);
    }
}

library FeederLogic {
    using StableMath for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant A_PRECISION = 100;

    /***************************************
                    MINT
    ****************************************/

    /**
     * @notice Transfers token in, updates internal balances and computes the fpToken output
     * @param _data                 Feeder pool storage state
     * @param _config               Core config for use in the invariant validator
     * @param _input                Data on the bAsset to deposit for the minted fpToken.
     * @param _inputQuantity        Quantity in input token units.
     * @param _minOutputQuantity    Minimum fpToken quantity to be minted. This protects against slippage.
     * @return mintOutput           Quantity of fpToken minted from the deposited bAsset.
     */
    function mint(
        FeederData storage _data,
        FeederConfig calldata _config,
        Asset calldata _input,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity
    ) external returns (uint256 mintOutput) {
        BassetData[] memory cachedBassetData = _data.bAssetData;
        AssetData memory inputData =
            _transferIn(_data, _config, cachedBassetData, _input, _inputQuantity);
        // Validation should be after token transfer, as real input amt is unknown before
        mintOutput = computeMint(cachedBassetData, inputData.idx, inputData.amt, _config);
        require(mintOutput >= _minOutputQuantity, "Mint quantity < min qty");
    }

    /**
     * @notice Transfers tokens in, updates internal balances and computes the fpToken output.
     * Only fAsset & mAsset are supported in this path.
     * @param _data                 Feeder pool storage state
     * @param _config               Core config for use in the invariant validator
     * @param _indices              Non-duplicate addresses of the bAssets to deposit for the minted fpToken.
     * @param _inputQuantities      Quantity of each input in input token units.
     * @param _minOutputQuantity    Minimum fpToken quantity to be minted. This protects against slippage.
     * @return mintOutput           Quantity of fpToken minted from the deposited bAsset.
     */
    function mintMulti(
        FeederData storage _data,
        FeederConfig calldata _config,
        uint8[] calldata _indices,
        uint256[] calldata _inputQuantities,
        uint256 _minOutputQuantity
    ) external returns (uint256 mintOutput) {
        uint256 len = _indices.length;
        uint256[] memory quantitiesDeposited = new uint256[](len);
        // Load bAssets from storage into memory
        BassetData[] memory allBassets = _data.bAssetData;
        uint256 maxCache = _getCacheDetails(_data, _config.supply);
        // Transfer the Bassets to the integrator & update storage
        for (uint256 i = 0; i < len; i++) {
            if (_inputQuantities[i] > 0) {
                uint8 idx = _indices[i];
                BassetData memory bData = allBassets[idx];
                quantitiesDeposited[i] = _depositTokens(
                    _data.bAssetPersonal[idx],
                    bData.ratio,
                    _inputQuantities[i],
                    maxCache
                );

                _data.bAssetData[idx].vaultBalance =
                    bData.vaultBalance +
                    SafeCast.toUint128(quantitiesDeposited[i]);
            }
        }
        // Validate the proposed mint, after token transfer
        mintOutput = computeMintMulti(allBassets, _indices, quantitiesDeposited, _config);
        require(mintOutput >= _minOutputQuantity, "Mint quantity < min qty");
        require(mintOutput > 0, "Zero mAsset quantity");
    }

    /***************************************
                    SWAP
    ****************************************/

    /**
     * @notice Swaps two assets - either internally between fAsset<>mAsset, or between fAsset<>mpAsset by
     * first routing through the mAsset pool.
     * @param _data              Feeder pool storage state
     * @param _config            Core config for use in the invariant validator
     * @param _input             Data on bAsset to deposit
     * @param _output            Data on bAsset to withdraw
     * @param _inputQuantity     Units of input bAsset to swap in
     * @param _minOutputQuantity Minimum quantity of the swap output asset. This protects against slippage
     * @param _recipient         Address to transfer output asset to
     * @return swapOutput        Quantity of output asset returned from swap
     * @return localFee          Fee paid, in fpToken terms
     */
    function swap(
        FeederData storage _data,
        FeederConfig calldata _config,
        Asset calldata _input,
        Asset calldata _output,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 swapOutput, uint256 localFee) {
        BassetData[] memory cachedBassetData = _data.bAssetData;

        AssetData memory inputData =
            _transferIn(_data, _config, cachedBassetData, _input, _inputQuantity);
        // 1. [f/mAsset ->][ f/mAsset]               : Y - normal in, SWAP, normal out
        // 3. [mpAsset -> mAsset][ -> fAsset]        : Y - mint in  , SWAP, normal out
        if (_output.exists) {
            (swapOutput, localFee) = _swapLocal(
                _data,
                _config,
                cachedBassetData,
                inputData,
                _output,
                _minOutputQuantity,
                _recipient
            );
        }
        // 2. [fAsset ->][ mAsset][ -> mpAsset]      : Y - normal in, SWAP, mpOut
        else {
            address mAsset = _data.bAssetPersonal[0].addr;
            (swapOutput, localFee) = _swapLocal(
                _data,
                _config,
                cachedBassetData,
                inputData,
                Asset(0, mAsset, true),
                0,
                address(this)
            );
            swapOutput = IMasset(mAsset).redeem(
                _output.addr,
                swapOutput,
                _minOutputQuantity,
                _recipient
            );
        }
    }

    /***************************************
                    REDEEM
    ****************************************/

    /**
     * @notice Burns a specified quantity of the senders fpToken in return for a bAsset. The output amount is derived
     * from the invariant. Supports redemption into either the fAsset, mAsset or assets in the mAsset basket.
     * @param _data              Feeder pool storage state
     * @param _config            Core config for use in the invariant validator
     * @param _output            Data on bAsset to withdraw
     * @param _fpTokenQuantity   Quantity of fpToken to burn
     * @param _minOutputQuantity Minimum bAsset quantity to receive for the burnt fpToken. This protects against slippage.
     * @param _recipient         Address to transfer the withdrawn bAssets to.
     * @return outputQuantity    Quanity of bAsset units received for the burnt fpToken
     * @return localFee          Fee paid, in fpToken terms
     */
    function redeem(
        FeederData storage _data,
        FeederConfig calldata _config,
        Asset calldata _output,
        uint256 _fpTokenQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 outputQuantity, uint256 localFee) {
        if (_output.exists) {
            (outputQuantity, localFee) = _redeemLocal(
                _data,
                _config,
                _output,
                _fpTokenQuantity,
                _minOutputQuantity,
                _recipient
            );
        } else {
            address mAsset = _data.bAssetPersonal[0].addr;
            (outputQuantity, localFee) = _redeemLocal(
                _data,
                _config,
                Asset(0, mAsset, true),
                _fpTokenQuantity,
                0,
                address(this)
            );
            outputQuantity = IMasset(mAsset).redeem(
                _output.addr,
                outputQuantity,
                _minOutputQuantity,
                _recipient
            );
        }
    }

    /**
     * @dev Credits a recipient with a proportionate amount of bAssets, relative to current vault
     * balance levels and desired fpToken quantity. Burns the fpToken as payment. Only fAsset & mAsset are supported in this path.
     * @param _data                 Feeder pool storage state
     * @param _config               Core config for use in the invariant validator
     * @param _inputQuantity        Quantity of fpToken to redeem
     * @param _minOutputQuantities  Min units of output to receive
     * @param _recipient            Address to credit the withdrawn bAssets
     * @return scaledFee            Fee collected in fpToken terms
     * @return outputs              Array of output asset addresses
     * @return outputQuantities     Array of output asset quantities
     */
    function redeemProportionately(
        FeederData storage _data,
        FeederConfig calldata _config,
        uint256 _inputQuantity,
        uint256[] calldata _minOutputQuantities,
        address _recipient
    )
        external
        returns (
            uint256 scaledFee,
            address[] memory outputs,
            uint256[] memory outputQuantities
        )
    {
        // Calculate mAsset redemption quantities
        scaledFee = _inputQuantity.mulTruncate(_data.redemptionFee);
        // cache = (config.supply - inputQuantity) * 0.2
        uint256 maxCache = _getCacheDetails(_data, _config.supply - _inputQuantity);

        // Load the bAsset data from storage into memory
        BassetData[] memory allBassets = _data.bAssetData;
        uint256 len = allBassets.length;
        outputs = new address[](len);
        outputQuantities = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            // Get amount out, proportionate to redemption quantity
            uint256 amountOut =
                (allBassets[i].vaultBalance * (_inputQuantity - scaledFee)) / _config.supply;
            require(amountOut > 1, "Output == 0");
            amountOut -= 1;
            require(amountOut >= _minOutputQuantities[i], "bAsset qty < min qty");
            // Set output in array
            (outputQuantities[i], outputs[i]) = (amountOut, _data.bAssetPersonal[i].addr);
            // Transfer the bAsset to the recipient
            _withdrawTokens(
                amountOut,
                _data.bAssetPersonal[i],
                allBassets[i],
                _recipient,
                maxCache
            );
            // Reduce vaultBalance
            _data.bAssetData[i].vaultBalance =
                allBassets[i].vaultBalance -
                SafeCast.toUint128(amountOut);
        }
    }

    /**
     * @dev Credits a recipient with a certain quantity of selected bAssets, in exchange for burning the
     *      relative fpToken quantity from the sender. Only fAsset & mAsset (0,1) are supported in this path.
     * @param _data                 Feeder pool storage state
     * @param _config               Core config for use in the invariant validator
     * @param _indices              Indices of the bAssets to receive
     * @param _outputQuantities     Units of the bAssets to receive
     * @param _maxInputQuantity     Maximum fpToken quantity to burn for the received bAssets. This protects against slippage.
     * @param _recipient            Address to receive the withdrawn bAssets
     * @return fpTokenQuantity      Quantity of fpToken units to burn as payment
     * @return localFee             Fee collected, in fpToken terms
     */
    function redeemExactBassets(
        FeederData storage _data,
        FeederConfig memory _config,
        uint8[] calldata _indices,
        uint256[] calldata _outputQuantities,
        uint256 _maxInputQuantity,
        address _recipient
    ) external returns (uint256 fpTokenQuantity, uint256 localFee) {
        // Load bAsset data from storage to memory
        BassetData[] memory allBassets = _data.bAssetData;

        // Validate redemption
        uint256 fpTokenRequired =
            computeRedeemExact(allBassets, _indices, _outputQuantities, _config);
        fpTokenQuantity = fpTokenRequired.divPrecisely(1e18 - _data.redemptionFee);
        localFee = fpTokenQuantity - fpTokenRequired;
        require(fpTokenQuantity > 0, "Must redeem some mAssets");
        fpTokenQuantity += 1;
        require(fpTokenQuantity <= _maxInputQuantity, "Redeem mAsset qty > max quantity");

        // Burn the full amount of Masset
        uint256 maxCache = _getCacheDetails(_data, _config.supply - fpTokenQuantity);
        // Transfer the Bassets to the recipient
        for (uint256 i = 0; i < _outputQuantities.length; i++) {
            _withdrawTokens(
                _outputQuantities[i],
                _data.bAssetPersonal[_indices[i]],
                allBassets[_indices[i]],
                _recipient,
                maxCache
            );
            _data.bAssetData[_indices[i]].vaultBalance =
                allBassets[_indices[i]].vaultBalance -
                SafeCast.toUint128(_outputQuantities[i]);
        }
    }

    /***************************************
                FORGING - INTERNAL
    ****************************************/

    /**
     * @dev Transfers an asset in and updates vault balance. Supports fAsset, mAsset and mpAsset.
     * Transferring an mpAsset requires first a mint in the main pool, and consequent depositing of
     * the mAsset.
     */
    function _transferIn(
        FeederData storage _data,
        FeederConfig memory _config,
        BassetData[] memory _cachedBassetData,
        Asset memory _input,
        uint256 _inputQuantity
    ) internal returns (AssetData memory inputData) {
        // fAsset / mAsset transfers
        if (_input.exists) {
            BassetPersonal memory personal = _data.bAssetPersonal[_input.idx];
            uint256 amt =
                _depositTokens(
                    personal,
                    _cachedBassetData[_input.idx].ratio,
                    _inputQuantity,
                    _getCacheDetails(_data, _config.supply)
                );
            inputData = AssetData(_input.idx, amt, personal);
        }
        // mpAsset transfers
        else {
            inputData = _mpMint(
                _data,
                _input,
                _inputQuantity,
                _getCacheDetails(_data, _config.supply)
            );
            require(inputData.amt > 0, "Must mint something from mp");
        }
        _data.bAssetData[inputData.idx].vaultBalance =
            _cachedBassetData[inputData.idx].vaultBalance +
            SafeCast.toUint128(inputData.amt);
    }

    /**
     * @dev Mints an asset in the main mAsset pool. Input asset must be supported by the mAsset
     * or else the call will revert. After minting, check if the balance exceeds the cache upper limit
     * and consequently deposit if necessary.
     */
    function _mpMint(
        FeederData storage _data,
        Asset memory _input,
        uint256 _inputQuantity,
        uint256 _maxCache
    ) internal returns (AssetData memory mAssetData) {
        mAssetData = AssetData(0, 0, _data.bAssetPersonal[0]);
        IERC20(_input.addr).safeTransferFrom(msg.sender, address(this), _inputQuantity);

        address integrator =
            mAssetData.personal.integrator == address(0)
                ? address(this)
                : mAssetData.personal.integrator;

        uint256 balBefore = IERC20(mAssetData.personal.addr).balanceOf(integrator);
        // Mint will revert if the _input.addr is not whitelisted on that mAsset
        IMasset(mAssetData.personal.addr).mint(_input.addr, _inputQuantity, 0, integrator);
        uint256 balAfter = IERC20(mAssetData.personal.addr).balanceOf(integrator);
        mAssetData.amt = balAfter - balBefore;

        // Route the mAsset to platform integration
        if (integrator != address(this)) {
            if (balAfter > _maxCache) {
                uint256 delta = balAfter - (_maxCache / 2);
                IPlatformIntegration(integrator).deposit(mAssetData.personal.addr, delta, false);
            }
        }
    }

    /**
     * @dev Performs a swap between fAsset and mAsset. If the output is an mAsset, do not
     * charge the swap fee.
     */
    function _swapLocal(
        FeederData storage _data,
        FeederConfig memory _config,
        BassetData[] memory _cachedBassetData,
        AssetData memory _inputData,
        Asset memory _output,
        uint256 _minOutputQuantity,
        address _recipient
    ) internal returns (uint256 swapOutput, uint256 scaledFee) {
        // Validate the swap
        (swapOutput, scaledFee) = computeSwap(
            _cachedBassetData,
            _inputData.idx,
            _output.idx,
            _inputData.amt,
            _output.idx == 0 ? 0 : _data.swapFee,
            _config
        );
        require(swapOutput >= _minOutputQuantity, "Output qty < minimum qty");
        require(swapOutput > 0, "Zero output quantity");
        // Settle the swap
        _withdrawTokens(
            swapOutput,
            _data.bAssetPersonal[_output.idx],
            _cachedBassetData[_output.idx],
            _recipient,
            _getCacheDetails(_data, _config.supply)
        );
        // Decrease output bal
        _data.bAssetData[_output.idx].vaultBalance =
            _cachedBassetData[_output.idx].vaultBalance -
            SafeCast.toUint128(swapOutput);
    }

    /**
     * @dev Performs a local redemption into either fAsset or mAsset.
     */
    function _redeemLocal(
        FeederData storage _data,
        FeederConfig memory _config,
        Asset memory _output,
        uint256 _fpTokenQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) internal returns (uint256 outputQuantity, uint256 scaledFee) {
        BassetData[] memory allBassets = _data.bAssetData;
        // Subtract the redemption fee
        scaledFee = _fpTokenQuantity.mulTruncate(_data.redemptionFee);
        // Calculate redemption quantities
        outputQuantity = computeRedeem(
            allBassets,
            _output.idx,
            _fpTokenQuantity - scaledFee,
            _config
        );
        require(outputQuantity >= _minOutputQuantity, "bAsset qty < min qty");
        require(outputQuantity > 0, "Output == 0");

        // Transfer the bAssets to the recipient
        _withdrawTokens(
            outputQuantity,
            _data.bAssetPersonal[_output.idx],
            allBassets[_output.idx],
            _recipient,
            _getCacheDetails(_data, _config.supply - _fpTokenQuantity)
        );
        // Set vault balance
        _data.bAssetData[_output.idx].vaultBalance =
            allBassets[_output.idx].vaultBalance -
            SafeCast.toUint128(outputQuantity);
    }

    /**
     * @dev Deposits a given asset to the system. If there is sufficient room for the asset
     * in the cache, then just transfer, otherwise reset the cache to the desired mid level by
     * depositing the delta in the platform
     */
    function _depositTokens(
        BassetPersonal memory _bAsset,
        uint256 _bAssetRatio,
        uint256 _quantity,
        uint256 _maxCache
    ) internal returns (uint256 quantityDeposited) {
        // 0. If integration is 0, short circuit
        if (_bAsset.integrator == address(0)) {
            (uint256 received, ) =
                MassetHelpers.transferReturnBalance(
                    msg.sender,
                    address(this),
                    _bAsset.addr,
                    _quantity
                );
            return received;
        }

        // 1 - Send all to PI, using the opportunity to get the cache balance and net amount transferred
        uint256 cacheBal;
        (quantityDeposited, cacheBal) = MassetHelpers.transferReturnBalance(
            msg.sender,
            _bAsset.integrator,
            _bAsset.addr,
            _quantity
        );

        // 2 - Deposit X if necessary
        // 2.1 - Deposit if xfer fees
        if (_bAsset.hasTxFee) {
            uint256 deposited =
                IPlatformIntegration(_bAsset.integrator).deposit(
                    _bAsset.addr,
                    quantityDeposited,
                    true
                );

            return StableMath.min(deposited, quantityDeposited);
        }
        // 2.2 - Else Deposit X if Cache > %
        // This check is in place to ensure that any token with a txFee is rejected
        require(quantityDeposited == _quantity, "Asset not fully transferred");

        uint256 relativeMaxCache = _maxCache.divRatioPrecisely(_bAssetRatio);

        if (cacheBal > relativeMaxCache) {
            uint256 delta = cacheBal - (relativeMaxCache / 2);
            IPlatformIntegration(_bAsset.integrator).deposit(_bAsset.addr, delta, false);
        }
    }

    /**
     * @dev Withdraws a given asset from its platformIntegration. If there is sufficient liquidity
     * in the cache, then withdraw from there, otherwise withdraw from the lending market and reset the
     * cache to the mid level.
     */
    function _withdrawTokens(
        uint256 _quantity,
        BassetPersonal memory _personal,
        BassetData memory _data,
        address _recipient,
        uint256 _maxCache
    ) internal {
        if (_quantity == 0) return;

        // 1.0 If there is no integrator, send from here
        if (_personal.integrator == address(0)) {
            // If this is part of a cross-swap or cross-redeem, and there is no
            // integrator.. then we don't need to transfer anywhere
            if (_recipient == address(this)) return;
            IERC20(_personal.addr).safeTransfer(_recipient, _quantity);
        }
        // 1.1 If txFee then short circuit - there is no cache
        else if (_personal.hasTxFee) {
            IPlatformIntegration(_personal.integrator).withdraw(
                _recipient,
                _personal.addr,
                _quantity,
                _quantity,
                true
            );
        }
        // 1.2. Else, withdraw from either cache or main vault
        else {
            uint256 cacheBal = IERC20(_personal.addr).balanceOf(_personal.integrator);
            // 2.1 - If balance b in cache, simply withdraw
            if (cacheBal >= _quantity) {
                IPlatformIntegration(_personal.integrator).withdrawRaw(
                    _recipient,
                    _personal.addr,
                    _quantity
                );
            }
            // 2.2 - Else reset the cache to X, or as far as possible
            //       - Withdraw X+b from platform
            //       - Send b to user
            else {
                uint256 relativeMidCache = _maxCache.divRatioPrecisely(_data.ratio) / 2;
                uint256 totalWithdrawal =
                    StableMath.min(
                        relativeMidCache + _quantity - cacheBal,
                        _data.vaultBalance - SafeCast.toUint128(cacheBal)
                    );

                IPlatformIntegration(_personal.integrator).withdraw(
                    _recipient,
                    _personal.addr,
                    _quantity,
                    totalWithdrawal,
                    false
                );
            }
        }
    }

    /**
     * @dev Gets the max cache size, given the supply of fpToken
     * @return maxCache    Max units of any given bAsset that should be held in the cache
     */
    function _getCacheDetails(FeederData storage _data, uint256 _supply)
        internal
        view
        returns (uint256 maxCache)
    {
        maxCache = (_supply * _data.cacheSize) / 1e18;
    }

    /***************************************
                    INVARIANT
    ****************************************/

    /**
     * @notice Compute the amount of fpToken received for minting
     * with `quantity` amount of bAsset index `i`.
     * @param _bAssets      Array of all bAsset Data
     * @param _i            Index of bAsset with which to mint
     * @param _rawInput     Raw amount of bAsset to use in mint
     * @param _config       Generalised FeederConfig stored externally
     * @return mintAmount   Quantity of fpTokens minted
     */
    function computeMint(
        BassetData[] memory _bAssets,
        uint8 _i,
        uint256 _rawInput,
        FeederConfig memory _config
    ) public pure returns (uint256 mintAmount) {
        // 1. Get raw reserves
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        // 2. Get value of reserves according to invariant
        uint256 k0 = _invariant(x, sum, _config.a);
        uint256 scaledInput = (_rawInput * _bAssets[_i].ratio) / 1e8;
        require(scaledInput > 1e6, "Must add > 1e6 units");
        // 3. Add deposit to x and sum
        x[_i] += scaledInput;
        sum += scaledInput;
        // 4. Finalise mint
        require(_inBounds(x, sum, _config.limits), "Exceeds weight limits");
        mintAmount = _computeMintOutput(x, sum, k0, _config);
    }

    /**
     * @notice Compute the amount of fpToken received for minting
     * with the given array of inputs.
     * @param _bAssets      Array of all bAsset Data
     * @param _indices      Indexes of bAssets with which to mint
     * @param _rawInputs    Raw amounts of bAssets to use in mint
     * @param _config       Generalised FeederConfig stored externally
     * @return mintAmount   Quantity of fpTokens minted
     */
    function computeMintMulti(
        BassetData[] memory _bAssets,
        uint8[] memory _indices,
        uint256[] memory _rawInputs,
        FeederConfig memory _config
    ) public pure returns (uint256 mintAmount) {
        // 1. Get raw reserves
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        // 2. Get value of reserves according to invariant
        uint256 k0 = _invariant(x, sum, _config.a);
        // 3. Add deposits to x and sum
        uint256 len = _indices.length;
        uint8 idx;
        uint256 scaledInput;
        for (uint256 i = 0; i < len; i++) {
            idx = _indices[i];
            scaledInput = (_rawInputs[i] * _bAssets[idx].ratio) / 1e8;
            x[idx] += scaledInput;
            sum += scaledInput;
        }
        // 4. Finalise mint
        require(_inBounds(x, sum, _config.limits), "Exceeds weight limits");
        mintAmount = _computeMintOutput(x, sum, k0, _config);
    }

    /**
     * @notice Compute the amount of bAsset received for swapping
     * `quantity` amount of index `input_idx` to index `output_idx`.
     * @param _bAssets      Array of all bAsset Data
     * @param _i            Index of bAsset to swap IN
     * @param _o            Index of bAsset to swap OUT
     * @param _rawInput     Raw amounts of input bAsset to input
     * @param _feeRate      Swap fee rate to apply to output
     * @param _config       Generalised FeederConfig stored externally
     * @return bAssetOutputQuantity   Raw bAsset output quantity
     * @return scaledSwapFee          Swap fee collected, in fpToken terms
     */
    function computeSwap(
        BassetData[] memory _bAssets,
        uint8 _i,
        uint8 _o,
        uint256 _rawInput,
        uint256 _feeRate,
        FeederConfig memory _config
    ) public pure returns (uint256 bAssetOutputQuantity, uint256 scaledSwapFee) {
        // 1. Get raw reserves
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        // 2. Get value of reserves according to invariant
        uint256 k0 = _invariant(x, sum, _config.a);
        // 3. Add deposits to x and sum
        uint256 scaledInput = (_rawInput * _bAssets[_i].ratio) / 1e8;
        require(scaledInput > 1e6, "Must add > 1e6 units");
        x[_i] += scaledInput;
        sum += scaledInput;
        // 4. Calc total fpToken q
        uint256 k1 = _invariant(x, sum, _config.a);
        scaledSwapFee = ((k1 - k0) * _feeRate) / 1e18;
        // 5. Calc output bAsset
        uint256 newOutputReserve = _solveInvariant(x, _config.a, _o, k0 + scaledSwapFee);
        // Convert swap fee to fpToken terms
        // fpFee = fee * s / k
        scaledSwapFee = (scaledSwapFee * _config.supply) / k0;
        uint256 output = x[_o] - newOutputReserve - 1;
        bAssetOutputQuantity = (output * 1e8) / _bAssets[_o].ratio;
        // 6. Check for bounds
        x[_o] -= output;
        sum -= output;
        require(_inBounds(x, sum, _config.limits), "Exceeds weight limits");
    }

    /**
     * @notice Compute the amount of bAsset index `i` received for
     * redeeming `quantity` amount of fpToken.
     * @param _bAssets              Array of all bAsset Data
     * @param _o                    Index of output bAsset
     * @param _netRedeemInput       Net amount of fpToken to redeem
     * @param _config               Generalised FeederConfig stored externally
     * @return rawOutputUnits       Raw bAsset output returned
     */
    function computeRedeem(
        BassetData[] memory _bAssets,
        uint8 _o,
        uint256 _netRedeemInput,
        FeederConfig memory _config
    ) public pure returns (uint256 rawOutputUnits) {
        require(_netRedeemInput > 1e6, "Must redeem > 1e6 units");
        // 1. Get raw reserves
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        // 2. Get value of reserves according to invariant
        uint256 k0 = _invariant(x, sum, _config.a);
        uint256 kFinal = (k0 * (_config.supply - _netRedeemInput)) / _config.supply + 1;
        // 3. Compute bAsset output
        uint256 newOutputReserve = _solveInvariant(x, _config.a, _o, kFinal);
        uint256 output = x[_o] - newOutputReserve - 1;
        rawOutputUnits = (output * 1e8) / _bAssets[_o].ratio;
        // 4. Check for max weight
        x[_o] -= output;
        sum -= output;
        require(_inBounds(x, sum, _config.limits), "Exceeds weight limits");
    }

    /**
     * @notice Compute the amount of fpToken required to redeem
     * a given selection of bAssets.
     * @param _bAssets          Array of all bAsset Data
     * @param _indices          Indexes of output bAssets
     * @param _rawOutputs       Desired raw bAsset outputs
     * @param _config           Generalised FeederConfig stored externally
     * @return redeemInput      Amount of fpToken required to redeem bAssets
     */
    function computeRedeemExact(
        BassetData[] memory _bAssets,
        uint8[] memory _indices,
        uint256[] memory _rawOutputs,
        FeederConfig memory _config
    ) public pure returns (uint256 redeemInput) {
        // 1. Get raw reserves
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        // 2. Get value of reserves according to invariant
        uint256 k0 = _invariant(x, sum, _config.a);
        // 3. Sub deposits from x and sum
        uint256 len = _indices.length;
        uint256 ratioed;
        for (uint256 i = 0; i < len; i++) {
            ratioed = (_rawOutputs[i] * _bAssets[_indices[i]].ratio) / 1e8;
            x[_indices[i]] -= ratioed;
            sum -= ratioed;
        }
        require(_inBounds(x, sum, _config.limits), "Exceeds weight limits");
        // 4. Get new value of reserves according to invariant
        uint256 k1 = _invariant(x, sum, _config.a);
        // 5. Total fpToken is the difference between values
        redeemInput = (_config.supply * (k0 - k1)) / k0;
        require(redeemInput > 1e6, "Must redeem > 1e6 units");
    }

    /**
     * @notice Gets the price of the fpToken, and invariant value k
     * @param _bAssets  Array of all bAsset Data
     * @param _config   Generalised FeederConfig stored externally
     * @return price    Price of an fpToken
     * @return k        Total value of basket, k
     */
    function computePrice(BassetData[] memory _bAssets, FeederConfig memory _config)
        public
        pure
        returns (uint256 price, uint256 k)
    {
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        k = _invariant(x, sum, _config.a);
        price = (1e18 * k) / _config.supply;
    }

    /***************************************
                    INTERNAL
    ****************************************/

    /**
     * @dev Computes the actual mint output after adding mint inputs
     * to the vault balances
     * @param _x            Scaled vaultBalances
     * @param _sum          Sum of vaultBalances, to avoid another loop
     * @param _k            Previous value of invariant, k, before addition
     * @param _config       Generalised FeederConfig stored externally
     * @return mintAmount   Amount of value added to invariant, in fpToken terms
     */
    function _computeMintOutput(
        uint256[] memory _x,
        uint256 _sum,
        uint256 _k,
        FeederConfig memory _config
    ) internal pure returns (uint256 mintAmount) {
        // 1. Get value of reserves according to invariant
        uint256 kFinal = _invariant(_x, _sum, _config.a);
        // 2. Total minted is the difference between values, with respect to total supply
        if (_config.supply == 0) {
            mintAmount = kFinal - _k;
        } else {
            mintAmount = (_config.supply * (kFinal - _k)) / _k;
        }
    }

    /**
     * @dev Simply scaled raw reserve values and returns the sum
     * @param _bAssets  All bAssets
     * @return x        Scaled vault balances
     * @return sum      Sum of scaled vault balances
     */
    function _getReserves(BassetData[] memory _bAssets)
        internal
        pure
        returns (uint256[] memory x, uint256 sum)
    {
        uint256 len = _bAssets.length;
        x = new uint256[](len);
        uint256 r;
        for (uint256 i = 0; i < len; i++) {
            BassetData memory bAsset = _bAssets[i];
            r = (bAsset.vaultBalance * bAsset.ratio) / 1e8;
            x[i] = r;
            sum += r;
        }
    }

    /**
     * @dev Checks that no bAsset reserves exceed max weight
     * @param _x            Scaled bAsset reserves
     * @param _sum          Sum of x, precomputed
     * @param _limits       Config object containing max and min weights
     * @return inBounds     Bool, true if all assets are within bounds
     */
    function _inBounds(
        uint256[] memory _x,
        uint256 _sum,
        WeightLimits memory _limits
    ) internal pure returns (bool inBounds) {
        uint256 len = _x.length;
        inBounds = true;
        uint256 w;
        for (uint256 i = 0; i < len; i++) {
            w = (_x[i] * 1e18) / _sum;
            if (w > _limits.max || w < _limits.min) return false;
        }
    }

    /***************************************
                    INVARIANT
    ****************************************/

    /**
     * @dev Compute the invariant f(x) for a given array of supplies `x`.
     * @param _x        Scaled vault balances
     * @param _sum      Sum of scaled vault balances
     * @param _a        Precise amplification coefficient
     * @return k        Cumulative value of all assets according to the invariant
     */
    function _invariant(
        uint256[] memory _x,
        uint256 _sum,
        uint256 _a
    ) internal pure returns (uint256 k) {
        if (_sum == 0) return 0;

        uint256 var1 = _x[0] * _x[1];
        uint256 var2 = (_a * var1) / (_x[0] + _x[1]) / A_PRECISION;
        // result = 2 * (isqrt(var2**2 + (A + A_PRECISION) * var1 // A_PRECISION) - var2) + 1
        k = 2 * (Root.sqrt((var2**2) + (((_a + A_PRECISION) * var1) / A_PRECISION)) - var2) + 1;
    }

    /**
     * @dev Solves the invariant for _i with respect to target K, given an array of reserves.
     * @param _x        Scaled reserve balances
     * @param _a        Precise amplification coefficient
     * @param _idx      Index of asset for which to solve
     * @param _targetK  Target invariant value K
     * @return y        New reserve of _i
     */
    function _solveInvariant(
        uint256[] memory _x,
        uint256 _a,
        uint8 _idx,
        uint256 _targetK
    ) internal pure returns (uint256 y) {
        require(_idx == 0 || _idx == 1, "Invalid index");

        uint256 x = _idx == 0 ? _x[1] : _x[0];
        uint256 var1 = _a + A_PRECISION;
        uint256 var2 = ((_targetK**2) * A_PRECISION) / var1;
        // var3 = var2 // (4 * x) + k * _a // var1 - x
        uint256 tmp = var2 / (4 * x) + ((_targetK * _a) / var1);
        uint256 var3 = tmp >= x ? tmp - x : x - tmp;
        //  result = (sqrt(var3**2 + var2) + var3) // 2
        y = ((Root.sqrt((var3**2) + var2) + tmp - x) / 2) + 1;
    }
}


// External
// Internal
// Libs
/**
 * @title   FeederPool
 * @author  mStable
 * @notice  Base contract for Feeder Pools (fPools). Feeder Pools are combined of 50/50 fAsset and mAsset. This supports
 *          efficient swaps into and out of mAssets and the bAssets in the mAsset basket (a.k.a mpAssets). There is 0
 *          fee to trade from fAsset into mAsset, providing low cost on-ramps into mAssets.
 * @dev     VERSION: 1.0
 *          DATE:    2021-03-01
 */
contract FeederPool is
    IFeederPool,
    Initializable,
    InitializableToken,
    PausableModule,
    InitializableReentrancyGuard
{
    using SafeERC20 for IERC20;
    using StableMath for uint256;

    // Forging Events
    event Minted(
        address indexed minter,
        address recipient,
        uint256 output,
        address input,
        uint256 inputQuantity
    );
    event MintedMulti(
        address indexed minter,
        address recipient,
        uint256 output,
        address[] inputs,
        uint256[] inputQuantities
    );
    event Swapped(
        address indexed swapper,
        address input,
        address output,
        uint256 outputAmount,
        uint256 fee,
        address recipient
    );
    event Redeemed(
        address indexed redeemer,
        address recipient,
        uint256 mAssetQuantity,
        address output,
        uint256 outputQuantity,
        uint256 scaledFee
    );
    event RedeemedMulti(
        address indexed redeemer,
        address recipient,
        uint256 mAssetQuantity,
        address[] outputs,
        uint256[] outputQuantity,
        uint256 scaledFee
    );
    // State Events
    event CacheSizeChanged(uint256 cacheSize);
    event FeesChanged(uint256 swapFee, uint256 redemptionFee, uint256 govFee);
    event WeightLimitsChanged(uint128 min, uint128 max);

    // FeederManager Events
    event BassetsMigrated(address[] bAssets, address newIntegrator);
    event StartRampA(uint256 currentA, uint256 targetA, uint256 startTime, uint256 rampEndTime);
    event StopRampA(uint256 currentA, uint256 time);

    // Constants
    uint256 private constant MAX_FEE = 1e16;
    uint256 private constant A_PRECISION = 100;
    address public immutable mAsset;

    // Core data storage
    FeederData public data;

    /**
     * @dev Constructor to set immutable bytecode
     * @param _nexus   Nexus address
     * @param _mAsset  Immutable mAsset address
     */
    constructor(address _nexus, address _mAsset) PausableModule(_nexus) {
        mAsset = _mAsset;
    }

    /**
     * @dev Basic initializer. Sets up core state and importantly provides infinite approvals to the mAsset pool
     * to support the cross pool swaps. bAssetData and bAssetPersonal are always ordered [mAsset, fAsset].
     * @param _nameArg     Name of the fPool token (a.k.a. fpToken)
     * @param _symbolArg   Symbol of the fPool token
     * @param _mAsset      Details on the base mAsset
     * @param _fAsset      Details on the attached fAsset
     * @param _mpAssets    Array of bAssets from the mAsset (to approve)
     * @param _config      Starting invariant config
     */
    function initialize(
        string calldata _nameArg,
        string calldata _symbolArg,
        BassetPersonal calldata _mAsset,
        BassetPersonal calldata _fAsset,
        address[] calldata _mpAssets,
        InvariantConfig memory _config
    ) public initializer {
        InitializableToken._initialize(_nameArg, _symbolArg);

        _initializeReentrancyGuard();

        require(_mAsset.addr == mAsset, "mAsset incorrect");
        data.bAssetPersonal.push(
            BassetPersonal(_mAsset.addr, _mAsset.integrator, false, BassetStatus.Normal)
        );
        data.bAssetData.push(BassetData(1e8, 0));
        data.bAssetPersonal.push(
            BassetPersonal(_fAsset.addr, _fAsset.integrator, _fAsset.hasTxFee, BassetStatus.Normal)
        );
        data.bAssetData.push(
            BassetData(SafeCast.toUint128(10**(26 - IBasicToken(_fAsset.addr).decimals())), 0)
        );
        for (uint256 i = 0; i < _mpAssets.length; i++) {
            // Call will fail if bAsset does not exist
            IMasset(_mAsset.addr).getBasset(_mpAssets[i]);
            IERC20(_mpAssets[i]).safeApprove(_mAsset.addr, 2**255);
        }

        uint64 startA = SafeCast.toUint64(_config.a * A_PRECISION);
        data.ampData = AmpData(startA, startA, 0, 0);
        data.weightLimits = _config.limits;

        data.swapFee = 4e14;
        data.redemptionFee = 1e15;
        data.cacheSize = 1e17;
        data.govFee = 0;
    }

    /**
     * @dev System will be halted during a recollateralisation event
     */
    modifier whenInOperation() {
        _isOperational();
        _;
    }

    // Internal fn for modifier to reduce deployment size
    function _isOperational() internal view {
        require(!_paused || msg.sender == _recollateraliser(), "Unhealthy");
    }

    /**
     * @dev Verifies that the caller is the Interest Validator contract
     */
    modifier onlyInterestValidator() {
        require(nexus.getModule(KEY_INTEREST_VALIDATOR) == msg.sender, "Only validator");
        _;
    }

    /***************************************
                    MINTING
    ****************************************/

    /**
     * @notice Mint fpTokens with a single bAsset. This contract must have approval to spend the senders bAsset.
     * Supports either fAsset, mAsset or mpAsset as input - with mpAssets used to mint mAsset before depositing.
     * @param _input                Address of the bAsset to deposit.
     * @param _inputQuantity        Quantity in input token units.
     * @param _minOutputQuantity    Minimum fpToken quantity to be minted. This protects against slippage.
     * @param _recipient            Receipient of the newly minted fpTokens
     * @return mintOutput           Quantity of fpToken minted from the deposited bAsset.
     */
    function mint(
        address _input,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external override nonReentrant whenInOperation returns (uint256 mintOutput) {
        require(_recipient != address(0), "Invalid recipient");
        require(_inputQuantity > 0, "Qty==0");

        Asset memory input = _getAsset(_input);

        mintOutput = FeederLogic.mint(
            data,
            _getConfig(),
            input,
            _inputQuantity,
            _minOutputQuantity
        );

        // Mint the fpToken
        _mint(_recipient, mintOutput);
        emit Minted(msg.sender, _recipient, mintOutput, _input, _inputQuantity);
    }

    /**
     * @notice Mint fpTokens with multiple bAssets. This contract must have approval to spend the senders bAssets.
     * Supports only fAsset or mAsset as inputs.
     * @param _inputs               Address of the bAssets to deposit.
     * @param _inputQuantities      Quantity in input token units.
     * @param _minOutputQuantity    Minimum fpToken quantity to be minted. This protects against slippage.
     * @param _recipient            Receipient of the newly minted fpTokens
     * @return mintOutput           Quantity of fpToken minted from the deposited bAssets.
     */
    function mintMulti(
        address[] calldata _inputs,
        uint256[] calldata _inputQuantities,
        uint256 _minOutputQuantity,
        address _recipient
    ) external override nonReentrant whenInOperation returns (uint256 mintOutput) {
        require(_recipient != address(0), "Invalid recipient");
        uint256 len = _inputQuantities.length;
        require(len > 0 && len == _inputs.length, "Input array mismatch");

        uint8[] memory indexes = _getAssets(_inputs);
        mintOutput = FeederLogic.mintMulti(
            data,
            _getConfig(),
            indexes,
            _inputQuantities,
            _minOutputQuantity
        );
        // Mint the fpToken
        _mint(_recipient, mintOutput);
        emit MintedMulti(msg.sender, _recipient, mintOutput, _inputs, _inputQuantities);
    }

    /**
     * @notice Get the projected output of a given mint.
     * @param _input             Address of the bAsset to deposit
     * @param _inputQuantity     Quantity in bAsset units
     * @return mintOutput        Estimated mint output in fpToken terms
     */
    function getMintOutput(address _input, uint256 _inputQuantity)
        external
        view
        override
        returns (uint256 mintOutput)
    {
        require(_inputQuantity > 0, "Qty==0");

        Asset memory input = _getAsset(_input);

        if (input.exists) {
            mintOutput = FeederLogic.computeMint(
                data.bAssetData,
                input.idx,
                _inputQuantity,
                _getConfig()
            );
        } else {
            uint256 estimatedMasset = IMasset(mAsset).getMintOutput(_input, _inputQuantity);
            mintOutput = FeederLogic.computeMint(data.bAssetData, 0, estimatedMasset, _getConfig());
        }
    }

    /**
     * @notice Get the projected output of a given mint
     * @param _inputs            Non-duplicate address array of addresses to bAssets to deposit for the minted mAsset tokens.
     * @param _inputQuantities   Quantity of each bAsset to deposit for the minted fpToken.
     * @return mintOutput        Estimated mint output in fpToken terms
     */
    function getMintMultiOutput(address[] calldata _inputs, uint256[] calldata _inputQuantities)
        external
        view
        override
        returns (uint256 mintOutput)
    {
        uint256 len = _inputQuantities.length;
        require(len > 0 && len == _inputs.length, "Input array mismatch");
        uint8[] memory indexes = _getAssets(_inputs);
        return
            FeederLogic.computeMintMulti(data.bAssetData, indexes, _inputQuantities, _getConfig());
    }

    /***************************************
                    SWAPPING
    ****************************************/

    /**
     * @notice Swaps two assets - either internally between fAsset<>mAsset, or between fAsset<>mpAsset by
     * first routing through the mAsset pool.
     * @param _input             Address of bAsset to deposit
     * @param _output            Address of bAsset to withdraw
     * @param _inputQuantity     Units of input bAsset to swap in
     * @param _minOutputQuantity Minimum quantity of the swap output asset. This protects against slippage
     * @param _recipient         Address to transfer output asset to
     * @return swapOutput        Quantity of output asset returned from swap
     */
    function swap(
        address _input,
        address _output,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external override nonReentrant whenInOperation returns (uint256 swapOutput) {
        require(_recipient != address(0), "Invalid recipient");
        require(_input != _output, "Invalid pair");
        require(_inputQuantity > 0, "Qty==0");

        Asset memory input = _getAsset(_input);
        Asset memory output = _getAsset(_output);
        require(_pathIsValid(input, output), "Invalid pair");

        uint256 localFee;
        (swapOutput, localFee) = FeederLogic.swap(
            data,
            _getConfig(),
            input,
            output,
            _inputQuantity,
            _minOutputQuantity,
            _recipient
        );

        uint256 govFee = data.govFee;
        if (govFee > 0) {
            data.pendingFees += ((localFee * govFee) / 1e18);
        }

        emit Swapped(msg.sender, input.addr, output.addr, swapOutput, localFee, _recipient);
    }

    /**
     * @notice Determines both if a trade is valid, and the expected fee or output.
     * Swap is valid if it does not result in the input asset exceeding its maximum weight.
     * @param _input             Address of bAsset to deposit
     * @param _output            Address of bAsset to receive
     * @param _inputQuantity     Units of input bAsset to swap
     * @return swapOutput        Quantity of output asset returned from swap
     */
    function getSwapOutput(
        address _input,
        address _output,
        uint256 _inputQuantity
    ) external view override returns (uint256 swapOutput) {
        require(_input != _output, "Invalid pair");
        require(_inputQuantity > 0, "Qty==0");

        Asset memory input = _getAsset(_input);
        Asset memory output = _getAsset(_output);
        require(_pathIsValid(input, output), "Invalid pair");

        // Internal swap between fAsset and mAsset
        if (input.exists && output.exists) {
            (swapOutput, ) = FeederLogic.computeSwap(
                data.bAssetData,
                input.idx,
                output.idx,
                _inputQuantity,
                output.idx == 0 ? 0 : data.swapFee,
                _getConfig()
            );
            return swapOutput;
        }

        // Swapping out of fAsset
        if (input.exists) {
            // Swap into mAsset > Redeem into mpAsset
            (swapOutput, ) = FeederLogic.computeSwap(
                data.bAssetData,
                1,
                0,
                _inputQuantity,
                0,
                _getConfig()
            );
            swapOutput = IMasset(mAsset).getRedeemOutput(_output, swapOutput);
        }
        // Else we are swapping into fAsset
        else {
            // Mint mAsset from mp > Swap into fAsset here
            swapOutput = IMasset(mAsset).getMintOutput(_input, _inputQuantity);
            (swapOutput, ) = FeederLogic.computeSwap(
                data.bAssetData,
                0,
                1,
                swapOutput,
                data.swapFee,
                _getConfig()
            );
        }
    }

    /**
     * @dev Checks if a given swap path is valid. Only fAsset<>mAsset & fAsset<>mpAsset swaps are supported.
     */
    function _pathIsValid(Asset memory _in, Asset memory _out)
        internal
        pure
        returns (bool isValid)
    {
        // mpAsset -> mpAsset
        if (!_in.exists && !_out.exists) return false;
        // f/mAsset -> f/mAsset
        if (_in.exists && _out.exists) return true;
        // fAsset -> mpAsset
        if (_in.exists && _in.idx == 1) return true;
        // mpAsset -> fAsset
        if (_out.exists && _out.idx == 1) return true;
        // Path is into or out of mAsset - just use main pool for this
        return false;
    }

    /***************************************
                    REDEMPTION
    ****************************************/

    /**
     * @notice Burns a specified quantity of the senders fpToken in return for a bAsset. The output amount is derived
     * from the invariant. Supports redemption into either the fAsset, mAsset or assets in the mAsset basket.
     * @param _output            Address of the bAsset to withdraw
     * @param _fpTokenQuantity   Quantity of LP Token to burn
     * @param _minOutputQuantity Minimum bAsset quantity to receive for the burnt fpToken. This protects against slippage.
     * @param _recipient         Address to transfer the withdrawn bAssets to.
     * @return outputQuantity    Quanity of bAsset units received for the burnt fpToken
     */
    function redeem(
        address _output,
        uint256 _fpTokenQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external override nonReentrant whenInOperation returns (uint256 outputQuantity) {
        require(_recipient != address(0), "Invalid recipient");
        require(_fpTokenQuantity > 0, "Qty==0");

        Asset memory output = _getAsset(_output);

        // Get config before burning. Config > Burn > CacheSize
        FeederConfig memory config = _getConfig();
        _burn(msg.sender, _fpTokenQuantity);

        uint256 localFee;
        (outputQuantity, localFee) = FeederLogic.redeem(
            data,
            config,
            output,
            _fpTokenQuantity,
            _minOutputQuantity,
            _recipient
        );

        uint256 govFee = data.govFee;
        if (govFee > 0) {
            data.pendingFees += ((localFee * govFee) / 1e18);
        }

        emit Redeemed(
            msg.sender,
            _recipient,
            _fpTokenQuantity,
            output.addr,
            outputQuantity,
            localFee
        );
    }

    /**
     * @dev Credits a recipient with a proportionate amount of bAssets, relative to current vault
     * balance levels and desired fpToken quantity. Burns the fpToken as payment. Only fAsset & mAsset are supported in this path.
     * @param _inputQuantity        Quantity of fpToken to redeem
     * @param _minOutputQuantities  Min units of output to receive
     * @param _recipient            Address to credit the withdrawn bAssets
     * @return outputQuantities     Array of output asset quantities
     */
    function redeemProportionately(
        uint256 _inputQuantity,
        uint256[] calldata _minOutputQuantities,
        address _recipient
    ) external override nonReentrant whenInOperation returns (uint256[] memory outputQuantities) {
        require(_recipient != address(0), "Invalid recipient");
        require(_inputQuantity > 0, "Qty==0");

        // Get config before burning. Burn > CacheSize
        FeederConfig memory config = _getConfig();
        _burn(msg.sender, _inputQuantity);

        address[] memory outputs;
        uint256 scaledFee;
        (scaledFee, outputs, outputQuantities) = FeederLogic.redeemProportionately(
            data,
            config,
            _inputQuantity,
            _minOutputQuantities,
            _recipient
        );

        uint256 govFee = data.govFee;
        if (govFee > 0) {
            data.pendingFees += ((scaledFee * govFee) / 1e18);
        }

        emit RedeemedMulti(
            msg.sender,
            _recipient,
            _inputQuantity,
            outputs,
            outputQuantities,
            scaledFee
        );
    }

    /**
     * @dev Credits a recipient with a certain quantity of selected bAssets, in exchange for burning the
     *      relative fpToken quantity from the sender. Only fAsset & mAsset (0,1) are supported in this path.
     * @param _outputs              Addresses of the bAssets to receive
     * @param _outputQuantities     Units of the bAssets to receive
     * @param _maxInputQuantity     Maximum fpToken quantity to burn for the received bAssets. This protects against slippage.
     * @param _recipient            Address to receive the withdrawn bAssets
     * @return fpTokenQuantity      Quantity of fpToken units burned as payment
     */
    function redeemExactBassets(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities,
        uint256 _maxInputQuantity,
        address _recipient
    ) external override nonReentrant whenInOperation returns (uint256 fpTokenQuantity) {
        require(_recipient != address(0), "Invalid recipient");
        uint256 len = _outputQuantities.length;
        require(len > 0 && len == _outputs.length, "Invalid array input");
        require(_maxInputQuantity > 0, "Qty==0");

        uint8[] memory indexes = _getAssets(_outputs);

        uint256 localFee;
        (fpTokenQuantity, localFee) = FeederLogic.redeemExactBassets(
            data,
            _getConfig(),
            indexes,
            _outputQuantities,
            _maxInputQuantity,
            _recipient
        );

        _burn(msg.sender, fpTokenQuantity);
        uint256 govFee = data.govFee;
        if (govFee > 0) {
            data.pendingFees += ((localFee * govFee) / 1e18);
        }

        emit RedeemedMulti(
            msg.sender,
            _recipient,
            fpTokenQuantity,
            _outputs,
            _outputQuantities,
            localFee
        );
    }

    /**
     * @notice Gets the estimated output from a given redeem
     * @param _output            Address of the bAsset to receive
     * @param _fpTokenQuantity   Quantity of fpToken to redeem
     * @return bAssetOutput      Estimated quantity of bAsset units received for the burnt fpTokens
     */
    function getRedeemOutput(address _output, uint256 _fpTokenQuantity)
        external
        view
        override
        returns (uint256 bAssetOutput)
    {
        require(_fpTokenQuantity > 0, "Qty==0");

        Asset memory output = _getAsset(_output);
        uint256 scaledFee = _fpTokenQuantity.mulTruncate(data.redemptionFee);

        bAssetOutput = FeederLogic.computeRedeem(
            data.bAssetData,
            output.exists ? output.idx : 0,
            _fpTokenQuantity - scaledFee,
            _getConfig()
        );
        // Extra step for mpAsset redemption
        if (!output.exists) {
            bAssetOutput = IMasset(mAsset).getRedeemOutput(output.addr, bAssetOutput);
        }
    }

    /**
     * @notice Gets the estimated output from a given redeem
     * @param _outputs           Addresses of the bAsset to receive
     * @param _outputQuantities  Quantities of bAsset to redeem
     * @return fpTokenQuantity   Estimated quantity of fpToken units needed to burn to receive output
     */
    function getRedeemExactBassetsOutput(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities
    ) external view override returns (uint256 fpTokenQuantity) {
        uint256 len = _outputQuantities.length;
        require(len > 0 && len == _outputs.length, "Invalid array input");

        uint8[] memory indexes = _getAssets(_outputs);

        uint256 mAssetRedeemed =
            FeederLogic.computeRedeemExact(
                data.bAssetData,
                indexes,
                _outputQuantities,
                _getConfig()
            );
        fpTokenQuantity = mAssetRedeemed.divPrecisely(1e18 - data.redemptionFee);
        if (fpTokenQuantity > 0) fpTokenQuantity += 1;
    }

    /***************************************
                    GETTERS
    ****************************************/

    /**
     * @notice Gets the price of the fpToken, and invariant value k
     * @return price    Price of an fpToken
     * @return k        Total value of basket, k
     */
    function getPrice() public view override returns (uint256 price, uint256 k) {
        return FeederLogic.computePrice(data.bAssetData, _getConfig());
    }

    /**
     * @notice Gets all config needed for general InvariantValidator calls
     */
    function getConfig() external view override returns (FeederConfig memory config) {
        return _getConfig();
    }

    /**
     * @notice Get data for a specific bAsset, if it exists
     * @param _bAsset     Address of bAsset
     * @return personal   Struct with personal data
     * @return vaultData  Struct with full bAsset data
     */
    function getBasset(address _bAsset)
        external
        view
        override
        returns (BassetPersonal memory personal, BassetData memory vaultData)
    {
        Asset memory asset = _getAsset(_bAsset);
        require(asset.exists, "Invalid asset");
        personal = data.bAssetPersonal[asset.idx];
        vaultData = data.bAssetData[asset.idx];
    }

    /**
     * @notice Get data for a all bAssets in basket
     * @return personal    Struct[] with full bAsset data
     * @return vaultData   Number of bAssets in the Basket
     */
    function getBassets()
        external
        view
        override
        returns (BassetPersonal[] memory, BassetData[] memory vaultData)
    {
        return (data.bAssetPersonal, data.bAssetData);
    }

    /***************************************
                GETTERS - INTERNAL
    ****************************************/

    /**
     * @dev Checks if a given asset exists in basket and return the index.
     * @return status    Data containing address, index and whether it exists in basket
     */
    function _getAsset(address _asset) internal view returns (Asset memory status) {
        // if input is mAsset then we know the position
        if (_asset == mAsset) return Asset(0, _asset, true);

        // else it exists if the position 1 is _asset
        return Asset(1, _asset, data.bAssetPersonal[1].addr == _asset);
    }

    /**
     * @dev Validates an array of input assets and returns their indexes. Assets must exist
     * in order to be valid, as mintMulti and redeemMulti do not support external bAssets.
     */
    function _getAssets(address[] memory _assets) internal view returns (uint8[] memory indexes) {
        uint256 len = _assets.length;

        indexes = new uint8[](len);

        Asset memory input_;
        for (uint256 i = 0; i < len; i++) {
            input_ = _getAsset(_assets[i]);
            indexes[i] = input_.idx;
            require(input_.exists, "Invalid asset");

            for (uint256 j = i + 1; j < len; j++) {
                require(_assets[i] != _assets[j], "Duplicate asset");
            }
        }
    }

    /**
     * @dev Gets all config needed for general InvariantValidator calls
     */
    function _getConfig() internal view returns (FeederConfig memory) {
        return FeederConfig(totalSupply() + data.pendingFees, _getA(), data.weightLimits);
    }

    /**
     * @dev Gets current amplification var A
     */
    function _getA() internal view returns (uint256) {
        AmpData memory ampData_ = data.ampData;

        uint64 endA = ampData_.targetA;
        uint64 endTime = ampData_.rampEndTime;

        // If still changing, work out based on current timestmap
        if (block.timestamp < endTime) {
            uint64 startA = ampData_.initialA;
            uint64 startTime = ampData_.rampStartTime;

            (uint256 elapsed, uint256 total) = (block.timestamp - startTime, endTime - startTime);

            if (endA > startA) {
                return startA + (((endA - startA) * elapsed) / total);
            } else {
                return startA - (((startA - endA) * elapsed) / total);
            }
        }
        // Else return final value
        else {
            return endA;
        }
    }

    /***************************************
                    YIELD
    ****************************************/

    /**
     * @dev Collects the interest generated from the lending markets, performing a theoretical mint, which
     * is then validated by the interest validator to protect against accidental hyper inflation.
     * @return mintAmount   fpToken units generated from interest collected from lending markets
     * @return newSupply    fpToken total supply after mint
     */
    function collectPlatformInterest()
        external
        override
        onlyInterestValidator
        whenInOperation
        nonReentrant
        returns (uint256 mintAmount, uint256 newSupply)
    {
        (uint8[] memory idxs, uint256[] memory gains) =
            FeederManager.calculatePlatformInterest(data.bAssetPersonal, data.bAssetData);
        // Calculate potential mint amount. This will be validated by the interest validator
        mintAmount = FeederLogic.computeMintMulti(data.bAssetData, idxs, gains, _getConfig());
        newSupply = totalSupply() + data.pendingFees + mintAmount;

        uint256 govFee = data.govFee;
        if (govFee > 0) {
            data.pendingFees += ((mintAmount * govFee) / 1e18);
        }

        // Dummy mint event to catch the collections here
        emit MintedMulti(address(this), msg.sender, 0, new address[](0), gains);
    }

    /**
     * @dev Collects the pending gov fees extracted from swap, redeem and platform interest.
     */
    function collectPendingFees() external onlyInterestValidator {
        uint256 fees = data.pendingFees;
        if (fees > 1) {
            uint256 mintAmount = fees - 1;
            data.pendingFees = 1;

            _mint(msg.sender, mintAmount);
            emit MintedMulti(
                address(this),
                msg.sender,
                mintAmount,
                new address[](0),
                new uint256[](0)
            );
        }
    }

    /***************************************
                    STATE
    ****************************************/

    /**
     * @dev Sets the MAX cache size for each bAsset. The cache will actually revolve around
     *      _cacheSize * totalSupply / 2 under normal circumstances.
     * @param _cacheSize Maximum percent of total fpToken supply to hold for each bAsset
     */
    function setCacheSize(uint256 _cacheSize) external onlyGovernor {
        require(_cacheSize <= 2e17, "Must be <= 20%");

        data.cacheSize = _cacheSize;

        emit CacheSizeChanged(_cacheSize);
    }

    /**
     * @dev Set the ecosystem fee for sewapping bAssets or redeeming specific bAssets
     * @param _swapFee       Fee calculated in (%/100 * 1e18)
     * @param _redemptionFee Fee calculated in (%/100 * 1e18)
     * @param _govFee        Fee calculated in (%/100 * 1e18)
     */
    function setFees(
        uint256 _swapFee,
        uint256 _redemptionFee,
        uint256 _govFee
    ) external onlyGovernor {
        require(_swapFee <= MAX_FEE, "Swap rate oob");
        require(_redemptionFee <= MAX_FEE, "Redemption rate oob");
        require(_govFee <= 5e17, "Gov fee rate oob");

        data.swapFee = _swapFee;
        data.redemptionFee = _redemptionFee;
        data.govFee = _govFee;

        emit FeesChanged(_swapFee, _redemptionFee, _govFee);
    }

    /**
     * @dev Set the maximum weight across all bAssets
     * @param _min Weight where 100% = 1e18
     * @param _max Weight where 100% = 1e18
     */
    function setWeightLimits(uint128 _min, uint128 _max) external onlyGovernor {
        require(_min <= 3e17 && _max >= 7e17, "Weights oob");

        data.weightLimits = WeightLimits(_min, _max);

        emit WeightLimitsChanged(_min, _max);
    }

    /**
     * @dev Transfers all collateral from one lending market to another - used initially
     *      to handle the migration between Aave V1 and Aave V2. Note - only supports non
     *      tx fee enabled assets. Supports going from no integration to integration, but
     *      not the other way around.
     * @param _bAssets Array of basket assets to migrate
     * @param _newIntegration Address of the new platform integration
     */
    function migrateBassets(address[] calldata _bAssets, address _newIntegration)
        external
        onlyGovernor
    {
        FeederManager.migrateBassets(data.bAssetPersonal, _bAssets, _newIntegration);
    }

    /**
     * @dev Starts changing of the amplification var A
     * @param _targetA      Target A value
     * @param _rampEndTime  Time at which A will arrive at _targetA
     */
    function startRampA(uint256 _targetA, uint256 _rampEndTime) external onlyGovernor {
        FeederManager.startRampA(data.ampData, _targetA, _rampEndTime, _getA(), A_PRECISION);
    }

    /**
     * @dev Stops the changing of the amplification var A, setting
     * it to whatever the current value is.
     */
    function stopRampA() external onlyGovernor {
        FeederManager.stopRampA(data.ampData, _getA());
    }
}