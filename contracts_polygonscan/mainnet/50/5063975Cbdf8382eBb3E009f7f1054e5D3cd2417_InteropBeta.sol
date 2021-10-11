// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./variables.sol";
import "./events.sol";
import "./interfaces.sol";
import "./helpers.sol";

contract InteropBeta is Variables, Helpers, Events, Ownable {
    using SafeERC20 for IERC20;

    ListInterface public immutable list;
    address dsaAddrTest;

    function withdrawTokens(IERC20 token) external {
        if (address(token) == nativeToken) {
            Address.sendValue(payable(msg.sender), address(this).balance);
        } else {
            token.safeTransfer(msg.sender, token.balanceOf(address(this)));
        }
    }

    function changeDSA(address _dsaAddrTest) external {
        dsaAddrTest = _dsaAddrTest;
    }

    constructor(address _instaIndex, address _dsaAddrTest) {
        list = ListInterface(IndexInterface(_instaIndex).list());
        dsaAddrTest = _dsaAddrTest;
    }

    
    function submitAction(
        Position memory position,
        address sourceDsaSender,
        string memory actionId,
        uint64 targetDsaId,
        uint256 targetChainId
    ) external {
        uint256 sourceChainId = getChainID();
        // address dsaAddr = msg.sender;
        address dsaAddr = dsaAddrTest;
        uint256 sourceDsaId = list.accountID(dsaAddr);
        require(sourceDsaId != 0, "msg.sender-not-dsa");

        bytes32 key = keccak256(
            abi.encode(
                position,
                actionId,
                sourceDsaSender,
                sourceDsaId,
                targetDsaId,
                sourceChainId,
                targetChainId,
                vnonce
            )
        );
        
        emit LogSubmit(
            position,
            actionId,
            keccak256(abi.encodePacked(actionId)),
            sourceDsaSender,
            sourceDsaId,
            targetDsaId,
            sourceChainId,
            targetChainId,
            vnonce
        );
        
        executeDsa[key] = dsaAddr;
        vnonce = vnonce + 1;

    }

    function revertAction(
        Position memory position,
        address sourceDsaSender,
        string memory actionId,
        uint64 sourceDsaId,
        uint64 targetDsaId,
        uint256 targetChainId,
        uint256 _vnonce
    ) external {
        uint256 sourceChainId = getChainID();
        address sourceDsaAddr = list.accountAddr(sourceDsaId);
        require(sourceDsaAddr != address(0), "dsa-not-valid");

        bytes32 key = keccak256(
            abi.encode(
                position,
                actionId,
                sourceDsaSender,
                sourceDsaId,
                targetDsaId,
                sourceChainId,
                targetChainId,
                _vnonce
            )
        );

        address sourceDsaAddrCheck = executeDsa[key];
        // require(msg.sender == sourceDsaAddrCheck, "not-same-dsa");
        // require(
        //     msg.sender == sourceDsaAddr || 
        //     msg.sender == owner()
        // , "not-valid-auth-to-revert");

        
        
        emit LogRevert(
            position,
            actionId,
            keccak256(abi.encodePacked(actionId)),
            sourceDsaSender,
            sourceDsaId,
            targetDsaId,
            sourceChainId,
            targetChainId,
            _vnonce
        );
    }

    /**
     * @dev cast sourceAction
     */
    function sourceAction(
        spell[] memory sourceSpells,
        Position memory position,
        string memory actionId,
        address sourceDsaSender,
        uint64 sourceDsaId,
        uint64 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 _vnonce
    ) 
        external 
        // onlyOwner
    {
        ActionVariables memory s;

        s.dsa = AccountInterface(list.accountAddr(sourceDsaId));
        require(address(s.dsa) != address(0), "dsa-not-valid");
        require(s.dsa.isAuth(sourceDsaSender), "sourceDsaSender-not-auth");
        
        sendSourceTokens(position.withdraw, address(s.dsa));

        s.success = cast(s.dsa, sourceSpells);
        if (s.success) {
            emit LogValidate(
                sourceSpells,
                position,
                actionId,
                keccak256(abi.encodePacked(actionId)),
                sourceDsaSender,
                sourceDsaId,
                targetDsaId,
                sourceChainId,
                targetChainId,
                _vnonce
            );
        } else {
            emit LogSourceFailed(
                sourceSpells,
                position,
                actionId,
                keccak256(abi.encodePacked(actionId)),
                sourceDsaSender,
                sourceDsaId,
                targetDsaId,
                sourceChainId,
                targetChainId,
                _vnonce
            );
            revert();
        }
    }

    /**
     * @dev cast targetAction
     */
    function targetAction(
        spell[] memory sourceSpells,
        spell[] memory targetSpells,
        Position memory position,
        string memory actionId,
        address sourceDsaSender,
        uint64 sourceDsaId,
        uint64 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 _vnonce
    )
        external
        // onlyOwner
    {
        ActionVariables memory t;

        t.key = keccak256(
            abi.encode(
                position,
                actionId,
                sourceDsaSender,
                sourceDsaId,
                targetDsaId,
                sourceChainId,
                targetChainId,
                _vnonce
            )
        );

        require(executeMapping[t.key] == false, "validation-failed");
        t.dsa = AccountInterface(list.accountAddr(targetDsaId));
        require(address(t.dsa) != address(0), "invalid-dsa");
        require(t.dsa.isAuth(sourceDsaSender), "sourceDsaSender-not-auth");


        sendTargetTokens(position.supply, address(t.dsa));

        {
            t.success = cast(t.dsa, targetSpells);

            if (t.success) {
                executeMapping[t.key] = true;
                emit LogExecute(
                    sourceSpells,
                    targetSpells,
                    position,
                    actionId,
                    keccak256(abi.encodePacked(actionId)),
                    sourceDsaSender,
                    sourceDsaId,
                    targetDsaId,
                    sourceChainId,
                    targetChainId,
                    _vnonce
                );
            } else {
                emit LogTargetFailed(
                    sourceSpells,
                    targetSpells,
                    position,
                    actionId,
                    keccak256(abi.encodePacked(actionId)),
                    sourceDsaSender,
                    sourceDsaId,
                    targetDsaId,
                    sourceChainId,
                    targetChainId,
                    _vnonce
                );
                revert();
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Variables {
    mapping(bytes32 => bool) public executeMapping;
    mapping(bytes32 => address) public executeDsa;
    uint256 public vnonce;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./helpers.sol";

contract Events is Helpers {
    event LogSubmit(
        Position position,
        string actionId,
        bytes32 indexed actionIdHashHash,
        address sourceDsaSender,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce
    );

    event LogRevert(
        Position position,
        string actionId,
        bytes32 indexed actionIdHashHash,
        address sourceDsaSender,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce
    );
    
    event LogValidate(
        spell[] sourceSpells,
        Position position,
        string actionId,
        bytes32 indexed actionIdHash,
        address sourceDsaSender,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce
    );
    
    event LogExecute(
        spell[] sourceSpells,
        spell[] targetSpells,
        Position position,
        string actionId,
        bytes32 indexed actionIdHash,
        address sourceDsaSender,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce
    );
    

    event LogSourceFailed(
        spell[] sourceSpells,
        Position position,
        string actionId,
        bytes32 indexed actionIdHash,
        address sourceDsaSender,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce
    );

    event LogTargetFailed(
        spell[] sourceSpells,
        spell[] targetSpells,
        Position position,
        string actionId,
        bytes32 indexed actionIdHash,
        address sourceDsaSender,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IndexInterface {
    function list() external view returns (address);
}
interface ListInterface {
    struct UserLink {
        uint64 first;
        uint64 last;
        uint64 count;
    }

    struct UserList {
        uint64 prev;
        uint64 next;
    }

    struct AccountLink {
        address first;
        address last;
        uint64 count;
    }

    struct AccountList {
        address prev;
        address next;
    }

    function accounts() external view returns (uint);
    function accountID(address) external view returns (uint64);
    function accountAddr(uint64) external view returns (address);
    function userLink(address) external view returns (UserLink memory);
    function userList(address, uint64) external view returns (UserList memory);
    function accountLink(uint64) external view returns (AccountLink memory);
    function accountList(uint64, address) external view returns (AccountList memory);
}

interface AccountInterface {

    function version() external view returns (uint);

    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    )
    external
    payable 
    returns (bytes32);

    function isAuth(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces.sol";


contract Helpers {
    using SafeERC20 for IERC20;

    struct ActionVariables {
        bytes32 key;
        AccountInterface dsa;
        string[] connectors;
        bytes[] callData;
        bool success;
    }

    struct spell {
        string connector;
        bytes data;
    }

    struct TokenInfo {
        address sourceToken;
        address targetToken;
        uint256 amount;
    }
    
    struct Position {
        TokenInfo[] supply;
        TokenInfo[] withdraw;
    }

    address constant internal nativeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
     /**
     * @dev Return chain Id
     */
    function getChainID() internal view returns (uint256) {
        return block.chainid;
    }

    function sendSourceTokens(TokenInfo[] memory tokens, address dsa) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i].sourceToken);
            uint256 amount = tokens[i].amount;
            if (address(token) == nativeToken) {
                Address.sendValue(payable(dsa), amount);
            } else {
                token.safeTransfer(dsa, amount);
            }
        }
    }

    function sendTargetTokens(TokenInfo[] memory tokens, address dsa) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i].targetToken);
            uint256 amount = tokens[i].amount;
            if (address(token) == nativeToken) {
                Address.sendValue(payable(dsa), amount);
            } else {
                token.safeTransfer(dsa, amount);
            }
        }
    }

    function cast(AccountInterface dsa, spell[] memory spells) internal returns (bool success) {
        string[] memory connectors = new string[](spells.length);
        bytes[] memory callData = new bytes[](spells.length);
        for (uint256 i = 0; i < spells.length; i++) {
            connectors[i] = spells[i].connector;
            callData[i] = spells[i].data;
        }
        (success, ) = address(dsa).call(
            abi.encodeWithSignature(
                "cast(string[],bytes[],address)",
                connectors,
                callData,
                address(this)
            )
        );
    }
}

// SPDX-License-Identifier: MIT

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