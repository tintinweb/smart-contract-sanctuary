// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VanityNameController {
    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;

    /** Data Structures and values **/
    uint256 internal constant FEE_AMOUNT_IN_WEI = 10000000000000000;
    uint256 internal constant SUBSCRIPTION_PERIOD = 5 minutes;

    struct VanityName {
        uint256 id;
        string name;
        uint256 expiresAt;
    }

    VanityName[] vanityNameStorage;

    // Mappings
    mapping(string => address) owners;
    mapping(string => uint256) vanityNameIds;
    mapping(address => uint256) totalStakedBalance;
    mapping(bytes32 => uint) public commitments;

    Counters.Counter counter;

    /** Events **/
    event NewBuy(string vanityName, address newOwner, uint256 expiresAt, uint256 fee);
    event FeesWithdrawn(string vanityName, address user, uint256 amount);
    event VanityNameRenewed(string vanityName, address owner, uint256 expiresAt);

    /** Internal functions and modifiers **/
    function _exists(string memory vanityName) internal view returns (bool) {
        return owners[vanityName] != address(0);
    }

    function _expired(string memory vanityName) internal view returns (bool) {
        if (!_exists(vanityName)) {
            return true;
        }
        uint256 id = vanityNameIds[vanityName];

        return vanityNameStorage[id].expiresAt < block.timestamp;
    }

    /** Smart contract functions **/
    function makeCommitment(string memory name, address owner, bytes32 secret) public pure returns (bytes32) {
        //create new reservation
        bytes32 label = keccak256(bytes(name));
        return keccak256(abi.encodePacked(label, owner, secret));
    }

    function commit(bytes32 commitment) public {
        require(commitments[commitment] < block.timestamp);
        commitments[commitment] = block.timestamp;
    }

    function consumeCommitment(string memory name, bytes32 commitment) internal {
        // Require a valid commitment
        require(commitments[commitment] <= block.timestamp);

        require(checkAvailability(name));

        delete (commitments[commitment]);
    }

    function buy(string memory vanityName, address user, bytes32 secret) public payable {
        require(_expired(vanityName), "VanityNameController: vanity name already in use.");

        bytes32 commitment = makeCommitment(vanityName, user, secret);
        consumeCommitment(vanityName, commitment);

        uint256 fee = getFee(vanityName);
        require(msg.value >= fee, "VanityNameController: ETH sent are not enough to buy the vanity name.");

        //Save new vanity name
        uint256 newEndTime = block.timestamp + SUBSCRIPTION_PERIOD;

        //If name was already registered previously then it already has an id, otherwise generate it
        if (!_exists(vanityName)) {
            uint256 id = counter.current();
            counter.increment();

            VanityName memory vanityNameStruct = VanityName(id, vanityName, newEndTime);
            vanityNameStorage.push(vanityNameStruct);

            vanityNameIds[vanityName] = id;
        }

        //Set owner
        owners[vanityName] = msg.sender;

        //Lock fee
        totalStakedBalance[msg.sender] = totalStakedBalance[msg.sender] + msg.value;

        emit NewBuy(vanityName, msg.sender, newEndTime, fee);
    }

    function withdrawFee(string memory vanityName) public payable {
        uint256 fee = getFee(vanityName);

        //require
        require(_exists(vanityName), "VanityNameController: you cannot withdraw fees for a non existing vanity name");
        require(ownerOf(vanityName) == msg.sender, "VanityNameController: you must be the owner of the vanity name");
        require(_expired(vanityName), "VanityNameController: subscription period must expire in order to withdraw fee");
        require(totalStakedBalance[msg.sender] >= fee, "VanityNameController: Balance unavailable to withdraw fee");

        //remove as owner of vanityName
        owners[vanityName] = address(0);

        //send staked amount for that vanityName
        totalStakedBalance[msg.sender] = totalStakedBalance[msg.sender] - fee;
        payable(msg.sender).transfer(fee);

        emit FeesWithdrawn(vanityName, msg.sender, fee);
    }

    function renew(string memory nameToRenew) public payable {
        require(ownerOf(nameToRenew) == msg.sender, "VanityNameController: you must be the owner of the vanity name");

        uint256 newEndTime = block.timestamp + SUBSCRIPTION_PERIOD;
        uint256 id = vanityNameIds[nameToRenew];
        VanityName storage vanityName = vanityNameStorage[id];
        vanityName.expiresAt = newEndTime;

        emit VanityNameRenewed(nameToRenew, msg.sender, vanityNameStorage[id].expiresAt);
    }

    /** Getters **/
    function ownerOf(string memory vanityName) public view returns (address) {
        return owners[vanityName];
    }

    function checkAvailability(string memory vanityName) public view returns (bool) {
        address owner = owners[vanityName];
        if (owner != address(0) && !_expired(vanityName)) {
            return false;
        } else {
            return true;
        }
    }

    function index() public view returns (VanityName[] memory) {
        return vanityNameStorage;
    }

    function get(string memory vanityName) public view returns (VanityName memory) {
        uint256 id = getId(vanityName);
        return vanityNameStorage[id];
    }

    function getFee(string memory vanityName) public pure returns (uint256) {
        return bytes(vanityName).length * FEE_AMOUNT_IN_WEI;
    }

    function getId(string memory vanityName) public view returns (uint256) {
        return vanityNameIds[vanityName];
    }

    function getVanityNameById(uint256 id) public view returns (VanityName memory) {
        return vanityNameStorage[id];
    }

    function getTotalStakedAmount(address user) public view returns (uint256) {
        return totalStakedBalance[user];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
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