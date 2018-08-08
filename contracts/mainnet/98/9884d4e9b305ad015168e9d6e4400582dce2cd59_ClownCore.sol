pragma solidity ^0.4.23;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract token {
    function totalSupply() public view returns (uint total);
    function balanceOf(address _owner) public view returns (uint balance);
    function ownerOf(uint _tokenId) external view returns (address owner);
    function approve(address _to, uint _tokenId) external;
    function transfer(address _to, uint _tokenId) external;
    function transferFrom(address _from, address _to, uint _tokenId) external;

    event Transfer(address from, address to, uint tokenId);
    event Approval(address owner, address approved, uint tokenId);

    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


contract AccessControl {
    
    event ContractUpgrade(address newContract);

    address public ceoAddress;
    address public cooAddress;

    bool public paused = false;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress
        );
        _;
    }

    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}

contract Base is AccessControl {

    event Birth(address owner, uint clownId, uint matronId, uint sireId, uint genes);

    event Transfer(address from, address to, uint tokenId);

    event Match(uint clownId, uint price, address seller, address buyer);

    struct Clown {
        uint genes;
        uint64 birthTime;
        uint32 matronId;
        uint32 sireId;
        uint16 sex; // 1 0
        uint16 cooldownIndex;
        uint16 generation;
        uint16 growthAddition;
        uint16 attrPower;
        uint16 attrAgile;
        uint16 attrWisdom;
    }
    
    uint16[] digList = [300, 500, 800, 900, 950, 1000];

    uint16[] rankList;

    uint rankNum;
    uint16[] spRank1 = [5, 25, 75, 95, 99, 100]; 
    uint16[] spRank2 = [15, 50, 90, 100, 0, 0];  
    uint16[] norRank1 = [10, 50, 85, 99, 100, 0];
    uint16[] norRank2 = [25, 70, 100, 0, 0, 0];


    Clown[] clowns;

    mapping (uint => address) public clownIndexToOwner;

    mapping (address => uint) ownershipTokenCount;

    mapping (uint => address) public clownIndexToApproved;

    uint _seed = now;


    function _random(uint size) internal returns (uint) {
        _seed = uint(keccak256(keccak256(block.number, _seed), now));
        return _seed % size;
    }

    function _subGene(uint _gene, uint _start, uint _len) internal pure returns (uint) {
      uint result = _gene % (10**(_start+_len));
      result = result / (10**_start);
      return result;
    }

    function _transfer(address _from, address _to, uint _tokenId) internal {
        ownershipTokenCount[_to]++;
        clownIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete clownIndexToApproved[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }

    function _createClown(
        uint _matronId,
        uint _sireId,
        uint _generation,
        uint _genes,
        address _owner
    )
        internal
        returns (uint)
    {
        require(_matronId == uint(uint32(_matronId)));
        require(_sireId == uint(uint32(_sireId)));
        require(_generation == uint(uint16(_generation)));

        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 8) {
            cooldownIndex = 8;
        }
        uint16[] memory randomValue = new uint16[](3);
        
        uint spAttr = _random(3);
        for (uint j = 0; j < 3; j++) {
            if (spAttr == j) {
                if (_generation == 0 || _subGene(_genes, 0, 2) >= 30) {
                    rankList = spRank1;
                } else {
                    rankList = spRank2;
                }
            } else {
                if (_generation == 0 || _subGene(_genes, 0, 2) >= 30) {
                    rankList = norRank1;
                } else {
                    rankList = norRank2;
                }
            }

            uint digNum = _random(100);
            rankNum = 10;
            for (uint k = 0; k < 6; k++) {
                if (rankList[k] >= digNum && rankNum == 10) {
                    rankNum = k;
                }
            }
            
            if (rankNum == 0 || rankNum == 10) {
                randomValue[j] = 100 + uint16(_random(_genes) % 200);
            } else {
                randomValue[j] = digList[rankNum - 1] + uint16(_random(_genes) % (digList[rankNum] - digList[rankNum - 1]));
            }
        }

        Clown memory _clown = Clown({
            genes: _genes,
            birthTime: uint64(now),
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            sex: uint16(_genes % 2),
            cooldownIndex: cooldownIndex,
            generation: uint16(_generation),
            growthAddition: 0,
            attrPower: randomValue[0],
            attrAgile: randomValue[1],
            attrWisdom: randomValue[2]
        });
        uint newClownId = clowns.push(_clown) - 1;

        require(newClownId == uint(uint32(newClownId)));

        Birth(
            _owner,
            newClownId,
            uint(_clown.matronId),
            uint(_clown.sireId),
            _clown.genes
        );

        _transfer(0, _owner, newClownId);

        return newClownId;
    }

}

