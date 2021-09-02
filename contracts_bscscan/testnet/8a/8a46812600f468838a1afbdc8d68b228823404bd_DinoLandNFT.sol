// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721.sol";
import "./DinosAccessControl.sol";

contract DinoLandNFT is ERC721, DinosAccessControl {
    
    constructor() ERC721("DinosLandNFT", "DINO") {
        //Genesis Dino
        dinos.push(Dino(0, block.timestamp, block.timestamp));
        //Create some dinos for testing
        createDino(1111, msg.sender); // Normal Novis
        createDino(1212, msg.sender); // Rare Aquis
        createDino(1313, msg.sender); // Super Rare Terrot
        createDino(1313, msg.sender); // Super Rare Terrot
        createDino(1314, msg.sender); // Lengendary Terrot
        createDino(1315, msg.sender); // Mystic Terrot
    }
    
    struct Dino {
        uint256 genes;
        uint256 bornAt;
        uint256 coolDownEndAt;
    }
    
    mapping(address => uint256[]) userOwnedDinos;
    mapping(uint256 => uint256) public dinoIsAtIndex;
    
    Dino[] dinos;
    
    event DinoSpawned(uint256 indexed _dinoId, address indexed _owner, uint256 _genes);
    event DinoRetired(uint256 indexed _dinoId);
    event DinoEvolved(uint256 indexed _dinoId, uint256 _oldGenes, uint256 _newGenes);
    
    modifier noContract() {
        require(!isContract(msg.sender), "Can not call from another contract");
        _;
    }
    
    modifier onlyDinoOwner(uint _dinoId) {
        require(ownerOf(_dinoId) == msg.sender, "You do not have permission");
        _;
    }
    
    modifier onlyEgg(uint _dinoId) {
        require(dinos[_dinoId].genes / 1000 == 0, "It is not an egg");
        _;
    }
    
    modifier onlyEggReady(uint _dinoId) {
        require(block.timestamp >= dinos[_dinoId].coolDownEndAt, "Egg is not ready");
        _;
    }
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    function getDino(uint _dinoId) external view returns(uint256, uint256, uint256) {
        Dino memory dino = dinos[_dinoId];
        return (dino.genes, dino.bornAt, dino.coolDownEndAt);
    }
    
    function getDinosByOwner(address _ownerAddress) public view returns(uint256[] memory) {
        return userOwnedDinos[_ownerAddress];
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    
    //Create dino
    function createDino(uint256 _genes, address _owner)
        onlyCLevel
        public
        returns (uint256)
    {
        require(_genes >= 1111 , "Dino genes is not valid");
        uint256 dinoId = _createDino(_genes, _owner, block.timestamp);
        userOwnedDinos[msg.sender].push(dinoId);
        uint256 arrayLength = userOwnedDinos[msg.sender].length;
        dinoIsAtIndex[dinoId] = arrayLength;
        emit DinoSpawned(dinoId, _owner, _genes);
        return dinoId;
    }
    //Create dino egg
     function createDinoEgg(uint256 _genes, address _owner, uint _incubationDuraion)
        onlyCLevel
        external
        returns (uint256)
    {
        require(_genes / 1000 == 0 , "Dino egg genes is not valid");
        uint256 _dinoId = _createDino(_genes, _owner, block.timestamp + _incubationDuraion);
        return _dinoId;
    }
    //Retire dino
     function retireDino(
        uint256 _dinoId,
        bool _rip
      )
        external
        onlyCLevel
      {
        _burn(_dinoId);
    
        if (_rip) {
          delete dinos[_dinoId];
        }
    
        emit DinoRetired(_dinoId);
      }
    //Envolve Dino
    function evolveDino(
        uint256 _dinoId,
        uint256 _newGenes
      )
        external
        onlyCLevel
      {
        require(_newGenes >= 1111 , "Dino genes is not valid");
        uint256 _oldGenes = dinos[_dinoId].genes;
        dinos[_dinoId].genes = _newGenes;
        emit DinoEvolved(_dinoId, _oldGenes, _newGenes);
      }
    function _createDino(uint256 _genes, address _owner, uint256 _coolDownEndAt)
        private
        returns (uint256)
    {
        Dino memory dino = Dino(_genes, block.timestamp, _coolDownEndAt);
        dinos.push(dino);
        uint256 _dinoId = dinos.length - 1;
        _mint(_owner, _dinoId);
        return _dinoId;
    }
    
    //Dinos Egg Generation
    
    /*
    NFT Genes:
    Egg: xx
    Format: 10 - Random Egg -  33% Novis, 33%Aquis, 33%Terrot
            11 - Novis
            12 - Aquis
            13 - Terrot
    Dino: xxxx
    First two digits format:
            11 - Novis
            12 - Aquis
            13 - Terrot
    Second two digits format:
            11 - Normal - 53%
            12 - Rare - 30%
            13 - Super rare -10%
            14 - Lengendary - 5%
            15 - Mystic - 2%
    */
    
    uint randomCount = 0;
    
    function hatchEgg(uint256 _dinoId) external onlyDinoOwner(_dinoId) onlyEgg(_dinoId) onlyEggReady(_dinoId) noContract {
        uint newGenes = _getRandomDinoGenesFromEgg(dinos[_dinoId].genes);
        dinos[_dinoId].genes = newGenes;
    }
    
    function createDinoFromEggGenes(uint256 _eggGenes, address _owner) external onlyCLevel noContract returns(uint256) {
         uint newGenes = _getRandomDinoGenesFromEgg(_eggGenes);
         uint256 newDinoId = createDino(newGenes, _owner);
         return newDinoId;
    }
    
    
    function _getRandomPercent() private returns(uint _rand) {
        uint rand = uint(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty, "Dinos Crypto", randomCount++)))%100 + 1;
        return rand;
    }
    
    
    function _getRandomDinoGenesFromEgg(uint _eggGenes) private returns(uint _randomGenes) {
        require(_eggGenes / 1000 == 0, "Not valid egg genes");
        if(_eggGenes == 10) {
            uint randEggNumber = _getRandomPercent();
            if(randEggNumber <= 33) {
                _eggGenes = 11;
            } else if(randEggNumber <= 66) {
                _eggGenes = 12;
            } else {
                _eggGenes = 13;
            }
        }
        uint randRareNumber = _getRandomPercent();
        
        if(randRareNumber <= 53) {
            return _eggGenes*100 + 11;
        } else if(randRareNumber <= 83) {
            return _eggGenes*100 + 12;
        } else if(randRareNumber <= 93) {
            return _eggGenes*100 + 13;
        } else if(randRareNumber <= 98) {
            return _eggGenes*100 + 14;
        } else {
            return _eggGenes*100 + 15;
        }
    }
    
}