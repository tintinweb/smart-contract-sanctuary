pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./ERC721Tradable.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract Creature is ERC721Tradable {

    address payable private _owner;
    uint256 private _currentTokenId = 0;


    uint256 private _basePrice = 0;
    uint256 private constant _protectPrice = 300000000000000000;
    uint256 private constant _imagePrice = 100000000000000000;
    uint256 private constant _simpleTraitPrice = 14000000000000000;
    uint256 private constant _advancedTraitPrice = 35000000000000000;
    uint256 private constant _legendaryTraitPrice = 60000000000000000;

    struct Rick {
        uint256 skin;
        uint256 hair;
        uint256 shirt;
        uint256 pants;
        uint256 shoes;
        uint256 item;
    }


    struct RickProtection {
        uint256 id;
        uint256 value;

    }

    bytes32 constant RICK_TYPEHASH = keccak256(
        "Rick(uint skin, uint hair, uint shirt, uint pants, uint shoes, uint item)"
    );

    bytes32 constant RICKPROTECTION_TYPEHASH = keccak256(
        "RickProtection(uint id, uint value)"
    );

    mapping (uint => Rick) private _ricks;
    mapping (uint => string) private _image;
    mapping (uint => string) private _name;

    //hash => rickId
    mapping (bytes32 => bool) private _rickHash;
    mapping (bytes32 => bool) private _rickProtectionHash;

    constructor(address _proxyRegistryAddress)
    public
    ERC721Tradable("CryptoRick", "RICKS", _proxyRegistryAddress)
    {
        _owner = msg.sender;

    }

    function craftRick(Rick memory rick) public returns (uint){
        require(msg.sender == _owner);

        uint nextId = _getNextTokenId();
        _safeMint(msg.sender, nextId);
        _incrementTokenId();

        bytes32 rickHash = hash(rick);
        _ricks[nextId] = rick;
        _rickHash[rickHash] = true;

        return nextId;
    }

    function getImage(uint rickId) public view returns (string memory){
        return _image[rickId];
    }

    function totalSupply() public view returns (uint256) {
        return 1024;
    }

    function hash(Rick memory _rick) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            RICK_TYPEHASH,
            _rick.skin,
            _rick.hair,
            _rick.shirt,
            _rick.pants,
            _rick.shoes
        ));
    }

    function hashProtection(RickProtection memory _rickProt) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            RICKPROTECTION_TYPEHASH,
            _rickProt.id,
            _rickProt.value
        ));
    }

    function _getNextTokenId() private view returns (uint256) { return _currentTokenId.add(1); }
    function _incrementTokenId() private { _currentTokenId++; }
    function getCurrentTokenId() public view returns (uint256) { return _currentTokenId; }

    function getRick(uint rickId) public view returns (Rick memory) {
        return _ricks[rickId];
    }

    function getName(uint rickId) public view returns (string memory){
        return _name[rickId];
    }

    function setName(
        uint rickId,
        string memory name
    ) public payable {
        require(ownerOf(rickId) == msg.sender, "RICK-08");
        require(msg.value >= 50000000000000000, "RICK-09");

        _name[rickId] = name;
    }

    function buyRick(
        Rick memory _rick,
        string memory image,
        uint[] memory protectedTraitIds
    ) public payable {

        /*
            Validate the Input!
            We throw our own RICK-XX error code to handle the frontend output.
        */
        //check for remaining ricks
        require(_currentTokenId < totalSupply(), "RICK-00");

        //is the rick uniq ?
        bytes32 rickHash = hash(_rick);
        require(_rickHash[rickHash] == false, "RICK-01");

        require(msg.value >= getPriceForRick(_rick, bytes(image).length > 0, protectedTraitIds.length), "RICK-02");

        bytes32 hashHair = hashProtection(RickProtection(1, _rick.hair));
        require(_rickProtectionHash[hashHair] == false, "RICK-03");

        bytes32 hashShirt = hashProtection(RickProtection(2, _rick.shirt));
        require(_rickProtectionHash[hashShirt] == false, "RICK-04");

        bytes32 hashPants = hashProtection(RickProtection(3, _rick.pants));
        require(_rickProtectionHash[hashPants] == false, "RICK-05");

        bytes32 hashShoes = hashProtection(RickProtection(4, _rick.shoes));
        require(_rickProtectionHash[hashShoes] == false, "RICK-06");

        bytes32 hashItem = hashProtection(RickProtection(5, _rick.item));
        require(_rickProtectionHash[hashItem] == false, "RICK-07");

        /*
            Mint the new Token
        */
        uint nextId = _getNextTokenId();
        _safeMint(msg.sender, nextId);
        _incrementTokenId();

        /*
            Save rick
        */
        _image[nextId] = image;
        _ricks[nextId] = _rick;
        _rickHash[rickHash] = true;

        /*
            Protect the traits
        */
        for (uint i = 0; i < protectedTraitIds.length; i++) {
            uint val = protectedTraitIds[i];

            if (val == 1) _rickProtectionHash[hashHair] = true;
            if (val == 2) _rickProtectionHash[hashShirt] = true;
            if (val == 3) _rickProtectionHash[hashPants] = true;
            if (val == 4) _rickProtectionHash[hashShoes] = true;
            if (val == 5) _rickProtectionHash[hashItem] = true;
        }

        //update basePrice
        if      (nextId == 50  ) _basePrice = 20000000000000000;
        else if (nextId == 250 ) _basePrice = 50000000000000000;
        else if (nextId == 500 ) _basePrice = 70000000000000000;
        else if (nextId == 1000) _basePrice = 100000000000000000;

    }

    function getPriceForRick(Rick memory rick, bool withImage, uint protectedTraits) internal view returns(uint){

        uint price = _basePrice;
        if (withImage) price += _imagePrice;
        if(protectedTraits > 0) price += _protectPrice * protectedTraits;

        if (rick.skin > 8) price += _legendaryTraitPrice;       //legendary  (9 - 13)
        else if (rick.skin > 4) price += _advancedTraitPrice;   //advanced   (5 - 8 )
        else price += _simpleTraitPrice;                        //simple     (1 - 4 )

        if (rick.hair > 40) price += _legendaryTraitPrice;       //legendary  (41 - 50)
        else if (rick.hair > 25) price += _advancedTraitPrice;   //advanced   (26 - 40 )
        else price += _simpleTraitPrice;                        //simple     (1 - 25 )

        if (rick.shirt > 40) price += _legendaryTraitPrice;       //legendary (41 - 50)
        else if (rick.shirt > 25) price += _advancedTraitPrice;   //advanced  (26 - 40 )
        else price += _simpleTraitPrice;                         //simple    (1 - 25 )

        if (rick.pants > 40) price += _legendaryTraitPrice;       //legendary (41 - 50)
        else if (rick.pants > 25) price += _advancedTraitPrice;   //advanced  (26 - 40 )
        else price += _simpleTraitPrice;                         //simple    (1 - 25 )

        if (rick.shoes > 40) price += _legendaryTraitPrice;       //legendary (41 - 50)
        else if (rick.shoes > 25) price += _advancedTraitPrice;   //advanced  (26 - 40 )
        else price += _simpleTraitPrice;                         //simple    (1 - 25)

        if (rick.item > 25) price += _legendaryTraitPrice;       //legendary (26 - 50)
        else if (rick.item > 0) price += _advancedTraitPrice;   //advanced  (1 - 25 )

        return price;

    }

    function withdraw(uint256 amount) public {
        require(msg.sender == _owner);
        msg.sender.transfer(amount);
    }

    function baseTokenURI() public pure returns (string memory) {
        return "https://www.crypto-ricks.com/api/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.crypto-ricks.com/contract";
    }

}