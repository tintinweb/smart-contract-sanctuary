// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./interfaces/ILaunchpadWhitelistImplementation.sol";

/**
 * @title LaunchpadWhitelistImplementation
 * @author Enjinstarter
 */
contract LaunchpadWhitelistImplementation is
    Initializable,
    ILaunchpadWhitelistImplementation
{
    uint256 public constant BATCH_MAX_NUM = 200;

    address private _governanceAccount;
    address private _adminAccount;

    mapping(address => uint256) private _whitelisteds;

    function initialize() public initializer {
        _governanceAccount = msg.sender;
        _adminAccount = msg.sender;
    }

    modifier onlyBy(address account) {
        require(
            msg.sender == account,
            "LaunchpadWhitelistImplementation: sender unauthorized"
        );
        _;
    }

    function addWhitelisted(address account, uint256 amount)
        external
        override
        onlyBy(_adminAccount)
    {
        _addWhitelisted(account, amount);
    }

    function removeWhitelisted(address account)
        external
        override
        onlyBy(_adminAccount)
    {
        _removeWhitelisted(account);
    }

    function addWhitelistedBatch(
        address[] memory accounts,
        uint256[] memory amounts
    ) external override onlyBy(_adminAccount) {
        require(accounts.length > 0, "LaunchpadWhitelistImplementation: empty");
        require(
            accounts.length <= BATCH_MAX_NUM,
            "LaunchpadWhitelistImplementation: exceed max"
        );
        require(
            amounts.length == accounts.length,
            "LaunchpadWhitelistImplementation: different length"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            _addWhitelisted(accounts[i], amounts[i]);
        }
    }

    function removeWhitelistedBatch(address[] memory accounts)
        external
        override
        onlyBy(_adminAccount)
    {
        require(accounts.length > 0, "LaunchpadWhitelistImplementation: empty");
        require(
            accounts.length <= BATCH_MAX_NUM,
            "LaunchpadWhitelistImplementation: exceed max"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            _removeWhitelisted(accounts[i]);
        }
    }

    function setGovernanceAccount(address account)
        external
        onlyBy(_governanceAccount)
    {
        require(
            account != address(0),
            "LaunchpadWhitelistImplementation: zero account"
        );

        _governanceAccount = account;
    }

    function setAdminAccount(address account)
        external
        onlyBy(_governanceAccount)
    {
        require(
            account != address(0),
            "LaunchpadWhitelistImplementation: zero account"
        );

        _adminAccount = account;
    }

    function isWhitelisted(address account)
        external
        view
        override
        returns (bool isWhitelisted_)
    {
        require(
            account != address(0),
            "LaunchpadWhitelistImplementation: zero account"
        );

        isWhitelisted_ = _whitelisteds[account] > 0;
    }

    function whitelistedAmountFor(address account)
        external
        view
        override
        returns (uint256 whitelistedAmount)
    {
        require(
            account != address(0),
            "LaunchpadWhitelistImplementation: zero account"
        );

        whitelistedAmount = _whitelisteds[account];
    }

    function governanceAccount()
        external
        view
        returns (address goveranceAccount_)
    {
        goveranceAccount_ = _governanceAccount;
    }

    function adminAccount() external view returns (address adminAccount_) {
        adminAccount_ = _adminAccount;
    }

    function _addWhitelisted(address account, uint256 amount) internal {
        require(
            account != address(0),
            "LaunchpadWhitelistImplementation: zero account"
        );
        require(amount > 0, "LaunchpadWhitelistImplementation: zero amount");
        require(
            _whitelisteds[account] == 0,
            "LaunchpadWhitelistImplementation: already whitelisted"
        );

        _whitelisteds[account] = amount;

        emit WhitelistedAdded(account, amount);
    }

    function _removeWhitelisted(address account) internal {
        require(
            account != address(0),
            "LaunchpadWhitelistImplementation: zero account"
        );
        require(
            _whitelisteds[account] > 0,
            "LaunchpadWhitelistImplementation: not whitelisted"
        );

        _whitelisteds[account] = 0;

        emit WhitelistedRemoved(account);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

/**
 * @title ILaunchpadWhitelistImplementation
 * @author Enjinstarter
 */
interface ILaunchpadWhitelistImplementation {
    function addWhitelisted(address account, uint256 amount) external;

    function removeWhitelisted(address account) external;

    function addWhitelistedBatch(
        address[] memory accounts,
        uint256[] memory amounts
    ) external;

    function removeWhitelistedBatch(address[] memory accounts) external;

    function isWhitelisted(address account)
        external
        view
        returns (bool isWhitelisted_);

    function whitelistedAmountFor(address account)
        external
        view
        returns (uint256 whitelistedAmount);

    event WhitelistedAdded(address indexed account, uint256 amount);
    event WhitelistedRemoved(address indexed account);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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