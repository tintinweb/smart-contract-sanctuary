/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

// SPDX-License-Identifier: None

pragma solidity ^0.8.11;

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: @openzeppelin/contracts/proxy/utils/Initializable.sol

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// File: StateImplementation.sol

contract StateImplementation is Initializable, Context {
    address internal gnosis;
    address internal credit;
    uint256 internal rate;

    mapping(address => bool) internal RELAYER_ROLE;
    mapping(address => bool) internal DEV_ROLE;
    mapping(address => bool) internal L3_ROLE;
    mapping(address => bool) internal L2_ROLE;
    mapping(address => bool) internal L1_ROLE;
    mapping(address => bool) internal BL_ROLE;
    mapping(address => uint256) internal SUB_WALLETS;

    event RoleGranted(string role, address indexed account, address indexed sender);
    event RoleRevoked(string role, address indexed account, address indexed sender);
    event AddedSubWallets(uint256 count, address indexed account, address indexed sender);
    event RemovedSubWallets(uint256 count, address indexed accounts, address indexed sender);

    modifier onlyGnosis() {
        require(_msgSender() == gnosis, "NOT_GNOSIS");
        _;
    }

    modifier onlyRelayer() {
        require(RELAYER_ROLE[_msgSender()], "NOT_RELAYER");
        _;
    }

    constructor() initializer {}
    function initialize(address _gnosis, address _credit, uint256 _rate) external initializer {
        require(Address.isContract(_gnosis) && Address.isContract(_credit), "INVALID_INITIALIZATION");

        gnosis = _gnosis;
        credit = _credit;
        rate = _rate;
    }

    receive() external payable {}

    function recoverEth() external onlyGnosis {
        payable(gnosis).transfer(address(this).balance);
    }

    function recoverToken(IERC20 _token) external onlyGnosis {
        _token.transfer(gnosis, _token.balanceOf(address(this)));
    }

    function getGnosis() external view returns (address) {
        return gnosis;
    }

    function getCredit() external view returns (address) {
        return credit;
    }

    function getRate() public view returns (uint256) {
        return rate;
    }

    function setRate(uint256 _rate) external onlyGnosis {
        rate = _rate;
    }

    function isRelayer(address _account) external view returns (bool) {
        return RELAYER_ROLE[_account];
    }

    function addRelayer(address _account) external onlyGnosis {
        if (!RELAYER_ROLE[_account]) {
            RELAYER_ROLE[_account] = true;
            emit RoleGranted("RELAYER_ROLE", _account, _msgSender());
        }
    }

    function removeRelayer(address _account) external onlyGnosis {
        if (RELAYER_ROLE[_account]) {
            RELAYER_ROLE[_account] = false;
            emit RoleRevoked("RELAYER_ROLE", _account, _msgSender());
        }
    }

    function isDev(address _account) public view returns (bool) {
        return DEV_ROLE[_account];
    }

    function _addDev(address _account) internal {
        if (!DEV_ROLE[_account]) {
            DEV_ROLE[_account] = true;
            emit RoleGranted("DEV_ROLE", _account, _msgSender());
        }
    }

    function _removeDev(address _account) internal {
        if (DEV_ROLE[_account]) {
            DEV_ROLE[_account] = false;
            emit RoleRevoked("DEV_ROLE", _account, _msgSender());
        }
    }

    function upgradeDev(address[] memory _accounts) external onlyRelayer {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _addDev(_accounts[i]);
            _removeL3(_accounts[i]);
            _removeL2(_accounts[i]);
            _removeL1(_accounts[i]);
        }
    }

    function isL3(address _account) public view returns (bool) {
        return L3_ROLE[_account];
    }

    function _addL3(address _account) internal {
        if (!L3_ROLE[_account]) {
            L3_ROLE[_account] = true;
            emit RoleGranted("L3_ROLE", _account, _msgSender());
        }
    }

    function _removeL3(address _account) internal {
        if (L3_ROLE[_account]) {
            L3_ROLE[_account] = false;
            emit RoleRevoked("L3_ROLE", _account, _msgSender());
        }
    }

    function upgradeL3(address[] memory _accounts) external onlyRelayer {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _removeDev(_accounts[i]);
            _addL3(_accounts[i]);
            _removeL2(_accounts[i]);
            _removeL1(_accounts[i]);
        }
    }

    function isL2(address _account) public view returns (bool) {
        return L2_ROLE[_account];
    }

    function _addL2(address _account) internal {
        if (!L2_ROLE[_account]) {
            L2_ROLE[_account] = true;
            emit RoleGranted("L2_ROLE", _account, _msgSender());
        }
    }

    function _removeL2(address _account) internal {
        if (L2_ROLE[_account]) {
            L2_ROLE[_account] = false;
            emit RoleRevoked("L2_ROLE", _account, _msgSender());
        }
    }

    function upgradeL2(address[] memory _accounts) external onlyRelayer {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _removeDev(_accounts[i]);
            _removeL3(_accounts[i]);
            _addL2(_accounts[i]);
            _removeL1(_accounts[i]);
        }
    }

    function isL1(address _account) public view returns (bool) {
        return L1_ROLE[_account];
    }

    function _addL1(address _account) internal {
        if (!L1_ROLE[_account]) {
            L1_ROLE[_account] = true;
            emit RoleGranted("L1_ROLE", _account, _msgSender());
        }
    }

    function _removeL1(address _account) internal {
        if (L1_ROLE[_account]) {
            L1_ROLE[_account] = false;
            emit RoleRevoked("L1_ROLE", _account, _msgSender());
        }
    }

    function upgradeL1(address[] memory _accounts) external onlyRelayer {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _removeDev(_accounts[i]);
            _removeL3(_accounts[i]);
            _removeL2(_accounts[i]);
            _addL1(_accounts[i]);
        }
    }

    function revokeRoles(address[] memory _accounts) external onlyRelayer {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _removeDev(_accounts[i]);
            _removeL3(_accounts[i]);
            _removeL2(_accounts[i]);
            _removeL1(_accounts[i]);
        }
    }

    function isBL(address _account) external view returns (bool) {
        return BL_ROLE[_account];
    }

    function addBL(address[] memory _accounts) external onlyRelayer {
        for (uint256 i = 0; i < _accounts.length; i++) {
            if (!BL_ROLE[_accounts[i]]) {
                BL_ROLE[_accounts[i]] = true;
                emit RoleGranted("BL_ROLE", _accounts[i], _msgSender());
            }
        }
    }

    function removeBL(address[] memory _accounts) external onlyRelayer {
        for (uint256 i = 0; i < _accounts.length; i++) {
            if (BL_ROLE[_accounts[i]]) {
                BL_ROLE[_accounts[i]] = false;
                emit RoleRevoked("BL_ROLE", _accounts[i], _msgSender());
            }
        }
    }

    function getBaseRate(address _account) external view returns (uint256) {
        if (isDev(_account)) return getRate() - (getRate() * 100 / 100);
        if (isL3(_account)) return getRate() - (getRate() * 75 / 100);
        if (isL2(_account)) return getRate() - (getRate() * 50 / 100);
        if (isL1(_account)) return getRate() - (getRate() * 25 / 100);

        return getRate();
    }

    function getSubWallets(address _account) external view returns (uint256) {
        if (isDev(_account)) return SUB_WALLETS[_account] + 10;
        if (isL3(_account)) return SUB_WALLETS[_account] + 1;

        return SUB_WALLETS[_account];
    }

    function addSubWallets(address[] memory _accounts, uint256 _counts) external onlyRelayer {
        for (uint256 i = 0; i < _accounts.length; i++) {
            SUB_WALLETS[_accounts[i]] = SUB_WALLETS[_accounts[i]] + _counts;
            emit AddedSubWallets(_counts, _accounts[i], _msgSender());
        }
    }

    function removeSubWallets(address[] memory _accounts, uint256 _counts) external onlyRelayer {
        for (uint256 i = 0; i < _accounts.length; i++) {
            if (SUB_WALLETS[_accounts[i]] > _counts) {
                SUB_WALLETS[_accounts[i]] = SUB_WALLETS[_accounts[i]] - _counts;
                emit RemovedSubWallets(_counts, _accounts[i], _msgSender());
            } else {
                SUB_WALLETS[_accounts[i]] = 0;
                emit RemovedSubWallets(SUB_WALLETS[_accounts[i]], _accounts[i], _msgSender());
            }
        }
    }

    function version() external pure returns (string memory) {
        return "2.0.0";
    }
}