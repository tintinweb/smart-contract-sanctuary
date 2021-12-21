// SPDX-License-Identifier: UNLICENSED

import "./collection.sol";

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

contract BlingMaster {
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
        // the beneficiary address
        address payable beneficiary;
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
    mapping(address => string) public brandName;

    mapping(address => bool) public whitelisted;

    event CollectionCreated(
        address creator,
        string ColCode,
        string Colname,
        string ColDescription,
        string[] ColProperties,
        address myContract,
        uint256 quantity,
        address beneficiary
    );

    event Whitelist(address[] brand, string[] name, bool[] status);

    event CollectionUpdated(
        address creator,
        string ColCode,
        string Colname,
        string ColDescription,
        string[] ColProperties,
        address myContract,
        uint256 quantity,
        address beneficiary
    );

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier onlyWhitelistedUsers() {
        require(
            whitelisted[msg.sender],
            "BlingMaster: Address Not Authorized"
        );
        _;
    }

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier onlyOwner() {
        require(
            IAdminRole(treasury).isAdmin(msg.sender),
            "BlingMaster: Address Not Authorized"
        );
        _;
    }

    /**
     * @notice Allows foundation admin to whitelist users
     */
    function updateWhitelist(
        address[] memory brands,
        string[] memory name,
        bool[] memory status
    ) public onlyOwner {
        for (uint256 i; i < brands.length; i++) {
            whitelisted[brands[i]] = status[i];
            brandName[brands[i]] = name[i];
        }
        emit Whitelist(brands, name, status);
    }

    function createCollection(
        string memory _colCode,
        string memory _colName,
        string memory _colDescription,
        uint256 _colQuantity,
        string[] memory _colProperties,
        address payable _beneficiary
    ) external onlyWhitelistedUsers returns (address collection) {
        // Add require condition to check
        require(
            getCollection[msg.sender][_colCode] == address(0),
            "BlingMaster: COLLECTION_EXISTS"
        ); // single check is sufficient

        bytes memory bytecode = type(BlingCollection).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, _colCode));

        assembly {
            collection := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        getCollection[msg.sender][_colCode] = collection;
        getCode[collection] = _colCode;
        BlingCollection(collection).initialize(
            treasury,
            _colCode,
            _colCode,
            _colQuantity,
            msg.sender
        );
        BlingCollection(collection).adminUpdateConfig(
            nftmarket,
            "https://ipfs.io/ipfs/"
        );
        collections[msg.sender][_colCode] = collectionInfo({
            name: _colName,
            quantity: _colQuantity,
            description: _colDescription,
            properties: _colProperties,
            myContract: collection,
            beneficiary: _beneficiary
        });

        emit CollectionCreated(
            msg.sender,
            _colCode,
            _colName,
            _colDescription,
            _colProperties,
            collection,
            _colQuantity,
            _beneficiary
        );
    }

    function updateCollection(
        address _colContract,
        string memory _colCode,
        string memory _colName,
        string memory _colDescription,
        string[] memory _colProperties,
        uint256 _totalSupply,
        address payable _beneficiary
    ) external onlyWhitelistedUsers {
        collectionInfo storage collection = collections[msg.sender][_colCode];

        require(
            getCollection[msg.sender][_colCode] == _colContract,
            "BlingMaster: COLLECTION_NOT_EXISTS"
        );
        // Add require condition to check
        require(
            (BlingCollection(_colContract).getNextTokenId() - 1) == 0,
            "BlingMaster: UPDATE_NOT_ALLOWED"
        ); // single check is sufficient

        collection.name = _colName;
        collection.description = _colDescription;
        collection.properties = _colProperties;
        collection.quantity = _totalSupply;
        collection.beneficiary = _beneficiary;
        BlingCollection(_colContract).adminUpdateSupply(_totalSupply);

        emit CollectionUpdated(
            msg.sender,
            _colCode,
            _colName,
            _colDescription,
            _colProperties,
            _colContract,
            _totalSupply,
            _beneficiary
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

    function updateAdminConfig(
        address _colContract,
        string memory _colCode,
        address _nftMarket,
        string memory baseURI
    ) public onlyOwner {
        require(
            getCollection[msg.sender][_colCode] == _colContract,
            "BlingMaster: COLLECTION_NOT_EXISTS"
        );
        BlingCollection(_colContract).adminUpdateConfig(_nftMarket, baseURI);
    }
}