contract Ownership is Base, token, owned {

    string public constant name = "CryptoClown";
    string public constant symbol = "CC";

    uint public promoTypeNum;

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256(&#39;name()&#39;)) ^
        bytes4(keccak256(&#39;symbol()&#39;)) ^
        bytes4(keccak256(&#39;totalSupply()&#39;)) ^
        bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
        bytes4(keccak256(&#39;ownerOf(uint)&#39;)) ^
        bytes4(keccak256(&#39;approve(address,uint)&#39;)) ^
        bytes4(keccak256(&#39;transfer(address,uint)&#39;)) ^
        bytes4(keccak256(&#39;transferFrom(address,address,uint)&#39;)) ^
        bytes4(keccak256(&#39;tokensOfOwner(address)&#39;)) ^
        bytes4(keccak256(&#39;tokenMetadata(uint,string)&#39;));


    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    function _owns(address _claimant, uint _tokenId) internal view returns (bool) {
        return clownIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint _tokenId) internal view returns (bool) {
        return clownIndexToApproved[_tokenId] == _claimant;
    }

    function _approve(uint _tokenId, address _approved) internal {
        clownIndexToApproved[_tokenId] = _approved;
    }

    function balanceOf(address _owner) public view returns (uint count) {
        return ownershipTokenCount[_owner];
    }

    function transfer(
        address _to,
        uint _tokenId
    )
        external
        whenNotPaused
    {
        require(_to != address(0));
        require(_to != msg.sender);

        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }

    function approve(
        address _to,
        uint _tokenId
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _tokenId));

        _approve(_tokenId, _to);

        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint _tokenId
    )
        external
        whenNotPaused
    {
        require(_to != address(0));
        require(_to != msg.sender);
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return clowns.length - 2;
    }

    function ownerOf(uint _tokenId)
        external
        view
        returns (address owner)
    {
        owner = clownIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    function tokensOfOwner(address _owner) external view returns(uint[] ownerTokens) {
        uint tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint totalCats = totalSupply();
            uint resultIndex = 0;

            uint catId;

            for (catId = 1; catId <= totalCats; catId++) {
                if (clownIndexToOwner[catId] == _owner) {
                    result[resultIndex] = catId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

}


contract Minting is Ownership {

    uint public constant PROMO_CREATION_LIMIT = 5000;
    uint public constant GEN0_CREATION_LIMIT = 45000;

    uint public promoCreatedCount;
    uint public gen0CreatedCount;

    function createPromoClown(uint _genes, address _owner, bool _isNew) external onlyCOO {
        address clownOwner = _owner;
        if (clownOwner == address(0)) {
             clownOwner = cooAddress;
        }
        require(promoCreatedCount < PROMO_CREATION_LIMIT);
        if (_isNew) {
            promoTypeNum++;
        }

        promoCreatedCount++;
        _createClown(0, 0, 0, _genes, clownOwner);
    }

    function createGen0(uint _genes) external onlyCOO {
        require(gen0CreatedCount < GEN0_CREATION_LIMIT);

        _createClown(0, 0, 0, _genes, msg.sender);

        gen0CreatedCount++;
    }

    function useProps(uint[] _clownIds, uint16[] _values, uint16[] _types) public onlyCOO {
        for (uint16 j = 0; j < _clownIds.length; j++) {
            uint _clownId = _clownIds[j];
            uint16 _value = _values[j];
            uint16 _type = _types[j];
            Clown storage clown = clowns[_clownId];

            if (_type == 0) {
                clown.growthAddition += _value;
            } else if (_type == 1) {
                clown.attrPower += _value;
            } else if (_type == 2) {
                clown.attrAgile += _value;
            } else if (_type == 3) {
                clown.attrWisdom += _value;
            }
        }
    }

}

contract GeneScienceInterface {
    function isGeneScience() public pure returns (bool);
    function mixGenes(uint genes1, uint genes2, uint promoTypeNum) public returns (uint);
}


contract Breeding is Ownership {

    GeneScienceInterface public geneScience;

    function setGeneScienceAddress(address _address) external onlyCEO {
        GeneScienceInterface candidateContract = GeneScienceInterface(_address);

        require(candidateContract.isGeneScience());

        geneScience = candidateContract;
    }


    function _updateCooldown(Clown storage _clown) internal {
        if (_clown.cooldownIndex < 7) {
            _clown.cooldownIndex += 1;
        }
    }


    function giveBirth(uint _matronId, uint _sireId) external onlyCOO returns(uint) {
        Clown storage matron = clowns[_matronId];

        Clown storage sire = clowns[_sireId];

        // 限制公母
        require(sire.sex == 1);
        require(matron.sex == 0);
        require(_matronId != _sireId);

        _updateCooldown(sire);
        _updateCooldown(matron);

        require(matron.birthTime != 0);

        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

        uint mGenes = matron.genes;
        uint sGenes = sire.genes;
        uint childGenes = geneScience.mixGenes(mGenes, sGenes, promoTypeNum);
        
        address owner = clownIndexToOwner[_matronId];
        uint clownId = _createClown(_matronId, _sireId, parentGen + 1, childGenes, owner);

        return clownId;
    }
}



contract ClownCore is Minting, Breeding {

    address public newContractAddress;

    function ClownCore() public {
        paused = true;

        ceoAddress = msg.sender;

        cooAddress = msg.sender;

        _createClown(0, 0, 0, uint(-1), 0x0);
        _createClown(0, 0, 0, uint(-2), 0x0);
    }

    function setNewAddress(address _newAddress) external onlyCEO whenPaused {
        newContractAddress = _newAddress;
        ContractUpgrade(_newAddress);
    }

    function getClown(uint _id)
        external
        view
        returns (
        uint cooldownIndex,
        uint birthTime,
        uint matronId,
        uint sireId,
        uint sex,
        uint generation,
        uint genes,
        uint growthAddition,
        uint attrPower,
        uint attrAgile,
        uint attrWisdom
    ) {
        Clown storage clo = clowns[_id];

        cooldownIndex = uint(clo.cooldownIndex);
        birthTime = uint(clo.birthTime);
        matronId = uint(clo.matronId);
        sireId = uint(clo.sireId);
        sex = uint(clo.sex);
        generation = uint(clo.generation);
        genes = uint(clo.genes);
        growthAddition = uint(clo.growthAddition);
        attrPower = uint(clo.attrPower);
        attrAgile = uint(clo.attrAgile);
        attrWisdom = uint(clo.attrWisdom);
    }

    function unpause() public onlyCEO whenPaused {
        
        require(geneScience != address(0));
        require(newContractAddress == address(0));

        super.unpause();
    }

}