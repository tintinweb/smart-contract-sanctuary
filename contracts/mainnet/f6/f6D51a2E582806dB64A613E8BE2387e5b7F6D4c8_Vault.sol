// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {DataTypes} from './libraries/DataTypes.sol';
import {Errors} from './libraries/Errors.sol';

/**
 * @title Aito Vault Contract
 * @author Aito
 *
 * @notice A contract that holds a staking auction won NFT's associated stkAAVE.
 */
contract Vault {
    using Address for address;

    address public immutable STAKING_AUCTION;

    constructor(address stakingAuction) {
        STAKING_AUCTION = stakingAuction;
    }

    modifier onlyStakingAuction() {
        require(msg.sender == STAKING_AUCTION, Errors.NOT_STAKING_AUCTION);
        _;
    }

    /**
     * @notice Executes the given low-level calls on given targets. Sender must be auction.
     *
     * @param targets The array of target addresses to call.
     * @param datas The array of abi encoded function data to call on each target.
     * @param callTypes The array of call types to execute, either regular call or delegateCall.
     */
    function execute(
        address[] calldata targets,
        bytes[] calldata datas,
        DataTypes.CallType[] calldata callTypes // The OpenZeppelin "Address" library handles reverting on failed calls.
    ) external onlyStakingAuction {
        require(
            targets.length == datas.length && datas.length == callTypes.length,
            Errors.VAULT_ARRAY_MISMATCH
        );

        for (uint256 i = 0; i < targets.length; i++) {
            if (callTypes[i] == DataTypes.CallType.Call) {
                targets[i].functionCall(datas[i]);
            } else if (callTypes[i] == DataTypes.CallType.DelegateCall) {
                targets[i].functionDelegateCall(datas[i]);
            } else {
                revert(Errors.INVALID_CALL_TYPE);
            }
        }
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

/// Library containing data types needed for the NFT controller & vaults
library DataTypes {

    struct DistributionData {
        address recipient;
        uint256 bps;
    }

    struct StakingAuctionFullData {
        StakingAuctionData auction;
        DistributionData[] distribution;
        uint256 auctionId;
        address auctioner;
        address vault;
    }

    struct StakingAuctionData {
        uint256 currentBid;
        address currentBidder;
        uint40 startTimestamp;
        uint40 endTimestamp;
    }

    struct StakingAuctionConfiguration {
        address vaultLogic;
        address treasury;
        uint40 minimumAuctionDuration;
        uint40 overtimeWindow;
        uint16 treasuryFeeBps;
        uint16 burnPenaltyBps;
    }

    struct GenericAuctionFullData {
        GenericAuctionData auction;
        DistributionData[] distribution;
        uint256 auctionId;
        address auctioner;
    }

    struct GenericAuctionData {
        uint256 currentBid;
        address currency;
        address currentBidder;
        uint40 startTimestamp;
        uint40 endTimestamp;
    }

    struct GenericAuctionConfiguration {
        address treasury;
        uint40 minimumAuctionDuration;
        uint40 overtimeWindow;
        uint16 treasuryFeeBps;
    }
    
    struct RankedAuctionData {
        uint256 minPrice;
        address recipient;
        address currency;
        uint40 startTimestamp;
        uint40 endTimestamp;
    }

struct ReserveAuctionFullData {
        ReserveAuctionData auction;
        DistributionData[] distribution;
        uint256 auctionId;
        address auctioner;
    }

    struct ReserveAuctionData {
        uint256 currentBid;
        uint256 buyNow;
        address currency;
        address currentBidder;
        uint40 duration;
        uint40 firstBidTimestamp;
        uint40 endTimestamp;
    }

    struct OpenEditionFullData {
        DistributionData[] distribution;
        OpenEditionSaleData saleData;
    }

    struct OpenEditionSaleData {
        uint256 price;
        address currency;
        address nft;
        uint40 startTimestamp;
        uint40 endTimestamp;
    }

    struct OpenEditionConfiguration {
        address treasury;
        uint40 minimumAuctionDuration;
        uint16 treasuryFeeBps;
    }

    struct OpenEditionBuyWithPermitParams {
        uint256 id;
        uint256 amount;
        uint256 permitAmount;
        uint256 deadline;
        address onBehalfOf;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct BidWithPermitParams {
        uint256 amount;
        uint256 deadline;
        uint256 nftId;
        address onBehalfOf;
        address nft;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct SimpleBidWithPermitParams {
        uint256 amount;
        uint256 deadline;
        address onBehalfOf;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    enum CallType {Call, DelegateCall}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

// Contains error code strings

library Errors {
  string public constant INVALID_AUCTION_TIMESTAMPS = '1';
  string public constant INVALID_BID_TIMESTAMPS = '2';
  string public constant INVALID_BID_AMOUNT = '3';
  string public constant AUCTION_ONGOING = '4';
  string public constant VALID_BIDDER = '5';
  string public constant NONEXISTANT_VAULT = '6';
  string public constant INVALID_DISTRIBUTION_BPS = '7';
  string public constant AUCTION_EXISTS = '8';
  string public constant NOT_STAKING_AUCTION = '9';
  string public constant INVALID_CALL_TYPE = '10';
  string public constant INVALID_AUCTION_DURATION = '11';
  string public constant INVALID_BIDDER = '12';
  string public constant PAUSED = '13';
  string public constant NOT_ADMIN = '14';
  string public constant INVALID_INIT_PARAMS = '15';
  string public constant INVALID_DISTRIBUTION_COUNT = '16';
  string public constant ZERO_RECIPIENT = '17';
  string public constant ZERO_CURRENCY = '18';
  string public constant RA_NOT_OUTBID = '19';
  string public constant RA_OUTBID = '20';
  string public constant RA_CLAIMED = '21';
  string public constant NO_DISTRIBUTIONS = '22';
  string public constant VAULT_ARRAY_MISMATCH = '23';
  string public constant CURRENCY_NOT_WHITELSITED = '24';
  string public constant NOT_NFT_OWNER = '25';
  string public constant ZERO_NFT = '26';
  string public constant NOT_COLLECTION_CREATOR = '27';
  string public constant INVALID_BUY_NOW = '28';
  string public constant INVALID_RESERVE_PRICE = '29';
}

{
  "optimizer": {
    "enabled": true,
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