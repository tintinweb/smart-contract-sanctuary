// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   DepositBoxERC20.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2019-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@skalenetwork/ima-interfaces/mainnet/DepositBoxes/IDepositBoxERC20.sol";

import "../../Messages.sol";
import "../DepositBox.sol";


/**
 * @title DepositBoxERC20
 * @dev Runs on mainnet,
 * accepts messages from schain,
 * stores deposits of ERC20.
 */
contract DepositBoxERC20 is DepositBox, IDepositBoxERC20 {
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // schainHash => address of ERC20 on Mainnet
    mapping(bytes32 => mapping(address => bool)) private _deprecatedSchainToERC20;
    mapping(bytes32 => mapping(address => uint256)) public transferredAmount;
    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _schainToERC20;

    /**
     * @dev Emitted when token is mapped in DepositBoxERC20.
     */
    event ERC20TokenAdded(string schainName, address indexed contractOnMainnet);
    
    /**
     * @dev Emitted when token is received by DepositBox and is ready to be cloned
     * or transferred on SKALE chain.
     */
    event ERC20TokenReady(address indexed contractOnMainnet, uint256 amount);

    /**
     * @dev Allows DEFAULT_ADMIN_ROLE to initialize token mapping
     * Notice - this function will be executed only once during upgrade
     * 
     * Requirements:
     * 
     * `msg.sender` should has DEFAULT_ADMIN_ROLE
     */
    function initializeAllTokensForSchain(
        string calldata schainName,
        address[] calldata tokens
    )
        external
        override
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Sender is not authorized");
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        for (uint256 i = 0; i < tokens.length; i++) {
            if (_deprecatedSchainToERC20[schainHash][tokens[i]] && !_schainToERC20[schainHash].contains(tokens[i])) {
                _schainToERC20[schainHash].add(tokens[i]);
                delete _deprecatedSchainToERC20[schainHash][tokens[i]];
            }
        }
    }

    /**
     * @dev Allows `msg.sender` to send ERC20 token from mainnet to schain
     * 
     * Requirements:
     * 
     * - Schain name must not be `Mainnet`.
     * - Receiver account on schain cannot be null.
     * - Schain that receives tokens should not be killed.
     * - Receiver contract should be defined.
     * - `msg.sender` should approve their tokens for DepositBoxERC20 address.
     */
    function depositERC20(
        string calldata schainName,
        address erc20OnMainnet,
        uint256 amount
    )
        external
        override
        rightTransaction(schainName, msg.sender)
        whenNotKilled(keccak256(abi.encodePacked(schainName)))
    {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        address contractReceiver = schainLinks[schainHash];
        require(contractReceiver != address(0), "Unconnected chain");
        require(
            ERC20Upgradeable(erc20OnMainnet).allowance(msg.sender, address(this)) >= amount,
            "DepositBox was not approved for ERC20 token"
        );
        bytes memory data = _receiveERC20(
            schainName,
            erc20OnMainnet,
            msg.sender,
            amount
        );
        if (!linker.interchainConnections(schainHash))
            _saveTransferredAmount(schainHash, erc20OnMainnet, amount);
        require(
            ERC20Upgradeable(erc20OnMainnet).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Transfer was failed"
        );
        messageProxy.postOutgoingMessage(
            schainHash,
            contractReceiver,
            data
        );
    }

    /**
     * @dev Allows MessageProxyForMainnet contract to execute transferring ERC20 token from schain to mainnet.
     * 
     * Requirements:
     * 
     * - Schain from which the tokens came should not be killed.
     * - Sender contract should be defined and schain name cannot be `Mainnet`.
     * - Amount of tokens on DepositBoxERC20 should be equal or more than transferred amount.
     */
    function postMessage(
        bytes32 schainHash,
        address sender,
        bytes calldata data
    )
        external
        override
        onlyMessageProxy
        whenNotKilled(schainHash)
        checkReceiverChain(schainHash, sender)
        returns (address)
    {
        Messages.TransferErc20Message memory message = Messages.decodeTransferErc20Message(data);
        require(message.token.isContract(), "Given address is not a contract");
        require(ERC20Upgradeable(message.token).balanceOf(address(this)) >= message.amount, "Not enough money");
        if (!linker.interchainConnections(schainHash))
            _removeTransferredAmount(schainHash, message.token, message.amount);
        require(
            ERC20Upgradeable(message.token).transfer(message.receiver, message.amount),
            "Transfer was failed"
        );
        return message.receiver;
    }

    /**
     * @dev Allows Schain owner to add an ERC20 token to DepositBoxERC20.
     * 
     * Emits an {ERC20TokenAdded} event.
     * 
     * Requirements:
     * 
     * - Schain should not be killed.
     * - Only owner of the schain able to run function.
     */
    function addERC20TokenByOwner(string calldata schainName, address erc20OnMainnet)
        external
        override
        onlySchainOwner(schainName)
        whenNotKilled(keccak256(abi.encodePacked(schainName)))
    {
        _addERC20ForSchain(schainName, erc20OnMainnet);
    }

    /**
     * @dev Allows Schain owner to return each user their tokens.
     * The Schain owner decides which tokens to send to which address, 
     * since the contract on mainnet does not store information about which tokens belong to whom.
     *
     * Requirements:
     * 
     * - Amount of tokens on schain should be equal or more than transferred amount.
     * - msg.sender should be an owner of schain
     * - IMA transfers Mainnet <-> schain should be killed
     */
    function getFunds(string calldata schainName, address erc20OnMainnet, address receiver, uint amount)
        external
        override
        onlySchainOwner(schainName)
        whenKilled(keccak256(abi.encodePacked(schainName)))
    {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(transferredAmount[schainHash][erc20OnMainnet] >= amount, "Incorrect amount");
        _removeTransferredAmount(schainHash, erc20OnMainnet, amount);
        require(
            ERC20Upgradeable(erc20OnMainnet).transfer(receiver, amount),
            "Transfer was failed"
        );
    }

    function gasPayer(
        bytes32 schainHash,
        address sender,
        bytes calldata data
    )
        external
        view
        override
        checkReceiverChain(schainHash, sender)
        returns (address)
    {
        Messages.TransferErc20Message memory message = Messages.decodeTransferErc20Message(data);
        return message.receiver;
    }

    /**
     * @dev Should return true if token was added by Schain owner or 
     * added automatically after sending to schain if whitelist was turned off.
     */
    function getSchainToERC20(
        string calldata schainName,
        address erc20OnMainnet
    )
        external
        view
        override
        returns (bool)
    {
        return _schainToERC20[keccak256(abi.encodePacked(schainName))].contains(erc20OnMainnet);
    }

    /**
     * @dev Should return length of a set of all mapped tokens which were added by Schain owner 
     * or added automatically after sending to schain if whitelist was turned off.
     */
    function getSchainToAllERC20Length(string calldata schainName) external view override returns (uint256) {
        return _schainToERC20[keccak256(abi.encodePacked(schainName))].length();
    }

    /**
     * @dev Should return an array of range of tokens were added by Schain owner 
     * or added automatically after sending to schain if whitelist was turned off.
     */
    function getSchainToAllERC20(
        string calldata schainName,
        uint256 from,
        uint256 to
    )
        external
        view
        override
        returns (address[] memory tokensInRange)
    {
        require(
            from < to && to - from <= 10 && to <= _schainToERC20[keccak256(abi.encodePacked(schainName))].length(),
            "Range is incorrect"
        );
        tokensInRange = new address[](to - from);
        for (uint256 i = from; i < to; i++) {
            tokensInRange[i - from] = _schainToERC20[keccak256(abi.encodePacked(schainName))].at(i);
        }
    }

    /**
     * @dev Creates a new DepositBoxERC20 contract.
     */
    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        ILinker linkerValue,
        IMessageProxyForMainnet messageProxyValue
    )
        public
        override(DepositBox, IDepositBox)
        initializer
    {
        DepositBox.initialize(contractManagerOfSkaleManagerValue, linkerValue, messageProxyValue);
    }

    /**
     * @dev Saves amount of tokens that was transferred to schain.
     */
    function _saveTransferredAmount(bytes32 schainHash, address erc20Token, uint256 amount) private {
        transferredAmount[schainHash][erc20Token] += amount;
    }

    /**
     * @dev Removes amount of tokens that was transferred from schain.
     */
    function _removeTransferredAmount(bytes32 schainHash, address erc20Token, uint256 amount) private {
        transferredAmount[schainHash][erc20Token] -= amount;
    }

    /**
     * @dev Allows DepositBoxERC20 to receive ERC20 tokens.
     * 
     * Emits an {ERC20TokenReady} event.
     * 
     * Requirements:
     * 
     * - Amount must be less than or equal to the total supply of the ERC20 contract.
     * - Whitelist should be turned off for auto adding tokens to DepositBoxERC20.
     */
    function _receiveERC20(
        string calldata schainName,
        address erc20OnMainnet,
        address to,
        uint256 amount
    )
        private
        returns (bytes memory data)
    {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        ERC20Upgradeable erc20 = ERC20Upgradeable(erc20OnMainnet);
        uint256 totalSupply = erc20.totalSupply();
        require(amount <= totalSupply, "Amount is incorrect");
        bool isERC20AddedToSchain = _schainToERC20[schainHash].contains(erc20OnMainnet);
        if (!isERC20AddedToSchain) {
            require(!isWhitelisted(schainName), "Whitelist is enabled");
            _addERC20ForSchain(schainName, erc20OnMainnet);
            data = Messages.encodeTransferErc20AndTokenInfoMessage(
                erc20OnMainnet,
                to,
                amount,
                _getErc20TotalSupply(erc20),
                _getErc20TokenInfo(erc20)
            );
        } else {
            data = Messages.encodeTransferErc20AndTotalSupplyMessage(
                erc20OnMainnet,
                to,
                amount,
                _getErc20TotalSupply(erc20)
            );
        }
        emit ERC20TokenReady(erc20OnMainnet, amount);
    }

    /**
     * @dev Adds an ERC20 token to DepositBoxERC20.
     * 
     * Emits an {ERC20TokenAdded} event.
     * 
     * Requirements:
     * 
     * - Given address should be contract.
     */
    function _addERC20ForSchain(string calldata schainName, address erc20OnMainnet) private {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(erc20OnMainnet.isContract(), "Given address is not a contract");
        require(!_schainToERC20[schainHash].contains(erc20OnMainnet), "ERC20 Token was already added");
        _schainToERC20[schainHash].add(erc20OnMainnet);
        emit ERC20TokenAdded(schainName, erc20OnMainnet);
    }

    /**
     * @dev Returns total supply of ERC20 token.
     */
    function _getErc20TotalSupply(ERC20Upgradeable erc20Token) private view returns (uint256) {
        return erc20Token.totalSupply();
    }

    /**
     * @dev Returns info about ERC20 token such as token name, decimals, symbol.
     */
    function _getErc20TokenInfo(ERC20Upgradeable erc20Token) private view returns (Messages.Erc20TokenInfo memory) {
        return Messages.Erc20TokenInfo({
            name: erc20Token.name(),
            decimals: erc20Token.decimals(),
            symbol: erc20Token.symbol()
        });
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   IDepositBoxERC20.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "../IDepositBox.sol";


interface IDepositBoxERC20 is IDepositBox {
    function initializeAllTokensForSchain(
        string calldata schainName,
        address[] calldata tokens
    ) external;
    function depositERC20(string calldata schainName, address erc20OnMainnet, uint256 amount) external;
    function addERC20TokenByOwner(string calldata schainName, address erc20OnMainnet) external;
    function getFunds(string calldata schainName, address erc20OnMainnet, address receiver, uint amount) external;
    function getSchainToERC20(string calldata schainName, address erc20OnMainnet) external view returns (bool);
    function getSchainToAllERC20Length(string calldata schainName) external view returns (uint256);
    function getSchainToAllERC20(
        string calldata schainName,
        uint256 from,
        uint256 to
    )
        external
        view
        returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   Messages.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.6;


/**
 * @title Messages
 * @dev Library for encoding and decoding messages
 * for transferring from Mainnet to Schain and vice versa.
 */
library Messages {

    /**
     * @dev Enumerator that describes all supported message types.
     */
    enum MessageType {
        EMPTY,
        TRANSFER_ETH,
        TRANSFER_ERC20,
        TRANSFER_ERC20_AND_TOTAL_SUPPLY,
        TRANSFER_ERC20_AND_TOKEN_INFO,
        TRANSFER_ERC721,
        TRANSFER_ERC721_AND_TOKEN_INFO,
        USER_STATUS,
        INTERCHAIN_CONNECTION,
        TRANSFER_ERC1155,
        TRANSFER_ERC1155_AND_TOKEN_INFO,
        TRANSFER_ERC1155_BATCH,
        TRANSFER_ERC1155_BATCH_AND_TOKEN_INFO
    }

    /**
     * @dev Structure for base message.
     */
    struct BaseMessage {
        MessageType messageType;
    }

    /**
     * @dev Structure for describing ETH.
     */
    struct TransferEthMessage {
        BaseMessage message;
        address receiver;
        uint256 amount;
    }

    /**
     * @dev Structure for user status.
     */
    struct UserStatusMessage {
        BaseMessage message;
        address receiver;
        bool isActive;
    }

    /**
     * @dev Structure for describing ERC20 token.
     */
    struct TransferErc20Message {
        BaseMessage message;
        address token;
        address receiver;
        uint256 amount;
    }

    /**
     * @dev Structure for describing additional data for ERC20 token.
     */
    struct Erc20TokenInfo {
        string name;
        uint8 decimals;
        string symbol;
    }

    /**
     * @dev Structure for describing ERC20 with token supply.
     */
    struct TransferErc20AndTotalSupplyMessage {
        TransferErc20Message baseErc20transfer;
        uint256 totalSupply;
    }

    /**
     * @dev Structure for describing ERC20 with token info.
     */
    struct TransferErc20AndTokenInfoMessage {
        TransferErc20Message baseErc20transfer;
        uint256 totalSupply;
        Erc20TokenInfo tokenInfo;
    }

    /**
     * @dev Structure for describing base ERC721.
     */
    struct TransferErc721Message {
        BaseMessage message;
        address token;
        address receiver;
        uint256 tokenId;
    }

    /**
     * @dev Structure for describing ERC20 with token info.
     */
    struct Erc721TokenInfo {
        string name;
        string symbol;
    }

    /**
     * @dev Structure for describing additional data for ERC721 token.
     */
    struct TransferErc721AndTokenInfoMessage {
        TransferErc721Message baseErc721transfer;
        Erc721TokenInfo tokenInfo;
    }

    /**
     * @dev Structure for describing whether interchain connection is allowed.
     */
    struct InterchainConnectionMessage {
        BaseMessage message;
        bool isAllowed;
    }

    /**
     * @dev Structure for describing whether interchain connection is allowed.
     */
    struct TransferErc1155Message {
        BaseMessage message;
        address token;
        address receiver;
        uint256 id;
        uint256 amount;
    }

    /**
     * @dev Structure for describing ERC1155 token in batches.
     */
    struct TransferErc1155BatchMessage {
        BaseMessage message;
        address token;
        address receiver;
        uint256[] ids;
        uint256[] amounts;
    }

    /**
     * @dev Structure for describing ERC1155 token info.
     */
    struct Erc1155TokenInfo {
        string uri;
    }

    /**
     * @dev Structure for describing message for transferring ERC1155 token with info.
     */
    struct TransferErc1155AndTokenInfoMessage {
        TransferErc1155Message baseErc1155transfer;
        Erc1155TokenInfo tokenInfo;
    }

    /**
     * @dev Structure for describing message for transferring ERC1155 token in batches with info.
     */
    struct TransferErc1155BatchAndTokenInfoMessage {
        TransferErc1155BatchMessage baseErc1155Batchtransfer;
        Erc1155TokenInfo tokenInfo;
    }


    /**
     * @dev Returns type of message for encoded data.
     */
    function getMessageType(bytes calldata data) internal pure returns (MessageType) {
        uint256 firstWord = abi.decode(data, (uint256));
        if (firstWord % 32 == 0) {
            return getMessageType(data[firstWord:]);
        } else {
            return abi.decode(data, (Messages.MessageType));
        }
    }

    /**
     * @dev Encodes message for transferring ETH. Returns encoded message.
     */
    function encodeTransferEthMessage(address receiver, uint256 amount) internal pure returns (bytes memory) {
        TransferEthMessage memory message = TransferEthMessage(
            BaseMessage(MessageType.TRANSFER_ETH),
            receiver,
            amount
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ETH. Returns structure `TransferEthMessage`.
     */
    function decodeTransferEthMessage(
        bytes calldata data
    ) internal pure returns (TransferEthMessage memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ETH, "Message type is not ETH transfer");
        return abi.decode(data, (TransferEthMessage));
    }

    /**
     * @dev Encodes message for transferring ETH. Returns encoded message.
     */
    function encodeTransferErc20Message(
        address token,
        address receiver,
        uint256 amount
    ) internal pure returns (bytes memory) {
        TransferErc20Message memory message = TransferErc20Message(
            BaseMessage(MessageType.TRANSFER_ERC20),
            token,
            receiver,
            amount
        );
        return abi.encode(message);
    }

    /**
     * @dev Encodes message for transferring ERC20 with total supply. Returns encoded message.
     */
    function encodeTransferErc20AndTotalSupplyMessage(
        address token,
        address receiver,
        uint256 amount,
        uint256 totalSupply
    ) internal pure returns (bytes memory) {
        TransferErc20AndTotalSupplyMessage memory message = TransferErc20AndTotalSupplyMessage(
            TransferErc20Message(
                BaseMessage(MessageType.TRANSFER_ERC20_AND_TOTAL_SUPPLY),
                token,
                receiver,
                amount
            ),
            totalSupply
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC20. Returns structure `TransferErc20Message`.
     */
    function decodeTransferErc20Message(
        bytes calldata data
    ) internal pure returns (TransferErc20Message memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ERC20, "Message type is not ERC20 transfer");
        return abi.decode(data, (TransferErc20Message));
    }

    /**
     * @dev Decodes message for transferring ERC20 with total supply. 
     * Returns structure `TransferErc20AndTotalSupplyMessage`.
     */
    function decodeTransferErc20AndTotalSupplyMessage(
        bytes calldata data
    ) internal pure returns (TransferErc20AndTotalSupplyMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC20_AND_TOTAL_SUPPLY,
            "Message type is not ERC20 transfer and total supply"
        );
        return abi.decode(data, (TransferErc20AndTotalSupplyMessage));
    }

    /**
     * @dev Encodes message for transferring ERC20 with token info. 
     * Returns encoded message.
     */
    function encodeTransferErc20AndTokenInfoMessage(
        address token,
        address receiver,
        uint256 amount,
        uint256 totalSupply,
        Erc20TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc20AndTokenInfoMessage memory message = TransferErc20AndTokenInfoMessage(
            TransferErc20Message(
                BaseMessage(MessageType.TRANSFER_ERC20_AND_TOKEN_INFO),
                token,
                receiver,
                amount
            ),
            totalSupply,
            tokenInfo
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC20 with token info. 
     * Returns structure `TransferErc20AndTokenInfoMessage`.
     */
    function decodeTransferErc20AndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc20AndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC20_AND_TOKEN_INFO,
            "Message type is not ERC20 transfer with token info"
        );
        return abi.decode(data, (TransferErc20AndTokenInfoMessage));
    }

    /**
     * @dev Encodes message for transferring ERC721. 
     * Returns encoded message.
     */
    function encodeTransferErc721Message(
        address token,
        address receiver,
        uint256 tokenId
    ) internal pure returns (bytes memory) {
        TransferErc721Message memory message = TransferErc721Message(
            BaseMessage(MessageType.TRANSFER_ERC721),
            token,
            receiver,
            tokenId
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC721. 
     * Returns structure `TransferErc721Message`.
     */
    function decodeTransferErc721Message(
        bytes calldata data
    ) internal pure returns (TransferErc721Message memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ERC721, "Message type is not ERC721 transfer");
        return abi.decode(data, (TransferErc721Message));
    }

    /**
     * @dev Encodes message for transferring ERC721 with token info. 
     * Returns encoded message.
     */
    function encodeTransferErc721AndTokenInfoMessage(
        address token,
        address receiver,
        uint256 tokenId,
        Erc721TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc721AndTokenInfoMessage memory message = TransferErc721AndTokenInfoMessage(
            TransferErc721Message(
                BaseMessage(MessageType.TRANSFER_ERC721_AND_TOKEN_INFO),
                token,
                receiver,
                tokenId
            ),
            tokenInfo
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC721 with token info. 
     * Returns structure `TransferErc721AndTokenInfoMessage`.
     */
    function decodeTransferErc721AndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc721AndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC721_AND_TOKEN_INFO,
            "Message type is not ERC721 transfer with token info"
        );
        return abi.decode(data, (TransferErc721AndTokenInfoMessage));
    }

    /**
     * @dev Encodes message for activating user on schain. 
     * Returns encoded message.
     */
    function encodeActivateUserMessage(address receiver) internal pure returns (bytes memory){
        return _encodeUserStatusMessage(receiver, true);
    }

    /**
     * @dev Encodes message for locking user on schain. 
     * Returns encoded message.
     */
    function encodeLockUserMessage(address receiver) internal pure returns (bytes memory){
        return _encodeUserStatusMessage(receiver, false);
    }

    /**
     * @dev Decodes message for user status. 
     * Returns structure UserStatusMessage.
     */
    function decodeUserStatusMessage(bytes calldata data) internal pure returns (UserStatusMessage memory) {
        require(getMessageType(data) == MessageType.USER_STATUS, "Message type is not User Status");
        return abi.decode(data, (UserStatusMessage));
    }


    /**
     * @dev Encodes message for allowing interchain connection.
     * Returns encoded message.
     */
    function encodeInterchainConnectionMessage(bool isAllowed) internal pure returns (bytes memory) {
        InterchainConnectionMessage memory message = InterchainConnectionMessage(
            BaseMessage(MessageType.INTERCHAIN_CONNECTION),
            isAllowed
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for allowing interchain connection.
     * Returns structure `InterchainConnectionMessage`.
     */
    function decodeInterchainConnectionMessage(bytes calldata data)
        internal
        pure
        returns (InterchainConnectionMessage memory)
    {
        require(getMessageType(data) == MessageType.INTERCHAIN_CONNECTION, "Message type is not Interchain connection");
        return abi.decode(data, (InterchainConnectionMessage));
    }

    /**
     * @dev Encodes message for transferring ERC1155 token.
     * Returns encoded message.
     */
    function encodeTransferErc1155Message(
        address token,
        address receiver,
        uint256 id,
        uint256 amount
    ) internal pure returns (bytes memory) {
        TransferErc1155Message memory message = TransferErc1155Message(
            BaseMessage(MessageType.TRANSFER_ERC1155),
            token,
            receiver,
            id,
            amount
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC1155 token.
     * Returns structure `TransferErc1155Message`.
     */
    function decodeTransferErc1155Message(
        bytes calldata data
    ) internal pure returns (TransferErc1155Message memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ERC1155, "Message type is not ERC1155 transfer");
        return abi.decode(data, (TransferErc1155Message));
    }

    /**
     * @dev Encodes message for transferring ERC1155 with token info.
     * Returns encoded message.
     */
    function encodeTransferErc1155AndTokenInfoMessage(
        address token,
        address receiver,
        uint256 id,
        uint256 amount,
        Erc1155TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc1155AndTokenInfoMessage memory message = TransferErc1155AndTokenInfoMessage(
            TransferErc1155Message(
                BaseMessage(MessageType.TRANSFER_ERC1155_AND_TOKEN_INFO),
                token,
                receiver,
                id,
                amount
            ),
            tokenInfo
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC1155 with token info.
     * Returns structure `TransferErc1155AndTokenInfoMessage`.
     */
    function decodeTransferErc1155AndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc1155AndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC1155_AND_TOKEN_INFO,
            "Message type is not ERC1155AndTokenInfo transfer"
        );
        return abi.decode(data, (TransferErc1155AndTokenInfoMessage));
    }

    /**
     * @dev Encodes message for transferring ERC1155 token in batches.
     * Returns encoded message.
     */
    function encodeTransferErc1155BatchMessage(
        address token,
        address receiver,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal pure returns (bytes memory) {
        TransferErc1155BatchMessage memory message = TransferErc1155BatchMessage(
            BaseMessage(MessageType.TRANSFER_ERC1155_BATCH),
            token,
            receiver,
            ids,
            amounts
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC1155 token in batches.
     * Returns structure `TransferErc1155BatchMessage`.
     */
    function decodeTransferErc1155BatchMessage(
        bytes calldata data
    ) internal pure returns (TransferErc1155BatchMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC1155_BATCH,
            "Message type is not ERC1155Batch transfer"
        );
        return abi.decode(data, (TransferErc1155BatchMessage));
    }

    /**
     * @dev Encodes message for transferring ERC1155 token in batches with token info.
     * Returns encoded message.
     */
    function encodeTransferErc1155BatchAndTokenInfoMessage(
        address token,
        address receiver,
        uint256[] memory ids,
        uint256[] memory amounts,
        Erc1155TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc1155BatchAndTokenInfoMessage memory message = TransferErc1155BatchAndTokenInfoMessage(
            TransferErc1155BatchMessage(
                BaseMessage(MessageType.TRANSFER_ERC1155_BATCH_AND_TOKEN_INFO),
                token,
                receiver,
                ids,
                amounts
            ),
            tokenInfo
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC1155 token in batches with token info.
     * Returns structure `TransferErc1155BatchAndTokenInfoMessage`.
     */
    function decodeTransferErc1155BatchAndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc1155BatchAndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC1155_BATCH_AND_TOKEN_INFO,
            "Message type is not ERC1155BatchAndTokenInfo transfer"
        );
        return abi.decode(data, (TransferErc1155BatchAndTokenInfoMessage));
    }

    /**
     * @dev Encodes message for transferring user status on schain.
     * Returns encoded message.
     */
    function _encodeUserStatusMessage(address receiver, bool isActive) private pure returns (bytes memory) {
        UserStatusMessage memory message = UserStatusMessage(
            BaseMessage(MessageType.USER_STATUS),
            receiver,
            isActive
        );
        return abi.encode(message);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   DepositBox.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.6;

import "@skalenetwork/ima-interfaces/mainnet/IDepositBox.sol";

import "./Twin.sol";


/**
 * @title DepositBox
 * @dev Abstract contracts for DepositBoxes on mainnet.
 */
abstract contract DepositBox is IDepositBox, Twin {

    ILinker public linker;

    // schainHash => true if automatic deployment tokens on schain was enabled 
    mapping(bytes32 => bool) private _automaticDeploy;

    bytes32 public constant DEPOSIT_BOX_MANAGER_ROLE = keccak256("DEPOSIT_BOX_MANAGER_ROLE");

    /**
     * @dev Modifier for checking whether schain was not killed.
     */
    modifier whenNotKilled(bytes32 schainHash) {
        require(linker.isNotKilled(schainHash), "Schain is killed");
        _;
    }

    /**
     * @dev Modifier for checking whether schain was killed.
     */
    modifier whenKilled(bytes32 schainHash) {
        require(!linker.isNotKilled(schainHash), "Schain is not killed");
        _;
    }

    /**
     * @dev Modifier for checking whether schainName is not equal to `Mainnet` 
     * and address of receiver is not equal to null before transferring funds from mainnet to schain.
     */
    modifier rightTransaction(string memory schainName, address to) {
        require(
            keccak256(abi.encodePacked(schainName)) != keccak256(abi.encodePacked("Mainnet")),
            "SKALE chain name cannot be Mainnet"
        );
        require(to != address(0), "Receiver address cannot be null");
        _;
    }

    /**
     * @dev Modifier for checking whether schainHash is not equal to `Mainnet` 
     * and sender contract was added as contract processor on schain.
     */
    modifier checkReceiverChain(bytes32 schainHash, address sender) {
        require(
            schainHash != keccak256(abi.encodePacked("Mainnet")) &&
            sender == schainLinks[schainHash],
            "Receiver chain is incorrect"
        );
        _;
    }

    /**
     * @dev Allows Schain owner turn on whitelist of tokens.
     */
    function enableWhitelist(string memory schainName) external override onlySchainOwner(schainName) {
        _automaticDeploy[keccak256(abi.encodePacked(schainName))] = false;
    }

    /**
     * @dev Allows Schain owner turn off whitelist of tokens.
     */
    function disableWhitelist(string memory schainName) external override onlySchainOwner(schainName) {
        _automaticDeploy[keccak256(abi.encodePacked(schainName))] = true;
    }

    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        ILinker newLinker,
        IMessageProxyForMainnet messageProxyValue
    )
        public
        override
        virtual
        initializer
    {
        Twin.initialize(contractManagerOfSkaleManagerValue, messageProxyValue);
        _setupRole(LINKER_ROLE, address(newLinker));
        linker = newLinker;
    }

    /**
     * @dev Returns is whitelist enabled on schain.
     */
    function isWhitelisted(string memory schainName) public view override returns (bool) {
        return !_automaticDeploy[keccak256(abi.encodePacked(schainName))];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   IDepositBox.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "@skalenetwork/skale-manager-interfaces/IContractManager.sol";

import "../IGasReimbursable.sol";
import "../IMessageReceiver.sol";
import "./ILinker.sol";
import "./IMessageProxyForMainnet.sol";
import "./ITwin.sol";


interface IDepositBox is ITwin, IMessageReceiver, IGasReimbursable {
    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        ILinker newLinker,
        IMessageProxyForMainnet messageProxyValue
    ) external;
    function enableWhitelist(string memory schainName) external;
    function disableWhitelist(string memory schainName) external;
    function isWhitelisted(string memory schainName) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IContractManager.sol - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaeiv

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;
interface IContractManager {
    function setContractsAddress(string calldata contractsName, address newContractsAddress) external;
    function getContract(string calldata name) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   IGasReimbursable.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "./IMessageReceiver.sol";


interface IGasReimbursable is IMessageReceiver {
    function gasPayer(
        bytes32 schainHash,
        address sender,
        bytes calldata data
    )
        external
        returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   IMessageReceiver.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;


interface IMessageReceiver {
    function postMessage(
        bytes32 schainHash,
        address sender,
        bytes calldata data
    )
        external
        returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   ILinker.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "./ITwin.sol";


interface ILinker is ITwin {
    function registerMainnetContract(address newMainnetContract) external;
    function removeMainnetContract(address mainnetContract) external;
    function connectSchain(string calldata schainName, address[] calldata schainContracts) external;
    function allowInterchainConnections(string calldata schainName) external;
    function kill(string calldata schainName) external;
    function disconnectSchain(string calldata schainName) external;
    function interchainConnections(bytes32) external view returns (bool);
    function isNotKilled(bytes32 schainHash) external view returns (bool);
    function hasMainnetContract(address mainnetContract) external view returns (bool);
    function hasSchain(string calldata schainName) external view returns (bool connected);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   IMessageProxyForMainnet.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "../IMessageProxy.sol";
import "./ICommunityPool.sol";

interface IMessageProxyForMainnet is IMessageProxy {
    function setCommunityPool(ICommunityPool newCommunityPoolAddress) external;
    function setNewHeaderMessageGasCost(uint256 newHeaderMessageGasCost) external;
    function setNewMessageGasCost(uint256 newMessageGasCost) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   ITwin.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "./ISkaleManagerClient.sol";

interface ITwin is ISkaleManagerClient {
    function addSchainContract(string calldata schainName, address contractReceiver) external;
    function removeSchainContract(string calldata schainName) external;
    function hasSchainContract(string calldata schainName) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   ISkaleManagerClient.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "@skalenetwork/skale-manager-interfaces/IContractManager.sol";


interface ISkaleManagerClient {
    function initialize(IContractManager newContractManagerOfSkaleManager) external;
    function isSchainOwner(address sender, bytes32 schainHash) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   IMessageProxy.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;


interface IMessageProxy {

    /**
     * @dev Structure that describes message. Should contain sender of message,
     * destination contract on schain that will receiver message,
     * data that contains all needed info about token or ETH.
     */
    struct Message {
        address sender;
        address destinationContract;
        bytes data;
    }

    /**
     * @dev Structure that contains fields for bls signature.
     */
    struct Signature {
        uint256[2] blsSignature;
        uint256 hashA;
        uint256 hashB;
        uint256 counter;
    }

    function addConnectedChain(string calldata schainName) external;
    function postIncomingMessages(
        string calldata fromSchainName,
        uint256 startingCounter,
        Message[] calldata messages,
        Signature calldata sign
    ) external;
    function setNewGasLimit(uint256 newGasLimit) external;
    function registerExtraContractForAll(address extraContract) external;
    function removeExtraContractForAll(address extraContract) external;    
    function removeConnectedChain(string memory schainName) external;
    function postOutgoingMessage(
        bytes32 targetChainHash,
        address targetContract,
        bytes memory data
    ) external;
    function registerExtraContract(string memory chainName, address extraContract) external;
    function removeExtraContract(string memory schainName, address extraContract) external;
    function setVersion(string calldata newVersion) external;
    function isContractRegistered(
        bytes32 schainHash,
        address contractAddress
    ) external view returns (bool);
    function getContractRegisteredLength(bytes32 schainHash) external view returns (uint256);
    function getContractRegisteredRange(
        bytes32 schainHash,
        uint256 from,
        uint256 to
    )
        external
        view
        returns (address[] memory);
    function getOutgoingMessagesCounter(string calldata targetSchainName) external view returns (uint256);
    function getIncomingMessagesCounter(string calldata fromSchainName) external view returns (uint256);
    function isConnectedChain(string memory schainName) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   ICommunityPool.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "@skalenetwork/skale-manager-interfaces/IContractManager.sol";


import "./ILinker.sol";
import "./IMessageProxyForMainnet.sol";
import "./ITwin.sol";


interface ICommunityPool is ITwin {
    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        ILinker linker,
        IMessageProxyForMainnet messageProxyValue
    ) external;
    function refundGasByUser(bytes32 schainHash, address payable node, address user, uint gas) external returns (uint);
    function rechargeUserWallet(string calldata schainName, address user) external payable;
    function withdrawFunds(string calldata schainName, uint amount) external;
    function setMinTransactionGas(uint newMinTransactionGas) external;    
    function refundGasBySchainWallet(
        bytes32 schainHash,
        address payable node,
        uint gas
    ) external returns (bool);
    function getBalance(address user, string calldata schainName) external view returns (uint);
    function checkUserBalance(bytes32 schainHash, address receiver) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   Twin.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *   @author Dmytro Stebaiev
 *   @author Vadim Yavorsky
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.6;

import "@skalenetwork/ima-interfaces/mainnet/ITwin.sol";

import "./MessageProxyForMainnet.sol";
import "./SkaleManagerClient.sol";

/**
 * @title Twin
 * @dev Runs on Mainnet,
 * contains logic for connecting paired contracts on Mainnet and on Schain.
 */
abstract contract Twin is SkaleManagerClient, ITwin {

    IMessageProxyForMainnet public messageProxy;
    mapping(bytes32 => address) public schainLinks;
    bytes32 public constant LINKER_ROLE = keccak256("LINKER_ROLE");

    /**
     * @dev Modifier for checking whether caller is MessageProxy contract.
     */
    modifier onlyMessageProxy() {
        require(msg.sender == address(messageProxy), "Sender is not a MessageProxy");
        _;
    }

    /**
     * @dev Binds a contract on mainnet with their twin on schain.
     *
     * Requirements:
     *
     * - `msg.sender` must be schain owner or has required role.
     * - SKALE chain must not already be added.
     * - Address of contract on schain must be non-zero.
     */
    function addSchainContract(string calldata schainName, address contractReceiver) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(LINKER_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash), "Not authorized caller"
        );
        require(schainLinks[schainHash] == address(0), "SKALE chain is already set");
        require(contractReceiver != address(0), "Incorrect address of contract receiver on Schain");
        schainLinks[schainHash] = contractReceiver;
    }

    /**
     * @dev Removes connection with contract on schain.
     *
     * Requirements:
     *
     * - `msg.sender` must be schain owner or has required role.
     * - SKALE chain must already be set.
     */
    function removeSchainContract(string calldata schainName) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(LINKER_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash), "Not authorized caller"
        );
        require(schainLinks[schainHash] != address(0), "SKALE chain is not set");
        delete schainLinks[schainHash];
    }

    /**
     * @dev Returns true if mainnet contract and schain contract are connected together for transferring messages.
     */
    function hasSchainContract(string calldata schainName) external view override returns (bool) {
        return schainLinks[keccak256(abi.encodePacked(schainName))] != address(0);
    }
    
    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        IMessageProxyForMainnet newMessageProxy
    )
        public
        virtual
        initializer
    {
        SkaleManagerClient.initialize(contractManagerOfSkaleManagerValue);
        messageProxy = newMessageProxy;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   MessageProxyForMainnet.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2019-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@skalenetwork/skale-manager-interfaces/IWallets.sol";
import "@skalenetwork/skale-manager-interfaces/ISchains.sol";
import "@skalenetwork/ima-interfaces/mainnet/IMessageProxyForMainnet.sol";
import "@skalenetwork/ima-interfaces/mainnet/ICommunityPool.sol";

import "../MessageProxy.sol";
import "./SkaleManagerClient.sol";
import "./CommunityPool.sol";

interface IMessageProxyForMainnetInitializeFunction is IMessageProxyForMainnet {
    function initializeAllRegisteredContracts(
        bytes32 schainHash,
        address[] calldata contracts
    ) external;
}


/**
 * @title Message Proxy for Mainnet
 * @dev Runs on Mainnet, contains functions to manage the incoming messages from
 * `targetSchainName` and outgoing messages to `fromSchainName`. Every SKALE chain with 
 * IMA is therefore connected to MessageProxyForMainnet.
 *
 * Messages from SKALE chains are signed using BLS threshold signatures from the
 * nodes in the chain. Since Ethereum Mainnet has no BLS public key, mainnet
 * messages do not need to be signed.
 */
contract MessageProxyForMainnet is SkaleManagerClient, MessageProxy, IMessageProxyForMainnetInitializeFunction {

    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * 16 Agents
     * Synchronize time with time.nist.gov
     * Every agent checks if it is their time slot
     * Time slots are in increments of 10 seconds
     * At the start of their slot each agent:
     * For each connected schain:
     * Read incoming counter on the dst chain
     * Read outgoing counter on the src chain
     * Calculate the difference outgoing - incoming
     * Call postIncomingMessages function passing (un)signed message array
     * ID of this schain, Chain 0 represents ETH mainnet,
    */

    ICommunityPool public communityPool;

    uint256 public headerMessageGasCost;
    uint256 public messageGasCost;
    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _registryContracts;
    string public version;

    /**
     * @dev Emitted when gas cost for message header was changed.
     */
    event GasCostMessageHeaderWasChanged(
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Emitted when gas cost for message was changed.
     */
    event GasCostMessageWasChanged(
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Allows DEFAULT_ADMIN_ROLE to initialize registered contracts
     * Notice - this function will be executed only once during upgrade
     * 
     * Requirements:
     * 
     * `msg.sender` should have DEFAULT_ADMIN_ROLE
     */
    function initializeAllRegisteredContracts(
        bytes32 schainHash,
        address[] calldata contracts
    ) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Sender is not authorized");
        for (uint256 i = 0; i < contracts.length; i++) {
            if (
                deprecatedRegistryContracts[schainHash][contracts[i]] &&
                !_registryContracts[schainHash].contains(contracts[i])
            ) {
                _registryContracts[schainHash].add(contracts[i]);
                delete deprecatedRegistryContracts[schainHash][contracts[i]];
            }
        }
    }

    /**
     * @dev Allows `msg.sender` to connect schain with MessageProxyOnMainnet for transferring messages.
     * 
     * Requirements:
     * 
     * - Schain name must not be `Mainnet`.
     */
    function addConnectedChain(string calldata schainName) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(schainHash != MAINNET_HASH, "SKALE chain name is incorrect");
        _addConnectedChain(schainHash);
    }

    /**
     * @dev Allows owner of the contract to set CommunityPool address for gas reimbursement.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as DEFAULT_ADMIN_ROLE.
     * - Address of CommunityPool contract must not be null.
     */
    function setCommunityPool(ICommunityPool newCommunityPoolAddress) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized caller");
        require(address(newCommunityPoolAddress) != address(0), "CommunityPool address has to be set");
        communityPool = newCommunityPoolAddress;
    }

    /**
     * @dev Allows `msg.sender` to register extra contract for being able to transfer messages from custom contracts.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE.
     * - Schain name must not be `Mainnet`.
     */
    function registerExtraContract(string memory schainName, address extraContract) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to register extra contract"
        );
        require(schainHash != MAINNET_HASH, "Schain hash can not be equal Mainnet");        
        _registerExtraContract(schainHash, extraContract);
    }

    /**
     * @dev Allows `msg.sender` to remove extra contract,
     * thus `extraContract` will no longer be available to transfer messages from mainnet to schain.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE.
     * - Schain name must not be `Mainnet`.
     */
    function removeExtraContract(string memory schainName, address extraContract) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to register extra contract"
        );
        require(schainHash != MAINNET_HASH, "Schain hash can not be equal Mainnet");
        _removeExtraContract(schainHash, extraContract);
    }

    /**
     * @dev Posts incoming message from `fromSchainName`. 
     * 
     * Requirements:
     * 
     * - `msg.sender` must be authorized caller.
     * - `fromSchainName` must be initialized.
     * - `startingCounter` must be equal to the chain's incoming message counter.
     * - If destination chain is Mainnet, message signature must be valid.
     */
    function postIncomingMessages(
        string calldata fromSchainName,
        uint256 startingCounter,
        Message[] calldata messages,
        Signature calldata sign
    )
        external
        override(IMessageProxy, MessageProxy)
    {
        uint256 gasTotal = gasleft();
        bytes32 fromSchainHash = keccak256(abi.encodePacked(fromSchainName));
        require(_checkSchainBalance(fromSchainHash), "Schain wallet has not enough funds");
        require(connectedChains[fromSchainHash].inited, "Chain is not initialized");
        require(messages.length <= MESSAGES_LENGTH, "Too many messages");
        require(
            startingCounter == connectedChains[fromSchainHash].incomingMessageCounter,
            "Starting counter is not equal to incoming message counter");

        require(_verifyMessages(fromSchainName, _hashedArray(messages), sign), "Signature is not verified");
        uint additionalGasPerMessage = 
            (gasTotal - gasleft() + headerMessageGasCost + messages.length * messageGasCost) / messages.length;
        uint notReimbursedGas = 0;
        for (uint256 i = 0; i < messages.length; i++) {
            gasTotal = gasleft();
            if (isContractRegistered(bytes32(0), messages[i].destinationContract)) {
                address receiver = _getGasPayer(fromSchainHash, messages[i], startingCounter + i);
                _callReceiverContract(fromSchainHash, messages[i], startingCounter + i);
                notReimbursedGas += communityPool.refundGasByUser(
                    fromSchainHash,
                    payable(msg.sender),
                    receiver,
                    gasTotal - gasleft() + additionalGasPerMessage
                );
            } else {
                _callReceiverContract(fromSchainHash, messages[i], startingCounter + i);
                notReimbursedGas += gasTotal - gasleft() + additionalGasPerMessage;
            }
        }
        connectedChains[fromSchainHash].incomingMessageCounter += messages.length;
        communityPool.refundGasBySchainWallet(fromSchainHash, payable(msg.sender), notReimbursedGas);
    }

    /**
     * @dev Sets headerMessageGasCost to a new value.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as CONSTANT_SETTER_ROLE.
     */
    function setNewHeaderMessageGasCost(uint256 newHeaderMessageGasCost) external override onlyConstantSetter {
        emit GasCostMessageHeaderWasChanged(headerMessageGasCost, newHeaderMessageGasCost);
        headerMessageGasCost = newHeaderMessageGasCost;
    }

    /**
     * @dev Sets messageGasCost to a new value.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as CONSTANT_SETTER_ROLE.
     */
    function setNewMessageGasCost(uint256 newMessageGasCost) external override onlyConstantSetter {
        emit GasCostMessageWasChanged(messageGasCost, newMessageGasCost);
        messageGasCost = newMessageGasCost;
    }

    /**
     * @dev Sets new version of contracts on mainnet
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted DEFAULT_ADMIN_ROLE.
     */
    function setVersion(string calldata newVersion) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DEFAULT_ADMIN_ROLE is required");
        emit VersionUpdated(version, newVersion);
        version = newVersion;
    }

    /**
     * @dev Creates a new MessageProxyForMainnet contract.
     */
    function initialize(IContractManager contractManagerOfSkaleManagerValue) public virtual override initializer {
        SkaleManagerClient.initialize(contractManagerOfSkaleManagerValue);
        MessageProxy.initializeMessageProxy(1e6);
        headerMessageGasCost = 70000;
        messageGasCost = 9000;
    }

    /**
     * @dev Checks whether chain is currently connected.
     * 
     * Note: Mainnet chain does not have a public key, and is implicitly 
     * connected to MessageProxy.
     * 
     * Requirements:
     * 
     * - `schainName` must not be Mainnet.
     */
    function isConnectedChain(
        string memory schainName
    )
        public
        view
        override(IMessageProxy, MessageProxy)
        returns (bool)
    {
        require(keccak256(abi.encodePacked(schainName)) != MAINNET_HASH, "Schain id can not be equal Mainnet");
        return super.isConnectedChain(schainName);
    }

    /**
     * @dev Converts calldata structure to memory structure and checks
     * whether message BLS signature is valid.
     */
    function _verifyMessages(
        string calldata fromSchainName,
        bytes32 hashedMessages,
        MessageProxyForMainnet.Signature calldata sign
    )
        internal
        view
        returns (bool)
    {
        return ISchains(
            contractManagerOfSkaleManager.getContract("Schains")
        ).verifySchainSignature(
            sign.blsSignature[0],
            sign.blsSignature[1],
            hashedMessages,
            sign.counter,
            sign.hashA,
            sign.hashB,
            fromSchainName
        );
    }

    function _checkSchainBalance(bytes32 schainHash) internal view returns (bool) {
        return IWallets(
            contractManagerOfSkaleManager.getContract("Wallets")
        ).getSchainBalance(schainHash) >= (MESSAGES_LENGTH + 1) * gasLimit * tx.gasprice;
    }

    function _getRegistryContracts()
        internal
        view
        override
        returns (mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) storage)
    {
        return _registryContracts;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   SkaleManagerClient.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@skalenetwork/skale-manager-interfaces/IContractManager.sol";
import "@skalenetwork/skale-manager-interfaces/ISchainsInternal.sol";
import "@skalenetwork/ima-interfaces/mainnet/ISkaleManagerClient.sol";


/**
 * @title SkaleManagerClient - contract that knows ContractManager
 * and makes calls to SkaleManager contracts.
 */
contract SkaleManagerClient is Initializable, AccessControlEnumerableUpgradeable, ISkaleManagerClient {

    IContractManager public contractManagerOfSkaleManager;

    /**
     * @dev Modifier for checking whether caller is owner of SKALE chain.
     */
    modifier onlySchainOwner(string memory schainName) {
        require(
            isSchainOwner(msg.sender, keccak256(abi.encodePacked(schainName))),
            "Sender is not an Schain owner"
        );
        _;
    }

    /**
     * @dev initialize - sets current address of ContractManager of SkaleManager.
     * @param newContractManagerOfSkaleManager - current address of ContractManager of SkaleManager.
     */
    function initialize(
        IContractManager newContractManagerOfSkaleManager
    )
        public
        override
        virtual
        initializer
    {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        contractManagerOfSkaleManager = newContractManagerOfSkaleManager;
    }

    /**
     * @dev Checks whether sender is owner of SKALE chain
     */
    function isSchainOwner(address sender, bytes32 schainHash) public view override returns (bool) {
        address skaleChainsInternal = contractManagerOfSkaleManager.getContract("SchainsInternal");
        return ISchainsInternal(skaleChainsInternal).isOwnerAddress(sender, schainHash);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IWallets - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaeiv

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IWallets {
    function refundGasBySchain(bytes32 schainId, address payable spender, uint spentGas, bool isDebt) external;
    function rechargeSchainWallet(bytes32 schainId) external payable;
    function getSchainBalance(bytes32 schainHash) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    ISchains.sol - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaeiv

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface ISchains {
    function verifySchainSignature(
        uint256 signA,
        uint256 signB,
        bytes32 hash,
        uint256 counter,
        uint256 hashA,
        uint256 hashB,
        string calldata schainName
    )
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   MessageProxy.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@skalenetwork/ima-interfaces/IGasReimbursable.sol";
import "@skalenetwork/ima-interfaces/IMessageProxy.sol";
import "@skalenetwork/ima-interfaces/IMessageReceiver.sol";


/**
 * @title MessageProxy
 * @dev Abstract contract for MessageProxyForMainnet and MessageProxyForSchain.
 */
abstract contract MessageProxy is AccessControlEnumerableUpgradeable, IMessageProxy {
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @dev Structure that stores counters for outgoing and incoming messages.
     */
    struct ConnectedChainInfo {
        // message counters start with 0
        uint256 incomingMessageCounter;
        uint256 outgoingMessageCounter;
        bool inited;
    }

    bytes32 public constant MAINNET_HASH = keccak256(abi.encodePacked("Mainnet"));
    bytes32 public constant CHAIN_CONNECTOR_ROLE = keccak256("CHAIN_CONNECTOR_ROLE");
    bytes32 public constant EXTRA_CONTRACT_REGISTRAR_ROLE = keccak256("EXTRA_CONTRACT_REGISTRAR_ROLE");
    bytes32 public constant CONSTANT_SETTER_ROLE = keccak256("CONSTANT_SETTER_ROLE");
    uint256 public constant MESSAGES_LENGTH = 10;

    //   schainHash => ConnectedChainInfo
    mapping(bytes32 => ConnectedChainInfo) public connectedChains;
    //   schainHash => contract address => allowed
    // solhint-disable-next-line private-vars-leading-underscore
    mapping(bytes32 => mapping(address => bool)) internal deprecatedRegistryContracts;

    uint256 public gasLimit;

    /**
     * @dev Emitted for every outgoing message to schain.
     */
    event OutgoingMessage(
        bytes32 indexed dstChainHash,
        uint256 indexed msgCounter,
        address indexed srcContract,
        address dstContract,
        bytes data
    );

    /**
     * @dev Emitted when function `postMessage` returns revert.
     *  Used to prevent stuck loop inside function `postIncomingMessages`.
     */
    event PostMessageError(
        uint256 indexed msgCounter,
        bytes message
    );

    /**
     * @dev Emitted when gas limit per one call of `postMessage` was changed.
     */
    event GasLimitWasChanged(
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Emitted when the version was updated
     */
    event VersionUpdated(string oldVersion, string newVersion);

    /**
     * @dev Emitted when extra contract was added.
     */
    event ExtraContractRegistered(
        bytes32 indexed chainHash,
        address contractAddress
    );

    /**
     * @dev Emitted when extra contract was removed.
     */
    event ExtraContractRemoved(
        bytes32 indexed chainHash,
        address contractAddress
    );

    /**
     * @dev Modifier to make a function callable only if caller is granted with {CHAIN_CONNECTOR_ROLE}.
     */
    modifier onlyChainConnector() {
        require(hasRole(CHAIN_CONNECTOR_ROLE, msg.sender), "CHAIN_CONNECTOR_ROLE is required");
        _;
    }

    /**
     * @dev Modifier to make a function callable only if caller is granted with {EXTRA_CONTRACT_REGISTRAR_ROLE}.
     */
    modifier onlyExtraContractRegistrar() {
        require(hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender), "EXTRA_CONTRACT_REGISTRAR_ROLE is required");
        _;
    }

    /**
     * @dev Modifier to make a function callable only if caller is granted with {CONSTANT_SETTER_ROLE}.
     */
    modifier onlyConstantSetter() {
        require(hasRole(CONSTANT_SETTER_ROLE, msg.sender), "Not enough permissions to set constant");
        _;
    }    

    /**
     * @dev Sets gasLimit to a new value.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted CONSTANT_SETTER_ROLE.
     */
    function setNewGasLimit(uint256 newGasLimit) external override onlyConstantSetter {
        emit GasLimitWasChanged(gasLimit, newGasLimit);
        gasLimit = newGasLimit;
    }

    /**
     * @dev Virtual function for `postIncomingMessages`.
     */
    function postIncomingMessages(
        string calldata fromSchainName,
        uint256 startingCounter,
        Message[] calldata messages,
        Signature calldata sign
    )
        external
        virtual
        override;

    /**
     * @dev Allows `msg.sender` to register extra contract for all schains
     * for being able to transfer messages from custom contracts.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE.
     * - Passed address should be contract.
     * - Extra contract must not be registered.
     */
    function registerExtraContractForAll(address extraContract) external override onlyExtraContractRegistrar {
        require(extraContract.isContract(), "Given address is not a contract");
        require(!_getRegistryContracts()[bytes32(0)].contains(extraContract), "Extra contract is already registered");
        _getRegistryContracts()[bytes32(0)].add(extraContract);
        emit ExtraContractRegistered(bytes32(0), extraContract);
    }

    /**
     * @dev Allows `msg.sender` to remove extra contract for all schains.
     * Extra contract will no longer be able to send messages through MessageProxy.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE.
     */
    function removeExtraContractForAll(address extraContract) external override onlyExtraContractRegistrar {
        require(_getRegistryContracts()[bytes32(0)].contains(extraContract), "Extra contract is not registered");
        _getRegistryContracts()[bytes32(0)].remove(extraContract);
        emit ExtraContractRemoved(bytes32(0), extraContract);
    }

    /**
     * @dev Should return length of contract registered by schainHash.
     */
    function getContractRegisteredLength(bytes32 schainHash) external view override returns (uint256) {
        return _getRegistryContracts()[schainHash].length();
    }

    /**
     * @dev Should return a range of contracts registered by schainHash.
     * 
     * Requirements:
     * range should be less or equal 10 contracts
     */
    function getContractRegisteredRange(
        bytes32 schainHash,
        uint256 from,
        uint256 to
    )
        external
        view
        override
        returns (address[] memory contractsInRange)
    {
        require(
            from < to && to - from <= 10 && to <= _getRegistryContracts()[schainHash].length(),
            "Range is incorrect"
        );
        contractsInRange = new address[](to - from);
        for (uint256 i = from; i < to; i++) {
            contractsInRange[i - from] = _getRegistryContracts()[schainHash].at(i);
        }
    }

    /**
     * @dev Returns number of outgoing messages.
     * 
     * Requirements:
     * 
     * - Target schain  must be initialized.
     */
    function getOutgoingMessagesCounter(string calldata targetSchainName)
        external
        view
        override
        returns (uint256)
    {
        bytes32 dstChainHash = keccak256(abi.encodePacked(targetSchainName));
        require(connectedChains[dstChainHash].inited, "Destination chain is not initialized");
        return connectedChains[dstChainHash].outgoingMessageCounter;
    }

    /**
     * @dev Returns number of incoming messages.
     * 
     * Requirements:
     * 
     * - Source schain must be initialized.
     */
    function getIncomingMessagesCounter(string calldata fromSchainName)
        external
        view
        override
        returns (uint256)
    {
        bytes32 srcChainHash = keccak256(abi.encodePacked(fromSchainName));
        require(connectedChains[srcChainHash].inited, "Source chain is not initialized");
        return connectedChains[srcChainHash].incomingMessageCounter;
    }

    function initializeMessageProxy(uint newGasLimit) public initializer {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CHAIN_CONNECTOR_ROLE, msg.sender);
        _setupRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender);
        _setupRole(CONSTANT_SETTER_ROLE, msg.sender);
        gasLimit = newGasLimit;
    }

    /**
     * @dev Posts message from this contract to `targetChainHash` MessageProxy contract.
     * This is called by a smart contract to make a cross-chain call.
     * 
     * Emits an {OutgoingMessage} event.
     *
     * Requirements:
     * 
     * - Target chain must be initialized.
     * - Target chain must be registered as external contract.
     */
    function postOutgoingMessage(
        bytes32 targetChainHash,
        address targetContract,
        bytes memory data
    )
        public
        override
        virtual
    {
        require(connectedChains[targetChainHash].inited, "Destination chain is not initialized");
        require(
            isContractRegistered(bytes32(0), msg.sender) || isContractRegistered(targetChainHash, msg.sender),
            "Sender contract is not registered"
        );        
        
        emit OutgoingMessage(
            targetChainHash,
            connectedChains[targetChainHash].outgoingMessageCounter,
            msg.sender,
            targetContract,
            data
        );

        connectedChains[targetChainHash].outgoingMessageCounter += 1;
    }

    /**
     * @dev Allows LockAndData to remove connected chain from this contract.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be LockAndData contract.
     * - `schainName` must be initialized.
     */
    function removeConnectedChain(string memory schainName) public virtual override onlyChainConnector {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(connectedChains[schainHash].inited, "Chain is not initialized");
        delete connectedChains[schainHash];
    }    

    // Registration state detection
    function isConnectedChain(
        string memory schainName
    )
        public
        view
        virtual
        override
        returns (bool)
    {
        return connectedChains[keccak256(abi.encodePacked(schainName))].inited;
    }

    /**
     * @dev Checks whether contract is currently registered as extra contract.
     */
    function isContractRegistered(
        bytes32 schainHash,
        address contractAddress
    )
        public
        view
        override
        returns (bool)
    {
        return _getRegistryContracts()[schainHash].contains(contractAddress);
    }

    /**
     * @dev Allows MessageProxy to register extra contract for being able to transfer messages from custom contracts.
     * 
     * Requirements:
     * 
     * - Extra contract address must be contract.
     * - Extra contract must not be registered.
     * - Extra contract must not be registered for all chains.
     */
    function _registerExtraContract(
        bytes32 chainHash,
        address extraContract
    )
        internal
    {      
        require(extraContract.isContract(), "Given address is not a contract");
        require(!_getRegistryContracts()[chainHash].contains(extraContract), "Extra contract is already registered");
        require(
            !_getRegistryContracts()[bytes32(0)].contains(extraContract),
            "Extra contract is already registered for all chains"
        );
        
        _getRegistryContracts()[chainHash].add(extraContract);
        emit ExtraContractRegistered(chainHash, extraContract);
    }

    /**
     * @dev Allows MessageProxy to remove extra contract,
     * thus `extraContract` will no longer be available to transfer messages from mainnet to schain.
     * 
     * Requirements:
     * 
     * - Extra contract must be registered.
     */
    function _removeExtraContract(
        bytes32 chainHash,
        address extraContract
    )
        internal
    {
        require(_getRegistryContracts()[chainHash].contains(extraContract), "Extra contract is not registered");
        _getRegistryContracts()[chainHash].remove(extraContract);
        emit ExtraContractRemoved(chainHash, extraContract);
    }

    /**
     * @dev Allows MessageProxy to connect schain with MessageProxyOnMainnet for transferring messages.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted CHAIN_CONNECTOR_ROLE.
     * - SKALE chain must not be connected.
     */
    function _addConnectedChain(bytes32 schainHash) internal onlyChainConnector {
        require(!connectedChains[schainHash].inited,"Chain is already connected");
        connectedChains[schainHash] = ConnectedChainInfo({
            incomingMessageCounter: 0,
            outgoingMessageCounter: 0,
            inited: true
        });
    }

    /**
     * @dev Allows MessageProxy to send messages from schain to mainnet.
     * Destination contract must implement `postMessage` method.
     */
    function _callReceiverContract(
        bytes32 schainHash,
        Message calldata message,
        uint counter
    )
        internal
        returns (address)
    {
        if (!message.destinationContract.isContract()) {
            emit PostMessageError(
                counter,
                "Destination contract is not a contract"
            );
            return address(0);
        }
        try IMessageReceiver(message.destinationContract).postMessage{gas: gasLimit}(
            schainHash,
            message.sender,
            message.data
        ) returns (address receiver) {
            return receiver;
        } catch Error(string memory reason) {
            emit PostMessageError(
                counter,
                bytes(reason)
            );
            return address(0);
        } catch (bytes memory revertData) {
            emit PostMessageError(
                counter,
                revertData
            );
            return address(0);
        }
    }

    function _getGasPayer(
        bytes32 schainHash,
        Message calldata message,
        uint counter
    )
        internal
        returns (address)
    {
        try IGasReimbursable(message.destinationContract).gasPayer{gas: gasLimit}(
            schainHash,
            message.sender,
            message.data
        ) returns (address receiver) {
            return receiver;
        } catch Error(string memory reason) {
            emit PostMessageError(
                counter,
                bytes(reason)
            );
            return address(0);
        } catch (bytes memory revertData) {
            emit PostMessageError(
                counter,
                revertData
            );
            return address(0);
        }
    }

    function _getRegistryContracts()
        internal
        view
        virtual
        returns (mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) storage);

    /**
     * @dev Returns hash of message array.
     */
    function _hashedArray(Message[] calldata messages) internal pure returns (bytes32) {
        bytes memory data;
        for (uint256 i = 0; i < messages.length; i++) {
            data = abi.encodePacked(
                data,
                bytes32(bytes20(messages[i].sender)),
                bytes32(bytes20(messages[i].destinationContract)),
                messages[i].data
            );
        }
        return keccak256(data);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    CommunityPool.sol - SKALE Manager
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaiev
    @author Artem Payvin
    @author Vadim Yavorsky

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.6;

import "@skalenetwork/ima-interfaces/mainnet/ICommunityPool.sol";
import "@skalenetwork/skale-manager-interfaces/IWallets.sol";

import "../Messages.sol";
import "./Twin.sol";


/**
 * @title CommunityPool
 * @dev Contract contains logic to perform automatic self-recharging ETH for nodes.
 */
contract CommunityPool is Twin, ICommunityPool {

    using AddressUpgradeable for address payable;

    bytes32 public constant CONSTANT_SETTER_ROLE = keccak256("CONSTANT_SETTER_ROLE");

    // address of user => schainHash => balance of gas wallet in ETH
    mapping(address => mapping(bytes32 => uint)) private _userWallets;

    // address of user => schainHash => true if unlocked for transferring
    mapping(address => mapping(bytes32 => bool)) public activeUsers;

    uint public minTransactionGas;    

    /**
     * @dev Emitted when minimal value in gas for transactions from schain to mainnet was changed 
     */
    event MinTransactionGasWasChanged(
        uint oldValue,
        uint newValue
    );

    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        ILinker linker,
        IMessageProxyForMainnet messageProxyValue
    )
        external
        override
        initializer
    {
        Twin.initialize(contractManagerOfSkaleManagerValue, messageProxyValue);
        _setupRole(LINKER_ROLE, address(linker));
        minTransactionGas = 1e6;
    }

    /**
     * @dev Allows MessageProxyForMainnet to reimburse gas for transactions 
     * that transfer funds from schain to mainnet.
     * 
     * Requirements:
     * 
     * - User that receives funds should have enough funds in their gas wallet.
     * - Address that should be reimbursed for executing transaction must not be null.
     */
    function refundGasByUser(
        bytes32 schainHash,
        address payable node,
        address user,
        uint gas
    )
        external
        override
        onlyMessageProxy
        returns (uint)
    {
        require(node != address(0), "Node address must be set");
        if (!activeUsers[user][schainHash]) {
            return gas;
        }
        uint amount = tx.gasprice * gas;
        if (amount > _userWallets[user][schainHash]) {
            amount = _userWallets[user][schainHash];
        }
        _userWallets[user][schainHash] = _userWallets[user][schainHash] - amount;
        if (!_balanceIsSufficient(schainHash, user, 0)) {
            activeUsers[user][schainHash] = false;
            messageProxy.postOutgoingMessage(
                schainHash,
                schainLinks[schainHash],
                Messages.encodeLockUserMessage(user)
            );
        }
        node.sendValue(amount);
        return (tx.gasprice * gas - amount) / tx.gasprice;
    }

    function refundGasBySchainWallet(
        bytes32 schainHash,
        address payable node,
        uint gas
    )
        external
        override
        onlyMessageProxy
        returns (bool)
    {
        if (gas > 0) {
            IWallets(contractManagerOfSkaleManager.getContract("Wallets")).refundGasBySchain(
                schainHash,
                node,
                gas,
                false
            );
        }
        return true;
    }

    /**
     * @dev Allows `msg.sender` to recharge their wallet for further gas reimbursement.
     * 
     * Requirements:
     * 
     * - 'msg.sender` should recharge their gas wallet for amount that enough to reimburse any 
     *   transaction from schain to mainnet.
     */
    function rechargeUserWallet(string calldata schainName, address user) external payable override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            _balanceIsSufficient(schainHash, user, msg.value),
            "Not enough ETH for transaction"
        );
        _userWallets[user][schainHash] = _userWallets[user][schainHash] + msg.value;
        if (!activeUsers[user][schainHash]) {
            activeUsers[user][schainHash] = true;
            messageProxy.postOutgoingMessage(
                schainHash,
                schainLinks[schainHash],
                Messages.encodeActivateUserMessage(user)
            );
        }
    }

    /**
     * @dev Allows `msg.sender` to withdraw funds from their gas wallet.
     * If `msg.sender` withdraws too much funds,
     * then he will no longer be able to transfer their tokens on ETH from schain to mainnet.
     * 
     * Requirements:
     * 
     * - 'msg.sender` must have sufficient amount of ETH on their gas wallet.
     */
    function withdrawFunds(string calldata schainName, uint amount) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(amount <= _userWallets[msg.sender][schainHash], "Balance is too low");
        _userWallets[msg.sender][schainHash] = _userWallets[msg.sender][schainHash] - amount;
        if (
            !_balanceIsSufficient(schainHash, msg.sender, 0) &&
            activeUsers[msg.sender][schainHash]
        ) {
            activeUsers[msg.sender][schainHash] = false;
            messageProxy.postOutgoingMessage(
                schainHash,
                schainLinks[schainHash],
                Messages.encodeLockUserMessage(msg.sender)
            );
        }
        payable(msg.sender).sendValue(amount);
    }

    /**
     * @dev Allows `msg.sender` set the amount of gas that should be 
     * enough for reimbursing any transaction from schain to mainnet.
     * 
     * Requirements:
     * 
     * - 'msg.sender` must have sufficient amount of ETH on their gas wallet.
     */
    function setMinTransactionGas(uint newMinTransactionGas) external override {
        require(hasRole(CONSTANT_SETTER_ROLE, msg.sender), "CONSTANT_SETTER_ROLE is required");
        emit MinTransactionGasWasChanged(minTransactionGas, newMinTransactionGas);
        minTransactionGas = newMinTransactionGas;
    }

    /**
     * @dev Returns the amount of ETH on gas wallet for particular user.
     */
    function getBalance(address user, string calldata schainName) external view override returns (uint) {
        return _userWallets[user][keccak256(abi.encodePacked(schainName))];
    }

    function checkUserBalance(bytes32 schainHash, address receiver) external view override returns (bool) {
        return activeUsers[receiver][schainHash] && _balanceIsSufficient(schainHash, receiver, 0);
    }

    function _balanceIsSufficient(bytes32 schainHash, address receiver, uint256 delta) private view returns (bool) {
        return delta + _userWallets[receiver][schainHash] >= minTransactionGas * tx.gasprice;
    } 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    ISchainsInternal - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaeiv

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface ISchainsInternal {
    function isNodeAddressesInGroup(bytes32 schainId, address sender) external view returns (bool);
    function isOwnerAddress(address from, bytes32 schainId) external view returns (bool);
}