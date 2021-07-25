// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

interface IOpenOracleFramework {
    /**
    * @dev getHistoricalFeeds function lets the caller receive historical values for a given timestamp
    *
    * @param feedIDs the array of feedIds
    * @param timestamps the array of timestamps
    */
    function getHistoricalFeeds(uint256[] memory feedIDs, uint256[] memory timestamps) external view returns (uint256[] memory);

    /**
    * @dev getFeeds function lets anyone call the oracle to receive data (maybe pay an optional fee)
    *
    * @param feedIDs the array of feedIds
    */
    function getFeeds(uint256[] memory feedIDs) external view returns (uint256[] memory, uint256[] memory, uint256[] memory);

    /**
    * @dev getFeed function lets anyone call the oracle to receive data (maybe pay an optional fee)
    *
    * @param feedID the array of feedId
    */
    function getFeed(uint256 feedID) external view returns (uint256, uint256, uint256);

    /**
    * @dev getFeedList function returns the metadata of a feed
    *
    * @param feedIDs the array of feedId
    */
    function getFeedList(uint256[] memory feedIDs) external view returns(string[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory);
}

contract OOFTWAP {

    // using Openzeppelin contracts for SafeMath and Address
    using Address for address;

    constructor() {
        
    }

    //---------------------------view functions ---------------------------

    function getTWAP(IOpenOracleFramework OOFContract, uint256[] memory feedIDs, uint256[] memory timestampstart, uint256[] memory timestampfinish, bool strictMode) external view returns (uint256[] memory TWAP) {

            uint256 feedLen = feedIDs.length;
            TWAP = new uint256[](feedLen);
            uint256[] memory timeslot = new uint256[](feedLen);

            require(feedIDs.length == timestampstart.length && feedIDs.length == timestampfinish.length, "Feeds and Timestamps must match");

            (,,timeslot,,) = OOFContract.getFeedList(feedIDs);

            for (uint c = 0; c < feedLen; c++) {

                uint256 twapCount = timestampfinish[c] / timeslot[c] - timestampstart[c] / timeslot[c] + 1;
                uint256[] memory twapFeedIDs = new uint256[](twapCount);
                uint256[] memory timestampToCheck = new uint256[](twapCount);
                uint256 twapTotal;

                uint256[] memory totals = new uint256[](twapCount);

                for (uint s = 0; s < twapCount; s++) {
                    timestampToCheck[s] = timestampstart[c] + s * timeslot[c];
                    twapFeedIDs[s] = feedIDs[c];
                }

                totals = OOFContract.getHistoricalFeeds(twapFeedIDs, timestampToCheck);

                uint256 twapLen;

                if (strictMode) {
                    require(totals[0] != 0 && totals[totals.length-1] != 0, "Strict Mode: no 0 values for first and last element");
                }

                for (uint t = 0; t < totals.length; t++){
                    if (totals[t] != 0) {
                        twapTotal += totals[t];
                        twapLen += 1;
                    }
                }

                if (twapLen > 0) {
                    TWAP[c] = twapTotal / twapLen;
                } else {
                    TWAP[c] = 0;
                }
            }

            return (TWAP);
    }

    function lastTWAP(IOpenOracleFramework OOFContract, uint256[] memory feedIDs, uint256[] memory timeWindows) external view returns (uint256[] memory TWAP) {

        TWAP = new uint256[](feedIDs.length);
        uint256[] memory timeslot = new uint256[](feedIDs.length);

        (,,timeslot,,) = OOFContract.getFeedList(feedIDs);

        for (uint c = 0; c < feedIDs.length; c++) {
            uint256 timestampfinish = block.timestamp;
            uint256 timestampstart = timestampfinish - timeWindows[c];

            uint256 twapCount = timestampfinish / timeslot[c] - timestampstart / timeslot[c] + 1;
            uint256[] memory twapFeedIDs = new uint256[](twapCount);
            uint256[] memory timestampToCheck = new uint256[](twapCount);
            uint256 twapTotal;

            uint256[] memory totals = new uint256[](twapCount);

            for (uint s = 0; s < twapCount; s++) {
                timestampToCheck[s] = timestampstart + s * timeslot[c];
                twapFeedIDs[s] = feedIDs[c];
            }

            totals = OOFContract.getHistoricalFeeds(twapFeedIDs, timestampToCheck);

            uint256 twapLen;

            for (uint t = 0; t < totals.length; t++){
                if (totals[t] != 0) {
                    twapTotal += totals[t];
                    twapLen += 1;
                }
            }

            if (twapLen > 0) {
                uint256 feedValue;
                (feedValue,,) = OOFContract.getFeed(feedIDs[c]);
                TWAP[c] = (twapTotal + feedValue) / (twapLen + 1);
            } else {
                TWAP[c] = 0;
            }
        }

        return (TWAP);
    }
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}