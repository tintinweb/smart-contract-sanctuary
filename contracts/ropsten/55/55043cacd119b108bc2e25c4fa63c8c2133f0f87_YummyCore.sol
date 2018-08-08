pragma solidity ^0.4.23;

contract ERC721 {
//    function totalSupply() public view returns (uint256 total);
//    function balanceOf(address _owner) public view returns (uint256 balance);
//    function ownerOf(uint256 _tokenId) external view returns (address owner);
//    function approve(address _to, uint256 _tokenId) external;
//    function transfer(address _to, uint256 _tokenId) external;
//    function transferFrom(address _from, address _to, uint256 _tokenId) external;
//
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
//
////    function name() public view returns (string _name);
////    function symbol() public view returns (string _symbol);
//
//    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
//    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract YummyAccessControl {

    // Roles
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // Block actions when contract is paused
    bool public paused = false;

    // Access modifier for CEO
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    // Access modifier for CFO
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    // Access modifier for COO
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    // Access modifier for CEO, CFO, COO
    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == cooAddress
        );
        _;
    }

    // Only CEO can assign a new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    // Only CEO can assign a new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
    }

    // Only CEO can assign a new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }

    // Modifier to allow actions only when not paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    // Modifier to allow actions only when paused
    modifier whenPaused {
        require(paused);
        _;
    }

    // Only CEO, CFO and COO can unpause contract
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    // Only CEO, CFO and COO can pause contract
    function unpause() public onlyCEO whenPaused {
        paused = false;
    }

}

contract YummyBase is YummyAccessControl {

    // Events
    event TokenCreation(address owner, uint256 tokenId, uint256 mmotherId, uint256 fatherId, uint256 genes);
    event Transfer(address from, address to, uint256 tokenId);

    // The the token data structure
    struct Token {
        uint256 genes;
        uint64 creationTime;
        uint64 cooldownEndBlock;
        uint32 motherId;
        uint32 fatherId;
        uint32 breedingWithId;
        uint16 cooldownIndex;
        uint16 generation;
    }

    // Lookup table for cooldowns triggered after every breeding
    uint32[14] public cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];

    // Approximation of block time used for computing cooldown end blocks
    uint256 public secondsPerBlock = 15;

    // Token storage, token ID is the index of the token in this array
    Token[] tokens;

    // Mapping from token ID to owner address
    mapping (uint256 => address) public tokenIndexToOwner;

    // Mapping of owner address to token count
    mapping (address => uint256) ownershipTokenCount;

    // Mapping of token index to approved address for transferFrom()
    mapping (uint256 => address) public tokenIndexToApproved;

    // Mapping from token ID to allowed address for breeding
    mapping (uint256 => address) public fatherAllowedToAddress;

    // Address of the SaleCockAuction that handles sales of tokens
//    SaleClockAuction public saleAuction;

    // Address of the BreedingClockAuction that handles breeding auctions
    BreedingClockAuction public breedingAuction;

    /*
    * @dev Assigns ownership of a token to an address
    */
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        tokenIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete fatherAllowedToAddress[_tokenId];
            delete tokenIndexToApproved[_tokenId];
        }
        emit Transfer(_from, _to, _tokenId);
    }

    /*
    * @dev Internal method for creating and storing a token
    * @dev Doesn&#39;t check anything and should only be called with valid data
    */
    function _createToken(
        uint256 _motherId,
        uint256 _fatherId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    )
    internal
    returns (uint)
    {
        require(_motherId == uint256(uint32(_motherId)));
        require(_fatherId == uint256(uint32(_fatherId)));
        require(_generation == uint256(uint16(_generation)));

        // New token starts with gen/2 cooldown index
        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        Token memory _token = Token({
            genes: _genes,
            creationTime: uint64(now),
            cooldownEndBlock: 0,
            motherId: uint32(_motherId),
            fatherId: uint32(_fatherId),
            breedingWithId: 0,
            cooldownIndex: cooldownIndex,
            generation: uint16(_generation)
        });

        uint256 newTokenId = tokens.push(_token) - 1;

        require(newTokenId == uint256(uint32(newTokenId)));

        // Emits the creation event
        emit TokenCreation(
            _owner,
            newTokenId,
            uint256(_token.motherId),
            uint256(_token.fatherId),
            _token.genes
        );

        // Transfers the token and emits Transfer event
        _transfer(0, _owner, newTokenId);

        return newTokenId;
    }

    // Only CEO, CFO and COO can adjust the secondsPerBlock variable
    function setSecondsPerBlock(uint256 secs) external onlyCLevel {
        require(secs < cooldowns[0]);
        secondsPerBlock = secs;
    }
}

