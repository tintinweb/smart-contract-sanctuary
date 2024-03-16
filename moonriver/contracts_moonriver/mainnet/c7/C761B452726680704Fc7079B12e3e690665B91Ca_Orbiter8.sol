pragma solidity >=0.5.0 <0.6.0;

import "./StarSystems/StarSystemLibrary.sol";
import "./StarSystems/Avatar/AvatarControls.sol";

//todo: should 'requires' be in this contact?

contract Orbiter8 {
    using StarSystemLibrary for StarSystemLibrary.Galaxy;
    using StarSystemLibrary for StarSystemLibrary.StarSystem;
    StarSystemLibrary.Galaxy galaxy;

    AvatarControls private avatarControls;


    event ChatLog(address _sender, string _message);
    function sendChat(string memory message) public {
        emit ChatLog(msg.sender, message);
    }

    /** connection to tokens contract for tracking planets */
    function setPlanetTokenizer(address tokenAddress) public {
        galaxy.setPlanetTokenizer(tokenAddress);
    }
    function getPlanetTokenizer() public view returns (address) {
        return galaxy.getPlanetTokenizer();
    }

    /** connection to tokens contract for tracking ships */
    function setShipTokenizer(address tokenAddress) public {
        galaxy.setShipTokenizer(tokenAddress);
    }
    function getShipTokenizer() public view returns (address) {
        return galaxy.getShipTokenizer();
    }


    /** connection to tokens contract for tracking credits */
    function setCreditTokenizer(address tokenAddress) public {
        galaxy.setCreditTokenizer(tokenAddress);
    }
    function getCreditTokenizer() public view returns (address) {
        return galaxy.getCreditTokenizer();
    }
    function myBalance() external view returns (uint256) {
        return galaxy.balanceOf(msg.sender);
    }

    function setAvatarControls(address avatarControlsAddress) public {
        avatarControls = AvatarControls(avatarControlsAddress);
        avatarControls.createAvatar('Great Daemon');
    }

    /** this method must be called to initialize the galaxy */
    function genesis() public {
        galaxy.genesis();
    }

    /** this method must be called to initialize the first solar system */
    function makeSolarSystem() public {
        galaxy.makeSolarSystem();
    }

    /** Avatars */
    // function createAvatar(string memory name) public {
    //    galaxy.createAvatar(name);
    // }

    /** Ship */
    function getShip(
        uint256 shipId
    ) external view returns (
        string memory,
        uint,
        uint,
        address
    ) {
        return galaxy.getShip(shipId);
    }

    event ShipLaunch(string _name);
    function launchShip(string memory name) public {
        galaxy.launchShip(name);
        //todo: this shouldn't stay here, just a way to inject some credits
        galaxy.awardCredits(msg.sender, 100);
        emit ShipLaunch(name);
    }

    function renameMyShip(string memory name) public {
        galaxy.renameMyShip(name);
    }

    /** Planets */

    function getPlanet(
        uint256 planetId
    ) external view returns (
        string memory,
        uint256,
        uint8[4] memory,
        address,
        bool[8] memory,
        bool
    ) {
        return galaxy.getPlanet(planetId);
    }

    function renamePlanet(uint256 id, string memory name) public {
        galaxy.renamePlanet(id, name);
    }

    function claimPlanet(
        uint256 planetId,
        string memory planetName
    ) public {
        return galaxy.claimPlanet(planetId, planetName);
    }

    function buildStation (
        uint256 planetId,
        string memory stationName
    ) public {
        galaxy.buildStation(planetId, stationName);
    }

    /** get planet by system's planet id rather than global planet id */
    function getLocalPlanet(
        uint256 orbitalId
    ) external view returns (
        string memory,
        uint256,
        uint8[4] memory,
        address,
        bool[8] memory,
        bool
    ) {
        return galaxy.getLocalPlanet(orbitalId);
    }

    /** moons */

    function getMoon(
        uint256 planetId,
        uint8 moonId
    ) external view returns (
        string memory,
        uint8,
        uint8,
        uint8
        //address
    ) {
        return galaxy.getMoon(planetId, moonId);
    }

    function renameMoon(
        uint256 planetId,
        uint8 moonId,
        string memory name
    ) public {
        galaxy.renameMoon(planetId, moonId, name);
    }

    /** Space Stations */

    function getStation(
        uint256 planetId
    ) external view returns (
        string memory,
        uint8,
        int16[3] memory,
        uint16[4] memory
    ) {
        return galaxy.getStation(planetId);
    }

    function renameStation(uint256 id, string memory name) public {
        galaxy.renameStation(id, name);
    }

    function addPortToStation(uint256 id) public {
        galaxy.addPortToStation(id);
    }

    event PortTrade(address _sender, uint _planetId, int16 _equipment, int16 _fuel, int16 _organics, int _value);
    function tradeAtPort(
        uint256 planetId,
        int16 equipment,
        int16 fuel,
        int16 organics
    ) public {
        int tradeValue = galaxy.tradeAtPort(planetId, equipment, fuel, organics);
        emit PortTrade(msg.sender, planetId, equipment, fuel, organics, tradeValue);
    }

    function addHoldsToShip(
        uint256 planetId,
        uint8 holds
    ) public {
        galaxy.addHoldsToShip(planetId, holds);
    }

    /** Galaxy */
    function moveToSystem(uint256 destinationSystemId) public  {
        galaxy.moveToSystem(destinationSystemId);
    }

    function getSystemCount() public view returns(uint256) {
        return galaxy.getStarSystemCount();
    }

    function getMyShipLocation() public view returns(uint256) {
        return galaxy.getMyShipLocation();
    }

    function getMyShipId() public view returns(uint256) {
        return galaxy.getMyShipId();
    }

    function getMyShip() public view returns(
        string memory, //name
        uint,          //star system
        uint,          //orbit
        uint8,         //cargo limit
        uint8,         //equipment
        uint8,         //fuel
        uint8          //organics
    ) {
        return galaxy.getMyShip();
    }

    function getPlayerSystemData() public view returns(
        uint256,
        string memory,
        uint8,
        uint256,
        address,
        uint256[12] memory,
        uint256[14] memory,
        uint256[30] memory
    ) {
        return galaxy.getSystemData(galaxy.getMyShipLocation());
    }

    function getSystemName(uint256 systemId) public view returns(
        string memory
    ) {
        return galaxy.getSystemName(systemId);
    }

    function renameStar(string memory name) public {
        galaxy.renameStar(name);
    }


}

pragma solidity >=0.5.0 <0.6.0;

library HelperLibrary {

    struct Helper {
        uint helperNonce;
    }

    //TODO: look for other random number generation options
    function getRandom(Helper memory help) internal view returns(uint) {
        help.helperNonce += 1;
        return uint(
            keccak256(
                abi.encodePacked(
                    help.helperNonce,
                    msg.sender,
                    blockhash(block.number - 1)
                )
            )
        );
    }

}

pragma solidity ^0.5.16;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
//import './NFTs.sol';

