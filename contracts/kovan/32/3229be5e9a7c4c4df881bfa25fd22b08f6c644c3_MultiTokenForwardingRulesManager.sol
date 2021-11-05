/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: Unlicensed

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: contracts/upgradeable_contracts/modules/OwnableModule.sol

pragma solidity 0.7.5;


/**
 * @title OwnableModule
 * @dev Common functionality for multi-token extension non-upgradeable module.
 */
contract OwnableModule {
    address public owner;

    /**
     * @dev Initializes this contract.
     * @param _owner address of the owner that is allowed to perform additional actions on the particular module.
     */
    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @dev Throws if sender is not the owner of this contract.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Changes the owner of this contract.
     * @param _newOwner address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
}

// File: contracts/upgradeable_contracts/modules/forwarding_rules/MultiTokenForwardingRulesManager.sol

pragma solidity 0.7.5;


/**
 * @title MultiTokenForwardingRulesManager
 * @dev Multi token mediator functionality for managing destination AMB lanes permissions.
 */
contract MultiTokenForwardingRulesManager is OwnableModule {
    address internal constant ANY_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    // Forwarding rules mapping
    // token => sender => receiver => destination lane
    mapping(address => mapping(address => mapping(address => int256))) public forwardingRule;

    event ForwardingRuleUpdated(address token, address sender, address receiver, int256 lane);

    // solhint-disable-next-line no-empty-blocks
    constructor(address _owner) OwnableModule(_owner) {}

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
        int256 defaultLane = forwardingRule[_token][ANY_ADDRESS][ANY_ADDRESS]; // specific token for all senders and receivers
        int256 lane;
        if (defaultLane < 0) {
            lane = forwardingRule[_token][_sender][ANY_ADDRESS]; // specific token for specific sender
            if (lane != 0) return lane;
            lane = forwardingRule[_token][ANY_ADDRESS][_receiver]; // specific token for specific receiver
            if (lane != 0) return lane;
            return defaultLane;
        }
        lane = forwardingRule[ANY_ADDRESS][_sender][ANY_ADDRESS]; // all tokens for specific sender
        if (lane != 0) return lane;
        return forwardingRule[ANY_ADDRESS][ANY_ADDRESS][_receiver]; // all tokens for specific receiver
    }

    /**
     * Updates the forwarding rule for bridging specific token.
     * Only owner can call this method.
     * @param _token address of the token contract on the foreign side.
     * @param _enable true, if bridge operations for a given token should be forwarded to the manual lane.
     */
    function setTokenForwardingRule(address _token, bool _enable) external {
        require(_token != ANY_ADDRESS);
        _setForwardingRule(_token, ANY_ADDRESS, ANY_ADDRESS, _enable ? int256(-1) : int256(0));
    }

    /**
     * Allows a particular address to send bridge requests to the oracle-driven lane for a particular token.
     * Only owner can call this method.
     * @param _token address of the token contract on the foreign side.
     * @param _sender address of the tokens sender on the home side of the bridge.
     * @param _enable true, if bridge operations for a given token and sender should be forwarded to the oracle-driven lane.
     */
    function setSenderExceptionForTokenForwardingRule(
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
    function setReceiverExceptionForTokenForwardingRule(
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
     * @param _enable true, if all bridge operations from a given sender should be forwarded to the manual lane.
     */
    function setSenderForwardingRule(address _sender, bool _enable) external {
        require(_sender != ANY_ADDRESS);
        _setForwardingRule(ANY_ADDRESS, _sender, ANY_ADDRESS, _enable ? int256(-1) : int256(0));
    }

    /**
     * Updates the forwarding rule for the specific receiver.
     * Only owner can call this method.
     * @param _receiver address of the tokens receiver on the foreign side.
     * @param _enable true, if all bridge operations to a given receiver should be forwarded to the manual lane.
     */
    function setReceiverForwardingRule(address _receiver, bool _enable) external {
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