contract YummyOwnership is YummyBase, ERC721 {

    string public constant name = "Yummies";
    string public constant symbol = "YUMS";

    // TODO: ERC165 for ERC721

    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_to != address(breedingAuction));
        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }

    function _owns(
        address _claimant,
        uint256 _tokenId
    )
        internal
        view
        returns (bool)
    {
        return tokenIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(
        address _claimant,
        uint256 _tokenId
    )
        internal
        view
        returns (bool)
    {
        return tokenIndexToApproved[_tokenId] == _claimant;
    }

    function _approve(
        uint256 _tokenId,
        address _approved
    )
        internal
    {
        tokenIndexToApproved[_tokenId] = _approved;
    }

    function balanceOf(
        address _owner
    )
        public
        view
        returns (uint256 count)
    {
        return ownershipTokenCount[_owner];
    }

    // TODO: transfer() ? vs transferFrom()

    function approve(
        address _approved,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _tokenId));

        _approve(_tokenId, _approved);

        emit Approval(msg.sender, _approved, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        _transfer(_from, _to, _tokenId);
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return tokens.length;
    }

    function ownerOf(
        uint256 _tokenId
    )
        external
        view
        returns (address owner)
    {
        owner = tokenIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    /*
    * @dev NEVER CALL THIS FUNCTION FROM A SMART CONTRACT (ONLY WEB3)
    * Very expensive and dynamic array as return type not supported
    */
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = totalSupply();
            uint256 resultIndex = 0;
            uint256 tokenId;

            for (tokenId = 1; tokenId <= totalTokens; tokenId++) {
                if (tokenIndexToOwner[tokenId] == _owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }
        }

        return result;
    }


}

contract Ownable {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}

