// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

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
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./interface/ISolver.sol";

contract Solver is ISolver, Initializable {
    address public admin;
    address public pendingAdmin;

    mapping(address => bool) public transferGuardianPaused;
    mapping(address => bool) public depositGuardianPaused;
    mapping(address => bool) public withdrawGuardianPaused;

    mapping(address => bool) public convertUnsafeTransferContracts;
    mapping(address => bool) public rejectUnsafeTransferContracts;

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    function initialize() public initializer {
        admin = msg.sender;
    }

    function isSolver() external pure override returns (bool) {
        return true;
    }

    function _setTransferGuuardianPause(address product, bool enable)
        public
        onlyAdmin
    {
        transferGuardianPaused[product] = enable;
    }

    function _setDepositGuuardianPause(address product, bool enable)
        public
        onlyAdmin
    {
        depositGuardianPaused[product] = enable;
    }

    function _setWithdrawGuuardianPause(address product, bool enable)
        public
        onlyAdmin
    {
        withdrawGuardianPaused[product] = enable;
    }

    function _setConvertUnsafeTransferContracts(address product, bool enable)
        public
        onlyAdmin
    {
        convertUnsafeTransferContracts[product] = enable;
    }

    function _setRejectUnsafeTransferContracts(address product, bool enable)
        public
        onlyAdmin
    {
        rejectUnsafeTransferContracts[product] = enable;
    }

    function depositAllowed(
        address product,
        address depositor,
        uint64 term,
        uint256 depositAmount,
        uint64[] calldata maturities
    ) external override returns (uint256) {
        //reserve vars
        product;
        depositor;
        term;
        depositAmount;
        maturities;

        require(!depositGuardianPaused[product], "deposit is paused");

        return 0;
    }

    function depositVerify(
        address product,
        address depositor,
        uint256 depositAmount,
        uint256 tokenId,
        uint64 term,
        uint64[] calldata maturities
    ) external override returns (uint256) {
        product;
        depositor;
        depositAmount;
        tokenId;
        term;
        maturities;

        return 0;
    }

    function withdrawAllowed(
        address product,
        address payee,
        uint256 withdrawAmount,
        uint256 tokenId,
        uint64 term,
        uint64 maturity
    ) external override returns (uint256) {
        //reserve
        product;
        payee;
        withdrawAmount;
        tokenId;
        term;
        maturity;

        require(!withdrawGuardianPaused[product], "withdraw is paused");

        return 0;
    }

    function withdrawVerify(
        address product,
        address payee,
        uint256 withdrawAmount,
        uint256 tokenId,
        uint64 term,
        uint64 maturity
    ) external override returns (uint256) {
        //reserve
        product;
        payee;
        withdrawAmount;
        tokenId;
        term;
        maturity;

        return 0;
    }

    function transferFromAllowed(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external override returns (uint256) {
        //reserve vars
        product;
        from;
        to;
        tokenId;
        amount;
        targetTokenId;

        require(!transferGuardianPaused[product], "transfer is paused");
        return 0;
    }

    function transferFromVerify(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external override returns (uint256) {
        //reserve vars
        product;
        from;
        to;
        tokenId;
        targetTokenId;
        amount;

        return 0;
    }

    function mergeAllowed(
        address product,
        address owner,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external override returns (uint256) {
        //reserve vars
        product;
        owner;
        tokenId;
        targetTokenId;
        amount;
        return 0;
    }

    function mergeVerify(
        address product,
        address owner,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external override returns (uint256) {
        //reserve vars
        product;
        owner;
        tokenId;
        targetTokenId;
        amount;
        return 0;
    }

    function splitAllowed(
        address product,
        address owner,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 amount
    ) external override returns (uint256) {
        //reserve vars
        product;
        owner;
        tokenId;
        newTokenId;
        amount;
        return 0;
    }

    function splitVerify(
        address product,
        address owner,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 amount
    ) external override returns (uint256) {
        //reserve vars
        product;
        owner;
        tokenId;
        newTokenId;
        amount;
        return 0;
    }

    function publishFixedPriceAllowed(
        address icToken,
        uint256 tokenId,
        address seller,
        address currency,
        uint256 min,
        uint256 max,
        uint256 startTime,
        bool useAllowList,
        uint256 price
    ) external override returns (uint256) {
        //reserve vars
        icToken;
        tokenId;
        seller;
        currency;
        min;
        max;
        startTime;
        useAllowList;
        price;

        return 0;
    }

    function publishDecliningPriceAllowed(
        address icToken,
        uint256 tokenId,
        address seller,
        address currency,
        uint256 min,
        uint256 max,
        uint256 startTime,
        bool useAllowList,
        uint256 highest,
        uint256 lowest,
        uint256 duration,
        uint256 interval
    ) external override returns (uint256) {
        //reserve vars
        icToken;
        tokenId;
        seller;
        currency;
        min;
        max;
        startTime;
        useAllowList;
        highest;
        lowest;
        duration;
        interval;

        return 0;
    }

    function publishVerify(
        address icToken,
        uint256 tokenId,
        address seller,
        address currency,
        uint256 saleId,
        uint256 units
    ) external override {
        //reserve vars
        icToken;
        tokenId;
        seller;
        currency;
        saleId;
        units;
    }

    function buyAllowed(
        address icToken,
        uint256 tokenId,
        uint256 saleId,
        address buyer,
        address currency,
        uint256 buyAmount,
        uint256 buyUnits,
        uint256 price
    ) external override returns (uint256) {
        //reserve vars
        icToken;
        tokenId;
        saleId;
        buyer;
        currency;
        buyAmount;
        buyUnits;
        price;

        return 0;
    }

    function buyVerify(
        address icToken,
        uint256 tokenId,
        uint256 saleId,
        address buyer,
        address seller,
        uint256 amount,
        uint256 units,
        uint256 price,
        uint256 fee
    ) external override {
        //reserve
        icToken;
        tokenId;
        saleId;
        buyer;
        seller;
        amount;
        units;
        price;
        fee;
    }

    function removeAllow(
        address icToken,
        uint256 tokenId,
        uint256 saleId,
        address seller
    ) external override returns (uint256) {
        //reserve vars
        icToken;
        tokenId;
        saleId;
        seller;

        return 0;
    }

    function needConvertUnsafeTransfer(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 units
    ) public view override returns (bool) {
        //reserve vars
        product;
        from;
        tokenId;
        units;
        return convertUnsafeTransferContracts[to];
    }

    function needRejectUnsafeTransfer(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 units
    ) public view override returns (bool) {
        //reserve vars
        product;
        from;
        tokenId;
        units;
        return rejectUnsafeTransferContracts[to];
    }

    function _setPendingAdmin(address newPendingAdmin) public {
        require(msg.sender == admin, "only admin");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function _acceptAdmin() public {
        require(
            msg.sender == pendingAdmin && msg.sender != address(0),
            "only pending admin"
        );

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISolver {
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    function isSolver() external returns (bool);

    function depositAllowed(
        address product,
        address depositor,
        uint64 term,
        uint256 depositAmount,
        uint64[] calldata maturities
    ) external returns (uint256);

    function depositVerify(
        address product,
        address depositor,
        uint256 depositAmount,
        uint256 tokenId,
        uint64 term,
        uint64[] calldata maturities
    ) external returns (uint256);

    function withdrawAllowed(
        address product,
        address payee,
        uint256 withdrawAmount,
        uint256 tokenId,
        uint64 term,
        uint64 maturity
    ) external returns (uint256);

    function withdrawVerify(
        address product,
        address payee,
        uint256 withdrawAmount,
        uint256 tokenId,
        uint64 term,
        uint64 maturity
    ) external returns (uint256);

    function transferFromAllowed(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external returns (uint256);

    function transferFromVerify(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external returns (uint256);

    function mergeAllowed(
        address product,
        address owner,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external returns (uint256);

    function mergeVerify(
        address product,
        address owner,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external returns (uint256);

    function splitAllowed(
        address product,
        address owner,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 amount
    ) external returns (uint256);

    function splitVerify(
        address product,
        address owner,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 amount
    ) external returns (uint256);

    function needConvertUnsafeTransfer(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 units
    ) external view returns (bool);

    function needRejectUnsafeTransfer(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 units
    ) external view returns (bool);

    function publishFixedPriceAllowed(
        address icToken,
        uint256 tokenId,
        address seller,
        address currency,
        uint256 min,
        uint256 max,
        uint256 startTime,
        bool useAllowList,
        uint256 price
    ) external returns (uint256);

    function publishDecliningPriceAllowed(
        address icToken,
        uint256 tokenId,
        address seller,
        address currency,
        uint256 min,
        uint256 max,
        uint256 startTime,
        bool useAllowList,
        uint256 highest,
        uint256 lowest,
        uint256 duration,
        uint256 interval
    ) external returns (uint256);

    function publishVerify(
        address icToken,
        uint256 tokenId,
        address seller,
        address currency,
        uint256 saleId,
        uint256 units
    ) external;

    function buyAllowed(
        address icToken,
        uint256 tokenId,
        uint256 saleId,
        address buyer,
        address currency,
        uint256 buyAmount,
        uint256 buyUnits,
        uint256 price
    ) external returns (uint256);

    function buyVerify(
        address icToken,
        uint256 tokenId,
        uint256 saleId,
        address buyer,
        address seller,
        uint256 amount,
        uint256 units,
        uint256 price,
        uint256 fee
    ) external;

    function removeAllow(
        address icToken,
        uint256 tokenId,
        uint256 saleId,
        address seller
    ) external returns (uint256);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}