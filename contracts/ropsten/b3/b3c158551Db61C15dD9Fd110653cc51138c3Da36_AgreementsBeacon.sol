// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.7.3;

contract AgreementsBeacon {
    struct Beacon {
        address creator;
        bool activated;
        bytes32 templateId;
        string templateConfig;
        string url;
        mapping(address => Agreement) agreements;
    }

    struct Agreement {
        address creator;
        address accepter;
        address agreement;
        LegalState state;
        string errorCode;
        uint256 requestIndex;
        uint256 currentBlockHeight;
        uint256 currentEventIndex;
    }

    enum LegalState {
        DRAFT,
        FORMULATED,
        EXECUTED,
        FULFILLED,
        DEFAULT,
        CANCELED,
        UNDEFINED,
        REDACTED
    }

    // Internal database
    mapping(address => mapping(uint256 => Beacon)) private beacons;

    // Event names
    bytes32 private constant EVENT_NAMESPACE = "monax";
    bytes32 private constant EVENT_NAME_BEACON_STATE_CHANGE =
        "request:beacon-status-change";
    bytes32 private constant EVENT_NAME_REQUEST_CREATE_AGREEMENT =
        "request:create-agreement";
    bytes32 private constant EVENT_NAME_REPORT_AGREEMENT_STATUS =
        "report:agreement-status";

    // Global variables
    address[] private owners;
    uint256 private requestIndex;
    uint256 private currentEventIndex;

    // Global constants
    bytes32 public constant BASE_URL = "https://agreements.zone";
    uint256 public constant AGREEMENT_BEACON_PRICE = 1000; // TODO

    // Event definitions
    event LogBeaconStatusChange(
        bytes32 indexed eventNamespace,
        bytes32 indexed eventCategory,
        address creator,
        address relayer,
        address tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string templateConfig,
        bool activated,
        uint256 currentBlockHeight,
        uint256 currentEventIndex
    );

    event LogRequestCreateAgreement(
        bytes32 indexed eventNamespace,
        bytes32 indexed eventCategory,
        address creator,
        address relayer,
        address tokenContractAddress,
        uint256 tokenId,
        address accepter,
        uint256 requestIndex,
        uint256 currentBlockHeight,
        uint256 currentEventIndex
    );

    event LogAgreementStatus(
        bytes32 indexed eventNamespace,
        bytes32 indexed eventCategory,
        address agreement,
        LegalState state,
        string errorCode,
        uint256 requestIndex,
        uint256 currentBlockHeight,
        uint256 currentEventIndex
    );

    /**
     * Modifier functions
     */
    modifier ownersOnly() {
        bool isOwner;
        for (uint256 i; i < owners.length; i++) {
            if (msg.sender == owners[i]) {
                isOwner = true;
            }
        }
        require(isOwner, "Sender must be a contract owner");
        _;
    }

    modifier requireCharge() {
        uint256 price = AGREEMENT_BEACON_PRICE;
        require(msg.value >= price, "Insufficient funds for operation");
        _;
    }

    modifier isBeaconActivated(address tokenContractAddress, uint256 tokenId) {
        require(
            beacons[tokenContractAddress][tokenId].activated,
            "Beacon not activated"
        );
        _;
    }

    modifier addEvent(uint256 eventCount) {
        _;
        currentEventIndex += eventCount;
    }

    modifier addRequestIndex() {
        _;
        requestIndex += 1;
    }

    constructor(address[] memory _owners) {
        require(_owners.length > 0, "> 1 owner required");
        requestIndex = 1;
        owners = _owners;
    }

    /**
     * Public mutable functions
     */
    function requestCreateBeacon(
        address tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string memory templateConfig
    ) public payable requireCharge() {
        require(
            beacons[tokenContractAddress][tokenId].creator == address(0),
            "Request limit reached"
        );
        beacons[tokenContractAddress][tokenId].creator = msg.sender;
        beacons[tokenContractAddress][tokenId].templateId = templateId;
        beacons[tokenContractAddress][tokenId].templateConfig = templateConfig;
        beacons[tokenContractAddress][tokenId].activated = true;
        beacons[tokenContractAddress][tokenId].url = setBeaconUrl(
            tokenContractAddress,
            tokenId
        );
        emitBeaconStateChange(
            tokenContractAddress,
            tokenId,
            templateId,
            templateConfig,
            true
        );
    }

    function requestUpdateBeacon(
        address tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string memory templateConfig,
        bool activated
    ) public payable requireCharge() {
        require(
            beacons[tokenContractAddress][tokenId].creator == msg.sender,
            "You do not own me"
        );
        beacons[tokenContractAddress][tokenId].templateId = templateId;
        beacons[tokenContractAddress][tokenId].templateConfig = templateConfig;
        beacons[tokenContractAddress][tokenId].activated = activated;
        emitBeaconStateChange(
            tokenContractAddress,
            tokenId,
            templateId,
            templateConfig,
            activated
        );
    }

    function requestCreateAgreement(
        address tokenContractAddress,
        uint256 tokenId,
        address[] memory accepters
    )
        public
        payable
        requireCharge()
        isBeaconActivated(tokenContractAddress, tokenId)
        addRequestIndex()
    {
        for (uint256 i = 0; i < accepters.length; i++) {
            address accepter = accepters[i];
            if (
                beacons[tokenContractAddress][tokenId].agreements[accepter]
                    .requestIndex != 0
            ) {
                continue;
            }
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .creator = beacons[tokenContractAddress][tokenId].creator;
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .accepter = accepter;
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .requestIndex = requestIndex;
            emitCreateAgreementRequest(tokenContractAddress, tokenId, accepter);
        }
    }

    /**
     * Owner mutable functions
     */
    function reportAgreementStatus(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter,
        address agreement,
        LegalState state,
        string memory errorCode
    ) public ownersOnly() {
        if (
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .agreement == address(0)
        ) {
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .agreement = agreement;
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .state = state;
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .errorCode = errorCode;
        } else {
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .state = state;
        }
        beacons[tokenContractAddress][tokenId].agreements[accepter]
            .currentBlockHeight = block.number;
        beacons[tokenContractAddress][tokenId].agreements[accepter]
            .currentEventIndex = currentEventIndex;
        emitAgreementStatus(tokenContractAddress, tokenId, accepter);
    }

    /**
     * Public view functions
     */
    function getBeaconURL(address tokenContractAddress, uint256 tokenId)
        public
        view
        isBeaconActivated(tokenContractAddress, tokenId)
        returns (string memory)
    {
        return beacons[tokenContractAddress][tokenId].url;
    }

    function getBeaconCreator(address tokenContractAddress, uint256 tokenId)
        public
        view
        isBeaconActivated(tokenContractAddress, tokenId)
        returns (address creator)
    {
        return beacons[tokenContractAddress][tokenId].creator;
    }

    function getAgreementId(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    )
        public
        view
        isBeaconActivated(tokenContractAddress, tokenId)
        returns (address agreement)
    {
        return
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .agreement;
    }

    function getAgreementStatus(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    )
        public
        view
        isBeaconActivated(tokenContractAddress, tokenId)
        returns (LegalState state)
    {
        return
            beacons[tokenContractAddress][tokenId].agreements[accepter].state;
    }

    /**
     * Emit events
     */
    function emitBeaconStateChange(
        address tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string memory templateConfig,
        bool activated
    ) internal addEvent(1) {
        emit LogBeaconStatusChange(
            EVENT_NAMESPACE,
            EVENT_NAME_BEACON_STATE_CHANGE,
            msg.sender,
            tx.origin, // solhint-disable-line avoid-tx-origin
            tokenContractAddress,
            tokenId,
            templateId,
            templateConfig,
            activated,
            block.number,
            currentEventIndex
        );
    }

    function emitCreateAgreementRequest(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    ) internal addEvent(1) {
        emit LogRequestCreateAgreement(
            EVENT_NAMESPACE,
            EVENT_NAME_REQUEST_CREATE_AGREEMENT,
            msg.sender,
            tx.origin, // solhint-disable-line avoid-tx-origin
            tokenContractAddress,
            tokenId,
            accepter,
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .requestIndex,
            block.number,
            currentEventIndex
        );
    }

    function emitAgreementStatus(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    ) internal addEvent(1) {
        emit LogAgreementStatus(
            EVENT_NAMESPACE,
            EVENT_NAME_REPORT_AGREEMENT_STATUS,
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .agreement,
            beacons[tokenContractAddress][tokenId].agreements[accepter].state,
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .errorCode,
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .requestIndex,
            block.number,
            currentEventIndex
        );
    }

    /**
     * Utility functions
     */
    function setBeaconUrl(address tokenContractAddress, uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    BASE_URL,
                    "/ethereum",
                    "/",
                    getChainID(),
                    "/",
                    addr2str(tokenContractAddress),
                    "/",
                    uint2str(tokenId)
                )
            );
    }

    // TODO: use a library
    function getChainID() internal pure returns (string memory) {
        uint256 id;
        /* solhint-disable no-inline-assembly */
        assembly {
            id := chainid()
        }
        /* solhint-enable no-inline-assembly */
        return uint2str(id);
    }

    // TODO: use a library
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    // TODO: use a library
    function addr2str(address _address) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory hexchars = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = hexchars[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = hexchars[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
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