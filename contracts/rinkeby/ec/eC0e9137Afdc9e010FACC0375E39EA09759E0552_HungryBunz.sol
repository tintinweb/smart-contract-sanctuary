// SPDX-License-Identifier: None
// HungryBunz Implementation V1
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ERC721.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./Initializable.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

interface ISnax {
    function computeMultiplier(address requester, bytes16 targetStats, uint16[] memory team) external view returns (uint256);
    function feed(bytes16 stats, uint256 wholeBurn) external view returns (bytes16);
}

interface IItem {
    function applyProperties(bytes32 properties, uint16 item) external view returns (bytes32);
}

interface nom {
    function burn(address account, uint256 amount) external;
    function unstake(uint16[] memory tokenIds, address targetAccount) external;
}

interface IMetadataGen {
    function generateStats(address requester, uint16 newTokenId, uint32 password) external view returns (bytes16);
    function generateAttributes(address requester, uint16 newTokenId, uint32 password) external view returns (bytes16);
}

interface IMetadataRenderer {
    function renderMetadata(uint16 tokenId, bytes16 atts, bytes16 stats) external view returns (string memory);
}

interface IEvolve {
    function evolve(uint8 next1of1, uint16 burntId, address owner, bytes32 t1, bytes32 t2) external view returns(bytes32);
}