contract ShipTokens is ERC721Full, Ownable {

    constructor() ERC721Full("Starships - Orbiter 8 Alpha 3.4", "O8SHIPS") public {
        //_setBaseURI("https://orbiter8.com/tokens/");
    }

    /**
     * overriding method
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked("https://orbiter8.com/tokens/ship/", uint2str(tokenId)));
    }

    function mintShip(uint256 shipId, address owner) public onlyOwner {
        _mint(owner, shipId);
        _setTokenURI(shipId, uint2str(shipId));
    }

    // todo: move to a library or something
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

pragma solidity ^0.5.16;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
//import './NFTs.sol';

contract PlanetTokens is ERC721Full, Ownable {

    constructor() ERC721Full("Planets -Orbiter 8 Alpha 3.4", "O8PLANETS") public {
        //_setBaseURI("https://orbiter8.com/tokens/");
    }

    /**
     * overriding method
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked("https://orbiter8.com/tokens/planet/", uint2str(tokenId)));
    }

    function mintPlanet(uint256 planetId) public onlyOwner {
        _mint(owner(), planetId);
        _setTokenURI(planetId, uint2str(planetId));
    }

    function mintPlanetForUser(address owner, uint256 planetId) public onlyOwner {
        _mint(owner, planetId);
    }

    function awardPlanet(address benefactor , uint256 planetId) public onlyOwner {
        _transferFrom(owner(), benefactor, planetId);
    }

    // todo: move to a library or something
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

}

pragma solidity ^0.5.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract Credits is ERC20, ERC20Detailed, Ownable {
    constructor() ERC20Detailed("Pan-Galactic Credits -Orbiter 8 Alpha 3.4", "", 0) public {
    }

    function awardCredits(address player, uint256 amount) public onlyOwner {
        _mint(player, amount);
    }

    function spendCredits(address player, uint256 amount) public onlyOwner {
        _burn(player, amount);
    }

    function tokenURI() external pure returns (string memory) {
        return "https://orbiter8.com/tokens/credits";
    }
}

pragma solidity >=0.5.0 <0.6.0;

library PresetLibrary {

    uint8 public constant nothing = 0;
    uint8 public constant planet = 1;
    uint8 public constant moon = 2;
    uint8 public constant station = 3;

    uint8 public constant objectType = 0;
    uint8 public constant size = 1;
    uint8 public constant class = 2;
    uint8 public constant rings = 3;
    uint8 public constant slot = 3;
    uint8 public constant speed = 4;

    /* check type */

    function isNothing(uint8 id) external pure returns (
        bool
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[objectType] == nothing;
    }

    function isPlanet(uint8 id) external pure returns (
        bool
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[objectType] == planet;
    }

    function isMoon(uint8 id) external pure returns (
        bool
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[objectType] == moon;
    }

    function isStation(uint8 id) external pure returns (
        bool
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[objectType] == station;
    }

    /* get values */

    function getName(uint8 id) external pure returns (
        string memory
    ) {
        (string memory name, ) = getSolarSystem(id);
        return name;
    }

    function getSize(uint8 id) external pure returns (
        uint8
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[size];
    }

    function getClass(uint8 id) external pure returns (
        uint8
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[class];
    }

    function getRings(uint8 id) external pure returns (
        uint8
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[rings];
    }

    function getSlot(uint8 id) external pure returns (
        uint8
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[slot];
    }

    function getSpeed(uint8 id) external pure returns (
        uint8
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[speed];
    }

    /* get whole object */
    //TODO: make this a datastructure and reduce contract size
    function getSolarSystem(
        uint8 index
    ) internal pure returns(
        string memory, // name
        uint8[5] memory
    ) {
        if (index == 0) {
            return (
                'Mercury', [
                    planet,
                    3,   //size
                    1,   //class K, Desert Wasteland
                    0,   //rings
                    250  //orbital speed
                ]
            );
        }

        if (index == 1) {
             return (
                'Icarus', [
                    station,
                    1,   //size
                    0,   //class
                    0,   //
                    15   //oribtal speed
                ]
            );
        }

        if (index == 2) {
            return (
                'Venus', [
                    planet,
                    12,  //size
                    5,   //class H, Volcanic
                    0,   //rings
                    83   //orbital speed
                ]
            );
        }

        if (index == 3) {
            return (
                'Port Hesperus', [
                    station,
                    1,   //size
                    0,   //class
                    1,   //slot
                    15   //orbital speed
                ]
            );
        }

        if (index == 4) {
            return (
                'Earth', [
                    planet,
                    12,  //size
                    0,   //class M, Earthline
                    0,   //rings
                    50   //orbital speed
                ]
            );
        }

        if (index == 5) {
            return (
                'I.S.S.', [
                    station,
                    6,   //size
                    0,   //class
                    0,   //
                    10   //orbital speed
                ]
            );
        }

        if (index == 6) {
            return (
                'Luna', [
                    moon,
                    10,   //size
                    1,   //class K, Desert Wasteland
                    1,   //slot
                    100   //orbital speed
                ]
            );
        }

        if (index == 7) {
            return (
                'Mars', [
                    planet,
                    6,   //size
                    1,   //class K, Desert Wasteland
                    0,   //rings
                    26   //orbital speed
                ]
            );
        }

        if (index == 8) {
            return (
                'Tiangong', [
                    station,
                    4,   //size
                    4,   //class K, Desert Wasteland
                    0,   //
                    15   //orbital speed
                ]
            );
        }

        if (index == 9) {
            return (
                'Phobos', [
                    moon,
                    1,   //size
                    1,   //class K, Desert Wasteland
                    0,   //slot
                    185  //orbital speed
                ]
            );
        }

        if (index == 10) {
            return (
                'Deimos', [
                    moon,
                    1,   //size
                    1,   //class K, Desert Wasteland
                    3,   //slot
                    42   //orbital speed
                ]
            );
        }

        if (index == 11) {
            return (
                'Jupiter', [
                    planet,
                    54,  //size
                    6,   //class U, Gas / Vapor
                    0,   //rings
                    5    //orbital speed
                ]
            );
        }

        if (index == 12) {
            return (
                'Tycho Station', [
                    station,
                    12,  //size
                    0,   //class
                    0,   //
                    7    //orbital speed
                ]
            );
        }

        if (index == 13) {
            return (
                'Io', [
                    moon,
                    10,   //size
                    1,   //class K, Desert Wasteland
                    1,   //slot
                    41   //orbital speed
                ]
            );
        }

        if (index == 14) {
            return (
                'Europa', [
                    moon,
                    8,   //size
                    1,   //class K, Desert Wasteland
                    2,   //slots
                    42   //orbital speed
                ]
            );
        }

        if (index == 15) {
            return (
                'Ganymede', [
                    moon,
                    14,   //size
                    1,    //class K, Desert Wasteland
                    3,    //slot
                    56    //orbital speed
                ]
            );
        }

        if (index == 16) {
            return (
                'Callisto', [
                    moon,
                    14,   //size
                    1,    //class K, Desert Wasteland
                    4,    //slot
                    26    //orbital speed
                ]
            );
        }

        if (index == 17) {
            return (
                'Saturn', [
                    planet,
                    36,  //size
                    6,   //class U, Gas / Vapor
                    10,  //rings
                    4    //orbital speed
                ]
            );
        }

        if (index == 18) {
            return (
                'Ticonderoga', [
                    station,
                    10,  //size
                    1,   //class
                    0,   //
                    15   //orbital speed
                ]
            );
        }

        if (index == 19) {
            return (
                'Enceladus', [
                    moon,
                    3,   //size
                    1,   //class K, Desert Wasteland
                    0,   //slot
                    111  //orbital speed
                ]
            );
        }

        if (index == 20) {
            return (
                'Tethys', [
                    moon,
                    3,   //size
                    1,   //class K, Desert Wasteland
                    1,   //slot
                    46   //orbital speed
                ]
            );
        }

        if (index == 21) {
            return (
                'Dione', [
                    moon,
                    3,   //size
                    1,   //class K, Desert Wasteland
                    2,   //slot
                    21   //orbital speed
                ]
            );
        }

        if (index == 22) {
            return (
                'Rhea', [
                    moon,
                    5,   //size
                    1,   //class K, Desert Wasteland
                    3,   //slot
                    71   //orbital speed
                ]
            );
        }

        if (index == 23) {
            return (
                'Titan', [
                    moon,
                    14,   //size
                    1,   //class K, Desert Wasteland
                    4,   //slot
                    67   //orbital speed
                ]
            );
        }

        if (index == 24) {
            return (
                'Iapetus', [
                    moon,
                    5,   //size
                    1,   //class K, Desert Wasteland
                    5,   //slot
                    31   //orbital speed
                ]
            );
        }

        if (index == 25) {
            return (
                'Uranus', [
                    planet,
                    24,  //size
                    4,   //class C, Glacial / Ice
                    1,   //rings
                    3    //orbital speed
                ]
            );
        }

        if (index == 26) {
            return (
                'Oberon', [
                    station,
                    3,   //size
                    0,   //class
                    0,   //
                    15   //orbital speed
                ]
            );
        }

        if (index == 27) {
            return (
                'Puck', [
                    moon,
                    1,   //size
                    1,   //class K, Desert Wasteland
                    0,   //slot
                    29   //orbital speed
                ]
            );
        }

        if (index == 28) {
            return (
                'Miranda', [
                    moon,
                    3,   //size
                    1,   //class K, Desert Wasteland
                    1,   //slot
                    5    //orbital speed
                ]
            );
        }

        if (index == 29) {
            return (
                'Ariel', [
                    moon,
                    5,   //size
                    1,   //class K, Desert Wasteland
                    2,   //slot
                    33   //orbital speed
                ]
            );
        }

        if (index == 30) {
            return (
                'Umbriel', [
                    moon,
                    5,   //size
                    1,   //class K, Desert Wasteland
                    3,   //slot
                    10   //orbital speed
                ]
            );
        }

        if (index == 31) {
            return (
                'Titania', [
                    moon,
                    5,   //size
                    1,   //class K, Desert Wasteland
                    4,   //slot
                    41   //orbital speed
                ]
            );
        }

        if (index == 32) {
            return (
                'Oberon', [
                    moon,
                    5,   //size
                    1,   //class K, Desert Wasteland
                    5,   //slot
                    20   //orbital speed
                ]
            );
        }

        if (index == 33) {
            return (
                'Neptune', [
                    planet,
                    24,  //size
                    4,   //class C, Glacial / Ice
                    0,   //rings
                    10   //orbital speed
                ]
            );
        }

        if (index == 34) {
            return (
                'Terra Venture', [
                    station,
                    3,   //size
                    0,   //class
                    0,   //
                    15   //orbital speed
                ]
            );
        }

        if (index == 35) {
            return (
                'Proteus', [
                    moon,
                    1,   //size
                    1,   //class K, Desert Wasteland
                    1,   //slot
                    25   //orbital speed
                ]
            );
        }

        if (index == 36) {
            return (
                'Triton', [
                    moon,
                    9,   //size
                    1,   //class K, Desert Wasteland
                    2,   //slot
                    22   //orbital speed
                ]
            );
        }

        if (index == 37) {
            return (
                'Nereid', [
                    moon,
                    1,   //size
                    1,   //class K, Desert Wasteland
                    3,   //slot
                    28   //orbital speed
                ]
            );
        }

        if (index == 38) {
            return (
                'Pluto', [
                    planet,
                    1,   //size
                    1,   //class K, Desert Wasteland
                    0,   //rings or slots
                    1    //orbital speed
                ]
            );
        }

        if (index == 39) {
            return (
                'Nerva Beacon', [
                    station,
                    1,   //size
                    1,   //class
                    0,   //
                    15    //orbital speed
                ]
            );
        }

        if (index == 40) {
            return (
                'Charon', [
                    moon,
                    1,   //size
                    1,   //class K, Desert Wasteland
                    3,   //slot
                    21   //orbital speed
                ]
            );
        }

        return (
            '', [
                nothing,
                0,
                0,
                0,
                0
            ]
        );
    }
}