contract YummyBreeding is YummyOwnership {

    /**
    * @dev The Pregnant event is fired when two Yummies successfully combine to create a new Yummy
    * Starts the timer for the mother
    */
    event Pregnant(address owner, uint256 motherId, uint256 fatherId, uint256 cooldownEndBlock);

    /**
    * @dev The minimum payment required to use autoBreed
    * The fee goes towards the gas cost used to call giveBirth()
    */
    uint256 public autoBirthFee = 2 finney;

    /**
    * @dev Number of pregnant tokens
    */
    uint256 public pregnantTokens;

    /**
    * @dev Gene science contract
    */
    GeneScience public geneScience;

    function setGeneScienceAddress(address _address) external onlyCLevel {
        GeneScience candidateContract = GeneScience(_address);
        require(candidateContract.isGeneScience());
        geneScience = candidateContract;
    }

    /**
    * @dev Number of pregnant tokens
    */
    function _isReadyToBreed(Token _token) internal view returns (bool) {
        return (_token.breedingWithId == 0) && (_token.cooldownEndBlock <= uint64(block.number));
    }

    /**
    * @dev Check if a father has authorized breeding with this mother
    * True if owner of mother and father are the same address or if father has been given breeding permission
    */
    function _isBreedingPermitted(uint256 _fatherId, uint256 _motherId) internal view returns (bool) {
        address motherOwner = tokenIndexToOwner[_motherId];
        address fatherOwner = tokenIndexToOwner[_fatherId];

        return (motherOwner == fatherOwner || fatherAllowedToAddress[_fatherId] == motherOwner);
    }

    /**
    * @dev Set the cooldown end block for the token, based on it&#39;s current cooldownIndex
    * Increment cooldownIndex if it hasn&#39;t hit the cap
    */
    function _triggerCooldown(Token storage _token) internal {
        _token.cooldownEndBlock = uint64((cooldowns[_token.cooldownIndex] / secondsPerBlock) + block.number);
        if (_token.cooldownIndex < 13) {
            _token.cooldownIndex += 1;
        }
    }

    /**
    * @dev Grant approval for breeding to another user with one of your tokens
    */
    function approveBreeding(address _addr, uint256 _fatherId) external whenNotPaused {
        require(_owns(msg.sender, _fatherId));
        fatherAllowedToAddress[_fatherId] = _addr;
    }

    /**
    * @dev Updates the minimum payment required for calling giveBirthAuto()
    * This fee is used to offset the gas cost incurred by the autobirth daemon
    */
    function setAutoBirthFee(uint256 val) external onlyCLevel {
        autoBirthFee = val;
    }

    /**
    * @dev Checks if a given token is pregnant and if the pregnancy is over
    */
    function _isReadyToGiveBirth(Token _mother) private view returns (bool) {
        return (_mother.breedingWithId != 0) && (_mother.cooldownEndBlock <= uint64(block.number));
    }

    /**
    * @dev Checks if a given token is able to breed (not pregnant and not under cooldown)
    */
    function isReadyToBreed(uint256 _tokenId) public view returns (bool) {
        require(_tokenId > 0); // genesis token cannot breed ?
        Token storage token = tokens[_tokenId];
        return _isReadyToBreed(token);
    }

    /**
    * @dev Check if a token is pregnant
    */
    function isPregnant(uint256 _tokenId) public view returns (bool) {
        require(_tokenId > 0);
        return tokens[_tokenId].breedingWithId != 0;
    }

    /**
    * @dev Checks if a fiven father-mother pair is valid
    * @notice WARNING : Does not check ownership permissions (this is up to caller)
    */
    function _isValidBreedingPair(
        Token storage _mother,
        uint256 _motherId,
        Token storage _father,
        uint256 _fatherId
    )
    private
    view
    returns (bool)
    {
        // No self-breeding
        if (_motherId == _fatherId) { return false; }

        // No breeding token&#39;s father
        if (_mother.motherId == _fatherId || _mother.fatherId == _fatherId) {
            return false;
        }

        // No breeding token&#39;s mother
        if (_father.motherId == _motherId || _mother.fatherId == _motherId) {
            return false;
        }

        // Shortcut the sibling check for gen0 tokens
        if (_father.motherId == 0 || _mother.motherId == 0) { return true; }

        // No breeding with siblings
        if (_father.motherId == _mother.motherId || _father.motherId == _mother.fatherId) {
            return false;
        }
        if (_father.fatherId == _mother.motherId || _father.fatherId == _mother.fatherId) {
            return false;
        }

        return true;
    }

    /**
    * @dev Internal check if a given mother and father are a valid pair for auction breeding
    * @notice Skips ownership and breeding approval checks
    */
    function _canBreedViaAuction(uint256 _motherId, uint256 _fatherId)
    internal
    view
    returns (bool)
    {
        Token storage mother = tokens[_motherId];
        Token storage father = tokens[_fatherId];
        return _isValidBreedingPair(mother, _motherId, father, _fatherId);
    }

    /**
     * @dev Checks ownership and approval for breeding
     * @notice Does NOT check breeding cooldown and pregnancy
     */
    function canBreedWith(uint256 _motherId, uint256 _fatherId)
    external
    view
    returns (bool)
    {
        require(_motherId > 0);
        require(_fatherId > 0);
        Token storage mother = tokens[_motherId];
        Token storage father = tokens[_fatherId];
        return _isValidBreedingPair(mother, _motherId, father, _fatherId) &&
        _isBreedingPermitted(_fatherId, _motherId);
    }

    /**
     * @dev Internal breeding function
     * @notice Assumes all breeding requirements are done
     */
    function _breedWith(uint256 _motherId, uint256 _fatherId) internal {
        // Get a reference to tokens from storage
        Token storage mother = tokens[_motherId];
        Token storage father = tokens[_fatherId];

        // Set the mother as pregnant and keep track of father
        mother.breedingWithId = uint32(_fatherId);

        // Trigger cooldown for both parents
        _triggerCooldown(father);
        _triggerCooldown(mother);

        // count pregnancies
        pregnantTokens++;

        // emit Pregnant event
        emit Pregnant(
            tokenIndexToOwner[_motherId],
                _motherId,
                _fatherId,
                mother.cooldownEndBlock
        );
    }

    /**
     * @dev Breed tokens. Will either make the mother pregnant, or fail completely
     * @notice Requires a prepayment of the fee given out to the first caller of giveBirth()
     * If successful, mother becomes pregnant and father&#39;s cooldown begins
     */
    function breedWithAuto(uint256 _motherId, uint256 _fatherId)
    external
    payable
    whenNotPaused
    {
        // Check payment
        require(msg.value >= autoBirthFee);
        // Caller must own the mother
        require(_owns(msg.sender, _motherId));
        // Check that mother and father are owned or breeding-approved for the caller
        require(_isBreedingPermitted(_fatherId, _motherId));

        // Check that tokens are not pregnant or under cooldown
        Token storage mother = tokens[_motherId];
        require(_isReadyToBreed(mother));
        Token storage father = tokens[_fatherId];
        require(_isReadyToBreed(father));

        // Test validity of the couple
        require(_isValidBreedingPair(mother, _motherId, father, _fatherId));

        // Make a baby
        _breedWith(_motherId, _fatherId);

    }

    /**
     * @dev A pregnant token gives birth
     */
    function giveBirth(uint256 _motherId)
    external
    whenNotPaused
    returns (uint256)
    {
        // Get storage reference to mother token
        Token storage mother = tokens[_motherId];

        // Check validity and breeding readiness of mother
        require(mother.creationTime != 0);
        require(_isReadyToGiveBirth(mother));

        uint256 fatherId = mother.breedingWithId;
        Token storage father = tokens[fatherId];

        // Get higher generation number of parents
        uint16 parentGeneration = mother.generation;
        if (father.generation > mother.generation) {
            parentGeneration = father.generation;
        }

        // Compute the new token&#39;s DNA
        uint256 dna = geneScience.randomGenes();

        // Create the new token
        address owner = tokenIndexToOwner[_motherId];
        uint256 tokenId = _createToken(_motherId, fatherId, parentGeneration + 1, dna, owner);

        // Clear reference to father
        delete mother.breedingWithId;

        pregnantTokens--;

        // Send the balance fee to the person who made birth happen
        msg.sender.transfer(autoBirthFee);

        // Return the new token&#39;s ID
        return tokenId;
    }
}