contract HungryBunz is Initializable, PaymentSplitter, Ownable, ERC721 {
    //******************************************************
    //CRITICAL CONTRACT PARAMETERS
    //******************************************************
    using ECDSA for bytes32;
    using Strings for uint256;
    
    bool _saleStarted;
    bool _saleEnd;
    bool _bypassAPI;
    bool _metadataRevealed;
    bool _transferPaused;
    uint8 _season; //Defines rewards season
    uint8 _1of1Index; //Currently available 1of1 piece
    uint16 _totalSupply;
    uint16 _maxSupply;
    uint256 _maxPerWallet;
    uint256 _baseMintPrice;
    uint256 _nameTagPrice;
    address _nomContractAddress;
    address _metadataAddress;
    address _arbGateway; //Will need to be populated with the L1 or L2 partner for arb messaging.
    address _openSea;
    address _signerAddress; //Signer address for the transaction
    
    string _storefrontURI;
    IItem items;
    ISnax snax;
    IMetadataRenderer renderer;
    IMetadataGen generator;
    IEvolve _evolver;
    ProxyRegistry _osProxies;
    
    //******************************************************
    //GAMEPLAY MECHANICS
    //******************************************************
    uint8 _maxRank; //Maximum rank setting to allow additional evolutions over time...
    mapping(uint8 => mapping(uint8 => uint16)) _evolveThiccness; //Required thiccness total to evolve by current rank
    mapping(uint8 => uint8) _1of1Allotted; //Allocated 1 of 1 pieces per season
    mapping(uint8 => bool) _1of1sOnThisLayer; //Permit 1/1s on this layer and season.
    
    //******************************************************
    //ANTI BOT AND FAIR LAUNCH HASH TABLES AND ARRAYS
    //******************************************************
    mapping(address => uint256) tokensMintedByAddress; //Tracks total NFTs minted to limit individual wallets.
    
    //******************************************************
    //METADATA HASH TABLES AND ARRAYS
    //******************************************************
    //Bools stored as uint256 to shave a few units off gas fees.
    mapping(uint16 => bytes32) metadataById; //Stores critical metadata by ID
    mapping(uint16 => bytes32) _lockedTokens; //Tracks tokens locked for staking
    mapping(uint16 => uint256) _inactiveOnThisChain; //Tracks which tokens are active on current chain
    mapping(bytes16 => uint256) _usedCombos; //Stores attribute combo hashes to guarantee uniqueness
    mapping(uint16 => string) namedBunz; //Stores names for bunz
    
    //******************************************************
    //CONTRACT CONSTRUCTOR AND INITIALIZER FOR PROXY
    //******************************************************
    constructor() {
        //Initialize ownable on implementation
        //to prevent any misuse of implementation
        //contract.
        ownableInit();
    }
    
    function initHungryBunz (
        address[] memory payees,
        uint256[] memory paymentShares
    )  external initializer
    {
        //Require to prevent users from initializing
        //implementation contract
        require(owner() == address(0) || owner() == msg.sender,
            "No.");
        
        ownableInit();
        initPaymentSplitter(payees, paymentShares);
        initERC721("HungryBunz", "BUNZ");

        _maxRank = 2;
        _transferPaused = true;
        _signerAddress = 0xF658480075BA1158f12524409066Ca495b54b0dD;
        _baseMintPrice = 0.06 ether;
        _maxSupply = 8888;
        _maxPerWallet = 5;
        _nameTagPrice = 200 * 10**18;
        _evolveThiccness[0][1] = 5000;
        _evolveThiccness[0][2] = 30000;
        //Guesstimate on targets for season 1
        _evolveThiccness[1][1] = 15000;
        _evolveThiccness[1][2] = 30000;
        _1of1Index = 1; //Initialize at 1
        
        //WL Opensea Proxies for Cheaper Trading
        _openSea = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
        _osProxies = ProxyRegistry(_openSea);
    }
    
    //******************************************************
    //OVERRIDES TO HANDLE CONFLICTS BETWEEN IMPORTS
    //******************************************************
    function _burn(uint256 tokenId) internal virtual override(ERC721) {
        ERC721._burn(tokenId);
        delete metadataById[uint16(tokenId)];
        _totalSupply -= 1;
    }
    
    //Access to ERC721 implementation for use within app contracts.
    function applicationOwnerOf(uint256 tokenId) public view returns (address) {
        return ERC721.ownerOf(tokenId);
    }
    
    //Override ownerOf to accomplish lower cost alternative to lock tokens for staking.
    function ownerOf(uint256 tokenId) public view virtual override(ERC721) returns (address) {
        address owner = ERC721.ownerOf(tokenId);
        if (lockedForStaking(tokenId) || _inactiveOnThisChain[uint16(tokenId)] == 1) {
            owner = address(0);
        }
        return owner;
    }
    
    //Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    function isApprovedForAll(
        address owner,
        address operator
    )
        public
        view
        override(ERC721)
        returns (bool)
    {
        if (address(_osProxies.proxies(owner)) == operator) {
            return true;
        }
        
        return ERC721.isApprovedForAll(owner, operator);
    }
    
    //Override for simulated transfers and burns.
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override(ERC721) returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        //Transfers not allowed while inactive on this chain. Transfers
        //potentially allowed when spender is foraging contract and
        //token is locked for staking.
        return ((spender == owner || getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender) || spender == address(this)) &&
            (!lockedForStaking(tokenId) || spender == _nomContractAddress) &&
            _inactiveOnThisChain[uint16(tokenId)] == 0 && !_transferPaused);
    }
    
    //******************************************************
    //OWNER ONLY FUNCTIONS TO CONNECT CHILD CONTRACTS.
    //******************************************************    
    function ccNom(address contractAddress) public onlyOwner {
        //Not cast to interface as this will need to be cast to address
        //more often than not.
        _nomContractAddress = contractAddress;
    }
    
    function ccGateway(address contractAddress) public onlyOwner {
        //Notably not cast to interface because this contract never calls
        //functions on gateway.
        _arbGateway = contractAddress;
    }

    function ccSnax(ISnax contractAddress) public onlyOwner {
        snax = contractAddress;
    }
    
    function ccItems(IItem contractAddress) public onlyOwner {
        items = contractAddress;
    }
    
    function ccGenerator(IMetadataGen contractAddress) public onlyOwner {
        generator = contractAddress;
    }
    
    function ccRenderer(IMetadataRenderer newRenderer) public onlyOwner {
        renderer = newRenderer;
    }
    
    function ccEvolution(IEvolve newEvolver) public onlyOwner {
        _evolver = newEvolver;
    }

    function getInterfaces() external view returns (bytes memory) {
        return abi.encodePacked(
            _nomContractAddress,
            _arbGateway,
            address(snax),
            address(items),
            address(generator),
            address(renderer),
            address(_evolver)
        );
    }
    
    //******************************************************
    //OWNER ONLY FUNCTIONS TO MANAGE CRITICAL PARAMETERS
    //******************************************************
    function startSale() public onlyOwner {
        require(_saleEnd == false, "Cannot restart sale.");
        _saleStarted = true;
    }
    
    function endSale() public onlyOwner {
        _saleStarted = false;
        _saleEnd = true;
    }

    function enableTransfer() public onlyOwner {
        _transferPaused = false;
    }

    //Emergency transfer pause to prevent innapropriate transfer of tokens.
    function pauseTransfer() public onlyOwner {
        _transferPaused = true;
    }
    
    function changeWalletLimit(uint16 newLimit) public onlyOwner {
        //Set to 1 higher than limit for cheaper less than check!
        _maxPerWallet = newLimit;
    }
    
    function reduceSupply(uint16 newSupply) public onlyOwner {
        require (newSupply < _maxSupply,
            "Can only reduce supply");
        require (newSupply > _totalSupply,
            "Cannot reduce below current!");
        _maxSupply = newSupply;
    }
    
    function update1of1Index(uint8 oneOfOneIndex) public onlyOwner {
        //This function is provided exclusively so that owner may
        //update 1of1Index to facilitate creation of 1of1s on L2
        //if this is deemed to be a feature of interest to community
        _1of1Index = oneOfOneIndex;
    }
    
    function startNewSeason(uint8 oneOfOneCount, bool enabledOnThisLayer) public onlyOwner {
        //Require all 1 of 1s for current season claimed before
        //starting a new season. L2 seasons will require sync.
        require(_1of1Index == _1of1Allotted[_season],
            "No.");
        _season++;
        _1of1Allotted[_season] = oneOfOneCount + _1of1Index;
        _1of1sOnThisLayer[_season] = enabledOnThisLayer;
    }
    
    function addRank(uint8 newRank) public onlyOwner { //Used to enable third, fourth, etc. evolution levels.
        _maxRank = newRank;
    }
    
    function updateEvolveThiccness(uint8 rank, uint8 season, uint16 threshold) public onlyOwner {
        //Rank as current. E.G. (1, 10000) sets threshold to evolve to rank 2
        //to 10000 pounds or thiccness points
        _evolveThiccness[season][rank] = threshold;
    }
    
    function setPriceToName(uint256 newPrice) public onlyOwner {
        _nameTagPrice = newPrice;
    }
    
    function bypassAPI() public onlyOwner {
        _bypassAPI = true;
    }
    
    function reveal() public onlyOwner {
        _metadataRevealed = true;
    }
    
    function setStoreFrontURI(string memory newURI) public onlyOwner {
        _storefrontURI = newURI;
    }
    
    //******************************************************
    //VIEWS FOR GETTING PRICE INFORMATION
    //******************************************************
    function baseMintPrice() public view returns (uint256) {
        return _baseMintPrice;
    }
    
    function totalMintPrice(uint8 numberOfTokens) public view returns (uint256) {
        return _baseMintPrice * numberOfTokens;
    }
    
    //******************************************************
    //ANTI-BOT PASSWORD HANDLERS
    //******************************************************
    function hashTransaction(address sender, uint256 qty, bytes8 salt) private pure returns(bytes32) {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, qty, salt)))
          );
          
          return hash;
    }
    
    function matchAddresSigner(bytes32 hash, bytes memory signature) public view returns(bool) {
        return (_signerAddress == hash.recover(signature));
    }
    
    //******************************************************
    //UTILITY FUNCTIONS
    //******************************************************    
    //For Opensea Storefront!
    function contractURI() public view returns (string memory) {
        return _storefrontURI;
    }
    
    //******************************************************
    //TOKENURI OVERRIDE RELOCATED TO BELOW UTILITY FUNCTIONS
    //******************************************************
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token Doesn't Exist");
        //Heavy lifting is done by rendering contract.
        bytes16 atts = serializeAtts(uint16(tokenId));
        bytes16 stats = serializeStats(uint16(tokenId));
        return renderer.renderMetadata(uint16(tokenId), atts, stats);
    }
    
    function _writeSerializedAtts(uint16 tokenId, bytes16 newAtts) internal {
        bytes16 currentStats = serializeStats(tokenId);
        metadataById[tokenId] = bytes32(abi.encodePacked(newAtts, currentStats));
    }
    
    function writeSerializedAtts(uint16 tokenId, bytes16 newAtts) external {
        require(msg.sender == _arbGateway,
            "Not Arb Gateway!");
        _writeSerializedAtts(tokenId, newAtts);
    }
    
    function serializeAtts(uint16 tokenId) public view returns (bytes16) {
        return _metadataRevealed ? bytes16(metadataById[tokenId]) : bytes16(0);
    }
    
    function _writeSerializedStats(uint16 tokenId, bytes16 newStats) internal {
        bytes16 currentAtts = serializeAtts(tokenId);
        metadataById[tokenId] = bytes32(abi.encodePacked(currentAtts, newStats));
    }
    
    function writeSerializedStats(uint16 tokenId, bytes16 newStats) external {
        require(msg.sender == _arbGateway,
            "Not Arb Gateway!");
        _writeSerializedStats(tokenId, newStats);
    }
    
    function serializeStats(uint16 tokenId) public view returns (bytes16) {
        return _metadataRevealed ? bytes16(metadataById[tokenId] << 128) : bytes16(0);
    }
    
    function propertiesBytes(uint16 tokenId) external view returns(bytes32) {
        return metadataById[tokenId];
    }
    
    //******************************************************
    //STAKING VIEWS
    //******************************************************
    function lockedForStaking (uint256 tokenId) public view returns(bool) {
        return uint8(bytes1(_lockedTokens[uint16(tokenId)])) == 1;
    }

    //Check stake checks both staking status and ownership.
    function checkStake (uint16 tokenId) external view returns (address) {
        return lockedForStaking(tokenId) ? applicationOwnerOf(tokenId) : address(0);
    }

    //Returns staking timestamp
    function stakeStart (uint16 tokenId) public view returns(uint248) {
        return uint248(bytes31(_lockedTokens[tokenId] << 8));
    }

    //******************************************************
    //STAKING LOCK / UNLOCK AND TIMESTAMP FUNCTION
    //******************************************************
    function updateStakeStart (uint16 tokenId, uint248 newTime) external {
        uint8 stakeStatus = uint8(bytes1(_lockedTokens[tokenId]));
        _lockedTokens[tokenId] = bytes32(abi.encodePacked(stakeStatus, newTime));
    }
    function lockForStaking (uint16 tokenId) external {
        //Nom contract performs owner of check to prevent malicious locking
        require(msg.sender == _nomContractAddress,
            "Unauthorized");
        require(!lockedForStaking(tokenId),
            "Already locked!");
        bytes31 currentTimestamp = bytes31(_lockedTokens[tokenId] << 8);
        //Food coma period will persist after token transfer.
        uint248 stakeTimestamp = uint248(currentTimestamp) < block.timestamp ?
            uint248(block.timestamp) : uint248(currentTimestamp);
        _lockedTokens[tokenId] = bytes32(abi.encodePacked(uint8(1), stakeTimestamp));
        
        //Event with ownerOf override clears secondary listings.
        emit Transfer(applicationOwnerOf(tokenId), address(0), tokenId);
    }
    
    function unlock (uint16 tokenId, uint248 newTime) external {
        //Nom contract performs owner of check to prevent malicious unlocking
        require(msg.sender == _nomContractAddress,
            "Unauthorized");
        require(lockedForStaking(tokenId),
            "Not locked!");
        _lockedTokens[tokenId] = bytes32(abi.encodePacked(uint8(0), newTime));
        
        //Event with ownerOf override restores token in marketplace accounts
        emit Transfer(address(0), applicationOwnerOf(tokenId), tokenId);
    }
    
    //******************************************************
    //L2 FUNCTIONALITY
    //******************************************************
    function setInactiveOnThisChain(uint16 tokenId) external {
        //This can only be called by the gateway contract to prevent exploits.
        //Gateway will check ownership, and setting inactive is a pre-requisite
        //to issuing the message to mint token on the other chain. By verifying
        //that we aren't trying to re-teleport here, we save back and forth to
        //check the activity status of the token on the gateway contract.
        require(msg.sender == _arbGateway,
            "Not Arb Gateway!");
        require(_inactiveOnThisChain[tokenId] == 0,
            "Already inactive!");
        
        //Unstake token to mitigate very minimal exploit by staking then immediately
        //bridging to another layer to accrue slightly more tokens in a given time.
        uint16[] memory lockedTokens = new uint16[](1);
        lockedTokens[0] = tokenId;
        nom(_nomContractAddress).unstake(lockedTokens, applicationOwnerOf(tokenId));
        _inactiveOnThisChain[tokenId] = 1;
        
        //Event with ownerOf override clears secondary listings.
        emit Transfer(applicationOwnerOf(tokenId), address(0), tokenId);
    }
    
    function setActiveOnThisChain(uint16 tokenId, bytes memory metadata, address sender) external {
        require(msg.sender == _arbGateway,
            "Not Arb Gateway!");
        if (_exists(uint256(tokenId))) {
            require(_inactiveOnThisChain[tokenId] == 1,
                "Already active");
        }
        _inactiveOnThisChain[tokenId] = 0;
        
        if(!_exists(uint256(tokenId))) {
            _safeMint(sender, tokenId);
        } else {
            address localOwner = applicationOwnerOf(tokenId);
            if (localOwner != sender) {
                //This indicates a transaction occurred
                //on the other layer. Transfer.
                safeTransferFrom(localOwner, sender, tokenId);
            }
        }
        
        metadataById[tokenId] = bytes32(metadata);
        
        uint16 burntId = uint16(bytes2(abi.encodePacked(metadata[14], metadata[15])));
        if (_exists(uint256(burntId))) {
            _burn(burntId);
        }
        
        //Event with ownerOf override restores token in marketplace accounts
        emit Transfer(address(0), applicationOwnerOf(tokenId), tokenId);
    }
    
    //******************************************************
    //MINT FUNCTIONS
    //******************************************************
    function _mintToken(address to, uint32 password, uint16 newId) internal {        
        //Generate data in mint function to reduce calls. Cost 40k.
        //While loop and additional write operation is necessary
        //evil to prevent duplicates.
        bytes16 newAtts;
        while(newAtts == 0 || _usedCombos[newAtts] == 1) {
            newAtts = generator.generateAttributes(to, newId, password);
            password++;
        }
        _usedCombos[newAtts] = 1;
        
        bytes16 newStats = generator.generateStats(to, newId, password);
        metadataById[newId] = bytes32(abi.encodePacked(newAtts, newStats));

        //Cost 20k.
        _safeMint(to, newId);
    }
    
    function publicAccessMint(uint8 numberOfTokens, bytes memory signature, bytes8 salt)
        public
        payable
    {
        //Between the use of msg.sender in the tx hash for purchase authorization,
        //and the requirements for wallet limiter, saving the salt is an undesirable
        //gas add. Users may re-use the same hash for multiple Txs if they prefer,
        //instead of maxing out their mint the first time.
        bytes32 txHash = hashTransaction(msg.sender, numberOfTokens, salt);
        
        require(_saleStarted,
            "Sale not live.");
        require(matchAddresSigner(txHash, signature),
            "Unauthorized!");
        require((numberOfTokens + tokensMintedByAddress[msg.sender] < _maxPerWallet),
            "Exceeded max mint.");
        require(_totalSupply + numberOfTokens <= _maxSupply,
            "Not enough supply");
        require(msg.value >= totalMintPrice(numberOfTokens),
            "Insufficient funds.");
        
        //Set tokens minted by address before calling internal mint
        //to revert on attempted reentry to bypass wallet limit.
        uint16 offset = _totalSupply;
        tokensMintedByAddress[msg.sender] += numberOfTokens;
        _totalSupply += numberOfTokens; //Set once to save a few k gas

        for (uint i = 0; i < numberOfTokens; i++) {
            offset++;
            _mintToken(msg.sender, uint32(bytes4(signature)), offset);
        }
    }
    
    //******************************************************
    //BURN NOM FOR STAT BOOSTS
    //******************************************************
    //Team must be passed as an argument since gas fees to enumerate a
    //user's collection with Enumerable or similar are too high to justify.
    //Sanitization of the input array is done on the snax contract.
    function consume(uint16 consumer, uint256 burn, uint16[] memory team) public {
        //We only check that a token is active on this chain.
        //You may burn NOM to boost friends' NFTs if you wish.
        //You may also burn NOM to feed currently staked Bunz
        require(_inactiveOnThisChain[consumer] == 0,
            "Not active on this chain!");
        
        //Attempt to burn requisite amount of NOM. Will revert if
        //balance insufficient. This contract is approved burner
        //on NOM contract by default.
        nom(_nomContractAddress).burn(msg.sender, burn);
        
        uint256 wholeBurnRaw = burn / 10 ** 18; //Convert to integer units.
        bytes16 currentStats = serializeStats(consumer);
        //Computation done in snax contract for upgradability. Stack depth
        //limits require us to break the multiplier calc out into a separate
        //call to the snax contract.
        uint256 multiplier = snax.computeMultiplier(msg.sender, currentStats, team); //Returns BPS
        uint256 wholeBurn = (wholeBurnRaw * multiplier) / 10000;
        
        //Snax contract will take a tokenId, retrieve critical stats
        //and then modify stats, primarily thiccness, based on total
        //tokens burned. Output bytes are written back to struct.
        bytes16 transformedStats = snax.feed(currentStats, wholeBurn);
        _writeSerializedStats(consumer, transformedStats);
    }
    
    //******************************************************
    //ATTACH ITEM
    //******************************************************
    function attach(uint16 base, uint16 consumableItem) public {
        //This function will call another function on the item
        //NFT contract which will burn an item, apply its properties
        //to the base NFT, and return these values.
        require(msg.sender == applicationOwnerOf(base),
            "Don't own this token"); //Owner of check performed in item contract
        require(_inactiveOnThisChain[base] == 0,
            "Not active on this chain!");
            
        bytes32 transformedProperties = items.applyProperties(metadataById[base], consumableItem);
        metadataById[base] = transformedProperties;
    }
    
    //******************************************************
    //NAME BUNZ
    //******************************************************
    function getNameTagPrice() public view returns(uint256) {
        return _nameTagPrice;
    }
    
    function name(uint16 tokenId, string memory newName) public {
        require(msg.sender == applicationOwnerOf(tokenId),
            "Don't own this token"); //Owner of check performed in item contract
        require(_inactiveOnThisChain[tokenId] == 0,
            "Not active on this chain!");
            
        //Attempt to burn requisite amount of NOM. Will revert if
        //balance insufficient. This contract is approved burner
        //on NOM contract by default.
        nom(_nomContractAddress).burn(msg.sender, _nameTagPrice);
        
        namedBunz[tokenId] = newName;
    }
    
    //Hook for name not presently used in metadata render contract.
    //Provided for future use.
    function getTokenName(uint16 tokenId) public view returns(string memory) {
        return namedBunz[tokenId];
    }
    
    //******************************************************
    //PRESTIGE SYSTEM
    //******************************************************
    function prestige(uint16[] memory tokenIds) public {
        //This is ugly, but the gas savings elsewhere justify this spaghetti.
        for(uint16 i = 0; i < tokenIds.length; i++) {
            if (uint8(metadataById[tokenIds[i]][17]) != _season) {
                bytes16 currentAtts = serializeAtts(tokenIds[i]);
                bytes12 currentStats = bytes12(metadataById[tokenIds[i]] << 160);
                
                //Atts and rank (byte 16) stay the same. Season (byte 17) and thiccness (bytes 18 and 19) change.
                metadataById[tokenIds[i]] = bytes32(abi.encodePacked(
                        currentAtts, metadataById[tokenIds[i]][16], bytes1(_season), bytes2(0), currentStats
                    ));
            }
        }
    }
    
    //******************************************************
    //EVOLUTION MECHANISM
    //******************************************************
    function evolve(uint16 firstToken, uint16 secondToken) public {
        uint8 rank = uint8(metadataById[firstToken][16]);
        require((rank == uint8(metadataById[secondToken][16])) && (rank < _maxRank),
            "Can't evolve these bunz");
        uint8 season1 = uint8(metadataById[firstToken][17]);
        uint8 season = uint8(metadataById[secondToken][17]) > season1 ? uint8(metadataById[secondToken][17]) : season1;
        uint16 thiccness = uint16(bytes2(abi.encodePacked(metadataById[firstToken][18], metadataById[firstToken][19]))) +
            uint16(bytes2(abi.encodePacked(metadataById[secondToken][18], metadataById[secondToken][19])));
        
        //ownerOf will return the 0 address if tokens are on another layer, or currently staked.
        //Forcing unstake before evolve does not add enough to gas fees to justify the complex
        //logic to gracefully handle token burn while staked without introducing possible attack
        //vectors.
        require(ownerOf(firstToken) == msg.sender && ownerOf(secondToken) == msg.sender, 
            "Not called by owner.");
        require(thiccness >= _evolveThiccness[season][rank],
            "Not thicc enough.");
        
        //Below logic uses the higher season of the two tokens, since otherwise
        //tying this to global _season would allow users to earn 1/1s without
        //prestiging.
        uint8 next1of1 = (_1of1Index <= _1of1Allotted[season]) && _1of1sOnThisLayer[season] ? _1of1Index : 0;
        bytes32 evolvedToken = _evolver.evolve(next1of1, secondToken, msg.sender, metadataById[firstToken], metadataById[secondToken]);
        
        if (uint8(evolvedToken[8]) != 0) {
            _1of1Index++;
        }
        
        metadataById[firstToken] = evolvedToken;
        _burn(secondToken);
    }
}