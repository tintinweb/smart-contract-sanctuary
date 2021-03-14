// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract faFactory is Ownable, ERC721, ERC721Enumerable {

  using SafeMath for uint256;
  using SafeMath32 for uint32;
  using SafeMath16 for uint16;

  event NewFA(uint16 faId, uint32 dna);

  uint16 public FA_MAX_SUPPLY = 12125;
  uint16 public numberOfFAminted = 0;
  
  uint32[5] public classIndex  = [0, 0, 0, 0, 0];
  
  uint8 dnaDigits = 6; //1 + fa (1-2425) + class (1-5)
  uint32 dnaModulus = uint32(10 ** dnaDigits);
  uint cooldownTime = 1 days;
  string private _baseTokenURI; 

  FA[] public faArray;
  
  struct FA {
    uint32 dna;
    uint32 readyTime;
    uint32 winCount;
    uint32 lossCount;
    uint16 rarity;
    uint16 life;
    uint16 armour;
    uint16 attack;
    uint16 defence;
    uint16 magic;
    uint16 stamina;
    string colornanimation;
  }

  mapping (uint16 => address) public faToOwner;
  mapping (address => uint) public ownerFACount;
  
   constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
   }
   
   function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

  modifier validDna (uint32 _dna) {
    require(_dna.mod(dnaModulus) <= 124254);
    require(_dna.mod(dnaModulus.div(10)) <= 24254);
    require(_dna.mod(10) >= 0);
    require(_dna.mod(10) < 5);
    _;
  }
    
  function _createFA(uint32 _dna, uint16 _rarity) private validDna(_dna) {
    faArray.push(FA(_dna, uint32(block.timestamp), 0, 0, _rarity, 10, 10, 10, 10, 10, 5, "lime floating"));  
    uint16 id = uint16(faArray.length).sub(1);
    faToOwner[id] = msg.sender;
    ownerFACount[msg.sender] = ownerFACount[msg.sender].add(1);
    emit NewFA(id, _dna);
  }

  function _generateRandomRarity() internal view returns (uint16) {
    uint randRarity = uint(keccak256(abi.encodePacked(msg.sender, block.timestamp)));
    uint randRarity100 = randRarity.mod(100);
    uint16 _rarity = 0;
    
    if (randRarity100 < 70)
        _rarity = 1; //common - 70% probability
    if ((randRarity100 >= 70) && (randRarity100 < 85))
        _rarity = 2; //rare - 15% probability
    if ((randRarity100 >= 85) && (randRarity100 < 95))
        _rarity = 3; //epic - 10% probability
    if (randRarity100 >= 95)
        _rarity = 4; //legendary - 5% probability
        
    return _rarity;
  }

  function _makeFA(uint8 _class) internal  {
    require(classIndex[_class]<2425);
    uint16 _rarity =  _generateRandomRarity();
    uint32 _dnaaux1 = classIndex[_class].mul(10);
    uint32 _dnaaux2 = _dnaaux1.add(100000);
    uint32 _dna = _dnaaux2.add(_class);
    classIndex[_class] = classIndex[_class].add(1);
    numberOfFAminted = numberOfFAminted.add(1);
    _createFA(_dna, _rarity);
  }
  
   function getFAPrice() public view returns (uint256) {
        require(totalSupply() < FA_MAX_SUPPLY, "Sale has already ended");

        uint currentSupply = totalSupply();

        if (currentSupply >= 12123 ) {
            return 100000000000000000000; // 12123 - 12125  100 ETH
        } else if (currentSupply >= 12000 ) {
            return 3000000000000000000; // 12000 - 12123 3.0 ETH
        } else if (currentSupply >= 11000) {
            return 1700000000000000000; // 11000  - 11999 1.7 ETH
        } else if (currentSupply >= 9000) {
            return 1100000000000000000; // 9000 - 10999 1.1 ETH
        } else if (currentSupply >= 6000) {
            return 500000000000000000; // 6000 - 8999 0.6 ETH
        } else if (currentSupply >= 3000) {
            return 300000000000000000; // 3000 - 5999 0.3 ETH
        } else {
            return 100000000000000000; // 0 - 2999 0.1 ETH 
        }
    }
  
  function mintFA(uint256 _numberOfFA, uint8 _class) public payable {
        require(totalSupply() < FA_MAX_SUPPLY, "Sale has already ended");
        require(_numberOfFA > 0, "numberOfNfts cannot be 0");
        require(_numberOfFA <= 20, "You may not buy more than 10 FA at once");
        require(totalSupply().add(_numberOfFA) <= FA_MAX_SUPPLY, "Exceeds FA_MAX_SUPPLY");
        require(getFAPrice().mul(_numberOfFA) == msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < _numberOfFA; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            _makeFA(_class);
        }
    }
  
  
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}