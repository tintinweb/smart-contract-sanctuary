// SPDX-License-Identifier: UNLICENSED

import "./Collection.sol";

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

contract Bling_Master {
    // Include safemanth library
    using SafeMathUpgradeable for uint256;

    address payable treasury;
    address payable nftmarket;
    address payable admin;

    struct collectionInfo {
        // the collection name
        string name;
        // the collection quantity
        uint256 quantity;
        // the description of the collection
        string description;
        // the properties of the collection
        string[] properties;
        // the contract address
        address myContract;
    }

    constructor(address payable _treasury, address payable _nftMarket) {
        treasury = _treasury;
        nftmarket = _nftMarket;
        admin = msg.sender;
    }

    // collection info mapping
    mapping(address => mapping(string => collectionInfo)) public collections;
    // get collection
    mapping(address => mapping(string => address)) public getCollection;
    mapping(address => string) public getCode;

    mapping(address => bool) public whitelisted;

    event CollectionCreated(
        address creator,
        string ColCode,
        string Colname,
        string ColDescription,
        string[] ColProperties,
        address myContract,
        uint256 quantity
    );

    event CollectionUpdated(
        address creator,
        string ColCode,
        string Colname,
        string ColDescription,
        string[] ColProperties,
        address myContract,
        uint256 quantity
    );

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier onlyWhitelistedUsers() {
        require(whitelisted[msg.sender], "NFT721Mint: Address Not Authorized");
        _;
    }

    /**
     * @notice Allows foundation admin to whitelist users
     */
    function addWhitelist(address[] memory brands) public {
        require(admin == msg.sender);
        for (uint256 i; i < brands.length; i++) {
            whitelisted[brands[i]] = true;
        }
    }

    function createCollection(
        string memory _colCode,
        string memory _colName,
        string memory _colDescription,
        uint256 _colQuantity,
        string[] memory _colProperties
    ) external onlyWhitelistedUsers returns (address collection) {
        // Add require condition to check
        require(
            getCollection[msg.sender][_colCode] == address(0),
            "Bling_Master: COLLECTION_EXISTS"
        ); // single check is sufficient

        bytes memory bytecode = type(Bling_Collection).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, _colCode));

        assembly {
            collection := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        getCollection[msg.sender][_colCode] = collection;
        getCode[collection] = _colCode;
        Bling_Collection(collection).initialize(
            treasury,
            _colName,
            _colName,
            _colQuantity,
            msg.sender
        );
        Bling_Collection(collection).adminUpdateConfig(
            nftmarket,
            "https://ipfs.io/ipfs/"
        );
        collections[msg.sender][_colCode] = collectionInfo({
            name: _colName,
            quantity: _colQuantity,
            description: _colDescription,
            properties: _colProperties,
            myContract: collection
        });

        emit CollectionCreated(
            msg.sender,
            _colCode,
            _colName,
            _colDescription,
            _colProperties,
            collection,
            _colQuantity
        );
    }

    function updateCollection(
        address _colContract,
        string memory _colCode,
        string memory _colName,
        string memory _colDescription,
        string[] memory _colProperties,
        uint256 _totalSupply
    ) external onlyWhitelistedUsers {
        collectionInfo storage collection = collections[msg.sender][_colCode];

        require(
            getCollection[msg.sender][_colCode] == _colContract,
            "Bling_Master: COLLECTION_NOT_EXISTS"
        );
        // Add require condition to check
        require(
            (Bling_Collection(_colContract).getNextTokenId() - 1) == 0,
            "Bling_Master: UPDATE_NOT_ALLOWED"
        ); // single check is sufficient

        collection.name = _colName;
        collection.description = _colDescription;
        collection.properties = _colProperties;
        collection.quantity = _totalSupply;
        Bling_Collection(_colContract).masterUpdateSupply(_totalSupply);

        emit CollectionUpdated(
            msg.sender,
            _colCode,
            _colName,
            _colDescription,
            _colProperties,
            _colContract,
            _totalSupply
        );
    }

    function getCollectionDetails(address user, string memory _code)
        public
        view
        returns (
            string memory,
            string memory,
            string[] memory,
            uint256
        )
    {
        collectionInfo memory collection = collections[user][_code];
        return (
            collection.name,
            collection.description,
            collection.properties,
            collection.quantity
        );
    }
}