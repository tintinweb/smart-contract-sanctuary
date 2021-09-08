// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
// | |  ___  ____   | || |     ____     | || |      __      | || |   _____      | || |      __      | |
// | | |_  ||_  _|  | || |   .'    `.   | || |     /  \     | || |  |_   _|     | || |     /  \     | |
// | |   | |_/ /    | || |  /  .--.  \  | || |    / /\ \    | || |    | |       | || |    / /\ \    | |
// | |   |  __'.    | || |  | |    | |  | || |   / ____ \   | || |    | |   _   | || |   / ____ \   | |
// | |  _| |  \ \_  | || |  \  `--'  /  | || | _/ /    \ \_ | || |   _| |__/ |  | || | _/ /    \ \_ | |
// | | |____||____| | || |   `.____.'   | || ||____|  |____|| || |  |________|  | || ||____|  |____|| |
// | |              | || |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
// '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 

// website : https://koaladefi.finance/
// twitter : https://twitter.com/KoalaDefi

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Counters.sol";
import './IBEP20.sol';
import "./SafeMath.sol";

//TODO rename contract

contract NonFungibleKoalasTest is Context, AccessControlEnumerable, ERC721Enumerable, ERC721Burnable {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    uint256 private _maxAttributeIncrement = 5;

    address private _strengthToken;
    address private _agilityToken;
    address private _intelligenceToken;

    // Supports 1% of a token.
    // 10000 = 100% of a Token
    // 100 = 1% of a Token
    uint16 private _baseStrengthCost = 10000;
    uint16 private _baseAgilityCost = 10000;
    uint16 private _baseIntelligenceCost = 10000;

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;   

    uint16 public strengthBurnRateTax = 200;
    uint16 public agilityBurnRateTax = 200;
    uint16 public intelligenceBurnRateTax = 200;
            
    // Dev Address
    address public constant DEV_ADDRESS = 0x123A13a6Ae9312717F4BDbADbF2d903945b15C24;


    struct Stat {
        uint256 strength;
        uint256 agility;
        uint256 intelligence;
    }

    mapping(uint256 => Stat) private stats;

    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        // TODO: Define final tokens for : strength, agility, and intelligence token address
        _strengthToken = 0xBA26397cdFF25F0D26E815d218Ef3C77609ae7f1; // TODO For test only LYPTUS
        _agilityToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // TODO For test only WBNB
        _intelligenceToken = 0xB2EbAa0aD65e9c888008bF10646016f7FcDd73C3; // TODO For test only NALIS

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function randomAttributeIncrement() internal view returns (uint) {
        // psuedo-random
        return (uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % _maxAttributeIncrement) + 1;
    }

    function mint(address to) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "NonFungibleKoala: must have minter role to mint");
        
        _mint(to, _tokenIdTracker.current());
        uint256 baseAttr = randomAttributeIncrement();
        _setStats(_tokenIdTracker.current(), baseAttr, baseAttr, baseAttr);
        _tokenIdTracker.increment();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // internal functions

    function _setStats(uint256 tokenId, uint256 strength, uint256 agility, uint256 intelligence) internal { 
        stats[tokenId] = Stat(
            strength,
            agility,
            intelligence
        );
    }

    function _setStrength(uint256 tokenId, uint256 strength) internal { 
        stats[tokenId].strength = strength;
    }

    function _setAgility(uint256 tokenId, uint256 agility) internal {
        stats[tokenId].agility = agility;
    }

    function _setIntelligence(uint256 tokenId, uint256 intelligence) internal {
        stats[tokenId].intelligence = intelligence;
    }

    // public functions

    function setStrengthBurnRate(uint16 _burnRateTax) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleKoala: must have admin role");
        strengthBurnRateTax = _burnRateTax;
    }

    function setAgilityBurnRate(uint16 _burnRateTax) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleKoala: must have admin role");
        agilityBurnRateTax = _burnRateTax;
    }

    function setIntelligenceBurnRate(uint16 _burnRateTax) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleKoala: must have admin role");
        intelligenceBurnRateTax = _burnRateTax;
    }

    function setStrengthToken(address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleKoala: must have admin role");
        _strengthToken = _address;
    }

    function setAgilityToken(address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleKoala: must have admin role");
        _agilityToken = _address;
    }

    function setIntelligenceToken(address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleKoala: must have admin role");
        _intelligenceToken = _address;
    }

    function setStrengthBaseCost(uint16 _baseCost) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleKoala: must have admin role");
        _baseStrengthCost = _baseCost;
    }

    function setAgilityBaseCost(uint16 _baseCost) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleKoala: must have admin role");
        _baseAgilityCost = _baseCost;
    }

    function setIntelligenceBaseCost(uint16 _baseCost) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleKoala: must have admin role");
        _baseIntelligenceCost = _baseCost;
    }

    function setUrlBase(string memory baseTokenURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleKoala: must have admin role");
        _baseTokenURI = baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getStats(uint256 tokenId) public view returns (uint256 strength, uint256 agility, uint256 intelligence) {
        return (stats[tokenId].strength, stats[tokenId].agility, stats[tokenId].intelligence);
    }

    function getStrength(uint256 tokenId) public view returns (uint256 strength) {
        return stats[tokenId].strength;
    }

    function getAgility(uint256 tokenId) public view returns (uint256 agility) {
        return stats[tokenId].agility;
    }

    function getIntelligence(uint256 tokenId) public view returns (uint256 intelligence) {
        return stats[tokenId].intelligence;
    }
    
    function getStrengthAddress() public view returns (address strengthAddress) {
        return _strengthToken;
    }
    
    function getAgilityAddress() public view returns (address agilityAddress) {
        return _agilityToken;
    }
    
     function getIntelligenceAddress() public view returns (address intelligenceAddress) {
        return _intelligenceToken;
    }

    function improveStrength(uint256 tokenId) public {
        uint256 cost = _baseStrengthCost.mul(stats[tokenId].strength).mul(1e18).div(10000);
        uint256 toDev = cost;
        if (strengthBurnRateTax > 0){
            uint256 toBurn = cost.mul(strengthBurnRateTax).mul(1e18).div(10000);
            IBEP20(_strengthToken).transferFrom(msg.sender, BURN_ADDRESS, toBurn); 
            toDev = cost.sub(toBurn);
        }
        IBEP20(_strengthToken).transferFrom(msg.sender, DEV_ADDRESS, toDev);  

        // Add psuedo-random number in range
        _setStrength(tokenId, getStrength(tokenId) + randomAttributeIncrement());
    }

    function improveAgility(uint256 tokenId) public {
        uint256 cost = _baseAgilityCost.mul(stats[tokenId].agility).mul(1e18).div(10000);
        uint256 toDev = cost;
        if (agilityBurnRateTax > 0){
            uint256 toBurn = cost.mul(agilityBurnRateTax).mul(1e18).div(10000);
            IBEP20(_agilityToken).transferFrom(msg.sender, BURN_ADDRESS, toBurn); 
            toDev = cost.sub(toBurn);
        }
        IBEP20(_agilityToken).transferFrom(msg.sender, DEV_ADDRESS, toDev);  

        // Add psuedo-random number in range
        _setAgility(tokenId, getAgility(tokenId) + randomAttributeIncrement());
    }

    function improveIntelligence(uint256 tokenId) public {
        uint256 cost = _baseIntelligenceCost.mul(stats[tokenId].intelligence).mul(1e18).div(10000);
        uint256 toDev = cost;
        if (agilityBurnRateTax > 0){
            uint256 toBurn = cost.mul(intelligenceBurnRateTax).mul(1e18).div(10000);
            IBEP20(_intelligenceToken).transferFrom(msg.sender, BURN_ADDRESS, toBurn); 
            toDev = cost.sub(toBurn);
        }
        IBEP20(_intelligenceToken).transferFrom(msg.sender, DEV_ADDRESS, toDev);  

        // Add psuedo-random number in range
        _setIntelligence(tokenId, getIntelligence(tokenId) + randomAttributeIncrement());
    }

    function getStrengthCost(uint256 tokenId) public view returns (uint256 cost){
        return _baseStrengthCost.mul(stats[tokenId].strength).mul(1e18).div(10000);
    }

    function getAgilityCost(uint256 tokenId) public view returns (uint256 cost){
        return _baseAgilityCost.mul(stats[tokenId].agility).mul(1e18).div(10000);
    }

    function getIntelligenceCost(uint256 tokenId) public view returns (uint256 cost){
        return _baseIntelligenceCost.mul(stats[tokenId].intelligence).mul(1e18).div(10000);
    }
}