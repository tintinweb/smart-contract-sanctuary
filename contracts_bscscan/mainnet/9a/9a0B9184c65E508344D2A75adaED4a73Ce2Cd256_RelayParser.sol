/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title The interface for Graviton oracle router
/// @notice Forwards data about crosschain locking/unlocking events to balance keepers
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IOracleRouterV2 {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice Look up if `user` can route data to balance keepers
    function canRoute(address user) external view returns (bool);

    /// @notice Sets the permission to route data to balance keepers
    /// @dev Can only be called by the current owner.
    function setCanRoute(address parser, bool _canRoute) external;

    /// @notice Routes value to balance keepers according to the type of event associated with topic0
    /// @param uuid Unique identifier of the routed data
    /// @param chain Type of blockchain associated with the routed event, i.e. "EVM"
    /// @param emiter The blockchain-specific address where the data event originated
    /// @param topic0 Unique identifier of the event
    /// @param token The blockchain-specific token address
    /// @param sender The blockchain-specific address that sent the tokens
    /// @param receiver The blockchain-specific address to receive the tokens
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of tokens
    function routeValue(
        bytes16 uuid,
        string memory chain,
        bytes memory emiter,
        bytes32 topic0,
        bytes memory token,
        bytes memory sender,
        bytes memory receiver,
        uint256 amount
    ) external;

    /// @notice Event emitted when the owner changes via #setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when the `parser` permission is updated via `#setCanRoute`
    /// @param owner The owner account at the time of change
    /// @param parser The account whose permission to route data was updated
    /// @param newBool Updated permission
    event SetCanRoute(
        address indexed owner,
        address indexed parser,
        bool indexed newBool
    );

    /// @notice Event emitted when data is routed
    /// @param uuid Unique identifier of the routed data
    /// @param chain Type of blockchain associated with the routed event, i.e. "EVM"
    /// @param emiter The blockchain-specific address where the data event originated
    /// @param token The blockchain-specific token address
    /// @param sender The blockchain-specific address that sent the tokens
    /// @param receiver The blockchain-specific address to receive the tokens
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of tokens
    event RouteValue(
        bytes16 uuid,
        string chain,
        bytes emiter,
        bytes indexed token,
        bytes indexed sender,
        bytes indexed receiver,
        uint256 amount
    );
}

/// @title The interface for Graviton oracle parser
/// @notice Parses oracle data about crosschain locking/unlocking events
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface IOracleParserV2 {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice User that can send oracle data
    function nebula() external view returns (address);

    /// @notice Sets address of the user that can send oracle data to `_nebula`
    /// @dev Can only be called by the current owner.
    function setNebula(address _nebula) external;

    /// @notice Address of the contract that routes parsed data to balance keepers
    function router() external view returns (IOracleRouterV2);

    /// @notice Sets address of the oracle router to `_router`
    function setRouter(IOracleRouterV2 _router) external;

    /// @notice TODO
    function isEVM(string calldata chain) external view returns (bool);

    /// @notice TODO
    /// @param chain TODO
    /// @param newBool TODO
    function setIsEVM(string calldata chain, bool newBool) external;

    /// @notice Look up if the data uuid has already been processed
    function uuidIsProcessed(bytes16 uuid) external view returns (bool);

    /// @notice Parses a uint value from bytes
    function deserializeUint(
        bytes memory b,
        uint256 startPos,
        uint256 len
    ) external pure returns (uint256);

    /// @notice Parses an evm address from bytes
    function deserializeAddress(bytes memory b, uint256 startPos)
        external
        pure
        returns (address);

    /// @notice Parses bytes32 from bytes
    function bytesToBytes32(bytes memory b, uint256 offset)
        external
        pure
        returns (bytes32);

    /// @notice Parses bytes16 from bytes
    function bytesToBytes16(bytes memory b, uint256 offset)
        external
        pure
        returns (bytes16);

    /// @notice Compares two strings for equality
    /// @return true if strings are equal, false otherwise
    function equal(string memory a, string memory b)
        external
        pure
        returns (bool);

    /// @notice Parses data from oracles, forwards data to the oracle router
    function attachValue(bytes calldata impactData) external;

    /// @notice Event emitted when the owner changes via `#setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when the nebula changes via `#setNebula`.
    /// @param nebulaOld The account that was the previous nebula
    /// @param nebulaNew The account that became the nebula
    event SetNebula(address indexed nebulaOld, address indexed nebulaNew);

    /// @notice Event emitted when the router changes via `#setRouter`.
    /// @param routerOld The previous router
    /// @param routerNew The new router
    event SetRouter(
        IOracleRouterV2 indexed routerOld,
        IOracleRouterV2 indexed routerNew
    );

    /// @notice TODO
    /// @param chain TODO
    /// @param newBool TODO
    event SetIsEVM(string chain, bool newBool);

    /// @notice Event emitted when the data is parsed and forwarded to the oracle router via `#attachValue`
    /// @param nebula The account that sent the parsed data
    /// @param uuid Unique identifier of the parsed data
    /// @dev UUID is extracted by the oracles to confirm the delivery of data
    /// @param chain Type of blockchain associated with the parsed event, i.e. "EVM"
    /// @param emiter The blockchain-specific address where the parsed event originated
    /// @param topic0 The topic0 of the parsed event
    /// @param token The blockchain-specific token address
    /// @param sender The blockchain-specific address that sent the tokens
    /// @param receiver The blockchain-specific address to receive the tokens
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of tokens
    event AttachValue(
        address nebula,
        bytes16 uuid,
        string chain,
        bytes emiter,
        bytes32 topic0,
        bytes token,
        bytes sender,
        bytes receiver,
        uint256 amount
    );
}


