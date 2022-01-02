// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract CarchainNFT is ERC721, ERC721Enumerable, Pausable, AccessControl, ERC721Burnable {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    event CarCreated(uint256 indexed _id, address indexed sender, string hash, string make, string model, uint256 year, string vin, string engine, string colour, string plate, uint256 mileage);
    event MileageUpdated(uint256 indexed _id, address indexed sender, uint256 mileage, string hash);
    event ColourUpdated(uint256 indexed _id, address indexed sender, string colour, string hash);
    event PlateUpdated(uint256 indexed _id, address indexed sender, string plate, string hash);
    event EngineUpdated(uint256 indexed _id, address indexed sender, string engine, string hash);
    event EventStated(uint256 indexed _id, address indexed sender, string details, string hash);

    constructor() ERC721("Carchain", "CAR") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://carchain.it/token/";
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    struct Properties {
        string hash;
        string make;
        string model;
        uint256 year;
        string vin;
        string engine;
        string colour;
        string plate;
        uint256 mileage;
    }
    
    mapping(uint256 => Properties) metadata;

    function getMetadata(uint256 _id) external view returns (address owner, string memory hash, string memory make, string memory model, uint256 year, string memory vin, string memory engine, string memory colour, string memory plate, uint256 mileage) {
        Properties memory data = metadata[_id];
        return (ownerOf(_id), data.hash, data.make, data.model, data.year, data.vin, data.engine, data.colour, data.plate, data.mileage);
    }
    
    function mintAndSet(address _to, string memory _hash, string memory _make, string memory _model, uint256 _year, string memory _vin, string memory _engine, string memory _colour, string memory _plate, uint256 _mileage) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        metadata[tokenId].hash = _hash;
        metadata[tokenId].make = _make;
        metadata[tokenId].model = _model;
        metadata[tokenId].year = _year;
        metadata[tokenId].vin = _vin;
        metadata[tokenId].engine = _engine;
        metadata[tokenId].colour = _colour;
        metadata[tokenId].plate = _plate;
        metadata[tokenId].mileage = _mileage;
        
        _safeMint(_to, tokenId);

        emit CarCreated(tokenId, _msgSender(), _hash, _make, _model, _year, _vin, _engine, _colour, _plate, _mileage);
    }
    
    /**
     * @dev Throws if called by any account other than the token or the contract owner.
     */
    modifier onlyCarOwner(uint256 _id) {
        require(ownerOf(_id) == _msgSender() || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Invalid owner");
        _;
    }
    
    function updatePlate(uint256 _id, string memory _plate, string memory _hash) public onlyCarOwner(_id) {
        metadata[_id].plate = _plate;
        metadata[_id].hash = _hash;

        emit PlateUpdated(_id, _msgSender(), _plate, _hash);
    }
    
    function updateEngine(uint256 _id, string memory _engine, string memory _hash) public onlyCarOwner(_id) {
        metadata[_id].engine = _engine;
        metadata[_id].hash = _hash;

        emit EngineUpdated(_id, _msgSender(), _engine, _hash);
    }
    
    function updateMileage(uint256 _id, uint256 _mileage, string memory _hash) public onlyCarOwner(_id) {
        require(metadata[_id].mileage < _mileage, "Invalid number");
        
        metadata[_id].mileage = _mileage;
        metadata[_id].hash = _hash;

        emit MileageUpdated(_id, _msgSender(), _mileage, _hash);
    }
    
    function updateColour(uint256 _id, string memory _colour, string memory _hash) public onlyCarOwner(_id) {
        metadata[_id].colour = _colour;
        metadata[_id].hash = _hash;

        emit ColourUpdated(_id, _msgSender(), _colour, _hash);
    }
    
    function stateEvent(uint256 _id, string memory _details, string memory _hash) public onlyCarOwner(_id) {
        metadata[_id].hash = _hash;

        emit EventStated(_id, _msgSender(), _details, _hash);
    }
}