pragma solidity >=0.5.0 <0.6.0;

import "../../../Tokens/ShipTokens.sol";
//import "@openzeppelin/contracts/math/SafeMath.sol";

library ShipLibrary {

    /**************************************
    *
    * MODELS
    *
    ***************************************/

    uint8 public constant maxHolds = 250;

    // Structures
    struct Ship {
        string name;
        uint currentStarSystem;
        uint256 currentOrbit;
        uint8 cargoLimit;
        uint8 equipment;
        uint8 fuel;
        uint8 organics;
    }

    struct ShipStorage {
        address shipTokensAddress;
        Ship[] ships;
        mapping (address => uint) ownerToOccupiedShip;
        //todo: could be a value on the avatar instead of this mapping
    }

    // Modifiers
    modifier mustOwnShip (
        ShipStorage storage self,
        uint256 shipId
    ) {
        require(ShipTokens(self.shipTokensAddress).ownerOf(shipId) == msg.sender, 'Must be your ship.');
        _;
    }

    /**************************************
    *
    * VIEWS
    *
    ***************************************/

    function getMyShip(ShipStorage storage self) internal view returns(
        string memory, //name
        uint,          //star system
        uint,          //orbit
        uint8,         //cargo limit
        uint8,         //equipment
        uint8,         //fuel
        uint8          //organics
    )  {
        uint shipId = self.ownerToOccupiedShip[msg.sender];
        return (
            self.ships[shipId].name,
            self.ships[shipId].currentStarSystem,
            self.ships[shipId].currentOrbit,
            self.ships[shipId].cargoLimit,
            self.ships[shipId].equipment,
            self.ships[shipId].fuel,
            self.ships[shipId].organics
        );
    }

    function getMyShipId(ShipStorage storage self) internal view returns(uint)  {
        return self.ownerToOccupiedShip[msg.sender];
    }

    function getMyShipLocation(ShipStorage storage self) internal view returns(uint)  {
        uint shipId = self.ownerToOccupiedShip[msg.sender];
        return self.ships[shipId].currentStarSystem;
    }

    function getMyShipName(ShipStorage storage self) internal view returns(string memory) {
        uint shipId = self.ownerToOccupiedShip[msg.sender];
        return self.ships[shipId].name;
    }

    function getShipTokenizer(ShipStorage storage self) internal view returns(address) {
        return self.shipTokensAddress;
    }

    //todo: should probably only display cargo for own ship
    function getShip(
        ShipStorage storage self,
        uint256 shipId
    ) internal view returns(
        string memory, //name
        uint,          //star system
        uint,          //orbit
        address        //owner
    )  {
        return (
            self.ships[shipId].name,
            self.ships[shipId].currentStarSystem,
            self.ships[shipId].currentOrbit,
            ShipTokens(self.shipTokensAddress).ownerOf(shipId)
        );
    }

    /**************************************
    *
    * CONTROLS
    *
    ***************************************/

    function setShipTokenizer(
        ShipStorage storage self,
        address tokenAddress
    ) public {
        self.shipTokensAddress = tokenAddress;
    }

    function createMyShip(
        ShipStorage storage self,
        string memory _name
    ) internal returns (uint) {
        uint shipId = self.ships.push(Ship(
            _name,
            1, //sol
            3, //earth
            5,//holds
            1, //equipment
            1, //fuel
            1) //organics
        )-1;
        //auto occupy
        self.ownerToOccupiedShip[msg.sender] = shipId;
        //mint token
        ShipTokens(self.shipTokensAddress).mintShip(shipId, msg.sender);

        return shipId;
    }

    function addHolds(
        ShipStorage storage self,
        uint8 holds
    ) internal {
        uint shipId = self.ownerToOccupiedShip[msg.sender];
        require ((uint256(self.ships[shipId].cargoLimit) + uint256(holds)) <= maxHolds, "Maxed Out");
        self.ships[shipId].cargoLimit += holds;
        //TODO: replace this with safe math
    }

    function setMyShipOrbit (
        ShipStorage storage self,
        uint256 orbit
    ) internal  {
        uint shipId = self.ownerToOccupiedShip[msg.sender];
        self.ships[shipId].currentOrbit = orbit;
    }

    function boardShip(ShipStorage storage self, uint _shipId) internal mustOwnShip(self, _shipId) {
        self.ownerToOccupiedShip[msg.sender] = _shipId;
    }

    function moveMyShip(ShipStorage storage self, uint256 _systemId) internal {
        self.ships[self.ownerToOccupiedShip[msg.sender]].currentStarSystem = _systemId;
        self.ships[self.ownerToOccupiedShip[msg.sender]].currentOrbit = 0;
    }

    function renameMyShip(ShipStorage storage self, string memory _newName) internal {
        uint shipId = self.ownerToOccupiedShip[msg.sender];
        self.ships[shipId].name = _newName;
    }

    function modifyMyShipCargo(
        ShipStorage storage self,
        int16 equipment,
        int16 fuel,
        int16 organics
    ) internal {
        uint shipId = self.ownerToOccupiedShip[msg.sender];

        self.ships[shipId].equipment = modifiedCargo(self.ships[shipId].equipment, equipment);
        self.ships[shipId].fuel = modifiedCargo(self.ships[shipId].fuel, fuel);
        self.ships[shipId].organics = modifiedCargo(self.ships[shipId].organics, organics);
        uint newCargoLoad = uint(self.ships[shipId].equipment + self.ships[shipId].fuel + self.ships[shipId].organics);
        require(newCargoLoad <= self.ships[shipId].cargoLimit, 'Too much cargo.');
    }

    function modifiedCargo(uint16 current, int16 change) internal pure returns (uint8) {
        int256 finalVal = int256(current) + int256(change);
        require (finalVal >= 0, 'over sold');
        return uint8(finalVal);
    }

}

pragma solidity >=0.5.0 <0.6.0;

import "../../../Tokens/PlanetTokens.sol";

