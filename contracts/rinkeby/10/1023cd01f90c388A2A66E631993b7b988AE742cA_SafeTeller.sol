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

pragma solidity 0.7.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IGnosisSafe.sol";
import "./interfaces/IGnosisSafeProxyFactory.sol";

contract SafeTeller {
    using Address for address;

    // mainnet: 0x76E2cFc1F5Fa8F6a5b3fC4c8F4788F0116861F9B;
    address public proxyFactoryAddress;

    // mainnet: 0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F;
    address public gnosisMasterAddress;

    string public constant FUNCTION_SIG_SETUP =
        "setup(address[],uint256,address,bytes,address,address,uint256,address)";
    string public constant FUNCTION_SIG_EXEC =
        "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)";

    string public constant FUNCTION_SIG_ENABLE = "delegateSetup(address)";

    address internal constant SENTINEL = address(0x1);

    address public controller;
    address public context;

    event CreateSafe(uint256 indexed podId, address safeAddress);

    /**
     * @param _proxyFactoryAddress The proxy factory address
     * @param _gnosisMasterAddress The gnosis master address
     */
    constructor(address _proxyFactoryAddress, address _gnosisMasterAddress) {
        require(
            _proxyFactoryAddress != address(0),
            "Invalid proxyFactory address"
        );
        require(
            _gnosisMasterAddress != address(0),
            "Invalid gnosisMaster address"
        );
        controller = msg.sender;
        proxyFactoryAddress = _proxyFactoryAddress;
        gnosisMasterAddress = _gnosisMasterAddress;
        context = address(this);
    }

    /**
     * @param _controller The address to set as controller
     */
    function updateController(address _controller) external {
        require(_controller != address(0), "Invalid controller address");
        require(controller == msg.sender, "!controller");
        controller = _controller;
    }

    /**
     * @param safe The address of the safe
     * @param _newSafeTeller The address of the new safe teller contract
     */
    function migrateSafeTeller(address safe, address _newSafeTeller) external {
        require(controller == msg.sender, "!controller");
        bytes memory enableData = abi.encodeWithSignature(
            "enableModule(address)",
            _newSafeTeller
        );

        bool enableSuccess = IGnosisSafe(safe).execTransactionFromModule(
            safe,
            0,
            enableData,
            IGnosisSafe.Operation.Call
        );
        require(enableSuccess, "Migration failed on enable");

        // find current safe teller in module array
        uint256 pageSize = 10;
        address index = SENTINEL;
        address prevModule = address(0);

        while (prevModule == address(0)) {
            (address[] memory moduleBuffer, address next) = IGnosisSafe(safe)
                .getModulesPaginated(index, pageSize);
            require(moduleBuffer[0] != address(0), "module not found");
            index = next;

            for (uint256 i = 0; i < moduleBuffer.length; i++) {
                if (moduleBuffer[i] == address(this))
                    prevModule = i > 0 ? moduleBuffer[i - 1] : moduleBuffer[0];
            }
        }

        // disable current safeTeller
        bytes memory disableData = abi.encodeWithSignature(
            "disableModule(address,address)",
            prevModule,
            address(this)
        );

        bool disableSuccess = IGnosisSafe(safe).execTransactionFromModule(
            safe,
            0,
            disableData,
            IGnosisSafe.Operation.Call
        );
        require(disableSuccess, "Migration failed on disable");
    }

    function getMembers(address safe) external returns (address[] memory) {
        return IGnosisSafe(safe).getOwners();
    }

    function isModuleEnabled(address safe) external view returns (bool) {
        return IGnosisSafe(safe).isModuleEnabled(address(this));
    }

    /**
     * @param _podId The id number of the pod
     * @param _owners The  addresses to be owners of the safe
     * @param _threshold The number of owners that are required to sign a transaciton
     * @return safeAddress The address of the new safe
     */
    function createSafe(
        uint256 _podId,
        address[] memory _owners,
        uint256 _threshold
    ) external returns (address safeAddress) {
        require(controller == msg.sender, "!controller");
        bytes memory data = abi.encodeWithSignature(
            FUNCTION_SIG_ENABLE,
            context
        );

        // encode the setup call that will be called on the new proxy safe
        // from the proxy factory
        bytes memory setupData = abi.encodeWithSignature(
            FUNCTION_SIG_SETUP,
            _owners,
            _threshold,
            this,
            data,
            address(0),
            address(0),
            uint256(0),
            address(0)
        );

        try
            IGnosisSafeProxyFactory(proxyFactoryAddress).createProxy(
                gnosisMasterAddress,
                setupData
            )
        returns (address newSafeAddress) {
            emit CreateSafe(_podId, newSafeAddress);
            return newSafeAddress;
        } catch (bytes memory) {
            revert("Create Proxy With Data Failed");
        }
    }

    //TODO: could probably do all this as a delegate call
    /**
     * @param to The account address to add as an owner
     * @param safe The address of the safe
     */
    function onMint(address to, address safe) external {
        require(controller == msg.sender, "!controller");
        uint256 threshold = IGnosisSafe(safe).getThreshold();

        bytes memory data = abi.encodeWithSignature(
            "addOwnerWithThreshold(address,uint256)",
            to,
            threshold
        );

        bool success = IGnosisSafe(safe).execTransactionFromModule(
            safe,
            0,
            data,
            IGnosisSafe.Operation.Call
        );

        require(success, "Module Transaction Failed");
    }

    /**
     * @param from The address to be removed as an owner
     * @param safe The address of the safe
     */
    function onBurn(address from, address safe) external {
        require(controller == msg.sender, "!controller");
        uint256 threshold = IGnosisSafe(safe).getThreshold();
        address[] memory owners = IGnosisSafe(safe).getOwners();

        //look for the address pointing to address from
        address prevFrom = address(0);
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == from) {
                if (i == 0) {
                    prevFrom = SENTINEL;
                } else {
                    prevFrom = owners[i - 1];
                }
            }
        }
        if (owners.length - 1 < threshold) threshold -= 1;
        bytes memory data = abi.encodeWithSignature(
            "removeOwner(address,address,uint256)",
            prevFrom,
            from,
            threshold
        );

        bool success = IGnosisSafe(safe).execTransactionFromModule(
            safe,
            0,
            data,
            IGnosisSafe.Operation.Call
        );
        require(success, "Module Transaction Failed");
    }

    /**
     * @param from The address being removed as an owner
     * @param to The address being added as an owner
     * @param safe The address of the safe
     */
    function onTransfer(
        address from,
        address to,
        address safe
    ) external {
        require(controller == msg.sender, "!controller");
        address[] memory owners = IGnosisSafe(safe).getOwners();

        //look for the address pointing to address from
        address prevFrom;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == from) {
                if (i == 0) {
                    prevFrom = SENTINEL;
                } else {
                    prevFrom = owners[i - 1];
                }
            }
        }

        bytes memory data = abi.encodeWithSignature(
            "swapOwner(address,address,address)",
            prevFrom,
            from,
            to
        );

        bool success = IGnosisSafe(safe).execTransactionFromModule(
            safe,
            0,
            data,
            IGnosisSafe.Operation.Call
        );
        require(success, "Module Transaction Failed");
    }

    // TODO: move to library
    // Used in a delegate call to enable module add on setup
    function enableModule(address module) external {
        require(module == address(0));
    }

    function delegateSetup(address _context) external {
        this.enableModule(_context);
    }
}

pragma solidity 0.7.4;

interface IGnosisSafe {

    enum Operation {Call, DelegateCall}

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external returns (bool success);

    /// @dev Returns array of owners.
    /// @return Array of Safe owners.
    function getOwners() external returns (address[] memory);

    function getThreshold() external returns (uint256);

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        returns (address[] memory array, address next);

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);
}

pragma solidity 0.7.4;

interface IGnosisSafeProxyFactory {
    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param singleton Address of singleton contract.
    /// @param data Payload for message call sent to new proxy contract.
    function createProxy(address singleton, bytes memory data)
        external
        returns (address);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}