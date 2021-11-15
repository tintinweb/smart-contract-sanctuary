// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity 0.7.5;

interface IOwnable {
    function owner() external view returns (address);
}

pragma solidity 0.7.5;

import "@openzeppelin/contracts/utils/Address.sol";
import "./VersionableModule.sol";
import "../../../interfaces/IOwnable.sol";

/**
 * @title OmnibridgeModule
 * @dev Common functionality for Omnibridge extension non-upgradeable module.
 */
abstract contract OmnibridgeModule is VersionableModule {
    IOwnable public mediator;

    /**
     * @dev Throws if sender is not the owner of this contract.
     */
    modifier onlyOwner {
        require(msg.sender == mediator.owner());
        _;
    }
}

pragma solidity 0.7.5;

/**
 * @title VersionableModule
 * @dev Interface for Omnibridge module versioning.
 */
interface VersionableModule {
    function getModuleInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        );
}

pragma solidity 0.7.5;

import "../OmnibridgeModule.sol";

/**
 * @title NFTForwardingRulesManager
 * @dev NFT Omnibrdge module for managing destination AMB lanes permissions.
 */
contract NFTForwardingRulesManager is OmnibridgeModule {
    address internal constant ANY_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    // Forwarding rules mapping
    // token => sender => receiver => destination lane
    mapping(address => mapping(address => mapping(address => int256))) public forwardingRule;

    event ForwardingRuleUpdated(address token, address sender, address receiver, int256 lane);

    /**
     * @dev Initializes this module contract. Intended to be called only once through the proxy pattern.
     * @param _mediator address of the Omnibridge contract working with this module.
     */
    function initialize(IOwnable _mediator) external {
        require(address(mediator) == address(0));

        mediator = _mediator;
    }

    /**
     * @dev Tells the module interface version that this contract supports.
     * @return major value of the version
     * @return minor value of the version
     * @return patch value of the version
     */
    function getModuleInterfacesVersion()
        external
        pure
        override
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (2, 2, 8);
    }

    /**
     * @dev Tells the destination lane for a particular bridge operation by checking several wildcard forwarding rules.
     * @param _token address of the token contract on the foreign side of the bridge.
     * @param _sender address of the tokens sender on the home side of the bridge.
     * @param _receiver address of the tokens receiver on the foreign side of the bridge.
     * @return destination lane identifier, where the message should be forwarded to.
     *  1 - oracle-driven-lane should be used.
     *  0 - default behaviour should be applied.
     * -1 - manual lane should be used.
     */
    function destinationLane(
        address _token,
        address _sender,
        address _receiver
    ) public view returns (int256) {
        int256 lane = forwardingRule[ANY_ADDRESS][_sender][ANY_ADDRESS]; // all tokens for specific sender
        if (lane != 0) return lane;
        lane = forwardingRule[ANY_ADDRESS][ANY_ADDRESS][_receiver]; // all tokens for specific receiver
        if (lane != 0) return lane;
        lane = forwardingRule[_token][ANY_ADDRESS][ANY_ADDRESS]; // specific token for all senders and receivers
        if (lane != 0) return lane;
        lane = forwardingRule[_token][_sender][ANY_ADDRESS]; // specific token for specific sender
        if (lane != 0) return lane;
        return forwardingRule[_token][ANY_ADDRESS][_receiver]; // specific token for specific receiver
    }

    /**
     * Updates the forwarding rule for bridging specific token.
     * Only owner can call this method.
     * @param _token address of the token contract on the foreign side.
     * @param _enable true, if bridge operations for a given token should be forwarded to the oracle-driven lane.
     */
    function setRuleForTokenToPBO(address _token, bool _enable) external {
        require(_token != ANY_ADDRESS);
        _setForwardingRule(_token, ANY_ADDRESS, ANY_ADDRESS, _enable ? int256(1) : int256(0));
    }

    /**
     * Allows a particular address to send bridge requests to the oracle-driven lane for a particular token.
     * Only owner can call this method.
     * @param _token address of the token contract on the foreign side.
     * @param _sender address of the tokens sender on the home side of the bridge.
     * @param _enable true, if bridge operations for a given token and sender should be forwarded to the oracle-driven lane.
     */
    function setRuleForTokenAndSenderToPBO(
        address _token,
        address _sender,
        bool _enable
    ) external {
        require(_token != ANY_ADDRESS);
        require(_sender != ANY_ADDRESS);
        _setForwardingRule(_token, _sender, ANY_ADDRESS, _enable ? int256(1) : int256(0));
    }

    /**
     * Allows a particular address to receive bridged tokens from the oracle-driven lane for a particular token.
     * Only owner can call this method.
     * @param _token address of the token contract on the foreign side.
     * @param _receiver address of the tokens receiver on the foreign side of the bridge.
     * @param _enable true, if bridge operations for a given token and receiver should be forwarded to the oracle-driven lane.
     */
    function setRuleForTokenAndReceiverToPBO(
        address _token,
        address _receiver,
        bool _enable
    ) external {
        require(_token != ANY_ADDRESS);
        require(_receiver != ANY_ADDRESS);
        _setForwardingRule(_token, ANY_ADDRESS, _receiver, _enable ? int256(1) : int256(0));
    }

    /**
     * Updates the forwarding rule for the specific sender.
     * Only owner can call this method.
     * @param _sender address of the tokens sender on the home side.
     * @param _enable true, if all bridge operations from a given sender should be forwarded to the oracle-driven lane.
     */
    function setRuleForSenderOfAnyTokenToPBO(address _sender, bool _enable) external {
        require(_sender != ANY_ADDRESS);
        _setForwardingRule(ANY_ADDRESS, _sender, ANY_ADDRESS, _enable ? int256(1) : int256(0));
    }

    /**
     * Updates the forwarding rule for the specific receiver.
     * Only owner can call this method.
     * @param _receiver address of the tokens receiver on the foreign side.
     * @param _enable true, if all bridge operations to a given receiver should be forwarded to the oracle-driven lane.
     */
    function setRuleForReceiverOfAnyTokenToPBO(address _receiver, bool _enable) external {
        require(_receiver != ANY_ADDRESS);
        _setForwardingRule(ANY_ADDRESS, ANY_ADDRESS, _receiver, _enable ? int256(1) : int256(0));
    }

    /**
     * Updates the forwarding rule for the specific sender.
     * Only owner can call this method.
     * @param _sender address of the tokens sender on the home side.
     * @param _enable true, if all bridge operations from a given sender should be forwarded to the manual lane.
     */
    function setRuleForSenderOfAnyTokenToPBU(address _sender, bool _enable) external {
        require(_sender != ANY_ADDRESS);
        _setForwardingRule(ANY_ADDRESS, _sender, ANY_ADDRESS, _enable ? int256(-1) : int256(0));
    }

    /**
     * Updates the forwarding rule for the specific receiver.
     * Only owner can call this method.
     * @param _receiver address of the tokens receiver on the foreign side.
     * @param _enable true, if all bridge operations to a given receiver should be forwarded to the manual lane.
     */
    function setRuleForReceiverOfAnyTokenToPBU(address _receiver, bool _enable) external {
        require(_receiver != ANY_ADDRESS);
        _setForwardingRule(ANY_ADDRESS, ANY_ADDRESS, _receiver, _enable ? int256(-1) : int256(0));
    }

    /**
     * @dev Internal function for updating the preferred destination lane for the specific wildcard pattern.
     * Only owner can call this method.
     * Examples:
     *   _setForwardingRule(tokenA, ANY_ADDRESS, ANY_ADDRESS, -1) - forward all operations on tokenA to the manual lane
     *   _setForwardingRule(tokenA, Alice, ANY_ADDRESS, 1) - allow Alice to use the oracle-driven lane for bridging tokenA
     *   _setForwardingRule(tokenA, ANY_ADDRESS, Bob, 1) - forward all tokenA bridge operations, where Bob is the receiver, to the oracle-driven lane
     *   _setForwardingRule(ANY_ADDRESS, Mallory, ANY_ADDRESS, -1) - forward all bridge operations from Mallory to the manual lane
     * @param _token address of the token contract on the foreign side of the bridge.
     * @param _sender address of the tokens sender on the home side of the bridge.
     * @param _receiver address of the tokens receiver on the foreign side of the bridge.
     * @param _lane preferred destination lane for the particular sender.
     *  1 - forward to the oracle-driven lane.
     *  0 - behaviour is unset, proceed by checking other less-specific rules.
     * -1 - manual lane should be used.
     */
    function _setForwardingRule(
        address _token,
        address _sender,
        address _receiver,
        int256 _lane
    ) internal onlyOwner {
        forwardingRule[_token][_sender][_receiver] = _lane;

        emit ForwardingRuleUpdated(_token, _sender, _receiver, _lane);
    }
}

