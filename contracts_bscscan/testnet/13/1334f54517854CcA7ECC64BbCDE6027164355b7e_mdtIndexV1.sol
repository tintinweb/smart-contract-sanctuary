/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

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

// File: mdtIndexV1.sol

contract mdtIndexV1 is Context {
    address internal gnosis;
    address internal credit;
    uint256 internal rate;

    bytes32 internal constant GNOSIS_ROLE = keccak256("GNOSIS_ROLE");
    bytes32 internal constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 internal constant DEV_ROLE = keccak256("DEV_ROLE");
    bytes32 internal constant L3_ROLE = keccak256("L3_ROLE");
    bytes32 internal constant L2_ROLE = keccak256("L2_ROLE");
    bytes32 internal constant L1_ROLE = keccak256("L1_ROLE");

    mapping(bytes32 => mapping(address => bool)) internal roles;
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    modifier onlyRole(bytes32 _role) {
        require(roles[_role][_msgSender()], "NO_PERMISSION");
        _;
    }

    constructor(address _gnosis, address _credit, uint256 _rate) {
        // require(Address.isContract(_gnosis), "INVALID_GNOSIS");
        _grantRole(GNOSIS_ROLE, _gnosis);
        gnosis = _gnosis;
        credit = _credit;
        rate = _rate;
    }

    receive() external payable {}

    function recoverEth() external onlyRole(GNOSIS_ROLE) {
        payable(gnosis).transfer(address(this).balance);
    }

    function recoverToken(IERC20 _token) external onlyRole(GNOSIS_ROLE) {
        _token.transfer(gnosis, _token.balanceOf(address(this)));
    }

    function getGnosis() external view returns (address) {
        return gnosis;
    }

    function getCredit() external view returns (address) {
        return credit;
    }

    function setCredit(address _credit) external onlyRole(GNOSIS_ROLE) {
        credit = _credit;
    }

    function getRate() public view returns (uint256) {
        return rate;
    }

    function setRate(uint256 _rate) external onlyRole(GNOSIS_ROLE) {
        rate = _rate;
    }

    function isRelayer(address _account) external view returns (bool) {
        return roles[RELAYER_ROLE][_account];
    }

    function addRelayer(address _account) external onlyRole(GNOSIS_ROLE) {
        _grantRole(RELAYER_ROLE, _account);
    }

    function removeRelayer(address _account) external onlyRole(GNOSIS_ROLE) {
        _revokeRole(RELAYER_ROLE, _account);
    }

    function isDev(address _account) public view returns (bool) {
        return roles[DEV_ROLE][_account];
    }

    function upgradeDev(address[] memory _accounts) external onlyRole(RELAYER_ROLE) {
        __grantRoleMultiple(DEV_ROLE, _accounts);
        _revokeRoleMultiple(L3_ROLE, _accounts);
        _revokeRoleMultiple(L2_ROLE, _accounts);
        _revokeRoleMultiple(L1_ROLE, _accounts);
    }

    function isL3(address _account) public view returns (bool) {
        return roles[L3_ROLE][_account];
    }

    function upgradeL3(address[] memory _accounts) external onlyRole(RELAYER_ROLE) {
        _revokeRoleMultiple(DEV_ROLE, _accounts);
        __grantRoleMultiple(L3_ROLE, _accounts);
        _revokeRoleMultiple(L2_ROLE, _accounts);
        _revokeRoleMultiple(L1_ROLE, _accounts);
    }

    function isL2(address _account) public view returns (bool) {
        return roles[L2_ROLE][_account];
    }

    function upgradeL2(address[] memory _accounts) external onlyRole(RELAYER_ROLE) {
        _revokeRoleMultiple(DEV_ROLE, _accounts);
        _revokeRoleMultiple(L3_ROLE, _accounts);
        __grantRoleMultiple(L2_ROLE, _accounts);
        _revokeRoleMultiple(L1_ROLE, _accounts);
    }

    function isL1(address _account) public view returns (bool) {
        return roles[L1_ROLE][_account];
    }

    function upgradeL1(address[] memory _accounts) external onlyRole(RELAYER_ROLE) {
        _revokeRoleMultiple(DEV_ROLE, _accounts);
        _revokeRoleMultiple(L3_ROLE, _accounts);
        _revokeRoleMultiple(L2_ROLE, _accounts);
        __grantRoleMultiple(L1_ROLE, _accounts);
    }

    function revokeRoles(address[] memory _accounts) external onlyRole(RELAYER_ROLE) {
        _revokeRoleMultiple(DEV_ROLE, _accounts);
        _revokeRoleMultiple(L3_ROLE, _accounts);
        _revokeRoleMultiple(L2_ROLE, _accounts);
        _revokeRoleMultiple(L1_ROLE, _accounts);
    }

    function _grantRole(bytes32 _role, address _account) internal {
        if (!roles[_role][_account]) {
            roles[_role][_account] = true;
            emit RoleGranted(_role, _account, _msgSender());
        }
    }

    function __grantRoleMultiple(bytes32 _role, address[] memory _accounts) internal {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _grantRole(_role, _accounts[i]);
        }
    }

    function _revokeRole(bytes32 _role, address _account) internal {
        if (roles[_role][_account]) {
            roles[_role][_account] = false;
            emit RoleRevoked(_role, _account, _msgSender());
        }
    }

    function _revokeRoleMultiple(bytes32 _role, address[] memory _accounts) internal {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _revokeRole(_role, _accounts[i]);
        }
    }

    function getBaseRate(address _account) external view returns (uint256) {
        if (isDev(_account)) return getRate() - (getRate() * 100 / 100);
        if (isL3(_account)) return getRate() - (getRate() * 75 / 100);
        if (isL2(_account)) return getRate() - (getRate() * 50 / 100);
        if (isL1(_account)) return getRate() - (getRate() * 25 / 100);

        return getRate();
    }

    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}