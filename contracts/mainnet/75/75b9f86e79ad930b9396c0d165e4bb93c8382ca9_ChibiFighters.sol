pragma solidity ^0.4.21;

// ----------------------------------------------------------------------------
// Contract owner and transfer functions
// just in case someone wants to get my bacon
// ----------------------------------------------------------------------------
contract ContractOwned {
    address public contract_owner;
    address public contract_newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        contract_owner = msg.sender;
    }

    modifier contract_onlyOwner {
        require(msg.sender == contract_owner);
        _;
    }

    function transferOwnership(address _newOwner) public contract_onlyOwner {
        contract_newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == contract_newOwner);
        emit OwnershipTransferred(contract_owner, contract_newOwner);
        contract_owner = contract_newOwner;
        contract_newOwner = address(0);
    }
}


/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, returns 0 if it would go into minus range.
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b >= a) {
            return 0;
        }
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/** 
* ERC721 compatibility from
* https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC721/ERC721Token.sol
* plus our magic sauce
*/ 

/**
* @title Custom CustomEvents
* @dev some custom events specific to this contract
*/
contract CustomEvents {
    event ChibiCreated(uint tokenId, address indexed _owner, bool founder, string _name, uint16[13] dna, uint father, uint mother, uint gen, uint adult, string infoUrl);
    event ChibiForFusion(uint tokenId, uint price);
    event ChibiForFusionCancelled(uint tokenId);
    event WarriorCreated(uint tokenId, string battleRoar);
}

/**
* @title ERC721 interface
* @dev see https://github.com/ethereum/eips/issues/721
*/
contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function transfer(address _to, uint256 _tokenId) public;
    function approve(address _to, uint256 _tokenId) public;
    function takeOwnership(uint256 _tokenId) public;
    function tokenMetadata(uint256 _tokenId) constant public returns (string infoUrl);
    function tokenURI(uint256 _tokenId) public view returns (string);
}


// interacting with gene contract
contract GeneInterface {
    // creates genes when bought directly on this contract, they will always be superb
    // address, seed, founder, tokenId
    function createGenes(address, uint, bool, uint, uint) external view returns (
    uint16[13] genes
);
 
// transfusion chamber, no one really knows what that crazy thing does
// except the scientists, but they giggle all day long
// address, seed, tokenId
function splitGenes(address, uint, uint) external view returns (
    uint16[13] genes
    );
    function exhaustAfterFusion(uint _gen, uint _counter, uint _exhaustionTime) public pure returns (uint);
    function exhaustAfterBattle(uint _gen, uint _exhaust) public pure returns (uint);
        
}

// interacting with fcf contract
contract FcfInterface {
    function balanceOf(address) public pure returns (uint) {}
    function transferFrom(address, address, uint) public pure returns (bool) {}
}

// interacting with battle contract
contract BattleInterface {
    function addWarrior(address, uint, uint8, string) pure public returns (bool) {}
    function isDead(uint) public pure returns (bool) {}
}
 

/**
 * @title ERC721Token
 * Generic implementation for the required functionality of the ERC721 standard
 */
