/***
 * 
 *     ____ ____ ____ ____ ____ ____ _________ ____ ____ ____ ____ 
 *    ||K |||a |||w |||a |||i |||i |||       |||C |||a |||t |||s ||
 *    ||__|||__|||__|||__|||__|||__|||_______|||__|||__|||__|||__||
 *    |/__\|/__\|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|
 *
 * 
 *  Project: Kawaii Cats
 *  Website: https://kawaiicats.xyz/
 *  Contract: Kawaii Cats Fight contract
 *  
 *  Description: Enables the cat fight functionality.
 * 
 */


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IPURRtoken.sol";
import "./IKawaiiCatsNFT.sol"; 



contract CatFight is Ownable {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    address private _nftAddress;
    address private _tokenAddress;
    address private _owner;
    IKawaiiCatsNFT private nftInterface;
    IPURRtoken private token;

    uint256 public UPGRADE_PRICE = 2000000000000000000; //2 PURR
    
    CatFightS [] public fightArray;
    struct CatFightS {
        uint32 winCount;
        uint32 lossCount;
        uint32 Stamina;
        uint32 Life;
        uint32 Armour;
        uint32 Attack;
        uint32 Defence;
        uint32 Magic;
        uint32 Luck;
        
        uint32 breed;
        uint32 breedIndex;
        uint32 Rarity;
    }
    
    struct Stats {
        uint32 life;
        uint32 armour;
        uint32 attack;
        uint32 defence;
        uint32 magic;
        uint32 luck;
    }
    
    constructor (address nftAddress, address TokenAddress) {
        _nftAddress = nftAddress;
        _tokenAddress = TokenAddress;
        
        nftInterface = IKawaiiCatsNFT(_nftAddress);
        token = IPURRtoken(_tokenAddress);
        _owner = _msgSender();
    }
    
    modifier onlyNFTContract() {
        require(msg.sender == _nftAddress);
        _;
    }
    
    modifier onlyTokenContract() {
        require(msg.sender == _tokenAddress);
        _;
    }
    
    /**
     * @dev Generates a random luck with values [0-10].
     *
     */
    function _generateRandomLuck(uint _input) private view returns (uint32) {
        uint _randNonce = uint(keccak256(abi.encodePacked(_input))).mod(100);
        _randNonce = _randNonce.add(10);
        uint randLuck = uint(keccak256(abi.encodePacked(block.timestamp + 1 days, msg.sender, _randNonce))).mod(10);
        return uint32(randLuck).add(1); 
    }
    
    /**
     * @dev Creates cat fight data
     *
     */
     
    function createCatFightData (uint32 breed, uint32 breedIndex, uint32 rarity) external onlyNFTContract {
        uint32 _luck =  _generateRandomLuck(breedIndex);
        fightArray.push(CatFightS(0, 0, 3, 10, 10, 10, 10, 10, _luck, breed, breedIndex, rarity));  
    }
    
    
    /**
     * @dev  Upgrades the stats of tokenId based on statsArray (Life, Armour, Attack, Defence, Magic, Luck, Stamina)
     */
    function upgradeStats (uint16 tokenId, uint32[7] memory statsArray) public {
        address owner = nftInterface.ownerOf(tokenId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        
        uint32 _costToUpgrade = 0;
        
        //upgrade Life
        if (fightArray[tokenId].Life < statsArray[0])
        {
            if (fightArray[tokenId].Rarity == 4)
                require (statsArray[0] <= 100);
            if (fightArray[tokenId].Rarity == 3)
                require (statsArray[0] <= 150);
            if (fightArray[tokenId].Rarity == 2)
                require (statsArray[0] <= 200);
            if (fightArray[tokenId].Rarity == 1)
                require (statsArray[0] <= 300);
                
            _costToUpgrade = _costToUpgrade.add(statsArray[0].sub(fightArray[tokenId].Life));
            fightArray[tokenId].Life = statsArray[0]; 
        }
        
        //upgrade Armour
        if (fightArray[tokenId].Armour < statsArray[1])
        {
            if (fightArray[tokenId].Rarity == 4)
                require (statsArray[1] <= 100);
            if (fightArray[tokenId].Rarity == 3)
                require (statsArray[1] <= 150);
            if (fightArray[tokenId].Rarity == 2)
                require (statsArray[1] <= 200);
            if (fightArray[tokenId].Rarity == 1)
                require (statsArray[1] <= 300);
            
            _costToUpgrade = _costToUpgrade.add(statsArray[1].sub(fightArray[tokenId].Armour));
            fightArray[tokenId].Armour = statsArray[1]; 
        }
        
        //upgrade Attack
        if (fightArray[tokenId].Attack < statsArray[2])
        {
            if (fightArray[tokenId].Rarity == 4)
                require (statsArray[2] <= 100);
            if (fightArray[tokenId].Rarity == 3)
                require (statsArray[2] <= 150);
            if (fightArray[tokenId].Rarity == 2)
                require (statsArray[2] <= 200);
            if (fightArray[tokenId].Rarity == 1)
                require (statsArray[2] <= 300);
            
            _costToUpgrade = _costToUpgrade.add(statsArray[2].sub(fightArray[tokenId].Attack));
            fightArray[tokenId].Attack = statsArray[2]; 
        }
        
        //upgrade Defence
        if (fightArray[tokenId].Defence < statsArray[3])
        {
            if (fightArray[tokenId].Rarity == 4)
                require (statsArray[3] <= 100);
            if (fightArray[tokenId].Rarity == 3)
                require (statsArray[3] <= 150);
            if (fightArray[tokenId].Rarity == 2)
                require (statsArray[3] <= 200);
            if (fightArray[tokenId].Rarity == 1)
                require (statsArray[3] <= 300);
            
            _costToUpgrade = _costToUpgrade.add(statsArray[3].sub(fightArray[tokenId].Defence));
            fightArray[tokenId].Defence = statsArray[3];  
        }
        
        //upgrade Magic
        if (fightArray[tokenId].Magic < statsArray[4])
        {
            if (fightArray[tokenId].Rarity == 4)
                require (statsArray[4] <= 100);
            if (fightArray[tokenId].Rarity == 3)
                require (statsArray[4] <= 150);
            if (fightArray[tokenId].Rarity == 2)
                require (statsArray[4] <= 200);
            if (fightArray[tokenId].Rarity == 1)
                require (statsArray[4] <= 300);
            
            _costToUpgrade = _costToUpgrade.add(statsArray[4].sub(fightArray[tokenId].Magic));
            fightArray[tokenId].Magic = statsArray[4]; 
        }
        
         //upgrade Luck
        if (fightArray[tokenId].Luck < statsArray[5])
        {
            if (fightArray[tokenId].Rarity == 4)
                require (statsArray[5] <= 100);
            if (fightArray[tokenId].Rarity == 3)
                require (statsArray[5] <= 150);
            if (fightArray[tokenId].Rarity == 2)
                require (statsArray[5] <= 200);
            if (fightArray[tokenId].Rarity == 1)
                require (statsArray[5] <= 300);
            
            _costToUpgrade = _costToUpgrade.add(statsArray[5].sub(fightArray[tokenId].Luck));
            fightArray[tokenId].Luck = statsArray[5]; 
        }
        
        //upgrade Stamina
        if (fightArray[tokenId].Stamina<statsArray[6])
        {
            require (statsArray[6]<=5);
            _costToUpgrade = _costToUpgrade.add((statsArray[6].sub(fightArray[tokenId].Stamina)).mul(10));
            fightArray[tokenId].Stamina = statsArray[6]; 
        }
        
        if (_costToUpgrade > 0) {
            
            token.transferFrom(msg.sender, address(this), UPGRADE_PRICE.mul(_costToUpgrade));
            token.burn(UPGRADE_PRICE.mul(_costToUpgrade));
        }
    }
    
    /**
     * @dev Increases the wins. Only callable by the contract.
     *
     */
    function increaseWins(uint16 tokenId) external onlyTokenContract {
        fightArray[tokenId].winCount = fightArray[tokenId].winCount.add(1); 
    }
    
    /**
     * @dev Increases the losses. Only callable by the contract.
     *
     */
    function increaseLosses(uint16 tokenId) external onlyTokenContract {
        fightArray[tokenId].lossCount = fightArray[tokenId].lossCount.add(1);
    }
    
    /**
     * @dev Outputs the Stamina of a NFT.
     *
     */
    function getStamina(uint16 _id) external view returns (uint32) {
        return fightArray[_id].Stamina;    
    }
    
     /**
     * @dev Outputs the win count of a NFT.
     *
     */
    function getWinCount(uint16 _id) external view returns (uint32) {
        return fightArray[_id].winCount;
    }
    
    /**
     * @dev Outputs the loss count of a NFT.
     *
     */
    function getLossCount(uint16 _id) external view returns (uint32) {
        return fightArray[_id].lossCount;
    }
    
     /**
     * @dev Outputs the Stats of a NFT.
     *
     */
    function getStats(uint16 _id) external view returns (uint32, uint32, uint32, uint32, uint32, uint32) {
        return (fightArray[_id].Life, fightArray[_id].Armour, fightArray[_id].Attack, fightArray[_id].Defence, fightArray[_id].Magic, fightArray[_id].Luck);    
    }
    
    /**
     * @dev Outputs the battlePoints of a NFT 
     *
     */
    function calculateBattlePoints(uint16 _id) external view returns (uint32) {
       
        Stats memory catStats; 
       
        (catStats.life,catStats.armour,catStats.attack,catStats.defence,catStats.magic,catStats.luck) = (fightArray[_id].Life, fightArray[_id].Armour, fightArray[_id].Attack, fightArray[_id].Defence, fightArray[_id].Magic, fightArray[_id].Luck);
        uint randomLuck = uint256(keccak256(abi.encodePacked(block.timestamp+1 days, msg.sender, _id)));
        uint _LuckResult = (randomLuck.mod(catStats.luck)).mul(10);
            
        catStats.life = catStats.life.mul(10);
        catStats.armour = catStats.armour.mul(10);
        catStats.attack = catStats.attack.mul(10);
        catStats.defence = catStats.defence.mul(10);
        catStats.magic = catStats.magic.mul(10);
            
        uint32 statsPoints = catStats.life + catStats.armour + catStats.attack + catStats.defence + catStats.magic + uint32(_LuckResult);
        return statsPoints;
    }
    
     /**
     * @dev Changes the cost of upgrades.
     */
    function changeUpgradePrice(uint _newPrice) public onlyOwner{
       UPGRADE_PRICE = _newPrice; 
    } 
        
}