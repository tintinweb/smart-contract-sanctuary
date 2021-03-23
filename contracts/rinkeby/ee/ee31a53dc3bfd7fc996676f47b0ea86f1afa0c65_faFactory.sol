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

    uint16 public constant FA_MAX_SUPPLY = 12125;
    uint256 public constant UPGRADE_PRICE = 10000000000000000000;
    uint32[5] public classIndex  = [0, 0, 0, 0, 0];
    
    uint8 dnaDigits = 6; //1 + fa (1-2425) + class (1-5)
    uint32 dnaModulus = uint32(10 ** dnaDigits);
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
        uint32 Luck;
        string AnimationNColor;
    }

    mapping (uint16 => address) public faToOwner;
    //mapping (address => uint) public ownerFACount;
    mapping (uint16 => bool) public bannedNFT;
  
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x74a1476f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_RECEIVER = 0x150b7a02; 
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    
    IERC20 private token;
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
    }
   
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    modifier onlyAWTokenContract() {
        require(msg.sender == _AWTokenAddress);
        _;
    }
    
    function _increaseWins(uint16 tokenId) external onlyAWTokenContract {
        faArray[tokenId].winCount = faArray[tokenId].winCount.add(1);
    }
    
    function _increaseLosses(uint16 tokenId) external onlyAWTokenContract {
        faArray[tokenId].lossCount = faArray[tokenId].lossCount.add(1);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        faToOwner[uint16(tokenId)] = to;
        //ownerFACount[from] = ownerFACount[from].sub(1);
        //ownerFACount[to] = ownerFACount[to].add(1);
        safeTransferFrom(from, to, tokenId, "");
    }

    modifier validDna (uint32 _dna) {
        require(_dna.mod(dnaModulus) <= 124254);
        require(_dna.mod(dnaModulus.div(10)) <= 24254);
        require(_dna.mod(10) >= 0);
        require(_dna.mod(10) < 5);
        _;
    }
    
    function _createFA(uint32 _dna, uint32 _rarity, uint32 _luck) private validDna(_dna) {
        faArray.push(FA(_dna, uint32(block.timestamp), 0, 0, 5, 10, 10, 10, 10, 10, _rarity, _luck, "lime floating"));  
        uint16 id = uint16(faArray.length).sub(1);
        faToOwner[id] = msg.sender;
        bannedNFT[id] = false;
        //ownerFACount[msg.sender] = ownerFACount[msg.sender].add(1);
        emit NewFA(id, _dna);
    }

    function _generateRandomRarity(uint _input) public view returns (uint32) {
        uint _randNonce = uint(keccak256(abi.encodePacked(_input))).mod(100);
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
    
    function _generateRandomLuck(uint _input) public view returns (uint32) {
        uint _randNonce = uint(keccak256(abi.encodePacked(_input))).mod(100);
        _randNonce = _randNonce.add(10);
        uint randLuck = uint(keccak256(abi.encodePacked(block.timestamp + 1 days, msg.sender, _randNonce))).mod(10);
        return uint32(randLuck); 
    }

    function _makeFA(uint8 _class) internal  {
        require(classIndex[_class]<2425);
        uint32 _rarity =  _generateRandomRarity(classIndex[_class]);
        uint32 _dnaaux1 = classIndex[_class].mul(10);
        uint32 _dnaaux2 = _dnaaux1.add(100000);
        uint32 _dna = _dnaaux2.add(_class);
        classIndex[_class] = classIndex[_class].add(1);
        uint32 _luck =  _generateRandomLuck(classIndex[_class]);
        _createFA(_dna, _rarity, _luck);
    }
  
    function getFAPrice(uint256 _numberOfFA) public view returns (uint256) {
        require(totalSupply() < FA_MAX_SUPPLY, "Sale has already ended");
        uint currentSupply = totalSupply();
        uint part;
        uint firstpart;
        uint secondpart;
        
        if (currentSupply >= 12123 ) {
            return uint(100000000000000000000).mul(_numberOfFA); // 12123 - 12125  100 ETH
        } else if (currentSupply >= 12000 ) {
            if (currentSupply.add(_numberOfFA) > 12122) {
                part = uint(12122).sub(currentSupply);
                firstpart = part.mul(3000000000000000000);
                secondpart = (_numberOfFA.sub(part)).mul(100000000000000000000);
                return firstpart.add(secondpart);
            } 
            else
                return uint(3000000000000000000).mul(_numberOfFA); // 12000 - 12122 3.0 ETH
        } else if (currentSupply >= 11000) {
            if (currentSupply.add(_numberOfFA) >= 11999){
                part = uint(11999).sub(currentSupply);
                firstpart = part.mul(1700000000000000000);
                secondpart = (_numberOfFA.sub(part)).mul(3000000000000000000);
                return firstpart.add(secondpart);
            }
            else
                return uint(1700000000000000000).mul(_numberOfFA); // 11000  - 11999 1.7 ETH
        } else if (currentSupply >= 9000) {
            if (currentSupply.add(_numberOfFA) > 10999){
                part = uint(10999).sub(currentSupply);
                firstpart = part.mul(1100000000000000000);
                secondpart = (_numberOfFA.sub(part)).mul(1700000000000000000);
                return firstpart.add(secondpart);
            }
            else
                return uint(1100000000000000000).mul(_numberOfFA); // 9000 - 10999 1.1 ETH
        } else if (currentSupply >= 6000) {
             if (currentSupply.add(_numberOfFA) > 8999){
                part = uint(8999).sub(currentSupply);
                firstpart = part.mul(600000000000000000);
                secondpart = (_numberOfFA.sub(part)).mul(1100000000000000000);
                return firstpart.add(secondpart);
            }
            else
                return uint(600000000000000000).mul(_numberOfFA); // 6000 - 8999 0.6 ETH
        } else if (currentSupply >= 3000) {
            if (currentSupply.add(_numberOfFA) > 5999){
                part = uint(5999).sub(currentSupply);
                firstpart = part.mul(300000000000000000);
                secondpart = (_numberOfFA.sub(part)).mul(600000000000000000);
                return firstpart.add(secondpart);
            }
            else
                return uint(300000000000000000).mul(_numberOfFA); // 3000 - 5999 0.3 ETH
        } else {
            if (currentSupply.add(_numberOfFA) > 2999){
                part = uint(2999).sub(currentSupply);
                firstpart = part.mul(100000000000000000);
                secondpart = (_numberOfFA.sub(part)).mul(300000000000000000);
                return firstpart.add(secondpart);
            }
            else
                return uint(100000000000000000).mul(_numberOfFA); // 0 - 2999 0.1 ETH 
        }
    }
  
    function mintFA(uint256 _numberOfFA, uint8 _class) public payable {
        require(totalSupply() < FA_MAX_SUPPLY, "Sale has already ended");
        require(_numberOfFA > 0, "numberOfNfts cannot be 0");
        require(_numberOfFA <= 10, "You may not buy more than 10 AW nifties at once");
        require(totalSupply().add(_numberOfFA) <= FA_MAX_SUPPLY, "Exceeds FA_MAX_SUPPLY");
        require(getFAPrice(_numberOfFA) == msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < _numberOfFA; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            _makeFA(_class);
        }
    }
    
    function battlePoints(uint16 _id) external view returns (uint32) {
        uint _class = faArray[_id].dna.mod(10);
        if (_class == 0) //solid
            return  (faArray[_id].Life * 11) + (faArray[_id].Armour * 10) + (faArray[_id].Attack * 10) + (faArray[_id].Defence * 10) + (faArray[_id].Magic * 10) + (faArray[_id].Luck * 10);
        else if (_class == 1) //regular
            return  (faArray[_id].Life * 10) + (faArray[_id].Armour * 11) + (faArray[_id].Attack * 10) + (faArray[_id].Defence * 10) + (faArray[_id].Magic * 10) + (faArray[_id].Luck * 10);
        else if (_class == 2) //light
            return  (faArray[_id].Life * 10) + (faArray[_id].Armour * 10) + (faArray[_id].Attack * 10) + (faArray[_id].Defence * 11) + (faArray[_id].Magic * 10) + (faArray[_id].Luck * 10);
        else if (_class == 3) //thin
            return  (faArray[_id].Life * 10) + (faArray[_id].Armour * 10) + (faArray[_id].Attack * 11) + (faArray[_id].Defence * 10) + (faArray[_id].Magic * 10) + (faArray[_id].Luck * 10);
        else                  //duotone
            return  (faArray[_id].Life * 10) + (faArray[_id].Armour * 10) + (faArray[_id].Attack * 10) + (faArray[_id].Defence * 10) + (faArray[_id].Magic * 11) + (faArray[_id].Luck * 10);
    }
    
    function getStamina(uint16 _id) external view returns (uint32) {
        return faArray[_id].Stamina;    
    }
    
  
    /**
     * @dev  statsArray (Life, Armour, Attack, Defence, Magic, Luck, Stamina)
     */
    function upgradeStats (uint16 tokenId, uint32[7] memory statsArray) public {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(!bannedNFT[tokenId], "This NFT is banned");
        
        uint32 _costToUpgrade = 0;
        
        //upgrade Life
        if (faArray[tokenId].Life < statsArray[0])
        {
            if (faArray[tokenId].Rarity == 4)
                require (statsArray[0] <= 40);
            if (faArray[tokenId].Rarity == 3)
                require (statsArray[0] <= 50);
            if (faArray[tokenId].Rarity == 2)
                require (statsArray[0] <= 60);
            if (faArray[tokenId].Rarity == 1)
                require (statsArray[0] <= 70);
                
            _costToUpgrade = _costToUpgrade.add(statsArray[0].sub(faArray[tokenId].Life));
            faArray[tokenId].Life = statsArray[0]; 
        }
        
        //upgrade Armour
        if (faArray[tokenId].Armour < statsArray[1])
        {
            if (faArray[tokenId].Rarity == 4)
                require (statsArray[1] <= 40);
            if (faArray[tokenId].Rarity == 3)
                require (statsArray[1] <= 50);
            if (faArray[tokenId].Rarity == 2)
                require (statsArray[1] <= 60);
            if (faArray[tokenId].Rarity == 1)
                require (statsArray[1] <= 70);
            
            _costToUpgrade = _costToUpgrade.add(statsArray[1].sub(faArray[tokenId].Armour));
            faArray[tokenId].Armour = statsArray[1]; 
        }
        
        //upgrade Attack
        if (faArray[tokenId].Attack < statsArray[2])
        {
            if (faArray[tokenId].Rarity == 4)
                require (statsArray[2] <= 40);
            if (faArray[tokenId].Rarity == 3)
                require (statsArray[2] <= 50);
            if (faArray[tokenId].Rarity == 2)
                require (statsArray[2] <= 60);
            if (faArray[tokenId].Rarity == 1)
                require (statsArray[2] <= 70);
            
            _costToUpgrade = _costToUpgrade.add(statsArray[2].sub(faArray[tokenId].Attack));
            faArray[tokenId].Attack = statsArray[2]; 
        }
        
        //upgrade Defence
        if (faArray[tokenId].Defence < statsArray[3])
        {
            if (faArray[tokenId].Rarity == 4)
                require (statsArray[3] <= 40);
            if (faArray[tokenId].Rarity == 3)
                require (statsArray[3] <= 50);
            if (faArray[tokenId].Rarity == 2)
                require (statsArray[3] <= 60);
            if (faArray[tokenId].Rarity == 1)
                require (statsArray[3] <= 70);
            
            _costToUpgrade = _costToUpgrade.add(statsArray[3].sub(faArray[tokenId].Defence));
            faArray[tokenId].Defence = statsArray[3];  
        }
        
        //upgrade Magic
        if (faArray[tokenId].Magic < statsArray[4])
        {
            if (faArray[tokenId].Rarity == 4)
                require (statsArray[4] <= 40);
            if (faArray[tokenId].Rarity == 3)
                require (statsArray[4] <= 50);
            if (faArray[tokenId].Rarity == 2)
                require (statsArray[4] <= 60);
            if (faArray[tokenId].Rarity == 1)
                require (statsArray[4] <= 70);
            
            _costToUpgrade = _costToUpgrade.add(statsArray[4].sub(faArray[tokenId].Magic));
            faArray[tokenId].Magic = statsArray[4]; 
        }
        
         //upgrade Luck
        if (faArray[tokenId].Luck < statsArray[5])
        {
            if (faArray[tokenId].Rarity == 4)
                require (statsArray[5] <= 40);
            if (faArray[tokenId].Rarity == 3)
                require (statsArray[5] <= 50);
            if (faArray[tokenId].Rarity == 2)
                require (statsArray[5] <= 60);
            if (faArray[tokenId].Rarity == 1)
                require (statsArray[5] <= 70);
            
            _costToUpgrade = _costToUpgrade.add(statsArray[5].sub(faArray[tokenId].Luck));
            faArray[tokenId].Luck = statsArray[5]; 
        }
        
        //upgrade Stamina
        if (faArray[tokenId].Stamina<statsArray[6])
        {
            require (statsArray[6]<=10);
            _costToUpgrade = _costToUpgrade.add((statsArray[6].sub(faArray[tokenId].Stamina)).mul(10));
            faArray[tokenId].Stamina = statsArray[6]; 
        }
        
        if (_costToUpgrade > 0) {
            token.transferFrom(msg.sender, address(this), UPGRADE_PRICE.mul(_costToUpgrade));
            token.burn(UPGRADE_PRICE.mul(_costToUpgrade));
            emit StatsUpgraded(tokenId, statsArray);
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
    
    /**
     * @dev withdraws ETH.
     */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    /**
     * @dev Bans NFT in case of contract exploit.
     */
    function banNFT(uint16 tokenId) onlyOwner public {
        bannedNFT[tokenId] = true;
    }
    
    /**
     * @dev Unbans NFT.
     */
    function unbanNFT(uint16 tokenId) onlyOwner public {
        bannedNFT[tokenId] = false;
    }
    
    /**
     * @dev Checks the status of a NFT (banned = true / not banned = false).
     */
    function isBanned(uint16 tokenId) external view returns (bool) {
       return bannedNFT[tokenId];
    }
    
    
}