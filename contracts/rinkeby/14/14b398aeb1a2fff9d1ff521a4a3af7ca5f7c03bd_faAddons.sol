// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./IFA.sol"; 

contract faAddons is Ownable, ERC721, ERC721Enumerable {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    string private _baseTokenURI; 
    address private _AWTokenAddress;
    
    uint16 public constant PREMIUM_ADDON_SUPPLY = 500;
    uint16 public constant STANDARD_ADDON_SUPPLY = 4500;
    
    uint256 public PREMIUM_ADDON_PRICE = 200000000000000000;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x74a1476f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_RECEIVER = 0x150b7a02; 
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    address private _owner;
    address private _nftAddress;
    
    FAAD[] public faAddonArray;
    
    event NewFAAD(uint16 _typeId);
  
    struct FAAD {
        uint16 typeId; //1-6(for standard); 7-12(for premium);
        uint32 level; //for standard
    }
    
    
    struct Stats {
        uint32 life;
        uint32 armour;
        uint32 attack;
        uint32 defence;
        uint32 magic;
        uint32 luck;
    }
    
    
    uint32[2] public AddonsIndex  = [0, 0]; //Standard and Premium
    
    mapping (uint16 => uint16) public nftToAddonStandard;
    mapping (uint16 => uint16) public nftToAddonPremium;

    IERC20 private token;
    
     /**
     * @dev Sets the values for {name}, {symbol} and {baseTokenURI}.
     *      Sets the address of the associated token contract.
     * 
     */
    constructor(string memory name, string memory symbol, string memory baseTokenURI, address TokenAddress) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _AWTokenAddress = TokenAddress;
        
         // register supported interfaces
        supportsInterface(_INTERFACE_ID_ERC165);
        supportsInterface(_INTERFACE_ID_ERC20);
        supportsInterface(_INTERFACE_ID_ERC721);
        supportsInterface(_INTERFACE_ID_ERC721_RECEIVER);
        supportsInterface(_INTERFACE_ID_ERC721_METADATA);
        supportsInterface(_INTERFACE_ID_ERC721_ENUMERABLE); 
        
        token = IERC20(_AWTokenAddress);
        _owner = _msgSender();
    }
   
    /**
     * @dev Returns the baseTokenURI.
     *
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    

    /**
     * @dev safeTransferFrom override.
     *
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }


    /**
     * @dev See {IERC721}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev Withdraws ETH.
     */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    /**
     * @dev Only callable once, right after deployment.
     */
    function setNFTContractAddress(address nftAddress) public {
        require(_nftAddress == address(0), "Already set");
        
        _nftAddress = nftAddress;
    }
    
    
     
    
    /**
     * @dev Public NFT Addons creation function. 
     *
     */
    function mintFAAddons(uint16 _typeId) public payable {
        uint16 TOTAL_SUPPLY = PREMIUM_ADDON_SUPPLY + STANDARD_ADDON_SUPPLY;
        require(totalSupply() < TOTAL_SUPPLY, "Sale has already ended");
        
        if (_typeId>6)
        {
            require(PREMIUM_ADDON_PRICE == msg.value, "Ether value sent is not correct");
            require(AddonsIndex[1] < PREMIUM_ADDON_SUPPLY, "Premium addons sold out");
            AddonsIndex[1] = AddonsIndex[1].add(1);
        }
        
        else 
        {
            require(AddonsIndex[0] < STANDARD_ADDON_SUPPLY, "Premium addons sold out");
            AddonsIndex[0] = AddonsIndex[0].add(1);
        }
        
        uint mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
        faAddonArray.push(FAAD(_typeId,1));  
        emit NewFAAD(_typeId);
    }
    
    /**
     * @dev Public Assign Addon to a NFT. 
     *
     */
    function assignAddon(uint16 _addonId, uint16 _nftId) public  {
        address owner = ownerOf(_addonId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        if (faAddonArray[_addonId].typeId < 7)
            nftToAddonStandard[_nftId] = _addonId;
        else 
            nftToAddonPremium[_nftId] = _addonId;
    }
    

    /**
     * @dev Outputs the battlePoints of a NFT computed with addons.
     *
     */
    
    function newBattlePoints(uint16 _fromId, uint16 _toId) external view returns (uint32, uint32,uint32, uint32,uint32, uint32) {
       
        Stats[] memory statsIncreased;
        
        uint16 fromStandardAddonId = nftToAddonStandard[_fromId];
        //uint16 toStandardAddonId = nftToAddonStandard[_toId];
        
      /*uint16 fromPremiumAddonId = nftToAddonPremium[_fromId];
        uint16 toPremiumAddonId = nftToAddonPremium[_toId];
        
        uint32 _fromClass = IFA(_nftAddress).getClass(_fromId);
        uint32 _toClass = IFA(_nftAddress).getClass(_toId);
       */
        statsIncreased[fromStandardAddonId].life = IFA(_nftAddress).getLife(_fromId);
        statsIncreased[fromStandardAddonId].armour = IFA(_nftAddress).getArmour(_fromId);
        statsIncreased[fromStandardAddonId].attack = IFA(_nftAddress).getAttack(_fromId);
        statsIncreased[fromStandardAddonId].defence = IFA(_nftAddress).getDefence(_fromId);
        statsIncreased[fromStandardAddonId].magic = IFA(_nftAddress).getMagic(_fromId);
        statsIncreased[fromStandardAddonId].luck = IFA(_nftAddress).getLuck(_fromId);
        
        /*
        if (faAddonArray[fromStandardAddonId].typeId==1)
            statsIncreased[fromStandardAddonId].life = IFA(_nftAddress).getLife(_fromId) + faAddonArray[fromStandardAddonId].level;
        if (faAddonArray[fromStandardAddonId].typeId==2)
            statsIncreased[fromStandardAddonId].armour = IFA(_nftAddress).getArmour(_fromId) + faAddonArray[fromStandardAddonId].level;
        if (faAddonArray[fromStandardAddonId].typeId==3)
            statsIncreased[fromStandardAddonId].attack = IFA(_nftAddress).getAttack(_fromId) + faAddonArray[fromStandardAddonId].level;
        if (faAddonArray[fromStandardAddonId].typeId==4)
            statsIncreased[fromStandardAddonId].defence = IFA(_nftAddress).getDefence(_fromId) + faAddonArray[fromStandardAddonId].level;
        if (faAddonArray[fromStandardAddonId].typeId==5)
            statsIncreased[fromStandardAddonId].magic = IFA(_nftAddress).getMagic(_fromId) + faAddonArray[fromStandardAddonId].level;
        if (faAddonArray[fromStandardAddonId].typeId==6)
            statsIncreased[fromStandardAddonId].luck = IFA(_nftAddress).getLuck(_fromId) + faAddonArray[fromStandardAddonId].level;
             
        if (faAddonArray[toStandardAddonId].typeId==1)
            statsIncreased[toStandardAddonId].life = IFA(_nftAddress).getLife(_toId) + faAddonArray[toStandardAddonId].level; 
        if (faAddonArray[toStandardAddonId].typeId==2)
            statsIncreased[toStandardAddonId].armour = IFA(_nftAddress).getArmour(_toId) + faAddonArray[toStandardAddonId].level;
        if (faAddonArray[toStandardAddonId].typeId==3)
            statsIncreased[toStandardAddonId].attack = IFA(_nftAddress).getAttack(_toId) + faAddonArray[toStandardAddonId].level;
        if (faAddonArray[toStandardAddonId].typeId==4)
            statsIncreased[toStandardAddonId].defence = IFA(_nftAddress).getDefence(_toId) + faAddonArray[toStandardAddonId].level;
        if (faAddonArray[toStandardAddonId].typeId==5)
            statsIncreased[toStandardAddonId].magic = IFA(_nftAddress).getMagic(_toId) + faAddonArray[toStandardAddonId].level;
        if (faAddonArray[toStandardAddonId].typeId==6)
            statsIncreased[toStandardAddonId].luck = IFA(_nftAddress).getLuck(_toId) + faAddonArray[toStandardAddonId].level;
        */  
       
        return (statsIncreased[fromStandardAddonId].life, statsIncreased[fromStandardAddonId].armour, statsIncreased[fromStandardAddonId].attack, statsIncreased[fromStandardAddonId].defence, statsIncreased[fromStandardAddonId].magic, statsIncreased[fromStandardAddonId].luck);
        
        /*uint randomLuck = uint256(keccak256(abi.encodePacked(block.timestamp+1 days, msg.sender)));
        uint _luckFromMod = IFA(_nftAddress).getLuck(_fromId) + statsIncreased[fromStandardAddonId].luck;
        uint _luckResult = randomLuck.mod(_luckFromMod).mul(10);
        
        uint _luckToMod = IFA(_nftAddress).getLuck(_toId) + statsIncreased[toStandardAddonId].luck;
        uint _toLuckResult = randomLuck.mod(_luckToMod).mul(10);
            
        if ((faAddonArray[fromPremiumAddonId].typeId==7) || (faAddonArray[toPremiumAddonId].typeId==7)) // Only Luck
        {
            return uint32(_luckResult);
        }
        else if ((faAddonArray[fromPremiumAddonId].typeId==8) || (faAddonArray[toPremiumAddonId].typeId==8)) //Only Primary
        {
            if (_fromClass == 0) //solid 
                return statsIncreased[fromStandardAddonId].life.mul(11);
            else if (_fromClass == 1) //regular 
                return statsIncreased[fromStandardAddonId].armour.mul(11);
            else if (_fromClass == 2) //light 
                return statsIncreased[fromStandardAddonId].defence.mul(11);
            else if (_fromClass == 3) //thin 
                return statsIncreased[fromStandardAddonId].attack.mul(11);
            else  //duotone 
                return statsIncreased[fromStandardAddonId].magic.mul(11);
        }
        else if ((faAddonArray[fromPremiumAddonId].typeId==9) || (faAddonArray[toPremiumAddonId].typeId==9)) //Deny Luck
        {
            if (_fromClass == 0) { //solid
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(11);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else if (_fromClass == 1) { //regular 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(11);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else if (_fromClass == 2) { //light 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(11);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else if (_fromClass == 3) { //thin 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(11);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else { //duotone 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(11); 
            }
            
            uint32 statsPoints = statsIncreased[fromStandardAddonId].life + statsIncreased[fromStandardAddonId].armour + statsIncreased[fromStandardAddonId].attack + statsIncreased[fromStandardAddonId].defence;
            statsPoints = statsPoints + statsIncreased[fromStandardAddonId].magic;
            return statsPoints;
        }
        else if ((faAddonArray[fromPremiumAddonId].typeId==10) || (faAddonArray[toPremiumAddonId].typeId==10)) //Deny Primary bonus
        {
            statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
            statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
            statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
            statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
            statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10); 
            
            uint32 statsPoints = statsIncreased[fromStandardAddonId].life + statsIncreased[fromStandardAddonId].armour + statsIncreased[fromStandardAddonId].attack + statsIncreased[fromStandardAddonId].defence;
            statsPoints = statsPoints + statsIncreased[fromStandardAddonId].magic + uint32(_luckResult);
            return statsPoints;
        }
        else if ((faAddonArray[fromPremiumAddonId].typeId==11) || (faAddonArray[toPremiumAddonId].typeId==11)) //Switch Luck
        {
            if (_fromClass == 0) { //solid
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(11);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else if (_fromClass == 1) { //regular 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(11);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else if (_fromClass == 2) { //light 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(11);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else if (_fromClass == 3) { //thin 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(11);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else { //duotone 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(11); 
            }
            
            uint32 statsPoints = statsIncreased[fromStandardAddonId].life + statsIncreased[fromStandardAddonId].armour + statsIncreased[fromStandardAddonId].attack + statsIncreased[fromStandardAddonId].defence;
            statsPoints = statsPoints + statsIncreased[fromStandardAddonId].magic + uint32(_toLuckResult);
            return statsPoints;
        }
        else if ((faAddonArray[fromPremiumAddonId].typeId==12) || (faAddonArray[toPremiumAddonId].typeId==12)) //Switch Primary
        {
            if (_toClass == 0) { //solid
                statsIncreased[fromStandardAddonId].life = statsIncreased[toStandardAddonId].life.mul(11);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else if (_toClass == 1) { //regular 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[toStandardAddonId].armour.mul(11);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else if (_toClass == 2) { //light 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[toStandardAddonId].defence.mul(11);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else if (_toClass == 3) { //thin 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[toStandardAddonId].attack.mul(11);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else { //duotone 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[toStandardAddonId].magic.mul(11); 
            }
            
            uint32 statsPoints = statsIncreased[fromStandardAddonId].life + statsIncreased[fromStandardAddonId].armour + statsIncreased[fromStandardAddonId].attack + statsIncreased[fromStandardAddonId].defence;
            statsPoints = statsPoints + statsIncreased[fromStandardAddonId].magic + uint32(_luckResult);
            return statsPoints;
        }
        else { //normal play with standard addons
            if (_fromClass == 0) { //solid
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(11);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else if (_fromClass == 1) { //regular 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(11);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else if (_fromClass == 2) { //light 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(11);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else if (_fromClass == 3) { //thin 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(11);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(10);
            }
            else { //duotone 
                statsIncreased[fromStandardAddonId].life = statsIncreased[fromStandardAddonId].life.mul(10);
                statsIncreased[fromStandardAddonId].armour = statsIncreased[fromStandardAddonId].armour.mul(10);
                statsIncreased[fromStandardAddonId].attack = statsIncreased[fromStandardAddonId].attack.mul(10);
                statsIncreased[fromStandardAddonId].defence = statsIncreased[fromStandardAddonId].defence.mul(10);
                statsIncreased[fromStandardAddonId].magic = statsIncreased[fromStandardAddonId].magic.mul(11); 
            }
            
            uint32 statsPoints = statsIncreased[fromStandardAddonId].life + statsIncreased[fromStandardAddonId].armour + statsIncreased[fromStandardAddonId].attack + statsIncreased[fromStandardAddonId].defence;
            statsPoints = statsPoints + statsIncreased[fromStandardAddonId].magic + uint32(_luckResult);
            return statsPoints;
        }*/
    }
    
}