library PlanetLibrary {

    /**************************************
    *
    * MODELS
    *
    ***************************************/

    uint16 public constant costPerHold = 250;

    // Structures
    struct Planet {
        string name;
        uint256 star;
        uint8 size;
        uint8 class;
        uint8 rings;
        uint8 orbitSpeed;
    }
    struct Station {
        string name;
        uint8 size;
        //ship yards: modify ship
        PortOfTrade port; //port of trade: buy/sell goods
        //transport hub: transfer humans
    }
    //todo: these should become a libraries
    struct PortOfTrade {
        SupplyOfGood equipment;
        SupplyOfGood fuel;
        SupplyOfGood organics;
        uint256 lastTradeTime;
    }
    struct SupplyOfGood {
        int16 inventory;        //  100 = selling | -100 = buying
        int16 supplyCap; // -2000 = always needing more | 2000 = always producing more
    }
    struct TransportHub {
        SupplyOfGood people; // related to planet's population needs
    }
    struct ShipYard {
        uint8 size; // the larger they are, the more services they offer
    }

    struct PlanetStorage {
        address planetTokensAddress;
        Planet[] planets;
        mapping (uint256 => Station) stations;
        mapping (uint256 => TransportHub) hubs;
        mapping (uint256 => PortOfTrade) ports;
        mapping (uint256 => ShipYard) yards;
    }

    // Modifiers
    modifier mustBeUnclaimed (
        PlanetStorage storage self,
        uint256 planetId
    ) {
        require(PlanetTokens(self.planetTokensAddress).ownerOf(planetId) == address(this), 'Must be unclaimed planet.');
        _;
    }
    modifier mustOwnPlanet (
        PlanetStorage storage self,
        uint256 planetId
    ) {
        require(isMyPlanet(self, planetId), 'Must be your planet.');
        _;
    }
    modifier stationMustNotExist (
        PlanetStorage storage self,
        uint256 planetId
    ) {
        require(!stationExists(self, planetId), 'Station already exists.');
        _;
    }
    modifier stationMustExist (
        PlanetStorage storage self,
        uint256 planetId
    ) {
        require(stationExists(self, planetId), 'Station must exist.');
        _;
    }
    modifier stationMustNotHavePort (
        PlanetStorage storage self,
        uint256 planetId
    ) {
        require(stationHasPort(self, planetId) == false, 'Port must not exist.');
        _;
    }
    modifier stationMustHavePort (
        PlanetStorage storage self,
        uint256 planetId
    ) {
        require(stationHasPort(self, planetId), 'Port must not exist.');
        _;
    }

    /**************************************
    *
    * VIEWS
    *
    ***************************************/

    function isMyPlanet(
        PlanetStorage storage self,
        uint256 planetId
    ) internal view returns (bool) {
        if (PlanetTokens(self.planetTokensAddress).ownerOf(planetId) == msg.sender) return true;
        return false;
    }

    function stationExists(
        PlanetStorage storage self,
        uint256 planetId
    ) internal view returns (bool) {
        if (self.stations[planetId].size > 0) return true;
        return false;
    }
    function stationHasHub(
        PlanetStorage storage self,
        uint256 planetId
    ) internal view returns (bool) {
        if (self.hubs[planetId].people.supplyCap != 0) return true;
        return false;
    }
    function stationHasPort(
        PlanetStorage storage self,
        uint256 planetId
    ) internal view returns (bool) {
        if (self.ports[planetId].equipment.supplyCap != 0) return true;
        if (self.ports[planetId].fuel.supplyCap != 0) return true;
        if (self.ports[planetId].organics.supplyCap != 0) return true;
        return false;
    }
    function stationHasYard(
        PlanetStorage storage self,
        uint256 planetId
    ) internal view returns (bool) {
        if (self.yards[planetId].size > 0) return true;
        return false;
    }

    function getOwner(
        PlanetStorage storage self,
        uint256 planetId
    ) internal view returns (
        address
    ) {
        return PlanetTokens(self.planetTokensAddress).ownerOf(planetId);
    }

    function getPlanet(
        PlanetStorage storage self,
        uint256 planetId
    ) internal view returns (
        string memory,
        uint256,
        uint8[4] memory,
        address,
        bool
    ) {
        address owner = PlanetTokens(self.planetTokensAddress).ownerOf(planetId);
        if (owner == address(this)) {
            owner = address(0);
        }
        uint8[4] memory attribs = [
            self.planets[planetId].size,
            self.planets[planetId].class,
            self.planets[planetId].rings,
            self.planets[planetId].orbitSpeed
        ];

        return (
            self.planets[planetId].name,
            self.planets[planetId].star,
            attribs,
            owner,
            stationExists(self, planetId)
        );
    }

    function calculateInventoryCategoryGrowth (
        int256 secondsSinceLastTrade,
        int16 supplyCap,
        int16 inventory
    ) internal pure returns (
        int16
    ) {
        int256 secondsPerItemSpawn = 120;
        int16 itemsToSpawn = supplyCap - inventory; //could be negative
        int256 secondsUntilFull = int256(abs(itemsToSpawn) * secondsPerItemSpawn);

        if ((itemsToSpawn == 0) || (secondsSinceLastTrade >= secondsUntilFull)) {
            return supplyCap;
        }
        //from here we know that the time since the last trade does not amount to
        //enough time to produce enough inventory to hit the supply cap
        int16 itemsSpawned = int16(
          (secondsSinceLastTrade / secondsPerItemSpawn) * //absolute number of items times
          int256(supplyCap / abs(supplyCap))              //retain the sign of supplyCap
        );
        return inventory + itemsSpawned;
    }

    function getInventoryWithGrowth (
        PlanetStorage storage self,
        uint256 planetId
    ) internal view returns (
        int16[3] memory
    ) {
        PortOfTrade memory port = self.ports[planetId];
        require(port.lastTradeTime <= block.timestamp, "invalid timestamp");
        int256 secondsSinceLastTrade = int256(block.timestamp - port.lastTradeTime);

        return [
            calculateInventoryCategoryGrowth(secondsSinceLastTrade, port.equipment.supplyCap, port.equipment.inventory),
            calculateInventoryCategoryGrowth(secondsSinceLastTrade, port.fuel.supplyCap, port.fuel.inventory),
            calculateInventoryCategoryGrowth(secondsSinceLastTrade, port.organics.supplyCap, port.organics.inventory)
        ];

    }

    function getStation (
        PlanetStorage storage self,
        uint256 planetId
    ) external view stationMustExist(self, planetId) returns (
        string memory,
        uint8,
        int16[3] memory,
        uint16[4] memory
    ) {
        (uint16 equipmentPrice, uint16 fuelPrice, uint16 organicsPrice) = getPortPrices(self, planetId);
        return (
            self.stations[planetId].name,
            self.stations[planetId].size,
            getInventoryWithGrowth(self, planetId),
            //[
            //    self.ports[planetId].equipment.inventory,
            //    self.ports[planetId].fuel.inventory,
            //    self.ports[planetId].organics.inventory
            //],
            [
                equipmentPrice,
                fuelPrice,
                organicsPrice,
                costPerHold
            ]
        );
    }

    function getPlanetTokenizer(PlanetStorage storage self) internal view returns(address) {
        return self.planetTokensAddress;
    }

    function getPlanetLocation(
        PlanetStorage storage self,
        uint256 id
    ) internal view returns (
        uint256
    ) {
        return (
            self.planets[id].star
        );
    }

    /**************************************
    *
    * CONTROLS
    *
    ***************************************/

    function setPlanetTokenizer(
        PlanetStorage storage self,
        address tokenAddress
    ) public {
        self.planetTokensAddress = tokenAddress;
    }

    function createStation(
        PlanetStorage storage self,
        uint256 planetId,
        string memory name,
        uint8 size
    ) internal stationMustNotExist(self, planetId) { //todo: add planetMustExist
        self.stations[planetId].name = name;
        self.stations[planetId].size = size;
    }

    function calculatePrice(
        int16 inventory,
        int16 supplyCap,
        int16 foundationPrice,
        int16 liquidPrice
    ) internal pure returns (uint16) {
        require(supplyCap != 0, "invalid supply cap");
        int16 playerBias = liquidPrice / 10;
        //port is selling
        if (supplyCap > 0) {
            return uint16(liquidPrice * abs(supplyCap - inventory) / abs(supplyCap) + foundationPrice - playerBias);
        }
        return uint16(liquidPrice * abs(inventory) / abs(supplyCap) + foundationPrice + playerBias);
    }

    function getPortPrices (
        PlanetStorage storage self,
        uint256 planetId
    ) internal view stationMustExist(self, planetId) stationMustHavePort(self, planetId) returns (
        uint16,
        uint16,
        uint16
    ) {
        int16[3] memory inventory = getInventoryWithGrowth(self, planetId);
        uint16 equipmentPrice =  calculatePrice(
            inventory[0],
            self.ports[planetId].equipment.supplyCap,
            145,
            50
        );
        uint16 fuelPrice = calculatePrice(
            inventory[1],
            self.ports[planetId].fuel.supplyCap,
            65,
            50
        );
        uint16 organicsPrice = calculatePrice(
            inventory[2],
            self.ports[planetId].organics.supplyCap,
            90,
            50
        );
        return(equipmentPrice, fuelPrice, organicsPrice);
    }

    function getTradeValue (
        PlanetStorage storage self,
        uint256 planetId,
        int16 equipment,
        int16 fuel,
        int16 organics
    ) internal view stationMustExist(self, planetId) stationMustHavePort(self, planetId) returns (int256) {
        (uint16 equipmentPrice, uint16 fuelPrice, uint16 organicsPrice) = getPortPrices(self, planetId);
        return int256(
            (   int256(equipmentPrice) * int256(equipment) +
                int256(fuelPrice) * int256(fuel) +
                int256(organicsPrice) * int256(organics)
            ) * -1
        );
    }

    function updateInventoryWithGrowth(
        PlanetStorage storage self,
        uint256 planetId
    ) internal {
        int16[3] memory newInventory = getInventoryWithGrowth(self, planetId);
        self.ports[planetId].equipment.inventory = newInventory[0];
        self.ports[planetId].fuel.inventory = newInventory[1];
        self.ports[planetId].organics.inventory = newInventory[2];
        self.ports[planetId].lastTradeTime = block.timestamp;
    }


    function modifyPortInventory(
        PlanetStorage storage self,
        uint256 planetId,
        int16 equipment,
        int16 fuel,
        int16 organics
    ) internal stationMustExist(self, planetId) stationMustHavePort(self, planetId) returns (int256) {
        //record any newly generated inventory
        updateInventoryWithGrowth(self, planetId);
        //required stock exists
        require(abs(self.ports[planetId].equipment.inventory) >= abs(equipment), 'Inadequate equipment');
        require(abs(self.ports[planetId].fuel.inventory) >= abs(fuel), 'Inadequate fuel');
        require(abs(self.ports[planetId].organics.inventory) >= abs(organics), 'Inadequate organics');
        //both values have the same sign
        require(int256(self.ports[planetId].equipment.inventory) * int256(equipment) >= 0, 'Equipment clash');
        require(int256(self.ports[planetId].fuel.inventory) * int256(fuel) >= 0, 'Fuel clash');
        require(int256(self.ports[planetId].organics.inventory) * int256(organics) >= 0, 'Organics clash');

        int256 tradeValue = getTradeValue(self, planetId, equipment, fuel, organics);

        self.ports[planetId].equipment.inventory -= equipment;
        self.ports[planetId].fuel.inventory -= fuel;
        self.ports[planetId].organics.inventory -= organics;


        return tradeValue;
    }

    //todo: this should be in a library and I should be using safe math everywhere
    function abs(int16 x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

    function addPortToStation(
        PlanetStorage storage self,
        uint256 planetId
    ) internal stationMustExist(self, planetId) stationMustNotHavePort(self, planetId) {
        int16 equipment;
        int16 fuel;
        int16 organics;
        if (self.planets[planetId].class == 0) { //Terrestrial
          equipment = 500;  //S
          fuel = -1750;      // B
          organics = 1500;   //S
        } else if (self.planets[planetId].class == 1) { //Rocky
          equipment =  1000;//S
          fuel = -2000;     // B
          organics = -1000; // B
        } else if (self.planets[planetId].class == 2) { //Oceanic
          equipment = -1000;// B
          fuel = 1000;      //S
          organics = 2000;  //S
        } else if (self.planets[planetId].class == 3) { //Desert
          equipment = 750;  //S
          fuel = 2000;      //S
          organics = -1000; // B
        } else if (self.planets[planetId].class == 4) { //Ice
          equipment = 500;  //S
          fuel = -1000;     // B
          organics = 1000;  //S
        } else if (self.planets[planetId].class == 5) { //Volcanic
          equipment = -500; // B
          fuel = 2000;      //S
          organics = 500;   // B
        } else if (self.planets[planetId].class == 6) { //Gaseous
          equipment = -500; // B
          fuel = 2000;      //S
          organics = -500;  // B
        } else if (self.planets[planetId].class == 7) { //Ferrous
          equipment = 2000; //S
          fuel = -500;      // B
          organics = -2000; // B
        } else if (self.planets[planetId].class == 8) { //Lava
          equipment = -500; // B
          fuel = 1500;      //S
          organics = 500;   //S
        } else if (self.planets[planetId].class == 9) { //Swamp
          equipment = -1500;// B
          fuel = -1000;     // B
          organics = 2000;  //S
        }
        //e ssbssbbsbb 5 5
        //f bbssbssbss 6 4
        //o sbsbsbbbss 5 5

        self.ports[planetId].equipment.supplyCap = equipment;
        self.ports[planetId].fuel.supplyCap = fuel;
        self.ports[planetId].organics.supplyCap = organics;

        self.ports[planetId].equipment.inventory = equipment;
        self.ports[planetId].fuel.inventory = fuel;
        self.ports[planetId].organics.inventory = organics;

        //self.ports[planetId].lastTradeTime = block.timestamp;
    }

    function renameStation (
        PlanetStorage storage self,
        uint256 _planetId,
        string memory _newName
    ) internal stationMustExist(self, _planetId) {
        self.stations[_planetId].name = _newName;
    }

    function createRandomPlanet(
        PlanetStorage storage self,
        uint256 star,
        uint256 dna,
        uint8   distance
    ) internal returns (
        uint256
    ) {
        // todo: be smarter about what plants are likely at what distance
        uint8 size = uint8(dna % (20 + distance * 2)) + 1;
        uint8 class = uint8((dna / 50) % 10);
        uint8 rings = uint8((dna / 100) % 10);
        uint8 ringchance = uint8((dna / 1000) % 10);
        rings = (ringchance > 2) ? 0: rings;
        uint8 orbitSpeed = uint8(255 - ((dna / 1000) % 150)) / (distance + 1);
        return createPlanet(
            self,
            'Unexplored Planet',
            star,
            size,
            class,
            rings,
            orbitSpeed
        );
    }

    function createPlanet(
        PlanetStorage storage self,
        string memory name,
        uint256 star,
        uint8 size,
        uint8 class,
        uint8 rings,
        uint8 orbitSpeed
    ) internal returns (
        uint256
    ) {
        uint256 planetId = (self.planets.push(
            Planet(
                name,
                star,
                size,
                class,
                rings,
                orbitSpeed
            )
        )) - 1;
        PlanetTokens(self.planetTokensAddress).mintPlanet(planetId);

        return planetId;
    }

    function claimPlanet(
        PlanetStorage storage self,
        uint256 planetId
    ) internal mustBeUnclaimed(self, planetId) {
        PlanetTokens(self.planetTokensAddress).awardPlanet(msg.sender, planetId);
    }

    function renamePlanet(
        PlanetStorage storage self,
        uint256 planetId,
        string memory _newName
    ) internal mustOwnPlanet(self, planetId) {
        self.planets[planetId].name = _newName;
    }
}

pragma solidity >=0.5.0 <0.6.0;

library MoonLibrary {

    uint8 public constant maxMoons = 8;

    struct Moon {
        string name;
        uint8 size;
        uint8 class;
        uint8 velocity;
    }

    //moon system?
    struct MoonStorage {
        mapping (uint256 => mapping(uint8 => Moon)) moons;
    }

    function getMaxMoons() internal pure returns (uint8) {
        return maxMoons;
    }

    function getMoon(
        MoonStorage storage self,
        uint256 planetId,
        uint8 moonId
    ) internal view returns (
        string memory,
        uint8,
        uint8,
        uint8
    ) {
        require(self.moons[planetId][moonId].size > 0, "That's no moon");
        return (
            self.moons[planetId][moonId].name,
            self.moons[planetId][moonId].size,
            self.moons[planetId][moonId].class,
            self.moons[planetId][moonId].velocity
        );
    }

    function isMoon(
        MoonStorage storage self,
        uint256 planetId,
        uint8 moonId
    ) internal view returns (
        bool
    ) {
        if (self.moons[planetId][moonId].size > 0) {
            return true;
        }
        return false;
    }

    function getHasMoons (
        MoonStorage storage self,
        uint256 planetId
    ) internal view returns (
        bool[maxMoons] memory
    ) {
        bool[maxMoons] memory hasMoons;
        for (uint8 i = 0; i < maxMoons; i++) {
            if (isMoon(self, planetId, i)) {
                hasMoons[i] = true;
            } else {
              hasMoons[i] = false;
            }
        }
        return hasMoons;
    }

    /**
    * Creates all of the moons to accompany a solar system
    * returns array of ids
    */
    function createRandomMoon(
        MoonStorage storage self,
        uint256 planetId,
        uint8 moonId,
        uint256 seed
    ) internal {        
        //todo: this should be more intellegent 
        uint8 size = uint8(seed % (30 - moonId * 2)) + 1;
        uint8 class = uint8((seed / 50) % 10);
        uint8 velocity = uint8(((255 - moonId * 30) - ((seed / 2005) % 50)));
        createMoon(
            self,
            planetId,
            moonId,
            'Moon',
            size,
            class,
            velocity
        );
    }

    /**
    * Creates all of the moons to accompany a solar system
    * returns array of ids
    */
    function createMoon(
        MoonStorage storage self,
        uint256 planetId,
        uint8 moonId,
        string memory name,
        uint8 size,
        uint8 class,
        uint8 velocity
    ) internal {
        require(moonId < maxMoons, 'moon out of range');
        //todo: require no moon exists there already
        self.moons[planetId][moonId] = Moon(
            name,
            size,
            class,
            velocity
        );
    }

    function renameMoon(
        MoonStorage storage self, 
        uint256 planetId,
        uint8 moonId, 
        string memory newName
    ) internal {
        self.moons[planetId][moonId].name = newName;
    }
}

pragma solidity >=0.5.0 <0.6.0;

import './SystemObjects/PlanetLibrary.sol';
import './SystemObjects/MoonLibrary.sol';
import './SystemObjects/ShipLibrary.sol';
import './Avatar/AvatarLibrary.sol';
import '../../libraries/HelperLibrary.sol';
import './SystemObjects/presets/PresetLibrary.sol';
import '../../Tokens/Credits.sol';

library StarSystemLibrary {

    using PlanetLibrary for PlanetLibrary.PlanetStorage;
    using PlanetLibrary for PlanetLibrary.Planet;

    using MoonLibrary for MoonLibrary.MoonStorage;
    using MoonLibrary for MoonLibrary.Moon;

    using ShipLibrary for ShipLibrary.ShipStorage;
    using ShipLibrary for ShipLibrary.Ship;

    using AvatarLibrary for AvatarLibrary.Avatar;
    using AvatarLibrary for AvatarLibrary.AvatarStorage;

    using HelperLibrary for HelperLibrary.Helper;


    struct StarSystem {
        string name;
        uint8 starSize;
        uint256 birthTime;
        address discoveredBy;
        uint256[12] neighbors;
        uint256[14] planets;
        uint256[30] shipLog;
        uint256 visitorIndex;
    }
    struct Galaxy {

        StarSystem[] systems;
        mapping(uint => bool) wasCreated;
        mapping(uint => bool) wasVisited;
        HelperLibrary.Helper helper;

        address creditTokenizerAddress;

        //storage
        AvatarLibrary.AvatarStorage avatars; //all avatars
        PlanetLibrary.PlanetStorage planets; //all planets
        MoonLibrary.MoonStorage moons;       //all moons
        ShipLibrary.ShipStorage ships;       //all ships
    }


    /** connection to tokens contract for tracking credits */
    function setCreditTokenizer(
        Galaxy storage galaxy,
        address tokenAddress)
    public {
        galaxy.creditTokenizerAddress = tokenAddress;
    }
    function getCreditTokenizer(Galaxy storage galaxy) internal view returns(address) {
        return galaxy.creditTokenizerAddress;
    }
    function balanceOf(Galaxy storage galaxy, address player) internal view returns (uint256) {
        return Credits(galaxy.creditTokenizerAddress).balanceOf(player);
    }
    function awardCredits(Galaxy storage galaxy, address player, uint256 amount) internal {
        return Credits(galaxy.creditTokenizerAddress).awardCredits(player, amount);
    }
    function spendCredits(Galaxy storage galaxy, address player, uint256 amount) internal {
        return Credits(galaxy.creditTokenizerAddress).spendCredits(player, amount);
    }

    /** PLANET */

    /** connection to tokens contract for tracking planets */
    function setPlanetTokenizer(
        Galaxy storage galaxy,
        address tokenAddress)
    public {
        galaxy.planets.setPlanetTokenizer(tokenAddress);
    }
    function getPlanetTokenizer(Galaxy storage galaxy) internal view returns(address) {
        //return galaxy.planets.getplanetTokens.owner();
        return galaxy.planets.getPlanetTokenizer();
    }

    function getPlanet(
        Galaxy storage galaxy,
        uint256 planetId
    ) internal view returns (
        string memory,
        uint256,
        uint8[4] memory,
        address,
        bool[8] memory,
        bool
    ) {
        (
            string memory name,
            uint256 sun,
            uint8[4] memory attributes,
            address owner,
            bool hasPort
        ) = galaxy.planets.getPlanet(planetId);

        bool[8] memory hasMoons;
        hasMoons = galaxy.moons.getHasMoons(planetId);

        return (
            name,
            sun,
            attributes,
            owner,
            hasMoons,
            hasPort
        );
    }

    function buildStation (
        Galaxy storage galaxy,
        uint256 planetId,
        string memory stationName
    ) public {
        // require ownership
        require(galaxy.planets.isMyPlanet(planetId),'Must Own Planet');

        galaxy.planets.createStation(
            planetId,
            stationName,
            1
        );
        galaxy.planets.addPortToStation(planetId);
        spendCredits(galaxy, msg.sender, 10000);
    }

    function getLocalPlanet(
        Galaxy storage galaxy,
        uint256 orbitalId
    ) internal view returns (
        string memory,
        uint256,
        uint8[4] memory,
        address,
        bool[8] memory,
        bool
    ) {
        uint256 currentSystemId = getMyShipLocation(galaxy);
        uint256 planetId = galaxy.systems[currentSystemId].planets[orbitalId];
        return getPlanet(galaxy, planetId);
    }

    function planetInSystem(
        Galaxy storage galaxy,
        uint256 planetId
    ) internal view returns (
        bool
    ) {
        uint256 currentSystemId = getMyShipLocation(galaxy);
        for (uint i = 0; i < galaxy.systems[currentSystemId].planets.length; i++) {
            if (galaxy.systems[currentSystemId].planets[i] == planetId) {
                return true;
            }
        }
        return false;
    }

    function claimPlanet(
        Galaxy storage galaxy,
        uint256 planetId,
        string memory planetName
    ) internal {
        require(planetInSystem(galaxy, planetId), "Must be in system.");
        galaxy.planets.claimPlanet(planetId);
        galaxy.planets.renamePlanet(planetId, planetName);
        //perhaps this belongs in the calling method?
        galaxy.ships.setMyShipOrbit(
            planetId
        );
    }

    function renamePlanet(
        Galaxy storage galaxy,
        uint256 planetId,
        string memory planetName
    ) internal {
        galaxy.planets.renamePlanet(planetId, planetName);
        galaxy.ships.setMyShipOrbit(
            planetId
        );
    }

    /** MOON */

    function getMoon(
        Galaxy storage galaxy,
        uint256 planetId,
        uint8 moonId
    ) internal view returns (
        string memory,
        uint8,
        uint8,
        uint8
    ) {
        return galaxy.moons.getMoon(planetId, moonId);
    }

    function renameMoon(
        Galaxy storage galaxy,
        uint256 planetId,
        uint8 moonId,
        string memory moonName
    ) internal {
        galaxy.moons.renameMoon(planetId, moonId, moonName);
        galaxy.ships.setMyShipOrbit(
            planetId
        );
    }

    /** Space Station */

    function getStation(
        Galaxy storage galaxy,
        uint256 _planetId
    ) internal view returns (
        string memory,
        uint8,
        int16[3] memory,
        uint16[4] memory
    ) {
        return galaxy.planets.getStation(_planetId);
    }

    function renameStation(
        Galaxy storage galaxy,
        uint256 _planetId,
        string memory _stationName
    ) internal {
        galaxy.planets.renameStation(_planetId, _stationName);
    }

    function addPortToStation(
        Galaxy storage galaxy,
        uint256 _planetId
    ) public {
        galaxy.planets.addPortToStation(_planetId);
    }

    function tradeAtPort(
        Galaxy storage galaxy,
        uint256 _planetId,
        int16 _equipment,
        int16 _fuel,
        int16 _organics
    ) public returns (int) {
        galaxy.ships.modifyMyShipCargo(_equipment, _fuel, _organics);
        int256 creditBalance = galaxy.planets.modifyPortInventory(_planetId, _equipment, _fuel, _organics);
        address portOwner = galaxy.planets.getOwner(_planetId);
        if (creditBalance > 0) {
          uint256 income = uint256(creditBalance);
          awardCredits(galaxy, msg.sender, income);
          if (portOwner != msg.sender) {
            awardCredits(galaxy, portOwner, uint256(income / 100));
          }
        }
        if (creditBalance < 0) {
          uint256 expense = uint256(creditBalance * -1);
          require (expense < balanceOf(galaxy, msg.sender), 'insufficient credits');
          spendCredits(galaxy, msg.sender, expense);
          if (portOwner != msg.sender) {
            awardCredits(galaxy, portOwner, uint256(expense / 100));
          }
        }

        galaxy.ships.setMyShipOrbit(
            _planetId
        );
        return creditBalance;
    }

    function addHoldsToShip(
        Galaxy storage galaxy,
        uint256 planetId,
        uint8 holds
    ) public {
        (,,,uint16[4] memory price) = galaxy.planets.getStation(planetId);
        uint256 expense = uint256(holds) * uint256(price[3]);
        galaxy.ships.addHolds(holds);
        require (expense < balanceOf(galaxy, msg.sender), 'insufficient credits');
        spendCredits(galaxy, msg.sender, expense);
    }

    /** SHIP */

    function setShipTokenizer(
        Galaxy storage galaxy,
        address tokenAddress)
    public {
        galaxy.ships.setShipTokenizer(tokenAddress);
    }
    function getShipTokenizer(Galaxy storage galaxy) internal view returns(address) {
        return galaxy.ships.getShipTokenizer();
    }

    function getMyShipLocation(Galaxy storage galaxy) internal view returns (uint256)  {
        return galaxy.ships.getMyShipLocation();
    }

    function getMyShip(
        Galaxy storage galaxy
    ) internal view returns (
        string memory, //name
        uint,          //star system
        uint,          //orbit
        uint8,         //cargo limit
        uint8,         //equipment
        uint8,         //fuel
        uint8          //organics
    )  {
        return galaxy.ships.getMyShip();
    }

    function getMyShipId(Galaxy storage galaxy) internal view returns (uint256)  {
        return galaxy.ships.getMyShipId();
    }

    function getShip(
        Galaxy storage galaxy,
        uint256 shipId
    ) external view returns (
        string memory,
        uint,
        uint,
        address
    ) {
        return galaxy.ships.getShip(shipId);
    }

    function renameMyShip(
        Galaxy storage galaxy,
        string memory _shipName
    ) internal {
        galaxy.ships.renameMyShip(_shipName);
    }

    function moveToSystem(Galaxy storage galaxy, uint256 destinationSystemId) internal {
        require(getMyShipLocation(galaxy) > 0, "Ship must already be launched.");
        require(_isCurrentNeighbor(galaxy, destinationSystemId) == true, "You can only move to neighboring star systems.");
        if (galaxy.wasVisited[destinationSystemId] == false) {
            populateStarSystem(
                galaxy,
                destinationSystemId,
                getMyShipLocation(galaxy)
            );
        }
        galaxy.ships.moveMyShip(destinationSystemId);
        recordNewVisit(galaxy, destinationSystemId, getMyShipId(galaxy));
    }

    function launchShip(Galaxy storage galaxy, string memory _shipName) internal {
        require(getMyShipId(galaxy) == 0, "Ship must be new.");
        require(galaxy.wasVisited[1], "You must first make the solar system");
        uint256 shipId = galaxy.ships.createMyShip(_shipName);
        recordNewVisit(galaxy, 1, shipId);
    }

    /** SYSTEM */

    function renameStar(Galaxy storage galaxy, string memory _newName) internal {
        uint256 currentSystemId = getMyShipLocation(galaxy);
        require((galaxy.systems[currentSystemId].discoveredBy == msg.sender), "Must have discovered star.");
        galaxy.systems[currentSystemId].name = _newName;
    }

    function getStarSystemCount(Galaxy memory galaxy) internal pure returns(uint256) {
        return galaxy.systems.length;
    }

    function getSystemData(Galaxy storage galaxy, uint256 systemId) internal view returns(
        uint256,            //id
        string memory,      //name
        uint8,              //starSize
        uint256,            //bithtime
        address,            //discoveredBy
        uint256[12] memory, //neighbors
        uint256[14] memory, //planets
        uint256[30] memory  //logs
    ) {
        require(galaxy.wasCreated[systemId] == true, "Sector does not exist.");
        StarSystem memory system = galaxy.systems[systemId];
        return(
            systemId,
            system.name,
            system.starSize,
            system.birthTime,
            system.discoveredBy,
            system.neighbors,
            system.planets,
            system.shipLog
        );
    }

    function getSystemName(Galaxy storage galaxy, uint256 systemId) internal view returns(
        string memory
    ) {
        require(galaxy.wasCreated[systemId] == true, "Sector does not exist.");
        if (galaxy.wasVisited[systemId]) {
            return galaxy.systems[systemId].name;
        }
        return 'Unexplored Star';
    }

    function recordNewVisit(Galaxy storage galaxy, uint256 systemId, uint256 shipId) internal {
        galaxy.systems[systemId].shipLog[galaxy.systems[systemId].visitorIndex] = shipId;
        galaxy.systems[systemId].visitorIndex = (galaxy.systems[systemId].visitorIndex + 1) % 30;
    }

    function genesis(Galaxy storage galaxy) internal {
        require(galaxy.systems.length == 0, "a galaxy already exists");

        //create the otherverse, the player spawning location
        uint256 otherverseId = _spawnStarSystem(galaxy);
        require(otherverseId == 0, "Otherverse should have been zero.");
        galaxy.systems[otherverseId].name = "Otherverse";

        //create a zero based planet in the otherverse
        uint256 planetId = galaxy.planets.createPlanet(
            'Nowhere',
            otherverseId,   //sun
            0,   //size
            0,   //class K, Desert Wasteland
            0,   //rings
            0    //orbital speed
        );
        require(planetId == 0, "Failed to burn planet zero.");

        uint256 shipId = galaxy.ships.createMyShip('Ghost Ship');
        require(shipId == 0, "Failed to burn space ship zero.");

        //create the solar system
        uint256 solId = _spawnStarSystem(galaxy);
        require(solId == 1, "Sol System should have been one.");
        galaxy.systems[solId].name = "Sol";

        //fill in the neighbors with new systems
        for (uint i = 0; i < galaxy.systems[solId].neighbors.length; i++) {
            if (galaxy.systems[solId].neighbors[i] == 0) {
                galaxy.systems[solId].neighbors[i] = _spawnStarSystem(galaxy);
            }
        }

        //create a link from otherverse into the solar system
        galaxy.systems[0].neighbors[0] = solId;
    }


    function _isCurrentNeighbor(Galaxy storage galaxy, uint256 destinationSystemId) internal view returns(bool){
        require (destinationSystemId != 0, "You can not travel back to the Otherverse");
        uint currentStarSystem = getMyShipLocation(galaxy);
        uint neighborCount = galaxy.systems[currentStarSystem].neighbors.length;

        //fill in the neighbors with   new systems
        for (uint i = 0; i < neighborCount; i++) {
            if (galaxy.systems[currentStarSystem].neighbors[i] == destinationSystemId) {
                return true;
            }
        }

        return false;
    }

    function _spawnStarSystem(Galaxy storage galaxy) internal returns(uint) {
        //every star system can have up to 12 reachable neighbors
        uint256[12] memory emptyNeighbors;
        uint256[14] memory emptyPlanets;
        uint256[30] memory emptyVisitors;

        uint256 systemId = (galaxy.systems.push(
            StarSystem(
                "Star",
                1,
                uint32(block.timestamp),
                address(0),
                emptyNeighbors,
                emptyPlanets,
                emptyVisitors,
                0
            )
        )) - 1;

        galaxy.wasCreated[systemId] = true;

        return systemId;
    }

    /**
     * used to build backlinks
     */
    function getNeighborCompliment(
        uint currentId,
        uint arrayLength
    ) internal pure returns(uint) {
        return (currentId + arrayLength / 2) % arrayLength;
    }

    /**
     * The first visit to a star system will populate it
     */
    function populateStarSystem(
        Galaxy storage galaxy,
        uint256 starSystemId,
        uint256 originSystemId
    ) internal {
        require(starSystemId > 1, "Populate should not run on system 1.");
        require(galaxy.wasCreated[starSystemId] == true, "Star System Does Not Exist");
        require(galaxy.wasVisited[starSystemId] == false, "Star System Already Visited");

        StarSystem storage newSystem = galaxy.systems[starSystemId];
        StarSystem memory originSystem = galaxy.systems[originSystemId];

        galaxy.systems[starSystemId].discoveredBy = msg.sender;

        uint8 connections = 0;
        uint8 neighborCount = uint8(originSystem.neighbors.length);

        uint rando = galaxy.helper.getRandom();

        //set random star size
        newSystem.starSize = uint8((rando % 6) + 1);

        // link back to visited sectors
        for (uint8 i = 0; i < neighborCount; i++) {
            if (originSystem.neighbors[i] == starSystemId) {
                if (((rando + i) % 8 > 0) || (connections < 2)) {
                    newSystem.neighbors[
                        getNeighborCompliment(i, neighborCount)
                    ] = originSystemId;
                }
            } else {
                if (((rando + i) % 3 == 0) && (originSystem.neighbors[i] != 0)) {
                    newSystem.neighbors[
                        getNeighborCompliment(i, neighborCount)
                    ] = originSystem.neighbors[i];
                    connections ++;
                } else if ((rando + i) % 6 == 0) {
                    uint randoSystemId = ((rando - i) % (starSystemId));
                    newSystem.neighbors[
                        getNeighborCompliment(i, neighborCount)
                    ] = randoSystemId;
                }
            }
        }

        // fill in the remaining neighbors with new systems
        for (uint8 i = 0; i < newSystem.neighbors.length; i++) {
            if (newSystem.neighbors[i] == 0) {
                if ((rando + i) % 2 == 0) {
                    newSystem.neighbors[i] = _spawnStarSystem(galaxy);
                }
            }
        }

        spawnPlanets(galaxy, newSystem, rando);

        galaxy.wasVisited[starSystemId] = true;
    }

    function spawnPlanets(Galaxy storage galaxy, StarSystem storage newSystem, uint256 rando) internal {
        //spawn planets
        uint8 orbitalCount = uint8(newSystem.planets.length);
        for (uint8 i = 0; i < orbitalCount; i++) {
            if (((rando * (i+2)) % 14) < (newSystem.starSize / 2 + 4)) {
                uint256 planetId = galaxy.planets.createRandomPlanet(
                    getMyShipLocation(galaxy),
                    rando * (i+11) - i,
                    uint8(i)
                );
                newSystem.planets[i] = planetId;
                //spawn moons
                for (uint8 j = 0; j < MoonLibrary.getMaxMoons(); j++) {
                    //todo: clean this up
                    if (((rando * (i+j+2)) % 25) < (3 + i/4)) {
                        galaxy.moons.createRandomMoon(
                            planetId,
                            j,
                            rando * (j+7) - j
                        );
                    }
                }
            }
        }
    }

    /**
     * The first star system created is modled after our own.
     */
    function makeSolarSystem(Galaxy storage galaxy) internal {
        uint256 solId = 1;
        require(galaxy.wasVisited[solId] == false, "Must never have been visited");
        galaxy.wasVisited[solId] = true;
        galaxy.systems[solId].discoveredBy = msg.sender;
        //Set Sun Size
        galaxy.systems[solId].starSize = 4;
        uint256 planetId = 0;
        uint8 objectCount = 0;
        do {
            if (PresetLibrary.isPlanet(objectCount)) {
                galaxy.systems[solId].planets[planetId] = galaxy.planets.createPlanet(
                    PresetLibrary.getName(objectCount),
                    solId,
                    PresetLibrary.getSize(objectCount),
                    PresetLibrary.getClass(objectCount),
                    PresetLibrary.getRings(objectCount),
                    PresetLibrary.getSpeed(objectCount)
                );
                planetId = galaxy.systems[solId].planets[planetId];
                galaxy.planets.claimPlanet(planetId);

            }
            if (PresetLibrary.isMoon(objectCount)) {
                galaxy.moons.createMoon(
                    planetId,
                    PresetLibrary.getSlot(objectCount),
                    PresetLibrary.getName(objectCount),
                    PresetLibrary.getSize(objectCount),
                    PresetLibrary.getClass(objectCount),
                    PresetLibrary.getSpeed(objectCount)
                );
            }
            if (PresetLibrary.isStation(objectCount)) {
                galaxy.planets.createStation(
                    planetId,
                    PresetLibrary.getName(objectCount),
                    PresetLibrary.getSize(objectCount)
                );
                galaxy.planets.addPortToStation(
                    planetId
                );
            }
            objectCount++;
        } while (!PresetLibrary.isNothing(objectCount));
    }
}

pragma solidity >=0.5.0 <0.6.0;

library AvatarLibrary {

    struct Avatar {
        string name;
    }

    struct AvatarStorage {
        Avatar[] avatars;
        mapping (address => uint) addressToAvatar;
        mapping (address => bool) wasCreated;
    }

    function createAvatar(AvatarStorage storage self, string memory name) internal {
        require(self.wasCreated[msg.sender] == false, 'You already have an avatar.');
        uint id = self.avatars.push(
            Avatar(
                name
            )
        ) - 1;
        self.addressToAvatar[msg.sender] = id;
        self.wasCreated[msg.sender] = true;
    }

    function getAvatarCount(AvatarStorage storage self) public view returns (uint) {
        return self.avatars.length;
    }

    function getAvatarIdByAddress(AvatarStorage storage self, address owner) public view returns(uint) {
        //require (self.wasCreated[owner], 'Not an avatar.');
        return self.addressToAvatar[owner];
    }

    function getAvatarNameById(AvatarStorage storage self, uint id) public view returns (string memory) {
        return self.avatars[id].name;
    }

    function getAvatarNameByAddress(AvatarStorage storage self, address owner) public view returns (string memory) {
        //require (self.wasCreated[owner], 'Not an avatar.');
        uint avatarId = self.addressToAvatar[owner];
        return self.avatars[avatarId].name;
    }

    function hasAvatar(AvatarStorage storage self, address owner) public view returns (bool) {
        return self.wasCreated[owner];
    }
}

pragma solidity >=0.5.0 <0.6.0;

import "./AvatarLibrary.sol";

contract AvatarControls {

    using AvatarLibrary for AvatarLibrary.AvatarStorage;
    AvatarLibrary.AvatarStorage avatars;

    event New(string _name);
    function createAvatar(string memory name) public {
        avatars.createAvatar(name);
        emit New(name);
    }

    function getAvatarCount() external view returns(uint) {
        return avatars.getAvatarCount();
    }

    function getAvatarIdByAddress(address owner) public view returns(uint) {
        return avatars.getAvatarIdByAddress(owner);
    }

    function getAvatarNameById(uint id) public view returns(string memory) {
        return avatars.getAvatarNameById(id);
    }

    function getAvatarNameByAddress(address owner) public view returns(string memory) {
        return avatars.getAvatarNameByAddress(owner);
    }

    function getMyAvatarId() public view returns(uint) {
        return avatars.getAvatarIdByAddress(msg.sender);
    }

    function getMyAvatarName() public view returns(string memory) {
        return avatars.getAvatarNameByAddress(msg.sender);
    }

    function getMyAvatarSector() public pure returns(uint) {
        // todo: has to look at other contract
        uint test = 1;
        return test;
    }

    function getMyAvatarShipId() public pure returns(uint) {
        // todo: has to look at other contract
        uint shipid = 1;
        return shipid;
    }

    function hasAvatar(address owner) public view returns(bool) {
        return avatars.hasAvatar(owner);
    }

    function haveAvatar() public view returns(bool) {
        return avatars.hasAvatar(msg.sender);
    }

}

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

pragma solidity ^0.5.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.5.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

pragma solidity ^0.5.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./ERC721.sol";
import "./IERC721Metadata.sol";
import "../../introspection/ERC165.sol";

contract ERC721Metadata is Context, ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Base URI
    string private _baseURI;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the URI for a given token ID. May return an empty string.
     *
     * If the token's URI is non-empty and a base URI was set (via
     * {_setBaseURI}), it will be added to the token ID's URI as a prefix.
     *
     * Reverts if the token ID does not exist.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // Even if there is a base URI, it is only appended to non-empty token-specific URIs
        if (bytes(_tokenURI).length == 0) {
            return "";
        } else {
            // abi.encodePacked is being used to concatenate strings
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     *
     * Reverts if the token ID does not exist.
     *
     * TIP: if all token IDs share a prefix (e.g. if your URIs look like
     * `http://api.myproject.com/token/<id>`), use {_setBaseURI} to store
     * it and save gas.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI}.
     *
     * _Available since v2.5.0._
     */
    function _setBaseURI(string memory baseURI) internal {
        _baseURI = baseURI;
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a preffix in {tokenURI} to each token's URI, when
    * they are non-empty.
    *
    * _Available since v2.5.0._
    */
    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

pragma solidity ^0.5.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Metadata.sol";

/**
 * @title Full ERC721 Token
 * @dev This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology.
 *
 * See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC721Enumerable.sol";
import "./ERC721.sol";
import "../../introspection/ERC165.sol";

/**
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Enumerable is Context, ERC165, ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to address the beneficiary that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {ERC721-_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../drafts/Counters.sol";
import "../../introspection/ERC165.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This is an internal detail of the `ERC721` contract and its use is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.5.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

pragma solidity ^0.5.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}