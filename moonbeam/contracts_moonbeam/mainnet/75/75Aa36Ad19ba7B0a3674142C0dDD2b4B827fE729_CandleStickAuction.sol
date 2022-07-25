//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";

interface Auction {
    struct Offer {
        uint256 price;
        uint256 timestamp;
        bool fundsEscrowed;
        bool accepted;
        address bidder;
    }

    function end(uint256 itemId) external;

    function finalizeAuctionAndSendOut(uint256 itemId) external;

    function highestBid(uint256 itemId) external view returns (Offer memory);
}

contract CandleStickAuction is RrpRequesterV0 {
    event RequestedUint256(bytes32 indexed requestId);
    event ReceivedUint256(bytes32 indexed requestId, uint256 response);
    event RequestedUint256Array(bytes32 indexed requestId, uint256 size);
    event ReceivedUint256Array(bytes32 indexed requestId, uint256[] response);
    event ExtinguishFlame(uint256 id);
    event FlameExtinguishChance(uint256 result);
    event AuctionItemId(uint256 id);
    event LatestAuctionBidForItem(uint256 id, address bidder);

    address public airnode;
    bytes32 public endpointIdUint256;
    bytes32 public endpointIdUint256Array;
    address public sponsorWallet;

    address _owner;
    address _wind;

    bool public flameExtinguished;

    uint256 public attempts;
    uint256 public probabilityInMinutes = 60; // 1440 minutes in 24 hrs, so 1440/24 = 60;
    uint256 public cooldownPeriod = 55 minutes; // (in seconds) only 1 request per hour is allowed
    uint256 public lastAttempt;

    Auction privateAuction;

    mapping(bytes32 => bool) public expectingRequestWithIdToBeFulfilled;

    constructor(
        address _airnodeRrp,
        address wind,
        address auctionContract
    ) RrpRequesterV0(_airnodeRrp) {
        _owner = msg.sender;
        _wind = wind;
        privateAuction = Auction(auctionContract);
    }

    function createGustOfWind() external {
        require(msg.sender == _wind || msg.sender == _owner, "Not authorized");
        require(!flameExtinguished, "Auction has ended");
        require(
            block.timestamp >= (lastAttempt + cooldownPeriod),
            "Cooldown period has not completed"
        );
        // request 2 x uint256 ( 1 for itemID, the other for probability)
        _makeRequestUint256Array(2);
    }

    function updateProbability(uint256 probability) external onlyOwner {
        probabilityInMinutes = probability;
    }

    function updateCooldown(uint256 cooldownMins) external onlyOwner {
        cooldownPeriod = cooldownMins;
    }

    /// @notice Sets parameters used in requesting QRNG services
    /// @dev No access control is implemented here for convenience. This is not
    /// secure because it allows the contract to be pointed to an arbitrary
    /// Airnode. Normally, this function should only be callable by the "owner"
    /// or not exist in the first place.
    /// @param _airnode Airnode address
    /// @param _endpointIdUint256 Endpoint ID used to request a `uint256`
    /// @param _endpointIdUint256Array Endpoint ID used to request a `uint256[]`
    /// @param _sponsorWallet Sponsor wallet address
    function setRequestParameters(
        address _airnode,
        bytes32 _endpointIdUint256,
        bytes32 _endpointIdUint256Array,
        address _sponsorWallet
    ) external onlyOwner {
        airnode = _airnode;
        endpointIdUint256 = _endpointIdUint256;
        endpointIdUint256Array = _endpointIdUint256Array;
        sponsorWallet = _sponsorWallet;
    }

    /// @notice Requests a `uint256[]`
    /// @param size Size of the requested array
    function _makeRequestUint256Array(uint256 size) private {
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256Array,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillUint256Array.selector,
            // Using Airnode ABI to encode the parameters
            abi.encode(bytes32("1u"), bytes32("size"), size)
        );
        expectingRequestWithIdToBeFulfilled[requestId] = true;
        emit RequestedUint256Array(requestId, size);
    }

    /// @notice Called by the Airnode through the AirnodeRrp contract to
    /// fulfill the request
    /// @param requestId Request ID
    /// @param data ABI-encoded response
    function fulfillUint256Array(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        require(
            expectingRequestWithIdToBeFulfilled[requestId],
            "Request ID not kblock.timestampn"
        );
        require(!flameExtinguished, "Auction is over");

        attempts++;
        lastAttempt = block.timestamp;
        expectingRequestWithIdToBeFulfilled[requestId] = false;

        uint256[] memory qrngUint256Array = abi.decode(data, (uint256[]));
        emit ReceivedUint256Array(requestId, qrngUint256Array);

        uint256 itemId = _pickRandomId(qrngUint256Array[0]);
        emit AuctionItemId(itemId);

        Auction.Offer memory latest = privateAuction.highestBid(itemId);

        emit LatestAuctionBidForItem(itemId, latest.bidder);

        // End the auction automatically after 24 hours if it hasn't completed
        if (_extinguishFlame(qrngUint256Array[1]) || attempts > 23) {
            flameExtinguished = true;
            // privateAuction.finalizeAuctionAndSendOut(itemId);
            emit ExtinguishFlame(itemId);
        }
    }

    function _pickRandomId(uint256 seed) internal pure returns (uint256 id) {
        uint256 chance = seed % 100;

        if (chance < 33) return 0;
        else if (chance < 66) return 1;
        else return 2;
    }

    function _extinguishFlame(uint256 seed) internal returns (bool) {
        uint256 result = seed % 1440;
        emit FlameExtinguishChance(result);
        if (result < probabilityInMinutes) return true;
        else return false;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Sender not owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAirnodeRrpV0.sol";

/// @title The contract to be inherited to make Airnode RRP requests
contract RrpRequesterV0 {
    IAirnodeRrpV0 public immutable airnodeRrp;

    /// @dev Reverts if the caller is not the Airnode RRP contract.
    /// Use it as a modifier for fulfill and error callback methods, but also
    /// check `requestId`.
    modifier onlyAirnodeRrp() {
        require(msg.sender == address(airnodeRrp), "Caller not Airnode RRP");
        _;
    }

    /// @dev Airnode RRP address is set at deployment and is immutable.
    /// RrpRequester is made its own sponsor by default. RrpRequester can also
    /// be sponsored by others and use these sponsorships while making
    /// requests, i.e., using this default sponsorship is optional.
    /// @param _airnodeRrp Airnode RRP contract address
    constructor(address _airnodeRrp) {
        airnodeRrp = IAirnodeRrpV0(_airnodeRrp);
        IAirnodeRrpV0(_airnodeRrp).setSponsorshipStatus(address(this), true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAuthorizationUtilsV0.sol";
import "./ITemplateUtilsV0.sol";
import "./IWithdrawalUtilsV0.sol";

interface IAirnodeRrpV0 is
    IAuthorizationUtilsV0,
    ITemplateUtilsV0,
    IWithdrawalUtilsV0
{
    event SetSponsorshipStatus(
        address indexed sponsor,
        address indexed requester,
        bool sponsorshipStatus
    );

    event MadeTemplateRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event MadeFullRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event FulfilledRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        bytes data
    );

    event FailedRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        string errorMessage
    );

    function setSponsorshipStatus(address requester, bool sponsorshipStatus)
        external;

    function makeTemplateRequest(
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function fulfill(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);

    function fail(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        string calldata errorMessage
    ) external;

    function sponsorToRequesterToSponsorshipStatus(
        address sponsor,
        address requester
    ) external view returns (bool sponsorshipStatus);

    function requesterToRequestCountPlusOne(address requester)
        external
        view
        returns (uint256 requestCountPlusOne);

    function requestIsAwaitingFulfillment(bytes32 requestId)
        external
        view
        returns (bool isAwaitingFulfillment);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuthorizationUtilsV0 {
    function checkAuthorizationStatus(
        address[] calldata authorizers,
        address airnode,
        bytes32 requestId,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) external view returns (bool status);

    function checkAuthorizationStatuses(
        address[] calldata authorizers,
        address airnode,
        bytes32[] calldata requestIds,
        bytes32[] calldata endpointIds,
        address[] calldata sponsors,
        address[] calldata requesters
    ) external view returns (bool[] memory statuses);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITemplateUtilsV0 {
    event CreatedTemplate(
        bytes32 indexed templateId,
        address airnode,
        bytes32 endpointId,
        bytes parameters
    );

    function createTemplate(
        address airnode,
        bytes32 endpointId,
        bytes calldata parameters
    ) external returns (bytes32 templateId);

    function getTemplates(bytes32[] calldata templateIds)
        external
        view
        returns (
            address[] memory airnodes,
            bytes32[] memory endpointIds,
            bytes[] memory parameters
        );

    function templates(bytes32 templateId)
        external
        view
        returns (
            address airnode,
            bytes32 endpointId,
            bytes memory parameters
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWithdrawalUtilsV0 {
    event RequestedWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet
    );

    event FulfilledWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet,
        uint256 amount
    );

    function requestWithdrawal(address airnode, address sponsorWallet) external;

    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        address airnode,
        address sponsor
    ) external payable;

    function sponsorToWithdrawalRequestCount(address sponsor)
        external
        view
        returns (uint256 withdrawalRequestCount);
}