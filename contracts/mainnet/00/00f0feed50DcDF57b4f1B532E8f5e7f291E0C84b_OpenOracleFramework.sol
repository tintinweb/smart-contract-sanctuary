// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IConjureFactory.sol";
import "./interfaces/IConjureRouter.sol";

contract OpenOracleFramework {

    // using Openzeppelin contracts for SafeMath and Address
    using SafeMath for uint256;
    using Address for address;

    // the address of the collateral contract factory
    address public factoryContract;

    // address used for pay out
    address payable public payoutAddress;

    // number of signers
    uint256 public signerLength;

    // addresses of the signers
    address[] public signers;

    // threshold which has to be reached
    uint256 public signerThreshold;

    // struct to keep the values for each individual round
    struct feedRoundStruct {
        uint256 value;
        uint256 timestamp;
    }

    // stores historical values of feeds
    mapping(uint256 => mapping(uint256 => uint256)) private historicalFeeds;

    // indicates if sender is a signer
    mapping(address => bool) private isSigner;

    // mapping to store the actual submitted values per FeedId, per round number
    mapping(uint256 => mapping(uint256 => mapping(address => feedRoundStruct))) private feedRoundNumberToStructMapping;

    // indicates support of feeds
    mapping(uint256 => uint256) public feedSupport;

    // indicates if address si subscribed to a feed
    mapping(address => mapping(uint256 => uint256)) private subscribedTo;

    struct oracleStruct {
        string feedName;
        uint256 feedDecimals;
        uint256 feedTimeslot;
        uint256 latestPrice;
        uint256 latestPriceUpdate;
        // 0... donation, 1... subscription
        uint256 revenueMode;
        uint256 feedCost;
    }

    oracleStruct[] private feedList;

    // indicates if oracle subscription is turned on. 0 indicates no pass
    uint256 public subscriptionPassPrice;

    mapping(address => uint256) private hasPass;

    struct proposalStruct {
        uint256 uintValue;
        address addressValue;
        address proposer;
        // 0 ... pricePass
        // 1 ... threshold
        // 2 ... add signer
        // 3 ... remove signer
        // 4 ... payoutAddress
        // 5 ... revenueMode
        // 6 ... feedCost
        uint256 proposalType;
        uint256 proposalFeedId;
        uint256 proposalActive;
    }

    proposalStruct[] public proposalList;

    mapping(uint256 => mapping(address => bool)) private hasSignedProposal;

    event contractSetup(address[] signers, uint256 signerThreshold, address payout);
    event feedAdded(string name, string description, uint256 decimal, uint256 timeslot, uint256 feedId, uint256 mode, uint256 price);
    event feedSigned(uint256 feedId, uint256 roundId, uint256 value, uint256 timestamp, address signer);
    event routerFeeTaken(uint256 value, address sender);
    event feedSupported(uint256 feedId, uint256 supportvalue);
    event newProposal(uint256 proposalId, uint256 uintValue, address addressValue, uint256 oracleType, address proposer);
    event proposalSigned(uint256 proposalId, address signer);
    event newFee(uint256 value);
    event newThreshold(uint256 value);
    event newSigner(address signer);
    event signerRemoved(address signer);
    event newPayoutAddress(address payout);
    event newRevenueMode(uint256 mode, uint256 feed);
    event newFeedCost(uint256 cost, uint256 feed);
    event subscriptionPassPriceUpdated(uint256 newPass);

    // only Signer modifier
    modifier onlySigner {
        _onlySigner();
        _;
    }

    // only Signer view
    function _onlySigner() private view {
        require(isSigner[msg.sender], "Only a signer can perform this action");
    }

    constructor() {
        // Don't allow implementation to be initialized.
        //factoryContract = address(1);
    }

    function initialize(
        address[] memory signers_,
        uint256 signerThreshold_,
        address payable payoutAddress_,
        uint256 subscriptionPassPrice_,
        address factoryContract_
    ) external
    {
        require(factoryContract == address(0), "already initialized");
        require(factoryContract_ != address(0), "factory can not be null");
        require(signerThreshold_ != 0, "Threshold cant be 0");
        require(signerThreshold_ <= signers_.length, "Threshold cant be more then signer count");

        factoryContract = factoryContract_;
        signerThreshold = signerThreshold_;
        signers = signers_;

        for(uint i=0; i< signers.length; i++) {
            require(signers[i] != address(0), "Not zero address");
            isSigner[signers[i]] = true;
        }

        signerLength = signers_.length;
        payoutAddress = payoutAddress_;
        subscriptionPassPrice = subscriptionPassPrice_;

        emit contractSetup(signers_, signerThreshold, payoutAddress);
    }

    //---------------------------helper functions---------------------------

    /**
    * @dev implementation of a quicksort algorithm
    *
    * @param arr the array to be sorted
    * @param left the left outer bound element to start the sort
    * @param right the right outer bound element to stop the sort
    */
    function quickSort(uint[] memory arr, int left, int right) private pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    /**
    * @dev sort implementation which calls the quickSort function
    *
    * @param data the array to be sorted
    * @return the sorted array
    */
    function sort(uint[] memory data) private pure returns (uint[] memory) {
        quickSort(data, int(0), int(data.length - 1));
        return data;
    }

    //---------------------------view functions ---------------------------

    function getHistoricalFeeds(uint256[] memory feedIDs, uint256[] memory timestamps) external view returns (uint256[] memory) {

        uint256 feedLen = feedIDs.length;
        uint256[] memory returnPrices = new uint256[](feedLen);
        require(feedIDs.length == timestamps.length, "Feeds and Timestamps must match");

        for (uint i = 0; i < feedIDs.length; i++) {

            if (subscriptionPassPrice > 0) {
                if (hasPass[msg.sender] <= block.timestamp) {
                    if (feedList[feedIDs[i]].revenueMode == 1 && subscribedTo[msg.sender][feedIDs[i]] < block.timestamp) {
                        revert("No subscription to feed");
                    }
                }
            } else {
                if (feedList[feedIDs[i]].revenueMode == 1 && subscribedTo[msg.sender][feedIDs[i]] < block.timestamp) {
                    revert("No subscription to feed");
                }
            }

            uint256 roundNumber = timestamps[i] / feedList[feedIDs[i]].feedTimeslot;
            returnPrices[i] =  historicalFeeds[feedIDs[i]][roundNumber];
        }

        return (returnPrices);
    }


    /**
    * @dev getFeeds function lets anyone call the oracle to receive data (maybe pay an optional fee)
    *
    * @param feedIDs the array of feedIds
    */
    function getFeeds(uint256[] memory feedIDs) external view returns (uint256[] memory, uint256[] memory, uint256[] memory) {

        uint256 feedLen = feedIDs.length;
        uint256[] memory returnPrices = new uint256[](feedLen);
        uint256[] memory returnTimestamps = new uint256[](feedLen);
        uint256[] memory returnDecimals = new uint256[](feedLen);

        for (uint i = 0; i < feedIDs.length; i++) {
            (returnPrices[i] ,returnTimestamps[i], returnDecimals[i]) = getFeed(feedIDs[i]);
        }

        return (returnPrices, returnTimestamps, returnDecimals);
    }

    /**
    * @dev getFeed function lets anyone call the oracle to receive data (maybe pay an optional fee)
    *
    * @param feedID the array of feedId
    */
    function getFeed(uint256 feedID) public view returns (uint256, uint256, uint256) {

        uint256 returnPrice;
        uint256 returnTimestamp;
        uint256 returnDecimals;

        if (subscriptionPassPrice > 0) {
            if (hasPass[msg.sender] <= block.timestamp) {
                if (feedList[feedID].revenueMode == 1 && subscribedTo[msg.sender][feedID] < block.timestamp) {
                    revert("No subscription to feed");
                }
            }
        } else {
            if (feedList[feedID].revenueMode == 1 && subscribedTo[msg.sender][feedID] < block.timestamp) {
                revert("No subscription to feed");
            }
        }

        returnPrice = feedList[feedID].latestPrice;
        returnTimestamp = feedList[feedID].latestPriceUpdate;
        returnDecimals = feedList[feedID].feedDecimals;

        return (returnPrice, returnTimestamp, returnDecimals);
    }

    function getFeedLength() external view returns(uint256){
        return feedList.length;
    }

    function getFeedList(uint256[] memory feedIDs) external view returns(string[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {

        uint256 feedLen = feedIDs.length;
        string[] memory returnNames = new string[](feedLen);
        uint256[] memory returnDecimals = new uint256[](feedLen);
        uint256[] memory returnTimeslot = new uint256[](feedLen);
        uint256[] memory returnRevenueMode = new uint256[](feedLen);
        uint256[] memory returnCost = new uint256[](feedLen);

        for (uint i = 0; i < feedIDs.length; i++) {
            returnNames[i] = feedList[feedIDs[i]].feedName;
            returnDecimals[i] = feedList[feedIDs[i]].feedDecimals;
            returnTimeslot[i] = feedList[feedIDs[i]].feedTimeslot;
            returnRevenueMode[i] = feedList[feedIDs[i]].revenueMode;
            returnCost[i] = feedList[feedIDs[i]].feedCost;
        }

        return (returnNames, returnDecimals, returnTimeslot, returnRevenueMode, returnCost);
    }

    //---------------------------oracle management functions ---------------------------

    // function to withdraw funds
    function withdrawFunds() external {

        if (payoutAddress == address(0)) {
            for (uint n = 0; n < signers.length; n++){
                payable(signers[n]).transfer(address(this).balance/signers.length);
            }
        } else {
            payoutAddress.transfer(address(this).balance);
        }
    }

    function createNewFeeds(string[] memory names, string[] memory descriptions, uint256[] memory decimals, uint256[] memory timeslots, uint256[] memory feedCosts, uint256[] memory revenueModes) onlySigner external {
        require(names.length == descriptions.length, "Length mismatch");
        require(descriptions.length == decimals.length, "Length mismatch");
        require(decimals.length == timeslots.length, "Length mismatch");
        require(timeslots.length == feedCosts.length, "Length mismatch");
        require(feedCosts.length == revenueModes.length, "Length mismatch");

        for(uint i = 0; i < names.length; i++) {
            require(decimals[i] <= 18, "Decimal places too high");
            require(timeslots[i] > 0, "Timeslot cannot be 0");
            require(revenueModes[i] <= 1, "Wrong revenueMode parameter");

            feedList.push(oracleStruct({
            feedName: names[i],
            feedDecimals: decimals[i],
            feedTimeslot: timeslots[i],
            latestPrice: 0,
            latestPriceUpdate: 0,
            revenueMode: revenueModes[i],
            feedCost: feedCosts[i]
            }));

            emit feedAdded(names[i], descriptions[i], decimals[i], timeslots[i], feedList.length - 1, revenueModes[i], feedCosts[i]);
        }
    }

    /**
    * @dev submitFeed function lets a signer submit as many feeds as they want to
    *
    * @param values the array of values
    * @param feedIDs the array of feedIds
    */
    function submitFeed(uint256[] memory feedIDs, uint256[] memory values) onlySigner external {
        require(values.length == feedIDs.length, "Value length and feedID length do not match");

        // process feeds
        for (uint i = 0; i < values.length; i++) {
            // get current round number for feed
            uint256 roundNumber = block.timestamp / feedList[feedIDs[i]].feedTimeslot;

            // check if the signer already pushed an update for the given period
            if (feedRoundNumberToStructMapping[feedIDs[i]][roundNumber][msg.sender].timestamp != 0) {
                delete feedRoundNumberToStructMapping[feedIDs[i]][roundNumber][msg.sender];
            }

            // feed - number and push value
            feedRoundNumberToStructMapping[feedIDs[i]][roundNumber][msg.sender] = feedRoundStruct({
            value: values[i],
            timestamp: block.timestamp
            });

            emit feedSigned(feedIDs[i], roundNumber, values[i], block.timestamp, msg.sender);

            // check if threshold was met
            uint256 signedFeedsLen;
            uint256[] memory prices = new uint256[](signers.length);
            uint256 k;

            for (uint j = 0; j < signers.length; j++) {
                if (feedRoundNumberToStructMapping[feedIDs[i]][roundNumber][signers[j]].timestamp != 0) {
                    signedFeedsLen++;
                    prices[k++] = feedRoundNumberToStructMapping[feedIDs[i]][roundNumber][signers[j]].value;
                }
            }

            // Change the list size of the array in place
            assembly {
                mstore(prices, k)
            }

            // if threshold is met process price
            if (signedFeedsLen >= signerThreshold) {

                uint[] memory sorted = sort(prices);
                uint returnPrice;

                // uneven so we can take the middle
                if (sorted.length % 2 == 1) {
                    uint sizer = (sorted.length + 1) / 2;
                    returnPrice = sorted[sizer-1];
                    // take average of the 2 most inner numbers
                } else {
                    uint size1 = (sorted.length) / 2;
                    returnPrice =  (sorted[size1-1]+sorted[size1])/2;
                }

                // process the struct for storing
                if (block.timestamp / feedList[feedIDs[i]].feedTimeslot > feedList[feedIDs[i]].latestPriceUpdate / feedList[feedIDs[i]].feedTimeslot) {
                    historicalFeeds[feedIDs[i]][feedList[feedIDs[i]].latestPriceUpdate / feedList[feedIDs[i]].feedTimeslot] = feedList[feedIDs[i]].latestPrice;
                }
                feedList[feedIDs[i]].latestPriceUpdate = block.timestamp;
                feedList[feedIDs[i]].latestPrice = returnPrice;
            }
        }
    }

    function signProposal(uint256 proposalId) onlySigner external {
        require(proposalList[proposalId].proposalActive != 0, "Proposal not active");

        hasSignedProposal[proposalId][msg.sender] = true;
        emit proposalSigned(proposalId, msg.sender);

        uint256 signedProposalLen;

        for(uint i = 0; i < signers.length; i++) {
            if (hasSignedProposal[proposalId][signers[i]]) {
                signedProposalLen++;
            }
        }

        // execute proposal
        if (signedProposalLen >= signerThreshold) {
            if (proposalList[proposalId].proposalType == 0) {
                updatePricePass(proposalList[proposalId].uintValue);
            } else if (proposalList[proposalId].proposalType == 1) {
                updateThreshold(proposalList[proposalId].uintValue);
            } else if (proposalList[proposalId].proposalType == 2) {
                addSigners(proposalList[proposalId].addressValue);
            } else if (proposalList[proposalId].proposalType == 3) {
                removeSigner(proposalList[proposalId].addressValue);
            } else if (proposalList[proposalId].proposalType == 4) {
                updatePayoutAddress(proposalList[proposalId].addressValue);
            } else if (proposalList[proposalId].proposalType == 5) {
                updateRevenueMode(proposalList[proposalId].uintValue, proposalList[proposalId].proposalFeedId);
            } else {
                updateFeedCost(proposalList[proposalId].uintValue, proposalList[proposalId].proposalFeedId);
            }

            // lock proposal
            proposalList[proposalId].proposalActive = 0;
        }
    }

    function createProposal(uint256 uintValue, address addressValue, uint256 proposalType, uint256 feedId) onlySigner external {

        uint256 proposalArrayLen = proposalList.length;

        // fee or threshold
        if (proposalType == 0 || proposalType == 1 || proposalType == 7) {
            proposalList.push(proposalStruct({
            uintValue: uintValue,
            addressValue: address(0),
            proposer: msg.sender,
            proposalType: proposalType,
            proposalFeedId: 0,
            proposalActive: 1
            }));
        } else if (proposalType == 5 || proposalType == 6) {
            proposalList.push(proposalStruct({
            uintValue: uintValue,
            addressValue: address(0),
            proposer: msg.sender,
            proposalType: proposalType,
            proposalFeedId : feedId,
            proposalActive: 1
            }));
        } else {
            proposalList.push(proposalStruct({
            uintValue: 0,
            addressValue: addressValue,
            proposer: msg.sender,
            proposalType: proposalType,
            proposalFeedId : 0,
            proposalActive: 1
            }));
        }

        hasSignedProposal[proposalArrayLen][msg.sender] = true;

        emit newProposal(proposalArrayLen, uintValue, addressValue, proposalType, msg.sender);
        emit proposalSigned(proposalArrayLen, msg.sender);
    }

    function updatePricePass(uint256 newPricePass) private {
        subscriptionPassPrice = newPricePass;

        emit subscriptionPassPriceUpdated(newPricePass);
    }

    function updateRevenueMode(uint256 newRevenueModeValue, uint256 feedId ) private {
        require(newRevenueModeValue <= 1, "Invalid argument for revenue Mode");
        feedList[feedId].revenueMode = newRevenueModeValue;
        emit newRevenueMode(newRevenueModeValue, feedId);
    }

    function updateFeedCost(uint256 feedCost, uint256 feedId) private {
        require(feedCost > 0, "Feed price cant be 0");
        feedList[feedId].feedCost = feedCost;
        emit newFeedCost(feedCost, feedId);
    }

    function updateThreshold(uint256 newThresholdValue) private {
        require(newThresholdValue != 0, "Threshold cant be 0");
        require(newThresholdValue <= signerLength, "Threshold cant be bigger then length of signers");

        signerThreshold = newThresholdValue;
        emit newThreshold(newThresholdValue);
    }

    function addSigners(address newSignerValue) private {

        // check for duplicate signer
        for (uint i=0; i < signers.length; i++) {
            if (signers[i] == newSignerValue) {
                revert("Signer already exists");
            }
        }

        signers.push(newSignerValue);
        signerLength++;
        isSigner[newSignerValue] = true;
        emit newSigner(newSignerValue);
    }

    function updatePayoutAddress(address newPayoutAddressValue) private {
        payoutAddress = payable(newPayoutAddressValue);
        emit newPayoutAddress(newPayoutAddressValue);
    }

    function removeSigner(address toRemove) internal {
        require(isSigner[toRemove], "Address to remove has to be a signer");
        require(signers.length -1 >= signerThreshold, "Less signers than threshold");

        for (uint i = 0; i < signers.length; i++) {
            if (signers[i] == toRemove) {
                delete signers[i];
                signerLength --;
                isSigner[toRemove] = false;
                emit signerRemoved(toRemove);
            }
        }
    }

    //---------------------------subscription functions---------------------------

    function subscribeToFeed(uint256[] memory feedIDs, uint256[] memory durations, address buyer) payable external {
        require(feedIDs.length == durations.length, "Length mismatch");

        uint256 total;
        for (uint i = 0; i < feedIDs.length; i++) {
            require(feedList[feedIDs[i]].revenueMode == 1, "Donation mode turned on");
            require(durations[i] >= 3600, "Minimum subscription is 1h");

            if (subscribedTo[buyer][feedIDs[i]] <=block.timestamp) {
                subscribedTo[buyer][feedIDs[i]] = block.timestamp.add(durations[i]);
            } else {
                subscribedTo[buyer][feedIDs[i]] = subscribedTo[buyer][feedIDs[i]].add(durations[i]);
            }

            total += feedList[feedIDs[i]].feedCost * durations[i] / 3600;
        }

        // check if enough payment was sent
        require(msg.value >= total, "Not enough funds sent to cover oracle fees");

        // send feeds to router
        address payable conjureRouter = IConjureFactory(factoryContract).getConjureRouter();
        IConjureRouter(conjureRouter).deposit{value:msg.value/50}();
        emit routerFeeTaken(msg.value/50, msg.sender);
    }

    function buyPass(address buyer, uint256 duration) payable external {
        require(subscriptionPassPrice != 0, "Subscription Pass turned off");
        require(duration >= 3600, "Minimum subscription is 1h");
        require(msg.value >= subscriptionPassPrice * duration / 86400, "Not enough payment");

        if (hasPass[buyer] <=block.timestamp) {
            hasPass[buyer] = block.timestamp.add(duration);
        } else {
            hasPass[buyer] = hasPass[buyer].add(duration);
        }

        address payable conjureRouter = IConjureFactory(factoryContract).getConjureRouter();
        IConjureRouter(conjureRouter).deposit{value:msg.value/50}();
        emit routerFeeTaken(msg.value/50, msg.sender);
    }

    function supportFeeds(uint256[] memory feedIds, uint256[] memory values) payable external {
        require(feedIds.length == values.length, "Length mismatch");

        uint256 total;
        for (uint i = 0; i < feedIds.length; i++) {
            require(feedList[feedIds[i]].revenueMode == 0, "Subscription mode turned on");
            feedSupport[feedIds[i]] = feedSupport[feedIds[i]].add(values[i]);
            total += values[i];

            emit feedSupported(feedIds[i], values[i]);
        }

        require(msg.value >= total, "Msg.value does not meet support values");

        address payable conjureRouter = IConjureFactory(factoryContract).getConjureRouter();
        IConjureRouter(conjureRouter).deposit{value:total/100}();
        emit routerFeeTaken(total/100, msg.sender);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/// @author Conjure Finance Team
/// @title IConjureFactory
/// @notice Interface for interacting with the ConjureFactory Contract
interface IConjureFactory {

    /**
     * @dev gets the current conjure router
     *
     * @return the current conjure router
    */
    function getConjureRouter() external returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/// @author Conjure Finance Team
/// @title IConjureRouter
/// @notice Interface for interacting with the ConjureRouter Contract
interface IConjureRouter {

    /**
     * @dev calls the deposit function
    */
    function deposit() external payable;
}