/// @title RelayParser
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract RelayParser is IOracleParserV2 {
    /// @inheritdoc IOracleParserV2
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc IOracleParserV2
    address public override nebula;

    modifier isNebula() {
        require(msg.sender == nebula, "ACN");
        _;
    }

    /// @inheritdoc IOracleParserV2
    IOracleRouterV2 public override router;

    /// @inheritdoc IOracleParserV2
    mapping(bytes16 => bool) public override uuidIsProcessed;

    /// @inheritdoc IOracleParserV2
    mapping(string => bool) public override isEVM;

    constructor(
        IOracleRouterV2 _router,
        address _nebula,
        string[] memory evmChains
    ) {
        owner = msg.sender;
        router = _router;
        nebula = _nebula;
        for (uint256 i = 0; i < evmChains.length; i++) {
            isEVM[evmChains[i]] = true;
        }
    }

    /// @inheritdoc IOracleParserV2
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc IOracleParserV2
    function setNebula(address _nebula) external override isOwner {
        address nebulaOld = nebula;
        nebula = _nebula;
        emit SetNebula(nebulaOld, _nebula);
    }

    /// @inheritdoc IOracleParserV2
    function setRouter(IOracleRouterV2 _router)
        external
        override
        isOwner
    {
        IOracleRouterV2 routerOld = router;
        router = _router;
        emit SetRouter(routerOld, _router);
    }

    /// @inheritdoc IOracleParserV2
    function setIsEVM(string calldata chain, bool newBool)
        external
        override
        isOwner
    {
        isEVM[chain] = newBool;
        emit SetIsEVM(chain, newBool);
    }

    /// @inheritdoc IOracleParserV2
    function deserializeUint(
        bytes memory b,
        uint256 startPos,
        uint256 len
    ) public pure override returns (uint256) {
        uint256 v = 0;
        for (uint256 p = startPos; p < startPos + len; p++) {
            v = v * 256 + uint256(uint8(b[p]));
        }
        return v;
    }

    /// @inheritdoc IOracleParserV2
    function deserializeAddress(bytes memory b, uint256 startPos)
        public
        pure
        override
        returns (address)
    {
        return address(uint160(deserializeUint(b, startPos, 20)));
    }

    /// @inheritdoc IOracleParserV2
    function bytesToBytes32(bytes memory b, uint256 offset)
        public
        pure
        override
        returns (bytes32)
    {
        bytes32 out;
        for (uint256 i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i]) >> (i * 8);
        }
        return out;
    }

    /// @inheritdoc IOracleParserV2
    function bytesToBytes16(bytes memory b, uint256 offset)
        public
        pure
        override
        returns (bytes16)
    {
        bytes16 out;
        for (uint256 i = 0; i < 16; i++) {
            out |= bytes16(b[offset + i]) >> (i * 8);
        }
        return out;
    }

    /// @inheritdoc IOracleParserV2
    function equal(string memory a, string memory b)
        public
        pure
        override
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /// @inheritdoc IOracleParserV2
    function attachValue(bytes calldata data) external override isNebula {
        bytes16 uuid = bytesToBytes16(data, 0); // [  0: 16]
        // @dev parse data only once
        if (uuidIsProcessed[uuid]) {
            return;
        }
        uuidIsProcessed[uuid] = true;
        string memory chain = string(abi.encodePacked(data[16:19])); // [ 16: 19]
        if (isEVM[chain]) {
            bytes memory emiter = data[19:39]; // [ 19: 39]
            bytes1 topics = bytes1(data[39]); // [ 39: 40]
            // @dev ignore data with unexpected number of topics
            if (
                keccak256(abi.encodePacked(topics)) !=
                keccak256(
                    abi.encodePacked(bytes1(abi.encodePacked(uint256(3))[31]))
                )
            ) {
                return;
            }
            bytes32 topic0 = bytesToBytes32(data, 40); // [ 40: 72]
            // bytes memory destinationHash = data[72:104]; // [ 72:104][12:32]
            // bytes memory receiverHash = data[104:136]; // [104:136][12:32]
            uint256 amount = deserializeUint(data, 200, 32); // [200:232]
            string memory destination = string(abi.encodePacked(data[264:296])); // [264:296]
            bytes memory receiver = data[328:360]; // [328:360]

            bytes memory token = new bytes(32);
            bytes memory sender = receiver;

            router.routeValue(
                uuid,
                destination,
                emiter,
                topic0,
                token,
                sender,
                receiver,
                amount
            );

            emit AttachValue(
                msg.sender,
                uuid,
                chain,
                emiter,
                topic0,
                token,
                sender,
                receiver,
                amount
            );
        }
    }
}