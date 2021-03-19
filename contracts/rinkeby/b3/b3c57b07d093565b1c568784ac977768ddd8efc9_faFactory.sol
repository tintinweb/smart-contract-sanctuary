// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";

contract faFactory is Ownable, ERC721, ERC721Enumerable {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    event NewFA(uint16 faId, uint32 dna);
    event StatsUpgraded(uint16 tokenId, uint32[7] statsArray);

    uint16 public FA_MAX_SUPPLY = 12125;
    uint32[5] public classIndex  = [0, 0, 0, 0, 0];
    uint256 public constant UPGRADE_PRICE = 1 * (10 ** 18);
  
    uint8 dnaDigits = 6; //1 + fa (1-2425) + class (1-5)
    uint32 dnaModulus = uint32(10 ** dnaDigits);
    uint cooldownTime = 1 days;
    string private _baseTokenURI; 
    address private _AWTokenAddress;

    FA[] public faArray;
  
    struct FA {
        uint32 dna;
        uint32 readyTime;
        uint32 winCount;
        uint32 lossCount;
        uint32 Stamina;
        uint32 Life;
        uint32 Armour;
        uint32 Attack;
        uint32 Defence;
        uint32 Magic;
        uint32 Rarity;
        string AnimationNColor;
    }

    mapping (uint16 => address) public faToOwner;
    mapping (address => uint) public ownerFACount;
  
    constructor(string memory name, string memory symbol, string memory baseTokenURI, address TokenAddress) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _AWTokenAddress = TokenAddress;
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
    
    function _createFA(uint32 _dna, uint32 _rarity) private validDna(_dna) {
        faArray.push(FA(_dna, uint32(block.timestamp), 0, 0, 5, 10, 10, 10, 10, 10, _rarity, "lime floating"));  
        uint16 id = uint16(faArray.length).sub(1);
        faToOwner[id] = msg.sender;
        ownerFACount[msg.sender] = ownerFACount[msg.sender].add(1);
        emit NewFA(id, _dna);
    }

    function _generateRandomRarity(uint _rarity) public view returns (uint32) {
        uint _randNonce = uint(keccak256(abi.encodePacked(_rarity))).mod(100);
        _randNonce = _randNonce.add(5);
        uint randRarity = uint(keccak256(abi.encodePacked(block.timestamp + 1 days, msg.sender, _randNonce))).mod(100);
        if (randRarity >= 95) {
            return 1; //legendary - 5% probability
        } else if (randRarity >= 85) {
            return 2; //epic - 10% probability
        } else if (randRarity >= 70) {    
            return 3; //rare - 15% probability
        } else 
            return 4; //common - 70% probability
    }

    function _makeFA(uint8 _class) internal  {
        require(classIndex[_class]<2425);
        uint32 _rarity =  _generateRandomRarity(classIndex[_class]);
        uint32 _dnaaux1 = classIndex[_class].mul(10);
        uint32 _dnaaux2 = _dnaaux1.add(100000);
        uint32 _dna = _dnaaux2.add(_class);
        classIndex[_class] = classIndex[_class].add(1);
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
            return 600000000000000000; // 6000 - 8999 0.6 ETH
        } else if (currentSupply >= 3000) {
            return 300000000000000000; // 3000 - 5999 0.3 ETH
        } else {
            return 100000000000000000; // 0 - 2999 0.1 ETH 
        }
    }
  
    function mintFA(uint256 _numberOfFA, uint8 _class) public payable {
        require(totalSupply() < FA_MAX_SUPPLY, "Sale has already ended");
        require(_numberOfFA > 0, "numberOfNfts cannot be 0");
        require(_numberOfFA <= 10, "You may not buy more than 10 FA at once");
        require(totalSupply().add(_numberOfFA) <= FA_MAX_SUPPLY, "Exceeds FA_MAX_SUPPLY");
        require(getFAPrice().mul(_numberOfFA) == msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < _numberOfFA; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            _makeFA(_class);
        }
    }
    
    function battlePoints(uint16 _id) public view returns (uint32){
        uint _class = faArray[_id].dna.mod(10);
        if (_class == 0) //solid
            return  (faArray[_id].Life * 11) + (faArray[_id].Armour * 10) + (faArray[_id].Attack * 10) + (faArray[_id].Defence * 10) + (faArray[_id].Magic * 10);
        else if (_class == 1) //regular
            return  (faArray[_id].Life * 10) + (faArray[_id].Armour * 11) + (faArray[_id].Attack * 10) + (faArray[_id].Defence * 10) + (faArray[_id].Magic * 10);
        else if (_class == 2) //light
            return  (faArray[_id].Life * 10) + (faArray[_id].Armour * 10) + (faArray[_id].Attack * 10) + (faArray[_id].Defence * 11) + (faArray[_id].Magic * 10);
        else if (_class == 3) //thin
            return  (faArray[_id].Life * 10) + (faArray[_id].Armour * 10) + (faArray[_id].Attack * 11) + (faArray[_id].Defence * 10) + (faArray[_id].Magic * 10);
        else                  //duotone
            return  (faArray[_id].Life * 10) + (faArray[_id].Armour * 10) + (faArray[_id].Attack * 10) + (faArray[_id].Defence * 10) + (faArray[_id].Magic * 11);
    }
    
    
     //inside ERC20 pentru ca trebe mint
   /* function battleFA(uint16 _fromId, uint16 _toId) external {
        require(msg.sender == faToOwner[_fromId]);
       
        if (battlePoints(_fromId) >= battlePoints(_toId)) {
            faArray[_fromId].winCount = faArray[_fromId].winCount.add(1);
            faArray[_toId].lossCount = faArray[_toId].lossCount.add(1);
            //make money for both mint 
        } else {
            faArray[_fromId].lossCount = faArray[_fromId].lossCount.add(1);
            faArray[_toId].winCount = faArray[_toId].winCount.add(1);
            //make money for both mint
        }
    }*/
    
    //inside ERC20 pentru ca trebe mint
    //function claim
    
    
    // statsArray (dna, Life, Armour, Attack, Defence, Magic, Stamina)
    function upgradeStats (uint16 tokenId, uint32[7] memory statsArray) public {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        
       uint32 _levelsToUpgrade = 0;
        
        //upgrade Life
        if (faArray[tokenId].Life<statsArray[1])
        {
            _levelsToUpgrade = _levelsToUpgrade.add(statsArray[1].sub(faArray[tokenId].Life));
            faArray[tokenId].Life = statsArray[1]; 
        }
        
        //upgrade Armour
        if (faArray[tokenId].Armour<statsArray[2])
        {
            _levelsToUpgrade = _levelsToUpgrade.add(statsArray[2].sub(faArray[tokenId].Armour));
            faArray[tokenId].Armour = statsArray[2]; 
        }
        
        //upgrade Attack
        if (faArray[tokenId].Attack<statsArray[3])
        {
            _levelsToUpgrade = _levelsToUpgrade.add(statsArray[3].sub(faArray[tokenId].Attack));
            faArray[tokenId].Attack = statsArray[3]; 
        }
        
        //upgrade Defence
        if (faArray[tokenId].Defence<statsArray[4])
        {
            _levelsToUpgrade = _levelsToUpgrade.add(statsArray[4].sub(faArray[tokenId].Defence));
            faArray[tokenId].Defence = statsArray[4];  
        }
        
        //upgrade Magic
        if (faArray[tokenId].Magic<statsArray[5])
        {
            _levelsToUpgrade = _levelsToUpgrade.add(statsArray[5].sub(faArray[tokenId].Magic));
            faArray[tokenId].Magic = statsArray[5]; 
        }
        
        //upgrade stamina
        if (faArray[tokenId].Stamina<statsArray[6])
        {
            _levelsToUpgrade = _levelsToUpgrade.add(statsArray[6].sub(faArray[tokenId].Stamina));
            faArray[tokenId].Stamina = statsArray[6]; 
        }
        
        IERC20(_AWTokenAddress).transferFrom(msg.sender, address(this), UPGRADE_PRICE.mul(_levelsToUpgrade));
        IERC20(_AWTokenAddress).burn(UPGRADE_PRICE.mul(_levelsToUpgrade));
        emit StatsUpgraded(tokenId, statsArray);
    }
    
    uint public testvar = 0;
    function test() public {
        
        IERC20(_AWTokenAddress).transferFrom(msg.sender, address(this), 1000000000000000000);
        IERC20(_AWTokenAddress).burn(1000000000000000000);
        testvar = testvar.add(1);
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
    
     function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}