contract ChibiFighters is ERC721, ContractOwned, CustomEvents {
    using SafeMath for uint256;

    // Total amount of tokens
    uint256 private totalTokens;

    // Mapping from token ID to owner
    mapping (uint256 => address) private tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private tokenApprovals;

    // Mapping from owner to list of owned token IDs
    mapping (address => uint256[]) private ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private ownedTokensIndex;

    // interfaces for other contracts, so updates are possible
    GeneInterface geneContract;
    FcfInterface fcfContract;
    BattleInterface battleContract;
    address battleContractAddress;

    // default price for 1 Chibi
    uint public priceChibi;
    // minimum price for fusion chibis
    uint priceFusionChibi;

    // counter that keeps upping with each token
    uint uniqueCounter;

    // time to become adult
    uint adultTime;

    // recovery time after each fusion
    uint exhaustionTime;
    
    // our comission
    uint comission;
    
    // battleRemoveContractAddress to remove from array
    address battleRemoveContractAddress;

    struct Chibi {
        // address of current chibi owner
        address owner;
        // belongs to og
        bool founder;
        // name of the chibi, chibis need names
        string nameChibi;
        // the dna, specifies, bodyparts, etc.
        // array is easier to decode, but we are not reinventing the wheel here
        uint16[13] dna;
        // originates from tokenIds, gen0s will return 0
        // uint size only matters in structs
        uint256 father;
        uint256 mother;
        // generations, gen0 is created from the incubator, they are pure
        // but of course the funniest combos will come from the fusion chamber
        uint gen;
        // fusions, the beautiful fusion Chibis that came out of this one
        uint256[] fusions;
        // up for fusion?
        bool forFusion;
        // cost to fusion with this Chibi, can be set by player at will
        uint256 fusionPrice;
        // exhaustion after fusion
        uint256 exhausted;
        // block after which chibi is an adult 
        uint256 adult;
        // info url
        string infoUrl;
    }

    // the link to chibis website
    string _infoUrlPrefix;

    Chibi[] public chibies;

    string public constant name = "Chibi Fighters";
    string public constant symbol = "CBF";

    // pause function so fusion and minting can be paused for updates
    bool paused;
    bool fcfPaused;
    bool fusionPaused; // needed so founder can fuse while game is paused

    /**
    * @dev Run only once at contract creation
    */
    constructor() public {
        // a helping counter to keep chibis unique
        uniqueCounter = 0;
        // inital price in wei
        priceChibi = 100000000000000000;
        // default price to allow fusion
        priceFusionChibi = 10000000000000000;
        // time to become adult
        adultTime = 2 hours;
        //exhaustionTime = 3 hours;
        exhaustionTime = 1 hours;
        // start the contract paused
        paused = true;
        fcfPaused = true;
        fusionPaused = true;
        // set comission percentage 100-90 = 10%
        comission = 90; 

        _infoUrlPrefix = "http://chibigame.io/chibis.php?idj=";
    }
    
    /**
    * @dev Set Comission rate 100-x = %
    * @param _comission Rate inverted
    */
    function setComission(uint _comission) public contract_onlyOwner returns(bool success) {
        comission = _comission;
        return true;
    }
    
    /**
    * @dev Set minimum price for fusion Chibis in Wei
    */
    function setMinimumPriceFusion(uint _price) public contract_onlyOwner returns(bool success) {
        priceFusionChibi = _price;
        return true;
    }
    
    /**
    * @dev Set time until Chibi is considered adult
    * @param _adultTimeSecs Set time in seconds
    */
    function setAdultTime(uint _adultTimeSecs) public contract_onlyOwner returns(bool success) {
        adultTime = _adultTimeSecs;
        return true;
    }

    /**
    * @dev Fusion Chamber Cool down
    * @param _exhaustionTime Set time in seconds
    */
    function setExhaustionTime(uint _exhaustionTime) public contract_onlyOwner returns(bool success) {
        exhaustionTime = _exhaustionTime;
        return true;
    }
    
    /**
    * @dev Set game state paused for updates, pauses the entire creation
    * @param _setPaused Boolean sets the game paused or not
    */
    function setGameState(bool _setPaused) public contract_onlyOwner returns(bool _paused) {
        paused = _setPaused;
        fcfPaused = _setPaused;
        fusionPaused = _setPaused;
        return paused;
    }
    
    /**
    * @dev Set game state for fcf tokens only, so Founder can get Chibis pre launch
    * @param _setPaused Boolean sets the game paused or not
    */
    function setGameStateFCF(bool _setPaused) public contract_onlyOwner returns(bool _pausedFCF) {
        fcfPaused = _setPaused;
        return fcfPaused;
    }
    
    /**
    * @dev unpause Fusions so Founder can Fuse
    * @param _setPaused Boolean sets the game paused or not
    */
    function setGameStateFusion(bool _setPaused) public contract_onlyOwner returns(bool _pausedFusions) {
        fusionPaused = _setPaused;
        return fusionPaused;
    }

    /**
    * @dev Query game state. Paused (True) or not?
    */
    function getGameState() public constant returns(bool _paused) {
        return paused;
    }

    /**
    * @dev Set url prefix, of course that won`t change the existing Chibi urls on chain
    */
    function setInfoUrlPrefix(string prefix) external contract_onlyOwner returns (bool success) {
        _infoUrlPrefix = prefix;
        return true;
    }

    /**
    * @dev Connect to Founder contract so user can pay in FCF
    */
    function setFcfContractAddress(address _address) external contract_onlyOwner returns (bool success) {
        fcfContract = FcfInterface(_address);
        return true;
    }

    /**
    * @dev Connect to Battle contract
    */
    function setBattleContractAddress(address _address) external contract_onlyOwner returns (bool success) {
        battleContract = BattleInterface(_address);
        battleContractAddress = _address;
        return true;
    }
    
    /**
    * @dev Connect to Battle contract
    */
    function setBattleRemoveContractAddress(address _address) external contract_onlyOwner returns (bool success) {
        battleRemoveContractAddress = _address;
        return true;
    }

    /**
    * @dev Rename a Chibi
    * @param _tokenId ID of the Chibi
    * @param _name Name of the Chibi
    */
    function renameChibi(uint _tokenId, string _name) public returns (bool success){
        require(ownerOf(_tokenId) == msg.sender);

        chibies[_tokenId].nameChibi = _name;
        return true;
    }

    /**
     * @dev Has chibi necromancer trait?
     * @param _tokenId ID of the chibi
     */
    function isNecromancer(uint _tokenId) public view returns (bool) {
        for (uint i=10; i<13; i++) {
            if (chibies[_tokenId].dna[i] == 1000) {
                return true;
            }
        }
        return false;
    }

    /**
    * @dev buy Chibis with Founders
    */
    function buyChibiWithFcf(string _name, string _battleRoar, uint8 _region, uint _seed) public returns (bool success) {
        // must own at least 1 FCF, only entire FCF can be swapped for Chibis
        require(fcfContract.balanceOf(msg.sender) >= 1 * 10 ** 18);
        require(fcfPaused == false);
        // prevent hack
        uint fcfBefore = fcfContract.balanceOf(address(this));
        // user must approved Founders contract to take tokens from account
        // oh my, this will need a tutorial video
        // always only take 1 Founder at a time
        if (fcfContract.transferFrom(msg.sender, this, 1 * 10 ** 18)) {
            _mint(_name, _battleRoar, _region, _seed, true, 0);
        }
        // prevent hacking
        assert(fcfBefore == fcfContract.balanceOf(address(this)) - 1 * 10 ** 18);
        return true;
    }

    /**
    * @dev Put Chibi up for fusion, this will not destroy your Chibi. Only adults can fuse.
    * @param _tokenId Id of Chibi token that is for fusion
    * @param _price Price for the chibi in wei
    */
    function setChibiForFusion(uint _tokenId, uint _price) public returns (bool success) {
        require(ownerOf(_tokenId) == msg.sender);
        require(_price >= priceFusionChibi);
        require(chibies[_tokenId].adult <= now);
        require(chibies[_tokenId].exhausted <= now);
        require(chibies[_tokenId].forFusion == false);
        require(battleContract.isDead(_tokenId) == false);

        chibies[_tokenId].forFusion = true;
        chibies[_tokenId].fusionPrice = _price;

        emit ChibiForFusion(_tokenId, _price);
        return true;
    }

    function cancelChibiForFusion(uint _tokenId) public returns (bool success) {
        if (ownerOf(_tokenId) != msg.sender && msg.sender != address(battleRemoveContractAddress)) {
            revert();
        }
        require(chibies[_tokenId].forFusion == true);
        
        chibies[_tokenId].forFusion = false;
        
        emit ChibiForFusionCancelled(_tokenId);
            
    return false;
    }
    

 
    /**
    * @dev Connect to gene contract. That way we can update that contract and add more fighters.
    */
    function setGeneContractAddress(address _address) external contract_onlyOwner returns (bool success) {
        geneContract = GeneInterface(_address);
        return true;
    }
 
    /**
    * @dev Fusions cost too much so they are here
    * @return All the fusions (babies) of tokenId
    */
    function queryFusionData(uint _tokenId) public view returns (
        uint256[] fusions,
        bool forFusion,
        uint256 costFusion,
        uint256 adult,
        uint exhausted
        ) {
        return (
        chibies[_tokenId].fusions,
        chibies[_tokenId].forFusion,
        chibies[_tokenId].fusionPrice,
        chibies[_tokenId].adult,
        chibies[_tokenId].exhausted
        );
    }
    
    /**
    * @dev Minimal query for battle contract
    * @return If for fusion
    */
    function queryFusionData_ext(uint _tokenId) public view returns (
        bool forFusion,
        uint fusionPrice
        ) {
        return (
        chibies[_tokenId].forFusion,
        chibies[_tokenId].fusionPrice
        );
    }
 
    /**
    * @dev Triggers a Chibi event to get some data of token
    * @return various
    */
    function queryChibi(uint _tokenId) public view returns (
        string nameChibi,
        string infoUrl,
        uint16[13] dna,
        uint256 father,
        uint256 mother,
        uint gen,
        uint adult
        ) {
        return (
        chibies[_tokenId].nameChibi,
        chibies[_tokenId].infoUrl,
        chibies[_tokenId].dna,
        chibies[_tokenId].father,
        chibies[_tokenId].mother,
        chibies[_tokenId].gen,
        chibies[_tokenId].adult
        );
    }

    /**
    * @dev Triggers a Chibi event getting some additional data
    * @return various
    */
    function queryChibiAdd(uint _tokenId) public view returns (
        address owner,
        bool founder
        ) {
        return (
        chibies[_tokenId].owner,
        chibies[_tokenId].founder
        );
    }
    // exhaust after battle
    function exhaustBattle(uint _tokenId) internal view returns (uint) {
        uint _exhaust = 0;
        
        for (uint i=10; i<13; i++) {
            if (chibies[_tokenId].dna[i] == 1) {
                _exhaust += (exhaustionTime * 3);
            }
            if (chibies[_tokenId].dna[i] == 3) {
                _exhaust += exhaustionTime.div(2);
            }
        }
        
        _exhaust = geneContract.exhaustAfterBattle(chibies[_tokenId].gen, _exhaust);

        return _exhaust;
    }
    // exhaust after fusion
    function exhaustFusion(uint _tokenId) internal returns (uint) {
        uint _exhaust = 0;
        
        uint counter = chibies[_tokenId].dna[9];
        // set dna here, that way boni still apply but not infinite fusions possible
        // max value 9999
        if (chibies[_tokenId].dna[9] < 9999) chibies[_tokenId].dna[9]++;
        
        for (uint i=10; i<13; i++) {
            if (chibies[_tokenId].dna[i] == 2) {
                counter = counter.sub(1);
            }
            if (chibies[_tokenId].dna[i] == 4) {
                counter++;
            }
        }

        _exhaust = geneContract.exhaustAfterFusion(chibies[_tokenId].gen, counter, exhaustionTime);
        
        return _exhaust;
    }
    /** 
     * @dev Exhaust Chibis after battle
     */
    function exhaustChibis(uint _tokenId1, uint _tokenId2) public returns (bool success) {
        require(msg.sender == battleContractAddress);
        
        chibies[_tokenId1].exhausted = now.add(exhaustBattle(_tokenId1));
        chibies[_tokenId2].exhausted = now.add(exhaustBattle(_tokenId2)); 
        
        return true;
    }
    
    /**
     * @dev Split traits between father and mother and leave the random at the _tokenId2
     */
    function traits(uint16[13] memory genes, uint _seed, uint _fatherId, uint _motherId) internal view returns (uint16[13] memory) {
    
        uint _switch = uint136(keccak256(_seed, block.coinbase, block.timestamp)) % 5;
        
        if (_switch == 0) {
            genes[10] = chibies[_fatherId].dna[10];
            genes[11] = chibies[_motherId].dna[11];
        }
        if (_switch == 1) {
            genes[10] = chibies[_motherId].dna[10];
            genes[11] = chibies[_fatherId].dna[11];
        }
        if (_switch == 2) {
            genes[10] = chibies[_fatherId].dna[10];
            genes[11] = chibies[_fatherId].dna[11];
        }
        if (_switch == 3) {
            genes[10] = chibies[_motherId].dna[10];
            genes[11] = chibies[_motherId].dna[11];
        }
        
        return genes;
        
    }
    
    /**
    * @dev The fusion chamber combines both dnas and adds a generation.
    */
    function fusionChibis(uint _fatherId, uint _motherId, uint _seed, string _name, string _battleRoar, uint8 _region) payable public returns (bool success) {
        require(fusionPaused == false);
        require(ownerOf(_fatherId) == msg.sender);
        require(ownerOf(_motherId) != msg.sender);
        require(chibies[_fatherId].adult <= now);
        require(chibies[_fatherId].exhausted <= now);
        require(chibies[_motherId].adult <= now);
        require(chibies[_motherId].exhausted <= now);
        require(chibies[_motherId].forFusion == true);
        require(chibies[_motherId].fusionPrice == msg.value);
        // exhaust father and mother
        chibies[_motherId].forFusion = false;
        chibies[_motherId].exhausted = now.add(exhaustFusion(_motherId));
        chibies[_fatherId].exhausted = now.add(exhaustFusion(_fatherId));
        
        uint _gen = 0;
        if (chibies[_fatherId].gen >= chibies[_motherId].gen) {
            _gen = chibies[_fatherId].gen.add(1);
        } else {
            _gen = chibies[_motherId].gen.add(1);
        }
        // fusion chamber here we come
        uint16[13] memory dna = traits(geneContract.splitGenes(address(this), _seed, uniqueCounter+1), _seed, _fatherId, _motherId);
        
        // new Chibi is born!
        addToken(msg.sender, uniqueCounter);

        // father and mother get the chibi in their fusion list
        chibies[_fatherId].fusions.push(uniqueCounter);
        // only add if mother different than father, otherwise double entry
        if (_fatherId != _motherId) {
            chibies[_motherId].fusions.push(uniqueCounter);
        }
        
        // baby Chibi won&#39;t have fusions
        uint[] memory _fusions;
        
        // baby Chibis can&#39;t be fused
        chibies.push(Chibi(
            msg.sender,
            false,
            _name, 
            dna,
            _fatherId,
            _motherId,
            _gen,
            _fusions,
            false,
            priceFusionChibi,
            0,
            now.add(adultTime.mul((_gen.mul(_gen)).add(1))),
            strConcat(_infoUrlPrefix, uint2str(uniqueCounter))
        ));
        
        // fires chibi created event
        emit ChibiCreated(
            uniqueCounter,
            chibies[uniqueCounter].owner,
            chibies[uniqueCounter].founder,
            chibies[uniqueCounter].nameChibi,
            chibies[uniqueCounter].dna, 
            chibies[uniqueCounter].father, 
            chibies[uniqueCounter].mother, 
            chibies[uniqueCounter].gen,
            chibies[uniqueCounter].adult,
            chibies[uniqueCounter].infoUrl
        );

        // send transfer event
        emit Transfer(0x0, msg.sender, uniqueCounter);
        
        // create Warrior
        if (battleContract.addWarrior(address(this), uniqueCounter, _region, _battleRoar) == false) revert();
        
        uniqueCounter ++;
        // transfer money to seller minus our share, remain stays in contract
        uint256 amount = msg.value / 100 * comission;
        chibies[_motherId].owner.transfer(amount);
        return true;
 }

    /**
    * @dev Guarantees msg.sender is owner of the given token
    * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
    */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }
 
    /**
    * @dev Gets the total amount of tokens stored by the contract
    * @return uint256 representing the total amount of tokens
    */
    function totalSupply() public view returns (uint256) {
        return totalTokens;
    }
 
    /**
    * @dev Gets the balance of the specified address
    * @param _owner address to query the balance of
    * @return uint256 representing the amount owned by the passed address
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return ownedTokens[_owner].length;
    }
 
    /**
    * @dev Gets the list of tokens owned by a given address
    * @param _owner address to query the tokens of
    * @return uint256[] representing the list of tokens owned by the passed address
    */
    function tokensOf(address _owner) public view returns (uint256[]) {
        return ownedTokens[_owner];
    }
 
    /**
    * @dev Gets the owner of the specified token ID
    * @param _tokenId uint256 ID of the token to query the owner of
    * @return owner address currently marked as the owner of the given token ID
    */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }
 
    /**
    * @dev Gets the approved address to take ownership of a given token ID
    * @param _tokenId uint256 ID of the token to query the approval of
    * @return address currently approved to take ownership of the given token ID
    */
    function approvedFor(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }
 
    /**
    * @dev Transfers the ownership of a given token ID to another address
    * @param _to address to receive the ownership of the given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        clearApprovalAndTransfer(msg.sender, _to, _tokenId);
    }
 
    /**
    * @dev Approves another address to claim for the ownership of the given token ID
    * @param _to address to be approved for the given token ID
    * @param _tokenId uint256 ID of the token to be approved
    */
    function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        if (approvedFor(_tokenId) != 0 || _to != 0) {
            tokenApprovals[_tokenId] = _to;
            emit Approval(owner, _to, _tokenId);
        }
    }
 
    /**
    * @dev Claims the ownership of a given token ID
    * @param _tokenId uint256 ID of the token being claimed by the msg.sender
    */
    function takeOwnership(uint256 _tokenId) public {
        require(isApprovedFor(msg.sender, _tokenId));
        clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }
    
    function mintSpecial(string _name, string _battleRoar, uint8 _region, uint _seed, uint _specialId) public contract_onlyOwner returns (bool success) {
        // name can be empty
        _mint(_name, _battleRoar, _region, _seed, false, _specialId);
        return true;
    }
    
    /**
    * @dev Mint token function
    * @param _name name of the Chibi
    */
    function _mint(string _name, string _battleRoar, uint8 _region, uint _seed, bool _founder, uint _specialId) internal {
        require(msg.sender != address(0));
        addToken(msg.sender, uniqueCounter);
    
        // creates a gen0 Chibi, no father, mother, gen0
        uint16[13] memory dna;
        
        if (_specialId > 0) {
            dna  = geneContract.createGenes(address(this), _seed, _founder, uniqueCounter, _specialId);
        } else {
            dna = geneContract.createGenes(address(this), _seed, _founder, uniqueCounter, 0);
        }

        uint[] memory _fusions;

        chibies.push(Chibi(
            msg.sender,
            _founder,
            _name, 
            dna,
            0,
            0,
            0,
            _fusions,
            false,
            priceFusionChibi,
            0,
            now.add(adultTime),
            strConcat(_infoUrlPrefix, uint2str(uniqueCounter))
        ));
        
        // send transfer event
        emit Transfer(0x0, msg.sender, uniqueCounter);
        
        // create Warrior
        if (battleContract.addWarrior(address(this), uniqueCounter, _region, _battleRoar) == false) revert();
        
        // fires chibi created event
        emit ChibiCreated(
            uniqueCounter,
            chibies[uniqueCounter].owner,
            chibies[uniqueCounter].founder,
            chibies[uniqueCounter].nameChibi,
            chibies[uniqueCounter].dna, 
            chibies[uniqueCounter].father, 
            chibies[uniqueCounter].mother, 
            chibies[uniqueCounter].gen,
            chibies[uniqueCounter].adult,
            chibies[uniqueCounter].infoUrl
        );
        
        uniqueCounter ++;
    }
 
    /**
    * @dev buy gen0 chibis
    * @param _name name of the Chibi
    */
    function buyGEN0Chibi(string _name, string _battleRoar, uint8 _region, uint _seed) payable public returns (bool success) {
        require(paused == false);
        // cost at least 100 wei
        require(msg.value == priceChibi);
        // name can be empty
        _mint(_name, _battleRoar, _region, _seed, false, 0);
        return true;
    }
 
    /**
    * @dev set default sale price of Chibies
    * @param _priceChibi price of 1 Chibi in Wei
    */
    function setChibiGEN0Price(uint _priceChibi) public contract_onlyOwner returns (bool success) {
        priceChibi = _priceChibi;
        return true;
    }
 
    /**
    * @dev Tells whether the msg.sender is approved for the given token ID or not
    * This function is not private so it can be extended in further implementations like the operatable ERC721
    * @param _owner address of the owner to query the approval of
    * @param _tokenId uint256 ID of the token to query the approval of
    * @return bool whether the msg.sender is approved for the given token ID or not
    */
    function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
        return approvedFor(_tokenId) == _owner;
    }
 
    /**
    * @dev Internal function to clear current approval and transfer the ownership of a given token ID
    * @param _from address which you want to send tokens from
    * @param _to address which you want to transfer the token to
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        require(_to != ownerOf(_tokenId));
        require(ownerOf(_tokenId) == _from);

        clearApproval(_from, _tokenId);
        removeToken(_from, _tokenId);
        addToken(_to, _tokenId);
        
        // Chibbi code
        chibies[_tokenId].owner = _to;
        chibies[_tokenId].forFusion = false;
        
        emit Transfer(_from, _to, _tokenId);
    }
 
    /**
    * @dev Internal function to clear current approval of a given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function clearApproval(address _owner, uint256 _tokenId) private {
        require(ownerOf(_tokenId) == _owner);
        tokenApprovals[_tokenId] = 0;
        emit Approval(_owner, 0, _tokenId);
    }
 
    /**
    * @dev Internal function to add a token ID to the list of a given address
    * @param _to address representing the new owner of the given token ID
    * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
    */
    function addToken(address _to, uint256 _tokenId) private {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        uint256 length = balanceOf(_to);
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
        totalTokens++;
    }
 
    /**
    * @dev Internal function to remove a token ID from the list of a given address
    * @param _from address representing the previous owner of the given token ID
    * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
    */
    function removeToken(address _from, uint256 _tokenId) private {
        require(ownerOf(_tokenId) == _from);
        
        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = balanceOf(_from).sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];
        
        tokenOwner[_tokenId] = 0;
        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;
        // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
        // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
        // the lastToken to the first position, and then dropping the element placed in the last position of the list
        
        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
        totalTokens = totalTokens.sub(1);
    }

    /**
    * @dev Send Ether to owner
    * @param _address Receiving address
    * @param amount Amount in WEI to send
    **/
    function weiToOwner(address _address, uint amount) public contract_onlyOwner {
        require(amount <= address(this).balance);
        _address.transfer(amount);
    }
    
    /**
    * @dev Return the infoUrl of Chibi
    * @param _tokenId infoUrl of _tokenId
    **/
    function tokenMetadata(uint256 _tokenId) constant public returns (string infoUrl) {
        return chibies[_tokenId].infoUrl;
    }
    
    function tokenURI(uint256 _tokenId) public view returns (string) {
        return chibies[_tokenId].infoUrl;
    }

    //
    // some helpful functions
    // https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    //
    function uint2str(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);

        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
        }
    }