contract YummyAuction is YummyBreeding {

    function setBreedingAuctionAddress(address _address) external onlyCLevel {
        BreedingClockAuction candidateContract = BreedingClockAuction(_address);

        require(candidateContract.isBreedingClockAuction());

        breedingAuction = candidateContract;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPaused {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

contract GeneScience {

    function isGeneScience() public pure returns (bool) {
        return true;
    }

    function uintToBytes(uint256 x) public pure returns (bytes b) {
        b = new bytes(32);
        for (uint i = 0; i < 32; i++) {
            b[i] = byte(uint8(x / (2**(8*(31 - i)))));
        }
    }

    function mixGenes(uint256 genes1, uint256 genes2) public pure returns (uint256) {
        // convert uint256 genes to iterable byte(32) arrays
        bytes memory b1 = uintToBytes(genes1);
        bytes memory b2 = uintToBytes(genes2);

        // bytes32 is castable back to uint256
        bytes32 newGenes;

        // mix genes
        for (uint i = 0; i < 32; i++) {
            if (i % 2 == 0) {
                newGenes |= bytes32(b1[i] & 0xFF) >> (i * 8);
            } else {
                newGenes |= bytes32(b2[i] & 0xFF) >> (i * 8);
            }
        }

        return uint256(newGenes);
    }

    function randomGenes() public view returns (uint256) {
        return uint256(keccak256(now));
    }
}

contract ClockAuctionBase {

}

contract ClockAuction is Pausable, ClockAuctionBase {

}

contract BreedingClockAuction is ClockAuction {

    bool public isBreedingClockAuction = true;

}

contract YummyMinting is YummyAuction {

}

contract YummyCore is YummyMinting {

    constructor() public {
        paused = true;

        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;

        _createToken(0, 0, 0, 0, msg.sender);

    }

    function() external payable {
        require(
            msg.sender == address(breedingAuction)
        );
    }


}